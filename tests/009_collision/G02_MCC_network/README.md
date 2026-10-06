# G02_MCC_network 测试与验证

[中文](README.zh-CN.md) | [English](README.en.md)

这些测试检查输入能否被正确读取，以及碰撞是否遵守给定模型。初学者先读[零维碰撞盒](examples/collision_box/README.zh-CN.md)，接口主线见[模块说明](../../../G_Collision/G02_MCC_network/README.zh-CN.md)。用户模型的写法见[CSV 数据格式](../../../docs/source/rst_files/G_Collision/G02_MCC_network/csv_format.rst)。

## 目录和数据

- 功能源码在 `G_Collision/G02_MCC_network/`；本目录的 `cpp/` 是 C++ 回归测试，`examples/` 是 C++ 调用程序和碰撞盒。
- `CMakeLists.txt`、`cmake/` 和 `run.sh` 提供构建、安装和测试入口；`tools/validate_model.cpp` 检查用户模型目录。
- 仓库不携带 CSV 数据文件或空白表格。测试根据 C++ 中的最小合成模型，在运行时生成临时 CSV；公共测试模型位于 build 的 `generated_models/{demo_binary,demo_three_body,collision_box_elastic}`。

这些质量、截面和速率只验证软件行为，不能用于真实气体的研究结论。安装包不携带测试数据。

## 运行默认测试

在 Linux/WSL 仓库根目录运行，需要 CMake 3.20 与 C++20 编译器：

```bash
bash tests/009_collision/G02_MCC_network/run.sh
```

脚本在临时构建目录编译，用 CTest 逐项执行；CTest 自动安排合成数据生成。看 `100% tests passed` 和 `PASS: G02_MCC_network build and ctest suite`。失败返回非零状态，按失败项查看诊断。默认脚本开启 AddressSanitizer/UndefinedBehaviorSanitizer，MPI/OpenMP 默认关闭。

| 检查 | 内容 |
|---|---|
| 模型包与插值 | CSV 格式、字段关联、单位、反应约束和数据点之间的取值 |
| 随机数与 C01 | 不同事件/抽样用途的流隔离、等待时间与通道概率、多次碰撞均值和方差 |
| C02–C08 | 各类反应的产物、速度、能量和电荷账本 |
| 批量接口 | 跨步工作区、产物 ID、状态变化、统一提交及失败时粒子保持 |
| 碰撞盒 | 平均速度、温度、碰撞计数和末态分布与简单理论的匹配 |
| 可选 CPU 并行 | 串行/OpenMP 一致性、MPI 全局 ID 与失败协调 |

手动构建并开启并行：

```bash
cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_mcc_tests   -DCMAKE_BUILD_TYPE=Debug -DG02_MCC_ENABLE_MPI=ON -DG02_MCC_ENABLE_OPENMP=ON
cmake --build /tmp/g02_mcc_tests -j 4
ctest --test-dir /tmp/g02_mcc_tests --output-on-failure
```

仅构建库时用 `-DG02_MCC_BUILD_TESTS=OFF`。可选 MPI 需要 C++ MPI 支持；OpenMP 需要对应编译器支持。

## 手动生成和检查

CTest 会自动生成公共模型。直接运行依赖模型路径的测试、文档调用示例或 MPI 碰撞盒前，先执行：

```bash
/tmp/g02_mcc_tests/g02_generate_test_data /tmp/g02_mcc_tests/generated_models
/tmp/g02_mcc_tests/g02_validate_model /tmp/g02_mcc_tests/generated_models/collision_box_elastic
```

检查自己的数据时，最后一个参数改成用户模型目录。PASS 只代表读取和已实现约束检查通过，不证明物理数据可靠。

## 零维碰撞盒与基准

碰撞盒跟踪 A 与固定、等质量 B 背景的弹性碰撞，速度仍有三个分量；“零维”指没有空间变化。零密度/零 dt 时状态保持；接近平衡时检查 Maxwell 分布；不同 dt 用相同总时间核对统计；启用 OpenMP 后可比较逐粒子结果。

```bash
bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh
```

未指定 `--model` 时自动生成进程独占的临时合成包，退出时清理；传 `--model DIR` 时只加载该目录。程序验证用户模型仍满足碰撞盒解析判据所要求的单通道等质量模型。图形输出需要 Python 3 和 Matplotlib，C++ 检查/CTest 不依赖画图。

`bench_batch` 的参数依次为粒子数、通道数、测量次数、OpenMP 线程数和采样器，例如：

```bash
/tmp/g02_mcc_tests/bench_batch 1000000 100 7 8 prefix
```

基准测计算耗时，统计和物理约束由测试验证；并行说明见 [PERFORMANCE.md](PERFORMANCE.md)。

## 测试依据与文献

[C01 的概率依据、两体运动学及碰撞盒推导](../../../docs/source/rst_files/G_Collision/G02_MCC_network/references.rst)给出逐项对应。C01 核对指数时钟和 Poisson 筛选；碰撞盒用当前等质量、恒频率模型的解析矩，不是论文数据拟合。分模块与解析结果对照的方法可参见 [Parodi–Petronio (2025)](https://doi.org/10.1063/5.0241527)，本库未复现该文七个算例。合成数据和通过阈值由本测试定义。
