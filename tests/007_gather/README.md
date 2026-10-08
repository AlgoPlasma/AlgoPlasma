# 007_gather

Gather-related regression tests for `C_Gather`.

The tests are split by module so each one can be built and run independently:

- `C01_gather_3Dxyz`: trilinear field gather and fused gather-push checks.
- `C02_gather_3Dxyz_bspline`: direct B-spline field gather checks.
- `C03_gather_3Draz_nonuniform`: staggered nonuniform cylindrical gather, convergence, and invalid-input checks.

Each subdirectory writes deterministic CSV data from Fortran and uses Python for
reference comparison and error statistics. C01/C02 also generate diagnostic
figures; C03 checks expected error exits and requires only the Python standard library.
