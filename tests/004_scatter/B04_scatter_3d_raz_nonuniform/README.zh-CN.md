# B04 非均匀柱坐标沉积测试

[English](README.md)

测试直接编译并调用 B04 的四个公开例程，以及用于均匀网格对照的 B02 公开电荷沉积例程。
参考结果由手算、独立的 Gauss 积分及解析体积平均构造。

## 文件与测试范围

| 文件 | 作用 |
| --- | --- |
| [source_f90/main.f90](source_f90/main.f90) | 数值算例、参考值与通过判据 |
| [run.sh](run.sh) | 以一致选项编译 B04、B02 和测试主程序，运行测试并导出数据 |
| [plot_results.py](plot_results.py) | 从本地双精度数据生成英文文档插图 |

每种配置执行 **79 项断言**，另在公开例程调用后检查返回状态。

| 算例 | 检查内容 |
| --- | --- |
| 八节点手算 | 节点体积、增量、总量、正负抵消、零贡献、数组下界和内部面的两种单元表示 |
| 物理角点粒子 | 贡献写入对应端点，总量保持 |
| 线性场投影 | 单元体积平均与解析积分一致 |
| 四组网格 | 含轴全周、环域全周、环域角向物理端面、单个周期角单元：体积、均匀密度、带符号总量、单元平均总量及接缝/端点处理 |
| 非均匀轴点 | 加权参考值、同一物理轴点的密度一致性，以及正负输入和沉积后总量的保持 |
| 公开 B02 对照 | 从轴开始的均匀全周网格上，在轴点平均前比较节点数组；采用 71 个确定性粒子，含正负电荷和可变权重 |
| 参数错误 | 返回码和目标数组保持原值 |
| 浮点范围（19 项断言） | 体积倒数及加法的范围限制、抵消、周期重复目标、大幅值和零场的单元平均；拒绝操作时保留整个目标数组 |

两点张量积 Gauss 积分构造确定性贡献，检查分配权重与柱坐标体积归一化能否恢复均匀物理密度。
具体输入、公式和结果图见[双语 Sphinx 测试源文件](../../../docs/source/tests/004_scatter/B04_scatter_3d_raz_nonuniform.rst)。

## 运行与判读

需要 Bash（例如 Linux 或 WSL 环境）、GNU Fortran，以及仓库内 B04 和 B02 的源文件。
从仓库根目录执行：

```bash
bash tests/004_scatter/B04_scatter_3d_raz_nonuniform/run.sh double debug
bash tests/004_scatter/B04_scatter_3d_raz_nonuniform/run.sh double release
bash tests/004_scatter/B04_scatter_3d_raz_nonuniform/run.sh single debug
```

- `FC` 可指定编译器路径；脚本选项按 GNU Fortran 编写。
- 各配置启用预处理并使用 Fortran 2008。`double` 加入 `-fdefault-real-8`；
  `single` 使用默认实数精度。所有源文件采用一致选项。
- `debug` 启用 `-fcheck=all` 和 `-ffpe-trap=invalid,zero,overflow`；
  `release` 使用 `-O2`。完整选项见 [run.sh](run.sh)。
- 产物保存在测试目录的 `build/<precision>-<mode>/` 中，由 Git 忽略。

成功运行时退出码为 0，最后一行为：

```text
B04 PASS: checks=79, real_bits=64
```

单精度对应 `real_bits=32`。断言失败时输出 `FAIL` 并非零退出；返回码不符合预期时也非零退出。
`METRIC` 行给出数值误差。多数比较采用 `2048*epsilon(1.0)`，并按对应物理量或数值量缩放。
大幅值单元平均以 `huge(1.0)` 归一化，按 `16*epsilon(1.0)` 检查。
状态码和数组保留使用直接判断；完整判据见测试页及[测试源码](source_f90/main.f90)。

## 本地数据与绘图

运行脚本向 `build/<precision>-<mode>/` 导出 CSV：`hand_nodes.csv` 和 `uniform_nodes.csv`
对应图 1、图 2；`axis_nodes.csv`、`axis_metrics.csv` 和 `axis_totals.csv` 分别保存轴点密度、
误差及总量。可执行程序的第一个可选参数指定已有输出目录，运行脚本会传入该参数；
省略此参数时，可执行程序仅运行检查，不导出 CSV。

完成 double/debug 测试后，从仓库根目录执行：

```bash
python tests/004_scatter/B04_scatter_3d_raz_nonuniform/plot_results.py
```

绘图需要 Python、NumPy 和 Matplotlib。脚本在测试目录的 `build/figures/` 生成三张英文图，
供中英文文档共用。`--axis-only` 仅生成轴点图，`--data-dir` 指定其他双精度 CSV 目录，
`--output-dir` 指定图片输出目录。原始数据和运行日志保存在本地并由 Git 忽略，
已选用的文档插图保留在仓库中。

## 继续阅读

- [模块与调用约定](../../../B_Scatter/B04_scatter_3d_raz_nonuniform/README.zh-CN.md)
- [调用示例](../../../examples/B04_scatter_3d_raz_nonuniform/README.zh-CN.md)
- [详细测试说明](../../../docs/source/tests/004_scatter/B04_scatter_3d_raz_nonuniform.rst)（双语 Sphinx 源文件）

文档构建完成后，可打开相对于仓库根目录的本地文件
`docs/build/html/tests/004_scatter/B04_scatter_3d_raz_nonuniform.html`。
