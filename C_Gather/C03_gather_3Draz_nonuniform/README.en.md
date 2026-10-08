# C03: Nonuniform 3D RAZ Field Gather

[中文](README.zh-CN.md) | [English](README.en.md)

Gather fields at physical coordinates `(r [m],alpha [rad],z [m])` using D04-style cell indexing; return cylindrical E/B components.

- `Er/Ea/Ez`: `(face,center,center)` / `(center,face,center)` / `(center,center,face)`.
- `Br/Ba/Bz`: `(face,face,face)`.

This layout supports staggered electrostatic E and prescribed nodal B, not E02 Yee fields. The caller prepares particle ownership, ghost fields, and physical boundaries.

## Files and Interfaces

- `mod_C03_gather_3Draz_nonuniform.f90`: Module entry.
- `sub_C03_gather_3Draz_nonuniform.f90`: Particle-array wrapper.
- `sub_C03_gather_3Draz_nonuniform_point.f90`: Single-point gather.
- `sub_C03_gather_helpers.f90`: Public sub_C03_check_grid and private helpers.

## Call Fragment

Assumes geometry and field arrays are already allocated and populated.

```fortran
use mod_C03_gather_3Draz_nonuniform
! After declarations and geometry/field initialization:
call sub_C03_check_grid(il(1),iu(1),r_face,dr)
call sub_C03_check_grid(il(2),iu(2),a_face,da)
call sub_C03_check_grid(il(3),iu(3),z_face,dz)
call sub_C03_gather_3Draz_nonuniform_point( &
    x,il,iu,r_face,a_face,z_face,dr,da,dz,Er,Ea,Ez,Br,Ba,Bz,E,B)
```

Optional arguments: `cell(3)` is a read-only cell cache; `a_period>0` enables angular wrapping; `a_origin` defaults to zero and requires the period.

Compile only the module entry with `gfortran -cpp`. Default `real` is used; for double precision, apply `-fdefault-real-8` consistently to the caller and module.

[Full interface, formulas, and boundary contracts](../../docs/source/rst_files/C_Gather/C03_gather_3Draz_nonuniform.rst).
