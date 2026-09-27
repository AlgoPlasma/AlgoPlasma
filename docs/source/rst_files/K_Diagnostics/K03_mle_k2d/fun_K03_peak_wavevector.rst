--------------------------
fun_K03_peak_wavevector.py
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   输入似然应有限且包含可定位的峰。非有限或完全平坦的数组抛 ValueError；相等最大值按数组顺序取第一个。

   .. rubric:: 直接用途

   定位对数似然网格的极大点。

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
      * - ``log_likelihood``
        - ``in``
        - ``(nky, nkx)``
        - 来自 ``fun_K03_joint_log_likelihood`` 的似然。
        - 无量纲
        - 输出按 ``[iy, ix]`` 索引，与 ``numpy.meshgrid`` 默认次序一致。
      * - ``kx_values``
        - ``in``
        - ``(nkx,)``
        - 波数网格。
        - rad/m
        - 对应输出的轴 1。
      * - ``ky_values``
        - ``in``
        - ``(nky,)``
        - 波数网格。
        - rad/m
        - 对应输出的轴 0。

   .. rubric:: 返回值

   ``dict``，含 ``kx``、``ky``、``k_magnitude``、``angle_deg`` 和 ``peak_log_likelihood``。

   .. rubric:: 局部假设 / 前置条件

   - 估计值被限制在网格上，精度与网格分辨率及混叠分支选择有关。

   .. rubric:: 实现逻辑

   - ``argmax`` 后 ``unravel_index``，同时给出直角坐标与极坐标形式。

   .. rubric:: 调用注意

   - 峰位落在边界时，可扩大范围并比较结果；``angle_deg`` 由 ``arctan2`` 给出。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   The input likelihood must be finite and have a locatable peak. Nonfinite or flat arrays raise ValueError; exact ties select the first point in array order.

   .. rubric:: Direct Purpose

   Locate the maximum of a log-likelihood grid.

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
      * - ``log_likelihood``
        - ``in``
        - ``(nky, nkx)``
        - Likelihood from ``fun_K03_joint_log_likelihood``.
        - Dimensionless
        - The output is indexed ``[iy, ix]``, matching the ``numpy.meshgrid`` default ordering.
      * - ``kx_values``
        - ``in``
        - ``(nkx,)``
        - Wavenumber grid.
        - rad/m
        - Maps to axis 1 of the output.
      * - ``ky_values``
        - ``in``
        - ``(nky,)``
        - Wavenumber grid.
        - rad/m
        - Maps to axis 0 of the output.

   .. rubric:: Return Value

   ``dict`` with ``kx``, ``ky``, ``k_magnitude``, ``angle_deg`` and ``peak_log_likelihood``.

   .. rubric:: Local Assumptions and Preconditions

   - The estimate is confined to the grid, so the accuracy depends on grid resolution and alias selection.

   .. rubric:: Implementation Notes

   - ``argmax`` followed by ``unravel_index``, reported in both Cartesian and polar form.

   .. rubric:: Calling Notes

   - For a boundary peak, expand the range and compare the resulting estimates. ``angle_deg`` comes from ``arctan2``.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
