--------------------------
fun_K02_peak_wavenumber.py
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   只比较有限正功率；没有有效功率的频段返回 NaN。

   .. rubric:: 直接用途

   取每个频点上 Beall 谱的峰位波数。

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
      * - ``spectrum``
        - ``in``
        - ``(nf, nk)``
        - 来自 ``fun_K02_beall_spectrum`` 的谱。
        - 累积权重的单位
        - 轴 0 为频点，轴 1 为波数格。
      * - ``k_centers``
        - ``in``
        - ``(nk,)``
        - 波数格中心。
        - rad/m
        - 与 ``spectrum`` 的轴 1 一一对应。

   .. rubric:: 返回值

   ``numpy.ndarray``，shape ``(nf,)``；行功率和为零的频点返回 ``nan``。

   .. rubric:: 局部假设 / 前置条件

   - 取的是直方图最大值，即有限样本下的众数。其散布由相位统计和分段数决定，**不等于格宽**。

   .. rubric:: 实现逻辑

   - 沿波数轴取 ``argmax``，再用行功率和判断该频点是否有功率。

   .. rubric:: 调用注意

   - 分段数不足时它退化为最强的单个样本；需要更稳的读数应增加分段数或改用矩估计。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   Only finite positive power is compared; empty/invalid rows return NaN.

   .. rubric:: Direct Purpose

   Return the peak wavenumber of a Beall spectrum at each frequency.

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
      * - ``spectrum``
        - ``in``
        - ``(nf, nk)``
        - Spectrum from ``fun_K02_beall_spectrum``.
        - Units of the accumulation weight
        - Axis 0 is the frequency, axis 1 the wavenumber bin.
      * - ``k_centers``
        - ``in``
        - ``(nk,)``
        - Wavenumber bin centres.
        - rad/m
        - One-to-one with axis 1 of ``spectrum``.

   .. rubric:: Return Value

   ``numpy.ndarray``, shape ``(nf,)``; frequencies whose row sums to zero return ``nan``.

   .. rubric:: Local Assumptions and Preconditions

   - This is the histogram maximum, a finite-sample mode. Its scatter is set by the phase statistics and the segment count, **not** by the bin width.

   .. rubric:: Implementation Notes

   - ``argmax`` along the wavenumber axis, with the row sum used to decide whether a frequency received power at all.

   .. rubric:: Calling Notes

   - With too few segments it degenerates into the strongest single sample; a steadier reading needs more segments or a moment estimate.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
