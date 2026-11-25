# J02 CEX Coefficient Tests

[简体中文](README.zh-CN.md)

Verify the cell-local CEX coefficients in the [J02 neutral transport module](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/README.md):
ion distribution and relative speed → collision energy and cross section → collision kernel → loss frequency and loss per unit path length.
The tests use a fixed ion background and synthetic cross sections for the current reduced 2D2V model.
Collision gain and coupling to spatial transport require separate implementations.

## Environment and commands

Bash and GNU Fortran are required. Run from the repository root:

```bash
bash tests/012_fluid/J02_neutral_sn_transport_2Drz/cex_coefficients/run.sh
```

The script builds one test program with default real promoted to 8 bytes, array checks,
invalid/zero/overflow floating-point traps and compiler warnings.
Use `FC` to select a compatible compiler; the first positional argument selects the build directory.

## Files and interfaces

| File | Purpose |
| --- | --- |
| [run.sh](run.sh) | Build and run the standalone coefficient test |
| [test_J02_cex_coefficients.f90](../source_f90/test_J02_cex_coefficients.f90) | Three analytical checks and error assertions |
| [sub_J02_sn_relative_speed.f90](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_relative_speed.f90) | Relative speed and velocity conversion |
| [sub_J02_sn_reaction_kernel.f90](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reaction_kernel.f90) | Cross-section tables, energy conversion and pair kernels |
| [sub_J02_sn_cex.f90](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_cex.f90) | Ion-distribution normalization and frequency summation |

The following fragment shows the call sequence. Check `ierr == SN_SUCCESS` after each call before using its outputs:

```fortran
type(sn_reaction_table_type) :: table

! energy_table: eV; sigma_table: m^2.
call sub_J02_initialize_reaction_table(energy_table, sigma_table, &
    SN_REACTION_ENERGY_CM, SN_REACTION_RANGE_ERROR, table, ierr)
call sub_J02_build_ion_maxwellian(ion_quadrature, ion_density, ion_temperature, ion_mass, &
    drift_velocity_r, drift_velocity_z, ion_distribution, ierr)
call sub_J02_compute_cex_frequency(neutral_quadrature, ion_quadrature, ion_distribution, &
    neutral_mass, ion_mass, table, frequency, sigma_t, ierr)
```

- Number density is in m^-3, positive temperature in K, mass in kg and velocity in m/s.
  `ion_distribution` already includes density and satisfies `sum(ion_quadrature%weight*ion_distribution)=ion_density`.
  A nonnegative discrete distribution may also be supplied directly. This normalization fixes density;
  the accuracy of other moments depends on the velocity grid.
- Neutral and ion velocity nodes may differ, but both must use the same local orthonormal basis.
  Ion-distribution nodes with zero quadrature-weighted population do not contribute to the sum.
- `frequency(m)=sum_j w_j*f_i,j*sigma(g_mj)*g_mj` has units s^-1;
  `sigma_t(m)=frequency(m)/v_m` has units m^-1. Outputs can be stored per spatial cell;
  the computation accumulates contributions node by node.
- Table energies are in eV and cross sections in m^2, with linear interpolation.
  `SN_REACTION_ENERGY_CM` uses reduced mass;
  `SN_REACTION_ENERGY_PROJECTILE_LAB` uses projectile mass in the stationary-target frame.
  The generic kernel takes `projectile_mass,target_mass`; the CEX entry takes
  `neutral_mass,ion_mass` and explicitly selects the ion as projectile internally.
- Outside the energy table, `SN_REACTION_RANGE_ERROR` returns an error;
  `SN_REACTION_RANGE_CLAMP` selects an endpoint cross section.
  Applications must supply cross sections with documented units, energy convention and validity range.

The generic binary-reaction kernel can be called separately:

```fortran
relative_speed = fun_J02_relative_speed(velocity_a, velocity_b)
call sub_J02_evaluate_reaction_kernel(table, projectile_mass, target_mass, relative_speed, &
    energy_ev, cross_section_m2, kernel, ierr)
```

Here `kernel = cross_section_m2 * relative_speed` has units m^3/s.
The routine returns properties for one velocity-node pair; the CEX summation performs the distribution average.

## Checks and acceptance criteria

| Check | Reference and criterion |
| --- | --- |
| Energy, cross section and collision kernel | Compare a synthetic linear cross section with hand calculations; check center-of-mass and projectile-lab energy separately, with relative errors at most `1e-12` |
| Ion-background normalization | Recover prescribed density on a nonuniform velocity grid within relative error `1e-12`; require a nonnegative distribution and zero distribution at zero density |
| Frequency and transport loss coefficient | Use `n_i*sigma0*g` for a single ion node and an independent sum for the Maxwellian background; also check `sigma_t=frequency/v`, with relative errors at most `1e-12` |

Further assertions cover out-of-range table queries, kernel overflow, negative ion backgrounds and output state after failure.
These tests verify coefficient implementation; quantitative Xe CEX prediction requires validated cross sections and background data.

## Outputs

The default build directory is `build/cex_coefficients/` under the parent test directory.
It contains module files and `test_cex.out`. Results are printed to the terminal:
success reports three `PASS` groups and a final `RESULT: PASS`; failure returns a nonzero status.
The script produces no CSV files or figures. Reruns overwrite matching build files and retain other files in the directory.

See the [J02 test overview](../README.md) for the complete test entry points.
