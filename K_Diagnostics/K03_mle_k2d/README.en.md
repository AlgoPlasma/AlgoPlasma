# K03_mle_k2d

[中文](README.zh-CN.md) | [English](README.en.md)

`K03_mle_k2d` combines the phase measurements of several probe configurations
into one two-dimensional maximum-likelihood inversion, returning `(K_x, K_y)`
per frequency.  It is the stage that removes the aliasing: a single
configuration's likelihood is a family of parallel fringes, combining
configurations intersects those families, and different separation **lengths**
have incommensurate fringe periods, which fixes the fold order.

## Files

One routine per file, as elsewhere in the repository; `mod_` only aggregates.

| File | Purpose |
| --- | --- |
| `mod_K03_mle_k2d.py` | Module entry, collecting the routines of this unit. |
| `fun_K03_wavenumber_grid.py` | Uniform grid on `[-k_range, +k_range]`. |
| `fun_K03_predicted_phase.py` | The forward model `K . chi` on the grid. |
| `fun_K03_config_log_likelihood.py` | Log-likelihood of one configuration. |
| `fun_K03_joint_log_likelihood.py` | Sum over configurations. |
| `fun_K03_peak_wavevector.py` | Peak location, Cartesian and polar. |
| `fun_K03_search_wavevector.py` | Coarse search followed by a refinement. |

## Interface

| Function | Purpose |
| --- | --- |
| `fun_K03_wavenumber_grid(k_range_rad_m, n_grid)` | Uniform grid on `[-k_range, +k_range]`. |
| `fun_K03_predicted_phase(chi, kx_values, ky_values)` | The forward model `K . chi` on the grid. |
| `fun_K03_config_log_likelihood(chi, delta_theta, variance, kx_values, ky_values)` | Log-likelihood of one configuration. |
| `fun_K03_joint_log_likelihood(configurations, kx_values, ky_values, normalise=True)` | Sum over configurations. |
| `fun_K03_peak_wavevector(log_likelihood, kx_values, ky_values)` | Peak location, Cartesian and polar. |
| `fun_K03_search_wavevector(configurations, k_range_rad_m, ...)` | Coarse search over the whole range, then a refinement around the peak. |

Arrays are indexed `[iy, ix]`, matching the default ordering of
`numpy.meshgrid`.

## Likelihood

```
ln L_j(K) = -0.5 wrap(K.chi_j - theta_bar_j)^2 / sigma_j^2
ln L(K)   = sum_j ln L_j(K)
```

The forward model `K . chi` matches the cross-phase convention of
`K01_signal_spectra`, with no sign flip.

**The residual is wrapped before squaring.**  That step is not a numerical
convenience: it is what makes an aliased configuration contribute a periodic
family of fringes rather than one ridge, so the folded information stays in the
likelihood and can be resolved by the other configurations.

## Notes

- **Different separation lengths are required.**  With a single length every
  configuration has the same fringe period, the fold order stays undetermined,
  and the inversion cannot exceed that length's Nyquist wavenumber.  Changing
  only the orientation is not enough.
- **Search range.**  The estimate is confined to the grid, so `k_range` must
  contain the true wavevector; a peak on the boundary means the range was too
  narrow.  Grid discretisation puts a floor of half a grid step on the accuracy.
- **The variance is a single-sample variance.**  `K01` returns the variance of
  one segment sample.  With equal segment counts this is only an overall
  constant and does not move the peak; with unequal counts, weight by the
  variance of the mean, `sigma^2/n`.
- **Memory.**  The likelihood array holds `n_grid^2` float64 values: about
  1.3 MB at 401x401, accumulated configuration by configuration.
- **A wide band needs the two-stage search.**  One uniform grid must reach the
  largest wavevector while still resolving the smallest, and three decades would
  need thousands of points per axis.  `search_wavevector` searches coarse, then
  rebuilds a fine grid around the coarse peak.  The coarse stage only has to
  pick the right fringe.  Since the fringe period `2 pi/|chi|` decreases as the
  separation grows, the longest separation sets the smallest period and the
  strictest grid-spacing requirement.  Keep the coarse step well below that
  period; check this first if a result looks locked to the wrong fold.

## Usage

```python
import sys
sys.path.insert(0, "/path/to/AlgoPlasma")

from K_Diagnostics.K03_mle_k2d.mod_K03_mle_k2d import (
    fun_K03_joint_log_likelihood, fun_K03_peak_wavevector,
    fun_K03_wavenumber_grid,
)

grid = fun_K03_wavenumber_grid(k_range_rad_m=3300.0, n_grid=301)
configs = [(chi_j, delta_theta_j, variance_j) for ...]   # from K01
result = fun_K03_peak_wavevector(fun_K03_joint_log_likelihood(configs, grid, grid), grid, grid)
# result["kx"], result["ky"], result["k_magnitude"], result["angle_deg"]
```

## Tests

`tests/010_diagnostics/case_broadband_dispersion`: 35 configurations jointly invert 80
frequencies whose wavenumbers span 171 to 3286 rad/m.  The criterion is a
straight line through the origin fitted to `f` against `|k_hat|`, whose slope
must return the ion sound speed used to build the signals — a physical constant,
not a chosen tolerance.

| Quantity | Measured |
| --- | --- |
| Fitted ion sound speed | 3829.6 m/s (true 3824.6, relative error **1.3e-3**) |
| `\|k\|` relative error | median 0.28 %, p95 0.83 % |
| Direction error | median 0.26 deg, p95 0.62 deg |

The same data that K02 shows folded into a sawtooth on a single pair is
recovered here as a straight branch.

## Provenance

This implementation follows the multi-configuration Bayesian spatial
anti-aliasing method of Liu and Jorns.

## References

- M. F. Liu and B. A. Jorns, "Anti-aliasing technique for inferring dispersion
  of short-wavelength instabilities in electric propulsion devices," AIAA
  SciTech Forum, Paper AIAA-2025-1293 (2025),
  [doi:10.2514/6.2025-1293](https://doi.org/10.2514/6.2025-1293).
- M. F. Liu and B. A. Jorns, "Experimental validation of a spatial
  anti-aliasing plasma wave analysis technique on ion acoustic turbulence in a
  hollow cathode plume," 39th International Electric Propulsion Conference,
  Paper IEPC-2025-357 (2025).
