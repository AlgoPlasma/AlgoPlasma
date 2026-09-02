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

## The Problem This Module Solves

A single probe pair measures only the projection of the wavevector onto its
separation, and only modulo `2 pi` of phase.  Once the wavelength drops below
twice the spacing, the pair therefore reports a **folded, false wavenumber**: a
straight dispersion branch appears broken into a sawtooth on the `S(k, f)` map.
K02 supplies the closed-form geometry of that limit and makes it visible; K03
removes it by combining separations of several **lengths**.  Changing only the
orientation is not enough — different lengths give incommensurate fringe
periods, and that is what fixes the fold order.

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

NumPy is the only dependency.  None of the three units performs **any file
I/O** — reading raw data and writing results are the caller's responsibility,
and computation happens only in the test's main program.

## Tests

[`tests/010_diagnostics/case_broadband_dispersion/`](../tests/010_diagnostics/case_broadband_dispersion/):
one synthetic broadband dataset drives all three units and produces four
figures.  The criteria come from the generator rather than from chosen
tolerances — the central one being that **fitting the recovered dispersion
branch through the origin must return the ion sound speed used to build the
signals**, measured at a relative error of 1.3e-3.

```bash
cd tests/010_diagnostics/case_broadband_dispersion && bash run.sh
```

## Provenance

- K01 and K03 migrated from [`simulation/simulation_liu`](../../the-world-of-king-peng-zilong/simulation/simulation_liu/),
  following the anti-aliasing wavevector method of Liu & Jorns (IEPC-2025-357).
- K02 migrated from [`core/beall`](../../the-world-of-king-peng-zilong/core/beall/).
- The synthetic signal used by the test is taken from
  `simulation/simulation_beall/02宽频`, under `/mnt/d/波探针原始数据/simulation/`.

## References

- Liu and Jorns, IEPC-2025-357 (2025).  Taken from source comments; the author
  initials are not given there and should be completed before formal citation.
- J. M. Beall, Y. C. Kim, and E. J. Powers, "Estimation of wavenumber and
  frequency spectra using fixed probe pairs," J. Appl. Phys. **53**(6),
  3933–3940 (1982).
