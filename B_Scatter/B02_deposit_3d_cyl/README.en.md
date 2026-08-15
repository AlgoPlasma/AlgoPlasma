# B02_deposit_3d_cyl

[中文](README.zh-CN.md) | [English](README.en.md)

3D cylindrical `(r, phi, z)` PIC charge-density and current-density deposition
utilities. The implementation covers cylindrical node-volume normalization,
periodic `phi` handling, `r=0` axis averaging, and trajectory splitting across
cell boundaries.

## Files

- `mod_B02_deposit_charge_3d_cyl.f90`: Module entry point for charge deposition.
- `sub_B02_deposit_charge_3d_cyl.f90`: Deposits one particle charge to eight
  neighboring nodes.
- `mod_B02_deposit_current_3d_cyl.f90`: Module entry point for current deposition.
- `sub_B02_deposit_current_3d_cyl.f90`: Deposits `Jr`, `Jphi`, and `Jz` with
  swept-volume formulas.
- `mod_B02_average_axis_3d_cyl.f90`: Module entry point for axis averaging.
- `sub_B02_average_axis_charge_3d_cyl.f90`: Averages `rho(0,:,k)`.
- `sub_B02_average_axis_jz_3d_cyl.f90`: Averages `jz(0,:,k)`.

## Public Interfaces

```fortran
call sub_B02_deposit_charge_3d_cyl(rp, phip, zp, qp, wp, dr, dphi, dz, &
    nr, nphi, nz, rho)

call sub_B02_deposit_current_3d_cyl(r0, phi0, z0, r1, phi1, z1, qp, wp, &
    dr, dphi, dz, nr, nphi, nz, dt, jr, jphi, jz)

call sub_B02_average_axis_charge_3d_cyl(nr, nphi, nz, rho)
call sub_B02_average_axis_jz_3d_cyl(nr, nphi, nz, jz)
```

`rho`, `jr`, `jphi`, and `jz` are declared as `(0:nr,0:nphi,0:nz)`. After the
particle loop, average axis charge density and axial current density over
`phi`.

## Compile Notes And Reference

The sources use default `real`; use consistent compiler options such as
`-fdefault-real-8` or `-real-size 64` when double-precision default reals are
required. Algorithm details and formulas live in the Sphinx page
`docs/source/rst_files/B_Scatter/B02_deposit_3d_cyl.rst`.
