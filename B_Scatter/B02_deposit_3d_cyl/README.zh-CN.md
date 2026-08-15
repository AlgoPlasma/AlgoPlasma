# B02_deposit_3d_cyl

[中文](README.zh-CN.md) | [English](README.en.md)

三维柱坐标 `(r, phi, z)` PIC 电荷密度与电流密度沉积工具。实现包含柱坐标
节点体积归一化、`phi` 周期处理、`r=0` 轴线平均，以及跨单元轨迹切分。

## 文件

- `mod_B02_deposit_charge_3d_cyl.f90`: 电荷沉积模块入口。
- `sub_B02_deposit_charge_3d_cyl.f90`: 将单个粒子电荷沉积到八个相邻节点。
- `mod_B02_deposit_current_3d_cyl.f90`: 电流沉积模块入口。
- `sub_B02_deposit_current_3d_cyl.f90`: 按扫掠体积沉积 `Jr`、`Jphi` 和 `Jz`。
- `mod_B02_average_axis_3d_cyl.f90`: 轴线平均工具模块入口。
- `sub_B02_average_axis_charge_3d_cyl.f90`: 平均 `rho(0,:,k)`。
- `sub_B02_average_axis_jz_3d_cyl.f90`: 平均 `jz(0,:,k)`。

## 主要接口

```fortran
call sub_B02_deposit_charge_3d_cyl(rp, phip, zp, qp, wp, dr, dphi, dz, &
    nr, nphi, nz, rho)

call sub_B02_deposit_current_3d_cyl(r0, phi0, z0, r1, phi1, z1, qp, wp, &
    dr, dphi, dz, nr, nphi, nz, dt, jr, jphi, jz)

call sub_B02_average_axis_charge_3d_cyl(nr, nphi, nz, rho)
call sub_B02_average_axis_jz_3d_cyl(nr, nphi, nz, jz)
```

`rho`、`jr`、`jphi`、`jz` 均按 `(0:nr,0:nphi,0:nz)` 声明。粒子循环结束后
应对轴线电荷密度和轴向电流密度做方位向平均。

## 编译与参考

源码使用默认 `real`；双精度默认实数需统一编译选项，例如 `-fdefault-real-8`
或 `-real-size 64`。算法细节和公式见 Sphinx 文档
`docs/source/rst_files/B_Scatter/B02_deposit_3d_cyl.rst`。
