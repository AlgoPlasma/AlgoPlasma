# E_Maxwell Kunpeng/AMD comparison

This directory stores cross-platform comparison tests for `E_Maxwell`
subroutines. Each subdirectory is one benchmark case and should be runnable on
both AMD and Kunpeng machines with platform-specific entry points:

```bash
./run_amd.sh
./run_amd_ompdo.sh
./run_kunpeng.sh
./run_kunpeng_ompdo.sh
./run_kunpeng_optimized.sh
./clean.sh
```

The first case is:

- `E03_fdtd_3d_cartesian`: single-node benchmark for the 3D Cartesian FDTD
  electric/magnetic update kernels.

## Output convention

Each case writes a small comparison file:

```text
output/key_metrics.csv
```

The same file is also copied to:

```text
data_raw/<platform>/key_metrics.csv
```

Run the platform script on each server so the copied files are kept side by
side:

```bash
./run_amd.sh
./run_amd_ompdo.sh
./run_kunpeng.sh
./run_kunpeng_ompdo.sh
./run_kunpeng_optimized.sh
```

Case-specific raw logs and repeat-level timing files are kept under
`data_raw/<platform>/`.

The scripts pass command-line arguments through to each case:

```bash
THREAD_LIST="1 2 4 8 16 32 64" ./run_amd.sh 160 160 160 100 5
THREAD_LIST="1 2 4 8 16 32 64" ./run_amd_ompdo.sh 160 160 160 100 5
THREAD_LIST="1 2 4 8 16 32 64" ./run_kunpeng.sh 160 160 160 100 5
THREAD_LIST="1 2 4 8 16 32 64" ./run_kunpeng_ompdo.sh 160 160 160 100 5
THREAD_LIST="1 2 4 8 16 32 64" ./run_kunpeng_optimized.sh 160 160 160 100 5
```
