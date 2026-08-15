# A01_Boris_3Dxyz_omp

This case compares the OpenMP performance of the `boris_xyz_SoA_omp` test on
two platforms:

- `data_raw/from_AMD`: logs from the AMD server.
- `data_raw/from_kunpeng`: logs from the Kunpeng server.

The original Fortran benchmark and original shell scripts are kept in
`source_f90/`. The top-level `run.sh` does not rerun the benchmark; it parses
the existing logs and writes:

- `output/summary.csv`
- `output/figures/wall_time_vs_threads.png`
- `output/figures/throughput_vs_threads.png`
- `output/figures/speedup_vs_threads.png`

Run:

```bash
bash run.sh
```
