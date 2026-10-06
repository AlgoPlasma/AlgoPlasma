-----------------------------
fun_K02_nyquist_wavenumber.py
-----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   给出该间距可分辨的最大波数 :math:`\pi/|\boldsymbol{\chi}|`。

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

   ``float``，Nyquist 波数，rad/m。

   .. rubric:: 局部假设 / 前置条件

   - 一对探针只能观测到模 :math:`2\pi` 的相位 :math:`\mathbf{K}\cdot\boldsymbol{\chi}`，因此该区间之外的波数与其折叠像无法区分。
   - 对速度为 :math:`v` 的色散支，对应的频率上限是 :math:`v/(2|\boldsymbol{\chi}|)`。

   .. rubric:: 实现逻辑

   - 本单元所有 routine 都经 ``fun_K02_separation_magnitude`` 取 :math:`|\boldsymbol{\chi}|`，形状与零长度校验集中在那一处。

   .. rubric:: 调用注意

   - 这是单对探针的硬限制，与信噪比和分段数无关；要越过它只能靠 K03 的多间距联合反演。

   .. rubric:: 算法说明

   .. math::

      k_{\rm Nyq} = \frac{\pi}{|\boldsymbol{\chi}|},\qquad
      f_{\rm alias} = \frac{v}{2|\boldsymbol{\chi}|}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Return the largest wavenumber a separation can resolve, :math:`\pi/|\boldsymbol{\chi}|`.

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

   ``float``, the Nyquist wavenumber in rad/m.

   .. rubric:: Local Assumptions and Preconditions

   - A pair observes the phase :math:`\mathbf{K}\cdot\boldsymbol{\chi}` only modulo :math:`2\pi`, so wavenumbers outside that interval cannot be told apart from their folded images.
   - For a branch of speed :math:`v` the corresponding frequency limit is :math:`v/(2|\boldsymbol{\chi}|)`.

   .. rubric:: Implementation Notes

   - Every routine in this unit takes :math:`|\boldsymbol{\chi}|` through ``fun_K02_separation_magnitude``, where the shape and zero-length checks are done once.

   .. rubric:: Calling Notes

   - This is a hard limit of a single pair, independent of signal-to-noise ratio and segment count; only the multi-separation inversion of K03 can go beyond it.

   .. rubric:: Algorithm Notes

   .. math::

      k_{\rm Nyq} = \frac{\pi}{|\boldsymbol{\chi}|},\qquad
      f_{\rm alias} = \frac{v}{2|\boldsymbol{\chi}|}

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
