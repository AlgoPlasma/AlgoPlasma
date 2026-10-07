# J03_neutral_continuity_faceflux_2Drz

[中文](README.zh-CN.md) | [English](README.en.md)

J03 initializes fixed face transport coefficients from reference density and signed fluxes, evaluates current fluxes with upwind density, and advances transient cylindrical continuity. It does not track particles, solve velocity distributions or rerun preprocessing.

A face coefficient has velocity units but is not a cell mean velocity. Any reference-field method satisfying the geometry, array and sign conventions can supply the inputs.

## Files

| File | Responsibility |
| --- | --- |
| `mod_J03_neutral_continuity_faceflux_2Drz.f90` | Closure type, face constants, status codes and includes |
| `sub_J03_transport_closure.f90` | Geometry/topology checks, reference copies and face coefficients |
| `sub_J03_continuity_solver.f90` | Current flux, stable timestep, transient step, diagnostics and optional steady solve |
| `sub_J03_error.f90` | Status-to-message conversion |

## Transient sequence

1. Initialize once with `sub_J03_initialize_transport_closure` and check status.
2. Choose physical initial density and time separately.
3. Update `source_rate`, `closure%loss_frequency` and `closure%boundary_inflow_flux` each step.
4. Obtain a conservative bound from `sub_J03_compute_stable_timestep`; also enforce physical time resolution.
5. Call `sub_J03_continuity_step`, check step balance, then advance the application clock.

The update is `n_new=(n_old-dt*div(flux_old)+dt*S)/(1+dt*nu)`, with production `S` in m⁻³s⁻¹ and removal frequency `nu` in s⁻¹. Discrete transient balance uses old-density outflow and new-density removal, not zero net rate.

The step does not enforce its stability bound or reject a negative updated density. Optional clipping changes total particle number. Callers must also check finite nonnegative reference density and physical boundary-flux signs.

## Other interfaces and limits

- `sub_J03_compute_residual` and `sub_J03_compute_balance` return local residuals and global particle rates.
- `sub_J03_solve_steady` iterates fixed conditions with both change and scaled-residual criteria; it does not replace a physical-time loop.
- All reference-field sources use `sub_J03_initialize_transport_closure`.
- Changing reference fields or geometry requires reinitialization; editing stored reference arrays alone does not update coefficients.
- The current solver is single-domain, without MPI exchange or result gathering.

## Build and documentation

Compile the module with preprocessing and the local include path, not the included implementation files. Keep real precision consistent with callers.

Sphinx [J03](../../docs/source/rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz.rst) contains derivations, routine inputs/outputs, a complete calculation and error handling. Commands and assertions are in [J03 tests](../../tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/README.md).
