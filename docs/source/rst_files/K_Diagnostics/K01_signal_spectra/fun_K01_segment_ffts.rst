-----------------------
fun_K01_segment_ffts.py
-----------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   新增可选参数 window='boxcar'；hann 对应对称 numpy.hanning 窗，要求至少三个样本。

   .. rubric:: 直接用途

   把一路探针记录切成不重叠的分段，逐段去均值后做实数 FFT。

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
      * - ``signal``
        - ``in``
        - ``(n,)``
        - 实探针记录；末尾不足一段的数据被丢弃。
        - 调用者归一化下的信号单位
        - 一维时间序列，样本按时间顺序排列。
      * - ``nperseg``
        - ``in``
        - ``scalar``
        - 每段采样点数。
        - 样本数，无量纲
        - 决定频率分辨率 ``fs/nperseg``。
      * - ``n_segments``
        - ``in``
        - ``scalar``，可选
        - 最多取这么多段；默认用完所有完整分段。
        - 段数，无量纲
        - 沿分段轴截断。
      * - ``detrend``
        - ``in``
        - ``scalar``，可选
        - 变换前逐段去均值，默认为真。
        - 布尔
        - 沿每段的时间轴作用。

   .. rubric:: 返回值

   ``numpy.ndarray``，复数，shape ``(n_segments, nperseg//2+1)``；轴 0 为分段，轴 1 为频点。

   .. rubric:: 局部假设 / 前置条件

   - 分段不重叠，但不重叠不保证统计独立。相关性会影响有效样本量与众数估计的稳定性；当前返回的是单样本相位方差，不能仅由分段重叠断言 K03 权重必然偏大。
   - window 可选 boxcar（默认）或 hann（numpy.hanning）；去均值后乘窗。Hann 窗降低频谱旁瓣，同时使主瓣变宽。

   .. rubric:: 实现逻辑

   - 把记录 reshape 成 ``(nseg, nperseg)`` 后沿轴 1 一次性做 ``numpy.fft.rfft``。
   - 去均值在 reshape 之后逐段进行，因此各段的直流分量独立扣除。

   .. rubric:: 调用注意

   - 调用方需保证两路探针用同一 ``nperseg`` 和同一段数，否则 ``fun_K01_cross_phase`` 会因 shape 不一致而报错。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   Optional window='boxcar'; hann uses symmetric numpy.hanning and requires at least three samples.

   .. rubric:: Direct Purpose

   Split one probe record into non-overlapping segments and take the real FFT of each.

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
      * - ``signal``
        - ``in``
        - ``(n,)``
        - Real probe record; a trailing partial segment is discarded.
        - Signal units under the caller's normalisation
        - One-dimensional time series in sample order.
      * - ``nperseg``
        - ``in``
        - ``scalar``
        - Samples per segment.
        - Sample count, dimensionless
        - Sets the frequency resolution ``fs/nperseg``.
      * - ``n_segments``
        - ``in``
        - ``scalar``, optional
        - Stop after this many segments; the default uses every complete segment.
        - Segment count, dimensionless
        - Truncates along the segment axis.
      * - ``detrend``
        - ``in``
        - ``scalar``, optional
        - Remove the mean of each segment before transforming. Default true.
        - Boolean
        - Acts along the time axis of each segment.

   .. rubric:: Return Value

   ``numpy.ndarray``, complex, shape ``(n_segments, nperseg//2+1)``; axis 0 is the segment, axis 1 the frequency bin.

   .. rubric:: Local Assumptions and Preconditions

   - Segments do not overlap, but non-overlap does not guarantee independence. Correlation affects effective sample size and mode stability. The returned variance describes individual phase samples; overlap alone does not establish that K03 weights are inflated.
   - window accepts boxcar (default) or hann (numpy.hanning); detrending precedes windowing. Hann reduces spectral sidelobes and broadens the main lobe.

   .. rubric:: Implementation Notes

   - The record is reshaped to ``(nseg, nperseg)`` and transformed with a single ``numpy.fft.rfft`` along axis 1.
   - Detrending happens after the reshape, so each segment loses its own mean.

   .. rubric:: Calling Notes

   - The caller must use the same ``nperseg`` and segment count for both probes, or ``fun_K01_cross_phase`` will reject the mismatched shapes.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
