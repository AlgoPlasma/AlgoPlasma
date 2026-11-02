"""Derive K05 paper-style panels from saved moments and an explicit kinetic scenario.

No refitting, gain equalization, or modification of the original captures.
The voltage-domain rates remain conditional diagnostics, including failed Kim bounds.
"""
import argparse
import hashlib
import json
from pathlib import Path
import platform

import numpy as np
import scipy
from scipy.constants import atomic_mass, e, epsilon_0, m_e
from scipy.optimize import root
from scipy.special import ive, wofz


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


class ColdIonEDI:
    """Maxwellian magnetized electrons, unmagnetized cold ions, exp(-i omega t).

    Coordinates are field-aligned: k_perp=ky, k_parallel fixed, k dot u_i=0.
    E = k^2 lambda_De^2 * epsilon; its zeros equal dielectric zeros at k != 0.
    Gordeev series: Cavalier (2013), thesis Eq. (2.8); cold-ion response: Eq. (2.7).
    """

    def __init__(self, config):
        self.config = dict(config)
        for key in ("temperature_ev", "density_m3", "ion_mass_u", "k_parallel_debye"):
            if not np.isfinite(config[key]) or config[key] <= 0:
                raise ValueError(f"{key} must be positive and finite")
        self.b = np.hypot(config["magnetic_radial_gauss"],
                          config["magnetic_axial_gauss"]) * 1e-4
        if not np.isfinite(self.b) or self.b <= 0:
            raise ValueError("Nonzero finite magnetic field required")
        self.mi = config["ion_mass_u"] * atomic_mass
        self.ld = np.sqrt(epsilon_0 * config["temperature_ev"] / (config["density_m3"] * e))
        self.vte = np.sqrt(config["temperature_ev"] * e / m_e)
        self.wce = e * self.b / m_e
        self.wpi = np.sqrt(config["density_m3"] * e**2 / (epsilon_0 * self.mi))
        self.kpar = config["k_parallel_debye"] / self.ld
        self.vd = config["electron_drift_m_per_s"]

    def gordeev(self, omega, ky, extra_harmonics=0):
        bessel_argument = (ky * self.vte / self.wce)**2
        nmax = int(np.ceil(12 * np.sqrt(bessel_argument + 1) + 20)) + extra_harmonics
        orders = np.arange(-nmax, nmax + 1)
        # ive avoids overflow in I_n(b) * exp(-b).
        weights = ive(abs(orders), bessel_argument)
        scale = np.sqrt(2) * self.kpar * self.vte
        doppler = omega - ky * self.vd
        zeta = (doppler - orders * self.wce) / scale
        with np.errstate(over="ignore", invalid="ignore"):
            z_function = 1j * np.sqrt(np.pi) * wofz(zeta)
            response = doppler / scale * np.sum(weights * z_function)
        return response, float(abs(1 - weights.sum()))

    def dielectric(self, omega, ky, extra_harmonics=0):
        k2ld2 = (ky**2 + self.kpar**2) * self.ld**2
        with np.errstate(divide="ignore", invalid="ignore"):
            return (1 + k2ld2 + self.gordeev(omega, ky, extra_harmonics)[0]
                    - k2ld2 * self.wpi**2 / omega**2)

    def root_at(self, ky, guess=None):
        k2ld2 = (ky**2 + self.kpar**2) * self.ld**2
        acoustic = np.sqrt(k2ld2 / (1 + k2ld2)) + .01j
        guesses = [acoustic] if guess is None else [guess / self.wpi, acoustic]
        tolerance = self.config.get("root_tolerance", 1e-9)
        for initial in guesses:
            def residual(z):
                value = self.dielectric(complex(*z) * self.wpi, ky)
                return [value.real, value.imag]
            solution = root(residual, [initial.real, initial.imag], tol=1e-11)
            omega = complex(*solution.x) * self.wpi
            error = abs(self.dielectric(omega, ky))
            if omega.real > 0 and np.isfinite(error) and error <= tolerance:
                return omega, error
        raise ValueError(f"No accepted positive-frequency continuation root at ky={ky:g}")

    def group_velocity(self, omega, ky, relative_step=1e-5):
        dw = self.wpi * relative_step
        dk = max(.001, abs(ky) * relative_step)
        d_omega = (self.dielectric(omega + dw, ky) - self.dielectric(omega - dw, ky)) / (2 * dw)
        d_ky = (self.dielectric(omega, ky + dk) - self.dielectric(omega, ky - dk)) / (2 * dk)
        return float((-d_ky / d_omega).real)

    def branch(self, ky):
        omega, error, vg, tail, convergence, derivative_check = [], [], [], [], [], []
        previous = None
        for k in ky:
            w, err = self.root_at(float(k), previous)
            previous = w
            velocity = self.group_velocity(w, k)
            omega.append(w)
            error.append(err)
            vg.append(velocity)
            tail.append(self.gordeev(w, k)[1])
            convergence.append(abs(self.dielectric(w, k, 16) - self.dielectric(w, k)))
            derivative_check.append(abs(velocity - self.group_velocity(w, k, 2e-5)))
        return dict(ky=np.asarray(ky), omega=np.asarray(omega), residual=np.asarray(error),
                    vg=np.asarray(vg), bessel_tail=np.asarray(tail),
                    harmonic_check=np.asarray(convergence), derivative_check=np.asarray(derivative_check))


def map_frequency(branch, frequency_hz):
    """Interpolate one monotone branch only; never extrapolate or join branches."""
    f = branch["omega"].real / (2 * np.pi)
    if np.any(~np.isfinite(f)) or np.any(np.diff(f) <= 0):
        raise ValueError("A strictly monotone branch is required for a unique f-to-k mapping")
    target = np.asarray(frequency_hz)
    def interp(values):
        return np.interp(target, f, values, left=np.nan, right=np.nan)
    return interp(branch["vg"]), interp(branch["omega"].imag), interp(branch["ky"])


def symmetric_q_map(pairs, counts, coefficients):
    """Expand unordered products to an ordered symmetric map without doubling them.

    coefficients: target x padded_pair complex array. Negative targets are
    conjugate reconstructions required by a real signal, not independent fits.
    """
    limit = int(np.max(abs(pairs)))
    out = np.full((2 * limit + 1, 2 * limit + 1), np.nan + 1j * np.nan)
    for row, count in enumerate(counts):
        for j, (b, c) in enumerate(pairs[row, :count]):
            value = coefficients[row, j] / (1 if b == c else 2)
            for bb, cc, v in [(b, c, value), (c, b, value),
                              (-b, -c, value.conjugate()), (-c, -b, value.conjugate())]:
                if np.isfinite(out[bb + limit, cc + limit]):
                    if not np.allclose(out[bb + limit, cc + limit], v):
                        raise ValueError("Conflicting signed-pair coefficient")
                out[bb + limit, cc + limit] = v
    return np.arange(-limit, limit + 1), out


def convert_rates(linear, phase, quadratic_full_increment, input_power, vg, separation):
    """Half-power transfer convention of Brown & Jorns Eq. (6), in measured volts."""
    if not np.isfinite(separation) or separation <= 0:
        raise ValueError("Positive finite separation required")
    gamma = np.real(np.exp(-1j * phase) * linear) - 1
    gamma = gamma * vg / separation
    # Stored t_app = 2 Re<X* B_rot>/P_X; undo both normalization and factor two.
    transfer = quadratic_full_increment * input_power * vg / (2 * separation)
    return gamma, transfer


def analyze(budget, validation, spectra, config, output):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    if any(output.iterdir()):
        raise FileExistsError("Choose an empty output directory; preserve earlier analysis")
    paths = [Path(budget), Path(validation), Path(spectra), Path(config)]
    hashes = {p.name: sha(p) for p in paths}
    cfg = json.loads(Path(config).read_text(encoding="utf-8"))
    b, v, s = (np.load(p, allow_pickle=False) for p in paths[:3])
    f = b["frequency_hz"]
    prefix = "n2048_b5__"
    np.testing.assert_array_equal(f, v[prefix + "frequency_hz"])
    np.testing.assert_allclose(b["ls_coef"], v[prefix + "coefficients"], equal_nan=True)
    assert np.array_equal(b["captures"], [2, 3, 4, 5])
    input_power = v[prefix + "target_power"] / b["test_ratio"]
    model = ColdIonEDI(cfg)
    branch = model.branch(np.linspace(cfg["ky_min_per_m"], cfg["ky_max_per_m"], cfg["ky_count"]))
    vg, theoretical_gamma, target_ky = map_frequency(branch, f)
    if not np.all(np.isfinite(vg)):
        raise ValueError("Illustrative branch does not cover all fitted frequencies; no extrapolation allowed")
    arr = dict(frequency_hz=f, captures=b["captures"], phase=b["phase"],
               admissible=b["admissible"], identified=b["identified"],
               target_vg=vg, target_ky=target_ky, theoretical_gamma=theoretical_gamma,
               input_power=input_power, target_power=v[prefix + "target_power"])
    arr.update({"dispersion_" + key: value for key, value in branch.items()})
    for method, mi in [("ls", 0), ("kim", 1)]:
        gamma, transfer = convert_rates(
            b[method + "_coef"][:, :, 0], b["phase"], b["increments"][:, :, mi, 1],
            input_power, vg, cfg["separation_m"])
        arr[method + "_gamma"] = gamma
        arr[method + "_transfer_half"] = transfer
        arr[method + "_transfer_half_over_px"] = transfer / input_power
        maps = []
        for i in range(4):
            bins, qmap = symmetric_q_map(b["pairs"], b["pair_count"], b[method + "_coef"][i, :, 1:])
            maps.append(qmap)
        arr[method + "_q_map"] = np.asarray(maps)
    spacing = np.median(np.diff(f))
    arr["pair_frequency_hz"] = bins * spacing
    psd_f = s["g2_f_hz"]
    for g in b["captures"]:
        np.testing.assert_array_equal(psd_f, s[f"g{g}_f_hz"])
    arr["psd_frequency_hz"] = psd_f
    arr["psd_c1"] = np.stack([s[f"g{g}_psd_c1"] for g in b["captures"]])
    arr["psd_c3"] = np.stack([s[f"g{g}_psd_c3"] for g in b["captures"]])
    np.savez_compressed(output / "comparison_arrays.npz", **arr)
    j = int(np.argmin(abs(f - 2e6)))
    qvalid = abs(arr["kim_q_map"][np.isfinite(arr["kim_q_map"])])
    report = dict(
        config=cfg, inputs_sha256=hashes,
        sources_sha256={Path(__file__).name: sha(__file__)},
        versions=dict(python=platform.python_version(), numpy=np.__version__, scipy=scipy.__version__),
        scope="Measured voltage coefficients, held-out moments, and explicitly assumed kinetic branch; no physical EDI identification.",
        fitted_frequency_mhz=[float(f.min()/1e6), float(f.max()/1e6)],
        input_frequency_limit_mhz=float(max(abs(arr["pair_frequency_hz"]))/1e6),
        analysis=dict(fourier="exp(+i 2 pi f t)/N", segment_samples=2048,
                      frequency_spacing_hz=float(spacing), window="periodic Hann", segment_demean=True,
                      overlap=0, validation="four whole-capture holdouts", transfer_moments="held-out capture",
                      q_map="mean magnitude over folds; symmetric ordered-pair convention",
                      negative_targets="conjugate reconstruction, not independently fitted",
                      psd="page06 one-sided Hann-corrected Welch spectra, 16384 samples; equal capture average",
                      half_power_transfer="matches Brown & Jorns Eq6 factor convention; full d|X|^2/dt contribution is 2T",
                      units=dict(q="V^-1", gamma="s^-1", transfer_half="V^2/s", psd="V^2/Hz")),
        derived_scales=dict(magnetic_t=float(model.b), debye_m=float(model.ld),
                            electron_gyro_hz=float(model.wce/(2*np.pi)), ion_plasma_hz=float(model.wpi/(2*np.pi)),
                            parallel_wave_number_per_m=float(model.kpar)),
        audit=dict(root_count=len(branch["ky"]), root_residual_max=float(branch["residual"].max()),
                   harmonic_tail_max=float(branch["bessel_tail"].max()),
                   extended_harmonic_difference_max=float(branch["harmonic_check"].max()),
                   group_derivative_step_difference_max_m_per_s=float(branch["derivative_check"].max()),
                   monotone_branch=True, frequency_extrapolation=False,
                   admissible=int(b["admissible"].sum()), total=int(b["admissible"].size)),
        example=dict(frequency_hz=float(f[j]), model_vg_m_per_s=float(vg[j]),
                     theory_gamma_per_s=float(theoretical_gamma[j]),
                     kim_gamma_fold2_per_s=float(arr["kim_gamma"][0, j]),
                     ls_gamma_fold2_per_s=float(arr["ls_gamma"][0, j]),
                     kim_transfer_half_fold2_v2_per_s=float(arr["kim_transfer_half"][0, j])),
        ranges=dict(model_vg_m_per_s=[float(vg.min()), float(vg.max())],
                    kim_q_magnitude_v_inverse=[float(qvalid.min()), float(qvalid.max())]),
        references=[
            "Brown & Jorns, Phys. Rev. Lett. 130, 115101 (2023), Figs2-3, Eqs4,6,7; doi:10.1103/PhysRevLett.130.115101",
            "Cavalier (2013), Universite de Lorraine thesis, Eqs2.7-2.8; https://docnum.univ-lorraine.fr/public/DDOC_T_2013_0130_CAVALIER.pdf",
        ])
    for p in paths:
        assert sha(p) == hashes[p.name], "An input changed during calculation"
    (output / "comparison_summary.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n",
                                                    encoding="utf-8")
    print(json.dumps(dict(audit=report["audit"], example=report["example"]), indent=2))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--budget", type=Path, required=True, help="Saved transfer_arrays.npz")
    p.add_argument("--validation", type=Path, required=True, help="Saved validation_arrays.npz")
    p.add_argument("--spectra", type=Path, required=True, help="Saved spectral_arrays.npz")
    p.add_argument("--config", type=Path, default=Path(__file__).with_name("paper_comparison_config.json"))
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    analyze(args.budget, args.validation, args.spectra, args.config, args.output)
