"""@file config.py
@brief Shared parameters of the broadband dispersion case.

@details
The signal model is taken from the broadband Beall validation in
simulation/simulation_beall/02宽频/generate_signal.py: a continuous spectrum of
ion acoustic modes on the linear branch omega = k c_s, superposed in the time
domain, with an amplitude law A ~ 1/f and independent white Gaussian noise on
each probe. Xenon, m_i = 131 u, T_e = 20 eV, so c_s is about 3825 m/s and there
is no ion drift. All modes share the propagation direction PHI_DEG, so a mode at
frequency f has K = (2 pi f / c_s)(cos phi, sin phi). Because A ~ 1/f the power
spectrum falls as 1/f^2, which is the exponent the K01 check recovers.

The reference generates a single probe pair, so it can afford nperseg = 166666
and a band reaching 10 MHz. This case drives 35 configurations plus a long
record for the Beall pair, roughly a hundred times more work, so the band stops
at BAND_MAX_HZ and the segment length is NPERSEG, which sets the mode spacing to
the bin width. Neither changes the character of the signal: it stays one mode
per frequency bin on the same branch with the same amplitude law.

What the shorter band would have cost is the number of visible aliasing folds,
and that is recovered through the separation of the Beall pair instead. The first
alias boundary is f_alias = c_s / (2 d); the fold period is 2*f_alias for an
aligned pair. Thus the deliberately coarse
BEALL_SPACING_MM pair produces the same repeating pattern a wider band would,
without enlarging the inversion's search grid. That pair also carries
BEALL_N_SEGMENTS rather than N_SEGMENTS, because the Beall spectrum is a
statistical estimator that spreads each sample over a wavenumber histogram and
needs far more of them than a mean phase does.

@author Zilong PENG (2026/09/02)

@details Routines
mode_frequencies         mode frequencies in Hz, one per rFFT bin across the band
mode_bins                rFFT bin index of each mode
mode_amplitudes          the A ~ 1/f envelope, normalised to one at the band foot
mode_wavevectors         true wavevectors in rad/m from omega = k c_s
configurations           the inversion array plus the coarse Beall pair
config_name              file stem of one configuration
segments_for             segment count recorded for one configuration
wavenumber_range         half-width of the coarse search grid, with a margin
alias_frequency          frequency above which a separation aliases, c_s / 2d
"""

from __future__ import annotations

from pathlib import Path

import numpy as np


CASE_ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = CASE_ROOT / "build"
OUTPUT_DIR = CASE_ROOT / "output"
FIGURE_DIR = OUTPUT_DIR / "figures"

ELEMENTARY_CHARGE_C = 1.6e-19
ATOMIC_MASS_UNIT_KG = 1.67e-27
XENON_MASS_UNITS = 131.0
ELECTRON_TEMPERATURE_EV = 20.0

ION_MASS_KG = XENON_MASS_UNITS * ATOMIC_MASS_UNIT_KG
SOUND_SPEED_M_S = float(
    np.sqrt(ELECTRON_TEMPERATURE_EV * ELEMENTARY_CHARGE_C / ION_MASS_KG)
)

SAMPLING_RATE_HZ = 1.0e7
NPERSEG = 1250
N_SEGMENTS = 256  # histogram-mode estimation needs more samples than a mean
BIN_WIDTH_HZ = SAMPLING_RATE_HZ / NPERSEG

BAND_MIN_HZ = 1.0e5
BAND_MAX_HZ = 2.0e6
PHI_DEG = 30.0
MODE_BATCH = 64          # modes summed at once, to bound the working array

SPACINGS_MM = (3.0, 3.5, 4.0, 4.5, 5.0)
ANGLES_DEG = (0, 15, 30, 45, 60, 75, 90)

BEALL_SPACING_MM = 20.0
BEALL_ANGLE_DEG = 30

BEALL_N_SEGMENTS = 512

SNR = 10.0
SEED = 20260902
N_GRID = 1501            # exhaustive uniform grid; no local refinement
FFT_WINDOW = "boxcar"   # this generator uses exactly bin-aligned modes
MLE_WORKERS = 48         # each worker uses bounded-memory row blocks
MODE_STRIDE = 3          # inversion is run on every third mode
BEALL_K_BINS = 80

# Engineering acceptance requirements for this fixed synthetic case, not
# universal estimator confidence bounds. Declare before the reference run.
ACCEPTANCE = {
    "power_to_floor": 10.0,  # total PSD; signal PSD is then nine times the floor
    "slope_abs_error": 0.15,
    "band_edge_bins": 2.0,
    "threshold_crossing_relative_error": 0.15,
    "in_band_coherence_min": 0.8,
    "out_of_band_coherence_mean_factor": 2.0,
    "beall_p95_bins": 2.0,
    "sound_speed_relative_error": 0.005,
    "magnitude_median_relative_error": 0.05,
    "angle_p95_deg": 2.0,
    "vector_relative_error": 0.05,
    "allowed_bad_modes": 0,
}


def mode_frequencies() -> np.ndarray:
    first = int(np.ceil(BAND_MIN_HZ / BIN_WIDTH_HZ))
    last = int(np.floor(BAND_MAX_HZ / BIN_WIDTH_HZ))
    return np.arange(first, last + 1, dtype=np.int64) * BIN_WIDTH_HZ


def mode_bins() -> np.ndarray:
    return np.rint(mode_frequencies() / BIN_WIDTH_HZ).astype(np.int64)


def mode_amplitudes() -> np.ndarray:
    frequencies = mode_frequencies()
    return frequencies[0] / frequencies


def mode_wavevectors() -> np.ndarray:
    magnitude = 2.0 * np.pi * mode_frequencies() / SOUND_SPEED_M_S
    angle = np.deg2rad(PHI_DEG)
    return np.stack([magnitude * np.cos(angle), magnitude * np.sin(angle)], axis=1)


def configurations() -> list[dict]:
    from K_Diagnostics.K02_beall.mod_K02_beall import fun_K02_separation_vector

    out = []
    for spacing_mm in SPACINGS_MM:
        for angle_deg in ANGLES_DEG:
            out.append({"spacing_mm": float(spacing_mm), "angle_deg": int(angle_deg)})
    out.append({"spacing_mm": BEALL_SPACING_MM, "angle_deg": BEALL_ANGLE_DEG})

    for entry in out:
        entry["chi"] = fun_K02_separation_vector(
            entry["spacing_mm"] * 1.0e-3, np.deg2rad(float(entry["angle_deg"]))
        )
        entry["is_beall_pair"] = (
            entry["spacing_mm"] == BEALL_SPACING_MM
            and entry["angle_deg"] == BEALL_ANGLE_DEG
        )
    return out


def config_name(spacing_mm: float, angle_deg: int) -> str:
    return f"signal_r{spacing_mm:.1f}mm_a{int(angle_deg):d}deg"


def segments_for(entry: dict) -> int:
    return BEALL_N_SEGMENTS if entry["is_beall_pair"] else N_SEGMENTS


def wavenumber_range() -> float:
    return 1.15 * float(np.max(np.hypot(*mode_wavevectors().T)))


def alias_frequency(spacing_m: float) -> float:
    return SOUND_SPEED_M_S / (2.0 * float(spacing_m))
