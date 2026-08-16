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

一种已经测试通过的 HYPRE 安装方式是从
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

其中 `-j 8` 表示使用 8 个 CPU 核心并行编译。安装完成后，进入本算例目录运行：

```bash
cd ../../algoplasma/examples/001_two_stream_2d
./run.sh
```

在上述平行目录结构下，`run.sh` 会自动使用 `hypre/src/hypre` 下的
HYPRE 安装路径。如果 HYPRE 安装在其他位置，可显式指定安装前缀：

```bash
HYPRE_ROOT=/path/to/hypre/src/hypre ./run.sh
```

如果已经位于 AlgoPlasma 仓库根目录，则通常直接运行：

```bash
cd examples/001_two_stream_2d
bash run.sh
```

当前算例使用单个 MPI 进程运行。除初始时刻和第一个时间步外，程序每隔
5 步向 `output/` 写出一次场数据，每隔 50 步写出一次粒子数据。应用层
主程序位于 `src/main.f90`；数组分配、周期性虚拟网格等算例相关细节位于
`src/two_stream_case.f90`，从而使主程序中的 PIC 循环保持清晰、紧凑。

计算结束后，`plot.py` 会在 `figures/` 目录生成两幅论文用图：

- `fig1_phase_space_evolution.png`
- `fig2_field_growth_energy.png`

如需删除编译文件、模拟输出和生成的图片，使算例恢复到初始状态，可运行：

```bash
./clean.sh
```
