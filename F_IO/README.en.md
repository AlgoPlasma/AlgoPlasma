# F_IO

[中文](README.zh-CN.md) | [English](README.en.md)

`F_IO` is AlgoPlasma's MPI per-rank data input/output layer for particle phase-space
arrays and local field arrays.

## Subdirectories

- `F01_par_load`: loads per-rank particle files and provides a local particle-count helper.
- `F02_par_output`: writes per-rank particle phase-space arrays.
- `F03_field_load`: reads 1D packed or 3D cell-centered field files written by F04.
- `F04_field_output`: writes 1D, 3D, or grid-to-cell averaged field files.

## Dependencies

- All submodules depend on MPI.
- Particle HDF5 paths require the HDF5 Fortran bindings and `USE_HDF5=1` at compile time.
- Binary files use Fortran unformatted stream I/O; readers and writers should use matching default `integer`/`real` sizes and endianness.

## File Convention

The default name is `label/label_IIIIIIIIII_RRRRR.ext`. `label` should be a
simple name and should not contain `/`.
