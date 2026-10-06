==========================
Diagnostics Usage Cookbook
==========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这页解决什么问题

   本页面向已经理解混叠、想把 ``K_Diagnostics`` 接进自己分析流程的读者。它说明该按什么顺序调用
   哪些 routine、怎样准备输入数据，以及如何选择分段、窗口和网格参数。

   .. rubric:: 先选哪个单元

   .. list-table::
      :header-rows: 1
      :widths: 26 40 34

      * - 手里有什么
        - 想得到什么
        - 用哪个
      * - 一对探针
        - 谱形态、相干频段
        - K01
      * - 一对探针
        - 波数-频率分布 :math:`S(k,f)`
        - K01 → K02
      * - 多个具有互补方向与间距的构型
        - 每个频点的二维波矢
        - K01 → K03
      * - 同一份数据
        - 混叠与解混叠的对照
        - K01 → K02 与 K03 各走一遍

   .. rubric:: 输入准备

   - **读数据**。三个单元都不做任何文件读写，原始记录从哪来、怎么对齐时间由调用方决定。
   - **探针顺序**。间距定义为 :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`，传给
     ``fun_K01_cross_phase`` 的第二个参数必须是位于 :math:`+\boldsymbol{\chi}` 的那一路。
     搞反会让所有结果镜像而不报错。
   - **单位自洽**。间距用米、波数用 rad/m、频率用 Hz。模块不做任何单位换算。
   - **加窗**。可向 segment_ffts 传 window='hann'，并向 power_spectrum 传相同参数。
   - **搜索范围**。``k_range`` 必须包含真实波矢。边界峰需要核查范围。

   .. rubric:: 最小调用结构

   .. code-block:: python

      import sys
      sys.path.insert(0, "/path/to/AlgoPlasma")

      import numpy as np
      from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (
          fun_K01_cross_phase, fun_K01_phase_mode_statistics, fun_K01_segment_ffts,
      )
      from K_Diagnostics.K03_mle_k2d.mod_K03_mle_k2d import fun_K03_search_wavevector

      configurations = []
      for chi, probe_1, probe_2 in probe_pairs:          # 调用方自行读取
          ffts_1 = fun_K01_segment_ffts(probe_1, nperseg)
          ffts_2 = fun_K01_segment_ffts(probe_2, nperseg)
          phase, _ = fun_K01_cross_phase(ffts_1, ffts_2)
          mean_phase, variance = fun_K01_phase_mode_statistics(phase[:, mode_bins])
          configurations.append((chi, mean_phase[m], variance[m]))

      result = fun_K03_search_wavevector(configurations, k_range_rad_m=3800.0)

   .. rubric:: 参数怎么选

   - 分段长度决定频率分辨率。非整周期实信号的泄漏可能偏置互相位；可用 window='hann' 减轻，并用相同窗口做 PSD 归一化。
   - 分段数决定相位直方图的样本量。可增加分段数并比较众数位置的变化，检查当前噪声水平与分箱下的统计稳定性。
   - **波数格数**。Beall 的波数范围恒为 :math:`\pm\pi/|\boldsymbol{\chi}|`，不要设得更宽或更窄。
   - 网格步长为 2*k_range/(n_grid-1)。固定范围后逐步增加 n_grid，比较估计波矢以检查数值收敛。

   .. rubric:: 结果检查

   - 结合基线方向和长度检查联合似然中的候选峰，参见基础页的几何条件。
   - 此方差描述分段相位的散布，用于设置似然中的残差尺度。众数的估计误差另受样本数、分箱和相位分布影响。
   - 比较折叠波数时使用圆周残差；直接相减会在 Nyquist 边附近产生接近一个周期的假误差。
   - 先识别信号高于噪声底的频段，再判断信号相干性；带外相干度用于检查噪声基准，不能作为传播方向可靠的证据。

.. container:: ap-lang ap-lang-en

   .. rubric:: What This Page Is For

   This page is for a reader who already understands aliasing and wants to wire
   ``K_Diagnostics`` into their own analysis. It states the order in which to call the routines,
   how to prepare input data, and how to choose segment, window and grid parameters.

   .. rubric:: Choose the Unit First

   .. list-table::
      :header-rows: 1
      :widths: 26 40 34

      * - What you have
        - What you want
        - What to use
      * - One probe pair
        - Spectral shape, coherent band
        - K01
      * - One probe pair
        - The wavenumber-frequency distribution :math:`S(k,f)`
        - K01 then K02
      * - Complementary baseline directions and spacings
        - A two-dimensional wavevector per frequency
        - K01 then K03
      * - The same dataset
        - The contrast between aliasing and its removal
        - K01, then K02 and K03 separately

   .. rubric:: What the Caller Owns

   - **Reading data.** None of the three units performs file I/O; where the records come from
     and how they are time-aligned is the caller's decision.
   - **Probe order.** The separation is :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`,
     so the second argument of ``fun_K01_cross_phase`` must be the probe at
     :math:`+\boldsymbol{\chi}`. Reversing it mirrors every result without raising an error.
   - **Consistent units.** Separations in metres, wavenumbers in rad/m, frequencies in Hz. The
     module converts nothing.
   - **Windowing.** Use window='hann' for non-bin-aligned data, with matching power_spectrum normalization.
   - **Search range.** ``k_range`` must contain the true wavevector; a boundary peak warrants
     expanding the range and comparing estimates.

   .. rubric:: Minimal Calling Structure

   .. code-block:: python

      import sys
      sys.path.insert(0, "/path/to/AlgoPlasma")

      import numpy as np
      from K_Diagnostics.K01_signal_spectra.mod_K01_signal_spectra import (
          fun_K01_cross_phase, fun_K01_phase_mode_statistics, fun_K01_segment_ffts,
      )
      from K_Diagnostics.K03_mle_k2d.mod_K03_mle_k2d import fun_K03_search_wavevector

      configurations = []
      for chi, probe_1, probe_2 in probe_pairs:          # caller reads its own data
          ffts_1 = fun_K01_segment_ffts(probe_1, nperseg)
          ffts_2 = fun_K01_segment_ffts(probe_2, nperseg)
          phase, _ = fun_K01_cross_phase(ffts_1, ffts_2)
          mean_phase, variance = fun_K01_phase_mode_statistics(phase[:, mode_bins])
          configurations.append((chi, mean_phase[m], variance[m]))

      result = fun_K03_search_wavevector(configurations, k_range_rad_m=3800.0)

   .. rubric:: Choosing the Parameters

   - Segment length sets frequency resolution. Leakage from non-bin-aligned real signals can bias cross phase. Use window='hann' to reduce it, with matching PSD normalization.
   - Segment count sets the sample size of the phase histogram. Compare mode estimates as the count increases to assess stability for the chosen binning and noise level.
   - **Wavenumber bins.** The Beall range is always :math:`\pm\pi/|\boldsymbol{\chi}|`;
     neither widen nor narrow it.
   - Grid spacing is 2*k_range/(n_grid-1). Increase n_grid at fixed range and compare wavevector estimates to assess convergence.

   .. rubric:: Checking the results

   - Inspect candidate peaks using both baseline directions and lengths; see the geometry conditions in the foundations.
   - Use the segment-phase variance as the likelihood residual scale, and examine mode stability across sample counts.
   - Use circular residuals for folded wavenumbers; ordinary subtraction can produce
     nearly a full period of spurious error near a Nyquist edge.
   - Assess signal coherence where power stands above the noise floor. Out-of-band coherence
     checks the noise baseline; it does not establish a reliable propagation direction.
