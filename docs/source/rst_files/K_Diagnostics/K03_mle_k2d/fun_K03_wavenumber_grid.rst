--------------------------
fun_K03_wavenumber_grid.py
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   构造 :math:`[-k_{\rm range}, +k_{\rm range}]` 上的均匀搜索网格。

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
      * - ``k_range_rad_m``
        - ``in``
        - ``scalar``，正
        - 网格半宽。
        - rad/m
        - 网格关于原点对称。
      * - ``n_grid``
        - ``in``
        - ``scalar``，:math:`\ge 2`
        - 轴上的点数。
        - 点数，无量纲
        - 步长为 :math:`2k_{\rm range}/(n-1)`。

   .. rubric:: 返回值

   ``numpy.ndarray``，shape ``(n_grid,)``，单位 rad/m。

   .. rubric:: 局部假设 / 前置条件

   - 似然在网格上取极大，估计值被限制在网格内：范围必须包含真实波矢。
   - 网格离散化给出半个网格步长的精度下限。

   .. rubric:: 实现逻辑

   - ``numpy.linspace``，两端闭合。

   .. rubric:: 调用注意

   - 峰位落在网格边界说明范围设得过窄，应扩大 :math:`k_{\rm range}` 后重算。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Build a uniform search grid on :math:`[-k_{\rm range}, +k_{\rm range}]`.

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
      * - ``k_range_rad_m``
        - ``in``
        - ``scalar``, positive
        - Half-width of the grid.
        - rad/m
        - The grid is symmetric about the origin.
      * - ``n_grid``
        - ``in``
        - ``scalar``, :math:`\ge 2`
        - Points along the axis.
        - Point count, dimensionless
        - The step is :math:`2k_{\rm range}/(n-1)`.

   .. rubric:: Return Value

   ``numpy.ndarray``, shape ``(n_grid,)``, in rad/m.

   .. rubric:: Local Assumptions and Preconditions

   - The likelihood is maximised on the grid, so the estimate is confined to it: the range must contain the true wavevector.
   - Grid discretisation puts a floor of half a grid step on the accuracy.

   .. rubric:: Implementation Notes

   - ``numpy.linspace``, closed at both ends.

   .. rubric:: Calling Notes

   - A peak on the grid boundary means the range was too narrow; widen :math:`k_{\rm range}` and search again.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>

