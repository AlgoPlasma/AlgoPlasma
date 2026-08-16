# G01_MCC

[中文](README.zh-CN.md) | [English](README.en.md)

`G01_MCC` is a null-collision Monte Carlo Collision module.

## Files

- `mod_G01_collision.f90`: module wrapper including the G01 routines in this directory.
- `sub_G01_load_cross_section.f90`: reads two-column energy/cross-section tables.
- `fun_G01_cross_section.f90`: linearly interpolates uniformly spaced energy tables.
- `sub_G01_collision1.f90`: electron-neutral MCC for elastic scattering, excitation, and ionization.
- `sub_G01_collision2.f90`: ion-neutral MCC for charge exchange and ion-neutral scattering.
- `sub_G01_electron.f90`: samples electron scattering, energy loss, and secondary-particle velocities.

## Main Interfaces

- `sub_G01_load_cross_section(Nmax,cross_section,path)`
- `fun_G01_cross_section(energy,Nmax,cross_section)`
- `sub_G01_collision1(...)`
- `sub_G01_collision2(...)`
- `sub_G01_electron(...)`

## Notes

Cross-section energy grids should be uniformly spaced. `sub_G01_collision1` and
`sub_G01_collision2` use MPI reductions for the global maximum collision
frequency, so callers must provide valid particle-array capacity and density
grid bounds.
