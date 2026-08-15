# D06_phi_to_E

[中文](README.zh-CN.md) | [English](README.en.md)

Computes the three electric field components from the electrostatic potential using second-order central differences (E = -∇φ, dx = dy = dz = 1).

## Files

- `mod_D06_phi_to_E.f90`: Module wrapper.
- `sub_D06_phi_to_E.f90`: Main subroutine.

## Main Interface

```fortran
call sub_D06_phi_to_E(il, iu, phi, Ex, Ey, Ez)
```

- `phi(il(1)-1:iu(1)+1, ...)`: 3D potential array with one ghost layer per side; ghost cells must already be filled (e.g. by D05) before calling.
- `Ex/Ey/Ez(il(1)-1:iu(1)+1, ...)`: Output electric field arrays; values are set on the physical domain `il:iu`.

The stencil is:
```
Ex(i,j,k) = (phi(i-1,j,k) - phi(i+1,j,k)) * 0.5
Ey(i,j,k) = (phi(i,j-1,k) - phi(i,j+1,k)) * 0.5
Ez(i,j,k) = (phi(i,j,k-1) - phi(i,j,k+1)) * 0.5
```

## Dependencies

None (no MPI or external libraries required).
