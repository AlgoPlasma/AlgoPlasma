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

   .. rubric:: 1. 在频点上，就是在这一段里转了整数圈

   固定 :math:`f_s=32000\ \mathrm{Hz}`、:math:`N=256`，段时长为 8 ms，
   频点间隔为 125 Hz。对比两条振幅为 1 的余弦波：

   - 1000 Hz 在一段里经历 8 个周期，正好是第 8 个频点。
   - 1062.5 Hz 在一段里经历 8.5 个周期，处在 1000 和 1125 Hz 两个频点之间。

   它们各自都只有一个真实频率。第二种情况下，DFT 的任何单个频点都不能完整表示这段数据，
   必须用多个频点共同表示；本来期望集中在一个峰上的谱值因此分散，这叫 **谱泄漏**。

   .. figure:: ../images/knowledge/leakage_repeated_record.png
      :width: 100%
      :alt: 8 周期记录重复后平滑衔接，8.5 周期余弦记录重复后在 8 ms 接缝出现跳跃。

      把同一段 8 ms 记录复制两遍，深灰色虚线标出拼接处。
      上图 8 个周期可以平滑拼接；下图 8.5 个周期在这个余弦例子中从 −1 跳回 +1。
      第二段画的是第一段的重复，不是原始无限长波在后半段的继续演化。

   周期拼接是理解 DFT 基函数的一种办法，不意味着程序真的复制了数据。
   非整数周期通常在接缝出现数值或导数的不连续，因此需要更多频率来表示。
   “首尾数值不相等”只是本例最直观的表现；某些初相位可以让首尾值相等，
   但仍不满足整数周期条件，不能仅靠首尾两个值判断是否泄漏。

   .. rubric:: 2. 看频谱：泄漏不是多了许多真实波

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
   - 当前 K01 分段函数不自动加窗，功率谱函数也不补偿窗；本页是知识解释，不改变算法行为。

   :ref:`返回探针诊断第 5 节：继续读相干度 <foundations-zh-after-leakage>` ·
   :doc:`回顾 FFT <fft>` · :doc:`知识点目录 <index>`

.. container:: ap-lang ap-lang-en

   .. rubric:: Spectral leakage: why does one tone occupy many bins?

   Read :doc:`FFT and frequency bins <fft>` for bin spacing. This note uses noiseless signals
   to distinguish finite-record spreading from genuinely multiple components.
   Afterwards, :ref:`return to probe diagnostics section 5 <foundations-en-after-leakage>`.

   .. rubric:: 1. Bin alignment means an integer number of cycles in the segment

   Fix :math:`f_s=32000\ \mathrm{Hz}` and :math:`N=256`: an 8 ms segment and 125 Hz bins.
   Compare two unit-amplitude cosines:

   - 1000 Hz completes 8 cycles and lies exactly on bin 8.
   - 1062.5 Hz completes 8.5 cycles, halfway between 1000 and 1125 Hz.

   Each has just one true frequency. No single DFT bin can represent the second record;
   several bins must contribute. Spectral strength spreads away from the expected single
   peak: this is **spectral leakage**.

   .. figure:: ../images/knowledge/leakage_repeated_record.png
      :width: 100%
      :alt: Repeating an eight-cycle record joins smoothly; an 8.5-cycle cosine record jumps at the join.

      Repeat the same 8 ms record twice; the dark grey dashed line marks the join. The eight-cycle
      trace joins smoothly. The 8.5-cycle cosine jumps from −1 to +1 in this example.
      The second segment repeats the first; it is not the continuation of the original wave.

   Periodic repetition is a way to understand the DFT basis, not a claim that the program
   copies data. Non-integer cycles generally create a discontinuity in value or derivatives
   at the join, requiring more frequencies. Unequal endpoint values are only the most
   visible symptom here. Some initial phases give equal endpoint values but still have
   off-bin frequencies; checking two endpoint values alone is insufficient.

   .. rubric:: 2. Read the spectrum: leakage does not create many physical waves

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
   - Current K01 segmentation applies no extra window and its power routine makes no window
     correction. This conceptual note changes no algorithm behaviour.

   :ref:`Return to probe diagnostics section 5: coherence <foundations-en-after-leakage>` ·
   :doc:`Review FFT <fft>` · :doc:`Knowledge index <index>`
