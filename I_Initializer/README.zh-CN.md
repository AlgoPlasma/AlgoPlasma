# I_Initializer

[中文](README.zh-CN.md) | [English](README.en.md)

`I_Initializer` 放置 AlgoPlasma 的粒子初始化工具。

## 子目录

- `I01_par_distribute`: 在 Fortran 内存中生成规则粒子初值，当前包括每格均匀位置和 Maxwellian 速度初始化。
- `I02_par_init_and_load`: 用 Python 离线生成二进制粒子文件，并在 MPI Fortran 程序中载入到本地子域。

## 数据约定

- 粒子数组使用 `par(1:6,...)`，其中 `1:3` 为 `x,y,z`，`4:6` 为 `vx,vy,vz`。
- I01 假设归一化网格间距 `dx=dy=dz=1`。
- I02 的二进制文件位于 `output_init_particles_bin/`，每个粒子记录为 6 个 `float64` 值。

## 文档

详细的初始化流程、坐标约定和 API 说明见 Sphinx 的 `I_Initializer` 页面。
