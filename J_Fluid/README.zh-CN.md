# J_Fluid

[中文](README.zh-CN.md) | [English](README.en.md)

`J_Fluid` 放置 AlgoPlasma 的流体方程更新例程。

## 子目录

- `J01_continuity_freeflow`: 使用三维 Lax-Friedrichs 有限体积格式推进自由流连续性方程。

## 约定

- 网格和时间步采用归一化约定 `dx=dy=dz=dt=1`。
- 速度场 `ux`、`uy`、`uz` 和源项 `s` 为 cell-centered 数组。
- 边界条件和 guard/ghost cells 需要在调用更新例程前设置好。

## 文档

详细的数值格式、索引约定和 API 说明见 Sphinx 的 `J_Fluid` 页面。
