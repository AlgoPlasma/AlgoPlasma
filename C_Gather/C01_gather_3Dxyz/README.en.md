# C01_gather_3Dxyz

[中文](README.zh-CN.md) | [English](README.en.md)

`C01_gather_3Dxyz` interpolates 3D Cartesian electromagnetic fields from a
cell-centered grid to particle positions. It also provides a fused kernel that
gathers fields and immediately advances particles with a non-relativistic Boris
update.

## Files

| File | Role |
| --- | --- |
| `mod_C01_gather_3Dxyz.f90` | Source-level Fortran module entry. |
| `sub_C01_gather_3Dxyz.f90` | Trilinearly interpolates `Ex,Ey,Ez,Bx,By,Bz` to one particle. |
| `sub_C01_gather_3Dxyz_push.f90` | Loops over particles, gathers fields, performs a Boris velocity update, and advances positions. |

## Interfaces

```fortran
call sub_C01_gather_3Dxyz(p, np, par, il, iu, Ex, Ey, Ez, Bx, By, Bz, E, B)
call sub_C01_gather_3Dxyz_push(np, par, il, iu, Ex, Ey, Ez, Bx, By, Bz, q, m, dt)
```

`dt` in `sub_C01_gather_3Dxyz_push` is optional and defaults to `1.0`.

## Usage

```fortran
#include "C_Gather/C01_gather_3Dxyz/mod_C01_gather_3Dxyz.f90"

program demo_c01
    use mod_C01_gather_3Dxyz
    implicit none

    ! Allocate and fill par, il, iu, Ex, Ey, Ez, Bx, By, Bz before calling.
end program demo_c01
```

Compilation usually requires C preprocessing:

```bash
gfortran -cpp -O2 demo_c01.f90
```
