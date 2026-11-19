# G_Collision

[English](README.md)

`G_Collision` 收集 AlgoPlasma 中的碰撞模型，包含 `G01_MCC`、`G02_MCC_network` 和中性弹性碰撞库 `G03_DSMC`。

## 第一次学习碰撞模拟

推荐从 [G02 零维碰撞盒教程](../tests/009_collision/G02_MCC_network/examples/collision_box/README.zh-CN.md)开始：
观察一群热粒子与较冷气体碰撞后怎样逐渐冷却。
教程解释“零维”、温度与整体运动的区别、随机碰撞次数，以及三张输出图的读法。
只需先了解速度、动能和平均数；模块接口见 [G02 说明](G02_MCC_network/README.zh-CN.md)。

若要从分子运动开始系统学习 DSMC，进入 Sphinx 文档的 `G_Collision → G03_DSMC`。文档按物理、算法与源码导读组织；[文档源入口](../docs/source/rst_files/G_Collision/G03_DSMC.rst)与[模块目录说明](G03_DSMC/README.zh-CN.md)供维护时查阅。

## 子目录

- `G01_MCC`: null-collision MCC；包含截面表读取、截面插值、电子-中性粒子碰撞、离子-中性粒子碰撞和电离二次粒子处理。
- `G02_MCC_network`: 数据驱动的批量 MCC 碰撞网络；提供 C++20 核心，支持二体与三体通道及零维碰撞盒验证算例。测试在运行时生成合成数据，不能用于科研结论。
- `G03_DSMC`: 单一中性原子、等权重粒子的 C++20 DSMC 碰撞库；直接接收柱坐标粒子和非均匀三维网格，支持 HS/VHS/VSS、NTC 与连续候选时钟，提供原理、源码导读和验证判据。

## 依赖

- `G01_MCC` 使用 MPI 和 Fortran `include`；调用方需要配置 MPI、预处理和 include 路径，并保持物理单位一致。
- `G02_MCC_network` 使用 CMake 和 C++20；MPI 和 OpenMP 可选。其测试目录可独立配置和运行。
- `G03_DSMC` 使用 C++20，当前为串行 CPU 实现；构建与输入格式由调用工程决定。[当前测试](../tests/009_collision/G03_DSMC/README.zh-CN.md)覆盖模型、柱坐标网格、两种调度和碰撞弛豫；从仓库根目录运行 `bash tests/009_collision/G03_DSMC/run.sh`。

## 文档

公式、接口和验证方式见各子目录 README 及 Sphinx 的 `G_Collision` 页面。
