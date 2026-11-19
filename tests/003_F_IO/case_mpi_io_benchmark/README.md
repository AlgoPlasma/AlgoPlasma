# MPI F_IO Benchmark

[简体中文](README.zh-CN.md)

This directory benchmarks parallel particle read and write throughput for `F_IO`.

Test scope

- MPI rank counts default to `1 2 4 8 16 32 64`.
- Formats `dat/bin/h5`.
- `F02` writes and `F01` reads.
- Each rank writes its own file, so the results measure the library's current per-rank file I/O scheme.

Run with defaults.

```bash
./run.sh
```

Default parameters

- `TOTAL_PARTICLES=4000000`
- `NVAR=12`
- `NREPEAT=3`
- `MPI_COUNTS="1 2 4 8 16 32 64"`
- `PRECISION=single`

The default test measures strong scaling with a fixed total particle count.

| MPI ranks | np per rank | total particles |
|---:|---:|---:|
| 1 | 4,000,000 | 4,000,000 |
| 2 | 2,000,000 | 4,000,000 |
| 4 | 1,000,000 | 4,000,000 |
| 8 | 500,000 | 4,000,000 |
| 16 | 250,000 | 4,000,000 |
| 32 | 125,000 | 4,000,000 |
| 64 | 62,500 | 4,000,000 |

To change the scale, use the following command.

```bash
TOTAL_PARTICLES=8000000 NREPEAT=2 MPI_COUNTS="1 2 4 8 16 32 64" ./run.sh
```

To test in double precision, use the following command.

```bash
PRECISION=double ./run.sh
```

The workspace had about `211G` of free disk space. An estimate using `TOTAL_PARTICLES=4000000`, `NVAR=6`, and `NREPEAT=3` puts the final retained set of double-precision raw outputs in `B_dat/B_bin/B_h5` at a few GB, which fits within that space.

If Open MPI requires oversubscription, use the following command.

```bash
MPI_EXTRA_ARGS="--oversubscribe" ./run.sh
```

Outputs

- `benchmark_results.csv`
- `benchmark_io_speedup.png`
- `benchmark_io_speed.png`
- `run_np2.log`, `run_np4.log`, `run_np8.log`, `run_np16.log`
- `B_dat/`, `B_bin/`, and `B_h5/` hold raw outputs from the run at the last rank count.

The CSV column `payload_MB` measures the raw array payload using the following formula.

```text
nvar * np_per_rank * sizeof(real) * ranks
```

The actual `dat` files on disk are larger than this payload. Use `write_seconds/read_seconds` as the primary metrics because they measure the total wall time to write or read the batch. `MB/s` is a secondary metric calculated using the same payload definition.

`benchmark_io_speedup.png` uses the smallest MPI rank count as the baseline. The current results include `1 MPI rank`, so the baseline is `1 MPI rank`.

```text
speedup = time(1 rank) / time(N ranks)
```

Recorded results

- `TOTAL_PARTICLES=4000000`
- `NVAR=12`
- `NREPEAT=3`
- `MPI_COUNTS="1 2 4 8 16 32 64"`
- The run used `MPI_EXTRA_ARGS="--oversubscribe"`.
- default real size = `4 bytes`
- All runs reported `max_abs_diff = 0`.

| format | ranks | np per rank | payload MB | write seconds | read seconds |
|---|---:|---:|---:|---:|---:|
| dat | 1 | 4,000,000 | 183.11 | 54.8712 | 33.0439 |
| bin | 1 | 4,000,000 | 183.11 | 1.5162 | 1.3252 |
| h5 | 1 | 4,000,000 | 183.11 | 1.2530 | 0.9695 |
| dat | 2 | 2,000,000 | 183.11 | 29.9548 | 18.0211 |
| bin | 2 | 2,000,000 | 183.11 | 0.8213 | 0.7316 |
| h5 | 2 | 2,000,000 | 183.11 | 0.6492 | 0.5789 |
| dat | 4 | 1,000,000 | 183.11 | 17.7876 | 10.1286 |
| bin | 4 | 1,000,000 | 183.11 | 0.6068 | 0.6432 |
| h5 | 4 | 1,000,000 | 183.11 | 0.5099 | 0.5166 |
| dat | 8 | 500,000 | 183.11 | 12.3561 | 6.1435 |
| bin | 8 | 500,000 | 183.11 | 0.5518 | 0.6061 |
| h5 | 8 | 500,000 | 183.11 | 0.4946 | 0.5225 |
| dat | 16 | 250,000 | 183.11 | 11.2437 | 5.4891 |
| bin | 16 | 250,000 | 183.11 | 0.5429 | 0.6052 |
| h5 | 16 | 250,000 | 183.11 | 0.4875 | 0.5314 |
| dat | 32 | 125,000 | 183.11 | 11.4032 | 5.4416 |
| bin | 32 | 125,000 | 183.11 | 0.5844 | 0.6343 |
| h5 | 32 | 125,000 | 183.11 | 0.5481 | 0.5578 |
| dat | 64 | 62,500 | 183.11 | 11.6309 | 5.3743 |
| bin | 64 | 62,500 | 183.11 | 0.6217 | 0.6319 |
| h5 | 64 | 62,500 | 183.11 | 0.6276 | 0.6168 |
