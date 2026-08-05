# B01_scatter_3Dxyz

[中文](README.zh-CN.md) | [English](README.md)

3D Cartesian PIC particle-deposition utilities. This directory provides CIC
number-density and quantity deposition, NGP per-cell variance statistics, and
MPI ghost-cell exchange after deposition.

## Files

- `mod_B01_scatter_3Dxyz.f90`: B01 module entry point for the basic CIC routine.
- `sub_B01_scatter_3Dxyz.f90`: Deposits unit particle weight to eight
  neighboring nodes with CIC weights.
- `sub_B01_scatter_3Dxyz_v.f90`: Deposits `par(d,p)` to the grid with CIC weights.
- `sub_B01_scatter_3Dxyz_T.f90`: Computes per-cell variance of `par(d,p)` with a
  two-pass NGP assignment.
- `sub_B01_scatter_3Dxyz_mpi_exchange.f90`: Handles periodic endpoints and MPI
  halo contribution exchange.

## Public Interfaces

```fortran
call sub_B01_scatter_3Dxyz(il, iu, den, np, par, w)
call sub_B01_scatter_3Dxyz_v(il, iu, den, np, par, w, d)
call sub_B01_scatter_3Dxyz_T(il, iu, T, np, par, d)
call sub_B01_scatter_3Dxyz_mpi_exchange(il, iu, den, mpi_n, rank_to_ijk, &
    domain_split, ijk_to_rank, l)
```

`par(1:3,p)` stores particle positions in grid units. Zero output arrays before
calling the deposition routines.

## Compile Notes

Module entry files and MPI exchange code usually require preprocessing, such as
`-cpp` or `-fpp`. If the application uses double-precision default reals, compile
the main program and these sources consistently with `-fdefault-real-8` or
`-real-size 64`.
