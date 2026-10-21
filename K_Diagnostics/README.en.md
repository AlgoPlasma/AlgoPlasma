# K_Diagnostics

[中文](README.zh-CN.md) | [English](README.en.md)

`K_Diagnostics` collects computational methods for extracting physical diagnostic
quantities from experimental or numerical data. It provides reusable routines for
specific diagnostic tasks. Current capabilities cover spectra and phase analysis,
probe-pair wavenumber diagnostics, wavevector inference from multiple configurations,
and extraction of breathing-cycle waveforms from repeated records at one spatial point.

## Current Capabilities

| ID | Directory | Input | Output |
| --- | --- | --- | --- |
| K01 | [`K01_signal_spectra`](K01_signal_spectra/) | One or two time series, or their segment spectra | Segment spectra, power spectra, coherence, cross phase, mode-referenced phase statistics and mean pair auto-power |
| K02 | [`K02_beall`](K02_beall/) | Pair cross phase, mean auto-power, frequency and separation; fold-order calculation also needs a known projected wavenumber | Folded wavenumber, Beall spectrum `S(k, f)` and aliasing relations |
| K03 | [`K03_mle_k2d`](K03_mle_k2d/) | Separation vectors, phase statistics and a search grid for multiple configurations | Joint log likelihood and a two-dimensional wavevector estimate `(K_x, K_y)` per frequency |
| K04 | [`K04_breathing_waveform`](K04_breathing_waveform/) | Repeated voltage records at one spatial point, with the same sampling rate and comparable conditions | Phase-repeatable waveform `C` and residual `R = X - C` for a held-out record |

K01's FFT, power spectrum, coherence and cross phase can process time series from
different sources. `pair_power` supplies the weight used by the Beall workflow;
`phase_mode_statistics` uses the mode-bin centre and variance definition adopted
by this probe-inference workflow. Each routine's input and statistical conventions
still apply.

[K04_breathing_waveform](K04_breathing_waveform/) contains the breathing-waveform extraction routines.
The [learning page](../docs/source/rst_files/K_Diagnostics/K04_breathing_waveform.rst) explains the method;
the [routine README](K04_breathing_waveform/README.en.md) describes the Python interface.
Artificial examples, local tests, plotting and cleanup live in
[`tests/011_K04_breathing_waveform`](../tests/011_K04_breathing_waveform/README.en.md), with running instructions.
K04 learns a phase-repeatable waveform from repeated single-point records and supplies residuals for later spectral analysis.

## Probe Wave Diagnostics: K01–K03

The [probe wave diagnostics topic](../docs/source/rst_files/K_Diagnostics/probe_wave_diagnostics.rst)
gives the K01 → K02 → K03 reading order. The problem and sign conventions
below apply to this probe diagnostic chain.

Each baseline constrains the wavevector projection along its direction through the measured phase difference. Summing the configurations' log likelihoods locates jointly supported wavevectors in the two-dimensional wavenumber plane. Baseline directions and lengths determine where the phase fringes intersect.

### Sign Convention for the Probe Diagnostic Chain

- Separation `chi = r_2 - r_1`, cross spectrum `C = X_1 conj(X_2)`.
- With the `exp(-i omega t)` forward transform of `numpy.fft.rfft`, a plane wave
  gives `theta = arg C = K . chi`, wrapped into `(-pi, pi]`.
- K03's forward model is that same `K . chi`, and K02 recovers the wavenumber as
  `k_par = wrap(theta)/|chi|`; the chain uses the same phase sign throughout.

When swapping the probe order, reverse the baseline vector as well. Reversing only
the cross phase while keeping the geometry unchanged mirrors the inferred wavevector.

## Usage

Python, source-level modules, no installation. Add the repository root to
`sys.path` and import as namespace packages.

The example below shows probe-based wavevector inference. The caller supplies
the input data and analysis parameters:

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
- [K04 tests and artificial examples](../tests/011_K04_breathing_waveform/README.en.md): checks breathing-cycle waveform extraction and provides running and figure-reproduction instructions.

The broadband page publishes figures, numerical tables, per-mode CSV and source hashes from one run. Its thresholds are engineering requirements for this fixed synthetic case, not universal accuracy guarantees.


## Provenance

- K01 implements segmented FFTs, cross spectra, power spectra, coherence and the
  mode-referenced phase statistics used by the current probe-inference workflow.
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
