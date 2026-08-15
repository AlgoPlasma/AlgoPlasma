# J01_continuity_freeflow

[中文](README.zh-CN.md) | [English](README.en.md)

`J01_continuity_freeflow` advances the free-flow continuity equation with a
three-dimensional Lax-Friedrichs finite-volume scheme.

## Files

- `mod_J01_continuity_freeflow.f90`: module wrapper that exposes the subroutine through `include`.
- `sub_J01_continuity_freeflow.f90`: computes directional numerical fluxes and updates the density `n` in place.

## Main Interface

`sub_J01_continuity_freeflow(il,iu,n,s,ux,uy,uz,n0)`:

- `il` / `iu`: reference lower and upper bounds passed in by the caller. In the
  current implementation, the density update actually runs over
  `il(1)-1:iu(1)`, `il(2)-1:iu(2)`, `il(3)-1:iu(3)`.
- `n`: number-density array including guard cells, updated in place. Its
  indexing should follow the current routine contract, not the simpler
  `n(il:iu)` active-cell convention.
- `s`: source term.
- `ux` / `uy` / `uz`: velocity arrays stored on the same indexing layout
  expected by the flux construction in this routine.
- `n0`: work array storing the old density.

## Indexing Convention

The routine does not use the simplest "active density = `n(il:iu)`"
interpretation. With the current array declarations:

- `n`, `s`, `ux`, `uy`, `uz`, and `n0` are declared on
  `il(*)-2:iu(*)+1`.
- The updated density region is `n(il(1)-1:iu(1), il(2)-1:iu(2), il(3)-1:iu(3))`.
- The work arrays are face-staggered:
  `Fx(il(1)-2:iu(1), il(2)-1:iu(2), il(3)-1:iu(3))`,
  `Fy(il(1)-1:iu(1), il(2)-2:iu(2), il(3)-1:iu(3))`,
  `Fz(il(1)-1:iu(1), il(2)-1:iu(2), il(3)-2:iu(3))`.

## Build

The module is organized with Fortran `include`; builds need preprocessing enabled
and this directory on the include path.
