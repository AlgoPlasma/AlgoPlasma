# E02_Maxwell_3Drtz

[中文](README.zh-CN.md) | [English](README.md)

Full 3D cylindrical `(r,phi,z)` Maxwell/FDTD kernels retaining `phi` variation and updating all six field components.

## Files

- `mod_E02_fdtd_3d_cylindrical.f90`: Module wrapper.
- `sub_E02_fdtd_3d_cylindrical_E.f90`: Updates `Er, Ephi, Ez` from magnetic fields.
- `sub_E02_fdtd_3d_cylindrical_H.f90`: Updates `Hr, Hphi, Hz` from electric fields.
- `mod_E02_cpml_3d_cylindrical.f90`: 3D cylindrical CPML module.
- `sub_E02_cpml_3d_cylindrical_E.f90`: Updates `Er, Ephi, Ez` and memory variables in CPML regions.
- `sub_E02_cpml_3d_cylindrical_H.f90`: Updates `Hr, Hphi, Hz` and memory variables in CPML regions.

## Notes

The caller usually handles periodic wrap/ghost fill in the `phi` direction. Radial metrics and axis closure must match field-array locations. CPML memory variables must persist across time steps.
