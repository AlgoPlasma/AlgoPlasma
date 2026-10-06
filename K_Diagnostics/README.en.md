# K_Diagnostics

[中文](README.zh-CN.md) | [English](README.en.md)

`K_Diagnostics` collects probe diagnostic algorithms.  Unlike modules `A`–`J`,
which act on particles and grids, this module takes probe time series as input
and returns spectral quantities.  It serves experimental data analysis and
applies equally to probe signals extracted from a PIC simulation.

The three units are three stages of one diagnostic chain:

| ID | Directory | Input | Output |
| --- | --- | --- | --- |
| K01 | [`K01_signal_spectra`](K01_signal_spectra/) | Two raw probe records | Segment spectra, power spectra, coherence, cross phase with its mean and variance |
| K02 | [`K02_beall`](K02_beall/) | Cross phase of one pair | Aliasing algebra and the Beall dispersion spectrum `S(k, f)` |
| K03 | [`K03_mle_k2d`](K03_mle_k2d/) | Phase means and variances of many configurations | Two-dimensional wavevector `(K_x, K_y)` per frequency |

[K04_breathing_waveform](K04_breathing_waveform/) contains the breathing-waveform extraction routines.
The [learning page](../docs/source/rst_files/K_Diagnostics/K04_breathing_waveform.rst) explains the method;
the [routine README](K04_breathing_waveform/README.en.md) describes the Python interface.
Artificial examples, local tests, plotting and cleanup live in
[`tests/011_K04_breathing_waveform`](../tests/011_K04_breathing_waveform/README.en.md), with running instructions.
K04 learns a phase-repeatable waveform from repeated single-point records and supplies residuals for later spectral analysis.

## The Problem This Module Solves

Each baseline constrains the wavevector projection along its direction through the measured phase difference. Summing the configurations' log likelihoods locates jointly supported wavevectors in the two-dimensional wavenumber plane. Baseline directions and lengths determine where the phase fringes intersect.

## Shared Convention

- Separation `chi = r_2 - r_1`, cross spectrum `C = X_1 conj(X_2)`.
- With the `exp(-i omega t)` forward transform of `numpy.fft.rfft`, a plane wave
  gives `theta = arg C = K . chi`, wrapped into `(-pi, pi]`.
- K03's forward model is that same `K . chi`, and K02 recovers the wavenumber as
  `k_par = wrap(theta)/|chi|` — **no sign flip anywhere in the module**.

Swapping the probe order negates `theta` and mirrors every recovered result.

## Usage

Python, source-level modules, no installation.  Add the repository root to
`sys.path` and import as namespace packages:

```python
import sys
sys.path.insert(0, "/path/to/AlgoPlasma")

from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (
    fun_K01_cross_phase, fun_K01_phase_mode_statistics, fun_K01_segment_ffts,
)
from K_Diagnostics.K03_mle_k2d.mod_K03_mle_k2d import (
    fun_K03_joint_log_likelihood, fun_K03_peak_wavevector, fun_K03_wavenumber_grid,
)

configs = []
for chi, probe_1, probe_2 in probe_pairs:        # caller reads its own data
    phase, _ = fun_K01_cross_phase(
        fun_K01_segment_ffts(probe_1, nperseg), fun_K01_segment_ffts(probe_2, nperseg)
    )
    mean_phase, variance = fun_K01_phase_mode_statistics(phase[:, bins])
    configs.append((chi, mean_phase[m], variance[m]))

grid = fun_K03_wavenumber_grid(k_range_rad_m=3300.0, n_grid=301)
result = fun_K03_peak_wavevector(fun_K03_joint_log_likelihood(configs, grid, grid), grid, grid)
```

NumPy is the only dependency.  None of the numerical routines performs **any file
I/O** — reading raw data and writing results are the caller's responsibility,
while examples and tests orchestrate the calculations. Plotting also needs Matplotlib.

## Tests

- [basic_numerical tests](../tests/010_diagnostics/case_basic_checks/): deterministic analytic checks, including power normalization, phase statistics, Beall accumulation and variance-weighted inversion.
- [broadband_dispersion](../tests/010_diagnostics/case_broadband_dispersion/): generated waveforms drive K01–K03. Acceptance checks the aggregate dispersion and every selected wavevector, including boundary and tie flags.

The broadband page publishes figures, numerical tables, per-mode CSV and source hashes from one run. Its thresholds are engineering requirements for this fixed synthetic case, not universal accuracy guarantees.


## Provenance

- K01 implements the underlying segmented-FFT, cross-spectrum, power-spectrum,
  coherence and circular-statistics operations.
- K02 follows the fixed-probe-pair wavenumber–frequency spectrum method of Beall
  et al.
- K03 follows the multi-configuration Bayesian spatial anti-aliasing method of
  Liu and Jorns.
- The test signals are generated deterministically from repository parameters by
  `tests/010_diagnostics/case_broadband_dispersion/source_py/generate.py`; no
  external or private data files are required.

## References

- M. F. Liu and B. A. Jorns, "Anti-aliasing technique for inferring dispersion
  of short-wavelength instabilities in electric propulsion devices," AIAA
  SciTech Forum, Paper AIAA-2025-1293 (2025),
  [doi:10.2514/6.2025-1293](https://doi.org/10.2514/6.2025-1293).
- M. F. Liu and B. A. Jorns, "Experimental validation of a spatial
  anti-aliasing plasma wave analysis technique on ion acoustic turbulence in a
  hollow cathode plume," 39th International Electric Propulsion Conference,
  Paper IEPC-2025-357 (2025).
- J. M. Beall, Y. C. Kim, and E. J. Powers, "Estimation of wavenumber and
  frequency spectra using fixed probe pairs," J. Appl. Phys. **53**(6),
  3933–3940 (1982).
