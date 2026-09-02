----------------------------
fun_K03_search_wavevector.py
----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   先在全域粗搜、再在粗峰附近细化。

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
      * - ``configurations``
        - ``in``
        - iterable
        - 每项为 :math:`(\boldsymbol{\chi}, \bar\theta, \sigma^2)`；会被 materialize，因为要遍历两次。
        - 见各分量
        - 两阶段使用同一批构型。
      * - ``k_range_rad_m``
        - ``in``
        - ``scalar``，正
        - 粗网格半宽，必须包含真实波矢。
        - rad/m
        - 只作用于第一阶段。
      * - ``n_coarse``
        - ``in``
        - ``scalar``，可选
        - 第一阶段每轴点数，默认 401。
        - 点数，无量纲
        - 决定粗步长。
      * - ``n_fine``
        - ``in``
        - ``scalar``，可选
        - 第二阶段每轴点数，默认 201。
        - 点数，无量纲
        - 决定最终精度。
      * - ``refine_span``
        - ``in``
        - ``scalar``，可选
        - 细化窗口在粗峰两侧各保留的粗步长数，默认 2.0。
        - 粗步长数，无量纲
        - 窗口关于粗峰对称。

   .. rubric:: 返回值

   ``dict``，同 ``fun_K03_peak_wavevector``，另加 ``coarse_step`` 与 ``fine_step``。

   .. rubric:: 局部假设 / 前置条件

   - 单一均匀网格无法服务宽频带：它既要够到最大波矢又要分辨最小波矢，跨三个数量级需要每轴数千点。
   - 细化窗口假定真峰落在粗峰的 ``refine_span`` 个粗步长之内。

   .. rubric:: 实现逻辑

   - 第一阶段在全域粗网格上取峰，第二阶段在粗峰附近重建细网格再取峰。

   .. rubric:: 调用注意

   - 粗搜阶段只需选对条纹、而非条纹内的具体位置，因此粗步长必须显著小于最短间距的条纹周期 :math:`2\pi/|\boldsymbol{\chi}|`。结果若像是被锁到错误的折叠阶，先查这一条。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Run a coarse grid search over the whole range, then refine around the coarse peak.

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
      * - ``configurations``
        - ``in``
        - iterable
        - Each item is :math:`(\boldsymbol{\chi}, \bar\theta, \sigma^2)`; materialised, since it is traversed twice.
        - See each component
        - The same set is used in both stages.
      * - ``k_range_rad_m``
        - ``in``
        - ``scalar``, positive
        - Half-width of the coarse grid; it must contain the true wavevector.
        - rad/m
        - Applies to the first stage only.
      * - ``n_coarse``
        - ``in``
        - ``scalar``, optional
        - Points per axis in the first stage. Default 401.
        - Point count, dimensionless
        - Sets the coarse step.
      * - ``n_fine``
        - ``in``
        - ``scalar``, optional
        - Points per axis in the second stage. Default 201.
        - Point count, dimensionless
        - Sets the final accuracy.
      * - ``refine_span``
        - ``in``
        - ``scalar``, optional
        - Coarse steps kept on each side of the coarse peak. Default 2.0.
        - Coarse steps, dimensionless
        - The window is symmetric about the coarse peak.

   .. rubric:: Return Value

   ``dict`` as ``fun_K03_peak_wavevector``, with ``coarse_step`` and ``fine_step`` added.

   .. rubric:: Local Assumptions and Preconditions

   - A single uniform grid cannot serve a wide band: it must reach the largest wavevector present while still resolving the smallest, and three decades would need thousands of points per axis.
   - The refinement window assumes the true peak lies within ``refine_span`` coarse steps of the coarse one.

   .. rubric:: Implementation Notes

   - The first stage takes the peak on a coarse grid over the whole range; the second rebuilds a fine grid around it and takes the peak again.

   .. rubric:: Calling Notes

   - The coarse stage only has to pick the right fringe, not the right point within it, so its step must stay well below the fringe period :math:`2\pi/|\boldsymbol{\chi}|` of the shortest separation. Check that first if a result looks locked to the wrong fold.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>

