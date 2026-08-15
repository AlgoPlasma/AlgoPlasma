# A01_Boris_3Dxyz

[中文](README.zh-CN.md) | [English](README.en.md)

`A01_Boris_3Dxyz` provides a non-relativistic Boris velocity pusher for a single particle in 3D Cartesian coordinates. It advances the particle velocity `v = (v_x, v_y, v_z)` under prescribed electric and magnetic fields.

## Files

| File | Role |
| --- | --- |
| `mod_A01_Boris_3Dxyz.f90` | Source-level Fortran module entry. It includes and exports the core subroutine. |
| `sub_A01_Boris_3Dxyz.f90` | Core Boris velocity update routine. |

## Interface

```fortran
call sub_A01_Boris_3Dxyz(v, E, B, k)
```

| Argument | Direction | Meaning |
| --- | --- | --- |
| `v(1:3)` | in/out | Particle velocity in Cartesian components. |
| `E(1:3)` | in | Electric field at the particle position. |
| `B(1:3)` | in | Magnetic field at the particle position. |
| `k` | in | Boris parameter, usually `q * dt / (2 * m)`. |

## Usage

The routine is organized as a source-level Fortran module. A calling program usually includes the module entry file and then uses the module:

```fortran
#include "A_Pusher/A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz.f90"

program demo_a01
    use mod_A01_Boris_3Dxyz
    implicit none

    real :: v(3), E(3), B(3), k

    v = (/1.0, 0.0, 0.0/)
    E = 0.0
    B = (/0.0, 0.0, 1.0/)
    k = 0.01

    call sub_A01_Boris_3Dxyz(v, E, B, k)
end program demo_a01
```

Compilation usually requires C preprocessing because the module uses `#include`:

```bash
gfortran -cpp -O2 demo_a01.f90
```

The source uses default `real`. If double precision is required, choose the compiler option at build time, for example:

```bash
gfortran -cpp -O2 -fdefault-real-8 demo_a01.f90
ifx -fpp -O2 -real-size 64 demo_a01.f90
```

## References

[1] J.P. Boris, Relativistic plasma simulation-optimization of a hybrid code, in: Proceedings of the Fourth Conference on Numerical Simulation of Plasmas, Naval Research Laboratory, Washington, D.C., 1970, pp.3-67.

[2] G.L. Delzanno, E. Camporeale, On particle movers in cylindrical geometry for Particle-In-Cell simulations, Journal of Computational Physics, 253 (2013) 259-277. DOI: <a href="https://doi.org/10.1016/j.jcp.2013.07.007" target="_blank" rel="noopener noreferrer">10.1016/j.jcp.2013.07.007</a>
