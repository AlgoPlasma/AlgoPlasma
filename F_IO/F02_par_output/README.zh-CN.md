# F02_par_output

[中文](README.zh-CN.md) | [English](README.md)

将每个 MPI rank 的粒子数组 `par(:,1:np)` 写入独立文件。

## 文件

- `mod_F02_par_output.f90`: 模块包装器。
- `sub_F02_par_output.f90`: `dat/bin/h5/hdf5` dispatcher。
- `sub_F02_par_output_dat.f90`: ASCII 输出。
- `sub_F02_par_output_bin.f90`: stream binary 输出。
- `sub_F02_par_output_h5.f90`: HDF5 输出，受 `USE_HDF5=1` 控制。

## 注意

`label` 同时作为目录和文件名前缀，应使用简单名字，不要包含 `/`。
