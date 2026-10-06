---------------------
fun_K02_fold_order.py
---------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   给出投影波数的混叠折叠阶数。

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
      * - ``k_projected``
        - ``in``
        - ``scalar`` 或数组
        - 投影波数。
        - rad/m
        - 逐元素运算。
      * - ``chi``
        - ``in``
        - ``(2,)``
        - 间距向量 :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`。
        - 米
        - 分量顺序为 :math:`(\chi_x,\chi_y)`，与波矢同一直角坐标系。

   .. rubric:: 返回值

   标量输入返回 ``int``，数组输入返回 ``numpy.ndarray`` of ``int64``。

   .. rubric:: 局部假设 / 前置条件

   - 输入为已知投影波数，函数计算它跨越的折叠周期数。常用于比较理论波数与测得的折叠波数。

   .. rubric:: 实现逻辑

   - :math:`n=\mathrm{round}(k_{\rm proj}|\boldsymbol{\chi}|/2\pi)`，使折叠结果落进 Nyquist 区间。

   .. rubric:: 调用注意

   - 阶数为 0 即未混叠；测试用它统计一份数据里出现了多少不同的折叠阶。

   .. rubric:: 算法说明

   .. math::

      n = \mathrm{round}\!\left(\frac{k_{\rm proj}\,|\boldsymbol{\chi}|}{2\pi}\right)

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Return the aliasing fold order of a projected wavenumber.

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
      * - ``k_projected``
        - ``in``
        - ``scalar`` or array
        - Projected wavenumber.
        - rad/m
        - Element-wise.
      * - ``chi``
        - ``in``
        - ``(2,)``
        - Separation vector :math:`\boldsymbol{\chi}=\mathbf{r}_2-\mathbf{r}_1`.
        - metres
        - Components ordered :math:`(\chi_x,\chi_y)`, in the same Cartesian frame as the wavevector.

   .. rubric:: Return Value

   ``int`` for scalar input, ``numpy.ndarray`` of ``int64`` otherwise.

   .. rubric:: Local Assumptions and Preconditions

   - The input is a known projected wavenumber; the function counts its folding periods. It is useful when comparing theoretical wavenumbers with measured folded values.

   .. rubric:: Implementation Notes

   - :math:`n=\mathrm{round}(k_{\rm proj}|\boldsymbol{\chi}|/2\pi)`, the integer that brings the folded result inside the Nyquist interval.

   .. rubric:: Calling Notes

   - An order of zero means the configuration is unaliased; the tests use it to count how many distinct orders a dataset exhibits.

   .. rubric:: Algorithm Notes

   .. math::

      n = \mathrm{round}\!\left(\frac{k_{\rm proj}\,|\boldsymbol{\chi}|}{2\pi}\right)

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
