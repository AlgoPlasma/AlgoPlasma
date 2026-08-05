# F03_field_load

[中文](README.zh-CN.md) | [English](README.md)

Reads local field files written by F04 for 1D packed and 3D cell-centered layouts.

## Files

- `mod_F03_field_load.f90`: module wrapper.
- `sub_F03_field_load_1d_dat.f90`: ASCII 1D field loader.
- `sub_F03_field_load_1d_bin.f90`: binary 1D field loader.
- `sub_F03_field_load_3d_dat.f90`: ASCII 3D field loader.
- `sub_F03_field_load_3d_bin.f90`: binary 3D field loader.

## Notes

Field files begin with `il(1:3)` and `iu(1:3)`. `3d_grid` output stores averaged
cell-centered values, so read it back with the regular 3D loaders.
