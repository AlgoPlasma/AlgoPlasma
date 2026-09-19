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
   哪些 routine、调用方必须自己负责什么、以及哪些参数一旦选错会安静地给出错误结果。

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
      * - 多个不同**长度**的间距
        - 每个频点的二维波矢
        - K01 → K03
      * - 同一份数据
        - 混叠与解混叠的对照
        - K01 → K02 与 K03 各走一遍

   .. rubric:: 调用方必须负责的事情

   - **读数据**。三个单元都不做任何文件读写，原始记录从哪来、怎么对齐时间由调用方决定。
   - **探针顺序**。间距定义为 :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`，传给
     ``fun_K01_cross_phase`` 的第二个参数必须是位于 :math:`+\boldsymbol{\chi}` 的那一路。
     搞反会让所有结果镜像而不报错。
   - **单位自洽**。间距用米、波数用 rad/m、频率用 Hz。模块不做任何单位换算。
   - **加窗**。内容在分段长度上不周期时需自行加窗；``fun_K01_segment_ffts`` 不加窗。
   - **搜索范围**。``k_range`` 必须包含真实波矢。峰位落在网格边界即说明范围过窄。

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

   - **分段长度 nperseg**。决定频率分辨率 :math:`f_s/n`。模态应尽量落在 bin 上；偏离 bin 只影响
     该 bin 内的功率，不影响**互**相位，因为泄漏因子对两路探针相同、在互谱里约掉。
   - **分段数**。K03 只需给出稳定的均值相位，十几段通常够；K02 是直方图估计器，分段数应显著多于
     波数格数，否则谱峰只是最强的单个样本。
   - **波数格数**。Beall 的波数范围恒为 :math:`\pm\pi/|\boldsymbol{\chi}|`，不要设得更宽或更窄。
   - **粗网格步长**。两级搜索的粗搜只需选对条纹。条纹周期
     :math:`2\pi/|\boldsymbol{\chi}|` 随间距增大而减小，因此最长间距产生最小周期并给出
     最严格的限制；粗网格步长必须显著小于该周期。

   .. rubric:: 常见集成错误

   - 只用一种间距长度就期待解开混叠。
   - 把 K01 返回的单样本方差当成均值方差；各构型分段数不同时应按 :math:`\sigma^2/n` 加权。
   - 用直接相减比较两个折叠波数，在 Nyquist 边附近得到整整一个周期的假误差。
   - 在谱已沉入噪声底的频段上评估相干度判据。

.. container:: ap-lang ap-lang-en

   .. rubric:: What This Page Is For

   This page is for a reader who already understands aliasing and wants to wire
   ``K_Diagnostics`` into their own analysis. It states the order in which to call the routines,
   what the caller must own, and which parameter choices fail silently.

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
      * - Several separation **lengths**
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
   - **Windowing.** Content that is not periodic in the segment length needs a window from the
     caller; ``fun_K01_segment_ffts`` applies none.
   - **Search range.** ``k_range`` must contain the true wavevector; a peak on the grid boundary
     means it does not.

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

   - **Segment length nperseg.** Sets the frequency resolution :math:`f_s/n`. Modes should sit
     on bins where possible; being off-bin affects only the in-bin power, not the **cross**
     phase, because the leakage factor is common to both probes and cancels in the cross
     spectrum.
   - **Segment count.** K03 only needs a stable mean phase, for which a dozen or so segments
     usually suffice; K02 is a histogram estimator and needs far more segments than wavenumber
     bins, or its peak is only the strongest single sample.
   - **Wavenumber bins.** The Beall range is always :math:`\pm\pi/|\boldsymbol{\chi}|`;
     neither widen nor narrow it.
   - **Coarse grid step.** In the two-stage search the coarse stage only has to pick the right
     fringe. Since the fringe period :math:`2\pi/|\boldsymbol{\chi}|` decreases as the
     separation grows, the longest separation sets the smallest period and the strictest
     limit; keep the coarse-grid step well below that period.

   .. rubric:: Common Integration Mistakes

   - Expecting to break the aliasing with a single separation length.
   - Treating the single-sample variance K01 returns as the variance of the mean; unequal
     segment counts should be weighted by :math:`\sigma^2/n`.
   - Comparing two folded wavenumbers with a plain difference and reading a full period of
     spurious error near a Nyquist edge.
   - Evaluating a coherence criterion on bins where the spectrum has already sunk into the
     noise floor.
