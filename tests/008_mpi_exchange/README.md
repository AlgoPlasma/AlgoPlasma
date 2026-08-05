# 008_mpi_exchange

This directory is the small-rank MPI regression entry for `H_MPI_Exchange`.
It runs on 4 MPI ranks with a fixed `2 x 2 x 1` logical topology and checks:

- `H01_mpi_exchange_field`: field ghost/halo overwrite
- `H03_mpi_exchange_den`: density boundary accumulation after scatter
- `H02_mpi_exchange_par`: particle migration across MPI subdomains

This is a compact regression case, not a complete proof of correctness. It is
meant to catch regressions quickly after changes to the H modules.

## Directory Roles

- `test_H_MPI_Exchange.f90`: the actual MPI test driver and assertions
- `plot_mpi_exchange.py`: reads `build/*.dat` and generates diagnostic figures
- `make.sh`: builds the test executable
- `run.sh`: builds, runs the 4-rank case, and plots by default
- `clean.sh`: removes generated files under `build/` and `fig/`
- `run.ps1`: PowerShell helper for the same case

For the detailed case construction, hand-derived expected values, and particle
ownership script, see:

- `docs/source/rst_files/H_MPI_Exchange/mpi_exchange_testing_guide.rst`
- `docs/source/tests/008_mpi_exchange/index.rst`

## Build And Run

```bash
cd tests/008_mpi_exchange
bash run.sh
```

Build only:

```bash
bash make.sh
```

Reuse an existing executable or skip plotting:

```bash
BUILD=0 bash run.sh
PLOT=0 bash run.sh
```

Default settings:

- `FC=mpif90`
- `MPIEXEC=mpiexec`
- `NP=4`
- `MPI_NP_FLAG=-n`

Override them when local command names differ:

```bash
FC=mpifort MPIEXEC=mpirun MPI_NP_FLAG=-np NP=4 bash run.sh
```

The build uses `-fdefault-real-8` because the current H01/H03 blocking
exchange helpers send default `real` arrays with `MPI_DOUBLE`.

## Runtime Notes

Useful prechecks:

```bash
which mpif90
which mpiexec
python3 -c "import matplotlib"
```

The test requires exactly 4 MPI ranks. If `NP` is not `4`, the executable exits
with an error before running assertions.

## Outputs

The Fortran test writes:

- `build/h01_field_faces.dat`
- `build/h03_density_faces.dat`
- `build/h02_particle_exchange.dat`

The plotting script writes:

- `fig/h01_field_exchange.png`
- `fig/h03_density_exchange.png`
- `fig/h02_particle_exchange.png`

The `.dat` files and figures are diagnostic outputs. The pass/fail decision
comes from the Fortran assertions in `test_H_MPI_Exchange.f90`.

A successful run prints:

```text
PASS: H_MPI_Exchange small MPI regression suite.
```

The current implementation also prints one `STOP 0` line per MPI rank on
success. Those lines are expected and are not failure markers.

## Scope And Limits

What this case does cover:

- H01 `x/y` halo exchange on the fixed `2 x 2 x 1` topology
- H01 local `z` periodic ghost fill in the unsplit direction
- H03 `x/y` boundary accumulation samples and local `z` periodic fold samples
- H02 two-species face/edge/corner migration, absorbing removal, and local `z`
  periodic wrap

What it does not cover:

- topologies other than `2 x 2 x 1`
- true z-direction MPI exchange (`domain_split(3)>1`)
- large-particle pressure or buffer-limit scenarios
- exhaustive full-face checking for all H03 paths

## Clean

```bash
cd tests/008_mpi_exchange
bash clean.sh
```

`clean.sh` removes generated data files, compiler cache files, executables, and
figures under `build/` and `fig/`.
