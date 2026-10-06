# J02 SN channel example

This is a small, complete usage example, not the B0/ION application or an accuracy test.
It combines a partial crossing-event inlet, mixed specular/thermal walls, an open
outlet, and prescribed volume loss. The numbered blocks in `sn_channel.f90` match
the J02 Sphinx chapter, ending with **Complete Calculation**.

Run from the repository root:

```bash
OMP_NUM_THREADS=4 OMP_DYNAMIC=FALSE bash examples/J02_sn_channel/run.sh
```

OpenMP is enabled by default. The script adds `-fopenmp` during both compilation
and linking. Use `OPENMP=0 bash examples/J02_sn_channel/run.sh` for a serial build.
Within a rank, only the velocity-node sweeps use OpenMP; wall updates and
reconstruction use the calling thread. This small example demonstrates use, not a speed benchmark.

Requires GNU Fortran; the example and library are both compiled with
`-fdefault-real-8`. Outputs are iteration information, density extrema and
physical particle rates. The coarse 4×6 mesh and 16×12 velocity grid teach the
calling sequence; they do not establish spatial or velocity convergence.

The script writes only `examples/J02_sn_channel/build/`.

## Spatial MPI / hybrid version of the same example

`sn_channel.f90` also accepts the MPI build macro. It creates a Cartesian
communicator, owns only local cells, marks remote interfaces, normalizes the
partial inlet using the **global** inlet area, then uses the same transport
entry and globally sums physical output rates. No global distribution is gathered.

```bash
MPI_NP=4 OMP_NUM_THREADS=2 bash examples/J02_sn_channel/run_mpi.sh
OPENMP=0 MPI_NP=4 bash examples/J02_sn_channel/run_mpi.sh
```

Requires an MPI Fortran compiler/launcher (defaults `mpifort`/`mpiexec`).
Use `MPIFC`, `MPIEXEC`, `MPIEXEC_FLAGS` to override. For local Open MPI
slot limitations, add `MPIEXEC_FLAGS=--oversubscribe`; not for benchmarking.
The process grid chosen by `MPI_Dims_create` must fit inside the 4×6 cell grid.
MPI products are isolated under `build/mpi`; MPI lifetime stays in this driver.
Only ranks at global z-low supply the partial interval arrays. Physical coordinate
values are not shifted to a block-local origin. J03 is not invoked by this example.
