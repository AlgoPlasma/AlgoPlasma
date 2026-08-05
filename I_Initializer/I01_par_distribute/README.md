# I01_par_distribute

[中文](README.zh-CN.md) | [English](README.md)

`I01_par_distribute` provides Fortran-side particle distribution initialization.

## Files

- `mod_I01_par_distribute.f90`: module wrapper that exposes the initialization routine through `include`.
- `sub_I01_par_distribute_equilibrium.f90`: initializes exactly uniform in-cell positions and Maxwellian velocities.

## Main Interface

`sub_I01_par_distribute_equilibrium(par,nppc,il,iu,vt,vd)` fills `par(1:6,1:np)`:

- `par(1:3,:)`: `x,y,z` in normalized grid coordinates.
- `par(4:6,:)`: Maxwellian velocities with drift `vd` and thermal speed `vt`.

The caller must preallocate `par` and keep the particle count consistent with
`il`, `iu`, and `nppc`.

## Build

The module is organized with Fortran `include`; builds need preprocessing enabled
and this directory on the include path.
