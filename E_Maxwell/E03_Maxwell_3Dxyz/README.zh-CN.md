# E03_Maxwell_3Dxyz

[中文](README.zh-CN.md) | [English](README.md)

3D Cartesian `(x,y,z)` Maxwell/FDTD 内核，包含标准 Yee curl 更新和 3D CPML 扩展。

## 文件

- `mod_E03_fdtd_3d_cartesian.f90`: 标准 Cartesian FDTD 模块。
- `sub_E03_fdtd_3d_cartesian_E.f90`: 从磁场更新 `Ex, Ey, Ez`。
- `sub_E03_fdtd_3d_cartesian_H.f90`: 从电场更新 `Hx, Hy, Hz`。
- `mod_E03_cpml_3d_cartesian.f90`: Cartesian CPML 扩展。
- `sub_E03_cpml_3d_cartesian_E.f90`: 在 CPML 区域更新 `Ex, Ey, Ez` 和 memory variables。
- `sub_E03_cpml_3d_cartesian_H.f90`: 在 CPML 区域更新 `Hx, Hy, Hz` 和 memory variables。

## 注意

核心更新不负责外部边界、源项或 MPI ghost exchange。CPML memory variables 需要在时间步之间保留。
