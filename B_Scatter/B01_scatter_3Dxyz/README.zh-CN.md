# B01_scatter_3Dxyz

[中文](README.zh-CN.md) | [English](README.md)

直角坐标三维 PIC 粒子沉积工具。该目录提供 CIC 数密度/物理量沉积、NGP
单元方差统计，以及沉积后的 MPI ghost-cell 交换。

## 文件

- `mod_B01_scatter_3Dxyz.f90`: B01 模块入口，包含基础 CIC 沉积例程。
- `sub_B01_scatter_3Dxyz.f90`: 将粒子单位权重按 CIC 权重沉积到八个相邻节点。
- `sub_B01_scatter_3Dxyz_v.f90`: 将 `par(d,p)` 按 CIC 权重沉积到网格。
- `sub_B01_scatter_3Dxyz_T.f90`: 使用两遍 NGP 计算每个单元内 `par(d,p)` 的方差。
- `sub_B01_scatter_3Dxyz_mpi_exchange.f90`: 处理周期端点和 MPI halo 贡献交换。

## 主要接口

```fortran
call sub_B01_scatter_3Dxyz(il, iu, den, np, par, w)
call sub_B01_scatter_3Dxyz_v(il, iu, den, np, par, w, d)
call sub_B01_scatter_3Dxyz_T(il, iu, T, np, par, d)
call sub_B01_scatter_3Dxyz_mpi_exchange(il, iu, den, mpi_n, rank_to_ijk, &
    domain_split, ijk_to_rank, l)
```

`par(1:3,p)` 为网格单位下的粒子位置。调用沉积例程前应清零输出数组。

## 编译提示

包含 module 入口或 MPI 交换例程时通常需要启用预处理，例如 `-cpp` 或 `-fpp`。
若项目使用双精度默认实数，请对主程序和本目录源文件统一使用
`-fdefault-real-8` 或 `-real-size 64`。
