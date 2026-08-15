# I01_par_distribute

[中文](README.zh-CN.md) | [English](README.en.md)

`I01_par_distribute` 提供 Fortran 内部粒子分布初始化例程。

## 文件

- `mod_I01_par_distribute.f90`: 模块包装器，通过 `include` 暴露初始化子程序。
- `sub_I01_par_distribute_equilibrium.f90`: 在每个单元内生成精确均匀位置，并按 Maxwellian 分布初始化速度。

## 主接口

`sub_I01_par_distribute_equilibrium(par,nppc,il,iu,vt,vd)` 填充 `par(1:6,1:np)`：

- `par(1:3,:)`: 归一化网格坐标中的 `x,y,z`。
- `par(4:6,:)`: 带漂移速度 `vd` 和热速度 `vt` 的 Maxwellian 速度。

调用者需要预先分配 `par`，并保证粒子数与 `il`、`iu`、`nppc` 一致。

## 构建

模块通过 Fortran `include` 组织源码；编译时需要启用预处理并配置本目录为 include 路径。
