# G03_DSMC 测试

[English](README.md)

通过柱坐标接口验证 [G03_DSMC 主库](../../../G_Collision/G03_DSMC/README.zh-CN.md)的
单组分、等权重 HS/VHS/VSS 弹性碰撞，包括 8 个核心检查组和 6 个碰撞弛豫回归。

## 环境与运行

依赖 Bash、支持 C++20 的 GCC/Clang、Python 3 和 Matplotlib 3.6 或以上。
测试直接编译主库的 8 个实现文件。只运行核心检查组或只构建时无需 Python。
可用 `CXX` 选择 C++ 编译器，`PYTHON` 选择绘图的 Python 环境。

从仓库根目录运行：

```bash
bash tests/009_collision/G03_DSMC/run.sh
```

成功时逐组输出 `PASS`，失败时返回非零状态并报告原因。
默认构建目录位于系统临时目录，退出时清理；结果保存在本目录的 `results/`，已由 Git 忽略。
重复运行会覆盖本次运行对应的日志与结果文件。

## 检查范围

| 运行组 | 源码 | 测试目的 |
| --- | --- | --- |
| `models` | `cpp/test_models.cpp` | 确认碰撞核及黏度标定符合模型定义，为事件率提供正确物性 |
| `scattering` | `cpp/test_models.cpp` | 检查弹性碰撞前后相对速率守恒，以及碰后方向统计是否符合指定散射模型 |
| `random` | `cpp/test_geometry.cpp` | 检查随机键重放、字段与用途区分，以及实数端点和整数索引均匀性 |
| `geometry` | `cpp/test_geometry.cpp` | 确认正确单元、真实体积和共同速度基底进入碰撞计算 |
| `conservation` | `cpp/test_stepper.cpp` | 确认完整的多单元、多步调用保持动量与能量守恒 |
| `schedules` | `cpp/test_stepper.cpp` | 确认物理碰撞率正确转化为事件数量、等待时间和选对概率 |
| `replay` | `cpp/test_stepper.cpp` | 确认重排与日志限长保持结果可复现，写回限于传入区间 |
| `errors` | `cpp/test_stepper.cpp` | 确认异常明确上报，失败时整步保留原状态 |
| `relaxation` | `examples/relaxation.cpp` | 检查组合演化的全程守恒，以及后期二阶、四阶统计量的相对平衡误差 |

单独运行与内存检查：

```bash
bash tests/009_collision/G03_DSMC/run.sh schedules
bash tests/009_collision/G03_DSMC/run.sh relaxation
G03_DSMC_SANITIZERS=1 bash tests/009_collision/G03_DSMC/run.sh
```

散射角检查每个角参数抽样 60000 次，候选计数与接受频率各使用 20000 个种子。
这些基础抽样检查与解析结果比较，采用六个标准误差的回归规则。

## 弛豫回归

三种模型与两种调度各运行一次，每组默认使用 N=16384、2000 步、种子 42。
时间步 `dt=1e-7 s`，总时长 200 微秒，数密度 `n=1e21 m^-3`，初始温度 300 K。
粒子位置固定在一个柱坐标单元内，初始全局速度为等量的正负 x 方向双束流。
粒子数用于减小统计涨落，支持 1% 的相对误差检查。

`--check` 执行两类检查：

- **平衡误差**：在后半程 `(100,200]` 微秒内，对第 1001–2000 步的统计量取时间均值。
  三方向能量份额 `Fa` 的目标为 `1/3`，x 分量峰度 `kappa_x` 的目标为 3。
  统一要求 `max_a |3*mean(Fa)-1| <= 1e-2`、`|mean(kappa_x)/3-1| <= 1e-2`。
  峰度先在每步计算，再取时间均值。
- **全程守恒**：每步的温度相对变化与平均速度变化除以初始速率 `v0`，均须不超过 `1e-10`。

任一检查失败即退出非零。自选步数时仍取后半程；较少粒子或较短演化可能无法满足同一精度。
碰撞次数作为诊断量输出。空间输运和输运系数需相应算例。

## 输出与读图

```text
results/
  run.log                         # 运行信息、实测相对误差与通过/失败原因
  relaxation-{HS,VHS,VSS}-{ntc,clock}.csv  # 六组逐步时间序列
  summary.csv                     # 末态、后期均值、相对误差与最大守恒误差
  relaxation.png                  # VSS + NTC 的方向能量与峰度弛豫
```

时间序列每步一行，包含初态，默认共 2001 行。
图的上半部分看方向能量从 `(1,0,0)` 趋近各 `1/3`，下半部分看峰度从 1 趋近 3。
灰色区域为后期取平均区间；`Late mean` 标注时间均值，曲线保留统计涨落。
`summary.csv` 中 `mean_*` 为该区间的均值，`*_relative_error` 为上述两项平衡误差。

只重新绘制已有数据：

```bash
bash tests/009_collision/G03_DSMC/run.sh plots
```

运行测试后重建文档可更新页面内的图。

## 自选参数

保留测试目录内的可执行文件，然后指定粒子数、步数和种子：

```bash
G03_DSMC_BUILD_DIR=tests/009_collision/G03_DSMC/build bash tests/009_collision/G03_DSMC/run.sh build
mkdir -p tests/009_collision/G03_DSMC/results
# MODEL SCHEDULE [particles steps [seed]] [--check]
tests/009_collision/G03_DSMC/build/relaxation VSS ntc 16384 2000 42 --check \
  > tests/009_collision/G03_DSMC/results/relaxation-VSS-ntc.csv
```

显式指定的构建目录会保留，脚本只清理自己创建的临时构建目录。

测试目的、公式与读图说明见 [G03_DSMC Validation](../../../docs/source/tests/009_collision/G03_DSMC.rst)，
模型与接口见[主库说明](../../../G_Collision/G03_DSMC/README.zh-CN.md)。
