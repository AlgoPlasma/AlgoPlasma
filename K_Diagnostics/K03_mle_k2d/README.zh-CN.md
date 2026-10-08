# K03_mle_k2d

[中文](README.zh-CN.md) | [English](README.en.md)

每条基线通过相位差约束波矢沿该方向的投影。将多个构型的对数似然相加，可以在二维波数平面上寻找共同支持的波矢。基线的方向和长度共同决定相位条纹的交汇位置。

## 文件

按仓库约定，一个 routine 一个文件，`mod_` 只做汇总。

| 文件 | 作用 |
| --- | --- |
| `mod_K03_mle_k2d.py` | 模块入口，汇总本单元全部 routine。 |
| `fun_K03_wavenumber_grid.py` | 构造 `[-k_range, +k_range]` 上的均匀网格。 |
| `fun_K03_predicted_phase.py` | 前向模型 `K·χ` 在网格上的取值。 |
| `fun_K03_config_log_likelihood.py` | 单构型对数似然。 |
| `fun_K03_joint_log_likelihood.py` | 多构型求和。 |
| `fun_K03_peak_wavevector.py` | 峰位及其极坐标形式。 |
| `fun_K03_search_wavevector.py` | 完整均匀网格遍历（分块向量化）。 |

## 接口

| 函数 | 作用 |
| --- | --- |
| `fun_K03_wavenumber_grid(k_range_rad_m, n_grid)` | 构造 `[-k_range, +k_range]` 上的均匀网格。 |
| `fun_K03_predicted_phase(chi, kx_values, ky_values)` | 前向模型 `K·χ` 在网格上的取值。 |
| `fun_K03_config_log_likelihood(chi, delta_theta, variance, kx_values, ky_values)` | 单构型对数似然。 |
| `fun_K03_joint_log_likelihood(configurations, kx_values, ky_values, normalise=True)` | 多构型求和。 |
| `fun_K03_peak_wavevector(log_likelihood, kx_values, ky_values)` | 峰位及其极坐标形式。 |
| `fun_K03_search_wavevector(configurations, k_range_rad_m, ...)` | 完整均匀网格遍历（分块向量化）。 |

数组按 `[iy, ix]` 索引，与 `numpy.meshgrid` 默认次序一致。

## 似然

```
ln L_j(K) = -½ · wrap(K·χ_j - θ̄_j)² / σ_j²
ln L(K)   = Σ_j ln L_j(K)
```

前向模型 `K·χ` 与 `K01_signal_spectra` 的互相位约定一致，不带符号翻转。

**残差在平方前先折算到 `(-π, π]`。** 这一步不是数值便利：正是它使混叠构型贡献出周期性的条纹族而非单条脊，混叠信息因而保留在似然里、可以被其他构型解出。

## 注意事项

- **几何。** 每条基线通过相位差约束波矢沿该方向的投影。将多个构型的对数似然相加，可以在二维波数平面上寻找共同支持的波矢。基线的方向和长度共同决定相位条纹的交汇位置。
- **搜索范围**。估计值被限制在网格内，`k_range` 必须包含真实波矢；边界峰需要核查范围。网格分辨率同时影响局部峰位与混叠分支选择。
- 方差描述分段相位的散布，在似然中用于衡量相位残差；众数估计的稳定性可通过改变样本数和分箱检查。
- **内存**。似然数组为 `n_grid²` 个 float64，401×401 约 1.3 MB，逐构型累加。
- 在给定的二维波数范围内建立均匀网格，计算各网格点的联合对数似然，取最大值对应的波矢作为估计结果。n_grid 指定每个坐标轴的点数，block_rows 指定每批计算的网格行数。

## 使用方式

```python
import sys
sys.path.insert(0, "/path/to/AlgoPlasma")

from K_Diagnostics.K03_mle_k2d.mod_K03_mle_k2d import (
    fun_K03_joint_log_likelihood, fun_K03_peak_wavevector,
    fun_K03_wavenumber_grid,
)

grid = fun_K03_wavenumber_grid(k_range_rad_m=3300.0, n_grid=301)
configs = [(chi_j, delta_theta_j, variance_j) for ...]   # 来自 K01
result = fun_K03_peak_wavevector(fun_K03_joint_log_likelihood(configs, grid, grid), grid, grid)
# result["kx"], result["ky"], result["k_magnitude"], result["angle_deg"]
```

## 测试

- [基础数值测试](../../tests/010_diagnostics/case_basic_checks/)：用解析参考检查功率归一化、相位统计、Beall 累积和方差加权反演等行为。
- [宽带测试](../../tests/010_diagnostics/case_broadband_dispersion/)：从合成波形驱动 K01–K03，同时验收整体色散关系和每个选定频点的波矢，并记录边界峰、并列峰。

宽带页面的图、数值表、逐频点 CSV 和源码哈希来自同次运行。阈值是这个合成案例的工程验收要求，不代表普适精度保证。


## 方法来源

本实现遵循 Liu 和 Jorns 提出的多构型贝叶斯空间反混叠方法。

## 参考文献

- M. F. Liu and B. A. Jorns, "Anti-aliasing technique for inferring dispersion of short-wavelength instabilities in electric propulsion devices," AIAA SciTech Forum, Paper AIAA-2025-1293 (2025), [doi:10.2514/6.2025-1293](https://doi.org/10.2514/6.2025-1293)。
- M. F. Liu and B. A. Jorns, "Experimental validation of a spatial anti-aliasing plasma wave analysis technique on ion acoustic turbulence in a hollow cathode plume," 39th International Electric Propulsion Conference, Paper IEPC-2025-357 (2025)。
