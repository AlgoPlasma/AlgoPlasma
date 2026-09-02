# K01_signal_spectra

[中文](README.zh-CN.md) | [English](README.en.md)

`K01_signal_spectra` is the front end of the diagnostic chain: it turns two raw
probe records into the spectral quantities the later units need.  The
segmentation scheme and the phase sign convention are defined here once and
shared by K02 and K03.

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
| `fun_K01_phase_mode_statistics.py` | Mode-referenced phase mean and variance (`ddof=1`). |

## Interface

| Function | Purpose |
| --- | --- |
| `fun_K01_wrap_to_pi(values)` | Wrap angles into `[-pi, pi]`. |
| `fun_K01_segment_ffts(signal, nperseg, n_segments=None, detrend=True)` | Segment, detrend, rFFT. |
| `fun_K01_power_spectrum(ffts, sampling_rate_hz, nperseg)` | One-sided power spectral density. |
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
locates the mode on a histogram and moves the cut opposite it before averaging:

```
theta_bar = theta_mode + <wrap(theta_i - theta_mode)>
sigma^2   = var(wrap(theta_i - theta_mode), ddof=1) + 1e-12
```

## Notes

- **Segments do not overlap.**  Overlapping them correlates the phase samples,
  whereas K03's likelihood weights assume independence.
- **No window is applied.**  A rectangular window is exact for content periodic
  in the segment length; measured data that is not bin aligned needs a window
  from the caller.  Being off-bin affects only the in-bin power, not the *cross*
  phase: the leakage factor is identical for both probes and cancels in
  `X_1 conj(X_2)`.
- **The coherence floor is not zero.**  With `n` independent segments,
  uncorrelated signals average to `1/n`, not 0.  That is the reference for
  judging an empty band.
- `phase_mode_statistics` returns the variance of an **individual** sample, not
  of the mean, and `theta_bar` is not re-wrapped.
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

`tests/010_diagnostics/case_broadband_dispersion`: the generator uses `A ~ 1/f`, so
the power spectrum falls as `1/f^2`.  Three quantities of the generator are
recovered from the measurement:

- fitted spectral exponent **-2.015** against -2;
- lower band edge 104 kHz, matching the generated value to within one bin;
- the frequency at which the spectrum meets the noise floor, 816 kHz measured
  against the 733 kHz the `1/f^2` law predicts (11 %).  This last one tests the
  spectrum across its whole dynamic range rather than only where it is strong.

Coherence has median 0.932 over the bins that stand clear of the floor, and
out-of-band bins sit at 0.038 against the `1/n_seg = 0.0625` floor.
