# J_Fluid

[中文](README.zh-CN.md) | [English](README.md)

`J_Fluid` contains AlgoPlasma fluid-equation update routines.

## Subdirectories

- `J01_continuity_freeflow`: advances the free-flow continuity equation with a three-dimensional Lax-Friedrichs finite-volume scheme.

## Conventions

- Grid spacing and time step use the normalized convention `dx=dy=dz=dt=1`.
- `ux`, `uy`, `uz`, and `s` are cell-centered arrays.
- Boundary conditions and guard/ghost cells must be set before calling the update routine.

## Documentation

Detailed numerical schemes, index conventions, and API notes live in the Sphinx
`J_Fluid` pages.
