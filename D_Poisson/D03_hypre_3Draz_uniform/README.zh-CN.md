# D03_hypre_3Draz_uniform

[中文](README.zh-CN.md) | [English](README.en.md)

均匀柱坐标 `(r,alpha,z)` 3D Poisson 求解器。它使用 HYPRE Struct/PFMG 求解由 D03 组装例程生成的 7 点邻接系统。

## 文件

- `mod_D03_hypre_3Draz_uniform.f90`: 模块包装文件。
- `sub_D03_hypre_3Draz_uniform.f90`: HYPRE Struct 求解驱动。
- `sub_D03_hypre_3Draz_uniform_A.f90`: 单域均匀网格矩阵/RHS 组装。
- `sub_D03_hypre_3Draz_uniform_A_mpi.f90`: MPI-local 矩阵/RHS 组装。
- `sub_D03_hypre_3Draz_uniform_bc_A_dielectric.f90`: 介质边界修正。
- `sub_D03_hypre_3Draz_uniform_bc_A_outflow.f90`: outflow/Robin 边界修正。

## 主接口

组装例程输出 `A_values` 和 `RHS`，求解驱动根据阶段化标志初始化 HYPRE 对象、更新矩阵、求解并释放资源。

## 依赖

需要 MPI、HYPRE 和 Fortran 编译环境。均匀网格由标量 `dr`、`da`、`dz` 描述。
