# K02_beall

[中文](README.zh-CN.md) | [English](README.en.md)

`K02_beall` holds two things: the **closed-form algebra of aliasing** and the
**Beall statistical dispersion spectrum `S(k, f)`** that makes it visible.

A single pair can only report wavenumbers inside `+-pi/|chi|`; modes beyond that
limit are folded back, so a straight dispersion branch appears broken into a
sawtooth on the `S(k, f)` map.  `K03_mle_k2d` removes the ambiguity using
complementary geometries when identifiability holds; multiple lengths alone do not guarantee it.

## Files

One routine per file, as elsewhere in the repository; `mod_` only aggregates.

| File | Purpose |
| --- | --- |
| `mod_K02_beall.py` | Module entry, collecting the routines of this unit. |
| `fun_K02_separation_vector.py` | Build `chi` from a spacing and an orientation. |
| `fun_K02_separation_magnitude.py` | `\|chi\|`, with the shape and zero-length checks done once. |
| `fun_K02_nyquist_wavenumber.py` | `pi/\|chi\|`. |
| `fun_K02_project_wavenumber.py` | `K . chi_hat`. |
| `fun_K02_fold_order.py` | The fold order `n`. |
| `fun_K02_fold_wavenumber.py` | The folded wavenumber. |
| `fun_K02_wavenumber_edges.py` | Histogram edges spanning `[-pi/\|chi\|, +pi/\|chi\|]`. |
| `fun_K02_beall_wavenumber.py` | `wrap(theta)/\|chi\|`. |
| `fun_K02_beall_spectrum.py` | Accumulate `S(k, f)`. |
| `fun_K02_peak_wavenumber.py` | Peak wavenumber at each frequency. |
| `fun_K02_wavenumber_residual.py` | Circular distance on the folded axis. |

## Interface

| Function | Purpose |
| --- | --- |
| `fun_K02_separation_vector(spacing_m, angle_rad)` | Build `chi` from a spacing and an orientation. |
| `fun_K02_nyquist_wavenumber(chi)` | `pi/|chi|`. |
| `fun_K02_project_wavenumber(k_vector, chi)` | `K . chi_hat`. |
| `fun_K02_fold_order(k_projected, chi)` | The fold order `n`. |
| `fun_K02_fold_wavenumber(k_projected, chi)` | The folded wavenumber. |
| `fun_K02_wavenumber_edges(chi, n_bins)` | Histogram edges spanning `[-pi/|chi|, +pi/|chi|]`. |
| `fun_K02_beall_wavenumber(phase, chi)` | `wrap(theta)/|chi|`. |
| `fun_K02_beall_spectrum(phase, magnitude, frequencies_hz, chi, k_edges, f_edges)` | Accumulate `S(k, f)`. |
| `fun_K02_peak_wavenumber(spectrum, k_centers)` | Peak wavenumber at each frequency. |
| `fun_K02_wavenumber_residual(measured, reference, chi)` | Circular distance on the folded axis. |

## Definitions

```
k_proj = K . chi_hat      k_nyq = pi/|chi|
n      = round(k_proj |chi| / 2 pi)
k_meas = k_proj - n 2 pi/|chi|
aliased  <=>  |k_proj| > k_nyq
```

`k_meas` is exactly what the wrapped phase reports: the phase `K . chi` is only
observable modulo `2 pi`.  The fold order `n` is the information a single pair
cannot supply.

## Method

For each segment `s` and frequency `f`, the histogram bin holding
`wrap(theta)/|chi|` receives the weight `(|X_1|**2 + |X_2|**2)/2`; the result is divided
by the segment count.  Each `(segment, frequency)` sample lands in exactly one
bin, which is what makes the estimator statistical: incoherent segments spread
out, coherent ones pile up.

## Notes

- **The wavenumber axis is periodic** with period `2 pi/|chi|`.  A value just
  inside one Nyquist edge is a neighbour of one just inside the other, so folded
  wavenumbers must be compared with `wavenumber_residual` rather than a plain
  difference; otherwise values near the edge report a full period of spurious
  error.
- **The range is exactly `+-pi/|chi|`**, neither wider nor narrower;
  `wavenumber_edges` supplies it.
- **Enough samples are needed.**  `peak_wavenumber` takes the histogram argmax,
  a finite-sample mode.  When the segment count is far below the number of
  wavenumber bins the "peak" is really just the strongest single sample and
  scatters widely; a smooth `S(k, f)` needs substantially more segments.
- **Baseline and projection.** Use the actual probe-displacement vector for
  `chi`; the reported Beall wavenumber is its component along that baseline, `K·chi_hat`.
- Aliasing cannot be resolved within this unit; recovering the truth needs K03.

## Usage

```python
import sys
sys.path.insert(0, "/path/to/AlgoPlasma")

import numpy as np
from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (
    fun_K01_cross_phase, fun_K01_pair_power, fun_K01_segment_ffts,
)
from K_Diagnostics.K02_beall.mod_K02_beall import (
    fun_K02_beall_spectrum, fun_K02_peak_wavenumber,
    fun_K02_separation_vector, fun_K02_wavenumber_edges,
)

chi = fun_K02_separation_vector(5.0e-3, np.deg2rad(30.0))
ffts_1 = fun_K01_segment_ffts(probe_1, nperseg)
ffts_2 = fun_K01_segment_ffts(probe_2, nperseg)
phase, _ = fun_K01_cross_phase(ffts_1, ffts_2)
magnitude = fun_K01_pair_power(ffts_1, ffts_2)
frequencies = np.fft.rfftfreq(nperseg, d=1.0 / fs_hz)
result = fun_K02_beall_spectrum(
    phase, magnitude, frequencies, chi,
    fun_K02_wavenumber_edges(chi, 80), f_edges,
)
peaks = fun_K02_peak_wavenumber(result["spectrum"], result["k_centers"])
```

## Tests

- [basic_numerical tests](../../tests/010_diagnostics/case_basic_checks/): deterministic analytic checks, including power normalization, phase statistics, Beall accumulation and variance-weighted inversion.
- [broadband_dispersion](../../tests/010_diagnostics/case_broadband_dispersion/): generated waveforms drive K01–K03. Acceptance checks the aggregate dispersion and every selected wavevector, including boundary and tie flags.

The broadband page publishes figures, numerical tables, per-mode CSV and source hashes from one run. Its thresholds are engineering requirements for this fixed synthetic case, not universal accuracy guarantees.


## Provenance

This implementation follows the fixed-probe-pair wavenumber–frequency spectrum
method of Beall et al.  The test deterministically generates raw two-probe
signals from repository parameters and constructs the aliasing map from the
measured cross phase rather than by folding a theoretical dispersion curve
directly.

## References

- J. M. Beall, Y. C. Kim, and E. J. Powers, "Estimation of wavenumber and
  frequency spectra using fixed probe pairs," J. Appl. Phys. **53**(6),
  3933–3940 (1982).
