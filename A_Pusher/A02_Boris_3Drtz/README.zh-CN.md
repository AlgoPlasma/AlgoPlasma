# A02_Boris_3Drtz

[中文](README.zh-CN.md) | [English](README.md)

`A02_Boris_3Drtz` 提供三维柱坐标中的非相对论 Boris 粒子推进器。它会同时更新单个粒子的位置 `x = (r, theta, z)` 和速度 `v = (v_r, v_theta, v_z)`。

## 文件

| 文件 | 作用 |
| --- | --- |
| `mod_A02_Boris_3Drtz.f90` | 源码级 Fortran module 入口，用于收纳并导出核心子程序。 |
| `sub_A02_Boris_3Drtz_push_v_x.f90` | 柱坐标位置和速度更新的核心子程序。 |

## 接口

```fortran
call sub_A02_Boris_3Drtz_push_v_x(x, v, E, B, k, dt)
```

| 参数 | 方向 | 含义 |
| --- | --- | --- |
| `x(1:3)` | in/out | 粒子位置 `(r, theta, z)`。 |
| `v(1:3)` | in/out | 粒子速度 `(v_r, v_theta, v_z)`。 |
| `E(1:3)` | in | 柱坐标分量表示的电场。 |
| `B(1:3)` | in | 柱坐标分量表示的磁场。 |
| `k` | in | Boris 参数，通常为 `q * dt / (2 * m)`。 |
| `dt` | in | 用于位置推进的时间步长。 |

## 使用方式

```fortran
#include "A_Pusher/A02_Boris_3Drtz/mod_A02_Boris_3Drtz.f90"

program demo_a02
    use mod_A02_Boris_3Drtz
    implicit none

    real :: x(3), v(3), E(3), B(3), k, dt

    x = (/1.0, 0.0, 0.0/)
    v = (/0.0, 0.0, 0.0/)
    E = 0.0
    B = (/0.0, 0.0, 1.0/)
    dt = 0.01
    k = 0.01

    call sub_A02_Boris_3Drtz_push_v_x(x, v, E, B, k, dt)
end program demo_a02
```

编译时通常需要开启 C 预处理：

```bash
gfortran -cpp -O2 demo_a02.f90
```

源码中使用默认 `real`。如果需要双精度，可在编译时选择对应编译器选项：

```bash
gfortran -cpp -O2 -fdefault-real-8 demo_a02.f90
ifx -fpp -O2 -real-size 64 demo_a02.f90
```

## 参考文献

[1] G.L. Delzanno, E. Camporeale, On particle movers in cylindrical geometry for Particle-In-Cell simulations, Journal of Computational Physics, 253 (2013) 259-277. DOI: <a href="https://doi.org/10.1016/j.jcp.2013.07.007" target="_blank" rel="noopener noreferrer">10.1016/j.jcp.2013.07.007</a>
