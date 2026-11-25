# 012_fluid Tests

[简体中文](README.zh-CN.md)

This directory tests the neutral reference fields and continuity solvers in
[J_Fluid](../../J_Fluid/README.md). J01 and J02 provide free-molecular (FM) and
discrete-ordinates (SN) preprocessing; J03 advances density using reference-field
face fluxes. The preprocessors use a reduced r-z model with two velocity components,
and J03 solves a scalar density equation.

## Test coverage

| Directory | Checks |
| --- | --- |
| [J01_free_molecular](J01_free_molecular/README.md) | 3 programs: sampling, reflection, trajectories, statistics and the complete FM entry |
| [J02_neutral_sn_transport_2Drz](J02_neutral_sn_transport_2Drz/README.md) | 12 ordinary programs: velocity quadrature, reaction coefficients, DG operators, boundaries, transport and reconstruction; separate parallel-consistency checks |
| [J03_neutral_continuity_faceflux_2Drz](J03_neutral_continuity_faceflux_2Drz/README.md) | 6 programs: closure, transients, equilibria, application configuration and FM/SN-to-J03 integration |
| [application_reference_J01](J03_neutral_continuity_faceflux_2Drz/application_reference_J01/README.md) | Complete FM → J03 loss-free B0 application |
| [application_reference](J03_neutral_continuity_faceflux_2Drz/application_reference/README.md) | Complete SN → J03 B0 and prescribed-loss ION applications |

The 21 ordinary programs use analytical relations, independent integration or
discrete balances as references. Two integration tests pass actual preprocessing
results into J03: the FM case uses a two-cell analytical time solution, and the SN
case uses `psi(r,z)=exp(-a*z)/r` to check spatial refinement and continuity evolution.
Derivations, tolerances and records are in the
[integration-test documentation](../../docs/source/tests/012_fluid/integration_tests.rst).

## Requirements and execution

Bash and GNU Fortran are required. Application acceptance and plotting also need
Python 3, NumPy and Matplotlib; standalone input-grid validation uses only the
Python standard library. Run all commands below from the repository root:

```bash
bash tests/012_fluid/J01_free_molecular/run.sh
bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh
```

Each program must pass its assertions and exit with status zero. Individual logs
are saved in the corresponding `build/` directory.

Application acceptance logic can be checked separately. Build the SN application
drivers before running the Python checks:

```bash
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference/make.sh
python3 tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/test_application_checks.py
```

The build command only creates executables. The Python checks supply negative,
NaN and infinite reference densities to the actual J03 driver and verify rejection
before time stepping. This check is explicitly skipped if the driver has not been
built. Both preprocessing and continuity densities must be finite and nonnegative
in active cells.

## Parallel checks and full applications

The ordinary J02 build recreates its `build/` directory, so run parallel checks
after the ordinary suite:

```bash
bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_parallel.sh
MPIEXEC_FLAGS=--oversubscribe bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_mpi.sh
```

MPI checks require an MPI compiler and launcher. `--oversubscribe` is an optional
Open MPI flag for machines with insufficient process slots. Full applications take
longer; their READMEs linked above describe execution, model scope and acceptance
criteria. Passing the fast suite establishes only the checks covered by those
small cases.

## Outputs and cleanup

Build files and logs remain in each test's `build/`; keep them out of commits.
Full applications also write into their own `build/` by default. Set
`APPLICATION_OUTPUT` to choose another directory. Application scripts require an
empty output directory, so use a new destination for each rerun.

The J03 `clean.sh` removes its own build directory and both full-application build
directories, including stored results. Save needed application outputs elsewhere
first; outputs directed outside those directories remain under the user's control.
See the [shared input guide](J03_neutral_continuity_faceflux_2Drz/application_inputs/README.md)
for the grid and application scope.
