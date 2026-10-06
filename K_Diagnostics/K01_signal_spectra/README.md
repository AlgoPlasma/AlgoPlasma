# K01_signal_spectra

[中文](README.zh-CN.md) | [English](README.en.md)

`K01_signal_spectra` 是诊断链的前端：把两路探针原始波形化为后续单元需要的谱量。分段方式与相位符号约定在这里定义一次，K02 与 K03 共用。

Beall 权重另由 `fun_K01_pair_power(ffts_1, ffts_2)` 提供。
零或非有限互谱返回 NaN 相位，有效样本不足两个返回 NaN 统计量。
按 Liu 2025 II.E 直接以众数估计均值；ddof=1 是本实现的明确约定。

## 文件

按仓库约定，一个 routine 一个文件，`mod_` 只做汇总。

| 文件 | 作用 |
| --- | --- |
| `mod_K01_signal_spectra.py` | 模块入口，汇总本单元全部 routine。 |
| `fun_K01_wrap_to_pi.py` | 把角度折算到 `[-π, π]`。 |
| `fun_K01_segment_ffts.py` | 分段（不重叠）、去均值、rFFT，返回 `(nseg, nfreq)`。 |
| `fun_K01_power_spectrum.py` | 分段平均的单边功率谱密度。 |
| `fun_K01_coherence.py` | 幅度平方相干度，取值 `[0, 1]`。 |
| `fun_K01_cross_phase.py` | 每段的互相位与互谱幅度。 |
| `fun_K01_phase_mode_statistics.py` | 众数估计的相位均值与方差（`ddof=1`）。 |

## 接口

| 函数 | 作用 |
| --- | --- |
| `fun_K01_wrap_to_pi(values)` | 把角度折算到 `[-π, π]`。 |
| `fun_K01_segment_ffts(signal, nperseg, n_segments=None, detrend=True, window='boxcar')` | 分段、去均值、rFFT。 |
| `fun_K01_power_spectrum(ffts, sampling_rate_hz, nperseg, window='boxcar')` | 单边功率谱密度。 |
| `fun_K01_coherence(ffts_1, ffts_2)` | 幅度平方相干度。 |
| `fun_K01_cross_phase(ffts_1, ffts_2)` | 互相位与互谱幅度。 |
| `fun_K01_phase_mode_statistics(phase, nbins=60)` | 相位均值与方差。 |

## 约定

间距向量 `χ = r₂ - r₁`，互谱 `C = X₁ · conj(X₂)`。配合 `numpy.fft.rfft` 的 `exp(-iωt)` 正变换，平面波给出 `θ = arg C = K · χ`，折算到 `(-π, π]`。K02 与 K03 直接沿用，无符号翻转。

## 众数参考的相位统计

当真实相位靠近 `±π` 时，各分段的相位样本分布在分支切割线两侧，算术平均会塌向零。本估计器先在直方图上定位众数，直接用众数估计均值，并将切割线移到众数对面计算方差：

```
θ̄ = θ_mode
σ² = var(wrap(θᵢ - θ_mode), ddof=1) + 1e-12
```

## 注意事项

- **分段不重叠**。不重叠仍不保证独立；相关性影响有效样本量与众数稳定性。返回的是单样本方差，不能由重叠直接断言 K03 权重偏大。
- 窗口可选 boxcar 或 hann。矩形窗适用于周期对齐数据；Hann 通过平滑记录两端降低旁瓣，同时展宽主峰。非整周期截断可能影响互相位估计，power_spectrum 使用与 FFT 相同的窗口进行功率归一化。
- **相干度的底不是零**。`n` 个独立分段下，不相关信号的相干度平均到 `1/n` 而非 0。判断空频带时应以 `1/n` 为参照。
- `phase_mode_statistics` 返回的是**单个样本**的方差，不是均值的方差；`θ̄` 是主值区间内的众数格中心。
- 末尾不足一个分段长度的数据会被丢弃。

## 使用方式

```python
import sys
sys.path.insert(0, "/path/to/AlgoPlasma")

from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (
    fun_K01_coherence, fun_K01_cross_phase, fun_K01_phase_mode_statistics,
    fun_K01_power_spectrum, fun_K01_segment_ffts,
)

ffts_1 = fun_K01_segment_ffts(probe_1, nperseg)
ffts_2 = fun_K01_segment_ffts(probe_2, nperseg)
psd = fun_K01_power_spectrum(ffts_1, fs_hz, nperseg)
gamma = fun_K01_coherence(ffts_1, ffts_2)
phase, magnitude = fun_K01_cross_phase(ffts_1, ffts_2)
mean_phase, variance = fun_K01_phase_mode_statistics(phase[:, mode_bins])
```

## 测试

- [基础数值测试](../../tests/010_diagnostics/case_basic_checks/)：用解析参考检查功率归一化、相位统计、Beall 累积和方差加权反演等行为。
- [宽带测试](../../tests/010_diagnostics/case_broadband_dispersion/)：从合成波形驱动 K01–K03，同时验收整体色散关系和每个选定频点的波矢，并记录边界峰、并列峰。

宽带页面的图、数值表、逐频点 CSV 和源码哈希来自同次运行。阈值是这个合成案例的工程验收要求，不代表普适精度保证。
