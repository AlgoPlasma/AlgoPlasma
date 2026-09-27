# Basic and boundary-condition checks / 基础与边界条件测试

Run from the repository root:

```bash
bash tests/010_diagnostics/case_basic_checks/run.sh
```

The twelve deterministic tests record their inputs, measured values, references,
criteria and outcomes in `output/summary.json`, including failures. Small arrays
used by the four PNG figures are saved under `output/details/`.
The plots read these arrays; they do not rerun the diagnostic algorithms.
These small vectorized checks use one worker, with no production data.

- `source_py/test_regressions.py`: inputs and assertions.
- `source_py/report.py`: numerical report, source hashes and optional documentation publication.
- `source_py/plot_results.py`: phase, weights, grid and leakage PNG figures.
- `clean.sh`: removes only this case's generated `output/`.

运行后可查看全部 12 项的实际数值和通过状态；4 张图解释相位分箱、功率权重、网格分辨率与谱泄漏。
报告中的不等式界限与误差容差逐项列出。窗口功率检验使用离散 Parseval 关系。

To update the documentation snapshot after a successful run:

```bash
bash tests/010_diagnostics/case_basic_checks/run.sh --publish-docs
```

This publishes the report, source arrays, PNGs and provenance together to
`docs/source/tests/010_diagnostics/_generated/case_basic_checks/`.
The small snapshot is intended for version control; runtime `output/` is not.
The source hashes identify the tested working tree, including uncommitted changes.
Sphinx reads the snapshot without running these tests.
