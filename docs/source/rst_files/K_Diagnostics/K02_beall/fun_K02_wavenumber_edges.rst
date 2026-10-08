---------------------------
fun_K02_wavenumber_edges.py
---------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   构造张成整个不混叠波数范围的均匀直方图边界。

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
        - 间距向量 :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`。
        - 米
        - 分量顺序为 :math:`(\chi_x,\chi_y)`，与波矢同一直角坐标系。
      * - ``n_bins``
        - ``in``
        - ``scalar``，:math:`\ge 2`
        - 直方图格数。
        - 格数，无量纲
        - 边界数为 ``n_bins+1``。

   .. rubric:: 返回值

   ``numpy.ndarray``，shape ``(n_bins+1,)``，单位 rad/m。

   .. rubric:: 局部假设 / 前置条件

   - 范围恰为 :math:`[-\pi/|\boldsymbol{\chi}|, +\pi/|\boldsymbol{\chi}|]`。设得更宽会留下永远填不上的空白，更窄则会丢弃该探针对本可以测到的波数。

   .. rubric:: 实现逻辑

   - 本单元所有 routine 都经 ``fun_K02_separation_magnitude`` 取 :math:`|\boldsymbol{\chi}|`，形状与零长度校验集中在那一处。

   .. rubric:: 调用注意

   - 格数应与分段数匹配：分段数远少于格数时，Beall 谱的峰只是最强的单个样本。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Build uniform histogram edges spanning the full unaliased wavenumber range.

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
        - Separation vector :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`.
        - metres
        - Components ordered :math:`(\chi_x,\chi_y)`, in the same Cartesian frame as the wavevector.
      * - ``n_bins``
        - ``in``
        - ``scalar``, :math:`\ge 2`
        - Number of histogram bins.
        - Bin count, dimensionless
        - Produces ``n_bins+1`` edges.

   .. rubric:: Return Value

   ``numpy.ndarray``, shape ``(n_bins+1,)``, in rad/m.

   .. rubric:: Local Assumptions and Preconditions

   - The range is exactly :math:`[-\pi/|\boldsymbol{\chi}|, +\pi/|\boldsymbol{\chi}|]`. A wider one leaves empty margins that can never be populated; a narrower one discards wavenumbers the pair can measure.

   .. rubric:: Implementation Notes

   - Every routine in this unit takes :math:`|\boldsymbol{\chi}|` through ``fun_K02_separation_magnitude``, where the shape and zero-length checks are done once.

   .. rubric:: Calling Notes

   - The bin count should match the segment count: with far fewer segments than bins, the Beall peak is only the strongest single sample.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
