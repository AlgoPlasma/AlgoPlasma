# D02_hypre_3Dxyz_bc

[中文](README.zh-CN.md) | [English](README.en.md)

Cartesian 3D Poisson solver with matrix/RHS assembly, boundary corrections, and HYPRE Struct solve interfaces.

## Files

- `mod_D02_hypre_3Dxyz_bc.f90`: Module wrapper.
- `sub_D02_hypre_3Dxyz_bc_A.f90`: Assembles the Cartesian 7-point stencil matrix and RHS.
- `sub_D02_hypre_3Dxyz_bc_A_dielectric.f90`: Applies dielectric surface-charge boundary corrections.
- `sub_D02_hypre_3Dxyz_bc_A_outflow.f90`: Applies outflow/Robin boundary corrections.
- `sub_D02_hypre_3Dxyz_bc.f90` / `fun_D02_hypre_3Dxyz_bc.c`: Fortran-C HYPRE solve path.
- `sub_D02_hypre_3Dxyz_bc_fortran.f90`: Pure Fortran staged HYPRE Struct interface.

## Main Interface

Assemble `A_values` and `rho1d` first, then solve `phi1d` with either the C/HYPRE wrapper or the Fortran HYPRE interface.

## Dependencies

Requires MPI, HYPRE, and a Fortran/C build environment. The per-cell `A_values` order is `center, xmin, xmax, ymin, ymax, zmin, zmax`.
