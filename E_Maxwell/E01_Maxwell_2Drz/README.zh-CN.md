# E01_Maxwell_2Drz

[中文](README.zh-CN.md) | [English](README.en.md)

2D 轴对称柱坐标 `(r,z)` Maxwell/FDTD 内核，包含两套解耦场分量更新和 2D RZ CPML。

> 注意：`TEz` 和 `TMz` 命名采用相对于 z 轴的物理约定：`TEz` 使用 `Ephi/Hr/Hz`，`TMz` 使用 `Er/Ez/Hphi`。

## 文件

- `mod_E01_fdtd_2d_rz_tez.f90`: TEz 分量组模块，收纳 `Ephi` 和 `Hr/Hz` 更新。
- `sub_E01_fdtd_2d_rz_tez_E.f90`: 用 `Hr/Hz` 更新 `Ephi`。
- `sub_E01_fdtd_2d_rz_tez_H.f90`: 用 `Ephi` 更新 `Hr/Hz`。
- `mod_E01_fdtd_2d_rz_tmz.f90`: TMz 分量组模块，收纳 `Er/Ez` 和 `Ha/Hphi` 更新。
- `sub_E01_fdtd_2d_rz_tmz_E.f90`: 用 `Ha/Hphi` 更新 `Er/Ez`。
- `sub_E01_fdtd_2d_rz_tmz_H.f90`: 用 `Er/Ez` 更新 `Ha/Hphi`。
- `mod_E01_cpml_2d_rz_tez.f90`: `Ephi` 与 `Hr/Hz` 的 2D RZ CPML 扩展。
- `mod_E01_cpml_2d_rz_tmz.f90`: `Er/Ez` 与 `Ha/Hphi` 的 2D RZ CPML 扩展。

## 注意

轴线 `r=0` 有专门闭合逻辑。调用方需要负责边界/ghost 填充、源项、CPML memory variables 和时间步调度。双精度通常由编译选项决定。
