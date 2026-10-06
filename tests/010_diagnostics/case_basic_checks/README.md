# basic_numerical tests / 基础数值测试

按三组检查诊断程序在已知输入下是否按定义工作。每组按“测试目的 → 输入与操作 → 预期及依据 → 本次核对 → 结论”阅读。
数值表和通过、失败、未完成的结论均由同次运行记录生成。

| 测试 | 目的与通过条件 |
| --- | --- |
| 频谱功率与互相位 | 功率符合 Parseval 关系，互相位符合独立直接 DFT 与整周期解析参考。 |
| 相位统计量 | 两个独立案例（含跨越 ±180°）的众数格中心和样本方差符合手算参考；各案例内部使用相同输入作对照。 |
| Beall 权重与谱峰 | 权重、逐格谱值和两种权重下的峰位符合手算参考。 |

- [基础数值测试](../../../docs/source/tests/010_diagnostics/case_basic_checks.rst)：三组结果表和可展开的附图。
- [谱泄漏知识点](../../../docs/source/knowledge/spectral_leakage.rst)：保留六面板图与“截取—拼接—频谱”的原理讲述。
- [Probe Diagnostics Foundations](../../../docs/source/rst_files/K_Diagnostics/diagnostics_foundations.rst)：诊断基础。

Each group explains its purpose, setup, expected behavior and basis, recorded checks,
and conclusion. The checks cover power/phase calculations, phase statistics, Beall
weights/bin values/peaks. Status and conclusions come
from the same run. Supporting figures are collapsible; the six-panel leakage explanation
is on the knowledge page. Phase statistics use two independent figures: each compares
methods on identical observations, rather than comparing two different input sets.

页面与图件的相位统一用°、方差用°²；展示时同步换算数值、误差和绝对容差。
代码和完整原始记录保留弧度，波数仍用 rad/m。输入角度的简写仅用于展示，不改变测试输入。
Phases and variances are displayed in ° and °², with errors and absolute tolerances
converted consistently. Code and full raw records retain radians; wavenumbers remain in rad/m.
Rounded input labels do not change the underlying test data.

Run from the repository root:

```bash
bash tests/010_diagnostics/case_basic_checks/run.sh
```

The underlying sixteen deterministic regression checks still record inputs,
measurements, criteria and outcomes in `output/summary.json`, including failures.
`output/results.rst` contains the full report. `output/checks_zh.rst` and
`output/checks_en.rst` supply the page tables. Small arrays are in `output/details/`;
plots read these arrays and the report without rerunning the algorithms.
Analytic waveform guides illustrate the recorded inputs. These vectorized checks
use one worker and no production data.

- `source_py/test_regressions.py`: inputs and assertions.
- `source_py/report.py`: numerical report, source hashes and optional documentation publication.
- `source_py/plot_results.py`: PNG figures from saved results.
- `clean.sh`: removes only this case's generated `output/`.

PASS 表示满足该项预期；FAIL 表示数值或行为不符；NOT RUN 表示尚未执行。
每组必须在所有展示项及其所属测试全部通过后才显示“通过”，失败时指出未满足的预期。
非整周期记录核对独立 DFT 参考；它相对输入相位差的偏差仅作现象展示，不以“大于5°”判断成功。
数值容差按 float64 机器精度、计算规模与量纲显式设定，页面说明工程余量的来源；它们不是物理精度指标。
相位与 Beall 图按需展开。
波矢恢复、几何约束、网格分块、无效输入等回归检查保留在完整报告中。六面板谱泄漏图仍由本目录生成，知识页直接引用同一图片。

PASS means the stated expectation is met; FAIL means a numerical or behavioral mismatch;
NOT RUN means an unexecuted check. Groups pass only when all selected checks and their
parent tests pass. Off-bin phase bias is an observation, not a minimum-error requirement.
The page documents explicit float64 rounding margins rather than physical accuracy targets.

To update the documentation snapshot after a successful run:

```bash
bash tests/010_diagnostics/case_basic_checks/run.sh --publish-docs
```

This publishes the full report, bilingual page tables, source arrays, PNGs and provenance together to
`docs/source/tests/010_diagnostics/_generated/case_basic_checks/`.
The small snapshot is intended for version control; runtime `output/` is not.
The source hashes identify the tested working tree, including uncommitted changes.
Sphinx reads the snapshot without running these tests.

完整报告新增四类检查：不等方差下的相位权重、奇偶长度与不同采样率下的 PSD、解析相干度对照、非法 Beall 基线。
相位权重案例使用冲突观测：可靠观测应有更大影响；解析最优 kx 为 0.1 rad/m，等权对照为 0.5 rad/m。
这与第三组的 Beall 功率权重用途不同，三组展示结构保持不变。
The full report also checks unequal phase-variance weights, PSD parity/rate scaling, analytic coherence,
and invalid baselines. The conflicting-observation case has weighted optimum kx=0.1 rad/m
and equal-weight optimum 0.5 rad/m; these likelihood weights differ from Beall power weights.
