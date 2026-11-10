# 基础数值测试

[English](README.md)

按三组检查诊断程序在已知输入下是否按定义工作。每组按“测试目的 → 输入与操作 → 预期及依据 → 本次核对 → 结论”组织。数值表和通过、失败、未完成的结论均由同次运行记录生成。

| 测试 | 目的与通过条件 |
| --- | --- |
| 频谱功率与互相位 | 功率符合 Parseval 关系，互相位符合独立直接 DFT 与整周期解析参考。 |
| 相位统计量 | 两个独立案例（含跨越 ±180°）的众数格中心和样本方差符合手算参考。各案例内部使用相同观测对照方法，并分别绘图。 |
| Beall 权重与谱峰 | 权重、逐格谱值和两种权重下的峰位符合手算参考。 |

- [基础数值测试](../../../docs/source/tests/010_diagnostics/case_basic_checks.rst)提供三组结果表和可展开的附图。
- [谱泄漏知识点](../../../docs/source/knowledge/spectral_leakage.rst)保留六面板图与“截取—拼接—频谱”的原理讲述。图仍由本目录生成，知识页引用同一图片。
- [探针诊断基础](../../../docs/source/rst_files/K_Diagnostics/diagnostics_foundations.rst)介绍诊断原理。

页面与图件的相位统一用 °、方差用 °²。展示时同步换算数值、误差和绝对容差。代码和完整原始记录保留弧度，波数仍用 rad/m。输入角度的简写仅用于展示，测试输入保留原值。

从仓库根目录运行以下命令。

```bash
bash tests/010_diagnostics/case_basic_checks/run.sh
```

底层的 16 项确定性回归检查在 `output/summary.json` 中记录输入、测量值、验收规则及结果，包括失败。`output/results.rst` 是完整报告。`output/checks_zh.rst` 和 `output/checks_en.rst` 提供页面所用的表格。小型数组保存在 `output/details/`，绘图程序读取这些数组及报告，无需重新运行算法。解析波形参考线用于展示记录的输入。检查采用向量化计算，只用一个工作进程，无需生产数据。

- `source_py/test_regressions.py` 提供输入和断言。
- `source_py/report.py` 生成数值报告和源文件哈希，也可发布文档。
- `source_py/plot_results.py` 从保存的结果生成 PNG 图。
- `clean.sh` 只清理本算例生成的 `output/`。

PASS 表示满足该项预期，FAIL 表示数值或行为不符，NOT RUN 表示尚未执行。每组必须在所有展示项及其所属测试全部通过后才显示“通过”。失败时会指出未满足的预期。

非整周期记录与独立 DFT 参考对照。它相对输入相位差的偏差仅作现象展示，不以“大于 5°”判断成功。数值容差按 float64 机器精度、计算规模和量纲显式设定，页面说明用于数值检查的工程余量，物理精度需另行评估。相位与 Beall 图按需展开。

波矢恢复、几何约束、网格分块和无效输入等回归检查保留在完整报告中。完整报告另有四类检查，分别针对不等方差下的相位权重、奇偶长度与不同采样率下的 PSD、解析相干度对照，以及非法 Beall 基线。相位权重案例使用冲突观测，可靠观测应有更大影响。解析最优 `kx` 为 0.1 rad/m，等权对照为 0.5 rad/m。这是似然权重，与第三组的 Beall 功率权重用途不同，三组展示结构保持原样。

成功运行后，可用以下命令更新文档快照。

```bash
bash tests/010_diagnostics/case_basic_checks/run.sh --publish-docs
```

命令将完整报告、双语页面表格、源数组、PNG 图和来源记录一并发布到 `docs/source/tests/010_diagnostics/_generated/case_basic_checks/`。小型快照纳入版本控制，运行时的 `output/` 目录由测试生成。源文件哈希用于识别执行测试时的工作树，包括尚未提交的修改。Sphinx 直接读取快照，无需运行测试。
