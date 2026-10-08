# J02_neutral_sn_transport_2Drz

[中文](README.zh-CN.md) | [English](README.en.md)

`J02_neutral_sn_transport_2Drz` provides reusable deterministic discrete-ordinates
(SN) building blocks for steady neutral transport on an r-z mesh with cylindrical geometry.

The spatial operator follows the reduced conservative cylindrical
form

```text
(1/r) d(r mu psi)/dr + d(eta psi)/dz + sigma_t psi = 0.
```

Consequently, a direction-wise constant `psi` is not a radial free-stream
invariant when `mu` is nonzero. Tests must respect this reduced equation
rather than assume a Cartesian free-stream invariant.

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
application output. If a local P1 polynomial becomes negative at a corner,
the sweep uses a P0 fallback satisfying the constant-test balance equation;
this is not clipping or preservation of the original P1 mean.

## Functional files

- `sub_J02_sn_inflow.f90`: reservoir shapes and crossing-event conversion.
- `sub_J02_sn_source.f90`: prescribed inlet-flux normalization and shared validation.
- `sub_J02_sn_boundary.f90`: partial-inlet area fractions and local intervals.
- `sub_J02_sn_wall.f90`: thermal shape, specular mapping and diffuse-flux normalization.
- `sub_J02_sn_loss.f90`: removal frequency to opacity conversion.
- `sub_J02_sn_sweep.f90`: one sweep, including boundary assembly and positivity recovery.
- `sub_J02_sn_reflection.f90`: source iteration calling the same sweep.

The same module includes all files. Redundant sweep entry points have been removed.
For zero drift, call `sub_J02_build_drifted_maxwellian_inflow_shape` with both drift velocities zero.

## Main interfaces

- `sub_J02_solve_transport`: application entry that selects an open sweep or
  reflecting source iteration and reconstructs cell and face fields into
  `sn_transport_result_type`. Supply exactly one of `boundary_inflow` and
  `zlo_inflow`; partial-inlet interval bounds must be supplied together.
  Check `ierr == SN_SUCCESS` before using any result. Sweep, source iteration and reconstruction can also be called separately.

- `sub_J02_initialize_mesh`: validates `r_edge`, `z_edge`, and `active`, then
  constructs the mesh object.
- `sub_J02_build_geometry`: computes cylindrical volumes, face areas, and the
  radial P1 mean correction for a supplied azimuthal span.
- `sub_J02_build_phase_quadrature`: constructs flattened angle-speed nodes and
  weights. `n_angles` must be at least 8 and divisible by 4 so no ordinate lies
  on a coordinate axis.
- `sub_J02_build_drifted_maxwellian_inflow_shape`: samples the same reservoir
  definition with prescribed `(u_r,u_z)`. Temperature is in K, particle mass
  in kg, and drift velocity in m/s.
- `sub_J02_normalize_inflow_flux`: scales a nonnegative `inflow_shape` to a
  requested number flux.
- `sub_J02_sweep`: performs one P1-DG sweep with prescribed inlet and optional frozen wall data. Its
  inputs `sigma_t(nr,nz,n_dir)` and
  `boundary_inflow(4,nr,nz,n_dir)` are respectively the macroscopic removal
  coefficient in `m^-1` and prescribed incoming phase-space density. Optional
  outputs `failed_direction`, `failed_i`, and `failed_k` locate a failed local
  solve without encoding indices into `ierr`.
- `sub_J02_build_partial_zlo_inlet`: converts a physical radial inlet band to
  cylindrical face fractions and local `xi` intervals.
- `sub_J02_build_wall_maxwell_shape`: samples the wall Maxwell speed shape used
  by flux-conserving diffuse reflection.
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
`fun_J02_error_message(ierr)` for a readable diagnostic. Error reporting uses
return values; progress is printed only when a positive `progress_interval`
is requested.

## Parallel and serial builds

The sweep supports OpenMP (Open Multi-Processing) shared-memory threads.
Compile the J02 module **and link the executable** with `-fopenmp` in GNU Fortran.
Set `OMP_NUM_THREADS=4 OMP_DYNAMIC=FALSE` to request four workers.
Without `-fopenmp`, the same source runs serially; no interface changes are needed.

Only the combined angle-speed loop is parallel. Each task writes one
`psi(:,:,:,m)` slice and traverses its cells in upwind order. Inlet data,
losses, the old field and wall constants are read-only during the sweep.
Within each rank, wall normalization and field reconstruction use the calling thread.
MPI builds additionally exchange upstream data and globally reduce convergence norms.
When several nodes fail, the lowest failing node index is reported after all
tasks finish. A failed sweep must not be used as a valid field.

The SN application test build enables OpenMP by default;
set `OPENMP=0` for a serial build. Ordinary module tests default to serial,
with `OPENMP=1` available. The separate `run_parallel.sh` checks both builds.
Thread count is not a speedup estimate: small grids, memory bandwidth and
serial stages can limit performance.

## Spatial MPI and hybrid builds

MPI partitions the r-z grid into conforming rectangular blocks; each rank owns
local cells and all velocity nodes. It is not velocity-only MPI decomposition.
Build with an MPI Fortran compiler and `-cpp -DJ02_USE_MPI`; add `-fopenmp`
to compile and link for hybrid execution. Without the MPI macro, no MPI dependency
is required.

- `sub_J02_sn_partition.f90`: public `sub_J02_initialize_partition` borrows an
  application-owned, nonperiodic 2D Cartesian communicator; optional `first/count`
  specify custom positive-sized blocks. J02 never initializes/finalizes MPI.
- `sub_J02_initialize_boundary_types(..., partition=part)`: connects matching
  active neighbors as `SN_FACE_REMOTE`, distinct from physical OPEN/WALL faces.
- `sub_J02_sweep(..., partition=part)` and
  `sub_J02_solve_transport(..., partition=part)`: local meshes and fields in,
  local results out; collective calls on every rank, with global failure indices.
- `sub_J02_sn_mpi_sweep.f90`: private upstream DG-plane communication and
  interface-flux reconstruction, reusing the existing DG/sweep kernel.
- `result%partition_flux(4,nr,nz)`: coordinate-signed number-flux density on
  REMOTE faces only. Physical open flux arrays do not include these faces.

Hybrid builds require main-thread calls and at least `MPI_THREAD_FUNNELED`.
Quadrature, precision and stopping options must agree on all ranks. Keep the
borrowed communicator alive and avoid overlapping solves on it. No periodic,
nonconforming or zero-cell partitions are supported; wholly inactive blocks
with positive cell counts are supported.

Applications create the Cartesian communicator and partition, normalize the
inlet by its global area, then call the transport entry on every rank.
With Open MPI, use `mpiexec -np N` to select the number of processes and
`OMP_NUM_THREADS` to select the threads per process in a hybrid build.
Omit `-fopenmp` during compilation and linking for pure MPI.

The MPI consistency runner is `tests/012_fluid/J02_neutral_sn_transport_2Drz/run_mpi.sh`.
B0/ION drivers and J03 remain single-domain. Using MPI output with the existing
J03 requires application-side global field/face assembly; no distributed J03
or automatic gather is claimed.

## Source layout

The code follows the AlgoPlasma wrapper convention. One public
`mod_J02_neutral_sn_transport_2Drz.f90` module owns the shared types and uses
preprocessor `include` directives to collect the independently readable
`sub_J02_sn_*.f90` implementation files.

Like the existing AlgoPlasma Fortran kernels, the source uses default `real`.
The ordinary test build uses `-fdefault-real-8`. Parallel consistency tests
also exercise the compiler's default real precision.

## Model scope

The model retains two spatial coordinates (r,z) and two velocity components
(v_r,v_z). It uses speed and one in-plane angle, without v_theta or the
associated cylindrical velocity dynamics. Cylindrical cell volumes, face
areas and r-weighted integration do not make it full axisymmetric 2D3V kinetics.
