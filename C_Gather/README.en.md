# C_Gather

[中文](README.zh-CN.md) | [English](README.en.md)

`C_Gather` contains grid-to-particle interpolation routines used in PIC-style
particle loops. These routines evaluate grid-based field quantities or shape
function weights at particle positions.

## Components

| Directory | Role |
| --- | --- |
| `C01_gather_3Dxyz` | Trilinear gather of 3D Cartesian electric and magnetic fields, plus a fused gather-and-push kernel. |
| `C02_gather_3Dxyz_bspline` | Direct B-spline gather of 3D Cartesian electric and magnetic fields. |

## Usage Notes

The routines are organized as source-level Fortran modules. A caller normally
includes the corresponding `mod_*.f90` entry file and uses the exported module.
Compilation usually requires C preprocessing because module files include the
subroutine sources with `#include`.

```bash
gfortran -cpp -O2 demo_gather.f90
```

The source uses default `real`. If double precision is required, choose the
compiler option at build time, for example `-fdefault-real-8` for `gfortran` or
`-real-size 64` for Intel Fortran.
