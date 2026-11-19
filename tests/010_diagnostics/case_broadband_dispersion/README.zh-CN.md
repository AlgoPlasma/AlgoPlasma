# broadband_dispersion 宽带色散测试

[English](README.md)

本算例用一组生成的合成数据驱动 `K_Diagnostics` 的三个单元，并将各单元的结果与数据生成器对照。`K_Diagnostics` 只提供计算例程，完整的计算流程在本算例中运行。

## 合成场

信号模型取自 `simulation/simulation_beall/02宽频/generate_signal.py` 中的宽带 Beall 验证。离子声波模态在色散直线 `omega = k c_s` 上形成连续谱，并在时域叠加。

- 使用氙，`m_i = 131 u`，`T_e = 20 eV`，因此 `c_s = 3825 m/s`。离子无漂移。
- 采样率为 10 MHz，每段 1250 个样本，频率格宽为 8 kHz。
- 104 kHz 到 2 MHz 范围内有 238 个模态，**每个频率格一个**，带内频谱连续。
- 振幅满足 `A ~ 1/f`，因此功率谱按 `1/f^2` 衰减。
- 各模态的传播方向均为 30°，`|K|` 从 171 到 3286 rad/m。
- 与参考算例一致，随机模态相位只抽样**一次**，由所有分段和所有构型共享。所有探针观测同一个平稳随机实现。
- 各探针叠加独立的高斯白噪声，宽带信噪比为 10。

每段波形是在两探针位置上计算 `sum_n A_n cos(K_n . x_p - omega_n t + phi_n)`，所以两探针间相位差恰好为 `K_n . chi`。每段时间从零开始，使各段在自身长度上满足周期性，每个模态都精确落在一个 rFFT 频率格中。

仓库不保存生成的记录。`make.sh` 根据 `source_py/config.py` 中的常量将记录重建到 `build/`，`clean.sh` 删除这些记录。

### 两组探针

**反演阵列**有 35 种构型，间距为 3.0–5.0 mm，方位角为 0–90°，每种记录 256 段。相位分布由这些重复分段估计。

**Beall 探针对**是一组单独的对准探针，间距 20 mm，记录 512 段。第一个混叠边界是 `f_alias = c_s/(2d)`，完整折叠周期是 `c_s/d`。生成的模态覆盖第 1 到第 10 阶共十个折叠阶，`f_max/f_alias` 不能用来计数完整折叠周期。较长的探针间距使多次折叠可见，同时不扩大反演搜索域。

## 检查项目

- K01 检查谱指数、频带下边缘、总功率越过噪声底十倍时的位置以及相干度。
- K02 检查强模态谱峰的周期误差，以直方图格数计量。
- K03 检查声速、模长和方向的统计量、**每个选中波矢**，以及边界峰和并列峰标志。

`source_py/config.py: ACCEPTANCE` 声明了验收条件。这些阈值是这个固定合成算例的工程要求。[双语测试文档](../../../docs/source/tests/010_diagnostics/case_broadband_dispersion.rst)解释了各项阈值，并附有同次运行的表格和四幅图。

总功率条件 `signal + noise > 10*noise` 对应信号阈值 `9*noise`。阈值预测按这个定义计算。K03 要求每个波矢满足 `|K_est-K_true| <= 0.05*|K_true| + grid_step/sqrt(2)`。网格项是到最近网格点的距离预算，5% 项是声明的有噪声反演要求。该参考算例不允许超预算模态、边界峰或多个完全并列的最大值。一般实验数据的估计有效性和唯一性仍需另行验证。

本算例在每个频率仅设一个传播方向。同频多波以及噪声或几何改变的情况需要单独验证。

## 运行

```bash
bash run.sh
# 所有检查通过后，另行发布同次运行的文档快照：
bash run.sh --publish-docs
```

驱动程序先运行四个小型验收反例，再重新生成记录并运行 K01–K03。`source_py/test_acceptance.py` 可以独立运行，无需波形文件。算法的解析参考检查见[基础数值测试](../case_basic_checks/README.zh-CN.md)。向量化反演最多使用 48 个工作进程，以分行计算控制内存用量。

输出包括以下内容。

- `output/summary.json` 记录要求、测量值、逐模态误差和原因，以及源文件哈希。
- `output/modes.csv` 每行对应一个反演频点，包含真实与反演分量以及搜索标志。
- `output/results_zh.rst` 和 `output/results_en.rst` 是本次运行生成的表格。
- `output/figures/` 下有 `raw_waveform.png`、`power_spectrum.png`、`beall_skf.png` 和 `mle_dispersion.png`。

`--publish-docs` 一并更新 `docs/source/tests/010_diagnostics/_generated/case_broadband_dispersion/` 中的小型数值快照，以及 `docs/source/images/tests/010_diagnostics/case_broadband_dispersion/` 中的四幅图。若运行失败，诊断文件留在 `output/`，已发布快照继续可用。`clean.sh` 删除运行产物以及 `build/` 下约 95 MB 的生成记录。

## 相关文档

[K_Diagnostics](../../../K_Diagnostics/README.zh-CN.md)、
[K01_signal_spectra](../../../K_Diagnostics/K01_signal_spectra/README.zh-CN.md)、
[K02_beall](../../../K_Diagnostics/K02_beall/README.zh-CN.md)、
[K03_mle_k2d](../../../K_Diagnostics/K03_mle_k2d/README.zh-CN.md)。
