# K_Diagnostics

[中文](README.zh-CN.md) | [English](README.en.md)

`K_Diagnostics` 收纳探针诊断算法。与 `A`–`J` 各模块处理粒子和网格不同，本模块的输入是探针时间序列，输出是波数、频率等谱量。既用于实验数据分析，也可作用于 PIC 模拟输出的探针信号。

三个单元是同一条诊断流水线的三段：

| 编号 | 目录 | 输入 | 输出 |
| --- | --- | --- | --- |
| K01 | [`K01_signal_spectra`](K01_signal_spectra/) | 两路探针原始波形 | 分段谱、功率谱、相干度、互相位及其均值与方差 |
| K02 | [`K02_beall`](K02_beall/) | 单对探针的互相位 | 混叠折叠代数 + Beall 统计色散谱 `S(k, f)` |
| K03 | [`K03_mle_k2d`](K03_mle_k2d/) | 多构型的相位均值与方差 | 每频点的二维波矢 `(K_x, K_y)` |

## 本模块解决的问题

一对探针只能测到波矢在其间距方向上的投影，而且只能测到模 2π 的相位。因此当波长小于两倍间距时，单对探针报出的是**折叠后的假波数**：一条笔直的色散支在 `S(k, f)` 图上被打断成锯齿。K02 给出这一限制的闭式几何并让它显形，K03 用多个**不同长度**的间距联合反演把它解除。仅改变探针方向不够——不同长度给出不可通约的条纹周期，才能定出折叠阶数。

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

依赖仅 NumPy。三个单元都**不做任何文件读写**——原始数据的读取和结果落盘由调用方负责，计算只在测试的主程序里发生。

## 测试

[`tests/010_diagnostics/case_broadband_dispersion/`](../tests/010_diagnostics/case_broadband_dispersion/)：一份合成宽带信号同时驱动三个单元，出四张图。判据取自生成器本身，不是人为容差——核心的一条是**把恢复出的色散支拟合成过原点的直线，斜率必须还原生成信号时用的离子声速**，实测相对误差 1.3e-3。

```bash
cd tests/010_diagnostics/case_broadband_dispersion && bash run.sh
```

## 方法来源

- K01/K03 迁移自 [`simulation/simulation_liu`](../../the-world-of-king-peng-zilong/simulation/simulation_liu/)，遵循 Liu & Jorns (IEPC-2025-357) 的反混叠波矢方法
- K02 迁移自 [`core/beall`](../../the-world-of-king-peng-zilong/core/beall/)
- 测试所用的合成信号取自 `simulation/simulation_beall/02宽频`（在 `/mnt/d/波探针原始数据/simulation/` 下）

## 参考文献

- Liu and Jorns, IEPC-2025-357 (2025)。引用信息取自源码注释，作者名首字母未给出，正式引用前应补全。
- J. M. Beall, Y. C. Kim, and E. J. Powers, "Estimation of wavenumber and frequency spectra using fixed probe pairs," J. Appl. Phys. **53**(6), 3933–3940 (1982).
