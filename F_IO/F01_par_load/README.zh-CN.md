# F01_par_load

[中文](README.zh-CN.md) | [English](README.en.md)

读取每个 MPI rank 的粒子文件到 `par(:,1:np)`。

## 文件

- `mod_F01_par_load.f90`: 模块包装器。
- `sub_F01_par_load.f90`: `dat/bin/h5/hdf5` dispatcher。
- `sub_F01_par_load_dat.f90`: ASCII 读入。
- `sub_F01_par_load_bin.f90`: stream binary 读入。
- `sub_F01_par_load_h5.f90`: HDF5 读入，受 `USE_HDF5=1` 控制。
- `sub_F01_par_load_count.f90`: 推断本 rank 粒子数，子程序名为 `sub_F01_load_par_count`。

## 注意

`dat/bin` 粒子文件不保存通用头信息；调用方需要提供 `np` 和足够大的 `par`。
