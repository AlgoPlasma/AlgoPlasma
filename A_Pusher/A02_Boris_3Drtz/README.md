# A02_Boris_3Drtz

[中文](README.zh-CN.md) | [English](README.md)

`A02_Boris_3Drtz` provides a non-relativistic Boris pusher for a single particle in 3D cylindrical coordinates. It advances both position `x = (r, theta, z)` and velocity `v = (v_r, v_theta, v_z)`.

## Files

| File | Role |
| --- | --- |
| `mod_A02_Boris_3Drtz.f90` | Source-level Fortran module entry. It includes and exports the core subroutine. |
| `sub_A02_Boris_3Drtz_push_v_x.f90` | Core cylindrical Boris position-and-velocity update routine. |

## Interface

```fortran
call sub_A02_Boris_3Drtz_push_v_x(x, v, E, B, k, dt)
```

| Argument | Direction | Meaning |
| --- | --- | --- |
| `x(1:3)` | in/out | Particle position `(r, theta, z)`. |
| `v(1:3)` | in/out | Particle velocity `(v_r, v_theta, v_z)`. |
| `E(1:3)` | in | Electric field in cylindrical components. |
| `B(1:3)` | in | Magnetic field in cylindrical components. |
| `k` | in | Boris parameter, usually `q * dt / (2 * m)`. |
| `dt` | in | Time-step size used for the position update. |

## Usage

```fortran
#include "A_Pusher/A02_Boris_3Drtz/mod_A02_Boris_3Drtz.f90"

program demo_a02
    use mod_A02_Boris_3Drtz
    implicit none

    real :: x(3), v(3), E(3), B(3), k, dt

    x = (/1.0, 0.0, 0.0/)
    v = (/0.0, 0.0, 0.0/)
    E = 0.0
    B = (/0.0, 0.0, 1.0/)
    dt = 0.01
    k = 0.01

    call sub_A02_Boris_3Drtz_push_v_x(x, v, E, B, k, dt)
end program demo_a02
```

Compilation usually requires C preprocessing:

```bash
gfortran -cpp -O2 demo_a02.f90
```

The source uses default `real`. If double precision is required, choose the compiler option at build time:

```bash
gfortran -cpp -O2 -fdefault-real-8 demo_a02.f90
ifx -fpp -O2 -real-size 64 demo_a02.f90
```

## References

[1] G.L. Delzanno, E. Camporeale, On particle movers in cylindrical geometry for Particle-In-Cell simulations, Journal of Computational Physics, 253 (2013) 259-277. DOI: <a href="https://doi.org/10.1016/j.jcp.2013.07.007" target="_blank" rel="noopener noreferrer">10.1016/j.jcp.2013.07.007</a>
