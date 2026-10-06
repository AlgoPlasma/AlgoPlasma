K_Diagnostics
=============

.. toctree::
    :maxdepth: 1

    K_Diagnostics/diagnostics_foundations
    K_Diagnostics/diagnostics_learning_path
    K_Diagnostics/diagnostics_usage_cookbook
    K_Diagnostics/diagnostics_testing_guide
    K_Diagnostics/K01_signal_spectra
    K_Diagnostics/K02_beall
    K_Diagnostics/K03_mle_k2d
    K_Diagnostics/K04_breathing_waveform

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   ``K_Diagnostics`` 收纳探针诊断算法。与 ``A``--``J`` 各模块处理粒子和网格不同，本模块的输入是
   探针时间序列，输出是波数、频率等谱量。它既用于实验数据分析，也可直接作用于 PIC 模拟输出的
   探针信号。

   本模块以 Python 实现，是仓库中第一个非 Fortran 的算法模块。文件组织仍遵循一个 routine 一个
   文件、``mod_`` 只做汇总的约定：``mod_`` 用 ``from ... import`` 汇总，对应 Fortran 侧的
   ``#include``。各单元的计算函数均不做文件读写；示例与测试负责调度计算。

   .. list-table:: 算法选择
      :header-rows: 1
      :widths: 8 30 26 36

      * - ID
        - 算法
        - 输入
        - 输出
      * - K01
        - :doc:`分段谱与互相位 <K_Diagnostics/K01_signal_spectra>`
        - 两路探针原始波形
        - 分段谱、功率谱、相干度、互相位及其均值与方差
      * - K02
        - :doc:`混叠代数与 Beall 谱 <K_Diagnostics/K02_beall>`
        - 单对探针的互相位
        - 折叠阶数、折叠波数、``S(k, f)``
      * - K03
        - :doc:`二维联合最大似然反演 <K_Diagnostics/K03_mle_k2d>`
        - 多构型的相位均值与方差
        - 每频点的二维波矢 ``(K_x, K_y)``

      * - K04
        - :doc:`呼吸波形分离：从探针数据到 C <K_Diagnostics/K04_breathing_waveform>`
        - 同一空间点、相同条件下的多条电压记录
        - 相位重复波形 C 与残差 R

   K04 从人工数据逐步讲到呼吸波形 C。计算函数位于 ``K_Diagnostics/K04_breathing_waveform/``，
   人工示例、测试和画图脚本位于 ``tests/011_K04_breathing_waveform/``；
   运行步骤见 :doc:`K04 测试与复现说明 </tests/011_K04_breathing_waveform/index>`。

   .. rubric:: 本模块解决的问题

   一对探针只能测到波矢在其间距方向上的投影，而且只能测到模 :math:`2\pi` 的相位。因此当波长小于
   两倍间距时，单对探针报出的是**折叠后的假波数**：一条笔直的色散支在 ``S(k, f)`` 图上被打断成
   锯齿。K02 给出这一限制的闭式几何并让它显形，K03 用多个**不同长度**的间距联合反演把它解除。
   仅改变探针方向不够——不同长度给出不可通约的条纹周期，才能定出折叠阶数。

   .. rubric:: 统一符号约定

   间距向量为 :math:`\boldsymbol{\chi} = \mathbf{r}_2 - \mathbf{r}_1`，互谱为
   :math:`C = X_1 X_2^{*}`。配合 ``numpy.fft.rfft`` 的 :math:`\exp(-i\omega t)` 正变换，平面波
   :math:`\exp[i(\mathbf{K}\cdot\mathbf{r}-\omega t)]` 给出

   .. math::

      \theta = \arg C = \mathbf{K}\cdot\boldsymbol{\chi}.

   K03 的前向模型就是该式，K02 由相位还原波数用
   :math:`k_\parallel = \mathrm{wrap}(\theta)/|\boldsymbol{\chi}|`\ ，全模块没有任何符号翻转。
   交换探针顺序会让 :math:`\theta` 反号并镜像所有反演结果。

   .. rubric:: 相关测试

   :doc:`tests/010_diagnostics </tests/010_diagnostics/index>`：一份合成宽带信号同时驱动三个单元，
   判据取自生成器本身而非人为容差。

   :doc:`tests/011_K04_breathing_waveform </tests/011_K04_breathing_waveform/index>`：K04 的本地测试、人工示例和文档图片复现。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   ``K_Diagnostics`` collects probe diagnostic algorithms. Unlike modules ``A``--``J``, which act
   on particles and grids, this module takes probe time series as input and returns spectral
   quantities. It serves experimental data analysis and applies equally to probe signals
   extracted from a PIC simulation.

   The module is written in Python, the first non-Fortran algorithm module in the repository.
   Its file organisation still follows the convention of one routine per file with a ``mod_``
   wrapper that only aggregates: here the wrapper re-exports through ``from ... import``, the
   counterpart of the Fortran ``#include``. Numerical routines perform no file I/O;
   examples and tests orchestrate the computations.

   .. list-table:: Algorithm Selection
      :header-rows: 1
      :widths: 8 30 26 36

      * - ID
        - Algorithm
        - Input
        - Output
      * - K01
        - :doc:`Segmented spectra and cross phase <K_Diagnostics/K01_signal_spectra>`
        - Two raw probe records
        - Segment spectra, power spectra, coherence, cross phase with its mean and variance
      * - K02
        - :doc:`Aliasing algebra and the Beall spectrum <K_Diagnostics/K02_beall>`
        - Cross phase of one pair
        - Fold order, folded wavenumber, ``S(k, f)``
      * - K03
        - :doc:`Joint 2-D maximum-likelihood inversion <K_Diagnostics/K03_mle_k2d>`
        - Phase means and variances of many configurations
        - Two-dimensional wavevector ``(K_x, K_y)`` per frequency

      * - K04
        - :doc:`Breathing waveform extraction: from samples to C <K_Diagnostics/K04_breathing_waveform>`
        - Repeated voltage records at one spatial point under the same conditions
        - Phase-repeatable waveform C and residual R

   K04 explains waveform extraction using artificial data. Numerical routines live in
   ``K_Diagnostics/K04_breathing_waveform/``; examples, tests and plots live in
   ``tests/011_K04_breathing_waveform/``. See the
   :doc:`K04 test and reproduction guide </tests/011_K04_breathing_waveform/index>`.

   .. rubric:: The Problem This Module Solves

   A single probe pair measures only the projection of the wavevector onto its separation, and
   only modulo :math:`2\pi` of phase. Once the wavelength drops below twice the spacing, the
   pair therefore reports a **folded, false wavenumber**: a straight dispersion branch appears
   broken into a sawtooth on the ``S(k, f)`` map. K02 supplies the closed-form geometry of that
   limit and makes it visible; K03 removes it by combining separations of several **lengths**.
   Changing only the orientation is not enough, because different lengths are what give
   incommensurate fringe periods and fix the fold order.

   .. rubric:: Shared Sign Convention

   The separation is :math:`\boldsymbol{\chi} = \mathbf{r}_2 - \mathbf{r}_1` and the cross
   spectrum is :math:`C = X_1 X_2^{*}`. With the :math:`\exp(-i\omega t)` forward transform of
   ``numpy.fft.rfft``, a plane wave
   :math:`\exp[i(\mathbf{K}\cdot\mathbf{r}-\omega t)]` gives

   .. math::

      \theta = \arg C = \mathbf{K}\cdot\boldsymbol{\chi}.

   K03's forward model is that same expression and K02 recovers the wavenumber as
   :math:`k_\parallel = \mathrm{wrap}(\theta)/|\boldsymbol{\chi}|`, so no sign flip appears
   anywhere in the module. Reversing the probe order negates :math:`\theta` and mirrors every
   recovered result.

   .. rubric:: Related Tests

   :doc:`tests/010_diagnostics </tests/010_diagnostics/index>`: one synthetic broadband dataset
   drives all three units, with criteria taken from the generator rather than from chosen
   tolerances.

   :doc:`tests/011_K04_breathing_waveform </tests/011_K04_breathing_waveform/index>`:
   K04 local tests, artificial examples and documentation figure reproduction.
