---------------------------
fun_K02_beall_wavenumber.py
---------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   把互相位换算为沿间距方向的波数。

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
        - 任意 shape
        - 来自 ``fun_K01_cross_phase`` 的互相位。
        - 弧度
        - 逐元素运算。
      * - ``chi``
        - ``in``
        - ``(2,)``
        - 间距向量 :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`。
        - 米
        - 分量顺序为 :math:`(\chi_x,\chi_y)`，与波矢同一直角坐标系。

   .. rubric:: 返回值

   ``numpy.ndarray``，沿间距方向的波数，rad/m，由构造保证落在 Nyquist 区间内。

   .. rubric:: 局部假设 / 前置条件

   - 沿用 K01 的符号约定；交换探针顺序会镜像本页所有结果。
   - 互谱为 :math:`X_1X_2^{*}`，平面波给出 :math:`\theta=\mathbf{K}\cdot\boldsymbol{\chi}`，因此这里不需要任何符号翻转。

   .. rubric:: 实现逻辑

   - 折算由 ``fun_K01_wrap_to_pi`` 完成，再除以 :math:`|\boldsymbol{\chi}|`。

   .. rubric:: 调用注意

   - 有效间距是所关心方向上的**投影长度**：探针对与该方向成角时应传入投影后的向量。

   .. rubric:: 算法说明

   .. math::

      k_\parallel = \frac{\mathrm{wrap}(\theta)}{|\boldsymbol{\chi}|}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Convert a cross phase to a wavenumber along the separation.

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
        - any shape
        - Cross phase from ``fun_K01_cross_phase``.
        - radians
        - Element-wise.
      * - ``chi``
        - ``in``
        - ``(2,)``
        - Separation vector :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`.
        - metres
        - Components ordered :math:`(\chi_x,\chi_y)`, in the same Cartesian frame as the wavevector.

   .. rubric:: Return Value

   ``numpy.ndarray``, wavenumber along the separation in rad/m, confined to the Nyquist interval by construction.

   .. rubric:: Local Assumptions and Preconditions

   - Follows the K01 sign convention; reversing the probe order mirrors every result on this page.
   - The cross spectrum is :math:`X_1X_2^{*}` and a plane wave gives :math:`\theta=\mathbf{K}\cdot\boldsymbol{\chi}`, so no sign change is needed here.

   .. rubric:: Implementation Notes

   - The wrap is done by ``fun_K01_wrap_to_pi``, then divided by :math:`|\boldsymbol{\chi}|`.

   .. rubric:: Calling Notes

   - The effective separation is the **projected** length along the direction of interest: pass the projected vector when the pair is at an angle to it.

   .. rubric:: Algorithm Notes

   .. math::

      k_\parallel = \frac{\mathrm{wrap}(\theta)}{|\boldsymbol{\chi}|}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
