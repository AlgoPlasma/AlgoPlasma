# B01_scatter_3Dxyz_omp 鲲鹏性能对比

[English](README.md)

本算例对比原版 `sub_B01_scatter_3Dxyz` 内核的跨平台 OpenMP 性能。AMD 和鲲鹏服务器运行同一个基准程序，两边的日志齐备后，分析脚本会将两个平台的结果绘在同一组图中。

测试用于观察内核采用 `!$omp parallel default(firstprivate) reduction(+:den)` 时，性能如何随线程数和粒子数变化。参数扫描报告每个组合的单次调用耗时、加速比和并行效率。

## 扫描参数

| 参数 | 取值 |
| --- | --- |
| `np` | 10 000, 100 000, 1 000 000, 10 000 000 |
| `nthread` | 1, 2, 4, 6, 7, 8, 9, 10, 12, 14, 16, 32, 64 |
| `nrepeat` | 10（每组 `np`、`nthread` 组合） |
| 网格 | `il = (1,1,1)`，`iu = (12,12,12)`，每侧有 1 层保护单元 |
| `w` | 2.0 |

每个 `np` 取值只在 `[il, iu]` 内随机布置一次粒子，随后在该粒子数的所有线程数组合中复用。在计时区间之外执行 `den = 0`，每次计时只测一次纯沉积调用。

每个 `np`、`nthread` 组合运行 `nrepeat` 次，日志记录单次调用的平均、最短和最长耗时。按平台计算的派生列为：

- `speedup_vs_1 = t(np, 1) / t(np, N)`
- `efficiency_vs_1 = speedup / N`

## 目录结构

```
run_AMD.sh                        # 平台入口：编译、运行并写入 data_raw/from_AMD/log.run
run_kunpeng.sh                    # 平台入口：编译、运行并写入 data_raw/from_kunpeng/log.run
plot.sh                           # 后处理：调用 source_py/analyze.py
source_f90/main.f90               # 基准程序：外层遍历粒子数，内层遍历线程数
         /make.sh clean.sh         # 构建辅助脚本，由 run_*.sh 入口调用
source_py/analyze.py               # 解析日志，缺少数据时正常退出
data_raw/from_AMD/log.run          # 由以下脚本生成： run_AMD.sh
        /from_kunpeng/log.run      # 由以下脚本生成： run_kunpeng.sh
output/summary.csv                 # 只要任一平台有数据就写入
       /figures/                   # 只有两个平台都有数据才写入
```

顶层的三个 `.sh` 文件是仅有的入口。两个 `run_*.sh` 脚本在启动前均设置 `ulimit -s unlimited` 和 `OMP_STACKSIZE=1G`。原版内核用 `firstprivate` 将整个 `(3, np)` 数组复制到每个线程的栈上，当 `np = 1e7` 时，操作系统默认的 8 MB 栈会立即溢出。

## 复现步骤

在 AMD 服务器上运行：

```bash
cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
bash run_AMD.sh        # 清理、编译、运行并写入 data_raw/from_AMD/log.run
```

将本目录复制或同步到鲲鹏服务器后，在该服务器上运行：

```bash
cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
bash run_kunpeng.sh    # 清理、编译、运行并写入 data_raw/from_kunpeng/log.run
```

在分析机器上备齐两个 `log.run` 文件后，运行后处理：

```bash
bash plot.sh
```

只要有任一平台的数据，`plot.sh` 就会写入 `output/summary.csv`。**只有两个平台均有日志时**，脚本才会在 `output/figures/` 中写入三张图。若缺少某个平台的日志，脚本会指出缺失的平台并正常退出。

## 输出图

两个平台的数据齐备后，分析脚本生成：

- `time_vs_threads.png`：平均计算耗时随线程数变化的双对数图。AMD 和鲲鹏各占一张子图，每个 `np` 对应一条曲线。内核为每个线程复制 `par`，使曲线呈典型 U 形，在少量线程时达到最低点，随后上升。
- `speedup_vs_threads.png`：`t(1)/t(N)` 的双对数图，以 `ideal = N` 为参考。实测曲线明显低于理想对角线，在高线程数下会回落到 1 以下，大 `np` 的情形尤其明显。
- `efficiency_vs_threads.png`：`speedup / N`。效率由 1.0 降向 0，展示 `firstprivate + reduction` 的开销多快超过沉积工作量，较小 `np` 的效率下降最快。

## 内存预算

原版内核使用 `default(firstprivate)`，每个线程都会得到一份 `(3, np)` 粒子数组副本。启用 `-fdefault-real-8` 时，每线程占用 `24 × np` 字节。当 `np = 1e7` 且 `nthread = 64` 时，这部分内存约为 `64 × 240 MB ≈ 15 GB`。运行最大粒子数的测试前，先确认目标机器有足够的空闲内存。
