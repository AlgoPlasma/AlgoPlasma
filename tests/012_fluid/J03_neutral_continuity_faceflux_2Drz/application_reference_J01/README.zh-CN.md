# FM → J03 Application Test

[English](README.md)

本目录将 [J01 自由分子统计](../../../../J_Fluid/J01_free_molecular/README.zh-CN.md)
得到的参考密度与面通量接入 [J03 连续性求解](../../../../J_Fluid/J03_neutral_continuity_faceflux_2Drz/README.zh-CN.md)，
验证无体损失 B0 应用。FM 在 r-z 平面内追踪直线轨迹，保留径向和轴向速度；
柱坐标体积与面积用于统计归一化。

## 环境与运行

需要 Bash、GNU Fortran、Python 3、NumPy 和 Matplotlib。绘图使用 `Agg` 后端。
以下命令从仓库根目录运行：

```bash
APPLICATION_OUTPUT="$HOME/algoplasma-results/fm-B0" \
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference_J01/run.sh
```

默认输入为同级 [application_inputs](../application_inputs/README.zh-CN.md)，
有效区域由 [application_case.f90](../application_case.f90) 生成。
脚本第一个参数可指定其他网格目录，但须保持规定的 256×256 网格及有效区域索引。
输入检查在编译前执行。

默认追踪 2400000 条粒子历史；第二个位置参数或环境变量 `J01_FM_HISTORIES` 可设置历史数，
位置参数优先。改变历史数会改变统计误差和计算耗时。

## 检查内容与通过条件

脚本依次运行 J01 前处理、J03 连续性求解和公共验收绘图程序。
通过时 `summary.txt` 包含 `RESULT: PASS`；检查失败时脚本返回非零状态。

| 检查 | 通过条件 |
| --- | --- |
| FM 前处理 | 粒子历史完成，无截断 |
| 前处理与 J03 密度 | 有效单元内有限且非负 |
| J03 稳态 | 求解器报告收敛 |
| 局部残差 | 归一化残差 ≤ `1e-8` |
| 全局收支 | 相对粒子率失衡 ≤ `1e-6` |

密度场相对前处理的变化作为诊断输出。FM 前处理按 `1/3` 弧度扇区统计，
J03 按完整一圈积分；密度和单位面积通量直接传递，
比较总粒子率时应将 FM 扇区值乘以周向比例 `6*pi`。

公式、图示及 2026-10-06 的历史运行记录见
[完整应用测试页](../../../../docs/source/tests/012_fluid/application_tests.rst)。
本应用的模型范围为 r-z 平面内的两速度分量自由分子运动。

## 输出与清理

默认输出位于本目录的 `build/output_B0`。`APPLICATION_OUTPUT` 可覆盖这一位置；
指定目录须为空，重复运行应选择新的目录。

| 输出 | 内容 |
| --- | --- |
| `j01/`、`j03/` | 各阶段的场数据、统计或收支记录与 `run.log` |
| `summary.txt` | 历史完成状态、连续性收敛、残差、收支和密度变化 |
| `j01_chain_density.png` | 同一色标下的两个面板：FM 参考密度与 J03 稳态密度 |

图中横轴为 z、纵轴为 r，颜色表示中性密度；结合 `summary.txt` 判断是否通过。
J03 测试目录的 `clean.sh` 会删除本应用的整个 `build/`，包括默认结果。
需要保留的输出应先另存；写到外部目录的结果由使用者管理。
