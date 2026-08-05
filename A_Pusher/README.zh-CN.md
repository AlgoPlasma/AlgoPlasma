# A_Pusher

[中文](README.zh-CN.md) | [English](README.md)

`A_Pusher` 收集 AlgoPlasma 中的粒子推进算法，用于在给定电场、磁场、粒子电荷质量比和时间步长的条件下更新粒子速度或粒子相空间状态。当前目录包含三个粒子推进器，覆盖直角坐标、柱坐标和相对论速度推进场景。

## 当前算法

| 编号 | 目录 | 算法 | 主要用途 |
| --- | --- | --- | --- |
| A01 | [`A01_Boris_3Dxyz`](A01_Boris_3Dxyz/) | 3D 直角坐标非相对论 Boris 推进 | 对单个粒子的速度 `v = (v_x, v_y, v_z)` 做一次完整 Boris 更新。 |
| A02 | [`A02_Boris_3Drtz`](A02_Boris_3Drtz/) | 3D 柱坐标非相对论 Boris 推进 | 在柱坐标 `x = (r, theta, z)` 中同时更新单个粒子的位置和速度 `v = (v_r, v_theta, v_z)`。 |
| A03 | [`A03_Higuera_Cary_relativistic_3Dxyz`](A03_Higuera_Cary_relativistic_3Dxyz/) | 3D 直角坐标相对论 Higuera-Cary 推进 | 用 Higuera-Cary 方法更新相对论粒子速度，适合高速粒子和强电磁场问题。 |

## A01_Boris_3Dxyz

- 模块入口：`mod_A01_Boris_3Dxyz.f90`
- 核心子程序：`sub_A01_Boris_3Dxyz(v, E, B, k)`
- 坐标系：3D Cartesian / `xyz`
- 更新量：速度 `v`
- 适用范围：非相对论单粒子速度推进

该算法采用标准 Boris 结构，先进行电场半步加速，再进行磁场旋转，最后再进行电场半步加速。参数 `k` 表示 `q dt / 2m`。

## A02_Boris_3Drtz

- 模块入口：`mod_A02_Boris_3Drtz.f90`
- 核心子程序：`sub_A02_Boris_3Drtz_push_v_x(x, v, E, B, k, dt)`
- 坐标系：3D cylindrical / `rtz`
- 更新量：位置 `x` 和速度 `v`
- 适用范围：非相对论柱坐标粒子推进

该算法在柱坐标下执行 Boris 速度更新，并根据柱坐标几何关系推进粒子位置。输入的电场和磁场分量应与柱坐标分量一致。

## A03_Higuera_Cary_relativistic_3Dxyz

- 模块入口：`mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher.f90`
- 核心子程序：`sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v(v, E, B, k)`
- 坐标系：3D Cartesian / `xyz`
- 更新量：速度 `v`
- 适用范围：相对论速度推进

该算法使用 Higuera-Cary 相对论推进格式。它先把速度转换为 proper velocity `u = gamma v`，经过电场半步推进和磁场旋转后，再转换回速度形式。

## 使用方式

这些算法目前以 Fortran 源码级模块组织。通常在调用程序中通过 `mod_*.f90` 入口文件引入：

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

编译时通常需要开启 C 预处理：

```bash
gfortran -cpp -O2 -fdefault-real-8 demo_a01.f90
```
