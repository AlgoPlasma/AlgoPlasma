# K03_mle_k2d

[中文](README.zh-CN.md) | [English](README.en.md)

Each baseline constrains the wavevector projection along its direction through the measured phase difference. Summing the configurations' log likelihoods locates jointly supported wavevectors in the two-dimensional wavenumber plane. Baseline directions and lengths determine where the phase fringes intersect.

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
| `fun_K03_search_wavevector.py` | Exhaustive uniform-grid search in row blocks. |

## Interface

| Function | Purpose |
| --- | --- |
| `fun_K03_wavenumber_grid(k_range_rad_m, n_grid)` | Uniform grid on `[-k_range, +k_range]`. |
| `fun_K03_predicted_phase(chi, kx_values, ky_values)` | The forward model `K . chi` on the grid. |
| `fun_K03_config_log_likelihood(chi, delta_theta, variance, kx_values, ky_values)` | Log-likelihood of one configuration. |
| `fun_K03_joint_log_likelihood(configurations, kx_values, ky_values, normalise=True)` | Sum over configurations. |
| `fun_K03_peak_wavevector(log_likelihood, kx_values, ky_values)` | Peak location, Cartesian and polar. |
| `fun_K03_search_wavevector(configurations, k_range_rad_m, ...)` | Exhaustive uniform-grid search in row blocks. |

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

- **Geometry.** Each baseline constrains the wavevector projection along its direction through the measured phase difference. Summing the configurations' log likelihoods locates jointly supported wavevectors in the two-dimensional wavenumber plane. Baseline directions and lengths determine where the phase fringes intersect.
- **Search range.**  The estimate is confined to the grid, so `k_range` must
  contain the true wavevector; a boundary peak warrants a range check.  Grid discretisation puts a floor of a resolution-dependent limitation on accuracy.
- The variance describes segment-phase scatter and scales the phase residual in the likelihood. Vary sample count and histogram binning to assess the stability of the mode estimate.
- **Memory.**  The likelihood array holds `n_grid^2` float64 values: about
  1.3 MB at 401x401, accumulated configuration by configuration.
- Build a uniform grid over the chosen two-dimensional wavenumber range, evaluate the joint log likelihood at every point, and report the wavevector at its maximum. n_grid sets the number of points per axis; block_rows sets the number of rows evaluated in each batch.

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

- [basic_numerical tests](../../tests/010_diagnostics/case_basic_checks/): deterministic analytic checks, including power normalization, phase statistics, Beall accumulation and variance-weighted inversion.
- [broadband_dispersion](../../tests/010_diagnostics/case_broadband_dispersion/): generated waveforms drive K01–K03. Acceptance checks the aggregate dispersion and every selected wavevector, including boundary and tie flags.

The broadband page publishes figures, numerical tables, per-mode CSV and source hashes from one run. Its thresholds are engineering requirements for this fixed synthetic case, not universal accuracy guarantees.


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
