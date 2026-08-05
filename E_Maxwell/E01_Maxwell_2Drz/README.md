# E01_Maxwell_2Drz

[中文](README.zh-CN.md) | [English](README.md)

2D axisymmetric cylindrical `(r,z)` Maxwell/FDTD kernels with two decoupled field-set updates plus 2D RZ CPML.

> Note: `TEz` and `TMz` names follow the axial physical convention: `TEz` uses `Ephi/Hr/Hz`, and `TMz` uses `Er/Ez/Hphi`.

## Files

- `mod_E01_fdtd_2d_rz_tez.f90`: TEz component group module for `Ephi` and `Hr/Hz` updates.
- `sub_E01_fdtd_2d_rz_tez_E.f90`: Updates `Ephi` from `Hr/Hz`.
- `sub_E01_fdtd_2d_rz_tez_H.f90`: Updates `Hr/Hz` from `Ephi`.
- `mod_E01_fdtd_2d_rz_tmz.f90`: TMz component group module for `Er/Ez` and `Ha/Hphi` updates.
- `sub_E01_fdtd_2d_rz_tmz_E.f90`: Updates `Er/Ez` from `Ha/Hphi`.
- `sub_E01_fdtd_2d_rz_tmz_H.f90`: Updates `Ha/Hphi` from `Er/Ez`.
- `mod_E01_cpml_2d_rz_tez.f90`: 2D RZ CPML extension for `Ephi` and `Hr/Hz`.
- `mod_E01_cpml_2d_rz_tmz.f90`: 2D RZ CPML extension for `Er/Ez` and `Ha/Hphi`.

## Notes

The `r=0` axis has dedicated closure logic. The caller owns boundary/ghost fill, sources, CPML memory variables, and time-step orchestration. Double precision is normally selected by compiler flags.
