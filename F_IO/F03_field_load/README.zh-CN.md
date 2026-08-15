# F03_field_load

[中文](README.zh-CN.md) | [English](README.en.md)

读取 F04 写出的本地场文件，支持 1D packed 和 3D cell-centered 布局。

## 文件

- `mod_F03_field_load.f90`: 模块包装器。
- `sub_F03_field_load_1d_dat.f90`: ASCII 1D 场读入。
- `sub_F03_field_load_1d_bin.f90`: binary 1D 场读入。
- `sub_F03_field_load_3d_dat.f90`: ASCII 3D 场读入。
- `sub_F03_field_load_3d_bin.f90`: binary 3D 场读入。

## 注意

场文件头包含 `il(1:3)` 和 `iu(1:3)`。`3d_grid` 输出保存的是平均后的 cell-centered 值，
读回时使用普通 3D loader。
