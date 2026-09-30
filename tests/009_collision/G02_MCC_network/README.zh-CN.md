# G02_MCC_network 测试与验证

[中文](README.zh-CN.md) | [English](README.en.md)

CSV 填写入口：[空白模板、原始示例与检查命令](templates/README.zh-CN.md)。

这里的测试回答两个问题：输入数据能否被正确读取，碰撞程序是否按给定模型工作。
初次接触碰撞模拟，先读[零维碰撞盒教程](examples/collision_box/README.zh-CN.md)：
它解释热粒子怎样冷却、三张图怎么看，以及 `PASS` 的含义。

测试使用合成数据。通过测试表示这些软件检查通过；真实气体的研究仍需合适的物理模型和真实反应数据。

## 代码与算例放在哪里？

G02 的功能代码在 [`G_Collision/G02_MCC_network`](../../../G_Collision/G02_MCC_network/README.zh-CN.md)。本目录集中放置：

- `examples/`：零维碰撞盒、C++、Fortran 和 MPI 调用示例。
- `data/`：合成模型和错误输入测试数据；`cpp/`、`fortran/`：回归测试。
- `CMakeLists.txt`、`cmake/` 和 `run.sh`：构建、安装与测试入口。
- `templates/blank/`：CSV 空白模板；`tools/validate_model.cpp`：模型包检查工具。

这里的 `fortran/` 放 Fortran 测试主程序；库的 Fortran 调用接口位于
`G_Collision/G02_MCC_network/fortran_interface/`。C++ 实现和头文件直接位于 G02 根目录。

构建方法见[模块说明](../../../G_Collision/G02_MCC_network/README.zh-CN.md#构建与测试)。
默认构建库和测试；加上 `-DG02_MCC_BUILD_TESTS=OFF` 可只构建库，仍使用本目录的构建入口。

## 先运行默认测试

在 Linux/WSL 终端中，从 AlgoPlasma 根目录运行。
需要 CMake 3.20 或以上、支持 C++20 的 C++ 编译器、C 与 Fortran 编译器（例如 GCC/gfortran）：

```bash
bash tests/009_collision/G02_MCC_network/run.sh
```

脚本会在临时目录中构建，并用 CTest（CMake 的测试运行工具）逐项运行。
最后应显示 `100% tests passed` 和 `PASS: G02_MCC_network build and ctest suite`。
有一项失败就返回非零状态；根据输出中的失败测试名查具体诊断，不以旧图片判断通过。

默认还开启 AddressSanitizer（内存错误检查）和 UndefinedBehaviorSanitizer（未定义行为检查），
用于发现越界等程序错误。默认不启用 MPI/OpenMP。

## 各组测试在检查什么？

| 测试组 | 用普通话说 |
|---|---|
| 模型包与插值 | 文件引用、单位、反应物和产物是否合理；表格两个已知点之间的取值是否正确 |
| C01 与采样器 | 何时碰撞、选择哪条通道的随机抽样是否符合预期 |
| C02–C08 算法 | 碰撞后生成的粒子、速度和能量收支是否满足各自模型 |
| 批量与 C/Fortran 接口 | 一次处理许多粒子、换一种编程语言调用，结果能否正确传递；失败时数据是否保留 |
| 零维碰撞盒 | 热粒子的平均运动、温度和碰撞次数是否与简化理论相符 |
| 可选并行测试 | 多线程或多进程协作时，粒子编号、交换量和结果是否仍然正确 |

## 启用并行测试

MPI 让多个进程协作，OpenMP 让一个进程内的多个 CPU 线程分工。
安装支持 C++/Fortran 的 MPI 环境和支持 OpenMP 的编译器后，可运行完整测试集：

```bash
cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_mcc_tests \
  -DCMAKE_BUILD_TYPE=Debug -DG02_MCC_ENABLE_MPI=ON -DG02_MCC_ENABLE_OPENMP=ON
cmake --build /tmp/g02_mcc_tests -j 4
ctest --test-dir /tmp/g02_mcc_tests --output-on-failure
```

## 零维碰撞盒

`tests/009_collision/G02_MCC_network/examples/collision_box/` 观察一群 A 与固定 B 背景的弹性碰撞，
两者质量相同。每个粒子仍有三维速度，“零维”指不区分空间位置。

| 对照设置 | 预期结果 |
|---|---|
| 默认热粒子与冷背景 | A 的平均漂移减弱，温度逐渐接近 B；次数统计符合恒频率下的泊松分布 |
| 背景密度为零 | 没有碰撞，粒子速度保持初始值 |
| 时间步为零 | 没有经过时间，粒子状态保持不变 |
| A 一开始就与 B 同温且无漂移 | 统计量保持在平衡值附近，允许有限样本的起伏 |
| 不同步长、相同总时间 | 各次运行均应通过同一理论参照的统计检查，无需逐粒子相同 |
| 不同采样器 | 换一种抽取反应通道的实现，仍应符合相同统计规律 |
| 串行与 OpenMP | 相同种子和设置下，逐粒子结果与碰撞计数一致 |

“速度矩”指平均速度、平均速率平方等统计量；“弛豫”指逐渐接近平衡的过程。
程序把它们与理论曲线比较，同时检查 A 与背景的总动量、总能量收支。
只有运行到足够接近平衡时，才检查末态 Maxwell（麦克斯韦）分布。
缩短时间的算例会跳过尚未达到的检查点。任一实际执行的检查失败都会返回非零状态。

手动运行并生成 CSV、图片：

```bash
bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh
```

结果写到示例目录下已忽略的 `results/`；绘图需要 Python 3 和 Matplotlib，C++ 验证与 CTest 不依赖绘图。参数、公式和输出说明见[算例说明](examples/collision_box/README.zh-CN.md)。

## 基准程序

这里的“基准”测量计算速度；物理判定由上面的测试完成。

`bench_batch` 由同一测试工程构建；其参数依次为粒子数、通道数、测量次数和 OpenMP 线程数。例如 `/tmp/g02_mcc_tests/bench_batch 1000000 100 7 8`。
