# K04_breathing_waveform

[中文](README.zh-CN.md) | [English](README.en.md)

从同一空间点的多条电压记录中，提取随呼吸周期重复的平均波形 `C`，返回残差 `R = X - C`。
每次留出一整条记录，用其余记录学习共同形状，再按留出记录自己的相位还原 `C`。
本目录只保存计算函数和说明；函数依赖 NumPy，不读写文件，也不修改输入。

方法与公式见[逐步学习页](../../docs/source/rst_files/K_Diagnostics/K04_breathing_waveform.rst)。
人工数据、测试、画图及清理脚本统一位于
[`tests/011_K04_breathing_waveform`](../../tests/011_K04_breathing_waveform/README.zh-CN.md)，
运行步骤见该目录 README 或[文档测试页](../../docs/source/tests/011_K04_breathing_waveform/index.rst)。

## 调用方式

Python 3.10+，依赖 NumPy。把仓库根目录加入 Python 导入路径，或从仓库根目录运行自己的脚本：

```python
from K_Diagnostics.K04_breathing_waveform.mod_K04_breathing_waveform import (
    fun_K04_extract_waveform,
)

# records 由调用方提供：同一空间点的至少三条一维电压数组；fs 为采样率，单位 Hz。
result = fun_K04_extract_waveform(records, fs, held_out=0)
C, R = result["C"], result["R"]
```

各条记录须为有限实数电压、采样率一致、工况可比较；长度可以不同。
`C`、`R` 的单位为 V，长度与 `records[held_out]` 相同。
改变 `held_out` 可逐条得到各自的留出结果。完整入口为：

```python
fun_K04_extract_waveform(records, fs, held_out=0, bins=256, cutoff=3e6,
                        grid_size=4096, search=(35e3, 45e3), band=(25e3, 55e3))
```

默认值对应文档人工例子。实际数据应重新选择找峰范围 `search`、取相位频带 `band`、
箱数 `bins`、名义谐波上限 `cutoff`（Hz）和查表点数 `grid_size`。
返回字典还包含原始及筛选后的频率系数、相位、分箱和计数、平均形状 `mu`、傅里叶系数 `a`
以及周期曲线 `w`，便于核对中间过程。各函数的 docstring 给出完整输入、单位、约束及返回值。

## 文件

`mod_K04_breathing_waveform.py` 只汇总导入；每个 `fun_` 文件提供一个函数：

| 文件 | 用途 |
| --- | --- |
| `fun_K04_find_frequency.py` | 原始 FFT 与主频查找 |
| `fun_K04_make_complex_signal.py` | 保留正频率带并做复数逆 FFT |
| `fun_K04_mark_position.py` | 完整相位与周期内位置 |
| `fun_K04_put_into_bins.py` | 按相位位置累计原始电压和样本数 |
| `fun_K04_mean_other_records.py` | 排除留出记录，求共同平均形状 |
| `fun_K04_mean_to_coefficients.py` | 半箱位置修正后的傅里叶系数 |
| `fun_K04_coefficients_to_grid.py` | 按谐波上限构造周期曲线 |
| `fun_K04_grid_to_time.py` | 周期插值回原始采样点 |
| `fun_K04_extract_waveform.py` | 串起完整提取流程 |
| `fun_K04_compact_phase.py` | 窄带相位的省点计算 |

`C` 包含基线和保留阶数内的相位重复成分；谐波上限不是普通低通截止频率。
残差的起伏强弱仍可能随呼吸相位变化。省点算法另见
[知识点](../../docs/source/knowledge/compact_phase.rst)。
