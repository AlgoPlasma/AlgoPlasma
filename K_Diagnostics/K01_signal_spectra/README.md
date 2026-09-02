# K01_signal_spectra

[中文](README.zh-CN.md) | [English](README.en.md)

`K01_signal_spectra` 是诊断链的前端：把两路探针原始波形化为后续单元需要的谱量。分段方式与相位符号约定在这里定义一次，K02 与 K03 共用。

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
| `fun_K01_phase_mode_statistics.py` | 众数参考的相位均值与方差（`ddof=1`）。 |

## 接口

| 函数 | 作用 |
| --- | --- |
| `fun_K01_wrap_to_pi(values)` | 把角度折算到 `[-π, π]`。 |
| `fun_K01_segment_ffts(signal, nperseg, n_segments=None, detrend=True)` | 分段、去均值、rFFT。 |
| `fun_K01_power_spectrum(ffts, sampling_rate_hz, nperseg)` | 单边功率谱密度。 |
| `fun_K01_coherence(ffts_1, ffts_2)` | 幅度平方相干度。 |
| `fun_K01_cross_phase(ffts_1, ffts_2)` | 互相位与互谱幅度。 |
| `fun_K01_phase_mode_statistics(phase, nbins=60)` | 相位均值与方差。 |

## 约定

间距向量 `χ = r₂ - r₁`，互谱 `C = X₁ · conj(X₂)`。配合 `numpy.fft.rfft` 的 `exp(-iωt)` 正变换，平面波给出 `θ = arg C = K · χ`，折算到 `(-π, π]`。K02 与 K03 直接沿用，无符号翻转。

## 众数参考的相位统计

当真实相位靠近 `±π` 时，各分段的相位样本分布在分支切割线两侧，算术平均会塌向零。本估计器先在直方图上定位众数，把切割线移到众数对面再平均：

```
θ̄ = θ_mode + ⟨wrap(θᵢ - θ_mode)⟩
σ² = var(wrap(θᵢ - θ_mode), ddof=1) + 1e-12
```

## 注意事项

- **分段不重叠**。重叠会使相位样本相关，而 K03 的似然权重假设样本独立。
- **不加窗**。内容在分段长度上周期时矩形窗即精确；非 bin 对齐的实测数据需调用方自行加窗。偏离 bin 只影响该 bin 内的功率，不影响**互**相位——泄漏因子对两路探针相同，在 `X₁·conj(X₂)` 中约掉。
- **相干度的底不是零**。`n` 个独立分段下，不相关信号的相干度平均到 `1/n` 而非 0。判断空频带时应以 `1/n` 为参照。
- `phase_mode_statistics` 返回的是**单个样本**的方差，不是均值的方差；`θ̄` 不再折算回 `(-π, π]`。
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

`tests/010_diagnostics/case_broadband_dispersion`：生成器用 `A ∝ 1/f`，对应功率谱 `∝ 1/f²`。三条判据都是把生成器的量测回来：

- 谱指数拟合 **−2.015**，对真值 −2
- 下带边 104 kHz，与生成值一致到一个频点
- 谱与噪声底的交点 816 kHz，对 `1/f²` 律预言的 733 kHz（11%）——这一条把谱在整个动态范围上都检验了，而不只在强的那一段

相干度在高出噪声底的频点上中位 0.932，带外 0.038 对 `1/n_seg = 0.0625` 的底。
