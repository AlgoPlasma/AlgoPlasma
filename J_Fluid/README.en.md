# J_Fluid

[中文](README.zh-CN.md) | [English](README.en.md)

This group provides neutral reference fields, density evolution, and retained continuity utilities. It can supply neutral density to Particle-in-Cell (PIC) applications; charged-particle pushing, electromagnetic fields and reaction-rate calculations belong to other modules.

## Directories

| Directory | Calculation | Main outputs |
| --- | --- | --- |
| `J01_free_molecular` | Free Molecular (FM) inlet sampling, reflection and particle-history statistics | Reference density, mean velocity and signed face fluxes |
| `J02_neutral_sn_transport_2Drz` | Discrete Ordinates (SN) quadrature, transport sweeps and reflection iteration | Reference density, mean velocity, incoming and outgoing fluxes |
| `J03_neutral_continuity_faceflux_2Drz` | Reference-field face coefficients and transient continuity | Current density, fluxes and balance quantities |

J01 and J02 are alternative reference-field methods, not successive steps. J03 consumes geometry and field arrays without depending on preprocessor internals.

The normalized Cartesian continuity routine and prescribed-velocity cylindrical tools remain in a separate module inside the J01 directory.

## Scope and compilation

The neutral preprocessors retain r,z and two velocity components, without azimuthal velocity dynamics. Cylindrical measures do not imply full three-velocity axisymmetric kinetics; each method documents its own equations and approximations. J03 evolves scalar density and does not rerun reference-field calculations.

Compile the required `mod_*.f90` with preprocessing enabled, not the included `sub_*.f90` files. Keep real precision consistent between modules and callers.

## Reading order

The Sphinx [J_Fluid](../docs/source/rst_files/J_Fluid.rst) section contains independent J01 and J02 routes with their local data conventions, J03 with its complete calling sequence, and Legacy Utilities.

Commands and assertions belong to [tests/012_fluid](../tests/012_fluid/README.md), separate from algorithm derivations.
