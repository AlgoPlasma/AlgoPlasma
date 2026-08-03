# D01_hypre_3Dxyz MPI-rank comparison

This case benchmarks the D01 Cartesian Poisson/HYPRE solver on a fixed
`320 x 80 x 320` grid. It scans MPI process counts while keeping
`OMP_NUM_THREADS=1` by default, so the primary signal is MPI-rank scaling rather
than OpenMP thread scaling.

The domain is partitioned as x-slabs across MPI ranks. The benchmark records
HYPRE solve time, end-to-end total time, and norm diagnostics.

## Files

- `main_time.f90`: MPI-rank benchmark driver.
- `make.sh`: Kunpeng build entry. Use `TOOLCHAIN=gcc` or `TOOLCHAIN=bisheng`.
- `build_config.sh`: selects the Kunpeng HYPRE/MPI/compiler environment.
- `run_mpi_gcc.sh`: Kunpeng GCC MPI-rank sweep. It sources the GCC HYPRE
  environment, recompiles through `./make.sh`, and runs `main_gcc.out`.
- `run_mpi_bisheng.sh`: Kunpeng BiSheng MPI-rank sweep. It sources the BiSheng
  HYPRE environment, recompiles through `./make.sh`, and runs
  `main_bisheng.out`.
- `run_mpi_AMD.sh`: AMD MPI-rank sweep for an already-built executable. It sets
  local HYPRE paths and runs `${EXE:-./main.out}`.
- `plot-time-np.py`: parses `run_*_np*_omp*_*.log`, writes a CSV summary, and
  generates MPI-rank comparison plots.
- `plot.py`: optional `phi.dat` visualizer, used only when `WRITE_PHI=1`.
- `clean.sh`: removes build products, `phi.dat`, and generated PNG files. It
  does not remove old log files or CSV summaries.

## Default scan

The Kunpeng MPI scripts use:

```bash
NP_LIST="1 2 4 8 16 24 32 48 64 128"
OMP_NUM_THREADS=1
NREPEAT=5
```

The AMD script uses the same default rank list, but exposes runtime overrides:

```bash
NP_LIST="1 2 4 8 16 24 32 48 64 128"
OMP_LIST="1"
NREPEAT=5
WRITE_PHI=0
MPI_BIND_ARGS="--bind-to none"
```

`WRITE_PHI=0` keeps `phi.dat` output disabled by default, which avoids mixing
large gather/write cost into the MPI-rank scaling comparison.

## Run

The basic workflow is:

1. Build the executable.
2. Run the matching MPI sweep script.
3. Copy or keep all platform logs in this directory.
4. Run `python3 plot-time-np.py`.

On the Kunpeng server, the required HYPRE/OpenMPI environments must exist before
running these scripts:

- GCC stack: `/opt/hypre/3.1.0-gcc/env.sh`
- BiSheng stack: `/opt/hypre/3.1.0-bisheng/env.sh`

`build_config.sh` selects the stack from `TOOLCHAIN`, whose default is `gcc`.
For `TOOLCHAIN=gcc`, it sources `/opt/hypre/3.1.0-gcc/env.sh`, uses
`/usr/bin/mpicc` and `/usr/bin/mpifort`, and writes `main_gcc.out`. For
`TOOLCHAIN=bisheng`, it sources `/opt/hypre/3.1.0-bisheng/env.sh`, uses
`/opt/openmpi/4.1.4-bisheng/bin/mpicc` and
`/opt/openmpi/4.1.4-bisheng/bin/mpifort`, and writes `main_bisheng.out`.

### Kunpeng GCC

Build first:

```bash
TOOLCHAIN=gcc bash make.sh
```

Then run the MPI-rank sweep:

```bash
TOOLCHAIN=gcc bash run_mpi_gcc.sh
```

`run_mpi_gcc.sh` also sources `/opt/hypre/3.1.0-gcc/env.sh` and calls
`./make.sh` again before launching the scan. Passing `TOOLCHAIN=gcc` keeps that
internal rebuild on the GCC stack even if the shell previously exported a
different `TOOLCHAIN`. The generated logs are named like
`run_gcc_np<N>_omp1_<R>.log`.

### Kunpeng BiSheng

Build first:

```bash
TOOLCHAIN=bisheng bash make.sh
```

Then run the MPI-rank sweep with the same toolchain value:

```bash
TOOLCHAIN=bisheng bash run_mpi_bisheng.sh
```

`run_mpi_bisheng.sh` sources `/opt/hypre/3.1.0-bisheng/env.sh` and calls
`./make.sh` again before launching the scan. Passing `TOOLCHAIN=bisheng` to the
run command keeps that internal rebuild on the BiSheng stack. The generated logs
are named like `run_bisheng_np<N>_omp1_<R>.log`.

### AMD

This directory currently provides the AMD run script but not a dedicated AMD
build script. On the AMD server, first build or provide an executable compatible
with the local HYPRE/OpenMPI installation, using the same sources
(`main_time.f90` plus the D01 C/Fortran interface sources). By default,
`run_mpi_AMD.sh` expects `./main.out`; use `EXE=/path/to/exe` to override it.

The AMD script sets:

```bash
HYPRE_DIR=${HOME}/nfs/hypre/src/hypre
HYPRE_LIB=${HYPRE_DIR}/lib
LD_LIBRARY_PATH=${HYPRE_LIB}:${LD_LIBRARY_PATH}
```

Run the scan:

```bash
EXE=./main.out bash run_mpi_AMD.sh
```

Useful AMD overrides:

```bash
NP_LIST="1 2 4 8 16 24 32 48 64 128" OMP_LIST="1" NREPEAT=3 \
MPI_BIND_ARGS="--bind-to none" EXE=./main.out bash run_mpi_AMD.sh
```

The generated logs are named like `run_AMD_np<N>_omp<T>_<R>.log`.

## Logs and plots

The plotting script expects log files named as follows:

```text
run_gcc_np<N>_omp<T>_<R>.log
run_bisheng_np<N>_omp<T>_<R>.log
run_AMD_np<N>_omp<T>_<R>.log
```

After logs from the target machines are in this directory:

```bash
python3 plot-time-np.py
```

Outputs:

- `time_compare_gcc_bisheng_AMD_np.csv`: mean and standard deviation table.
- `time_compare_<available_compilers>_np_omp<T>.png`: HYPRE and total time vs
  MPI ranks for each available OpenMP thread count.

`plot-time-np.py` skips missing platforms. For example, if only AMD logs are
present, it still generates the AMD-only summary and plot.

## Notes

- `clean.sh` does not remove old `run_*_np*_omp*_*.log` files or
  `time_compare_gcc_bisheng_AMD_np.csv`. Remove or move stale logs before
  plotting a new scan, otherwise old and new results will be averaged together.
- The default run scripts use `mpirun --bind-to none`. They do not pin ranks or
  OpenMP threads to cores or NUMA nodes. AMD can override this with
  `MPI_BIND_ARGS`; the current Kunpeng scripts have the binding argument fixed
  in the script.
- `plot.py` requires `phi.dat`, which is only written when the benchmark runs
  with `WRITE_PHI=1`.
