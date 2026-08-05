# H_MPI_Exchange Test Report Notes

## Added In This Pass

- Added `tests/008_mpi_exchange/test_H_MPI_Exchange.f90` with a `2 x 2 x 1` four-rank MPI topology covering H01, H02, and H03.
- Added `make.sh` as the Linux build entry and updated `run.sh` as the one-command build, run, and plot entry. `run.ps1` remains as a Windows helper.
- Added `plot_mpi_exchange.py` to read `build/*.dat` outputs and generate three diagnostic figures.
- Added the test README, Sphinx test page, and H module testing guide for documentation.
- Added `tests/H_MPI_Exchange_tests.zh-CN.md` as the Chinese meeting-report note. The case README remains in English.

## Issues Noted During Review

- The local Windows environment used during development did not provide `mpif90`, `mpifort`, `mpiexec`, or `gfortran`, so MPI execution must be verified on a Linux node with an MPI Fortran toolchain.
migration- H01 and H03 blocking exchange helper files use `MPI_DOUBLE` while the Fortran arrays are declared as default `real`. The test build uses `-fdefault-real-8` to keep the MPI datatype consistent with the array storage.
- A stale inline comment in `H03_mpi_exchange_den/sub_H03_mpi_exchange_den.f90` was removed without changing behavior.

## Suggested Presentation Order

- Start from the case layout: four ranks, `2 x 2 x 1` topology, tiny field and density grids, and a small particle set.
- Explain the three assertion groups: H01 halo overwrite and local periodic ghosts, H03 boundary accumulation and periodic folding, and H02 two-species particle migration with absorbing and periodic boundaries.
- Show the generated `fig/*.png` files as diagnostic plots. The pass/fail decision comes from the Fortran assertions.
