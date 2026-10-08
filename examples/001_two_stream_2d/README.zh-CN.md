# 二维静电双流不稳定性

[中文](README.zh-CN.md) | [English](README.md)

这是一个紧凑的 2D3V 粒子网格（particle-in-cell, PIC）算例，用于演示如何将
AlgoPlasma 组件组装成面向具体应用的时间推进程序。算例使用 `I01` 加载粒子，使用
`B01` 沉积电荷，使用 `D02`、`D05` 和 `D06` 求解静电场，使用 `C01`
将网格场插值到粒子位置，使用 `A01` 推进粒子速度，并通过 `F02` 和
`F04` 输出粒子与场数据。主程序负责粒子位置更新、周期性粒子边界条件和
各计算步骤的执行顺序。

归一化周期计算域大小为 `64 x 64`，采用 `64 x 64` 网格，并包含两束
平均漂移速度分别为 `+/- 3 v_te` 的电子束。其中，
`v_te = sqrt(k_B T_e / m_e)` 是每束麦克斯韦分布在单个速度方向上的
标准差。每束电子在每个网格单元中包含 64 个宏粒子。第二束电子复制第一束
电子的粒子位置并反转所有速度分量，从而形成保持对称性的静启动
（quiet start）。时间步长
为 `0.05 / omega_pe`，程序推进 800 步，终止时刻为
`omega_pe t = 40`。算例通过幅度为 0.005 的纵向粒子位移激发 `(2,1)`
模态，对应一阶近似下 0.5% 的密度扰动。

## 编译与运行

算例依赖 GNU Fortran、CMake、MPI、HYPRE 3.1 或更高版本，以及
NumPy、SciPy 和 Matplotlib。

一种从源码编译 HYPRE 的方式是从
<https://github.com/hypre-space/hypre> 下载 HYPRE，并将 `hypre/`
目录与 `algoplasma/` 目录平行放置：

```text
parent/
├── algoplasma/
└── hypre/
```

然后编译并安装 HYPRE：

```bash
cd hypre/src
./configure
make install -j 8
```

其中 `-j 8` 表示最多同时执行 8 个编译任务。安装完成后，进入本算例目录，
并指定 HYPRE 安装前缀（将占位路径替换为实际的绝对路径）：

```bash
cd ../../algoplasma/examples/001_two_stream_2d
HYPRE_ROOT=/absolute/path/to/hypre/src/hypre bash run.sh
```

`HYPRE_ROOT` 指定的目录必须包含 `include/HYPRE.h` 和 `lib/libHYPRE.*`。
当前 `run.sh` 的默认路径为 `/opt/hypre-3.1.0`，不会自动选择相邻目录中的
源码编译安装路径。

在参考 WSL 环境中，从 AlgoPlasma 仓库根目录执行：

```bash
cd examples/001_two_stream_2d
HYPRE_ROOT=/opt/hypre-3.1.0 \
OMP_NUM_THREADS=8 OMP_PROC_BIND=close OMP_PLACES=cores \
bash run.sh
```

`run.sh` 使用 CMake 配置并编译算例，运行模拟，然后调用 `plot.py`。
默认 OpenMP 设置为 8 个线程、`OMP_PROC_BIND=close` 和 `OMP_PLACES=cores`；
可通过环境变量覆盖这些设置。

当前算例使用单个 MPI 进程运行。除初始时刻和第一个时间步外，程序每隔
5 步向 `output/` 写出一次场数据，每隔 50 步写出一次粒子数据。应用层
主程序位于 `src/main.f90`；数组分配、周期性虚拟网格等算例相关细节位于
`src/two_stream_case.f90`，从而使主程序中的 PIC 循环保持清晰、紧凑。

计算结束后，`plot.py` 会在 `figures/` 目录生成两幅论文用图：

- `fig1_phase_space_evolution.png`
- `fig2_field_growth_energy.png`

这两幅图分别对应论文中的相空间图和场增长／能量图（图 4 和图 5）。
如需根据已有模拟输出重新生成图片，在本算例目录执行 `python3 plot.py`。

## 可复现性

本算例配套于介绍 AlgoPlasma `v1.0.1` 的论文。

参考运行于 2026 年 10 月 4 日完成核验，使用基于提交
`105fe3cc5740a852ccb96b74c339a152272b058a` 的 `develop` 工作区，
并将 `run.sh` 中的默认 HYPRE 路径调整为 `/opt/hypre-3.1.0`。
上述提交和环境信息记录了以下参考结果的来源。

### 参考环境

| 项目 | 参考配置 |
| --- | --- |
| 操作系统 | WSL2 下的 Ubuntu 22.04.5 LTS |
| Linux 内核 | 5.10.16.3-microsoft-standard-WSL2 |
| WSL 报告的 CPU | AMD EPYC 7502 32-Core Processor；64 个逻辑 CPU |
| WSL 可见内存 | 约 62.7 GiB |
| GNU Fortran / GCC | 11.4.0 |
| CMake | 3.22.1 |
| MPI 实现 | Open MPI 4.1.2 |
| HYPRE | 3.1.0；双精度实数运算；启用 MPI 和 OpenMP |
| Python | 3.10.12 |
| NumPy / SciPy / Matplotlib | 2.2.6 / 1.15.3 / 3.10.6 |
| 运行配置 | 1 个 MPI 进程；8 个 OpenMP 线程；close 绑核策略 |

GNU Fortran 编译选项为 `-cpp -DUSE_HDF5=0 -O3 -fdefault-real-8 -fopenmp`。
本算例禁用 HDF5 输出，因此运行时不需要 HDF5。
上述版本为本次运行实际测试的版本，并不表示兼容所有其他编译器或依赖版本。

### 初始化与参考结果

随机种子基值为 `src/case_parameters.f90` 中的
`random_seed_base = 20260810`。Fortran 随机数生成器在
`src/two_stream_case.f90` 中使用
`seed_values(j) = 20260810 + 104729*j` 初始化，其中 `j = 1, ..., nseed`，
`nseed` 由 `random_seed(size=nseed)` 获得。

本次运行完成全部 800 步，达到 `omega_pe*t = 40`。
`plot.py` 中的诊断计算得到以下参考值：

| 物理量 | 参考值 |
| --- | --- |
| PIC 增长率，gamma_PIC / omega_pe | 0.2603342007 |
| 理论增长率，gamma_theory / omega_pe | 0.2615993751 |
| 对数振幅拟合的 R-squared | 0.9835732215 |
| 已记录诊断时刻的最大总能量相对误差绝对值，百分比 | 0.01825332345 |

增长率拟合区间为 `10 <= omega_pe*t <= 19`。能量误差定义为
`100*abs((W(t)-W(0))/W(0))`，在已保存的诊断时刻计算；
`W` 为静电场能量与时间中心化粒子动能之和。
按论文精度舍入后，上述值分别为 `0.2603`、`0.2616`、`0.9836` 和 `0.0183%`。

这些数值是单一配置下的参考结果，并非跨平台测试的通过／失败容差。
不同工具链或线程配置的随机数实现和浮点运算顺序可能不同，
因此不保证输出文件或 PNG 图片逐字节一致。

### 运行时间与内存

参考运行中，完整的配置／编译／运行／绘图流程耗时 **39.57 秒**，
包括算例的首次编译。这是特定机器上的观测值，不是模拟本身的运行时间。

| 仅模拟阶段的测量项 | 参考值 |
| --- | --- |
| 墙钟时间，包括诊断输出 | 28.45 秒 |
| 峰值驻留内存（最大 RSS） | 64,928 KiB（约 63.41 MiB） |

仅模拟阶段的测量采用上述参考配置，使用 1 个 MPI 进程和 8 个 OpenMP 线程。
测量包含初始化和诊断输出，不包含编译和 Python 绘图。

如需重复测量，完成编译后，从本算例目录使用 GNU `time`：

```bash
cd output
OMP_NUM_THREADS=8 OMP_PROC_BIND=close OMP_PLACES=cores \
  /usr/bin/time -v -o resources.log ../build/two_stream_2d
```

该命令会重新运行模拟，并覆盖已有的诊断输出。
日志 `output/resources.log` 记录墙钟时间和最大驻留集大小
（标记为 `kbytes`，Linux 下单位为 KiB）。这些测量是本机上的观测值，
并非性能保证。

## 清理

如需删除编译文件、模拟输出和生成的图片，使算例恢复到初始状态，可运行：

```bash
./clean.sh
```
