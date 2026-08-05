# E03_Maxwell_3Dxyz

[中文](README.zh-CN.md) | [English](README.en.md)

3D Cartesian `(x,y,z)` Maxwell/FDTD kernels with standard Yee curl updates and a 3D CPML extension.

## Files

- `mod_E03_fdtd_3d_cartesian.f90`: Standard Cartesian FDTD module.
- `sub_E03_fdtd_3d_cartesian_E.f90`: Updates `Ex, Ey, Ez` from magnetic fields.
- `sub_E03_fdtd_3d_cartesian_H.f90`: Updates `Hx, Hy, Hz` from electric fields.
- `mod_E03_cpml_3d_cartesian.f90`: Cartesian CPML extension.
- `sub_E03_cpml_3d_cartesian_E.f90`: Updates `Ex, Ey, Ez` and memory variables in CPML regions.
- `sub_E03_cpml_3d_cartesian_H.f90`: Updates `Hx, Hy, Hz` and memory variables in CPML regions.

## Notes

Core updates do not own external boundaries, sources, or MPI ghost exchange. CPML memory variables must persist across time steps.
