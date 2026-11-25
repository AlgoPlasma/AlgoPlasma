Probe Wave Diagnostics
======================

.. toctree::
   :maxdepth: 1

   diagnostics_foundations
   diagnostics_learning_path
   diagnostics_usage_cookbook
   diagnostics_testing_guide

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 探针波动诊断

   本专题是 :doc:`K_Diagnostics <../K_Diagnostics>` 的一条学习路线，串起 K01 → K02 → K03，
   讨论如何从探针时间序列估计频率、投影波数和二维传播方向，以及空间混叠带来的限制。
   输入包括采样对齐的探针对记录、采样率和对应的基线向量；K03 还需要多个构型及波数搜索范围。

   .. rubric:: 阅读与使用

   - 初次接触方法：先读 :doc:`探针诊断基础 <diagnostics_foundations>`，再按 :doc:`学习路径 <diagnostics_learning_path>` 进入函数。
   - 准备处理数据：查 :doc:`使用示例 <diagnostics_usage_cookbook>`，核对数组形状、单位和构型信息。
   - 准备核对结果：查 :doc:`测试指南 <diagnostics_testing_guide>`，了解参考值与验收判据。

   阅读顺序是 :doc:`K01 频谱与相位统计 <K01_signal_spectra>` →
   :doc:`K02 探针对波数–频率谱 <K02_beall>` → :doc:`K03 多构型波矢反演 <K03_mle_k2d>`。
   K02 与 K03 也可分别使用 K01 的输出；K03 的输入是多构型相位统计，不需要先计算 Beall 谱。

   .. rubric:: 这个专题解决的问题

   一对探针只能测到波矢在其间距方向上的投影，而且只能测到模 :math:`2\pi` 的相位。当
   :math:`|\mathbf{K}\cdot\boldsymbol{\chi}|>\pi` 时，真实投影波数超出单对探针的主值区间，
   报出的是**折叠波数**：一条笔直的色散支在 ``S(k, f)`` 图上可呈锯齿。
   K02 给出折叠波数与真实投影波数之间的关系，并用 Beall 谱展示频率与折叠波数的分布。
   单对相位不能恢复被混叠隐藏的折叠阶；K02 的折叠阶计算需要已知的投影波数。

   K03 组合多个构型的相位测量。每条基线约束沿该方向的波矢投影，多个方向共同提供二维信息。
   K03 在二维波数范围内遍历均匀网格，以联合对数似然最大处的波矢作为估计结果。
   基线长度、方向及搜索范围决定能否区分候选波矢；
   :doc:`诊断基础 <diagnostics_foundations>` 第 7 节介绍条纹交汇与几何条件。

   .. rubric:: K01–K03 探针分析链的符号约定

   间距向量为 :math:`\boldsymbol{\chi} = \mathbf{r}_2 - \mathbf{r}_1`，互谱为
   :math:`C = X_1 X_2^{*}`。配合 ``numpy.fft.rfft`` 的 :math:`\exp(-i\omega t)` 正变换，平面波
   :math:`\exp[i(\mathbf{K}\cdot\mathbf{r}-\omega t)]` 给出

   .. math::

      \theta = \arg C = \mathbf{K}\cdot\boldsymbol{\chi} \pmod{2\pi}.

   K03 的前向相位为 :math:`\mathbf{K}\cdot\boldsymbol{\chi}`，K02 由相位还原波数用
   :math:`k_\parallel = \mathrm{wrap}(\theta)/|\boldsymbol{\chi}|`；这条分析链没有额外的符号翻转。
   交换探针顺序时，必须同时反转基线向量；若仅反转互相位而保持几何不变，反演波矢会镜像。

   .. rubric:: 配套测试

   :doc:`基础数值测试 </tests/010_diagnostics/case_basic_checks>` 检查功率与相位、相位统计、Beall 权重与谱峰。
   :doc:`宽带测试 </tests/010_diagnostics/case_broadband_dispersion>` 用一份合成信号驱动 K01–K03，
   把谱指数、折叠波数和恢复波矢与生成器参考值比较。运行入口见 :doc:`010 测试总览 </tests/010_diagnostics/index>`。

.. container:: ap-lang ap-lang-en

   .. rubric:: Probe Wave Diagnostics

   This topic is one learning route within :doc:`K_Diagnostics <../K_Diagnostics>`.
   It follows K01 → K02 → K03 to estimate frequencies, projected wavenumbers and two-dimensional
   propagation directions from probe time series, with explicit attention to spatial aliasing.
   Inputs include aligned probe-pair records, their sampling rate and baseline vectors;
   K03 additionally needs multiple configurations and a wavenumber search range.

   .. rubric:: Reading and Usage

   - New to the methods: start with the :doc:`foundations <diagnostics_foundations>`, then follow the :doc:`learning path <diagnostics_learning_path>` to the routines.
   - Ready to process data: use the :doc:`cookbook <diagnostics_usage_cookbook>` to check array shapes, units and configuration information.
   - Ready to assess results: consult the :doc:`testing guide <diagnostics_testing_guide>` for reference values and acceptance criteria.

   The reading order is :doc:`K01 spectra and phase statistics <K01_signal_spectra>` →
   :doc:`K02 probe-pair wavenumber–frequency spectra <K02_beall>` →
   :doc:`K03 wavevector inversion across configurations <K03_mle_k2d>`.
   K02 and K03 can each consume K01 outputs independently: K03 uses phase statistics across
   configurations and does not require a Beall spectrum first.

   .. rubric:: The Problem Addressed by This Topic

   A single probe pair measures only the wavevector projection along its separation and only
   modulo :math:`2\pi` of phase. When :math:`|\mathbf{K}\cdot\boldsymbol{\chi}|>\pi`, the true
   projected wavenumber lies outside the pair's principal interval. The reported value is a
   **folded wavenumber**: a straight dispersion branch can become a sawtooth on the ``S(k, f)`` map.
   K02 relates true and folded projected wavenumbers and constructs the Beall spectrum.
   One pair's phase cannot recover the hidden fold order; the K02 fold-order calculation
   requires a known projected wavenumber.

   K03 combines phase measurements from several configurations. Each baseline constrains the
   wavevector projection along its direction; multiple directions provide two-dimensional
   information. K03 evaluates a uniform two-dimensional wavenumber grid and reports its maximum
   joint log-likelihood point. Baseline lengths, directions and the search range determine
   whether candidate wavevectors can be distinguished. Section 7 of the
   :doc:`foundations <diagnostics_foundations>` explains fringe intersections and geometry conditions.

   .. rubric:: Sign Convention for the K01–K03 Probe Analysis Chain

   The separation is :math:`\boldsymbol{\chi} = \mathbf{r}_2 - \mathbf{r}_1` and the cross
   spectrum is :math:`C = X_1 X_2^{*}`. With the :math:`\exp(-i\omega t)` forward transform of
   ``numpy.fft.rfft``, a plane wave :math:`\exp[i(\mathbf{K}\cdot\mathbf{r}-\omega t)]` gives

   .. math::

      \theta = \arg C = \mathbf{K}\cdot\boldsymbol{\chi} \pmod{2\pi}.

   K03 models the phase as :math:`\mathbf{K}\cdot\boldsymbol{\chi}`; K02 recovers wavenumbers as
   :math:`k_\parallel = \mathrm{wrap}(\theta)/|\boldsymbol{\chi}|`, with no additional sign flip
   in this chain. Reversing the probe order requires reversing the baseline vector as well;
   negating only the phase while keeping the geometry fixed mirrors the recovered wavevector.

   .. rubric:: Supporting Tests

   The :doc:`basic numerical tests </tests/010_diagnostics/case_basic_checks>` check power and phase,
   phase statistics, and Beall weights and peaks. The
   :doc:`broadband test </tests/010_diagnostics/case_broadband_dispersion>` drives K01–K03 from one
   synthetic signal and compares spectral slopes, folded wavenumbers and recovered wavevectors
   against generator references. See the :doc:`010 test overview </tests/010_diagnostics/index>` for running instructions.
