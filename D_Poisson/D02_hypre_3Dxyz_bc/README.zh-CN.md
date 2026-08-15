# D02_hypre_3Dxyz_bc

[中文](README.zh-CN.md) | [English](README.en.md)

Cartesian 3D Poisson 求解器，包含矩阵/RHS 组装、边界修正和 HYPRE Struct 求解接口。

## 文件

- `mod_D02_hypre_3Dxyz_bc.f90`: 模块包装文件。
- `sub_D02_hypre_3Dxyz_bc_A.f90`: 组装 Cartesian 7 点 stencil 矩阵和 RHS。
- `sub_D02_hypre_3Dxyz_bc_A_dielectric.f90`: 应用介质面电荷边界修正。
- `sub_D02_hypre_3Dxyz_bc_A_outflow.f90`: 应用 outflow/Robin 边界修正。
- `sub_D02_hypre_3Dxyz_bc.f90` / `fun_D02_hypre_3Dxyz_bc.c`: Fortran-C HYPRE 求解路径。
- `sub_D02_hypre_3Dxyz_bc_fortran.f90`: 纯 Fortran HYPRE Struct 阶段化接口。

## 主接口

先调用组装例程生成 `A_values` 和 `rho1d`，再调用 C/HYPRE 包装或 Fortran HYPRE 接口求解 `phi1d`。

## 依赖

需要 MPI、HYPRE 和 Fortran/C 编译环境。`A_values` 的每个 cell 系数顺序为 `center, xmin, xmax, ymin, ymax, zmin, zmax`。
