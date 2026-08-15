# B_Scatter

[中文](README.zh-CN.md) | [English](README.en.md)

`B_Scatter` contains AlgoPlasma particle-to-grid deposition operators.

## Subdirectories

- `B01_scatter_3Dxyz`: CIC/NGP-style number-density, momentum-density, and statistical deposition on a 3D Cartesian `xyz` grid.
- `B02_deposit_3d_cyl`: charge-density and current-density deposition on a 3D cylindrical `r,phi,z` grid, including axis averaging.
- `B03_scatter_3Dxyz_bspline`: arbitrary-order B-spline number and particle-component deposition on a 3D Cartesian `xyz` grid.

## Conventions

- Particle arrays usually use `par(1:6,1:np)`, where `1:3` are positions and `4:6` are velocities or other particle components.
- B01 and B03 target Cartesian grids; B02 targets cylindrical grids and handles the `r=0` axis degeneracy.
- Sources use default `real`; double-precision default reals should be selected consistently with `-fdefault-real-8` or `-real-size 64`.
- Entry points using `include` or MPI exchange normally require Fortran preprocessing, for example `-cpp` or `-fpp`.

## Tests

Related tests live under `tests/004_scatter` and in the Sphinx `004_scatter`
test overview page.
