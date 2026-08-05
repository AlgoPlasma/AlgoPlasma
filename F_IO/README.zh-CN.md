# F_IO

[中文](README.zh-CN.md) | [English](README.md)

`F_IO` 是 AlgoPlasma 的 MPI per-rank 数据输入输出层，覆盖粒子相空间数组和局部场数组。

## 子目录

- `F01_par_load`: 读取每个 MPI rank 的粒子文件，并提供本地粒子数统计辅助例程。
- `F02_par_output`: 写出每个 MPI rank 的粒子相空间数组。
- `F03_field_load`: 读取 F04 写出的 1D packed 或 3D cell-centered 场文件。
- `F04_field_output`: 写出 1D、3D 或 grid-to-cell 平均后的场文件。

## 依赖

- 所有子模块依赖 MPI。
- 粒子 HDF5 路径需要 HDF5 Fortran 绑定，并在编译时定义 `USE_HDF5=1`。
- 二进制文件使用 Fortran unformatted stream；读写端应保持相同默认 `integer`/`real` 字节宽度和端序。

## 文件约定

默认文件名为 `label/label_IIIIIIIIII_RRRRR.ext`。`label` 应是简单名字，不应包含 `/`。
