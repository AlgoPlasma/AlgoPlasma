--------------------------
fun_K02_fold_wavenumber.py
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   把投影波数折叠进 Nyquist 区间。

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

   ``numpy.ndarray``，折叠后的波数，落在 :math:`\pm\pi/|\boldsymbol{\chi}|` 内。

   .. rubric:: 局部假设 / 前置条件

   - 这正是单对探针实际报出的量：相位只能被观测到模 :math:`2\pi`。
   - 越过 :math:`\pi/|\boldsymbol{\chi}|` 的色散支在 Beall 图上被打断成重复的锯齿。

   .. rubric:: 实现逻辑

   - 从投影波数中减去 :math:`n` 个周期，:math:`n` 来自 ``fun_K02_fold_order``。

   .. rubric:: 调用注意

   - 它给出的是**预言值**，可与 Beall 谱的实测峰位比较；两者之差应用 ``fun_K02_wavenumber_residual`` 计算。

   .. rubric:: 算法说明

   .. math::

      k_{\rm meas} = k_{\rm proj} - n\,\frac{2\pi}{|\boldsymbol{\chi}|}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Fold a projected wavenumber into the Nyquist interval.

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

   ``numpy.ndarray``, the folded wavenumber, within :math:`\pm\pi/|\boldsymbol{\chi}|`.

   .. rubric:: Local Assumptions and Preconditions

   - This is what a single pair actually reports: the phase is observable only modulo :math:`2\pi`.
   - A branch running past :math:`\pi/|\boldsymbol{\chi}|` is broken into a repeating sawtooth on the Beall map.

   .. rubric:: Implementation Notes

   - Subtracts :math:`n` periods from the projected wavenumber, with :math:`n` from ``fun_K02_fold_order``.

   .. rubric:: Calling Notes

   - The value is a **prediction** to compare with a measured Beall peak; take the difference with ``fun_K02_wavenumber_residual``.

   .. rubric:: Algorithm Notes

   .. math::

      k_{\rm meas} = k_{\rm proj} - n\,\frac{2\pi}{|\boldsymbol{\chi}|}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
