"""@file analyze.py
@brief Drive K01-K03 on the generated records and check them against the generator.

@details
The three units form one chain on one synthetic dataset, and this is where the
computation happens: the K_Diagnostics units are subroutines only. Every
criterion has the same shape, a quantity the generator was built from recovered
from the measurement and compared back, with explicit engineering acceptance limits for this fixed case.
These limits are not universal accuracy or confidence bounds.

K01 reduces the raw records to power spectra, coherence and cross phase. Because
the generator uses A ~ 1/f the power spectrum must fall as 1/f^2, so the fitted
exponent and the lower band edge are compared with the generator. The assessment uses modes whose total PSD exceeds ten times the measured noise
floor. Its threshold crossing is predicted from the f^-2 law with signal power
nine times the floor. It is not the frequency where signal and noise are equal.
In-band median coherence measures signal coherence; out-of-band mean coherence
is compared with the independent-segment zero-coherence expectation 1/n_segments.

K02 builds the Beall S(k, f) map of a single, deliberately coarse pair. The
branch runs far past that pair's Nyquist wavenumber, so it must appear folded
into a repeating sawtooth. Strong-mode histogram peaks are compared with K02's
closed-form prediction using a 95th-percentile residual limit. The residual is measured as a circular distance, because
the wavenumber axis is periodic. Only modes whose power stands clearly above
the noise floor are assessed, and their peak residual is measured in wavenumber
bins. This checks the folded-wavenumber trend; a single pair cannot recover the
lost fold order.

K03 inverts the probe array jointly on a complete uniform grid. Resolution must
be checked for alias selection as well as local error. Configurations have equal
sample counts, but their likelihood weights still depend on phase variance.
Acceptance checks the recovered sound speed, magnitude and direction statistics,
and every selected vector with its boundary/tie flags.

@author Zilong PENG (2026/09/02)

@details Routines
load                read the generated records and reduce each pair with K01
check_k01           spectral exponent, band edge, ten-times-floor crossing, coherence
check_k02           folded-wavenumber peaks on the coarse pair
check_k03           joint inversion and the recovered sound speed
_plot_waveform      noiseless against recorded, and the two noiseless probes
_plot_spectrum      both power spectra against the f^-2 law and the noise floor
_plot_beall         the measured S(k, f) inside the strip the coarse pair spans
_plot_dispersion    the recovered branch against f = c_s |k| / 2 pi
main                run the three checks, write output/summary.json and figures
"""

from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
import hashlib
import json
import platform
import shutil
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

    above_floor = psd_1[bins] > config.ACCEPTANCE["power_to_floor"] * floor
    slope = float(
        np.polyfit(
            np.log(mode_frequencies[above_floor]),
            np.log(psd_1[bins][above_floor] - floor),
            1,
        )[0]
    )

    clear = psd_1 > config.ACCEPTANCE["power_to_floor"] * floor
    clear[0] = False
    edges = np.flatnonzero(clear)
    band_low = float(frequencies[edges[0]])
    crossover_measured = float(frequencies[edges[-1]])
    level = float(psd_1[bins][0] - floor)
    crossover_predicted = float(
        threshold_crossing(mode_frequencies[0], level, floor)
    )
    crossover_error = abs(crossover_measured - crossover_predicted) / crossover_predicted

    measurable = psd_1[bins] > config.ACCEPTANCE["power_to_floor"] * floor
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
        "threshold_crossing_measured_hz": crossover_measured,
        "threshold_crossing_predicted_hz": crossover_predicted,
        "threshold_crossing_relative_error": crossover_error,
        "modes_above_floor": int(np.count_nonzero(measurable)),
        "noise_floor_psd": floor,
        "median_coherence_above_floor": float(np.median(in_band)),
        "mean_coherence_out_of_band": float(np.mean(gamma[outside])),
        "median_coherence_out_of_band": float(np.median(gamma[outside])),
        "coherence_floor_1_over_n": coherence_floor,
        "note": (
            "A ~ 1/f gives a power spectrum falling as 1/f^2.  The fitted "
            "exponent, the lower band edge and the frequency at which the "
            "total spectrum reaches ten times the noise floor are all compared with the "
            "generator; bins above the generated band must sit at the "
            "1/n_segments coherence floor"
        ),
        "passed": bool(
            abs(slope + 2.0) < config.ACCEPTANCE["slope_abs_error"]
            and abs(band_low - mode_frequencies[0]) <= config.ACCEPTANCE["band_edge_bins"] * config.BIN_WIDTH_HZ
            and crossover_error < config.ACCEPTANCE["threshold_crossing_relative_error"]
            and np.median(in_band) > config.ACCEPTANCE["in_band_coherence_min"]
            and np.mean(gamma[outside]) < config.ACCEPTANCE["out_of_band_coherence_mean_factor"] * coherence_floor
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
    measurable = (psd[bins] > config.ACCEPTANCE["power_to_floor"] * floor) & np.isfinite(residual)
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
            and np.percentile(residual_in_bins, 95) < config.ACCEPTANCE["beall_p95_bins"]
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
        return peak

    with ThreadPoolExecutor(max_workers=min(config.MLE_WORKERS, selected.size)) as pool:
        peaks = list(pool.map(recover, selected))
    recovered = np.array([[p["kx"], p["ky"]] for p in peaks])

    frequencies = frequencies[selected]
    diagnostics = evaluate_wavevectors(frequencies, recovered, wavevectors[selected], peaks,
                                      2*k_range/(config.N_GRID-1))
    _plot_dispersion(frequencies, np.hypot(*recovered.T), np.hypot(*wavevectors[selected].T))
    return {"modes_inverted": int(selected.size), "configurations": len(array),
            "grid_n": config.N_GRID, "wavenumber_range_rad_m": k_range, **diagnostics}


def threshold_crossing(first_frequency, signal_level, noise_floor):
    """For total PSD = signal + noise, ratio R requires signal=(R-1)*noise."""
    return float(first_frequency * np.sqrt(
        signal_level / ((config.ACCEPTANCE["power_to_floor"] - 1.0) * noise_floor)))


def evaluate_wavevectors(frequencies, recovered, truth_vectors, peaks, grid_step):
    """Assess every generated mode, as well as the fitted dispersion slope.

    A square grid contributes at most step/sqrt(2) to nearest-point distance.
    The additional 5% vector budget is a declared case requirement for noisy
    recovery, not a statistical confidence interval. No bad modes are allowed.
    Boundary/tie flags invalidate this reference case (truth lies inside its
    search domain); these flags are not universal proof of an invalid estimate.
    """
    truth = np.linalg.norm(truth_vectors, axis=1)
    magnitude = np.linalg.norm(recovered, axis=1)
    relative = np.abs(magnitude-truth)/truth
    delta_angle = np.arctan2(recovered[:, 1], recovered[:, 0]) - np.arctan2(truth_vectors[:, 1], truth_vectors[:, 0])
    angle_error = np.abs(np.degrees(np.arctan2(np.sin(delta_angle), np.cos(delta_angle))))
    vector_error = np.linalg.norm(recovered-truth_vectors, axis=1)
    budget = config.ACCEPTANCE["vector_relative_error"]*truth + grid_step/np.sqrt(2)
    speed = float(2*np.pi*np.sum(magnitude*frequencies)/np.sum(magnitude**2))
    speed_error = abs(speed-config.SOUND_SPEED_M_S)/config.SOUND_SPEED_M_S
    modes = []
    for i, peak in enumerate(peaks):
        reasons = []
        if not np.isfinite(vector_error[i]) or vector_error[i] > budget[i]:
            reasons.append("vector_error_exceeds_budget")
        if peak["boundary"]:
            reasons.append("boundary_peak")
        if peak["tied_grid_points"] != 1:
            reasons.append("tied_grid_maxima")
        modes.append(dict(frequency_hz=float(frequencies[i]),
                          kx_true=float(truth_vectors[i, 0]), ky_true=float(truth_vectors[i, 1]),
                          kx=float(recovered[i, 0]), ky=float(recovered[i, 1]),
                          magnitude_relative_error=float(relative[i]), angle_error_deg=float(angle_error[i]),
                          vector_error_rad_m=float(vector_error[i]), vector_budget_rad_m=float(budget[i]),
                          boundary=bool(peak["boundary"]), tied_grid_points=int(peak["tied_grid_points"]),
                          passed=not reasons, reasons=reasons))
    bad = sum(not m["passed"] for m in modes)
    return dict(grid_step_rad_m=grid_step, sound_speed_true_m_s=config.SOUND_SPEED_M_S,
                sound_speed_fitted_m_s=speed, sound_speed_relative_error=speed_error,
                k_magnitude_relative_error_median=float(np.median(relative)),
                k_magnitude_relative_error_p95=float(np.percentile(relative, 95)),
                k_magnitude_relative_error_max=float(np.max(relative)),
                angle_error_deg_median=float(np.median(angle_error)),
                angle_error_deg_p95=float(np.percentile(angle_error, 95)),
                vector_error_budget_ratio_max=float(np.max(vector_error/budget)),
                bad_modes=bad, modes=modes,
                note="Individual vector errors and search flags are checked before accepting the aggregate trend. Exact tie counts do not establish continuous uniqueness.",
                passed=bool(speed_error < config.ACCEPTANCE["sound_speed_relative_error"]
                            and np.median(relative) < config.ACCEPTANCE["magnitude_median_relative_error"]
                            and np.percentile(angle_error, 95) < config.ACCEPTANCE["angle_p95_deg"]
                            and bad <= config.ACCEPTANCE["allowed_bad_modes"]))


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
    axis.axhline(config.ACCEPTANCE["power_to_floor"]*floor, color="0.4", ls="--", lw=0.8, label="assessment threshold (10 x floor)")
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

    occupied = np.unique(fun_K02_fold_order(
        2*np.pi*mode_frequencies/config.SOUND_SPEED_M_S
        * np.cos(np.deg2rad(config.PHI_DEG)-direction), chi)).size
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
        f"{occupied} occupied fold orders",
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


def write_snapshot(summary, out):
    """Build bilingual tables and an inspectable per-mode CSV from this run."""
    checks = summary["checks"]
    k1, k2, k3 = (checks[k] for k in ["k01_signal_spectra", "k02_beall", "k03_mle_k2d"])
    limits = config.ACCEPTANCE
    rows = [
        ("谱指数误差", "Spectral exponent error", f"< {limits['slope_abs_error']}", f"{k1['spectral_slope_error']:.6g}"),
        ("下带边误差", "Lower band-edge error", f"<= {limits['band_edge_bins']} frequency bins", f"{abs(k1['band_low_measured_hz']-k1['band_low_true_hz'])/config.BIN_WIDTH_HZ:.6g} bins"),
        ("10 倍噪声底交点", "Ten-times-floor crossing", f"relative error < {limits['threshold_crossing_relative_error']:.0%}", f"{k1['threshold_crossing_measured_hz']/1000:.3f} / {k1['threshold_crossing_predicted_hz']/1000:.3f} kHz; error {k1['threshold_crossing_relative_error']:.3%}"),
        ("带内相干度中位数", "In-band median coherence", f"> {limits['in_band_coherence_min']}", f"{k1['median_coherence_above_floor']:.6g}"),
        ("带外相干度均值", "Out-of-band mean coherence", f"< {limits['out_of_band_coherence_mean_factor']}/N = {limits['out_of_band_coherence_mean_factor']/config.N_SEGMENTS:.6g}", f"{k1['mean_coherence_out_of_band']:.6g}"),
        ("Beall 圆周残差 p95", "Beall circular residual p95", f"< {limits['beall_p95_bins']} bins", f"{k2['peak_residual_in_bins_p95']:.6g} bins; {k2['modes_above_floor']} modes"),
        ("声速相对误差", "Sound-speed relative error", f"< {limits['sound_speed_relative_error']:.1%}", f"{k3['sound_speed_relative_error']:.4%}"),
        ("模长相对误差中位数", "Median magnitude error", f"< {limits['magnitude_median_relative_error']:.0%}", f"{k3['k_magnitude_relative_error_median']:.4%}"),
        ("方向误差 p95", "Direction error p95", f"< {limits['angle_p95_deg']} deg", f"{k3['angle_error_deg_p95']:.4f} deg"),
        ("逐频点误差与搜索标记", "Per-mode errors and search flags", f"bad modes <= {limits['allowed_bad_modes']}", f"{k3['bad_modes']} / {k3['modes_inverted']}; max vector error/budget = {k3['vector_error_budget_ratio_max']:.4f}"),
    ]
    for lang in ["zh", "en"]:
        zh = lang == "zh"
        lines = [":orphan:", "", ".. snapshot-start", "",
                 ("运行时间：" if zh else "Run time: ") + summary['provenance']['generated_at_utc'],
                 "", " / ".join(f"{name.split('_')[0].upper()}: {'PASS' if result['passed'] else 'FAIL'}" for name, result in checks.items()), "",
                 ".. list-table:: " + ("同次运行的验收结果" if zh else "Acceptance results from this run"),
                 "   :header-rows: 1", "", "   * - " + ("检查量" if zh else "Quantity"),
                 "     - " + ("要求" if zh else "Requirement"), "     - " + ("实测" if zh else "Measured")]
        for cn, en, requirement, measured in rows:
            lines += ["   * - " + (cn if zh else en), "     - " + requirement, "     - " + measured]
        lines += ["", (f"生成模态覆盖 {k2['distinct_fold_orders']} 个折叠阶；K03 检查全部 {k3['modes_inverted']} 个选定频点。" if zh else
                      f"Generated modes occupy {k2['distinct_fold_orders']} fold orders; K03 checks all {k3['modes_inverted']} selected frequencies."), ""]
        (out/f'results_{lang}.rst').write_text('\n'.join(lines), encoding='utf-8')
    with (out/'modes.csv').open('w', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(k3['modes'][0]))
        writer.writeheader()
        for mode in k3['modes']:
            writer.writerow({**mode, 'reasons': ';'.join(mode['reasons'])})


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--publish-docs', action='store_true', help='publish a consistent small snapshot after all checks pass')
    args = parser.parse_args(argv)
    config.FIGURE_DIR.mkdir(parents=True, exist_ok=True)
    entries = load()
    checks = {
        "k01_signal_spectra": check_k01(entries),
        "k02_beall": check_k02(entries),
        "k03_mle_k2d": check_k03(entries),
    }
    passed = all(check["passed"] for check in checks.values())
    sources = sorted((REPO_ROOT/'K_Diagnostics').rglob('*.py')) + sorted(HERE.glob('*.py'))
    sources += [config.CASE_ROOT/name for name in ['run.sh', 'make.sh', 'clean.sh']]
    provenance = dict(generated_at_utc=datetime.now(timezone.utc).isoformat(),
                      python=platform.python_version(), numpy=np.__version__, matplotlib=matplotlib.__version__,
                      seed=config.SEED, n_segments=config.N_SEGMENTS, nperseg=config.NPERSEG,
                      n_grid=config.N_GRID, workers=config.MLE_WORKERS,
                      source_sha256={str(p.relative_to(REPO_ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources})
    summary = dict(case='broadband_dispersion', passed=passed, checks=checks,
                   acceptance=config.ACCEPTANCE, provenance=provenance)
    (config.OUTPUT_DIR/'summary.json').write_text(json.dumps(summary, indent=2)+'\n', encoding='utf-8')
    write_snapshot(summary, config.OUTPUT_DIR)
    if args.publish_docs and passed:
        dest = REPO_ROOT/'docs/source/tests/010_diagnostics/_generated/case_broadband_dispersion'
        dest.mkdir(parents=True, exist_ok=True)
        for filename in ['summary.json', 'modes.csv', 'results_zh.rst', 'results_en.rst']:
            shutil.copy2(config.OUTPUT_DIR/filename, dest/filename)
        images = REPO_ROOT/'docs/source/images/tests/010_diagnostics/case_broadband_dispersion'
        images.mkdir(parents=True, exist_ok=True)
        for filename in ['raw_waveform.png', 'power_spectrum.png', 'beall_skf.png', 'mle_dispersion.png']:
            shutil.copy2(config.FIGURE_DIR/filename, images/filename)
    for name, check in checks.items():
        print(f"  {'PASS' if check['passed'] else 'FAIL'}  {name}")
    if not passed:
        print(json.dumps(checks, indent=2))
    print(f"summary and figures written to {config.OUTPUT_DIR}")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
