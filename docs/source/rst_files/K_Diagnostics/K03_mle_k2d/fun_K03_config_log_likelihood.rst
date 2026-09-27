--------------------------------
fun_K03_config_log_likelihood.py
--------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   参数必须有限，方差为正，chi 为非零二维向量；可选 prediction 必须匹配网格。

   .. rubric:: 直接用途

   给出单个探针构型在波数网格上的对数似然。

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
      * - ``chi``
        - ``in``
        - ``(2,)``
        - 间距向量。
        - 米
        - 分量顺序为 :math:`(\chi_x,\chi_y)`。
      * - ``delta_theta``
        - ``in``
        - ``scalar``
        - 测得的互相位均值。
        - 弧度
        - 取自 ``fun_K01_phase_mode_statistics``。
      * - ``variance``
        - ``in``
        - ``scalar``，正
        - 相位方差。
        - rad²
        - 单样本方差，见该 routine 的说明。
      * - ``kx_values``
        - ``in``
        - ``(nkx,)``
        - 波数网格。
        - rad/m
        - 对应输出的轴 1。
      * - ``ky_values``
        - ``in``
        - ``(nky,)``
        - 波数网格。
        - rad/m
        - 对应输出的轴 0。
      * - ``prediction``
        - ``in``
        - ``(nky, nkx)``，可选
        - 预先算好的 ``fun_K03_predicted_phase``。
        - 弧度
        - 必须与本页的 ``chi`` 和网格一致。

   .. rubric:: 返回值

   ``numpy.ndarray``，shape ``(nky, nkx)``，未归一的对数似然。

   .. rubric:: 局部假设 / 前置条件

   - 把测得的均值相位建模为围绕平面波预测值的高斯分布。
   - 此方差描述分段相位的散布，用于设置似然中的残差尺度。众数的估计误差另受样本数、分箱和相位分布影响。

   .. rubric:: 实现逻辑

   - 将预测相位与测量相位之差折算到主值区间，再平方并按方差加权。相位的周期性在波数平面上形成条纹，可与其他构型的条纹联合分析。

   .. rubric:: 调用注意

   - ``prediction`` 可用于复用相同基线和网格上的前向计算结果，应与本次 ``chi`` 和网格对应。

   .. rubric:: 算法说明

   .. math::

      \ln L(\mathbf{K}) = -\frac{1}{2\sigma^2}
      \left[\mathrm{wrap}\!\left(\mathbf{K}\cdot\boldsymbol{\chi}-\bar\theta\right)\right]^2

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   Inputs must be finite, variance positive, chi a nonzero 2-vector; optional prediction must match the grid.

   .. rubric:: Direct Purpose

   Return the log-likelihood of one probe configuration over the wavenumber grid.

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
      * - ``chi``
        - ``in``
        - ``(2,)``
        - Separation vector.
        - metres
        - Components ordered :math:`(\chi_x,\chi_y)`.
      * - ``delta_theta``
        - ``in``
        - ``scalar``
        - Measured mean cross phase.
        - radians
        - From ``fun_K01_phase_mode_statistics``.
      * - ``variance``
        - ``in``
        - ``scalar``, positive
        - Phase variance.
        - rad^2
        - A single-sample variance; see that routine.
      * - ``kx_values``
        - ``in``
        - ``(nkx,)``
        - Wavenumber grid.
        - rad/m
        - Maps to axis 1 of the output.
      * - ``ky_values``
        - ``in``
        - ``(nky,)``
        - Wavenumber grid.
        - rad/m
        - Maps to axis 0 of the output.
      * - ``prediction``
        - ``in``
        - ``(nky, nkx)``, optional
        - Precomputed ``fun_K03_predicted_phase``.
        - radians
        - Must belong to the same ``chi`` and grid as this call.

   .. rubric:: Return Value

   ``numpy.ndarray``, shape ``(nky, nkx)``, the unnormalised log-likelihood.

   .. rubric:: Local Assumptions and Preconditions

   - Models the measured mean phase as Gaussian about the plane-wave prediction.
   - The variance describes segment-phase scatter and sets the residual scale. Mode-location uncertainty also depends on sample count, binning and the distribution.

   .. rubric:: Implementation Notes

   - Wrap the predicted-minus-measured phase difference, square it and weight by the variance. Phase periodicity produces fringes in the wavenumber plane, which can be analyzed jointly with other configurations.

   .. rubric:: Calling Notes

   - Supply ``prediction`` to reuse a forward calculation for the same baseline and grid; it should correspond to this call's ``chi`` and grid.

   .. rubric:: Algorithm Notes

   .. math::

      \ln L(\mathbf{K}) = -\frac{1}{2\sigma^2}
      \left[\mathrm{wrap}\!\left(\mathbf{K}\cdot\boldsymbol{\chi}-\bar\theta\right)\right]^2

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
