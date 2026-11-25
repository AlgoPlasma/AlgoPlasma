# A01_Boris_3Dxyz_omp

[English](README.md)

本算例对比两种平台上 `boris_xyz_SoA_omp` 测试的 OpenMP 性能：

- `data_raw/from_AMD`：AMD 服务器的日志。
- `data_raw/from_kunpeng`：鲲鹏服务器的日志。

原始 Fortran 基准程序及 Shell 脚本保存在 `source_f90/`。顶层 `run.sh`
读取已有日志并生成以下文件，不会重新运行基准程序。

- `output/summary.csv`
- `output/figures/wall_time_vs_threads.png`
- `output/figures/throughput_vs_threads.png`
- `output/figures/speedup_vs_threads.png`

运行：

```bash
bash run.sh
```
