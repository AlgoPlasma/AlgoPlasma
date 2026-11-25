# RZ 二维均匀与非均匀网格制造解测试

[English](README.md)

## 1. 目的

本测试使用**同一制造解**验证柱坐标 `r-z` 泊松求解器在两类网格上的表现，直接使用现有求解器实现。

- **均匀网格**（D03）
- **非均匀网格**（D04）

测试检查以下内容。

- `r-z` 离散的正确性。
- `r = 0` 处轴线边界处理的正确性。
- `r = r_max` 处齐次诺伊曼边界的正确性。
- `z = 0` 和 `z = z_max` 处狄利克雷边界的正确性。
- 均匀和非均匀网格上的误差与收敛行为。

---

## 2. 制造解

测试使用以下解析解。

\f[
\phi(r,z)=\phi_0\left[\left(\frac{r}{L_r}\right)^2-\frac{1}{2}\left(\frac{r}{L_r}\right)^4\right]\sin\left(\pi z/L_z\right)
\f]

各参数为

- \f$L_r = r_{\max} - r_{\min}\f$
- \f$L_z = z_{\max} - z_{\min}\f$
- \f$\phi_0 = 1\f$

控制方程为

\f[
-\nabla^2 \phi = \rho / \varepsilon_0
\f]

测试程序根据解析表达式，在单元中心计算精确解 `phi_exact` 和源项 `rho1d`。

---

## 3. 边界条件

测试采用以下边界条件。

- `r_lo = BC_AXIS`
- `r_hi = BC_NEUMANN`，且 `dphi/dn = 0`
- `z_lo = BC_DIRICHLET = 0`
- `z_hi = BC_DIRICHLET = 0`
- `alpha` 方向为周期边界。

这组边界条件与当前 D03、D04 的组装例程兼容，无需提供随空间变化的狄利克雷数据。

---

## 4. 相关文件

### Fortran 主程序

- `main_compare_uniform_nonuniform_mms.f90`

该程序运行均匀与非均匀网格求解器，计算 `L_inf` 误差和相对 `L2` 误差，并写出细网格上的场数据。

### Python 绘图脚本

- `plot_compare_uniform_nonuniform.py`

该脚本读取细网格场数据，以**物理坐标 `(r,z)`** 绘制二维场图，坐标单位为 **cm**。

---

## 5. 输出文件

运行测试后通常会生成以下文件。

### 误差汇总

- `compare_uniform_nonuniform_rz_mms.dat`

文件格式如下。

```text
# N err_inf_uniform err_l2_uniform err_inf_nonuniform err_l2_nonuniform
```
