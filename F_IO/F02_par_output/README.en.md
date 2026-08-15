# F02_par_output

[中文](README.zh-CN.md) | [English](README.en.md)

Writes each MPI rank's particle array `par(:,1:np)` to a separate file.

## Files

- `mod_F02_par_output.f90`: module wrapper.
- `sub_F02_par_output.f90`: `dat/bin/h5/hdf5` dispatcher.
- `sub_F02_par_output_dat.f90`: ASCII writer.
- `sub_F02_par_output_bin.f90`: stream binary writer.
- `sub_F02_par_output_h5.f90`: HDF5 writer guarded by `USE_HDF5=1`.

## Notes

`label` is both the directory name and file prefix, so use a simple name
without `/`.
