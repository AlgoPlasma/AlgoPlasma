# K_Diagnostics

[中文](README.zh-CN.md) | [English](README.en.md)

`K_Diagnostics` 收纳探针诊断算法。与 `A`–`J` 各模块处理粒子和网格不同，本模块的输入是探针时间序列，输出是波数、频率等谱量。既用于实验数据分析，也可作用于 PIC 模拟输出的探针信号。

三个单元是同一条诊断流水线的三段：

| 编号 | 目录 | 输入 | 输出 |
| --- | --- | --- | --- |
| K01 | [`K01_signal_spectra`](K01_signal_spectra/) | 两路探针原始波形 | 分段谱、功率谱、相干度、互相位及其均值与方差 |
| K02 | [`K02_beall`](K02_beall/) | 单对探针的互相位 | 混叠折叠代数 + Beall 统计色散谱 `S(k, f)` |
| K03 | [`K03_mle_k2d`](K03_mle_k2d/) | 多构型的相位均值与方差 | 每频点的二维波矢 `(K_x, K_y)` |

[K04_breathing_waveform](K04_breathing_waveform/) 保存呼吸波形提取函数。
[逐步学习页](../docs/source/rst_files/K_Diagnostics/K04_breathing_waveform.rst) 讲解方法，
[函数说明](K04_breathing_waveform/README.zh-CN.md) 给出 Python 调用方式。
人工示例、本地测试、画图和清理脚本统一位于
[`tests/011_K04_breathing_waveform`](../tests/011_K04_breathing_waveform/README.zh-CN.md)，该目录 README 给出运行命令。
K04 从单空间点的重复记录学习相位重复波形，可为后续谱分析提供残差。

## 本模块解决的问题

每条基线通过相位差约束波矢沿该方向的投影。将多个构型的对数似然相加，可以在二维波数平面上寻找共同支持的波矢。基线的方向和长度共同决定相位条纹的交汇位置。

## 统一约定

- 间距向量 `χ = r₂ - r₁`，互谱 `C = X₁ · conj(X₂)`
- 配合 `numpy.fft.rfft` 的 `exp(-iωt)` 正变换，平面波给出 `θ = arg C = K · χ`（折算到 `(-π, π]`）
- K03 的前向模型就是 `K · χ`，K02 由相位还原波数用 `k∥ = wrap(θ)/|χ|`——**全模块无符号翻转**

交换探针顺序会让 `θ` 反号并镜像所有反演结果。

## 使用方式

Python 实现，源码级模块，不需要安装。把仓库根目录加入 `sys.path` 后按命名空间包导入：

```python
import sys
sys.path.insert(0, "/path/to/AlgoPlasma")

from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (
    fun_K01_cross_phase, fun_K01_phase_mode_statistics, fun_K01_segment_ffts,
)
from K_Diagnostics.K03_mle_k2d.mod_K03_mle_k2d import (
    fun_K03_joint_log_likelihood, fun_K03_peak_wavevector, fun_K03_wavenumber_grid,
)

configs = []
for chi, probe_1, probe_2 in probe_pairs:        # 调用方自行读取数据
    phase, _ = fun_K01_cross_phase(
        fun_K01_segment_ffts(probe_1, nperseg), fun_K01_segment_ffts(probe_2, nperseg)
    )
    mean_phase, variance = fun_K01_phase_mode_statistics(phase[:, bins])
    configs.append((chi, mean_phase[m], variance[m]))

grid = fun_K03_wavenumber_grid(k_range_rad_m=3300.0, n_grid=301)
result = fun_K03_peak_wavevector(fun_K03_joint_log_likelihood(configs, grid, grid), grid, grid)
```

计算函数依赖 NumPy，画图另需 Matplotlib。各单元的计算函数都**不做文件读写**；数据读取和结果落盘由调用方负责，示例与测试调度计算。

## 测试

- [基础数值测试](../tests/010_diagnostics/case_basic_checks/)：用解析参考检查功率归一化、相位统计、Beall 累积和方差加权反演等行为。
- [宽带测试](../tests/010_diagnostics/case_broadband_dispersion/)：从合成波形驱动 K01–K03，同时验收整体色散关系和每个选定频点的波矢，并记录边界峰、并列峰。

宽带页面的图、数值表、逐频点 CSV 和源码哈希来自同次运行。阈值是这个合成案例的工程验收要求，不代表普适精度保证。


## 方法来源

- K01 实现分段 FFT、互谱、功率谱、相干度和圆统计等基础信号处理步骤。
- K02 遵循 Beall 等人的固定探针对波数–频率谱方法。
- K03 遵循 Liu 和 Jorns 提出的多构型贝叶斯空间反混叠方法。
- 测试信号由 `tests/010_diagnostics/case_broadband_dispersion/source_py/generate.py`
  根据仓库内参数确定性生成，不依赖外部或私有数据文件。

## 参考文献

- M. F. Liu and B. A. Jorns, "Anti-aliasing technique for inferring dispersion of short-wavelength instabilities in electric propulsion devices," AIAA SciTech Forum, Paper AIAA-2025-1293 (2025), [doi:10.2514/6.2025-1293](https://doi.org/10.2514/6.2025-1293)。
- M. F. Liu and B. A. Jorns, "Experimental validation of a spatial anti-aliasing plasma wave analysis technique on ion acoustic turbulence in a hollow cathode plume," 39th International Electric Propulsion Conference, Paper IEPC-2025-357 (2025)。
- J. M. Beall, Y. C. Kim, and E. J. Powers, "Estimation of wavenumber and frequency spectra using fixed probe pairs," J. Appl. Phys. **53**(6), 3933–3940 (1982).
