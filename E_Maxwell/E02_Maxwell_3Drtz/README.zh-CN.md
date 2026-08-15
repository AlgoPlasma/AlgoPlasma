# E02_Maxwell_3Drtz

[中文](README.zh-CN.md) | [English](README.en.md)

完整 3D 柱坐标 `(r,phi,z)` Maxwell/FDTD 内核，保留 `phi` 方向变化并更新全部六个场分量。

## 文件

- `mod_E02_fdtd_3d_cylindrical.f90`: 模块包装文件。
- `sub_E02_fdtd_3d_cylindrical_E.f90`: 从磁场更新 `Er, Ephi, Ez`。
- `sub_E02_fdtd_3d_cylindrical_H.f90`: 从电场更新 `Hr, Hphi, Hz`。
- `mod_E02_cpml_3d_cylindrical.f90`: 3D 柱坐标 CPML 模块。
- `sub_E02_cpml_3d_cylindrical_E.f90`: 在 CPML 区域更新 `Er, Ephi, Ez` 和 memory variables。
- `sub_E02_cpml_3d_cylindrical_H.f90`: 在 CPML 区域更新 `Hr, Hphi, Hz` 和 memory variables。

## 注意

`phi` 方向通常由调用方处理周期 wrap/ghost fill。径向 metric 和轴线闭合必须与数组位置一致。CPML memory variables 需要跨时间步保留。
