FFT, Frequency Bins, and Nyquist
========================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: FFT：把一段波形变成各频率的振幅与相位

   这是全库共用的知识点。FFT（Fast Fourier Transform，快速傅里叶变换）是计算
   DFT（离散傅里叶变换）的快速方法；它们描述同一项变换，不是两种不同的物理分析。
   Nyquist（奈奎斯特）频率是采样率的一半，它给出通常无混叠频带的边界，下面用采样图解释。

   来自探针诊断页？读完可 :ref:`返回第 4 节继续读功率谱 <foundations-zh-after-fft>`。

   .. rubric:: 1. 先看图：一个复杂波形可以由几个简单波相加

   取一个单位为任意信号单位的例子：

   .. math::

      x(t)=\cos(2\pi\,1000t)+0.5\cos(2\pi\,3000t+\pi/3).

   两个成分的频率分别为 1 和 3 kHz，振幅分别为 1 和 0.5。
   为了在图中看清相位，这里特意给 3 kHz 成分设置 :math:`\pi/3` 的初相位；
   探针诊断页的双频示例仍使用它原来的初相位。

   .. figure:: ../images/knowledge/fft_amplitude_phase.png
      :width: 100%
      :alt: 两个正弦成分相加得到时域记录，FFT 分离出两个谱峰和对应复数向量。

      左上：两个成分；右上：相加后的信号与采样点，绘出前 2 ms。
      左下：用完整 8 ms 记录计算的单边振幅谱，两个峰分别为 1 和 0.5。
      右下：相应的复数系数乘以 2/N 后画成箭头，长度给出振幅，角度给出相位。
      图中的 Re、Im 分别表示实部和虚部。

   时域图问“每个时刻的数值是什么”，频域图问“每个频率的成分有多强、相位是多少”。
   FFT 并不只保留峰的位置，还保留一组复数。
   用 :math:`z=R(\cos\phi+i\sin\phi)=Re^{i\phi}` 表示一个复数，
   其中 :math:`i^2=-1`，长度 :math:`R=|z|` 与角度 :math:`\phi=\arg z` 就能同时装下这两个信息。

   .. rubric:: 2. 频点是什么？为什么间隔为 fs/N？

   采样率 :math:`f_s` 的单位是 Hz，即每秒取得的样本数。一段有 :math:`N` 个样本，
   时刻为 :math:`t_n=n/f_s`，:math:`n=0,\ldots,N-1`。
   DFT 把这 N 个数看作一段长度为 :math:`T_{\rm seg}=N/f_s` 的周期记录；
   最后一个实际样本在 :math:`(N-1)/f_s`，不再重复采集段终点。
   在这段时间内正好转 m 圈的频率是

   .. math::

      f_m=\frac{m}{T_{\rm seg}}=\frac{mf_s}{N},\qquad
      \Delta f=\frac{f_s}{N}.

   这些用于比较的离散频率叫作 **频点**，:math:`m` 是频点序号。
   它不是说真实波只能有这些频率，而是说一次 DFT 在这些频率上给出系数。
   本例 :math:`f_s=32000\ \mathrm{Hz}`、:math:`N=256`，因此
   :math:`T_{\rm seg}=8\ \mathrm{ms}`、:math:`\Delta f=125\ \mathrm{Hz}`。
   1 kHz 对应 :math:`m=8`，3 kHz 对应 :math:`m=24`。

   .. rubric:: 3. 求和为什么能取出振幅和相位？

   NumPy 默认的正变换是

   .. math::

      X[m]=\sum_{n=0}^{N-1}x[n]\exp\!\left(-i\frac{2\pi mn}{N}\right).

   先用一个以候选频率反向旋转的复数乘每个样本，再相加。
   如果信号正好含有这个频率，对应项在相乘后停止旋转，因而反复累加；
   其他整数频点的项在一圈圈旋转中相互抵消。这里比较的是整段数据，不是某一个峰。

   具体地，若 :math:`x[n]=A\cos(2\pi mn/N+\phi)`，利用
   :math:`\cos\alpha=(e^{i\alpha}+e^{-i\alpha})/2` 得到

   .. math::

      X[m]=\frac A2\sum_{n=0}^{N-1}
      \left[e^{i\phi}+e^{-i(4\pi mn/N+\phi)}\right]
      =\frac{NA}{2}e^{i\phi}.

   第一项加了 N 次；第二项在普通正频率点上恰好抵消。因此
   :math:`A=2|X[m]|/N`、:math:`\phi=\arg X[m]`。
   这个简单结果要求频率恰好在频点上，并且不是直流（0 Hz）或 Nyquist 端点。
   未加窗是这里采用的条件。若不满足整数周期条件，请读 :doc:`谱泄漏 <spectral_leakage>`。
   谱值接近零时，计算出的相角通常也没有可靠的物理意义。

   探针页写作 :math:`X_j[m]` 时，额外的 :math:`j` 只是区分第 1、2 路信号；
   每一路都独立执行同一项变换。定义和正负号采用
   `NumPy 官方 FFT 约定 <https://numpy.org/doc/stable/reference/routines.fft.html>`_。

   .. rubric:: 4. Nyquist 频率限制了什么？

   **Nyquist 频率** 定义为 :math:`f_{\rm Nyq}=f_s/2`，对应每周期两个样本。
   若想由均匀采样唯一恢复一个一般的带限信号，需要其频率成分严格低于这个边界，
   并排除采样前的带外成分。边界本身是特殊点，不能简单理解为“两点就足够恢复任意相位”。

   .. figure:: ../images/knowledge/nyquist_samples.png
      :width: 100%
      :alt: 8 Hz 采样下，3 Hz 与 5 Hz 的余弦波通过完全相同的离散样本。

      为看清采样点，这张图另用 fs=8 Hz，因此 Nyquist 频率是 4 Hz。
      蓝色 3 Hz 波和橙色 5 Hz 波在连续时间中不同，却经过完全相同的黑色采样点。
      只保留这些样本，就分不清它们；5 Hz 折到了 3 Hz，这叫时间混叠。

   本页的 32 kHz 采样对应 16 kHz 的 Nyquist 频率，所以 1 和 3 kHz 都在时间采样允许的范围内。
   时间 Nyquist 的单位是 Hz；探针间距决定的空间 Nyquist 波数单位是 rad/m，二者不是同一个量。

   .. rubric:: 5. 为什么 rfft 可以不返回负频率？

   实数记录的系数满足共轭对称关系 :math:`X[N-m]=X[m]^*`，这里的
   :math:`N-m` 位置代表相应的负频率。共轭就是把复数的虚部变号；
   负频率部分可以从正频率部分算回来，所以 ``rfft`` 只存非负频率。
   偶数 N 时结果有 :math:`N/2+1` 项，含 0 Hz 和 :math:`f_s/2`；
   奇数 N 时最高频点略低于 :math:`f_s/2`。

   直流和偶数 N 的 Nyquist 点没有另一项独立的负频率伙伴，不能像普通正频率那样乘 2。
   在 Nyquist 点，:math:`\cos(\pi n+\phi)=(-1)^n\cos\phi`，
   因而采样不能独立保留这个波的全部振幅与相位信息。

   下面就是生成第一张图的计算代码。``amplitude`` 为单边振幅显示，``phase`` 单位为 rad；
   它不是功率谱密度，不能混用归一化。

   .. literalinclude:: ../images/knowledge/plot_signal_notes.py
      :language: python
      :start-after: # fft-example-start
      :end-before: # fft-example-end
      :dedent: 4

   本例两个有信号的频点返回振幅 1、0.5，以及相位 0、π/3。
   :ref:`返回探针诊断第 4 节：继续读功率谱 <foundations-zh-after-fft>` ·
   :doc:`继续了解谱泄漏 <spectral_leakage>` · :doc:`知识点目录 <index>`

.. container:: ap-lang ap-lang-en

   .. rubric:: FFT: turn a finite record into amplitudes and phases

   This note is shared across the library. The FFT (Fast Fourier Transform) efficiently
   computes the DFT (Discrete Fourier Transform); these are not different physical analyses.
   The Nyquist frequency is half the sampling rate, the boundary of the usual unaliased band.
   A sampling diagram below explains it.

   Arriving from probe diagnostics? Afterwards, :ref:`return to section 4 and power spectra <foundations-en-after-fft>`.

   .. rubric:: 1. Start with the pictures: add simple components to make a complicated trace

   In arbitrary signal units, choose

   .. math::

      x(t)=\cos(2\pi\,1000t)+0.5\cos(2\pi\,3000t+\pi/3).

   The components are at 1 and 3 kHz, with amplitudes 1 and 0.5. To make phase visible,
   this note gives the 3 kHz tone initial phase :math:`\pi/3`; the probe tutorial's example
   retains its original initial phase.

   .. figure:: ../images/knowledge/fft_amplitude_phase.png
      :width: 100%
      :alt: Two sinusoidal components, their sampled sum, amplitude peaks, and complex coefficient arrows.

      Top left: components. Top right: their sum and samples, showing the first 2 ms.
      Bottom left: one-sided amplitudes from the full 8 ms record, with peaks 1 and 0.5.
      Bottom right: arrows for coefficients multiplied by 2/N; length is amplitude and
      angle is phase. Re and Im mean real and imaginary parts.

   A time trace gives the value at each time; a spectrum gives the strength and phase at
   each frequency. The FFT retains complex coefficients, not just peak locations.
   A complex number :math:`z=R(\cos\phi+i\sin\phi)=Re^{i\phi}`, where :math:`i^2=-1`,
   stores both its length :math:`R=|z|` and its angle :math:`\phi=\arg z`.

   .. rubric:: 2. What are frequency bins, and why are they spaced by fs/N?

   Sampling rate :math:`f_s` is samples per second, in Hz. A segment contains :math:`N`
   values at :math:`t_n=n/f_s`, :math:`n=0,\ldots,N-1`. The DFT treats them as one period
   of a record lasting :math:`T_{\rm seg}=N/f_s`. The last actual sample is at
   :math:`(N-1)/f_s`; the endpoint is not sampled twice. A frequency completing exactly m
   cycles in this interval is

   .. math::

      f_m=\frac{m}{T_{\rm seg}}=\frac{mf_s}{N},\qquad
      \Delta f=\frac{f_s}{N}.

   These discrete comparison frequencies are **bins**, indexed by :math:`m`. Real waves
   need not have these frequencies; a DFT reports coefficients at these locations.
   Here :math:`f_s=32000\ \mathrm{Hz}` and :math:`N=256` give
   :math:`T_{\rm seg}=8\ \mathrm{ms}` and :math:`\Delta f=125\ \mathrm{Hz}`.
   The 1 and 3 kHz tones occupy bins 8 and 24.

   .. rubric:: 3. How does the sum recover amplitude and phase?

   NumPy's default forward transform is

   .. math::

      X[m]=\sum_{n=0}^{N-1}x[n]\exp\!\left(-i\frac{2\pi mn}{N}\right).

   Multiply samples by a complex reference rotating backwards at the candidate frequency,
   then add them. A matching component stops rotating and accumulates, while components at
   other integer bins cancel over complete turns. This compares the entire segment.

   For :math:`x[n]=A\cos(2\pi mn/N+\phi)`, expand
   :math:`\cos\alpha=(e^{i\alpha}+e^{-i\alpha})/2`:

   .. math::

      X[m]=\frac A2\sum_{n=0}^{N-1}
      \left[e^{i\phi}+e^{-i(4\pi mn/N+\phi)}\right]
      =\frac{NA}{2}e^{i\phi}.

   The first term accumulates N times; the second cancels at ordinary positive bins.
   Consequently :math:`A=2|X[m]|/N` and :math:`\phi=\arg X[m]`. This simple result assumes
   an unwindowed, bin-aligned tone away from DC (0 Hz) and the Nyquist endpoint.
   For non-integer cycles see :doc:`spectral leakage <spectral_leakage>`. The angle of a
   near-zero coefficient usually has no reliable physical interpretation.

   In the probe tutorial's :math:`X_j[m]`, the extra :math:`j` only identifies the signal;
   both probes independently use the same transform. Definitions and signs follow the
   `official NumPy FFT convention <https://numpy.org/doc/stable/reference/routines.fft.html>`_.

   .. rubric:: 4. What does the Nyquist frequency limit?

   The **Nyquist frequency** is :math:`f_{\rm Nyq}=f_s/2`, or two samples per cycle.
   Unique recovery of a general band-limited signal from uniform samples requires its
   components to lie strictly below this boundary and excludes out-of-band content before
   sampling. The boundary itself is special: two points do not recover arbitrary phase.

   .. figure:: ../images/knowledge/nyquist_samples.png
      :width: 100%
      :alt: Cosines at 3 and 5 Hz coincide at every sample taken at 8 Hz.

      To expose individual samples this separate illustration uses fs=8 Hz and Nyquist
      frequency 4 Hz. The blue 3 Hz and orange 5 Hz curves differ continuously but pass
      through the same black samples. Samples alone cannot distinguish them: 5 Hz aliases
      to 3 Hz. This is temporal aliasing.

   The main example's 32 kHz sampling has Nyquist frequency 16 kHz, so both 1 and 3 kHz lie
   within its temporal band. Temporal Nyquist frequency is in Hz; the spatial Nyquist
   wavenumber set by probe spacing is in rad/m. They are different quantities.

   .. rubric:: 5. Why can rfft omit negative frequencies?

   A real record obeys :math:`X[N-m]=X[m]^*`, where index :math:`N-m` represents the matching
   negative frequency. Conjugation reverses the imaginary part. Negative coefficients can
   therefore be reconstructed, so ``rfft`` stores only nonnegative frequencies. For even N
   there are :math:`N/2+1` entries including DC and :math:`f_s/2`; for odd N the highest bin
   is slightly below :math:`f_s/2`.

   DC and the even-N Nyquist bin have no separate negative-frequency partner and must not
   be doubled like ordinary positive bins. At Nyquist,
   :math:`\cos(\pi n+\phi)=(-1)^n\cos\phi`, so samples cannot independently retain all
   amplitude and phase information of that component.

   The following calculation generates the first figure. ``amplitude`` is a one-sided
   amplitude display and ``phase`` is in radians; this is not a power spectral density.

   .. literalinclude:: ../images/knowledge/plot_signal_notes.py
      :language: python
      :start-after: # fft-example-start
      :end-before: # fft-example-end
      :dedent: 4

   The populated bins return amplitudes 1 and 0.5 and phases 0 and π/3.
   :ref:`Return to probe diagnostics section 4: power spectra <foundations-en-after-fft>` ·
   :doc:`Continue to spectral leakage <spectral_leakage>` · :doc:`Knowledge index <index>`
