------------------------------
fun_K02_wavenumber_residual.py
------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   给出折叠轴上两个波数之间的圆周距离。

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
      * - ``measured``
        - ``in``
        - 任意 shape
        - 实测波数。
        - rad/m
        - 逐元素运算。
      * - ``reference``
        - ``in``
        - 任意 shape
        - 参考波数，通常来自 ``fun_K02_fold_wavenumber``。
        - rad/m
        - 与 ``measured`` 广播兼容。
      * - ``chi``
        - ``in``
        - ``(2,)``
        - 间距向量 :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`。
        - 米
        - 分量顺序为 :math:`(\chi_x,\chi_y)`，与波矢同一直角坐标系。

   .. rubric:: 返回值

   ``numpy.ndarray``，绝对圆周差，rad/m，不超过 :math:`\pi/|\boldsymbol{\chi}|`。

   .. rubric:: 局部假设 / 前置条件

   - 单对探针的波数轴以 :math:`2\pi/|\boldsymbol{\chi}|` 为周期：紧贴 :math:`+\pi/|\boldsymbol{\chi}|` 的值与紧贴 :math:`-\pi/|\boldsymbol{\chi}|` 的值是邻居而不是对立面。
   - 直接相减比较折叠波数，会在贴近 Nyquist 边时报出整整一个周期的误差，那是相减方式的假象而非真实差异。

   .. rubric:: 实现逻辑

   - 把差值折算到以零为中心、宽度为一个折叠周期的区间上再取绝对值。

   .. rubric:: 调用注意

   - 圆周残差只比较折叠轴上的位置；相差整数个周期的波数具有相同残差，因此它不能判断已丢失的折叠阶。评价谱峰定位时，应把残差与波数网格宽度比较。

   .. rubric:: 算法说明

   .. math::

      \Delta k = \left| \left(\,k_{\rm m}-k_{\rm r}+k_{\rm Nyq}\right)
      \bmod 2k_{\rm Nyq} - k_{\rm Nyq} \right|

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Return the circular distance between two wavenumbers on the folded axis.

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
      * - ``measured``
        - ``in``
        - any shape
        - Measured wavenumbers.
        - rad/m
        - Element-wise.
      * - ``reference``
        - ``in``
        - any shape
        - Reference wavenumbers, usually from ``fun_K02_fold_wavenumber``.
        - rad/m
        - Broadcast-compatible with ``measured``.
      * - ``chi``
        - ``in``
        - ``(2,)``
        - Separation vector :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`.
        - metres
        - Components ordered :math:`(\chi_x,\chi_y)`, in the same Cartesian frame as the wavevector.

   .. rubric:: Return Value

   ``numpy.ndarray``, absolute circular difference in rad/m, never above :math:`\pi/|\boldsymbol{\chi}|`.

   .. rubric:: Local Assumptions and Preconditions

   - The wavenumber axis of a single pair is periodic with period :math:`2\pi/|\boldsymbol{\chi}|`: a value just below :math:`+\pi/|\boldsymbol{\chi}|` and one just above :math:`-\pi/|\boldsymbol{\chi}|` are neighbours, not opposites.
   - A plain difference reports a full period of error whenever a value sits near a Nyquist edge, which is an artefact of the subtraction rather than a real discrepancy.

   .. rubric:: Implementation Notes

   - The difference is folded onto an interval of one period centred on zero, then taken in absolute value.

   .. rubric:: Calling Notes

   - Circular residual compares positions only on the folded axis. Wavenumbers separated by an integer number of periods have the same residual, so it cannot identify the lost fold order. Compare it with the wavenumber-grid spacing when assessing peak localization.

   .. rubric:: Algorithm Notes

   .. math::

      \Delta k = \left| \left(\,k_{\rm m}-k_{\rm r}+k_{\rm Nyq}\right)
      \bmod 2k_{\rm Nyq} - k_{\rm Nyq} \right|

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
