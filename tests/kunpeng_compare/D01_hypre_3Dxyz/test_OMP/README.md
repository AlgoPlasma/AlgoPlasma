# D01_hypre_3Dxyz OpenMP-thread comparison

This case benchmarks the D01 Cartesian Poisson/HYPRE solver on a fixed
`320 x 80 x 320` grid. The benchmark is intended for exactly 4 MPI ranks and
scans OpenMP thread counts per rank. It compares Kunpeng GCC, Kunpeng BiSheng,
and an AMD server.

`main_time.f90` exits if the MPI size is not 4, so keep `NP=4` unless the
hard-coded 4-rank partition in the driver is changed.

## Files

- `main_time.f90`: fixed 4-rank OpenMP-thread benchmark driver.
- `make.sh`: Kunpeng build entry. Use `TOOLCHAIN=gcc` or `TOOLCHAIN=bisheng`.
- `build_config.sh`: selects the Kunpeng HYPRE/MPI/compiler environment.
- `make_AMD.sh`: AMD build entry for a local HYPRE source/install tree.
- `run_threads_gcc.sh`: Kunpeng GCC OpenMP thread sweep.
- `run_threads_bisheng.sh`: Kunpeng BiSheng OpenMP thread sweep.
- `run_AMD.sh`: AMD OpenMP thread sweep.
- `plot-time.py`: parses `run_*_np*_omp*_*.log`, prints mean timings, and writes
  the combined comparison plot.
- `clean.sh`: removes build products, `phi.dat`, generated logs, and local PNG
  comparison plots.

## Default Scan

All three run scripts use `NP=4`, `NREPEAT=5`, and this OpenMP thread list by
default:

```bash
THREAD_LIST="1 2 4 6 8 10 12 14 16 20 22 24 26 28 30 32 48 64"
```

Each run launches:

```bash
mpirun -np ${NP} --bind-to none \
  --mca pml ob1 \
  --mca btl self,vader,tcp \
  -x OMP_NUM_THREADS \
  -x LD_LIBRARY_PATH \
  ${EXE}
```

The scripts only set `OMP_NUM_THREADS`; they do not set `OMP_PROC_BIND`,
`OMP_PLACES`, or NUMA placement.

## Run

The basic workflow is:

1. Build the executable.
2. Run the matching OpenMP thread sweep script.
3. Copy or keep all platform logs in this directory.
4. Run `python3 plot-time.py`.

On the Kunpeng server, the required HYPRE/OpenMPI environments must exist before
running these scripts:

- GCC stack: `/opt/hypre/3.1.0-gcc/env.sh`
- BiSheng stack: `/opt/hypre/3.1.0-bisheng/env.sh`

`build_config.sh` selects the stack from `TOOLCHAIN`, whose default is `gcc`.
For `TOOLCHAIN=gcc`, it uses `ENV_SH=/opt/hypre/3.1.0-gcc/env.sh` and writes
`main_gcc.out`. For `TOOLCHAIN=bisheng`, it uses
`ENV_SH=/opt/hypre/3.1.0-bisheng/env.sh` and writes `main_bisheng.out`.

If those default environment files are not available, set `ENV_SH`, or export
`HYPRE_INC` and `HYPRE_LIB` before running `make.sh`.

### Kunpeng GCC

Build first:

```bash
TOOLCHAIN=gcc bash make.sh
```

Then run the OpenMP thread sweep:

```bash
ENV_SH=/opt/hypre/3.1.0-gcc/env.sh EXE=./main_gcc.out bash run_threads_gcc.sh
```

Generated logs are named like `run_gcc_np4_omp<T>_<R>.log`.

### Kunpeng BiSheng

Build first:

```bash
TOOLCHAIN=bisheng bash make.sh
```

Then run the OpenMP thread sweep:

```bash
ENV_SH=/opt/hypre/3.1.0-bisheng/env.sh EXE=./main_bisheng.out bash run_threads_bisheng.sh
```

Generated logs are named like `run_bisheng_np4_omp<T>_<R>.log`.

### AMD

Build first:

```bash
bash make_AMD.sh
```

`make_AMD.sh` defaults to:

```bash
HYPRE_INC=${HOME}/nfs/hypre/src/hypre/include
HYPRE_LIB=${HOME}/nfs/hypre/src/hypre/lib
HYPRE_SRC=${HOME}/nfs/hypre/src
FC=mpif90
CC=mpicc
```

Then run the OpenMP thread sweep:

```bash
bash run_AMD.sh
```

Generated logs are named like `run_AMD_np4_omp<T>_<R>.log`.

Useful AMD overrides:

```bash
HYPRE_DIR=${HOME}/nfs/hypre/src/hypre EXE=./main.out \
NP=4 NREPEAT=3 THREAD_LIST="1 2 4 8 16 32" bash run_AMD.sh
```

Keep `NP=4` unless `main_time.f90` is changed to support another MPI
partition.

## Logs and Plots

The plotting script expects log files named as follows:

```text
run_gcc_np4_omp<T>_<R>.log
run_bisheng_np4_omp<T>_<R>.log
run_AMD_np4_omp<T>_<R>.log
```

After logs from the target machines are in this directory:

```bash
python3 plot-time.py
```

Outputs:

- `time_3compares_np4.png`: combined KP-GCC, KP-BiSheng, and AMD plot.
- `/mnt/e/kunpeng/time_kp_amd_np4_ylim0_14.png`: additional Windows-side output
  when `/mnt/e/kunpeng` exists.

The plot uses a fixed y-axis range of `0-14 s`. AMD high-thread outliers remain
in the data but may be clipped by that y-axis limit.

`plot-time.py` skips missing platforms. For example, if only GCC and BiSheng
logs are present, the AMD curve is omitted.

## Notes

- `run_threads_gcc.sh`, `run_threads_bisheng.sh`, and `run_AMD.sh` do not build
  the executable. Run the matching build command first.
- `clean.sh` removes local `run_gcc_*`, `run_bisheng_*`, and `run_AMD_*` logs.
  Move logs elsewhere before cleaning if they are still needed.
- The run scripts use `mpirun --bind-to none`, so ranks and OpenMP threads are
  not pinned to cores or NUMA nodes.
