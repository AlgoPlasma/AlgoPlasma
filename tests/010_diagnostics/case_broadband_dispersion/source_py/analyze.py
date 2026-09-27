"""@file analyze.py
@brief Drive K01-K03 on the generated records and check them against the generator.

@details
The three units form one chain on one synthetic dataset, and this is where the
computation happens: the K_Diagnostics units are subroutines only. Every
criterion has the same shape, a quantity the generator was built from recovered
from the measurement and compared back, rather than a tolerance chosen to make
the test pass.

K01 reduces the raw records to power spectra, coherence and cross phase. Because
the generator uses A ~ 1/f the power spectrum must fall as 1/f^2, so the fitted
exponent and the lower band edge are compared with the generator. The spectrum
does not stay above the noise across the whole band: with A ~ 1/f the modes fade
as 1/f^2 and meet the floor partway, so the crossing frequency is predicted from
that law and the measured level and then looked for in the data, which tests the
spectrum over its whole dynamic range rather than only where it is strong.
Coherence is judged only on the bins that stand clear of the floor, since
elsewhere it carries no information, and against the 1/n_segments value that
uncorrelated bins average to rather than against zero.

K02 builds the Beall S(k, f) map of a single, deliberately coarse pair. The
branch runs far past that pair's Nyquist wavenumber, so it must appear folded
into a repeating sawtooth, and every mode's peak must land where K02's own
closed form predicts. The residual is measured as a circular distance, because
the wavenumber axis is periodic. Only modes whose power stands clearly above
the noise floor are assessed, and their peak residual is measured in wavenumber
bins. This checks the folded-wavenumber trend; a single pair cannot recover the
lost fold order.

K03 inverts the probe array jointly on a complete uniform grid. Resolution must
be checked for alias selection as well as local error. Configurations have equal
sample counts, but their likelihood weights still depend on phase variance.
The pass criterion is that a line through the origin fitted to f against |k|
returns the ion sound speed the generator used.

@author Zilong PENG (2026/09/02)

@details Routines
load                read the generated records and reduce each pair with K01
check_k01           spectral exponent, band edge, noise crossover, coherence
check_k02           folded-wavenumber peaks on the coarse pair
check_k03           joint inversion and the recovered sound speed
_plot_waveform      noiseless against recorded, and the two noiseless probes
_plot_spectrum      both power spectra against the f^-2 law and the noise floor
_plot_beall         the measured S(k, f) inside the strip the coarse pair spans
_plot_dispersion    the recovered branch against f = c_s |k| / 2 pi
main                run the three checks, write output/summary.json and figures
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(REPO_ROOT))

import config  # noqa: E402

from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (  # noqa: E402
    fun_K01_coherence,
    fun_K01_cross_phase,
    fun_K01_pair_power,
    fun_K01_phase_mode_statistics,
    fun_K01_power_spectrum,
    fun_K01_segment_ffts,
)
from K_Diagnostics.K02_beall.mod_K02_beall import (  # noqa: E402
    fun_K02_beall_spectrum,
    fun_K02_fold_order,
    fun_K02_fold_wavenumber,
    fun_K02_peak_wavenumber,
    fun_K02_project_wavenumber,
    fun_K02_wavenumber_edges,
    fun_K02_wavenumber_residual,
)
from K_Diagnostics.K03_mle_k2d.mod_K03_mle_k2d import (  # noqa: E402
    fun_K03_search_wavevector,
)


def load() -> list[dict]:
    if not (config.BUILD_DIR / "metadata.npz").exists():
        raise SystemExit("missing build/metadata.npz; run make.sh first")
    bins = config.mode_bins()

    entries = []
    for entry in config.configurations():
        path = (
            config.BUILD_DIR
            / f"{config.config_name(entry['spacing_mm'], entry['angle_deg'])}.npz"
        )
        data = np.load(path)
        ffts_1 = fun_K01_segment_ffts(data["probe_1"], config.NPERSEG, window=config.FFT_WINDOW)
        ffts_2 = fun_K01_segment_ffts(data["probe_2"], config.NPERSEG, window=config.FFT_WINDOW)
        phase, magnitude = fun_K01_cross_phase(ffts_1, ffts_2)
        mean_phase, variance = fun_K01_phase_mode_statistics(phase[: config.N_SEGMENTS, bins])
        entries.append(
            {
                **entry,
                "ffts_1": ffts_1,
                "ffts_2": ffts_2,
                "phase": phase,
                "magnitude": magnitude,
                "pair_power": fun_K01_pair_power(ffts_1, ffts_2),
                "mean_phase": mean_phase,
                "variance": variance,
                "probe_1": data["probe_1"],
                "probe_2": data["probe_2"],
                "clean_1": data["clean_1"],
                "clean_2": data["clean_2"],
            }
        )
    return entries


def check_k01(entries: list[dict]) -> dict:
    reference = next(entry for entry in entries if not entry["is_beall_pair"])
    take = config.N_SEGMENTS
    frequencies = np.fft.rfftfreq(config.NPERSEG, d=1.0 / config.SAMPLING_RATE_HZ)
    psd_1 = fun_K01_power_spectrum(reference["ffts_1"][:take], config.SAMPLING_RATE_HZ, config.NPERSEG, window=config.FFT_WINDOW)
    psd_2 = fun_K01_power_spectrum(reference["ffts_2"][:take], config.SAMPLING_RATE_HZ, config.NPERSEG, window=config.FFT_WINDOW)
    gamma = fun_K01_coherence(reference["ffts_1"][:take], reference["ffts_2"][:take])

    bins = config.mode_bins()
    mode_frequencies = config.mode_frequencies()

    out_of_band = np.ones(psd_1.size, dtype=bool)
    out_of_band[bins] = False
    out_of_band[0] = False
    floor = float(np.median(psd_1[out_of_band]))

    above_floor = psd_1[bins] > 10.0 * floor
    slope = float(
        np.polyfit(
            np.log(mode_frequencies[above_floor]),
            np.log(psd_1[bins][above_floor] - floor),
            1,
        )[0]
    )

    clear = psd_1 > 10.0 * floor
    clear[0] = False
    edges = np.flatnonzero(clear)
    band_low = float(frequencies[edges[0]])
    crossover_measured = float(frequencies[edges[-1]])
    level = float(psd_1[bins][0] - floor)
    crossover_predicted = float(
        mode_frequencies[0] * np.sqrt(level / (10.0 * floor))
    )
    crossover_error = abs(crossover_measured - crossover_predicted) / crossover_predicted

    measurable = psd_1[bins] > 10.0 * floor
    in_band = gamma[bins][measurable]
    coherence_floor = 1.0 / config.N_SEGMENTS
    outside = out_of_band & (frequencies > config.BAND_MAX_HZ)

    _plot_waveform(reference)
    _plot_spectrum(frequencies, psd_1, psd_2, bins, floor, slope)

    return {
        "reference_configuration": f"{reference['spacing_mm']:.1f} mm, {reference['angle_deg']} deg",
        "modes": int(bins.size),
        "spectral_slope_fitted": slope,
        "spectral_slope_expected": -2.0,
        "spectral_slope_error": abs(slope + 2.0),
        "band_low_measured_hz": band_low,
        "band_low_true_hz": float(mode_frequencies[0]),
        "band_top_generated_hz": float(mode_frequencies[-1]),
        "noise_crossover_measured_hz": crossover_measured,
        "noise_crossover_predicted_hz": crossover_predicted,
        "noise_crossover_relative_error": crossover_error,
        "modes_above_floor": int(np.count_nonzero(measurable)),
        "noise_floor_psd": floor,
        "median_coherence_above_floor": float(np.median(in_band)),
        "median_coherence_out_of_band": float(np.median(gamma[outside])),
        "coherence_floor_1_over_n": coherence_floor,
        "note": (
            "A ~ 1/f gives a power spectrum falling as 1/f^2.  The fitted "
            "exponent, the lower band edge and the frequency at which the "
            "spectrum meets the noise floor are all compared with the "
            "generator; bins above the generated band must sit at the "
            "1/n_segments coherence floor"
        ),
        "passed": bool(
            abs(slope + 2.0) < 0.15
            and abs(band_low - mode_frequencies[0]) <= 2.0 * config.BIN_WIDTH_HZ
            and crossover_error < 0.15
            and np.median(in_band) > 0.8
            and np.median(gamma[outside]) < 2.0 * coherence_floor
        ),
    }


def check_k02(entries: list[dict]) -> dict:
    reference = next(entry for entry in entries if entry["is_beall_pair"])
    chi = reference["chi"]
    frequencies = np.fft.rfftfreq(config.NPERSEG, d=1.0 / config.SAMPLING_RATE_HZ)
    keep = frequencies <= 1.1 * config.BAND_MAX_HZ
    edges = np.append(
        frequencies[keep] - 0.5 * config.BIN_WIDTH_HZ,
        frequencies[keep][-1] + 0.5 * config.BIN_WIDTH_HZ,
    )

    result = fun_K02_beall_spectrum(
        reference["phase"][:, keep],
        reference["pair_power"][:, keep],
        frequencies[keep],
        chi,
        fun_K02_wavenumber_edges(chi, config.BEALL_K_BINS),
        edges,
    )
    peaks = fun_K02_peak_wavenumber(result["spectrum"], result["k_centers"])

    bins = config.mode_bins()
    wavevectors = config.mode_wavevectors()
    projected = np.array([fun_K02_project_wavenumber(k, chi) for k in wavevectors])
    predicted = fun_K02_fold_wavenumber(projected, chi)
    orders = fun_K02_fold_order(projected, chi)
    measured = peaks[bins]

    bin_width = float(result["k_centers"][1] - result["k_centers"][0])
    residual = fun_K02_wavenumber_residual(measured, predicted, chi)
    psd = fun_K01_power_spectrum(
        reference["ffts_1"][: config.segments_for(reference)],
        config.SAMPLING_RATE_HZ,
        config.NPERSEG,
        window=config.FFT_WINDOW,
    )
    out_of_band = np.ones(psd.size, dtype=bool)
    out_of_band[bins] = False
    out_of_band[0] = False
    floor = float(np.median(psd[out_of_band]))
    measurable = (psd[bins] > 10.0 * floor) & np.isfinite(residual)
    residual_in_bins = residual[measurable] / bin_width
    fold_period = 2.0 * result["k_nyquist"]
    aliased = int(np.sum(np.abs(projected) > result["k_nyquist"]))

    _plot_beall(result, predicted, config.mode_frequencies(), chi)

    return {
        "configuration": f"{config.BEALL_SPACING_MM:.1f} mm, {config.BEALL_ANGLE_DEG} deg",
        "alias_frequency_hz": config.alias_frequency(config.BEALL_SPACING_MM * 1e-3),
        "k_nyquist_rad_m": float(result["k_nyquist"]),
        "segments": int(result["segments"]),
        "aliased_modes": aliased,
        "total_modes": int(bins.size),
        "distinct_fold_orders": int(np.unique(orders).size),
        "highest_fold_order": int(np.max(np.abs(orders))),
        "fold_period_rad_m": float(fold_period),
        "bin_width_rad_m": bin_width,
        "modes_above_floor": int(np.count_nonzero(measurable)),
        "noise_floor_psd": floor,
        "peak_residual_in_bins_median": float(np.median(residual_in_bins)) if residual_in_bins.size else None,
        "peak_residual_in_bins_p95": float(np.percentile(residual_in_bins, 95)) if residual_in_bins.size else None,
        "peak_residual_in_bins_max": float(np.max(residual_in_bins)) if residual_in_bins.size else None,
        "note": (
            "the prediction is K02's own closed form applied to the true "
            "wavevector and the measurement is the histogram peak; modes "
            "above ten times the noise floor verify the folded-wavenumber "
            "trend within the histogram-grid resolution, not the lost fold order"
        ),
        "passed": bool(
            aliased > 0
            and np.count_nonzero(measurable) > 0
            and np.percentile(residual_in_bins, 95) < 2.0
            and np.all(np.abs(measured) <= result["k_nyquist"] + 1.0e-9)
        ),
    }


def check_k03(entries: list[dict]) -> dict:
    array = [entry for entry in entries if not entry["is_beall_pair"]]
    frequencies = config.mode_frequencies()
    wavevectors = config.mode_wavevectors()
    selected = np.arange(0, frequencies.size, config.MODE_STRIDE)

    k_range = config.wavenumber_range()
    def recover(mode):
        peak = fun_K03_search_wavevector(
            (
                (entry["chi"], float(entry["mean_phase"][mode]), float(entry["variance"][mode]))
                for entry in array
            ),
            k_range,
            n_grid=config.N_GRID,
        )
        return peak["kx"], peak["ky"]

    with ThreadPoolExecutor(max_workers=min(config.MLE_WORKERS, selected.size)) as pool:
        recovered = np.asarray(list(pool.map(recover, selected)))

    frequencies = frequencies[selected]
    truth = np.hypot(*wavevectors[selected].T)
    magnitude = np.hypot(*recovered.T)
    angle = np.degrees(np.arctan2(recovered[:, 1], recovered[:, 0]))

    slope = float(np.sum(magnitude * frequencies) / np.sum(magnitude**2))
    speed = 2.0 * np.pi * slope
    speed_error = abs(speed - config.SOUND_SPEED_M_S) / config.SOUND_SPEED_M_S

    relative = np.abs(magnitude - truth) / truth
    angle_error = np.abs((angle - config.PHI_DEG + 180.0) % 360.0 - 180.0)

    _plot_dispersion(frequencies, magnitude, truth)

    return {
        "modes_inverted": int(selected.size),
        "configurations": len(array),
        "grid_n": config.N_GRID,
        "grid_step_rad_m": 2 * k_range / (config.N_GRID - 1),
        "wavenumber_range_rad_m": k_range,
        "sound_speed_true_m_s": config.SOUND_SPEED_M_S,
        "sound_speed_fitted_m_s": speed,
        "sound_speed_relative_error": speed_error,
        "k_magnitude_relative_error_median": float(np.median(relative)),
        "k_magnitude_relative_error_p95": float(np.percentile(relative, 95)),
        "angle_error_deg_median": float(np.median(angle_error)),
        "angle_error_deg_p95": float(np.percentile(angle_error, 95)),
        "note": (
            "the slope of f against |k| is the ion sound speed; the magnitude "
            "and circular direction errors jointly verify the recovered "
            "two-dimensional wavevector"
        ),
        "passed": bool(
            speed_error < 5.0e-3
            and float(np.median(relative)) < 0.05
            and float(np.percentile(angle_error, 95)) < 2.0
        ),
    }


def _plot_waveform(entry: dict) -> None:
    span = 200
    time_us = np.arange(span) / config.SAMPLING_RATE_HZ * 1.0e6
    clean_1 = entry["clean_1"][:span]
    clean_2 = entry["clean_2"][:span]

    figure, axes = plt.subplots(1, 2, figsize=(9.6, 3.3), sharey=True,
                               constrained_layout=True)
    axes[0].plot(time_us, entry["probe_1"][:span], lw=0.9, color="0.6",
                 label=f"recorded (SNR = {config.SNR:g})")
    axes[0].plot(time_us, clean_1, lw=1.4, color="tab:blue", label="noiseless")
    axes[0].set_title("probe 1: signal and noise", fontsize=10)
    axes[0].legend(fontsize=8, loc="upper right")

    axes[1].plot(time_us, clean_1, lw=1.4, color="tab:blue", label="probe 1")
    axes[1].plot(time_us, clean_2, lw=1.4, color="tab:orange", label="probe 2")
    axes[1].set_title(
        f"noiseless pair, separation {entry['spacing_mm']:.1f} mm at "
        f"{entry['angle_deg']}$^\\circ$",
        fontsize=10,
    )
    axes[1].legend(fontsize=8, loc="upper right")
    for axis in axes:
        axis.set_xlabel(r"time ($\mu$s)")
    axes[0].set_ylabel("signal (arb.)")
    figure.savefig(config.FIGURE_DIR / "raw_waveform.png", dpi=150)
    plt.close(figure)


def _plot_spectrum(frequencies, psd_1, psd_2, bins, floor, slope) -> None:
    mode_frequencies = config.mode_frequencies()
    reference = psd_1[bins][0] * (mode_frequencies / mode_frequencies[0]) ** -2.0

    figure, axis = plt.subplots(figsize=(6.2, 3.8), constrained_layout=True)
    axis.loglog(frequencies[1:] * 1e-3, psd_1[1:], lw=0.8, label="probe 1")
    axis.loglog(frequencies[1:] * 1e-3, psd_2[1:], lw=0.8, alpha=0.7, label="probe 2")
    axis.loglog(mode_frequencies * 1e-3, reference, "k--", lw=1.2,
                label=r"generator $\propto f^{-2}$")
    axis.axhline(floor, color="tab:red", ls=":", lw=1.0, label="noise floor")
    axis.set_xlim(50.0, frequencies[-1] * 1e-3)
    axis.set_ylim(floor / 5.0, psd_1[bins].max() * 5.0)
    axis.set_xlabel("frequency (kHz)")
    axis.set_ylabel("PSD (arb. / Hz)")
    axis.set_title(f"Power spectrum, fitted slope {slope:.2f}", fontsize=10)
    axis.legend(fontsize=8)
    figure.savefig(config.FIGURE_DIR / "power_spectrum.png", dpi=150)
    plt.close(figure)


def _plot_beall(result, predicted, mode_frequencies, chi) -> None:
    nyquist = result["k_nyquist"]
    spectrum = np.log10(result["spectrum"] + 1.0e-12)
    top = float(np.max(spectrum))

    direction = np.arctan2(chi[1], chi[0])
    dense_f = np.linspace(0.0, mode_frequencies[-1] * 1.02, 8000)
    dense_k = 2.0 * np.pi * dense_f / config.SOUND_SPEED_M_S
    projected = dense_k * np.cos(np.deg2rad(config.PHI_DEG) - direction)
    folded = fun_K02_fold_wavenumber(projected, chi)
    folded = np.where(
        np.concatenate([[False], np.abs(np.diff(folded)) > nyquist]), np.nan, folded
    )

    alias_hz = config.alias_frequency(config.BEALL_SPACING_MM * 1e-3)
    figure, axis = plt.subplots(figsize=(6.0, 4.4), constrained_layout=True)
    mesh = axis.pcolormesh(result["k_centers"], result["f_centers"] * 1e-3,
                           spectrum, shading="auto", cmap="magma",
                           vmin=top - 4.0, vmax=top)
    axis.plot(folded, dense_f * 1e-3, "-", color="tab:cyan", lw=0.9,
              label="aliased theory")
    axis.plot(predicted, mode_frequencies * 1e-3, "o", mfc="none", mec="white",
              ms=3, mew=0.7, label="K02 prediction")
    axis.set_xlim(-nyquist, nyquist)
    axis.set_ylim(0.0, mode_frequencies[-1] * 1.02e-3)
    axis.set_xlabel(r"$k_\parallel$ (rad/m)")
    axis.set_ylabel("frequency (kHz)")
    axis.set_title(
        f"Beall $S(k,f)$, coarse pair "
        f"({config.BEALL_SPACING_MM:.0f} mm at {config.BEALL_ANGLE_DEG}$^\\circ$, "
        f"{result['segments']} segments)\n"
        rf"$k_{{\rm Nyq}}$ = {nyquist:.0f} rad/m, "
        f"{mode_frequencies[-1] / alias_hz:.0f} folds across the band",
        fontsize=9,
    )
    axis.legend(fontsize=8, loc="lower left", framealpha=0.75)
    figure.colorbar(mesh, ax=axis, label=r"$\log_{10} S$", fraction=0.046)
    figure.savefig(config.FIGURE_DIR / "beall_skf.png", dpi=150)
    plt.close(figure)


def _plot_dispersion(frequencies, magnitude, truth) -> None:
    figure, axis = plt.subplots(figsize=(5.6, 4.2), constrained_layout=True)
    reference = np.linspace(0.0, truth.max() * 1.08, 200)
    axis.plot(reference, config.SOUND_SPEED_M_S * reference / (2.0 * np.pi) * 1e-3,
              "-", lw=1.2, color="tab:blue", label=r"theory: $f = c_s|k|/2\pi$")
    axis.plot(magnitude, frequencies * 1e-3, "o", ms=3.5, color="tab:orange",
              label="K03 recovered")
    axis.set_xlabel(r"$|k|$ (rad/m)")
    axis.set_ylabel("$f$ (kHz)")
    axis.set_title(
        f"Joint MLE dispersion, {len(config.SPACINGS_MM) * len(config.ANGLES_DEG)} "
        f"configurations\nthe branch K02 shows folded is recovered straight",
        fontsize=9,
    )
    axis.grid(alpha=0.3)
    axis.legend(fontsize=8)
    figure.savefig(config.FIGURE_DIR / "mle_dispersion.png", dpi=150)
    plt.close(figure)


def main() -> int:
    config.FIGURE_DIR.mkdir(parents=True, exist_ok=True)
    entries = load()

    checks = {
        "k01_signal_spectra": check_k01(entries),
        "k02_beall": check_k02(entries),
        "k03_mle_k2d": check_k03(entries),
    }
    passed = all(check["passed"] for check in checks.values())
    (config.OUTPUT_DIR / "summary.json").write_text(
        json.dumps(
            {"case": "broadband_dispersion", "passed": passed, "checks": checks},
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    for name, check in checks.items():
        print(f"  {'PASS' if check['passed'] else 'FAIL'}  {name}")
    print(f"summary and figures written to {config.OUTPUT_DIR}")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
