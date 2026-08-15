# E_Maxwell

[中文](README.zh-CN.md) | [English](README.en.md)

`E_Maxwell` contains AlgoPlasma subroutines for advancing Maxwell fields, finite-difference time-domain (FDTD) implementations, and convolutional perfectly matched layer (CPML) boundary extensions.

## Subdirectories

- `E01_Maxwell_2Drz`: 2D axisymmetric cylindrical `(r,z)` TE/TM FDTD and CPML.
- `E02_Maxwell_3Drtz`: Full 3D cylindrical `(r,phi,z)` FDTD and CPML.
- `E03_Maxwell_3Dxyz`: 3D Cartesian `(x,y,z)` FDTD and CPML.

## Usage Notes

- These routines are low-level field-advance and boundary-update kernels, not a full solver framework.
- The caller owns array allocation, boundary/ghost fill, sources, diagnostics, MPI exchange, and the time-step loop.
- Module wrappers use `#include` to collect subroutines; enable Fortran preprocessing if your compiler does not preprocess `.f90` automatically.
- Most source uses default `real`; double precision is normally selected project-wide at compile time, for example with `-fdefault-real-8`.

## Dependencies

These kernels are Fortran field-advance and boundary-update routines. The caller owns array allocation, boundary/ghost fill, sources, diagnostics, and the time-step loop.

## Documentation

Full formulas, learning path, usage cookbook, CPML cookbook, and test notes live in the Sphinx `E_Maxwell` page.
