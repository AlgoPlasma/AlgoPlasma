# D_Poisson

[中文](README.zh-CN.md) | [English](README.md)

`D_Poisson` 包含 AlgoPlasma 的静电 Poisson 求解器及相关后处理工具，主要通过 HYPRE Struct/PFMG 求解 cell-centered 结构网格上的电势方程。后处理例程负责展开求解器输出并计算电场等派生量。

## 子目录

- `D01_hypre_3Dxyz`: 早期 Cartesian C/HYPRE 求解器和 Fortran-C 桥接接口。
- `D02_hypre_3Dxyz_bc`: Cartesian 3D Poisson 组装和边界条件版本。
- `D03_hypre_3Draz_uniform`: 均匀柱坐标 `(r,alpha,z)` Poisson 求解器。
- `D04_hypre_3Draz_nonuniform`: 非均匀柱坐标 `(r,alpha,z)` Poisson 求解器。
- `D05_phi1d_to_phi3d`: 将 HYPRE 输出的一维解向量展开为含幽灵格点的三维数组，并进行 MPI halo 交换。
- `D06_phi_to_E`: 使用二阶中心差分由电势计算电场分量。

## 典型调用顺序

一次完整的 Poisson 求解和电场更新按如下顺序调用：

```
D02  →  D05  →  （边界条件修正）  →  D06  →  H01（电场 MPI 交换）
```

## 依赖

D01–D05 需要 MPI、HYPRE、Fortran 编译器和 C 编译器。D06 无外部依赖。

## 文档

完整公式、边界条件说明和测试结果见 Sphinx 文档中的 `D_Poisson` 页面以及 `tests/001_poisson` 测试页。
