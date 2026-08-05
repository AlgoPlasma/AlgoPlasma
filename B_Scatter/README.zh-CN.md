# B_Scatter

[中文](README.zh-CN.md) | [English](README.en.md)

`B_Scatter` 收纳 AlgoPlasma 中从粒子到网格的沉积算子。

## 子目录

- `B01_scatter_3Dxyz`: 三维直角坐标 `xyz` 下的 CIC/NGP 风格数密度、动量密度和统计量沉积。
- `B02_deposit_3d_cyl`: 三维柱坐标 `r,phi,z` 下的电荷密度和电流密度沉积，包含轴线平均处理。
- `B03_scatter_3Dxyz_bspline`: 三维直角坐标 `xyz` 下的任意阶 B-spline 粒子数和粒子分量沉积。

## 约定

- 粒子数组通常使用 `par(1:6,1:np)`，其中 `1:3` 为位置，`4:6` 为速度或其他粒子分量。
- B01 和 B03 面向 Cartesian 网格；B02 面向 cylindrical 网格，并处理 `r=0` 轴线退化。
- 源码使用默认 `real`；需要双精度默认实数时应统一使用 `-fdefault-real-8` 或 `-real-size 64`。
- 使用 `include` 或 MPI 交换的入口通常需要启用 Fortran 预处理，例如 `-cpp` 或 `-fpp`。

## 测试

相关测试见 `tests/004_scatter` 以及 Sphinx 的 `004_scatter` 测试说明页。
