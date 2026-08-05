# FDTD Stability Tests (No Source, Long Run)

This directory runs long no-source stability checks for core Maxwell kernels.
It is separate from MMS accuracy tests.

## Goals

- Long no-source integration and boundedness checks.
- Key monitors:
  - slow growth in `max_abs_E/H` and `total_energy`
  - near-axis accumulation (`axis_band_max`, `i0_active_max`)
  - first-ring amplification (`first_ring_max`, `i1_first_ring_max`)
- No MMS source injection. Do not call `add_e_source/add_h_source`.

## Covered Cases

- `test_stability_2d_rz_tmz.f90`
- `test_stability_2d_rz_tez.f90`
- `test_stability_3d_cyl_m0.f90`
- `test_stability_3d_cyl_m1.f90`

## Latest Baseline (`CFL=0.8`, `nsteps=20000`)

| case | final_energy_ratio | result |
|---|---:|---|
| 2D_RZ_TMz | 9.5997E-01 | stable |
| 2D_RZ_TEz | 1.0114E+00 | stable |
| 3D_CYL_M0 | 9.8467E-01 | stable |
| 3D_CYL_M1 | 9.4779E-01 | stable |

An older `3D_CYL_M1` run with generic outer ghost copy had energy growth
concentrated at the outer-radius boundary band (`i=nr-1`). The dominant
component was `Hz` (then `Hr`), not near-axis components.

## Boundary and Axis Handling

- No test uses PML/ABC.
- Cylindrical kernels use periodic handling along periodic directions:
  - `z` periodic
  - `phi` periodic (3D cylindrical)
- `r` keeps current axis closure plus outer ghost copy for ordinary components,
  with no extra boundary model.
- In the 3D cylindrical `m=1` test, the outer `Ephi` ghost is filled so that
  `r*Ephi` is continuous across the outer ghost cell.
- For `m=1` and TM, axis inactive DOFs (`Ephi/Hr` at `i=0`) are not divergence criteria.

Important for 3D cylindrical: the radial term in `Hz` uses a derivative of `r*Ephi`
(not only `Ephi`). Outer-radius ghost/closure must match this discretization.
Using `Ephi(nr)=Ephi(nr-1)` directly can cause slow growth for `m=1`.

An A/B check changed only the outer-radius `Ephi` ghost rule in the `m=1` stability test,
making it consistent with radius weighting. `final_energy_ratio` dropped from `3.9787`
to `9.4779E-01`, and `result` changed from `marginal` to `stable`.
This indicates the main issue is outer-radius radial ghost/closure, not axis terms.

## Build / Run / Clean

Run (default `nsteps=20000`, `monitor_every=100`):

```bash
bash make.sh
bash run.sh
```

Run (custom steps and monitor interval):

```bash
bash run.sh 50000 200
```

Clean: `bash clean.sh`

## Outputs

- One log per case: `logs/*.log`
- Summary file: `stability_summary.csv`

Columns in `stability_summary.csv`:

`case_name, CFL, nsteps, final_energy_ratio, max_abs_E_final, max_abs_H_final, result`

Allowed `result` values:

- `stable`
- `marginal`
- `unstable`

## Log Format

Monitor header:

```text
# step,time,max_abs_E,max_abs_H,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_first_ring_max
```

Extra columns for `m=1`:

```text
# step,time,max_abs_E,max_abs_H,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_first_ring_max,axis_near_Ez_max,axis_near_Hz_max
```

Sample row:

```text
200,2.430000E-01,9.812345E-05,8.456789E-05,1.603210E-08,1.204321E-05,9.876543E-06,7.654321E-06,8.765432E-06
```

Summary row (stdout):

```text
SUMMARY_CSV,3D_CYL_M1,0.800,20000,9.4779E-01,5.44E-05,5.92E-05,stable
```

## File List

Directory:

- `tests/005_maxwell/case_fdtd_stability`

Fortran files:

- `stability_common.f90`
- `test_stability_2d_rz_tmz.f90`
- `test_stability_2d_rz_tez.f90`
- `test_stability_3d_cyl_m0.f90`
- `test_stability_3d_cyl_m1.f90`

Scripts:

- `make.sh`
- `run.sh`
- `clean.sh`

## Notes

- These tests validate stability only, not convergence order.
- `case_fdtd_mms_convergence` remains independent in build and run flow.
