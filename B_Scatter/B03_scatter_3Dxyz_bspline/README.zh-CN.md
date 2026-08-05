# B03_scatter_3Dxyz_bspline

[中文](README.zh-CN.md) | [English](README.md)

`B03_scatter_3Dxyz_bspline` 在三维直角坐标网格上执行任意阶 centered
B-spline 粒子沉积。它与 `C_Gather/C02_gather_3Dxyz_bspline` 使用同一类
一维 B-spline 形函数，但方向相反：C02 是网格到粒子，B03 是粒子到网格。

## 文件

- `mod_B03_scatter_3Dxyz_bspline.f90`: B03 模块入口，包含顶层沉积例程和辅助函数。
- `sub_B03_scatter_3Dxyz_bspline.f90`: 顶层三维张量积 B-spline 粒子数沉积。
- `sub_B03_scatter_3Dxyz_bspline_v.f90`: 顶层三维张量积 B-spline 粒子分量沉积。
- `sub_B03_bspline_stencil_1d.f90`: 为一个方向生成 `order+1` 个网格指标和权重。
- `fun_B03_bspline_shape.f90`: 递归计算中心化 B-spline 形函数。

## 主要接口

```fortran
call sub_B03_scatter_3Dxyz_bspline(il,iu,den,np,par,w,order)
call sub_B03_scatter_3Dxyz_bspline_v(il,iu,den,np,par,d,w,order)
```

- `sub_B03_scatter_3Dxyz_bspline`: 每个粒子沉积 `1*w`，用于粒子数密度或电荷密度的基础沉积。
- `sub_B03_scatter_3Dxyz_bspline_v`: 每个粒子沉积 `par(d,p)*w`，用于某个粒子分量的沉积。
- `order=1`: 退化为 B01 的 CIC/三线性沉积。

调用前通常应先清零 `den`。本例程不处理边界条件、周期端点或 guard-cell 交换。

## 编译提示

该模块使用 `#include` 汇入子程序源文件，编译时需要启用 Fortran 预处理，例如：

```bash
gfortran -cpp -O2 -fopenmp your_program.f90
```
