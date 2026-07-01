# A01_Boris_3Dxyz

[中文](README.zh-CN.md) | [English](README.en.md)

`A01_Boris_3Dxyz` 提供三维直角坐标中的非相对论 Boris 速度推进器。它在给定电场和磁场后，对单个粒子的速度 `v = (v_x, v_y, v_z)` 做一次完整更新。

## 文件

| 文件 | 作用 |
| --- | --- |
| `mod_A01_Boris_3Dxyz.f90` | 源码级 Fortran module 入口，用于收纳并导出核心子程序。 |
| `sub_A01_Boris_3Dxyz.f90` | 核心 Boris 速度更新子程序。 |

## 接口

```fortran
call sub_A01_Boris_3Dxyz(v, E, B, k)
```

| 参数 | 方向 | 含义 |
| --- | --- | --- |
| `v(1:3)` | in/out | 粒子速度的直角坐标分量。 |
| `E(1:3)` | in | 粒子位置处的电场。 |
| `B(1:3)` | in | 粒子位置处的磁场。 |
| `k` | in | Boris 参数，通常为 `q * dt / (2 * m)`。 |

## 使用方式

该算法以源码级 Fortran module 组织。调用程序通常先包含 module 入口文件，再 `use` 对应 module：

```fortran
#include "A_Pusher/A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz.f90"

program demo_a01
    use mod_A01_Boris_3Dxyz
    implicit none

    real :: v(3), E(3), B(3), k

    v = (/1.0, 0.0, 0.0/)
    E = 0.0
    B = (/0.0, 0.0, 1.0/)
    k = 0.01

    call sub_A01_Boris_3Dxyz(v, E, B, k)
end program demo_a01
```

由于 module 使用 `#include`，编译时通常需要开启 C 预处理：

```bash
gfortran -cpp -O2 demo_a01.f90
```

源码中使用默认 `real`。如果需要双精度，可在编译时选择对应编译器选项，例如：

```bash
gfortran -cpp -O2 -fdefault-real-8 demo_a01.f90
ifx -fpp -O2 -real-size 64 demo_a01.f90
```

## 参考文献

[1] J.P. Boris, Relativistic plasma simulation-optimization of a hybrid code, in: Proceedings of the Fourth Conference on Numerical Simulation of Plasmas, Naval Research Laboratory, Washington, D.C., 1970, pp.3-67.

[2] G.L. Delzanno, E. Camporeale, On particle movers in cylindrical geometry for Particle-In-Cell simulations, Journal of Computational Physics, 253 (2013) 259-277. DOI: <a href="https://doi.org/10.1016/j.jcp.2013.07.007" target="_blank" rel="noopener noreferrer">10.1016/j.jcp.2013.07.007</a>
