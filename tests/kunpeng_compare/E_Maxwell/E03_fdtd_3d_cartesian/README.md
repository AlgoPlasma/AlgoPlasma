# E03_fdtd_3d_cartesian

This benchmark compares the `E_Maxwell/E03_Maxwell_3Dxyz` Cartesian FDTD
kernels on AMD and Kunpeng machines:

- `sub_E03_fdtd_3d_cartesian_H`
- `sub_E03_fdtd_3d_cartesian_E`

It initializes deterministic 3D field arrays, repeatedly calls the H and E
updates, and writes one compact metrics file for cross-server comparison.

## Run On Each Platform

```bash
./run_amd.sh
./run_amd_ompdo.sh
./run_kunpeng.sh
./run_kunpeng_ompdo.sh
./run_kunpeng_optimized.sh
```

The scripts are intentionally separate so the result directories are stable:

- `run_amd.sh` writes `data_raw/amd/`.
- `run_amd_ompdo.sh` writes `data_raw/amd_ompdo/`.
- `run_kunpeng.sh` writes `data_raw/kunpeng/`.
- `run_kunpeng_ompdo.sh` writes `data_raw/kunpeng_ompdo/`.
- `run_kunpeng_optimized.sh` writes `data_raw/kunpeng_optimized/`.

The default size is intentionally modest:

```text
NX=96 NY=96 NZ=96 NSTEPS=40 REPEATS=3 THREAD_LIST="1 2 4 8 16 32 64"
```

For server runs, increase the problem size through environment variables:

```bash
NX=160 NY=160 NZ=160 NSTEPS=100 REPEATS=5 THREAD_LIST="1 2 4 8 16 32 64" ./run_amd.sh
NX=160 NY=160 NZ=160 NSTEPS=100 REPEATS=5 THREAD_LIST="1 2 4 8 16 32 64" ./run_amd_ompdo.sh
NX=160 NY=160 NZ=160 NSTEPS=100 REPEATS=5 THREAD_LIST="1 2 4 8 16 32 64" ./run_kunpeng_ompdo.sh
NX=160 NY=160 NZ=160 NSTEPS=100 REPEATS=5 THREAD_LIST="1 2 4 8 16 32 64" ./run_kunpeng_optimized.sh
```

## Outputs

```text
output/key_metrics.csv          # thread-sweep summary with derived scaling columns
output/key_metrics_raw.csv      # raw one-row-per-thread data from the Fortran benchmark
output/timing_repeats.csv       # repeat-level timings for every thread count
output/logs/                    # raw stdout logs, one file per thread count
data_raw/<platform>/            # copy of the same files, grouped by platform
```

Important columns in `key_metrics.csv`:

- `platform`, `hostname`, `cpu_model`, `compiler`: machine/build metadata.
- `nx`, `ny`, `nz`, `nsteps`, `repeats`: benchmark size.
- `threads`: OpenMP thread count used for this row.
- `single_step_avg_s`, `single_step_best_s`, `single_step_worst_s`: per-step
  time, derived from the full-run timing divided by `nsteps`.
- `avg_s`, `best_s`, `worst_s`: elapsed time for one full `nsteps` run.
- `component_updates_per_s`: approximate throughput across six field-component
  updates per grid cell per step.
- `speedup_vs_1`, `efficiency_vs_1`: thread scaling relative to the one-thread
  row from the same platform.
- `checksum_e`, `checksum_h`, `total_energy`: numerical fingerprints for
  checking that both machines ran the same workload.

The E03 FDTD H/E update kernels use OpenMP `parallel do collapse(3)` over the
Cartesian grid, so `speedup_vs_1` and `efficiency_vs_1` report the measured
thread scaling for these update loops.
