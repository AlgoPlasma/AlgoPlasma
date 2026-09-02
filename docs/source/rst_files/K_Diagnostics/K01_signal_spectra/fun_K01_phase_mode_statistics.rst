--------------------------------
fun_K01_phase_mode_statistics.py
--------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   给出折叠相位样本的众数参考均值与方差。

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
      * - ``phase``
        - ``in``
        - ``(nseg,)`` 或 ``(nseg, nfreq)``
        - 来自 ``fun_K01_cross_phase`` 的折叠相位。
        - 无量纲（弧度）
        - 轴 0 必须是分段轴；轴 1 若存在则为频点。
      * - ``nbins``
        - ``in``
        - ``scalar``，可选
        - 定位众数用的直方图格数，默认 60。
        - 格数，无量纲
        - 直方图张在 :math:`(-\pi, \pi]` 上。

   .. rubric:: 返回值

   两个 ``numpy.ndarray``：均值相位与方差。1-D 输入时为标量，2-D 输入时为 ``(nfreq,)``。

   .. rubric:: 局部假设 / 前置条件

   - 返回的是**单个样本**的方差而不是均值的方差。各构型分段数相同时这只是似然的整体常数因子，不影响峰位；分段数不同时调用方应自行按 :math:`\sigma^2/n` 加权。
   - 均值不再折回 :math:`(-\pi, \pi]`，众数贴近切割线时可能超出该区间不超过一格宽。
   - 至少需要两个分段才能给出方差。

   .. rubric:: 实现逻辑

   - 相位分布可能横跨 :math:`\pm\pi` 的分支切割线，此时算术平均会塌向零。
   - 先在直方图上定位众数，把切割线移到众数对面再平均；方差取 ``ddof=1`` 并加 :math:`10^{-12}` 的下限以防除零。

   .. rubric:: 调用注意

   - 直方图格宽给出一个量化下限；相位散布远小于一格时，均值的精度由格宽而非样本数决定。

   .. rubric:: 算法说明

   .. math::

      \bar\theta = \theta_{\rm mode}
      + \left\langle \mathrm{wrap}(\theta_i - \theta_{\rm mode}) \right\rangle,\qquad
      \sigma^2 = \mathrm{var}\!\left[\mathrm{wrap}(\theta_i-\theta_{\rm mode})\right]_{\rm ddof=1}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Return the mode-referenced mean and variance of wrapped phase samples.

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
      * - ``phase``
        - ``in``
        - ``(nseg,)`` or ``(nseg, nfreq)``
        - Wrapped phases from ``fun_K01_cross_phase``.
        - Dimensionless (radians)
        - Axis 0 must be the segment axis; axis 1, if present, is the frequency bin.
      * - ``nbins``
        - ``in``
        - ``scalar``, optional
        - Histogram bins used to locate the mode. Default 60.
        - Bin count, dimensionless
        - The histogram spans :math:`(-\pi, \pi]`.

   .. rubric:: Return Value

   Two ``numpy.ndarray``: the mean phase and the variance; scalar for 1-D input and ``(nfreq,)`` for 2-D input.

   .. rubric:: Local Assumptions and Preconditions

   - The variance is that of an **individual** sample, not of the mean. With equal segment counts this is only an overall constant in the likelihood and does not move the peak; with unequal counts the caller should weight by :math:`\sigma^2/n`.
   - The mean is not re-wrapped, so it may leave :math:`(-\pi, \pi]` by up to one histogram bin when the mode sits on the cut.
   - At least two segments are needed for a variance.

   .. rubric:: Implementation Notes

   - A distribution of wrapped phases can straddle the :math:`\pm\pi` branch cut, where an arithmetic mean collapses towards zero.
   - The mode is located on a histogram, the cut is moved opposite it, and the average is taken there; the variance uses ``ddof=1`` plus a :math:`10^{-12}` floor against division by zero.

   .. rubric:: Calling Notes

   - The histogram bin width sets a quantisation floor: when the phase scatter is far below one bin, the accuracy of the mean is set by the bin width rather than by the sample count.

   .. rubric:: Algorithm Notes

   .. math::

      \bar\theta = \theta_{\rm mode}
      + \left\langle \mathrm{wrap}(\theta_i - \theta_{\rm mode}) \right\rangle,\qquad
      \sigma^2 = \mathrm{var}\!\left[\mathrm{wrap}(\theta_i-\theta_{\rm mode})\right]_{\rm ddof=1}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>

