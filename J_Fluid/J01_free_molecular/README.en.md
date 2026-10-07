# J01_free_molecular

[中文](README.zh-CN.md) | [English](README.en.md)

Two Fortran modules in this directory separate particle preprocessing from retained continuity utilities.

## Particle preprocessing

`mod_J01_neutral_free_molecular_2Drz` accepts mesh, inlet and wall conditions, generates independent histories, and returns reference density, mean velocity, internal fluxes and outgoing boundary fluxes. Its main entry is `sub_J01_free_molecular_mc_2Drz`.

| Implementation file | Responsibility |
| --- | --- |
| `sub_J01_fm_sampling.f90` | Effective inlet area, supply rate, position and velocity sampling |
| `sub_J01_fm_reflection.f90` | Specular reflection or diffuse velocity sampling at the wall temperature |
| `sub_J01_fm_trajectory.f90` | Next-face tracking, residence times and signed crossing counts |
| `sub_J01_fm_statistics.f90` | Density, mean velocity and flux estimators |
| `sub_J01_free_molecular_mc_2Drz.f90` | Validation, history loop, completion status and output |

The current model uses straight r-z trajectories without azimuthal motion, volume ionization or intermolecular collisions. Inlet velocities follow a positive-normal truncated drifting Gaussian distribution of incoming particles; no additional normal-speed weighting is applied. Density uses residence statistics, whereas flux uses signed crossings, not cell-average velocity times density.

The radial injection interval does not turn the remainder of an OPEN face into a wall. Applications supply prescribed inflow using the same particle rate and area. Histories stopped by the tracking limit produce incomplete statistics.

## Retained utilities

`mod_J01_continuity_freeflow` includes:

- `sub_J01_continuity_freeflow.f90`: original normalized Cartesian density update; `s` is a per-step decrement.
- `sub_J01_continuity_freeflow_2Drz.f90`: prescribed-velocity cylindrical flux construction and prescribed-flux density stepping.

These utilities do not sample or track particles. Their public interfaces and Cartesian indexing remain unchanged.

## Build and documentation

Compile only the required module files, with preprocessing and this directory on the include path. Do not compile include files separately. Keep real precision consistent, and use explicit `only` imports when both modules are needed because some constant names overlap.

The Sphinx [J01](../../docs/source/rst_files/J_Fluid/J01_free_molecular.rst) route covers data, injection, reflection, tracking, estimators and the complete calculation. Retained interfaces are under Legacy Utilities; see [J01 tests](../../tests/012_fluid/J01_free_molecular/README.md) for test commands.
