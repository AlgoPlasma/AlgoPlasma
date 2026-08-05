# C_Gather

[中文](README.zh-CN.md) | [English](README.md)

`C_Gather` 收集 PIC 粒子循环中常用的“网格到粒子”插值例程，用于把网格上的场量或形函数权重计算到粒子位置。

## 组件

| 目录 | 作用 |
| --- | --- |
| `C01_gather_3Dxyz` | 三维直角坐标电磁场的三线性 gather，以及 gather 与 push 融合的粒子循环内核。 |
| `C02_gather_3Dxyz_bspline` | 三维直角坐标电磁场的直接 B-spline gather。 |

## 使用说明

这些例程以源码级 Fortran module 组织。调用程序通常先包含对应的 `mod_*.f90` 入口文件，再 `use` 该 module。由于 module 文件使用 `#include` 收集子程序源文件，编译时通常需要开启 C 预处理。

```bash
gfortran -cpp -O2 demo_gather.f90
```

源码使用默认 `real` 精度。如需双精度，可在编译时选择相应选项，例如 `gfortran` 的 `-fdefault-real-8` 或 Intel Fortran 的 `-real-size 64`。
