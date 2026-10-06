-------------------------------
fun_K02_separation_magnitude.py
-------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   给出间距向量的长度，并集中做形状与零长度校验。

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

   .. rubric:: 返回值

   ``float``，长度 :math:`|\boldsymbol{\chi}|`，米。

   .. rubric:: 局部假设 / 前置条件

   - 本单元每个 routine 都要除以 :math:`|\boldsymbol{\chi}|`，所以校验集中在这里做一次，而不是在每个 routine 里重复。

   .. rubric:: 实现逻辑

   - :math:`\mathrm{hypot}(\chi_x,\chi_y)`；非 ``(2,)`` 或长度为零时抛 ``ValueError``。

   .. rubric:: 调用注意

   - 这是本单元内部共用的基础 routine，调用方通常不必直接使用。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Return the length of a separation vector, with the validation done once.

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

   .. rubric:: Return Value

   ``float``, the length :math:`|\boldsymbol{\chi}|` in metres.

   .. rubric:: Local Assumptions and Preconditions

   - Every routine in this unit divides by :math:`|\boldsymbol{\chi}|`, so the checks are done here once rather than repeated in each of them.

   .. rubric:: Implementation Notes

   - :math:`\mathrm{hypot}(\chi_x,\chi_y)`, raising ``ValueError`` for a wrong shape or a zero length.

   .. rubric:: Calling Notes

   - This is a shared internal routine of the unit; callers rarely need it directly.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
