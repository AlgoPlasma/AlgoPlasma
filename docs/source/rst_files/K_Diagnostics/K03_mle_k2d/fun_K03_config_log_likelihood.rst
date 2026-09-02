--------------------------------
fun_K03_config_log_likelihood.py
--------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

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
   - 方差为单样本方差；各构型分段数不同时应自行按 :math:`\sigma^2/n` 加权。

   .. rubric:: 实现逻辑

   - 残差在平方前先折算。这一步不是数值便利：正是它使混叠构型贡献出周期性的一族脊而非单条脊，混叠信息因而保留在似然里、可以被其他构型解出。

   .. rubric:: 调用注意

   - 传入 ``prediction`` 时不再校验其与 ``chi`` 是否匹配，调用方需自行保证一致。

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
   - The variance is a single-sample variance; unequal segment counts should be weighted by :math:`\sigma^2/n`.

   .. rubric:: Implementation Notes

   - The residual is wrapped before squaring. That step is not a numerical convenience: it is what makes an aliased configuration contribute a periodic family of ridges rather than a single one, so the folded information stays in the likelihood and can be resolved by the other configurations.

   .. rubric:: Calling Notes

   - When ``prediction`` is supplied it is not re-checked against ``chi``; the caller must keep them consistent.

   .. rubric:: Algorithm Notes

   .. math::

      \ln L(\mathbf{K}) = -\frac{1}{2\sigma^2}
      \left[\mathrm{wrap}\!\left(\mathbf{K}\cdot\boldsymbol{\chi}-\bar\theta\right)\right]^2

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>

