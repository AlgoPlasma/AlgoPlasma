# F04_field_output

[中文](README.zh-CN.md) | [English](README.md)

写出每个 MPI rank 的本地场文件，支持 1D、3D 和 grid-to-cell 平均输出。

## 文件

- `mod_F04_field_output.f90`: 模块包装器。
- `sub_F04_field_output_1d_dat.f90`, `sub_F04_field_output_1d_bin.f90`: 1D packed 输出。
- `sub_F04_field_output_3d_dat.f90`, `sub_F04_field_output_3d_bin.f90`: 3D cell-centered 输出。
- `sub_F04_field_output_3d_grid_dat.f90`, `sub_F04_field_output_3d_grid_bin.f90`: 8 点平均后输出 cell-centered 值。

## 注意

`3d_grid` 不保存原始节点值；需要保留原始节点场时，应使用 1D/3D 路径自行打包或指定范围。
