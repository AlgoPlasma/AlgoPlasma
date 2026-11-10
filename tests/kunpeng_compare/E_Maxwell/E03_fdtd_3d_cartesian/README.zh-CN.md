# E03_fdtd_3d_cartesian

[English](README.md)

本基准测试对比 AMD 和鲲鹏机器上 `E_Maxwell/E03_Maxwell_3Dxyz` 的直角坐标 FDTD 内核：

- `sub_E03_fdtd_3d_cartesian_H`
- `sub_E03_fdtd_3d_cartesian_E`

程序以确定性的方式初始化三维场数组，反复调用 H 场和 E 场更新例程，并写入一个精简的指标文件，供跨服务器比较。

## 在各平台上运行

```bash
./run_amd.sh
./run_amd_ompdo.sh
./run_kunpeng.sh
./run_kunpeng_ompdo.sh
./run_kunpeng_optimized.sh
```

各运行脚本独立，分别写入固定的结果目录：

- `run_amd.sh` 写入 `data_raw/amd/`。
- `run_amd_ompdo.sh` 写入 `data_raw/amd_ompdo/`。
- `run_kunpeng.sh` 写入 `data_raw/kunpeng/`。
- `run_kunpeng_ompdo.sh` 写入 `data_raw/kunpeng_ompdo/`。
- `run_kunpeng_optimized.sh` 写入 `data_raw/kunpeng_optimized/`。

默认问题规模较小：

```text
NX=96 NY=96 NZ=96 NSTEPS=40 REPEATS=3 THREAD_LIST="1 2 4 8 16 32 64"
```

在服务器上运行时，可以通过环境变量增大问题规模：

```bash
NX=160 NY=160 NZ=160 NSTEPS=100 REPEATS=5 THREAD_LIST="1 2 4 8 16 32 64" ./run_amd.sh
NX=160 NY=160 NZ=160 NSTEPS=100 REPEATS=5 THREAD_LIST="1 2 4 8 16 32 64" ./run_amd_ompdo.sh
NX=160 NY=160 NZ=160 NSTEPS=100 REPEATS=5 THREAD_LIST="1 2 4 8 16 32 64" ./run_kunpeng_ompdo.sh
NX=160 NY=160 NZ=160 NSTEPS=100 REPEATS=5 THREAD_LIST="1 2 4 8 16 32 64" ./run_kunpeng_optimized.sh
```

## 输出

```text
output/key_metrics.csv          # 线程数扫描汇总，含派生的扩展性指标
output/key_metrics_raw.csv      # Fortran 基准程序的原始数据，每种线程数一行
output/timing_repeats.csv       # 各线程数下每次重复运行的耗时
output/logs/                    # 标准输出原始日志，每种线程数一个文件
data_raw/<platform>/            # 同一批文件的副本，按平台分组
```

`key_metrics.csv` 中的主要列：

- `platform`、`hostname`、`cpu_model`、`compiler`：机器和构建信息。
- `nx`、`ny`、`nz`、`nsteps`、`repeats`：基准测试规模。
- `threads`：本行数据所用的 OpenMP 线程数。
- `single_step_avg_s`、`single_step_best_s`、`single_step_worst_s`：每步耗时，以完整运行的耗时除以 `nsteps` 得到。
- `avg_s`、`best_s`、`worst_s`：一次完整运行 `nsteps` 步的耗时。
- `component_updates_per_s`：按每步每个网格单元更新六个场分量估算的吞吐量。
- `speedup_vs_1`、`efficiency_vs_1`：相对于同一平台单线程结果的加速比和效率。
- `checksum_e`、`checksum_h`、`total_energy`：用于核对两台机器是否运行了相同工作负载的数值指标。

E03 FDTD 的 H/E 更新内核使用 OpenMP `parallel do collapse(3)` 遍历直角坐标网格。`speedup_vs_1` 和 `efficiency_vs_1` 反映这些更新循环实测的线程扩展性。
