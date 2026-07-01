# D01_hypre_3Dxyz_omp Kunpeng comparison

This case benchmarks the D01 Cartesian Poisson/HYPRE solver with 4 MPI ranks
on a fixed `32 x 8 x 32` grid. It compares Kunpeng GCC, Kunpeng BiSheng, and
an AMD server across OpenMP thread counts.

## Files

- `main_time.f90`: benchmark driver.
- `make.sh`: Kunpeng build entry. Use `TOOLCHAIN=gcc` or `TOOLCHAIN=bisheng`.
- `make_AMD.sh`: AMD build entry for a local HYPRE source/install tree.
- `run_threads_gcc.sh`: Kunpeng GCC thread sweep.
- `run_threads_bisheng.sh`: Kunpeng BiSheng thread sweep.
- `run_AMD.sh`: AMD thread sweep.
- `plot-time.py`: parses `run_*_np*_omp*_*.log` files and writes comparison plots.

## Run

On Kunpeng:

```bash
TOOLCHAIN=gcc bash make.sh
bash run_threads_gcc.sh

TOOLCHAIN=bisheng bash make.sh
bash run_threads_bisheng.sh
```

On AMD:

```bash
bash make_AMD.sh
bash run_AMD.sh
```

After logs from the target machines are in this directory:

```bash
python3 plot-time.py
```
