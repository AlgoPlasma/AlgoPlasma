# A03_Higuera_Cary_relativistic_3Dxyz

[中文](README.zh-CN.md) | [English](README.en.md)

`A03_Higuera_Cary_relativistic_3Dxyz` 提供三维直角坐标中的相对论 Higuera-Cary 速度推进器。它在给定电场和磁场后推进粒子速度，并考虑相对论修正。

## 文件

| 文件 | 作用 |
| --- | --- |
| `mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher.f90` | 源码级 Fortran module 入口，用于收纳并导出核心子程序。 |
| `sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v.f90` | 核心 Higuera-Cary 相对论速度更新子程序。 |

## 接口

```fortran
call sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v(v, E, B, k)
```

| 参数 | 方向 | 含义 |
| --- | --- | --- |
| `v(1:3)` | in/out | 粒子速度的直角坐标分量。 |
| `E(1:3)` | in | 粒子位置处的电场。 |
| `B(1:3)` | in | 粒子位置处的磁场。 |
| `k` | in | 通常为 `q * dt / (2 * m)`。 |

## 使用方式

```fortran
#include "A_Pusher/A03_Higuera_Cary_relativistic_3Dxyz/mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher.f90"

program demo_a03
    use mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher
    implicit none

    real :: v(3), E(3), B(3), k

    v = (/0.0, 0.0, 0.0/)
    E = 0.0
    B = (/0.0, 0.0, 1.0/)
    k = 0.01

    call sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v(v, E, B, k)
end program demo_a03
```

编译时通常需要开启 C 预处理：

```bash
gfortran -cpp -O2 demo_a03.f90
```

源码中使用默认 `real`。如果需要双精度，可在编译时选择对应编译器选项：

```bash
gfortran -cpp -O2 -fdefault-real-8 demo_a03.f90
ifx -fpp -O2 -real-size 64 demo_a03.f90
```

子程序内部使用 `c = 299792458.0` 进行相对论修正，因此速度、场量和时间步长的单位应保持一致。

## 参考文献

[1] A.V. Higuera, J.R. Cary, Structure-preserving second-order integration of relativistic charged particle trajectories in electromagnetic fields, Phys. Plasmas 24 (2017) 052104. DOI: <a href="https://doi.org/10.1063/1.4979989" target="_blank" rel="noopener noreferrer">10.1063/1.4979989</a>

[2] B. Ripperda, F. Bacchini, J. Teunissen, C. Xia, O. Porth, L. Sironi, G. Lapenta, R. Keppens, A comprehensive comparison of relativistic particle integrators, Astrophys. J. Suppl. Ser. 235 (2018) 21. DOI: <a href="https://doi.org/10.3847/1538-4365/aab114" target="_blank" rel="noopener noreferrer">10.3847/1538-4365/aab114</a>
