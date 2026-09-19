-----------------------------
fun_K02_project_wavenumber.py
-----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   给出波矢沿间距方向的分量 :math:`\mathbf{K}\cdot\hat{\boldsymbol{\chi}}`。

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
      * - ``k_vector``
        - ``in``
        - ``(2,)``
        - 二维波矢。
        - rad/m
        - 分量顺序为 :math:`(K_x,K_y)`。
      * - ``chi``
        - ``in``
        - ``(2,)``
        - 间距向量 :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`。
        - 米
        - 分量顺序为 :math:`(\chi_x,\chi_y)`，与波矢同一直角坐标系。

   .. rubric:: 返回值

   ``float``，投影波数，rad/m。

   .. rubric:: 局部假设 / 前置条件

   - 一对探针对垂直于自身间距的分量完全不敏感。这个投影是它唯一可能携带信息的部分，而且还要再经过折叠。

   .. rubric:: 实现逻辑

   - 本单元所有 routine 都经 ``fun_K02_separation_magnitude`` 取 :math:`|\boldsymbol{\chi}|`，形状与零长度校验集中在那一处。

   .. rubric:: 调用注意

   - 若要判断某模态在某构型上是否混叠，应把本 routine 的结果与 ``fun_K02_nyquist_wavenumber`` 比较。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Return the component of a wavevector along the separation, :math:`\mathbf{K}\cdot\hat{\boldsymbol{\chi}}`.

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
      * - ``k_vector``
        - ``in``
        - ``(2,)``
        - Two-dimensional wavevector.
        - rad/m
        - Components ordered :math:`(K_x,K_y)`.
      * - ``chi``
        - ``in``
        - ``(2,)``
        - Separation vector :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`.
        - metres
        - Components ordered :math:`(\chi_x,\chi_y)`, in the same Cartesian frame as the wavevector.

   .. rubric:: Return Value

   ``float``, the projected wavenumber in rad/m.

   .. rubric:: Local Assumptions and Preconditions

   - A pair is blind to the component perpendicular to its own separation. This projection is the only part of the wavevector it can carry information about, and even that only after folding.

   .. rubric:: Implementation Notes

   - Every routine in this unit takes :math:`|\boldsymbol{\chi}|` through ``fun_K02_separation_magnitude``, where the shape and zero-length checks are done once.

   .. rubric:: Calling Notes

   - To decide whether a mode aliases on a given configuration, compare this result with ``fun_K02_nyquist_wavenumber``.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
