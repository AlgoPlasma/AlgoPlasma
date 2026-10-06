----------------------------
fun_K02_separation_vector.py
----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   由间距和方位角构造探针间距向量。

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
      * - ``spacing_m``
        - ``in``
        - ``scalar``，正
        - 间距 :math:`|\boldsymbol{\chi}|`。
        - 米
        - 标量。
      * - ``angle_rad``
        - ``in``
        - ``scalar``
        - 自 :math:`+x` 轴起算的方位角。
        - 弧度
        - 决定 :math:`\boldsymbol{\chi}` 在平面内的指向。

   .. rubric:: 返回值

   ``numpy.ndarray``，shape ``(2,)``，单位米。

   .. rubric:: 局部假设 / 前置条件

   - 间距定义为 :math:`\mathbf{r}_2-\mathbf{r}_1`。反向会让所有互相位反号、所有反演出的波数镜像，因此这个向量的指向决定了整个模块族的符号约定。

   .. rubric:: 实现逻辑

   - :math:`\boldsymbol{\chi} = |\boldsymbol{\chi}|(\cos a, \sin a)`。

   .. rubric:: 调用注意

   - 间距必须为正；零或负值会被拒绝，因为后续 routine 都要除以其长度。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Build a probe separation vector from a spacing and an orientation.

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
      * - ``spacing_m``
        - ``in``
        - ``scalar``, positive
        - Separation :math:`|\boldsymbol{\chi}|`.
        - metres
        - Scalar.
      * - ``angle_rad``
        - ``in``
        - ``scalar``
        - Orientation from the :math:`+x` axis.
        - radians
        - Sets the in-plane direction of :math:`\boldsymbol{\chi}`.

   .. rubric:: Return Value

   ``numpy.ndarray``, shape ``(2,)``, in metres.

   .. rubric:: Local Assumptions and Preconditions

   - The separation is :math:`\mathbf{r}_2-\mathbf{r}_1`. Reversing it negates every cross phase and mirrors every recovered wavenumber, so the sense of this vector fixes the sign convention of the whole module family.

   .. rubric:: Implementation Notes

   - :math:`\boldsymbol{\chi} = |\boldsymbol{\chi}|(\cos a, \sin a)`.

   .. rubric:: Calling Notes

   - The spacing must be positive; zero or negative values are rejected, since every later routine divides by its length.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
