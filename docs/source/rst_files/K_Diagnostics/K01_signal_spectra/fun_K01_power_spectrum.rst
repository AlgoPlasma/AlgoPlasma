-------------------------
fun_K01_power_spectrum.py
-------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   新增参数 window='boxcar'，或与 FFT 一致的 'hann'；要求非空完整 rFFT 和正采样率。

   .. rubric:: 直接用途

   给出一路探针的分段平均单边功率谱密度。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 14 10 28 34 26 40

      * - 参数
        - 方向
        - shape / 范围
        - 含义
        - 单位 / 归一化
        - 索引 / 轴约定
      * - ``ffts``
        - ``in``
        - ``(nseg, nfreq)`` 复数
        - 来自 ``fun_K01_segment_ffts`` 的分段谱。
        - 调用者归一化下的信号单位
        - 轴 0 为分段，轴 1 为频点。
      * - ``sampling_rate_hz``
        - ``in``
        - ``scalar``
        - 采样率。
        - Hz
        - 标量，不涉及索引。
      * - ``nperseg``
        - ``in``
        - ``scalar``
        - 生成 ``ffts`` 时用的分段长度。
        - 样本数，无量纲
        - 用于还原谱的归一化因子。

   .. rubric:: 返回值

   ``numpy.ndarray``，shape ``(nfreq,)``，单位为 signal² 每 Hz。

   .. rubric:: 局部假设 / 前置条件

   - 单边约定：除直流外每个频点乘 2；``nperseg`` 为偶数时 Nyquist 频点同样不乘。
   - 窗口须与 segment_ffts 的 window 参数一致：boxcar（默认）或 hann。

   .. rubric:: 实现逻辑

   - 先沿分段轴取 :math:`\langle|X|^2\rangle`，再除以 ``fs*sum(window**2)``，最后施加单边因子。

   .. rubric:: 调用注意

   - 去均值后直流分量约为零，取对数坐标作图时应显式设置纵轴下限，否则该点会把坐标轴拉低数十个数量级。

   .. rubric:: 算法说明

   .. math::

      S(f) = \frac{\alpha}{f_s\sum_n w_n^2}\left\langle |X(f)|^2 \right\rangle,\qquad
      \alpha = \begin{cases} 1 & \text{直流与 Nyquist} \\ 2 & \text{其余频点} \end{cases}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   Optional window='boxcar', or 'hann' matching the FFT; requires complete nonempty rFFT arrays and positive sampling rate.

   .. rubric:: Direct Purpose

   Return the segment-averaged one-sided power spectral density of one probe.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 14 10 28 34 26 40

      * - Parameter
        - Direction
        - Shape / range
        - Meaning
        - Units / normalisation
        - Indexing / axis convention
      * - ``ffts``
        - ``in``
        - ``(nseg, nfreq)`` complex
        - Segment spectra from ``fun_K01_segment_ffts``.
        - Signal units under the caller's normalisation
        - Axis 0 is the segment, axis 1 the frequency bin.
      * - ``sampling_rate_hz``
        - ``in``
        - ``scalar``
        - Sampling rate.
        - Hz
        - Scalar; no indexing.
      * - ``nperseg``
        - ``in``
        - ``scalar``
        - Segment length used to produce ``ffts``.
        - Sample count, dimensionless
        - Restores the spectral normalisation.

   .. rubric:: Return Value

   ``numpy.ndarray``, shape ``(nfreq,)``, in signal^2 per Hz.

   .. rubric:: Local Assumptions and Preconditions

   - One-sided convention: every bin is doubled except DC and, for even ``nperseg``, the Nyquist bin.
   - The window argument must match segment_ffts: boxcar (default) or hann.

   .. rubric:: Implementation Notes

   - :math:`\langle|X|^2\rangle` is taken along the segment axis, divided by ``fs*sum(window**2)``, then given the one-sided factor.

   .. rubric:: Calling Notes

   - After detrending the DC bin is essentially zero, so a logarithmic axis needs an explicit lower limit or that single point drags the axis down by tens of decades.

   .. rubric:: Algorithm Notes

   .. math::

      S(f) = \frac{\alpha}{f_s\sum_n w_n^2}\left\langle |X(f)|^2 \right\rangle,\qquad
      \alpha = \begin{cases} 1 & \text{DC and Nyquist} \\ 2 & \text{otherwise} \end{cases}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
