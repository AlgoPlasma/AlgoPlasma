# A03_Higuera_Cary_relativistic_3Dxyz

[中文](README.zh-CN.md) | [English](README.en.md)

`A03_Higuera_Cary_relativistic_3Dxyz` provides a relativistic Higuera-Cary velocity pusher in 3D Cartesian coordinates. It advances the particle velocity under prescribed electric and magnetic fields while accounting for relativistic corrections.

## Files

| File | Role |
| --- | --- |
| `mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher.f90` | Source-level Fortran module entry. It includes and exports the core subroutine. |
| `sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v.f90` | Core relativistic Higuera-Cary velocity update routine. |

## Interface

```fortran
call sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v(v, E, B, k)
```

| Argument | Direction | Meaning |
| --- | --- | --- |
| `v(1:3)` | in/out | Particle velocity in Cartesian components. |
| `E(1:3)` | in | Electric field at the particle position. |
| `B(1:3)` | in | Magnetic field at the particle position. |
| `k` | in | Usually `q * dt / (2 * m)`. |

## Usage

```fortran
#include "A_Pusher/A03_Higuera_Cary_relativistic_3Dxyz/mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher.f90"

program demo_a03
    use mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher
    implicit none

    real :: v(3), E(3), B(3), k

    v = (/0.0, 0.0, 0.0/)
    E = 0.0
    B = (/0.0, 0.0, 1.0/)
    k = 0.01

    call sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v(v, E, B, k)
end program demo_a03
```

Compilation usually requires C preprocessing:

```bash
gfortran -cpp -O2 demo_a03.f90
```

The source uses default `real`. If double precision is required, choose the compiler option at build time:

```bash
gfortran -cpp -O2 -fdefault-real-8 demo_a03.f90
ifx -fpp -O2 -real-size 64 demo_a03.f90
```

The subroutine uses `c = 299792458.0` internally for relativistic correction, so velocity, field, and time-step units should be consistent.

## References

[1] A.V. Higuera, J.R. Cary, Structure-preserving second-order integration of relativistic charged particle trajectories in electromagnetic fields, Phys. Plasmas 24 (2017) 052104. DOI: <a href="https://doi.org/10.1063/1.4979989" target="_blank" rel="noopener noreferrer">10.1063/1.4979989</a>

[2] B. Ripperda, F. Bacchini, J. Teunissen, C. Xia, O. Porth, L. Sironi, G. Lapenta, R. Keppens, A comprehensive comparison of relativistic particle integrators, Astrophys. J. Suppl. Ser. 235 (2018) 21. DOI: <a href="https://doi.org/10.3847/1538-4365/aab114" target="_blank" rel="noopener noreferrer">10.3847/1538-4365/aab114</a>
