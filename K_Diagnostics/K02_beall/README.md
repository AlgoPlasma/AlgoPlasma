# K02_beall

[中文](README.zh-CN.md) | [English](README.en.md)

`K02_beall` 包含两部分：**混叠折叠的闭式代数**，以及让混叠显形的 **Beall 统计色散谱 `S(k, f)`**。

单对探针只能报出 `±π/|χ|` 以内的波数，超出该限的模态被折回，一条笔直的色散支在 `S(k, f)` 图上被打断成锯齿。`K03_mle_k2d` 用多个不同长度的间距把它解除——两个单元是同一次测量的问题面和解决面。

## 文件

按仓库约定，一个 routine 一个文件，`mod_` 只做汇总。

| 文件 | 作用 |
| --- | --- |
| `mod_K02_beall.py` | 模块入口，汇总本单元全部 routine。 |
| `fun_K02_separation_vector.py` | 由间距和方位角构造 `χ`。 |
| `fun_K02_separation_magnitude.py` | `\|χ\|`，并集中做形状与零长度校验。 |
| `fun_K02_nyquist_wavenumber.py` | `π/\|χ\|`。 |
| `fun_K02_project_wavenumber.py` | `K·χ̂`。 |
| `fun_K02_fold_order.py` | 折叠阶数 `n`。 |
| `fun_K02_fold_wavenumber.py` | 折叠后的波数。 |
| `fun_K02_wavenumber_edges.py` | 张成 `[-π/\|χ\|, +π/\|χ\|]` 的直方图边界。 |
| `fun_K02_beall_wavenumber.py` | `wrap(θ)/\|χ\|`。 |
| `fun_K02_beall_spectrum.py` | 累积 `S(k, f)`。 |
| `fun_K02_peak_wavenumber.py` | 每个频点的谱峰波数。 |
| `fun_K02_wavenumber_residual.py` | 折叠轴上的圆周距离。 |

## 接口

| 函数 | 作用 |
| --- | --- |
| `fun_K02_separation_vector(spacing_m, angle_rad)` | 由间距和方位角构造 `χ`。 |
| `fun_K02_nyquist_wavenumber(chi)` | `π/|χ|`。 |
| `fun_K02_project_wavenumber(k_vector, chi)` | `K·χ̂`。 |
| `fun_K02_fold_order(k_projected, chi)` | 折叠阶数 `n`。 |
| `fun_K02_fold_wavenumber(k_projected, chi)` | 折叠后的波数。 |
| `fun_K02_wavenumber_edges(chi, n_bins)` | 张成 `[-π/|χ|, +π/|χ|]` 的直方图边界。 |
| `fun_K02_beall_wavenumber(phase, chi)` | `wrap(θ)/|χ|`。 |
| `fun_K02_beall_spectrum(phase, magnitude, frequencies_hz, chi, k_edges, f_edges)` | 累积 `S(k, f)`。 |
| `fun_K02_peak_wavenumber(spectrum, k_centers)` | 每个频点的谱峰波数。 |
| `fun_K02_wavenumber_residual(measured, reference, chi)` | 折叠轴上的圆周距离。 |

## 定义

```
k_proj = K · χ̂        k_nyq = π/|χ|
n      = round(k_proj·|χ| / 2π)
k_meas = k_proj - n·2π/|χ|
混叠   ⟺  |k_proj| > k_nyq
```

`k_meas` 正是折叠相位所报出的波数——相位 `K·χ` 只能被观测到模 2π。折叠阶数 `n` 是单对探针无法提供的信息。

## 方法

对每个分段 `s` 和频点 `f`，把 `wrap(θ)/|χ|` 所在的直方图格加上权重 `|X₁·conj(X₂)|`，最后除以分段数。每个 `(分段, 频点)` 样本只落进一个格子，这就是该估计器"统计"的含义：不相干的分段散开，相干的分段堆叠。

## 注意事项

- **波数轴是周期的**，周期 `2π/|χ|`。贴着一侧 Nyquist 边的值与贴着另一侧的值是邻居而不是对立面，比较折叠波数必须用 `wavenumber_residual` 而不是直接相减，否则边界附近会报出整整一个周期的假误差。
- **波数范围就是 `±π/|χ|`**，不应设得更宽或更窄；`wavenumber_edges` 直接给出。
- **样本数要够**。`peak_wavenumber` 取直方图 argmax，是有限样本下的众数。分段数远少于波数格数时，"峰"实际上只是最强的那一个样本，散布很大。需要平滑的 `S(k, f)` 就要显著增加分段数。
- **有效间距是投影长度**。探针对与所关心方向成角时应传入投影后的 `χ`。
- 混叠无法在本单元内分辨，还原真值需要 K03。

## 使用方式

```python
import sys
sys.path.insert(0, "/path/to/AlgoPlasma")

import numpy as np
from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (
    fun_K01_cross_phase, fun_K01_segment_ffts,
)
from K_Diagnostics.K02_beall.mod_K02_beall import (
    fun_K02_beall_spectrum, fun_K02_peak_wavenumber,
    fun_K02_separation_vector, fun_K02_wavenumber_edges,
)

chi = fun_K02_separation_vector(5.0e-3, np.deg2rad(30.0))
phase, magnitude = fun_K01_cross_phase(
    fun_K01_segment_ffts(probe_1, nperseg), fun_K01_segment_ffts(probe_2, nperseg)
)
frequencies = np.fft.rfftfreq(nperseg, d=1.0 / fs_hz)
result = fun_K02_beall_spectrum(
    phase, magnitude, frequencies, chi,
    fun_K02_wavenumber_edges(chi, 80), f_edges,
)
peaks = fun_K02_peak_wavenumber(result["spectrum"], result["k_centers"])
```

## 测试

`tests/010_diagnostics/case_broadband_dispersion`：故意选一对**粗间距**探针（20 mm、30°，`f_alias = c_s/2d = 96 kHz`）。生成真值的 238 个模态**全部**混叠并跨越 10 个理论折叠阶；测得的 `S(k, f)` 呈现重复锯齿，即 Beall 图的特征形态。

判据只评价功率高于 10 倍噪声底的 83 个有效模态，检查其实测折叠波数峰是否落在闭式预测附近。圆周残差的中位数为 0.40 个波数格，p95 为 1.46 个波数格，低于 2 个波数格的阈值。该判据验证折叠波数趋势，不声称由单对探针恢复已丢失的折叠阶。

可见折叠条数为 `f_max / f_alias`，`f_alias = c_s/(2d)`。所以要展示混叠，把间距选粗和把频带拉宽是等效的——测试选前者，因为它不推高反演的成本。

## 方法来源

本实现遵循 Beall 等人的固定探针对波数–频率谱方法。测试从仓库内参数确定性生成双探针原始信号，再由实测互相位构造混叠图，而不是直接折叠理论色散曲线。

## 参考文献

- J. M. Beall, Y. C. Kim, and E. J. Powers, "Estimation of wavenumber and frequency spectra using fixed probe pairs," J. Appl. Phys. **53**(6), 3933–3940 (1982).
