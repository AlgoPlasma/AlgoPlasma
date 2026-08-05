# FDTD MMS Accuracy and Convergence Tests

This directory validates the core Maxwell kernels with MMS convergence tests.
It does not include CPML, particles, current sources, collisions, or filtering.

## Cases

- `test_mms_3d_cartesian_convergence.f90`: 3D Cartesian periodic MMS, grids `16^3`, `32^3`, `64^3`
- `test_mms_2d_rz_tmz_convergence.f90`: 2D RZ TMz MMS, grids `(20,32)`, `(40,64)`, `(80,128)`
- `test_mms_3d_cyl_m0_convergence.f90`: 3D cylindrical `m=0` MMS, grids `(20,16,32)`, `(40,16,64)`, `(80,16,128)`
- `test_mms_2d_rz_tez_convergence.f90`: 2D RZ TEz MMS, grids `(20,32)`, `(40,64)`, `(80,128)`
- `test_mms_3d_cyl_m1_convergence.f90`: 3D cylindrical `m=1` MMS, grids `(20,16,32)`, `(40,32,64)`, `(80,64,128)`

## Shared Settings

- Fixed CFL across all resolutions with the same physical end time `T`.
- Production kernels are used:
  - `mod_E03_fdtd_3d_cartesian`
  - `mod_E01_fdtd_2d_rz_tmz`
  - `mod_E01_fdtd_2d_rz_tez`
  - `mod_E02_fdtd_3d_cylindrical`
- Exact fields and source terms are defined in `mms_exact_sources.f90`.
- Exact and numerical fields are compared at native staggered locations.
- Reports include component-wise and combined `L2/Linf` errors and observed order.
- RZ and cylindrical norms use `r` weighting and report `axis_band_Linf`.

Recommended pass thresholds (already enforced in code with `RESULT: PASS/FAIL`):

- `L2 observed order >= 1.8`
- `Linf observed order >= 1.5`

## Build / Run / Clean

```bash
bash make.sh
bash run.sh
bash clean.sh
```

## Latest Summary

Run date: `2026-04-07`

| Case | Combined L2 (coarse/mid/fine) | L2 order (1->2, 2->3) | Combined Linf (coarse/mid/fine) | Linf order (1->2, 2->3) | axis_band_Linf (coarse/mid/fine) | Result |
|---|---|---|---|---|---|---|
| 3D Cartesian periodic MMS | `9.819e-04, 2.427e-04, 6.030e-05` | `2.017, 2.009` | `4.298e-03, 1.101e-03, 2.765e-04` | `1.965, 1.993` | `N/A` | `PASS` |
| 2D RZ TMz MMS | `4.467e-05, 1.106e-05, 2.752e-06` | `2.014, 2.007` | `1.289e-04, 3.256e-05, 8.191e-06` | `1.985, 1.991` | `1.355e-05, 1.674e-06, 2.456e-07` | `PASS` |
| 3D cylindrical m=0 MMS | `1.725e-05, 4.270e-06, 1.062e-06` | `2.015, 2.007` | `5.326e-05, 1.342e-05, 3.369e-06` | `1.988, 1.994` | `3.448e-05, 8.619e-06, 2.155e-06` | `PASS` |
| 2D RZ TEz MMS | `5.592e-05, 1.382e-05, 3.437e-06` | `2.016, 2.008` | `1.332e-04, 3.332e-05, 8.338e-06` | `1.999, 1.999` | `1.313e-04, 3.281e-05, 8.200e-06` | `PASS` |
| 3D cylindrical m=1 MMS (`nphi=16,32,64`) | `2.077e-05, 5.123e-06, 1.282e-06` | `2.019, 1.998` | `1.193e-04, 3.019e-05, 7.622e-06` | `1.983, 1.986` | `1.193e-04, 2.968e-05, 6.830e-06` | `PASS` |

Detailed component-wise logs:

- `test_mms_3d_cartesian_convergence.log`
- `test_mms_2d_rz_tmz_convergence.log`
- `test_mms_2d_rz_tez_convergence.log`
- `test_mms_3d_cyl_m0_convergence.log`
- `test_mms_3d_cyl_m1_convergence.log`

## Error Hotspots

- 3D Cartesian: worst points are distributed in the domain, not at one single point.
- 2D RZ TMz: worst point was around `Ez(i=0,k=0)` in a boundary band.
- 3D cylindrical m=0: worst point was around `Ephi(i=0,j=1,k=nz/2)` near the axis band.

## Recomputed With Consistent Active DOFs (2026-04-07)

1. 2D RZ TMz norms were limited to updated indices only:
   - `Er/Ez` on `i=0..nr-1, k=1..nz-1`
   - New observed orders: `L2 = 2.014, 2.007`, `Linf = 1.985, 1.991`, `RESULT: PASS`

2. 3D cylindrical m=0 excluded axis replacement DOFs from norms:
   - Excluded `Ephi(i=0,*,*)` and `Hr(i=0,*,*)`
   - New observed orders: `L2 = 2.015, 2.007`, `Linf = 1.988, 1.994`, `RESULT: PASS`

## Notes for TM and m=1

- There is no "3D Cartesian m=1" case in this directory. `m` is for cylindrical modal expansion.
- For 2D RZ TEz (`Ephi/Hr/Hz`), exact sampling, source sampling, and error ranges must match update loops.
- For 3D cylindrical `m=1`, `nphi` must be refined with the grid (`16 -> 32 -> 64`).
- Axis `Ez(i=0,*,*)` is updated by the axis closure term `4*dt/(ep*dr)*axis_hphi_avg`; source injection must skip axis `Ez`.
