# K03_mle_k2d

[中文](README.zh-CN.md) | [English](README.en.md)

`K03_mle_k2d` 把多个探针构型的相位测量联合成一次二维最大似然反演，给出每个频点的波矢 `(K_x, K_y)`。它是解除混叠的环节：单构型的似然是一族平行条纹，多构型的条纹族相交，而不同**间距长度**的条纹周期不可通约，从而定出唯一的折叠阶数。

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
| `fun_K03_search_wavevector.py` | 粗搜 + 细化的两级搜索。 |

## 接口

| 函数 | 作用 |
| --- | --- |
| `fun_K03_wavenumber_grid(k_range_rad_m, n_grid)` | 构造 `[-k_range, +k_range]` 上的均匀网格。 |
| `fun_K03_predicted_phase(chi, kx_values, ky_values)` | 前向模型 `K·χ` 在网格上的取值。 |
| `fun_K03_config_log_likelihood(chi, delta_theta, variance, kx_values, ky_values)` | 单构型对数似然。 |
| `fun_K03_joint_log_likelihood(configurations, kx_values, ky_values, normalise=True)` | 多构型求和。 |
| `fun_K03_peak_wavevector(log_likelihood, kx_values, ky_values)` | 峰位及其极坐标形式。 |
| `fun_K03_search_wavevector(configurations, k_range_rad_m, ...)` | 先粗搜全域、再在峰位附近细化的两级搜索。 |

数组按 `[iy, ix]` 索引，与 `numpy.meshgrid` 默认次序一致。

## 似然

```
ln L_j(K) = -½ · wrap(K·χ_j - θ̄_j)² / σ_j²
ln L(K)   = Σ_j ln L_j(K)
```

前向模型 `K·χ` 与 `K01_signal_spectra` 的互相位约定一致，不带符号翻转。

**残差在平方前先折算到 `(-π, π]`。** 这一步不是数值便利：正是它使混叠构型贡献出周期性的条纹族而非单条脊，混叠信息因而保留在似然里、可以被其他构型解出。

## 注意事项

- **必须有不同的间距长度**。若几何集合只含一个长度，所有构型的条纹周期相同，折叠阶数无法确定，反演无法超出该长度的 Nyquist 波数。仅改变方向不够。
- **搜索范围**。估计值被限制在网格内，`k_range` 必须包含真实波矢；峰位贴在边界说明范围过窄。网格离散化给出半个网格步长的精度下限。
- **方差是单样本方差**。`K01` 返回的 `σ²` 描述单个分段样本。各构型分段数相同时这只是似然的整体常数因子，不影响峰位；分段数不同时应自行按均值方差 `σ²/n` 加权。
- **内存**。似然数组为 `n_grid²` 个 float64，401×401 约 1.3 MB，逐构型累加。
- **宽频带要用两级搜索**。单一均匀网格既要够到最大波矢、又要分辨最小波矢；跨三个数量级需要每轴数千点。`search_wavevector` 先在全域粗搜、再在粗峰附近重建细网格。粗搜只需选对条纹而非条纹内的具体位置。由于条纹周期 `2π/|χ|` 随间距增大而减小，最长间距产生最小周期并给出最严格的网格限制；粗步长应显著小于该周期。结果若被锁到错误折叠阶，先查这一条。

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

`tests/010_diagnostics/case_broadband_dispersion`：35 个构型联合反演 80 个频点，波数跨 171–3286 rad/m。判据是把恢复出的 `f` 对 `|k̂|` 拟合成过原点的直线，斜率必须还原生成信号时用的离子声速——这是物理常数，不是人为容差。

| 量 | 实测 |
| --- | --- |
| 拟合离子声速 | 3829.6 m/s（真值 3824.6，相对误差 **1.3e-3**） |
| `|k|` 相对误差 | 中位 0.28%，p95 0.83% |
| 方向角误差 | 中位 0.26°，p95 0.62° |

同一份数据在 K02 的单对探针图上是折叠的锯齿，在这里被还原成直线。

## 方法来源

本实现遵循 Liu 和 Jorns 提出的多构型贝叶斯空间反混叠方法。

## 参考文献

- M. F. Liu and B. A. Jorns, "Anti-aliasing technique for inferring dispersion of short-wavelength instabilities in electric propulsion devices," AIAA SciTech Forum, Paper AIAA-2025-1293 (2025), [doi:10.2514/6.2025-1293](https://doi.org/10.2514/6.2025-1293)。
- M. F. Liu and B. A. Jorns, "Experimental validation of a spatial anti-aliasing plasma wave analysis technique on ion acoustic turbulence in a hollow cathode plume," 39th International Electric Propulsion Conference, Paper IEPC-2025-357 (2025)。
