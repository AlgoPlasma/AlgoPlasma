# MPI F_IO Benchmark

这个目录用于测试 `F_IO` 里粒子 I/O 的并行读写速度。

测试内容：

- MPI rank 数：默认 `1 2 4 8 16 32 64`
- 格式：`dat/bin/h5`
- 例程：`F02` 写、`F01` 读
- 每个 rank 写自己的文件，所以结果反映的是当前库的 per-rank file I/O 方案

运行：

```bash
./run.sh
```

默认参数：

- `TOTAL_PARTICLES=4000000`
- `NVAR=12`
- `NREPEAT=3`
- `MPI_COUNTS="1 2 4 8 16 32 64"`
- `PRECISION=single`

默认是固定总粒子数的 strong scaling 测试：

| MPI ranks | np per rank | total particles |
|---:|---:|---:|
| 1 | 4,000,000 | 4,000,000 |
| 2 | 2,000,000 | 4,000,000 |
| 4 | 1,000,000 | 4,000,000 |
| 8 | 500,000 | 4,000,000 |
| 16 | 250,000 | 4,000,000 |
| 32 | 125,000 | 4,000,000 |
| 64 | 62,500 | 4,000,000 |

可以这样改规模：

```bash
TOTAL_PARTICLES=8000000 NREPEAT=2 MPI_COUNTS="1 2 4 8 16 32 64" ./run.sh
```

双精度测试：

```bash
PRECISION=double ./run.sh
```

当前磁盘可用空间约 `211G`。按默认 `TOTAL_PARTICLES=4000000`、`NVAR=6`、`NREPEAT=3` 估算，双精度最后保留一轮 `B_dat/B_bin/B_h5` 原始输出大概几 GB，硬盘放得下。

如果 OpenMPI 需要超订阅参数：

```bash
MPI_EXTRA_ARGS="--oversubscribe" ./run.sh
```

输出：

- `benchmark_results.csv`
- `benchmark_io_speedup.png`
- `benchmark_io_speed.png`
- `run_np2.log`, `run_np4.log`, `run_np8.log`, `run_np16.log`
- `B_dat/`, `B_bin/`, `B_h5/` 是最后一次 rank 数运行留下的原始输出

CSV 里的 `payload_MB` 按数组原始 payload 计算：

```text
nvar * np_per_rank * sizeof(real) * ranks
```

所以 `dat` 的实际磁盘文件会比这个大。主要看 `write_seconds/read_seconds`，它表示完成这一批数据读写实际消耗的总 wall time；`MB/s` 只是用统一 payload 口径换算出来的辅助指标。

`benchmark_io_speedup.png` 用最小 MPI rank 数作为基准。当前结果包含 `1 MPI rank`，所以基准是 `1 MPI rank`：

```text
speedup = time(1 rank) / time(N ranks)
```

当前已跑结果：

- `TOTAL_PARTICLES=4000000`
- `NVAR=12`
- `NREPEAT=3`
- `MPI_COUNTS="1 2 4 8 16 32 64"`
- 运行时使用了 `MPI_EXTRA_ARGS="--oversubscribe"`
- default real size = `4 bytes`
- 所有 `max_abs_diff = 0`

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
