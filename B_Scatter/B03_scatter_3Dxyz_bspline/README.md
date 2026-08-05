# B03_scatter_3Dxyz_bspline

[中文](README.zh-CN.md) | [English](README.md)

`B03_scatter_3Dxyz_bspline` performs arbitrary-order centered B-spline
particle deposition on a 3D Cartesian grid. It uses the same family of 1D
B-spline shape functions as `C_Gather/C02_gather_3Dxyz_bspline`, but in the
opposite direction: C02 gathers grid data to particles, while B03 scatters
particle data to the grid.

## Files

- `mod_B03_scatter_3Dxyz_bspline.f90`: B03 module entry, including the top-level deposition routines and helpers.
- `sub_B03_scatter_3Dxyz_bspline.f90`: top-level 3D tensor-product B-spline number deposition.
- `sub_B03_scatter_3Dxyz_bspline_v.f90`: top-level 3D tensor-product B-spline particle-component deposition.
- `sub_B03_bspline_stencil_1d.f90`: builds `order+1` grid indices and weights in one direction.
- `fun_B03_bspline_shape.f90`: recursively evaluates the centered B-spline shape function.

## Main Interface

```fortran
call sub_B03_scatter_3Dxyz_bspline(il,iu,den,np,par,w,order)
call sub_B03_scatter_3Dxyz_bspline_v(il,iu,den,np,par,d,w,order)
```

- `sub_B03_scatter_3Dxyz_bspline`: deposits `1*w` per particle, useful as the base operation for number-density or charge-density deposition.
- `sub_B03_scatter_3Dxyz_bspline_v`: deposits `par(d,p)*w` per particle, useful for one selected particle-array component.
- `order=1`: reduces to the B01 CIC/trilinear deposition.

The caller should normally zero `den` before the call. This routine does not
handle boundary conditions, periodic endpoints, or guard-cell exchange.

## Compilation Note

The module uses `#include` to collect source files, so Fortran preprocessing is
required, for example:

```bash
gfortran -cpp -O2 -fopenmp your_program.f90
```
