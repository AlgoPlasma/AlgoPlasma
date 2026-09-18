# J02_neutral_sn_transport_2Drz

[中文](README.zh-CN.md) | [English](README.en.md)

`J02_neutral_sn_transport_2Drz` provides reusable deterministic discrete-ordinates
(SN) building blocks for steady neutral transport on an axisymmetric r-z mesh.

The spatial operator follows the current prototype's conservative axisymmetric
form

```text
(1/r) d(r mu psi)/dr + d(eta psi)/dz + sigma_t psi = 0.
```

Consequently, a direction-wise constant `psi` is not a radial free-stream
invariant when `mu` is nonzero; regression tests use frozen prototype
coefficients rather than assuming that invariant.

The first implementation stage contains cylindrical geometry, midpoint
full-circle angular nodes, uniform speed groups, reservoir and MC-sampled
inflow construction, flux normalization, a local P1-DG operator,
open-boundary directional sweeps, specular/diffuse wall source iteration,
partial z-low inlet integration, and cell-moment/internal-face-flux
reconstruction. `gauss-chebyshev` is retained as an explicit alias for the
same full-circle midpoint node set and ordering; it is not a second rule.

The phase-space state uses the Fortran-native layout
`psi(3,nr,nz,n_dir)`. The first index stores coefficients of the scaled local
basis `(1, xi, zeta)`. Velocity-space weights contain the two-dimensional polar
measure `v dv dtheta`.

This numerical kernel does not read PIC grids or namelists and does not write
application output. Positivity limiting remains outside the current public
interface.

## Main interfaces

- `sub_J02_initialize_mesh`: validates `r_edge`, `z_edge`, and `active`, then
  constructs the mesh object.
- `sub_J02_build_geometry`: computes cylindrical volumes, face areas, and the
  radial P1 mean correction for a supplied azimuthal span.
- `sub_J02_build_phase_quadrature`: constructs flattened angle-speed nodes and
  weights. `n_angles` must be at least 8 and divisible by 4 so no ordinate lies
  on a coordinate axis.
- `sub_J02_build_maxwellian_inflow_shape`: samples a zero-drift, unit-density
  two-dimensional reservoir Maxwellian.
- `sub_J02_build_drifted_maxwellian_inflow_shape`: samples the same reservoir
  definition with prescribed `(u_r,u_z)`. Temperature is in K, particle mass
  in kg, and drift velocity in m/s.
- `sub_J02_build_mc_crossing_inflow_shape`: converts nonnegative MC crossing
  probability masses per incoming discrete bin into a phase-density shape.
- `sub_J02_normalize_inflow_flux`: scales a nonnegative `inflow_shape` to a
  requested number flux.
- `sub_J02_sweep_all_directions`: solves the open-boundary P1-DG problem. Its
  inputs `sigma_t(nr,nz,n_dir)` and
  `boundary_inflow(4,nr,nz,n_dir)` are respectively the macroscopic removal
  coefficient in `m^-1` and prescribed incoming phase-space density. Optional
  outputs `failed_direction`, `failed_i`, and `failed_k` locate a failed local
  solve without encoding indices into `ierr`.
- `sub_J02_build_partial_zlo_inlet`: converts a physical radial inlet band to
  cylindrical face fractions and local `xi` intervals.
- `sub_J02_build_wall_maxwell_shape`: samples the wall Maxwell speed shape used
  by flux-conserving diffuse reflection.
- `sub_J02_sweep_reflecting`: performs one sweep from a supplied previous wall
  state with a specular/diffuse mixture.
- `sub_J02_solve_source_iteration`: iterates the reflecting boundary state to
  the requested relative tolerance and reports convergence diagnostics.
- `sub_J02_reconstruct_cell_moments` and
  `sub_J02_reconstruct_internal_face_fluxes`: integrate the angular field into
  cell density/velocity and signed internal face number-flux density.
- `sub_J02_reconstruct_open_boundary_fluxes`: separately integrates prescribed
  inflow and interior-trace outflow for the frozen J03 boundary closure. The
  optional z-low `xi` intervals restrict both fluxes to the open part of a
  partially reflecting face.
- `sub_J02_build_sigma_from_frequency`: converts `nu [s^-1]` to
  `sigma_t=nu/speed [m^-1]` for every discrete direction.

Boundary face index order is `r-lo`, `r-hi`, `z-lo`, `z-hi`. Values supplied
for outgoing directions are ignored by the upwind sweep.

## Inflow definitions

The reservoir builders return the sampled phase-space density

```text
f(v_r,v_z) = alpha/pi * exp(-alpha*((v_r-u_r)^2+(v_z-u_z)^2)),
alpha = particle_mass/(2*k_B*temperature).
```

It is a unit-density Maxwellian in two velocity dimensions. Its absolute
normalization is subsequently replaced by `sub_J02_normalize_inflow_flux`.

The MC interface deliberately accepts a different object:
`crossing_bin_probability(m)` is the probability mass of particles observed
crossing the boundary in incoming bin `m`. The converter divides it by
`weight(m)*speed(m)*abs(Omega(m).normal)` to recover a phase-density shape.
After flux normalization, the relative discrete-bin crossing probabilities
are exactly preserved. Do not pass reservoir samples to the MC converter, or
MC crossing histograms directly to the reservoir normalization routine.

All routines return globally unique `SN_ERR_*` codes. Use
`fun_J02_error_message(ierr)` for a readable diagnostic; library routines do
not print directly.

## Source layout

The code follows the AlgoPlasma wrapper convention. One public
`mod_J02_neutral_sn_transport_2Drz.f90` module owns the shared types and uses
preprocessor `include` directives to collect the independently readable
`sub_J02_sn_*.f90` implementation files.

Like the existing AlgoPlasma Fortran kernels, the source uses default `real`.
The supplied test build uses `-fdefault-real-8`, so its numerical verification
is performed in double precision.
