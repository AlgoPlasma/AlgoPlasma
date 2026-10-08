# 011_K04_breathing_waveform

[中文](README.zh-CN.md) | [English](README.en.md)

用人工数据验证 [K04 计算函数](../../K_Diagnostics/K04_breathing_waveform/README.zh-CN.md)，
并复现[逐步学习页](../../docs/source/rst_files/K_Diagnostics/K04_breathing_waveform.rst)的 12 张图，
以及[省点知识点](../../docs/source/knowledge/compact_phase.rst)的 2 张图。
本目录包含数据生成器、示例、画图脚本、17 项本地测试和清理脚本。
详细说明见[文档测试页](../../docs/source/tests/011_K04_breathing_waveform/index.rst)。

## 环境与运行

需要 Python 3.10+。计算和测试依赖 NumPy，画图还需要 Matplotlib；使用 `Agg` 后端，无需显示器或 LaTeX。
无需编译或安装 AlgoPlasma。本节命令从**仓库根目录**运行；已有依赖时无需重复安装：

```bash
python -m pip install -r tests/011_K04_breathing_waveform/requirements.txt
bash tests/011_K04_breathing_waveform/run.sh
```

`run.sh` 完成全部测试、两个数值示例和 14 张图的复现。只运行测试或只清理产物：

```bash
bash tests/011_K04_breathing_waveform/test.sh
bash tests/011_K04_breathing_waveform/clean.sh
```

这些脚本需要 Bash，可用于 Linux、macOS 和 WSL；进入本目录后也可执行 `bash run.sh`、`bash test.sh`
和 `bash clean.sh`。运行脚本默认使用 `python3`，例如 `PYTHON=python bash tests/011_K04_breathing_waveform/run.sh`
可选择当前环境中的 `python`。脚本关闭 Python 字节码写入，避免在算法目录生成缓存。

也可从仓库根目录逐步运行 Python，不依赖 Bash 调度：

```bash
python -B -m unittest discover -s tests/011_K04_breathing_waveform -v
python -B tests/011_K04_breathing_waveform/source_py/run_example.py
python -B tests/011_K04_breathing_waveform/source_py/plot_figures.py
python -B tests/011_K04_breathing_waveform/source_py/run_compact_phase.py
python -B tests/011_K04_breathing_waveform/source_py/plot_compact_phase.py
```

## 文件

| 文件 | 用途 |
| --- | --- |
| `run.sh` / `test.sh` | 完整复现 / 只运行本地测试 |
| `source_py/generate.py` | 正文和省点示例的人工数据生成器 |
| `source_py/run_example.py` | 运行正文示例，保存数组和误差指标 |
| `source_py/plot_figures.py` | 读取保存的结果，重画正文图 1–12 |
| `source_py/run_compact_phase.py` | 运行省点知识点示例 |
| `source_py/plot_compact_phase.py` | 重画移频图和相位误差图 |
| `source_py/_paths.py` | 按脚本位置定位仓库和默认输出目录 |
| `test_K04_breathing_waveform.py` | 14 项数值及文内代码一致性测试 |
| `test_clean.py` | 3 项清理范围与符号链接测试 |
| `clean.sh` | 删除默认运行产物及本目录的 Python 缓存 |
| `requirements.txt` | NumPy、Matplotlib 依赖 |
| `output/` | 运行后生成的结果，被 Git 忽略 |

## 输出与预期结果

默认结果位于本目录的 `output/`，重复运行覆盖同名文件：

- `synthetic_result.npz`：人工输入、生成器答案，以及 `F`、`F_hat`、相位、`mu`、`a`、`w`、`C`、`R` 等中间量。
- `metrics.json`：固定种子 20261004，10 条记录，每条 160000 点，采样率 8 MHz，留出第 0 条。
  主频为 39750 Hz，`H=75`，最少训练计数 5566，波形相对生成器答案的 RMSE 约 **0.00493408 V**。
- `figures/r3_01_x.png` 至 `r3_12_residual.png`：正文图 1–12，文件名与文档一致。
- `compact_phase_result.npz`、`compact_phase_metrics.json` 和 `compact_figures/`：省点计算结果和两张图。
  4096 个粗网格点所得相位相对直接法的 RMSE 约 **6.8351e-7 rad**。

`C_known`、`phi_known` 只用于核对，提取过程不读取答案。`R` 是剩余电压，`error` 是估计误差。
这些指标针对固定人工数据，不代表实验数据的普遍精度。

运行脚本支持 `--output-dir`，正文示例另支持 `--seed`；画图脚本支持 `--input` 和 `--output-dir`。
用 `--help` 查看选项。改变数值输出目录时，画图输入也应同步修改，例如从仓库根目录运行：

```bash
python -B tests/011_K04_breathing_waveform/source_py/run_example.py --output-dir /tmp/k04-demo
python -B tests/011_K04_breathing_waveform/source_py/plot_figures.py --input /tmp/k04-demo/synthetic_result.npz --output-dir /tmp/k04-demo/figures
```

## 测试检查了什么？

14 项数值测试检查已知相位、正频率半振幅、原始电压分箱、样本加权、整条记录留出、半箱位置修正、
谐波截断、周期查表、输入约束、人工波形恢复、省点归一化与移频、插值精度及首尾整圈数。
还会读取中英两版正文与知识点中的代码片段，实际执行并核对它们与计算函数的结果一致。
成功显示 `OK`，失败返回非零退出码。固定人工数据的回归阈值为波形 RMSE <10 mV、
省点相位 RMSE <1e-6 rad；这些不是普遍的物理精度界限。

另外 3 项测试在临时目录检查清理范围、重复运行、符号链接与脚本位置。
非 POSIX/Bash 环境跳过这 3 项，数值测试照常运行。

## 更新文档图片

默认画图只写入 `output/`。检查结果后，若要更新文档中的 12+2 张图，从仓库根目录运行：

```bash
python -B tests/011_K04_breathing_waveform/source_py/plot_figures.py --output-dir docs/source/images/K_Diagnostics/k04
python -B tests/011_K04_breathing_waveform/source_py/plot_compact_phase.py --output-dir docs/source/images/knowledge
```

这两行会覆盖对应文档图片；须先生成两个数值示例。
随后按[文档指南](../../docs/DOCUMENTATION_GUIDE.md)重建 Sphinx。

## 清理范围

`clean.sh` 删除本测试目录的整个默认 `output/` 和其下的数据、指标、图片，以及本测试目录内的
Python `__pycache__/`，包括 Git 忽略的文件。可重复运行，使默认生成文件恢复到刚克隆时不存在的状态。
源码、README、文档保存的图片和用户修改会保留。用 `--output-dir` 写到其他位置的结果需单独清理。
脚本不重置 Git，也不清理其他模块或整个文档构建目录。
