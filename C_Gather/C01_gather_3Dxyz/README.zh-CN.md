# C01_gather_3Dxyz

[中文](README.zh-CN.md) | [English](README.md)

`C01_gather_3Dxyz` 将三维直角坐标、cell-centered 网格上的电磁场插值到粒子位置。同时提供一个融合内核，在同一粒子循环中完成 gather、非相对论 Boris 速度更新和位置推进。

## 文件

| 文件 | 作用 |
| --- | --- |
| `mod_C01_gather_3Dxyz.f90` | 源码级 Fortran module 入口。 |
| `sub_C01_gather_3Dxyz.f90` | 将 `Ex,Ey,Ez,Bx,By,Bz` 三线性插值到单个粒子位置。 |
| `sub_C01_gather_3Dxyz_push.f90` | 遍历粒子，插值电磁场，执行 Boris 速度更新，并推进位置。 |

## 接口

```fortran
call sub_C01_gather_3Dxyz(p, np, par, il, iu, Ex, Ey, Ez, Bx, By, Bz, E, B)
call sub_C01_gather_3Dxyz_push(np, par, il, iu, Ex, Ey, Ez, Bx, By, Bz, q, m, dt)
```

`sub_C01_gather_3Dxyz_push` 中的 `dt` 是可选参数，省略时默认为 `1.0`。

## 使用方式

```fortran
#include "C_Gather/C01_gather_3Dxyz/mod_C01_gather_3Dxyz.f90"

program demo_c01
    use mod_C01_gather_3Dxyz
    implicit none

    ! 调用前需分配并填充 par, il, iu, Ex, Ey, Ez, Bx, By, Bz。
end program demo_c01
```

编译时通常需要开启 C 预处理：

```bash
gfortran -cpp -O2 demo_c01.f90
```
