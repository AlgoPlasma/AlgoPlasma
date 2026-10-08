"""@file generate.py
@brief Generate the synthetic two-probe records of the broadband dispersion case.

@details
One record pair is written per probe configuration into build/. Nothing is
shipped with the repository: the records are rebuilt from the constants in
config.py whenever the case is run, and clean.sh removes them.

Every mode is a plane wave on the branch omega = k c_s, superposed in the time
domain and sampled at the two probe positions x_1 = 0 and x_2 = chi:

    probe_p(t) = sum_n A_n cos(K_n . x_p - omega_n t + phi_n)

so the phase difference between the probes is exactly K_n . chi for every mode,
which is the convention K01 measures. The modes are summed in batches to bound
the working array.

As in the reference, the random phases phi_n are drawn once and reused for every
segment and every configuration: the field is one stationary realisation
observed by all the probes, not a fresh realisation per segment. Time restarts
at zero in each segment, so each segment is periodic in its own length and every
mode lands on an exact rFFT bin.

The noise level is taken from a reference pair at zero separation, following the
reference normalisation sigma^2 = 0.5 (mean(probe_1^2) + mean(probe_2^2)) / SNR,
and independent white Gaussian noise is then added to each probe.

@author Zilong PENG (2026/09/02)

@details Routines
clean_segment_pair  one noiseless segment for both probes, as a batched sum of
                    cosines
main                build every configuration, add noise, write build/
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(REPO_ROOT))

import config  # noqa: E402


def clean_segment_pair(
    chi: np.ndarray,
    phases: np.ndarray,
    omega: np.ndarray,
    wavevectors: np.ndarray,
    amplitudes: np.ndarray,
    time: np.ndarray,
) -> tuple[np.ndarray, np.ndarray]:
    chi = np.asarray(chi, dtype=np.float64)
    shift = wavevectors @ chi              # K_n . chi, the probe-2 offset
    probe_1 = np.zeros(time.size, dtype=np.float64)
    probe_2 = np.zeros(time.size, dtype=np.float64)

    for start in range(0, phases.size, config.MODE_BATCH):
        stop = min(start + config.MODE_BATCH, phases.size)
        base = phases[start:stop, None] - omega[start:stop, None] * time[None, :]
        weight = amplitudes[start:stop, None]
        probe_1 += np.sum(weight * np.cos(base), axis=0)
        probe_2 += np.sum(weight * np.cos(base + shift[start:stop, None]), axis=0)
    return probe_1, probe_2


def main() -> int:
    config.BUILD_DIR.mkdir(parents=True, exist_ok=True)

    frequencies = config.mode_frequencies()
    amplitudes = config.mode_amplitudes()
    wavevectors = config.mode_wavevectors()
    omega = 2.0 * np.pi * frequencies
    time = np.arange(config.NPERSEG, dtype=np.float64) / config.SAMPLING_RATE_HZ

    rng = np.random.default_rng(config.SEED)
    phases = rng.uniform(0.0, 2.0 * np.pi, size=frequencies.size)

    magnitude = np.hypot(*wavevectors.T)
    print(
        f"c_s = {config.SOUND_SPEED_M_S:.0f} m/s "
        f"(Xe, T_e = {config.ELECTRON_TEMPERATURE_EV:.0f} eV)"
    )
    print(
        f"modes {frequencies.size} over "
        f"{frequencies[0] / 1e3:.0f}-{frequencies[-1] / 1e3:.0f} kHz, one per bin "
        f"(df = {config.BIN_WIDTH_HZ / 1e3:.0f} kHz), |K| "
        f"{magnitude.min():.0f}-{magnitude.max():.0f} rad/m"
    )
    beall_alias = config.alias_frequency(config.BEALL_SPACING_MM * 1e-3)
    # This pair is aligned with propagation. Count occupied fold orders,
    # rather than dividing frequency by the first Nyquist crossing.
    orders = np.floor(frequencies / (2.0 * beall_alias) + 0.5).astype(int)
    print(
        f"Beall pair {config.BEALL_SPACING_MM:.0f} mm: f_alias = "
        f"{beall_alias / 1e3:.0f} kHz, so about "
        f"{np.unique(orders).size} occupied fold orders across the band"
    )

    reference_1, reference_2 = clean_segment_pair(
        np.array([0.0, 0.0]), phases, omega, wavevectors, amplitudes, time
    )
    signal_power = 0.5 * (
        float(np.mean(reference_1**2)) + float(np.mean(reference_2**2))
    )
    sigma = float(np.sqrt(signal_power / config.SNR))
    print(f"SNR = {config.SNR:g}, noise sigma = {sigma:.4f}")

    entries = config.configurations()
    for index, entry in enumerate(entries):
        n_segments = config.segments_for(entry)
        n_samples = n_segments * config.NPERSEG
        probe_1 = np.empty(n_samples, dtype=np.float64)
        probe_2 = np.empty(n_samples, dtype=np.float64)

        clean_1, clean_2 = clean_segment_pair(
            entry["chi"], phases, omega, wavevectors, amplitudes, time
        )
        for segment in range(n_segments):
            start = segment * config.NPERSEG
            stop = start + config.NPERSEG
            probe_1[start:stop] = clean_1 + rng.normal(0.0, sigma, config.NPERSEG)
            probe_2[start:stop] = clean_2 + rng.normal(0.0, sigma, config.NPERSEG)

        np.savez(
            config.BUILD_DIR
            / f"{config.config_name(entry['spacing_mm'], entry['angle_deg'])}.npz",
            probe_1=probe_1.astype(np.float32),
            probe_2=probe_2.astype(np.float32),
            clean_1=clean_1.astype(np.float32),
            clean_2=clean_2.astype(np.float32),
            chi=entry["chi"],
            spacing_mm=entry["spacing_mm"],
            angle_deg=entry["angle_deg"],
            n_segments=n_segments,
        )
        if (index + 1) % 10 == 0 or index + 1 == len(entries):
            print(f"  generated {index + 1}/{len(entries)} configurations")

    np.savez(
        config.BUILD_DIR / "metadata.npz",
        frequencies_hz=frequencies,
        mode_bins=config.mode_bins(),
        amplitudes=amplitudes,
        wavevectors=wavevectors,
        phases=phases,
        noise_sigma=sigma,
        sampling_rate_hz=config.SAMPLING_RATE_HZ,
        nperseg=config.NPERSEG,
        sound_speed_m_s=config.SOUND_SPEED_M_S,
        phi_deg=config.PHI_DEG,
    )
    print(f"signals written to {config.BUILD_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
