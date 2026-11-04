# K05 · 双谱转移分析

[中文](README.zh-CN.md) | [English](README.en.md)

围绕 Brown 与 Jorns 的 *Physical Review Letters* **130**, 115101 (2023)，
学习波增长、波间耦合与探针数据分析的联系。
[论文 DOI](https://doi.org/10.1103/PhysRevLett.130.115101)。

## 阅读导览

[K05 主页面](../../docs/source/rst_files/K_Diagnostics/K05_bispectral_transfer.rst)
简述目的，列出下方十一篇平行正文；按 01–11 阅读。

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
互动图联动空间波形与两条时间曲线；折叠区补充余弦波的复系数和载波相消。
明确双边归一化、导数与二次乘积的频率域形式，以及离子电流作为电势代理的条件。

[第四页面：从重复记录到功率谱、互谱与双谱](../../docs/source/rst_files/K_Diagnostics/K05_spectral_statistics.rst)
从分段与平均讲到功率、互谱相位和双谱；用三个复系数的乘积解释相位关系怎样在平均后保留。
折叠区补充平方双相干、NumPy 矩计算及互双谱的共轭次序。
最后从连续波动方程导出电势平方收支，保留耦合系数与双谱的复数乘积。

[第五页面：从统计量估计增长与耦合](../../docs/source/rst_files/K_Diagnostics/K05_coefficient_inference.rst)
从单波对、两个系数出发，讲到完整矩阵、可辨识性与 Kim 平稳性修正；
平稳修正先区分测得功率与模型功率，逐条解释新增矩方程，再用单波对展开消元，矩阵细节另行折叠。
明确相位旋转、群速度、幅值／功率增长及连续／有限步长转移的区别。

英文视图不含中文；中文视图保留英文术语。十一篇正文共用 K05 公式编号，支持跨页引用。

## 从数据到图的工作流程

1. 明确同步探针电压、采样率、探针顺序、间距、标定、平稳时间窗和不确定度。
2. 核对 Fourier 符号、幅值归一化和正负频率约定，再衔接 K01 频谱工具。
3. 计算三阶与四阶统计量，估计线性及二次系数，并检查病态性与合成数据真值。
4. 利用传播信息把空间系数转为增长率和转移率，区分幅值与功率增长率。
5. 输出频谱、增长率曲线、转移图以及不确定度、数据来源。对照原图还需要相应实验数据和参数。

公式对照框明确记录相位、归一化、波对计数和因子 2 的约定，实验示例按这些约定计算。
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
- 第四页：`K05_spectral_statistics.rst`。
- 目录：`K05_bispectral_transfer.rst` 的 toctree 并列列出十一篇正文。
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

公式采用跨页面、双语共用的 K05.n 编号，按目录中的页面次序和页内出现顺序连续排列，
折叠区也参与编号。新增或移动公式后，运行 `renumber_equations.py --write`，
再用 `--check` 检查并完整重建网站。当前有140个有效公式。
原有语义ID及链接保留；显示编号会随顺序更新。R31新旧号对照见
`equation_number_migration_20261103.json`。退役语义ID不能用于不同公式。
求和展开、相位求导与逐项代入仍收纳；第二页补有Poisson步骤和冷电子极化率例子。
入口与十一篇正文均为中性完成版；插图保留用于区分物理量的正常配色。
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
运行 `analyze_probe_sweep.py`，使用 `probe_sweep_config.json` 复现均值 I–V 流程。
页面用同一份0015逐步解释分箱、背景扣除、区间与斜率，并对照6.73与9.17 eV的来源。
原中位数流程保留作比较，详见 [EXPERIMENT.md](EXPERIMENT.md)。


第九页：[把实验数据画成文献图2、图3的形式](../../docs/source/rst_files/K_Diagnostics/K05_paper_comparison.rst)，先看五个面板，再说明计算与估计参数。第十页：[结果解释补充](../../docs/source/rst_files/K_Diagnostics/K05_power_budget.rst)，展开共同功率、相位和完整收支。复现见EXPERIMENT.md。


## 原式对照与全文收束

01、03、05、09页在对应的K05式下面列出文献原式(1)–(7)，使用固定对照框，
逐项说明符号／归一化／简化；入口可直接跳转。原式也参与当前K05编号，语义ID提供稳定链接；
框标题保留文献自身式号。09页增加线性Vlasov响应、冷离子极化率、Maxwell回旋轨道平均
和Poisson闭合推导。
[第11页](../../docs/source/rst_files/K_Diagnostics/K05_paper_synthesis.rst)
用原图讲增长、转移和饱和，补周向／总增长的关系与条件平稳收支，
附结果路线及符号表。实测数值产物没有重算。
