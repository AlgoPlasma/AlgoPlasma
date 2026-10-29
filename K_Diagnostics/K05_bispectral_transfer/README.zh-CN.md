# K05 · 双谱转移分析

[中文](README.zh-CN.md) | [English](README.en.md)

围绕 Brown 与 Jorns 的 *Physical Review Letters* **130**, 115101 (2023)，
学习波增长、波间耦合与探针数据分析的联系。
[论文 DOI](https://doi.org/10.1103/PhysRevLett.130.115101)。

## 阅读导览

[K05 主页面](../../docs/source/rst_files/K_Diagnostics/K05_bispectral_transfer.rst)
简述目的，列出下方八篇平行正文；按 01–08 阅读。

[第一页面：波增长与耦合](../../docs/source/rst_files/K_Diagnostics/K05_wave_growth.rst)
解释 Brown 与 Jorns (2023) 的公式 (1)：实波形 → 复包络 → 随包络运动的变化率 → 二次耦合 → 恢复快相位。
详细代数可以展开；波包图可调时间、增长或衰减，并可播放。
图中参数仅用于教学，不是实验数据或 EDI 动理学计算。

[第二页面：包络方程和系数从哪里来](../../docs/source/rst_files/K_Diagnostics/K05_envelope_coefficients.rst)
从等离子体响应的自洽性出发，通过邻近波的偏移，推导群速度与增长率，
再加入独立的二阶电荷响应，得到二次耦合系数。先讲一维，最后推广三维。
泊松方程整理、链式法则和近似条件可按需展开。

新增波数谱宽与波包的互动示意，可调谱宽和时间，完整函数放在折叠区。
泰勒展开补充从一元到二元的连接、二阶与虚部导数项；增长率补充舍弃项的大小比较，
泊松方程补充逐项代入和移项。

[第三页面：从移动的波到探针记录](../../docs/source/rst_files/K_Diagnostics/K05_probe_signals.rst)
用固定位置记录、时间傅里叶复系数和双探针比较连接文献公式 (1) 与 (2)。
互动图联动空间波形与两条时间曲线；折叠区补充相消、有限记录端点、传播解及 FFT 符号。
明确双边归一化、K01 转换，以及离子电流作为电势代理的条件。

[第四页面：从重复记录到功率谱、互谱与双谱](../../docs/source/rst_files/K_Diagnostics/K05_spectral_statistics.rst)
从分段与平均讲到功率、互谱相位和双谱；折叠区补充谱密度归一化、平方双相干、
NumPy 矩计算及互双谱的共轭次序。互动图固定三个频率的幅值，比较固定与独立相位关系。
最后从连续波动方程导出电势平方收支，保留耦合系数与双谱的复数乘积。

[第五页面：从统计量估计增长与耦合](../../docs/source/rst_files/K_Diagnostics/K05_coefficient_inference.rst)
从单波对、两个系数出发，讲到完整矩阵、可辨识性与 Kim 平稳性修正；
平稳修正先区分测得功率与模型功率，逐条解释新增矩方程，再用单波对展开消元，矩阵细节另行折叠。
明确相位旋转、群速度、幅值／功率增长及连续／有限步长转移的区别。

英文视图不含中文；中文视图保留英文术语。八篇正文共用 K05 公式编号，支持跨页引用。

## 后续从数据到图的路线

1. 明确同步探针电压、采样率、探针顺序、间距、标定、平稳时间窗和不确定度。
2. 核对 Fourier 符号、幅值归一化和正负频率约定，再衔接 K01 频谱工具。
3. 计算三阶与四阶统计量，估计线性及二次系数，并检查病态性与合成数据真值。
4. 利用传播信息把空间系数转为增长率和转移率，区分幅值与功率增长率。
5. 输出频谱、增长率曲线、转移图以及不确定度、数据来源。对照原图还需要相应实验数据和参数。

编码前需解决相位、归一化、波对计数和因子 2 的约定。
K01 当前使用 NumPy 的正向 `exp(-i omega t)` 变换及 `X1 * conj(X2)` 互谱，不能隐式更改。

## 编辑与接续

- 页面：`docs/source/rst_files/K_Diagnostics/K05_bispectral_transfer.rst`
  为简短入口；正文在同目录 `K05_wave_growth.rst`、
  `K05_envelope_coefficients.rst`、`K05_probe_signals.rst`。
- 插图：`docs/source/_static/K_Diagnostics/k05-wave-packet.{js,css,svg}`。
- 同目录下 `k05-packet-band.js` 与双语 `k05-packet-band-{en,zh}.svg` 提供谱宽示意。
  静态后备图与浏览器共用渲染函数；重建方法见英文 README。
- 双探针联动图：`k05-probe-signals.js` 及双语 `k05-probe-signals-{en,zh}.svg`。
- 第五页：`K05_coefficient_inference.rst`。
- 第四页：`K05_spectral_statistics.rst`；相位图：`k05-phase-statistics.js` 与双语 SVG。
- 目录：`K05_bispectral_transfer.rst` 的 toctree 并列列出八篇正文。
- 环境使用已有 `docs/requirements.txt`；文档配置还会调用 Doxygen。仓库根目录运行：

```sh
python -m sphinx -b html -W --keep-going docs/source docs/build/html
python -m http.server 8055 --bind 127.0.0.1 --directory docs/build/html
```

访问 `http://localhost:8055/rst_files/K_Diagnostics/K05_bispectral_transfer.html`。
不要修改生成的 HTML；编辑后检查两种语言、公式、折叠区以及时间、增长和播放控制。

阅读顺序：波增长与耦合 → 包络方程和系数的来源 → 固定探针记录与时间 Fourier 方程
→ 功率谱、互谱和双谱统计。正文逐步引入概念，技术条件放在折叠区。
公式核对原文纸面第 115101-2 页。更完整的文献学习历史在文献项目唯一的共享
`HANDOFF.md` 中；WSL 仓库与文献项目需要分别实际同步，才能在其他电脑继续。

## 公式与推导维护

公式采用跨页面、双语共用的 K05.n 编号。包络方程为 K05.7，一维完整波形方程为 K05.20，
三维方程仍为 K05.15。求和展开、相位求导与逐项代入放入折叠区。
原先具体 A/VQ 的互动例子已移除；K05.11–K05.13 保留为退役编号，不复用。
高斯绘图函数收纳。K05.16、K05.17 已移至第二页面；新增公式为 K05.22–K05.34。
谱宽与展开补充为 K05.35–K05.44；探针记录页面追加 K05.45–K05.59。
第 8 版追加 K05.60–K05.62，补充奈奎斯特频率、分部积分与空间传播积分。
第 10 版追加 K05.63–K05.75，介绍平均、谱统计和电势平方收支。
入口与八篇正文均为中性完成版；插图保留用于区分物理量的正常配色。
后续添加公式或页面时，先读 [公式编号维护说明](EQUATIONS.md)。

## 实验数据页面

[第六页](../../docs/source/rst_files/K_Diagnostics/K05_experimental_signals.rst)
使用四组同步实验记录，从波形逐步走到 PSD、互谱和双相干。
读取器、计算参数、测试及重建命令见 [EXPERIMENT.md](EXPERIMENT.md)。
原始 bin 不放入仓库；图使用去整段均值的电压波动，绝对直流标定与通道响应另行核查。

[第七页](../../docs/source/rst_files/K_Diagnostics/K05_model_validation.rst)
比较线性与二次模型对整组留出记录的预测，依次检查误差、残差关联、系数可辨识性和预定设置的敏感性。
使用 `validate_experiment.py` 复现，详见 [EXPERIMENT.md](EXPERIMENT.md)。

[第八页](../../docs/source/rst_files/K_Diagnostics/K05_probe_response.rst)
使用 DL350 慢扫描重建 I–V 曲线和温度斜率，并用明确标注的暂用估计检查偏置与电路响应。
运行 `analyze_probe_response.py`，在 `probe_response_config.json` 中替换假设。
