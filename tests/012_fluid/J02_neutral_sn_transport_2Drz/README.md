# J02 neutral SN transport tests

[简体中文](README.zh-CN.md)

Implementation: [module README](../../../J_Fluid/J02_neutral_sn_transport_2Drz/README.md). Run the commands below from the repository root.

Requires Bash and GNU Fortran (`gfortran`); the ordinary runner uses eight-byte real values and runtime bounds checks.

These deterministic tests exercise the discrete ordinates (SN) neutral-transport module at three levels: local procedures, assembled solver, and parallel consistency.

## Local procedures and assembly

The ordinary suite covers:

- two-dimensional velocity-space quadrature and exact equivalence of the
  `midpoint` and `gauss-chebyshev` alias names;
- cylindrical r-z cell volumes, face areas, and weighted means;
- entries of the local P1-DG streaming operator;
- independent three-point Gauss-Legendre integration of all four face operators,
  additive assembly and a worked pivoted 3×3 linear solve;
- two-dimensional Maxwell and drifted-Maxwell reservoir shapes;
- MC crossing-bin conversion and prescribed-flux normalization;
- specific error messages and separate sweep failure indices;
- moment, internal-face flux, and open-boundary flux reconstruction;
- specular/diffuse wall reflection, partial-face inlet integration, and
  reflecting-boundary source iteration.

Run with:

```bash
bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh
```

The ordinary runner executes 12 programs and defaults to a serial real8 build. To exercise it with
OpenMP, set `OPENMP=1 OMP_NUM_THREADS=4 OMP_DYNAMIC=FALSE`.
It also checks conservative positivity recovery, the unified sweep and
transport interfaces, and scaling/error regressions.

`source_f90/test_J02_transport_units.f90` checks axis geometry, topology, the absorption matrix,
frequency conversion, PDF/probability representations of the same inflow,
and signed boundary fluxes.

Run the ordinary suite before the parallel suites: its build script recreates
`build/`. The HTML documentation describes the inputs, reference values and
measured results for the module, assembled-solver and parallel tests.

## Serial/OpenMP consistency

Run the dedicated test from the repository root:

```bash
bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_parallel.sh
```

`source_f90/test_J02_parallel.f90` exercises the existing public
`sub_J02_sweep` and `sub_J02_solve_transport` interfaces. Its nonuniform
2×2 mesh and 16×3 angle-speed grid cover:

- open transport, nonnegative corner values and particle balance;
- pure specular, mixed and pure diffuse walls with a partial inlet,
  an inactive cell and spatially varying volume loss;
- compact and full inlet representations;
- deterministic direction/cell diagnostics for simultaneous failures;
- nonconvergence without stale reconstructed fields.

The script builds default real4 and promoted real8 variants. For each precision,
it runs a serial reference and OpenMP with 1, 2 and 4 workers, three repeats
per worker count. It checks the actual worker count and compares 17-digit text
records of the distribution, density, both velocities, all internal and
boundary flux arrays, and convergence/failure diagnostics. Records must match
exactly **within the same precision**; real4 and real8 are not compared.
The other 11 non-MPI numerical test programs also run in both real8 builds, giving 22 auxiliary runs.
Bounds checking and floating-point exception traps remain enabled.

The historical 2026-10-06 record contains 18 record comparisons and the then-current
16 auxiliary runs, all passing with GNU Fortran in WSL. The script defines the current program list.
Build products and logs are under `build/parallel`; the runner does not remove
existing application outputs. This demonstrates consistency for the covered
cases, not a general performance or discretization-accuracy result.

## Spatial MPI and MPI/OpenMP consistency

`source_f90/test_J02_mpi.f90` tests the same public sweep/transport entries.
A nonuniform 5×3 grid with 16×2 discrete velocities exercises the axis, all quadrants,
open/specular/mixed/diffuse boundaries, a partial inlet, an interface obstacle,
loss, wholly inactive blocks, and repeated successful calls after errors.
It compares local distributions, moments and all internal/open/REMOTE fluxes
with an unsplit reference, checks global particle balance, and checks collective
error codes/global cell locations for one-rank input failures and local numerical
failures. Only the test driver replicates the small global reference on each rank.
The solver works on the local partition.

```bash
MPIEXEC_FLAGS=--oversubscribe bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_mpi.sh
```

The launcher flag is optional and specific to Open MPI with insufficient local slots.
Override `MPIFC`, `MPIEXEC`, `MPIEXEC_FLAGS`, or `MPI_TEST_TIMEOUT` as needed.

The runner covers real4 and real8, pure MPI and hybrid 2/4-thread builds,
six spatial layouts (1×1, 2×1, 1×2, 2×2, 3×1, 1×3), two repeats each, and four
additional custom 2×2 tilings (radial 4+1, axial 2+1). All 76 launches passed
on 2026-10-06 in WSL with GNU Fortran 13.3 and Open MPI, with bounds checks,
floating-point traps and a default 90-second timeout per launch.
Communicator rank reordering is exercised.

Normalized field/flux tolerance is `max(1e-12,100*epsilon)`, reflection tolerance
is `max(1e-10,8*epsilon)`, and relative particle balance allows 100 times the
larger tolerance. MPI reductions are not assumed bitwise invariant across layouts.
Logs and build products remain under `build/mpi/r4` and `build/mpi/r8`.
These checks do not establish multi-node scaling, speedup, full B0/ION validation,
or a distributed J03 implementation.


## Application validation and cleanup

Application-scale B0/ION validation is provided by the J03 application tests.
Both full SN cases were rerun on 2026-10-06 with four OpenMP threads.
The application page and its numerical record document these runs. Large-scale spatial MPI
applications, multi-node performance, and distributed J03 still require validation.

Build files and logs remain visible under `build/`. When no longer needed, run:

```bash
bash tests/012_fluid/J02_neutral_sn_transport_2Drz/clean.sh
```

## Nonuniform speed groups

`test_J02_nonuniform_quadrature.f90` covers explicit edges, invalid inputs, velocity
measure, compatibility with uniform groups, reflection pairing, and transport balance
with partial inlet and three wall models. It supports default real and real8
builds compiled with `-fdefault-real-8`.
The MPI fixture accepts `nonuniform` as its fourth argument to use four nonuniform groups.
The cold/fast accuracy study and its limitations are described in
[nonuniform_speed/README.md](nonuniform_speed/README.md).

## Relative speed and coordinate conversion

`source_f90/test_J02_relative_speed.f90` checks exact geometric cases, physical
cylindrical-to-Cartesian rotation, common-frame invariance, different-frame
conversion, zero diagonals, symmetry and repeatability. It compares all 1,920
pairs from unequal nonuniform node sets against an independent cosine-law
reference and checks representable large/small norms.
Velocity-node construction uses initialized quadrature data.
The generic vector helpers support three components; J02 node reconstruction
sets the azimuthal component to zero and retains the reduced 2D2V model.

The test is discovered by the ordinary build. For isolated real4/real8 serial
and four-worker OpenMP runs without removing any existing build directory:

```bash
python3 tests/012_fluid/J02_neutral_sn_transport_2Drz/relative_speed/run_test.py
```

The runner verifies actual worker counts and identical pair CSVs between serial
and OpenMP within each precision. It overwrites its named outputs only.
See [the test definitions and error measures](relative_speed/README.md).

## CEX coefficient smoke test

`test_J02_cex_coefficients.f90` uses three double-precision checks for analytic
synthetic kernels, ion density normalization, and the collision frequency/sigma_t.
Run only these with `bash tests/012_fluid/J02_neutral_sn_transport_2Drz/cex_coefficients/run.sh`.
See [usage](cex_coefficients/README.md). No physical CEX data is bundled.
