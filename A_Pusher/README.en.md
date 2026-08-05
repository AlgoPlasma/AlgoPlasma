# A_Pusher

[中文](README.zh-CN.md) | [English](README.en.md)

`A_Pusher` collects particle-pushing algorithms in AlgoPlasma. These routines update particle velocity or phase-space state under prescribed electric and magnetic fields, particle charge-to-mass ratio, and time step. The current directory contains three pushers for Cartesian coordinates, cylindrical coordinates, and relativistic velocity updates.

## Current Algorithms

| ID | Directory | Algorithm | Main purpose |
| --- | --- | --- | --- |
| A01 | [`A01_Boris_3Dxyz`](A01_Boris_3Dxyz/) | Non-relativistic Boris pusher in 3D Cartesian coordinates | Advances the velocity `v = (v_x, v_y, v_z)` of a single particle by one full Boris step. |
| A02 | [`A02_Boris_3Drtz`](A02_Boris_3Drtz/) | Non-relativistic Boris pusher in 3D cylindrical coordinates | Advances both position `x = (r, theta, z)` and velocity `v = (v_r, v_theta, v_z)` for a single particle. |
| A03 | [`A03_Higuera_Cary_relativistic_3Dxyz`](A03_Higuera_Cary_relativistic_3Dxyz/) | Relativistic Higuera-Cary pusher in 3D Cartesian coordinates | Updates relativistic particle velocity for high-speed particles and strong electromagnetic fields. |

## A01_Boris_3Dxyz

- Module entry: `mod_A01_Boris_3Dxyz.f90`
- Core routine: `sub_A01_Boris_3Dxyz(v, E, B, k)`
- Coordinate system: 3D Cartesian / `xyz`
- Updated quantity: velocity `v`
- Scope: non-relativistic single-particle velocity push

This implementation follows the standard Boris structure: electric-field half kick, magnetic-field rotation, and a second electric-field half kick. The parameter `k` denotes `q dt / 2m`.

## A02_Boris_3Drtz

- Module entry: `mod_A02_Boris_3Drtz.f90`
- Core routine: `sub_A02_Boris_3Drtz_push_v_x(x, v, E, B, k, dt)`
- Coordinate system: 3D cylindrical / `rtz`
- Updated quantities: position `x` and velocity `v`
- Scope: non-relativistic cylindrical-coordinate particle push

This implementation performs the Boris velocity update in cylindrical coordinates and advances the particle position with the corresponding cylindrical geometry. Electric and magnetic field components should be provided in cylindrical components.

## A03_Higuera_Cary_relativistic_3Dxyz

- Module entry: `mod_A03_Higuera_Cary_relativistic_3Dxyz_pusher.f90`
- Core routine: `sub_A03_Higuera_Cary_relativistic_3Dxyz_push_v(v, E, B, k)`
- Coordinate system: 3D Cartesian / `xyz`
- Updated quantity: velocity `v`
- Scope: relativistic velocity push

This implementation uses the relativistic Higuera-Cary scheme. It converts velocity to proper velocity `u = gamma v`, applies the electric half kicks and magnetic rotation, and converts the result back to velocity.

## Usage

The pushers are currently organized as source-level Fortran modules. A calling program usually includes the corresponding `mod_*.f90` entry file:

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

Compilation usually requires C preprocessing:

```bash
gfortran -cpp -O2 -fdefault-real-8 demo_a01.f90
```
