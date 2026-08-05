# D01_hypre_3Dxyz

[中文](README.zh-CN.md) | [English](README.en.md)

早期 Cartesian 3D Poisson/HYPRE 接口。Fortran 侧通过桥接子程序调用 C 侧 HYPRE Struct 求解器。

## 文件

- `mod_D01_hypre_3Dxyz_bc.f90`: 模块包装文件。
- `sub_D01_hypre_3Dxyz_interface.f90`: Fortran-C 桥接入口。
- `fun_D01_hypre_3Dxyz_bc.c`: C/HYPRE Struct 求解器实现。

## 主接口

- `sub_D01_hypre_3Dxyz_interface(n, phi1d, rho1d, ilower, iupper, il0, iu0, tolerance, bc)`

`phi1d` 是输入初值和输出势函数，`rho1d` 是右端项，`ilower:iupper` 描述本 MPI rank 的本地 box。

## 依赖

需要 MPI、HYPRE、Fortran/C 混合编译环境。新代码通常优先参考 D02 的边界条件接口。
