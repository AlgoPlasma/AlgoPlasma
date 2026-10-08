# K01_signal_spectra

[中文](README.zh-CN.md) | [English](README.en.md)

`K01_signal_spectra` is the front end of the diagnostic chain: it turns two raw
probe records into the spectral quantities the later units need.  The
segmentation scheme and the phase sign convention are defined here once and
shared by K02 and K03.

The Beall weight is provided separately by `fun_K01_pair_power(ffts_1, ffts_2)`.
Zero/nonfinite cross spectra give NaN phase; fewer than two valid samples gives NaN statistics.
The histogram mode estimates the mean directly (Liu 2025 II.E); ddof=1 is an implementation convention.

## Files

One routine per file, as elsewhere in the repository; `mod_` only aggregates.

| File | Purpose |
| --- | --- |
| `mod_K01_signal_spectra.py` | Module entry, collecting the routines of this unit. |
| `fun_K01_wrap_to_pi.py` | Wrap angles into `[-pi, pi]`. |
| `fun_K01_segment_ffts.py` | Segment (without overlap), detrend, rFFT; returns `(nseg, nfreq)`. |
| `fun_K01_power_spectrum.py` | Segment-averaged one-sided power spectral density. |
| `fun_K01_coherence.py` | Magnitude-squared coherence in `[0, 1]`. |
| `fun_K01_cross_phase.py` | Per-segment cross phase and cross-spectral magnitude. |
| `fun_K01_phase_mode_statistics.py` | Histogram-mode phase mean and variance (`ddof=1`). |

## Interface

| Function | Purpose |
| --- | --- |
| `fun_K01_wrap_to_pi(values)` | Wrap angles into `[-pi, pi]`. |
| `fun_K01_segment_ffts(signal, nperseg, n_segments=None, detrend=True, window='boxcar')` | Segment, detrend, rFFT. |
| `fun_K01_power_spectrum(ffts, sampling_rate_hz, nperseg, window='boxcar')` | One-sided power spectral density. |
| `fun_K01_coherence(ffts_1, ffts_2)` | Magnitude-squared coherence. |
| `fun_K01_cross_phase(ffts_1, ffts_2)` | Cross phase and cross-spectral magnitude. |
| `fun_K01_phase_mode_statistics(phase, nbins=60)` | Phase mean and variance. |

## Convention

The separation is `chi = r_2 - r_1` and the cross spectrum is
`C = X_1 conj(X_2)`.  With the `exp(-i omega t)` forward transform of
`numpy.fft.rfft`, a plane wave gives `theta = arg C = K . chi`, wrapped into
`(-pi, pi]`.  K02 and K03 use it directly, with no sign flip.

## Mode-Referenced Phase Statistics

When the true phase approaches `+-pi` the segment phases fall on both sides of
the branch cut and an arithmetic mean collapses towards zero.  This estimator
uses the histogram mode directly as the mean estimate and shifts samples to compute variance:

```
theta_bar = theta_mode
sigma^2   = var(wrap(theta_i - theta_mode), ddof=1) + 1e-12
```

## Notes

- **Segments do not overlap.** Non-overlap does not guarantee independence. Correlation affects effective sample size and mode stability. The returned variance describes individual samples; overlap alone does not establish inflated K03 weights.
- Use window='boxcar' for bin-aligned data or window='hann' to reduce sidelobes while broadening the main lobe. Off-bin truncation can affect cross-phase estimates; power_spectrum uses the matching FFT window for power normalization.
- **The coherence floor is not zero.**  With `n` independent segments,
  uncorrelated signals average to `1/n`, not 0.  That is the reference for
  judging an empty band.
- `phase_mode_statistics` returns the variance of an **individual** sample, not
  of the mean. The mode centre is within the principal range; ddof=1 is an implementation convention.
- A trailing partial segment is discarded.

## Usage

```python
import sys
sys.path.insert(0, "/path/to/AlgoPlasma")

from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (
    fun_K01_coherence, fun_K01_cross_phase, fun_K01_phase_mode_statistics,
    fun_K01_power_spectrum, fun_K01_segment_ffts,
)

ffts_1 = fun_K01_segment_ffts(probe_1, nperseg)
ffts_2 = fun_K01_segment_ffts(probe_2, nperseg)
psd = fun_K01_power_spectrum(ffts_1, fs_hz, nperseg)
gamma = fun_K01_coherence(ffts_1, ffts_2)
phase, magnitude = fun_K01_cross_phase(ffts_1, ffts_2)
mean_phase, variance = fun_K01_phase_mode_statistics(phase[:, mode_bins])
```

## Tests

- [basic_numerical tests](../../tests/010_diagnostics/case_basic_checks/): deterministic analytic checks, including power normalization, phase statistics, Beall accumulation and variance-weighted inversion.
- [broadband_dispersion](../../tests/010_diagnostics/case_broadband_dispersion/): generated waveforms drive K01–K03. Acceptance checks the aggregate dispersion and every selected wavevector, including boundary and tie flags.

The broadband page publishes figures, numerical tables, per-mode CSV and source hashes from one run. Its thresholds are engineering requirements for this fixed synthetic case, not universal accuracy guarantees.
