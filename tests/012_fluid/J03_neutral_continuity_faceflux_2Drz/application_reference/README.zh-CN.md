# SN → J03 Application Tests

[English](README.md)

本目录将 [J02 的 SN 参考场](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/README.zh-CN.md)
接入 [J03 连续性求解](../../../../J_Fluid/J03_neutral_continuity_faceflux_2Drz/README.zh-CN.md)，
验证无体损失 B0 与给定体损失 ION 两个完整应用。
SN 保留 r-z 空间和两个速度分量，速度求积使用一个平面角度；J03 推进标量密度。
这一约化模型的柱坐标体积与面积用于离散守恒。

## 环境与运行

需要 Bash、GNU Fortran、Python 3、NumPy 和 Matplotlib。绘图使用 `Agg` 后端。
以下命令从仓库根目录运行：

```bash
OMP_NUM_THREADS=4 OMP_DYNAMIC=FALSE \
APPLICATION_OUTPUT="$HOME/algoplasma-results/sn-openmp-B0" \
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference/run_application_reference.sh B0
```

运行 ION 时，将最后参数改为 `ION` 并选择另一输出目录。
J02 默认启用 OpenMP，编译和链接均添加 `-fopenmp`；设置 `OPENMP=0` 可采用串行构建。
线程并行用于 J02 的离散速度扫描，J03 时间推进保持串行。

脚本第二个参数可指定网格目录；默认使用同级
[application_inputs](../application_inputs/README.zh-CN.md)。
输入须保持规定的 256×256 网格及有效区域索引。网格检查在编译前执行，
有效区域与 ION 损失由 [application_case.f90](../application_case.f90) 生成。

## 检查内容与通过条件

脚本依次运行 J02 前处理、J03 连续性求解和公共验收绘图程序。
通过时 `summary.txt` 包含 `RESULT: PASS`；检查失败时脚本返回非零状态。

| 检查 | 通过条件 |
| --- | --- |
| SN 前处理 | 反射源迭代收敛 |
| 前处理与 J03 密度 | 有效单元内有限且非负 |
| J03 稳态 | 求解器报告收敛 |
| 局部残差 | 归一化残差 ≤ `1e-8` |
| 全局收支 | 相对粒子率失衡 ≤ `1e-6` |

密度场相对前处理的变化作为诊断输出；面通量闭合下的 J03 密度由其自身方程决定。
公式和历史运行记录见[完整应用测试页](../../../../docs/source/tests/012_fluid/application_tests.rst)。
该页 2026-10-06 的 SN B0/ION 记录采用 4 个 OpenMP 线程；空间 MPI 的验证范围见
[J02 测试说明](../../J02_neutral_sn_transport_2Drz/README.zh-CN.md)。

## 输出与清理

默认输出目录为本目录的 `build/application_reference/output_B0` 或 `output_ION`。
`APPLICATION_OUTPUT` 可覆盖这一位置；指定目录须为空，重复运行应选择新的目录。

| 输出 | 内容 |
| --- | --- |
| `j02/`、`j03/` | 各阶段的场数据、收支记录与 `run.log` |
| `summary.txt` | 前处理状态、连续性收敛、残差、收支和密度变化 |
| `j02_chain_density.png` | 同一色标下的两个面板：SN 参考密度与 J03 稳态密度 |

图中横轴为 z、纵轴为 r，颜色表示中性密度；结合 `summary.txt` 判断是否通过。
J03 测试目录的 `clean.sh` 会删除本应用的整个 `build/`，包括默认结果。
需要保留的输出应先另存；写到外部目录的结果由使用者管理。
