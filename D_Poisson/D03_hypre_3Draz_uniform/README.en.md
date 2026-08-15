# D03_hypre_3Draz_uniform

[中文](README.zh-CN.md) | [English](README.en.md)

Uniform cylindrical `(r,alpha,z)` 3D Poisson solver. It uses HYPRE Struct/PFMG to solve the 7-neighbor system assembled by the D03 routines.

## Files

- `mod_D03_hypre_3Draz_uniform.f90`: Module wrapper.
- `sub_D03_hypre_3Draz_uniform.f90`: HYPRE Struct solve driver.
- `sub_D03_hypre_3Draz_uniform_A.f90`: Single-domain uniform-grid matrix/RHS assembly.
- `sub_D03_hypre_3Draz_uniform_A_mpi.f90`: MPI-local matrix/RHS assembly.
- `sub_D03_hypre_3Draz_uniform_bc_A_dielectric.f90`: Dielectric boundary correction.
- `sub_D03_hypre_3Draz_uniform_bc_A_outflow.f90`: Outflow/Robin boundary correction.

## Main Interface

Assembly routines produce `A_values` and `RHS`; the solve driver uses staged flags to initialize HYPRE objects, update the matrix, solve, and release resources.

## Dependencies

Requires MPI, HYPRE, and a Fortran build environment. The uniform grid is described by scalar `dr`, `da`, and `dz`.
