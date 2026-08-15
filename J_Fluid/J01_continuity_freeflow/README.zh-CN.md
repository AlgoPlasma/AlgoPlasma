# J01_continuity_freeflow

[中文](README.zh-CN.md) | [English](README.en.md)

`J01_continuity_freeflow` 使用三维 Lax-Friedrichs 有限体积格式推进自由流连续性方程。

## 文件

- `mod_J01_continuity_freeflow.f90`: 模块包装器，通过 `include` 暴露子程序。
- `sub_J01_continuity_freeflow.f90`: 计算三方向数值通量，并原地更新数密度 `n`。

## 主接口

`sub_J01_continuity_freeflow(il,iu,n,s,ux,uy,uz,n0)`：

- `il` / `iu`: 调用方传入的参考下界和上界。当前实现中，密度实际更新区间是
  `il(1)-1:iu(1)`、`il(2)-1:iu(2)`、`il(3)-1:iu(3)`。
- `n`: 数密度数组，包含 guard cells，并在例程中原地更新。它的索引应按当前例程
  契约理解，而不是简单理解为 `n(il:iu)` 这一层 active cell。
- `s`: 源项。
- `ux` / `uy` / `uz`: 与本例程通量构造所要求索引布局一致的速度数组。
- `n0`: 保存旧密度的工作数组。

## 索引约定

本例程不是最简单的“active 密度就是 `n(il:iu)`”那套解释。按当前数组声明：

- `n`、`s`、`ux`、`uy`、`uz`、`n0` 都声明在 `il(*)-2:iu(*)+1`。
- 实际更新的密度区间是
  `n(il(1)-1:iu(1), il(2)-1:iu(2), il(3)-1:iu(3))`。
- 三个方向的通量工作数组是面交错的：
  `Fx(il(1)-2:iu(1), il(2)-1:iu(2), il(3)-1:iu(3))`，
  `Fy(il(1)-1:iu(1), il(2)-2:iu(2), il(3)-1:iu(3))`，
  `Fz(il(1)-1:iu(1), il(2)-1:iu(2), il(3)-2:iu(3))`。

## 构建

模块通过 Fortran `include` 组织源码；编译时需要启用预处理并配置本目录为 include 路径。
