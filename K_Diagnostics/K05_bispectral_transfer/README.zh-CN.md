# K05 · 双谱转移分析

[中文](README.zh-CN.md) | [English](README.en.md)

围绕 Brown 与 Jorns 的 *Physical Review Letters* **130**, 115101 (2023)，
学习波增长、波间耦合与探针数据分析的联系。
[论文 DOI](https://doi.org/10.1103/PhysRevLett.130.115101)。

## 当前内容

[理论页面](../../docs/source/rst_files/K_Diagnostics/K05_bispectral_transfer.rst)
解释 Brown 与 Jorns (2023) 的公式 (1)：实波形 → 复包络 → 随包络运动的变化率 → 二次耦合 → 恢复快相位。
英文视图不含中文；中文视图保留英文术语。第 4 版展开相位求导与匹配恒等式，
先给出代入后的完整一维方程，再推广三维。蓝色表示本轮新增，紫红色表示本轮修订。详细代数可以展开；波包图可调时间、
增长或衰减，并可播放。图中参数仅用于教学，不是实验数据或 EDI 动理学计算。

**当前仅有文档。** 尚无 K05 数值函数、探针分析脚本、数值示例或数值测试；
网页动画不是分析接口。没有复现论文的实验图。

## 后续从数据到图的路线

1. 明确同步探针电压、采样率、探针顺序、间距、标定、平稳时间窗和不确定度。
2. 核对 Fourier 符号、幅值归一化和正负频率约定，再衔接 K01 频谱工具。
3. 计算三阶与四阶统计量，估计线性及二次系数，并检查病态性与合成数据真值。
4. 利用传播信息把空间系数转为增长率和转移率，区分幅值与功率增长率。
5. 输出频谱、增长率曲线、转移图以及不确定度、数据来源。对照原图还需要相应实验数据和参数。

以上尚未实现。编码前需解决相位、归一化、波对计数和因子 2 的约定。
K01 当前使用 NumPy 的正向 `exp(-i omega t)` 变换及 `X1 * conj(X2)` 互谱，不能隐式更改。

## 编辑与接续

- 页面：`docs/source/rst_files/K_Diagnostics/K05_bispectral_transfer.rst`。
- 插图：`docs/source/_static/K_Diagnostics/k05-wave-packet.{js,css,svg}`。
- 文档入口：`docs/source/rst_files/K_Diagnostics.rst` 与 K 组 README。
- 环境使用已有 `docs/requirements.txt`；文档配置还会调用 Doxygen。仓库根目录运行：

```sh
python -m sphinx -b html -W --keep-going docs/source docs/build/html
python -m http.server 8055 --bind 127.0.0.1 --directory docs/build/html
```

访问 `http://localhost:8055/rst_files/K_Diagnostics/K05_bispectral_transfer.html`。
不要修改生成的 HTML；编辑后检查两种语言、公式、折叠区以及时间、增长和播放控制。

接续记录（2026-10-23）：先根据读者的问题改进这一短篇初稿，再讲 Eq. (1) 到 Eq. (2)
的时间 Fourier 变换，之后实现反演。正文少引入新概念，技术条件放在折叠区。
公式核对原文纸面第 115101-2 页。更完整的文献学习历史在文献项目唯一的共享
`HANDOFF.md` 中；WSL 仓库与文献项目需要分别实际同步，才能在其他电脑继续。

## 公式与推导维护

公式采用跨页面、双语共用的 K05.n 编号。包络方程为 K05.7，一维完整波形方程为 K05.20，
三维方程仍为 K05.15。求和展开、相位求导与逐项代入放入折叠区。
原先具体 A/VQ 的互动例子已移除；K05.11–K05.13 保留为退役编号，不复用。
高斯绘图函数收纳，进阶匹配讨论在页末；只标记本轮增改。
后续添加公式或页面时，先读 [公式编号维护说明](EQUATIONS.md)。
