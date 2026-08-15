# D04_hypre_3Draz_nonuniform

[中文](README.zh-CN.md) | [English](README.en.md)

非均匀柱坐标 `(r,alpha,z)` 3D Poisson 求解器。它与 D03 使用同类 HYPRE Struct/PFMG 求解流程，但矩阵系数来自局部非均匀网格尺度。

## 文件

- `mod_D04_hypre_3Draz_nonuniform.f90`: 模块包装文件。
- `sub_D04_hypre_3Draz_nonuniform.f90`: HYPRE Struct 求解驱动。
- `sub_D04_hypre_3Draz_nonuniform_A.f90`: 单域非均匀网格矩阵/RHS 组装。
- `sub_D04_hypre_3Draz_nonuniform_A_mpi.f90`: MPI-local 矩阵/RHS 组装，使用 ghost 层。
- `sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric.f90`: 介质边界修正。
- `sub_D04_hypre_3Draz_nonuniform_bc_A_outflow.f90`: outflow/Robin 边界修正。

## 主接口

组装例程输出与 HYPRE Struct 盒子一致的 `A_values` 和 `RHS`。MPI 版本要求调用方提供正确的 owned-cell 范围、ghost 层和邻接标志。

## 依赖

需要 MPI、HYPRE 和 Fortran 编译环境。非均匀网格数组和本地 box 必须保持一致。
