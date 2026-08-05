# F01_par_load

[中文](README.zh-CN.md) | [English](README.md)

Loads each MPI rank's particle file into `par(:,1:np)`.

## Files

- `mod_F01_par_load.f90`: module wrapper.
- `sub_F01_par_load.f90`: `dat/bin/h5/hdf5` dispatcher.
- `sub_F01_par_load_dat.f90`: ASCII reader.
- `sub_F01_par_load_bin.f90`: stream binary reader.
- `sub_F01_par_load_h5.f90`: HDF5 reader guarded by `USE_HDF5=1`.
- `sub_F01_par_load_count.f90`: infers the current rank's particle count; the subroutine name is `sub_F01_load_par_count`.

## Notes

`dat/bin` particle files do not store universal header metadata; callers provide
`np` and a sufficiently large `par` buffer.
