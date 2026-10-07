# 012_fluid tests

The neutral application tests exercise reduced r-z, two-velocity-component
transport, not full axisymmetric 2D3V kinetics. J03 evolves scalar density with
a face-flux closure. The retained 3D Cartesian continuity tests are separate;
their passing does not establish a 3V neutral model.

## Fast checks

```bash
bash tests/012_fluid/J01_free_molecular/run.sh
bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference/make.sh
python3 tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/test_application_checks.py
```

Fortran checks require gfortran. Application validation and plots use NumPy and Matplotlib; input-grid validation itself uses only the standard library. Full applications are separate and may take substantially longer.

The application build above compiles the drivers without running transport.
It enables the test that supplies negative, NaN, and infinite J02 reference
densities to the actual J03 driver and verifies rejection before time stepping.
Without that build, the driver test is explicitly skipped. Both preprocessing
and continuity densities must be finite and nonnegative in active cells.

## Test order and analytical references

The three ordinary runners execute 20 small programs: five J01, nine J02 and
six J03 programs. Run local tests first. The J03 runner finishes with two actual
preprocessing-to-continuity tests:

- `test_J01_J03_channel.f90`: tracked histories and normalized tallies feed J03;
  a two-cell analytical time solution checks step refinement. A complete sampled
  FM run additionally checks injection, crossing balance and closure.
- `test_J02_J03_analytic.f90`: J02 solves the reduced transport field
  `psi(r,z)=exp(-a*z)/r` on three grids. Actual density and face fluxes feed J03,
  which fills from zero and recovers the reference field.

Local checks also include analytical sampling probabilities, independent DG face
integration and a transient storage balance with old-time flux and new-time loss.
See [the integration test documentation](../../docs/source/tests/012_fluid/integration_tests.rst)
for derivations, tolerances, results and limits.

Run OpenMP and MPI/hybrid checks after the ordinary J02 runner, because the
ordinary build recreates its build directory:

```bash
bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_parallel.sh
MPIEXEC_FLAGS=--oversubscribe bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_mpi.sh
```

`--oversubscribe` is an Open MPI option for a local machine with too few slots;
it is not required on a suitably allocated cluster.

## Generated outputs

Build files remain visible in `git status`. Keep them out of commits.
Preserve application outputs that are still needed; the J03 clean script removes
outputs stored in its build directories.

The application scripts refuse to overwrite a nonempty output directory. Set APPLICATION_OUTPUT to a new path for a rerun. No full-application pass should be inferred from fast-test results.
