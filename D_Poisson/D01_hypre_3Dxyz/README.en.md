# D01_hypre_3Dxyz

[中文](README.zh-CN.md) | [English](README.en.md)

Earlier Cartesian 3D Poisson/HYPRE interface. The Fortran side calls a C-side HYPRE Struct solver through a bridge subroutine.

## Files

- `mod_D01_hypre_3Dxyz_bc.f90`: Module wrapper.
- `sub_D01_hypre_3Dxyz_interface.f90`: Fortran-C bridge entry point.
- `fun_D01_hypre_3Dxyz_bc.c`: C/HYPRE Struct solver implementation.

## Main Interface

- `sub_D01_hypre_3Dxyz_interface(n, phi1d, rho1d, ilower, iupper, il0, iu0, tolerance, bc)`

`phi1d` is both the input initial guess and output potential, `rho1d` is the right-hand side, and `ilower:iupper` describes the local MPI-rank box.

## Dependencies

Requires MPI, HYPRE, and a mixed Fortran/C build environment. New code usually should use the D02 boundary-condition interface instead.
