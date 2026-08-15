# F04_field_output

[中文](README.zh-CN.md) | [English](README.en.md)

Writes each MPI rank's local field file for 1D, 3D, and grid-to-cell averaged outputs.

## Files

- `mod_F04_field_output.f90`: module wrapper.
- `sub_F04_field_output_1d_dat.f90`, `sub_F04_field_output_1d_bin.f90`: 1D packed output.
- `sub_F04_field_output_3d_dat.f90`, `sub_F04_field_output_3d_bin.f90`: 3D cell-centered output.
- `sub_F04_field_output_3d_grid_dat.f90`, `sub_F04_field_output_3d_grid_bin.f90`: output cell-centered values after an 8-point average.

## Notes

`3d_grid` does not preserve original nodal values. If the original grid-defined
field must be retained, pack it or provide its bounds through the 1D/3D paths.
