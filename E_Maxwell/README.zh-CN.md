# E_Maxwell

[中文](README.zh-CN.md) | [English](README.md)

`E_Maxwell` 包含 AlgoPlasma 的 Maxwell 方程场推进子程序、有限差分时域法（Finite-Difference Time-Domain, FDTD）实现，以及卷积完美匹配层（Convolutional Perfectly Matched Layer, CPML）边界扩展。

## 子目录

- `E01_Maxwell_2Drz`: 2D 轴对称柱坐标 `(r,z)` TE/TM FDTD 和 CPML。
- `E02_Maxwell_3Drtz`: 完整 3D 柱坐标 `(r,phi,z)` FDTD 和 CPML。
- `E03_Maxwell_3Dxyz`: 3D Cartesian `(x,y,z)` FDTD 和 CPML。

## 使用提示

- 这些 routine 是低层场推进和边界更新内核，不是完整求解器框架。
- 调用方负责数组分配、边界/ghost 填充、源项、诊断、MPI 交换和时间步循环。
- 模块包装文件使用 `#include` 收纳 subroutine；编译器若不自动预处理 `.f90`，需要启用 Fortran 预处理。
- 源码多使用默认 `real`；若需要双精度，通常在编译时统一使用类似 `-fdefault-real-8` 的选项决定。

## 依赖

这些内核是 Fortran 场推进和边界更新例程。调用方负责数组分配、边界/ghost 填充、源项、诊断和时间步循环。

## 文档

完整公式、学习路线、使用 cookbook、CPML cookbook 和测试说明见 Sphinx 的 `E_Maxwell` 页面。
