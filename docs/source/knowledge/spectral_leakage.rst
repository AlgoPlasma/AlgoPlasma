Spectral Leakage and Windows
============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 谱泄漏：只有一个频率，为什么很多频点都有值？

   先读 :doc:`FFT 与频点 <fft>` 可以了解频点间隔的来源。
   本页只用无噪声信号，帮助区分有限记录造成的谱扩散与真实的多频波动。
   读完可 :ref:`返回探针诊断第 5 节 <foundations-zh-after-leakage>`。

   .. _knowledge-leakage-zh-record:

   .. rubric:: 1. 从截取、拼接到频谱和相位

   先看一条没有噪声的余弦波。记录时长为 :math:`T`，共采样 64 点；
   一条记录恰好包含 2 个周期，另一条包含 1.25 个周期。
   **把截取的片段原样接到自己后面，接缝处会发生什么？**

   下图每行从左向右读。第一列画出保留的片段，第二列把它重复一遍，第三列再看它的频谱。
   上行的 2 个周期能够平滑衔接；下行的 1.25 个周期在接缝处重新回到起始值 +1，
   与原始余弦继续演化的灰色虚线分开了。

   .. figure:: ../tests/010_diagnostics/_generated/case_basic_checks/figures/spectral_leakage.png
      :alt: 两行分别展示 2 周期和 1.25 周期记录的截取、重复拼接和离散频谱，标出真实频率与相位读取点。
      :width: 100%

      (a–c) 完整的 2 周期记录；(d–f) 1.25 周期记录。波形上的小点是保存的样本，实线是对应余弦的解析示意。
      第二列的后半段重复同一片段，灰色虚线表示原始波的继续演化。
      第三列使用测试保存的 FFT 幅值：竖虚线标记真实频率，黑圈标记读取互相位的频点。

   这种拼接帮助理解 DFT 的周期延拓：延拓周期是整段记录的长度 :math:`T`。
   FFT 使用的离散频点，对应在 :math:`T` 内振荡 0、1、2、3……次的基函数。
   2 周期余弦正好匹配第 2 个频点；1.25 周期余弦没有一个恰好匹配的频点，
   需要多个频点共同表示，于是谱值分散到邻近和更远的频点，这就是本例的谱泄漏。
   **这些非零频点来自有限记录的表示，不意味着原始信号里多出了许多真实波。**

   接缝跳变是这个例子的直观表现。某些初相位可使接缝两侧数值相等，但仍存在导数不连续，
   因而不能只比较首尾两个值来判断泄漏。加窗的作用将在第 3 节继续说明。

   现在加入第二路余弦 :math:`y(t)=\cos(2\pi f t+0.8)`，第一路为
   :math:`x(t)=\cos(2\pi f t)`。两路都去均值并使用矩形窗，
   互谱 :math:`X_1X_2^*` 的参考相位为 −0.8 rad。
   测试从最接近真实频率的频点读相位：2 周期记录用第 2 点，1.25 周期记录用第 1 点。
   前者误差低于 :math:`10^{-12}` 度，后者约为 5.55°。
   **选第 1 点读数，是后续估计的选择；FFT 本身仍保留了其他频点上的分量。**
   这里的误差来自当前记录和读数方式，并不是所有非整周期信号都有固定的 5.55° 偏差。

   :ref:`查看对应的基础数值测试与通过条件 <basic-checks-zh-spectrum>`。

   .. rubric:: 2. 看频谱：泄漏不是多了许多真实波

   为了比较矩形窗和 Hann 窗，下面另取采样率32 kHz、256点的8 ms记录。
   1000 Hz对应8个周期，1062.5 Hz对应8.5个周期，频点间隔为125 Hz。
   这里换用更长的示例观察旁瓣；它与前面64点记录的数值不能直接混用。

   .. figure:: ../images/knowledge/leakage_spectra.png
      :width: 100%
      :alt: 整数频点余弦集中于一个谱峰，非整数频点余弦出现旁瓣，Hann 窗减轻远处旁瓣。

      蓝色：1000 Hz、矩形窗；橙色：1062.5 Hz、矩形窗；绿色：同一条 1062.5 Hz 信号加 Hann 窗。
      圆点为实际 DFT 频点，连线只帮助看趋势；深灰色点线标出真实的 1062.5 Hz。
      纵轴为经窗增益修正的单边振幅显示，采用对数刻度；这里只画普通正频率。
      蓝色的其他频点低于图的下限，不是数学上有小噪声底。

   橙色曲线在许多频点上有值，虽然输入没有噪声，也没有其他真实波。
   主峰周围集中的部分叫主瓣，向远处延伸的较小部分叫旁瓣。
   这与混叠不同：混叠是采样后不同真实频率不可区分；泄漏是有限长度记录使频谱扩展。
   本图两个频率都远低于 16 kHz 的时间 Nyquist 边界，泄漏仍会出现。

   .. rubric:: 3. 窗函数怎样缓解？有什么代价？

   只截取一段而不做额外加权，相当于使用矩形窗，段内 :math:`w[n]=1`。
   Hann 窗逐渐减小段边缘的权重，周期版本为

   .. math::

      w[n]=\frac12-\frac12\cos\left(\frac{2\pi n}{N}\right),\qquad
      X_w[m]=\sum_{n=0}^{N-1}w[n]x[n]e^{-i2\pi mn/N}.

   它让拼接更平缓，通常降低远处旁瓣，但主瓣会更宽。
   因此“减少泄漏”不等于“让所有峰都更窄”或“提高所有场景的频率分辨率”。
   加窗也改变了振幅：本图用 :math:`2|X_w|/\sum_n w[n]` 修正窗的相干增益，
   但频率落在两格之间造成的峰值偏差仍然存在。这是振幅显示；功率谱密度要使用相应的窗能量归一化，
   不能照搬这个分母。

   .. literalinclude:: ../images/knowledge/plot_signal_notes.py
      :language: python
      :start-after: # leakage-example-start
      :end-before: # leakage-example-end
      :dedent: 4

   代码沿用 FFT 页的 ``t``、``N``。橙色和绿色曲线使用完全相同的 ``x_off``，
   改变的只是分析权重，并没有给信号添加或删除真实波。
   窗的效果与归一化可进一步参照
   `SciPy 的谱分析教程 <https://docs.scipy.org/doc/scipy/tutorial/signal.html#spectral-analysis>`_。

   .. rubric:: 4. 回到实际数据，应记住什么？

   - 增加真实记录长度会缩小 :math:`\Delta f=f_s/N`，但不保证未知信号正好成为整数周期。
   - 补零只把同一有限记录的频谱画得更密，不会增加观测时间，也不能消除泄漏。
   - 加窗需要同时考虑旁瓣、主瓣和归一化，不宜只看图上的峰是否漂亮。
   - 当前 K01 默认使用矩形窗，可选择 ``window='hann'``；FFT 与功率谱函数须传入相同窗口。
     K01 的 Hann 窗为对称的 ``numpy.hanning``，与上面示意的周期 Hann 定义不同；功率谱按窗口平方和归一化。

   :ref:`返回探针诊断第 5 节：继续读相干度 <foundations-zh-after-leakage>` ·
   :doc:`回顾 FFT <fft>` · :doc:`知识点目录 <index>`

.. container:: ap-lang ap-lang-en

   .. rubric:: Spectral leakage: why does one tone occupy many bins?

   Read :doc:`FFT and frequency bins <fft>` for bin spacing. This note uses noiseless signals
   to distinguish finite-record spreading from genuinely multiple components.
   Afterwards, :ref:`return to probe diagnostics section 5 <foundations-en-after-leakage>`.

   .. _knowledge-leakage-en-record:

   .. rubric:: 1. From cropping and repetition to spectra and phase

   Consider a noiseless cosine sampled at 64 points over a duration :math:`T`. One record contains
   exactly 2 cycles, the other 1.25 cycles. **What happens at the join if the saved segment is
   repeated immediately after itself?**

   Read each row below from left to right: the retained segment, its periodic repetition, and its
   spectrum. The 2-cycle record joins smoothly. The 1.25-cycle record restarts at +1, separating
   from the grey dashed continuation of the original cosine.

   .. figure:: ../tests/010_diagnostics/_generated/case_basic_checks/figures/spectral_leakage.png
      :alt: Two rows trace 2-cycle and 1.25-cycle records from cropping through periodic repetition to FFT bins and phase readout.
      :width: 100%

      (a–c) Two complete cycles; (d–f) 1.25 cycles. Small waveform dots are saved samples; solid
      curves are analytic guides for the corresponding cosine. The second column repeats the record;
      dashed grey curves continue the original wave. The third column uses saved FFT magnitudes,
      with the true frequency marked by a dashed line and the phase-readout bin circled in black.

   Repetition illustrates the DFT's periodic extension with period :math:`T`. Its discrete bins
   correspond to basis functions completing 0, 1, 2, 3, … cycles within that interval. A 2-cycle
   cosine matches bin 2. No single bin matches 1.25 cycles, so several bins must contribute to its
   representation: the spectral values spread. **The extra nonzero bins do not imply that many
   physical waves have appeared in the original signal.**

   A jump is the visible symptom in this example. Some initial phases can give equal endpoint values
   while leaving a derivative discontinuity, so comparing endpoint values alone is insufficient.
   Section 3 below explains the effect of windowing.

   Now add a second cosine :math:`y(t)=\cos(2\pi f t+0.8)` to compare with
   :math:`x(t)=\cos(2\pi f t)`. Both records are demeaned and use a boxcar window.
   The reference phase of :math:`X_1X_2^*` is −0.8 rad. The test reads phase at the nearest bin:
   bin 2 for two cycles, bin 1 for 1.25 cycles. Their errors are below :math:`10^{-12}` degrees
   and about 5.55°, respectively. **Reading bin 1 is an estimator choice; the FFT still retains
   the other frequency components.** The 5.55° bias is specific to this construction.

   :ref:`Check the numerical test and its comparison criteria <basic-checks-en-spectrum>`.

   .. rubric:: 2. Read the spectrum: leakage does not create many physical waves

   To compare boxcar and Hann windows, now use a separate 256-sample record at 32 kHz,
   lasting 8 ms. A 1000 Hz tone completes 8 cycles; 1062.5 Hz completes 8.5 cycles,
   with bin spacing 125 Hz. This longer example illustrates sidelobes; its numerical
   values should not be mixed with the preceding 64-sample test.

   .. figure:: ../images/knowledge/leakage_spectra.png
      :width: 100%
      :alt: A bin-aligned cosine has one peak; an off-bin cosine has sidelobes reduced at long range by a Hann window.

      Blue: 1000 Hz with a rectangular window. Orange: 1062.5 Hz with a rectangular window.
      Green: the same 1062.5 Hz record with a Hann window. Dots are DFT bins; connecting lines
      guide the eye. The dark grey dotted line marks the true 1062.5 Hz. The logarithmic vertical
      axis displays amplitudes corrected for window gain, at ordinary positive bins only.
      Other blue bins fall below the plot floor; that floor is not actual noise.

   Orange values populate many bins although the input has neither noise nor additional
   waves. The concentrated central part is the main lobe; smaller distant contributions
   are sidelobes. Aliasing makes distinct true frequencies indistinguishable after sampling;
   leakage spreads a finite record's spectrum. Both tones are far below the temporal
   Nyquist boundary of 16 kHz, yet leakage occurs.

   .. rubric:: 3. How does a window help, and what does it cost?

   Cutting out a segment without extra weighting is a rectangular window, :math:`w[n]=1`
   inside the segment. The periodic Hann window reduces the weights near its edges:

   .. math::

      w[n]=\frac12-\frac12\cos\left(\frac{2\pi n}{N}\right),\qquad
      X_w[m]=\sum_{n=0}^{N-1}w[n]x[n]e^{-i2\pi mn/N}.

   Smoother joins generally reduce distant sidelobes but broaden the main lobe. Reducing
   leakage does not make every peak narrower or improve resolution in every situation.
   Windowing also changes amplitude. The plot uses :math:`2|X_w|/\sum_n w[n]` to correct
   coherent gain, but peak bias from being between bins remains. This is an amplitude
   display; power spectral density needs the appropriate window-energy normalization instead.

   .. literalinclude:: ../images/knowledge/plot_signal_notes.py
      :language: python
      :start-after: # leakage-example-start
      :end-before: # leakage-example-end
      :dedent: 4

   The code reuses ``t`` and ``N`` from the FFT page. Orange and green use exactly the same
   ``x_off``. Only analysis weights change; no physical components are added or removed.
   For window effects and normalization see the
   `SciPy spectral analysis tutorial <https://docs.scipy.org/doc/scipy/tutorial/signal.html#spectral-analysis>`_.

   .. rubric:: 4. What should you remember for real records?

   - A longer actual record reduces :math:`\Delta f=f_s/N` but does not guarantee integer cycles.
   - Zero padding samples the same finite-record spectrum more densely; it adds no observation
     time and does not remove leakage.
   - Consider sidelobes, main-lobe width, and normalization together when choosing a window.
   - K01 defaults to a boxcar window and supports ``window='hann'``; use the same window
     in the FFT and PSD routines. K01 uses symmetric ``numpy.hanning``, unlike the periodic
     Hann definition illustrated above, and normalizes PSD by the sum of squared window weights.

   :ref:`Return to probe diagnostics section 5: coherence <foundations-en-after-leakage>` ·
   :doc:`Review FFT <fft>` · :doc:`Knowledge index <index>`
