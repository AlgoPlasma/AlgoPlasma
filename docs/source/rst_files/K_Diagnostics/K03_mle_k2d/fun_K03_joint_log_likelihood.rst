-------------------------------
fun_K03_joint_log_likelihood.py
-------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   把多个探针构型的对数似然求和。

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
      * - ``configurations``
        - ``in``
        - iterable
        - 每项为 :math:`(\boldsymbol{\chi}, \bar\theta, \sigma^2)`。
        - 见各分量
        - 遍历一次；顺序不影响结果。
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
      * - ``normalise``
        - ``in``
        - ``scalar``，可选
        - 减去最大值使峰位为零，默认为真。
        - 布尔
        - 只做整体平移，不改变峰位。

   .. rubric:: 返回值

   ``numpy.ndarray``，shape ``(nky, nkx)``，联合对数似然。

   .. rubric:: 局部假设 / 前置条件

   - 单构型是严格简并的：其似然在垂直于 :math:`\boldsymbol{\chi}` 的方向上不变、沿该方向以 :math:`2\pi/|\boldsymbol{\chi}|` 为周期。
   - 必须有**不同的间距长度**：只含一个长度时所有条纹周期相同，折叠阶数无法确定。仅改变方向不够。

   .. rubric:: 实现逻辑

   - 逐构型累加 ``fun_K03_config_log_likelihood``；未提供任何构型时抛 ``ValueError``。

   .. rubric:: 调用注意

   - 各构型应携带同样的分段数，否则它们在似然里的权重不可比。

   .. rubric:: 算法说明

   .. math::

      \ln L(\mathbf{K}) = \sum_j \ln L_j(\mathbf{K})

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Sum the log-likelihoods of several probe configurations.

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
      * - ``configurations``
        - ``in``
        - iterable
        - Each item is :math:`(\boldsymbol{\chi}, \bar\theta, \sigma^2)`.
        - See each component
        - Traversed once; the order does not affect the result.
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
      * - ``normalise``
        - ``in``
        - ``scalar``, optional
        - Subtract the maximum so the peak sits at zero. Default true.
        - Boolean
        - A rigid shift that does not move the peak.

   .. rubric:: Return Value

   ``numpy.ndarray``, shape ``(nky, nkx)``, the joint log-likelihood.

   .. rubric:: Local Assumptions and Preconditions

   - One configuration is exactly degenerate: its likelihood is invariant perpendicular to :math:`\boldsymbol{\chi}` and periodic along it with period :math:`2\pi/|\boldsymbol{\chi}|`.
   - Different separation **lengths** are required: with a single length every fringe period is the same and the fold order stays undetermined. Changing only the orientation is not enough.

   .. rubric:: Implementation Notes

   - Accumulates ``fun_K03_config_log_likelihood`` configuration by configuration, raising ``ValueError`` if none is supplied.

   .. rubric:: Calling Notes

   - Configurations should carry the same segment count, or their weights in the likelihood are not comparable.

   .. rubric:: Algorithm Notes

   .. math::

      \ln L(\mathbf{K}) = \sum_j \ln L_j(\mathbf{K})

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>

