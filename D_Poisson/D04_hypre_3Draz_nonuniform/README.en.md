# D04_hypre_3Draz_nonuniform

[中文](README.zh-CN.md) | [English](README.en.md)

Nonuniform cylindrical `(r,alpha,z)` 3D Poisson solver. It uses the same HYPRE Struct/PFMG solve pattern as D03, but matrix coefficients come from local nonuniform mesh spacing.

## Files

- `mod_D04_hypre_3Draz_nonuniform.f90`: Module wrapper.
- `sub_D04_hypre_3Draz_nonuniform.f90`: HYPRE Struct solve driver.
- `sub_D04_hypre_3Draz_nonuniform_A.f90`: Single-domain nonuniform-grid matrix/RHS assembly.
- `sub_D04_hypre_3Draz_nonuniform_A_mpi.f90`: MPI-local matrix/RHS assembly with ghost layers.
- `sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric.f90`: Dielectric boundary correction.
- `sub_D04_hypre_3Draz_nonuniform_bc_A_outflow.f90`: Outflow/Robin boundary correction.

## Main Interface

Assembly routines produce `A_values` and `RHS` consistent with the HYPRE Struct box. The MPI version requires correct owned-cell ranges, ghost layers, and neighbor flags from the caller.

## Dependencies

Requires MPI, HYPRE, and a Fortran build environment. Nonuniform grid arrays and local boxes must remain consistent.
