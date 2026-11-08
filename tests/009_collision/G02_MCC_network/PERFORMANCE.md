# MCC 并行与性能

## 批量碰撞优化与数值回归

G02 用随机抽样决定一个时间步内哪些粒子发生碰撞。我们希望减少处理每个粒子所需的时间，同时让同一组输入得到相同的碰撞输出。一个例子是，电子的首个候选碰撞要等 0.20 ps 才出现，而当前步长只有 0.05 ps。此时可以直接处理下一个电子。若候选在本步之内，程序会把已经抽出的等待时间交给碰撞内核。

![含电离氦 200 Td 工况下，两版的平均能量与漂移速度随时间重合，下方两幅差值图均为零](he200_replay.png)

**读图。** 蓝实线是历史第 1 轮优化前的 G02，橙虚线是第 7 轮采用版。两版读取相同的初始电子，随机种子为 104729。含电离氦的约化电场为 200 Td，即电场强度与背景气体数密度之比。横轴是模拟物理时间（ns），左图显示平均能量（eV），右图显示漂移速度（纵轴单位为 10⁵ m/s）。2–4 ns 为计时窗口。每 100 步记录一次，从 0.005 ns 到 4 ns 共 800 点。对这一个工况和种子逐点相减，平均能量最大绝对差为 0 eV，漂移速度最大绝对差为 0 m/s。[查看绘图数据](he200_replay.csv)

批量入口可以复用上一时间步的粒子访问顺序。代码先核对数量、各位置的 ID
及存活状态，失序且原索引失效时重新排序。连续粒子容器整批复制到独立快照，
随后仍逐个检查粒子。相邻粒子的物种和状态相同时复用定义查找。

在同一步的已验证快照内，私有碰撞入口复用输入检查结果。相同种子和时间步的
随机数整数前缀可以复用，各粒子的 ID、事件号和用途号仍参与计算。首个候选
在步外时省去碰撞对象准备。在步内时将同一次抽样传给内核。等待时间快速判断
仅在有足够数值余量时排除候选，其余情况沿用完整对数公式。

历史电子群测试覆盖九个工况，包括 He 关闭或开启电离的 20、50、200 Td，
以及 Reid 模型的 1、12、24 Td。每轮用三个随机种子配对比较。七轮试验的
189 对过程 CSV 和 189 对最终粒子文件均逐字节相同。最终版本采用六轮改动，
事件号为零的预计算试验因计时收益不稳定未采用。

历史测速使用单线程和一个 MPI 进程，初始 4000 个电子，时间步 0.05 ps，
预运行和计时各 40000 步。这些记录描述该电子群驱动的有限时间窗口。
多核并行速度需要在相应粒子规模和并行配置下测量。

建议每个 PIC 时间步只调用一次批量 MCC，并跨步保留工作区。MPI（消息传递接口）
按宿主已有的粒子分区运行，OpenMP（共享内存并行）处理每个 rank 的本地粒子。
两者可以同时启用；MCC 不接管粒子迁移、网格划分或背景演化。

## 接入方式

```cpp
#include "mpi.hpp"

// 宿主先 MPI_Init_thread(..., MPI_THREAD_FUNNELED, ...)。
StepOptions options;
options.backend = CpuBackend::OpenMp;
options.threads = 4;
DistributedMccStepper mcc(engine, MPI_COMM_WORLD, options);
VectorParticleAdapter adapter(local_particles);
for (std::uint64_t step = 0; step < steps; ++step) {
    StepReport local_report = mcc.step(adapter, local_background, dt_s, step, seed);
    apply_local_sources(local_report.reservoir);
}
// 所有 rank 在 MPI_Finalize() 之前销毁 mcc。
```

不用 MPI 时，创建一次 `MccWorkspace workspace`，循环里调用
`stepper.step(adapter, background, dt, step, seed, workspace)`。不带工作区的重载
仍可用，但每步会重新分配临时缓冲区。

每个 rank 都调用 `DistributedMccStepper::step()`。粒子 ID 必须全局唯一；宿主迁移
粒子时保留 ID。每次调用返回本 rank 的报告，跨 rank 的源项汇总由宿主决定。
新产物 ID 按 `(parent_id, event_index, product_ordinal)` 的全局顺序分配，与粒子
落在哪个 rank 或线程无关。一个 rank 的准备或容量检查失败时，所有 rank 在提交
前退出，本步粒子不变。MPI 调用必须在主线程执行，线程支持至少为
`MPI_THREAD_FUNNELED`；步进器应在 `MPI_Finalize()` 前销毁。

工作区和适配器均不支持并发重入；一个粒子群保留稳定的 ID 高水位。

## 已实现的优化

- 活动通道按模型、背景、空间单元、物种、状态和采样选项缓存；背景数值变化时
  自动失效。相邻同键粒子复用查找结果；零密度通道做精确剪枝。
- 粒子快照、工作块和通道表跨步复用。已按 ID 排序的输入跳过排序；无出生/删除
  的提交直接原位更新，避免全量重建和更新数组复制。
- 多通道可选别名采样器（alias sampler，常数时间选通道）；默认前缀采样器。
  只有在目标负载的整步计时稳定快于默认方案至少 5% 时才建议启用。
- MPI 仅交换产物 ID 的元数据，不传输正常碰撞粒子；无产物时跳过路由通信。
  本地准备和提交前检查通过集体通信协调，保持整步失败原子性。

## 构建与测量

```bash
cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_mcc_hybrid -DCMAKE_BUILD_TYPE=Release \
  -DG02_MCC_ENABLE_MPI=ON -DG02_MCC_ENABLE_OPENMP=ON
cmake --build /tmp/g02_mcc_hybrid -j 4
ctest --test-dir /tmp/g02_mcc_hybrid --output-on-failure
/tmp/g02_mcc_hybrid/bench_batch 1000000 100 5 32 prefix
/tmp/g02_mcc_hybrid/bench_batch 1000000 100 5 32 alias
/tmp/g02_mcc_hybrid/g02_generate_test_data /tmp/g02_mcc_hybrid/generated_models
mpirun -n 4 /tmp/g02_mcc_hybrid/mpi_collision_box \
  /tmp/g02_mcc_hybrid/generated_models/collision_box_elastic 1000000 5 4
```

以下为本次随机数修复前保留的历史性能记录；本次没有复测这些数值。历史 Release 测量（32 物理核、OpenMPI 4.1.6；5 次中位数，预热 2 至 3 次）：

| 负载 | 配置 | 整步时间 |
| --- | --- | ---: |
| 100 万粒子、100 通道 | 1 线程、前缀 | 1.003 s |
| 同上 | 32 线程、前缀 | 0.110 s |
| 同上 | 32 线程、别名 | 0.105 s |
| 100 万粒子、1 通道碰撞盒 | 1 rank x 1 线程 | 0.288 s |
| 同上 | 2 rank x 1 线程 | 0.130 s |
| 同上 | 4 rank x 1 线程 | 0.068 s |
| 同上 | 4 rank x 4 线程 | 0.029 s |

100 通道基准的旧实现此前约为 0.365 s（32 线程）；当时跨步工作区版本约为
0.110 s。别名采样在这次并行测试里不到 5% 的整步收益，故保持前缀为默认。
MPI 行使用不同的单通道模型，只用于比较同一模型的 rank/thread 扩展，不应和
100 通道行直接比较。基准只测 MCC 整步，不含 Poisson、电荷沉积、电场、位置
推进或壁面；真实 PIC 的最终加速比还取决于它们及宿主粒子分区。
