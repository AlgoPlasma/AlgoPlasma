--------------------------
fun_K03_predicted_phase.py
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   给出某构型在波数网格每一点上会测到的互相位。

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
        - 间距向量。
        - 米
        - 分量顺序为 :math:`(\chi_x,\chi_y)`。
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

   ``numpy.ndarray``，shape ``(nky, nkx)``，未折叠的预测相位，弧度。

   .. rubric:: 局部假设 / 前置条件

   - 前向模型就是 :math:`\mathbf{K}\cdot\boldsymbol{\chi}`，与 ``fun_K01_cross_phase`` 所测的是同一个量，不带符号翻转。
   - 输出按 ``[iy, ix]`` 索引，与 ``numpy.meshgrid`` 默认次序一致。

   .. rubric:: 实现逻辑

   - 用广播构造网格，不物化两个完整的坐标数组。
   - 该项不依赖频率，所以在同一几何上扫多个频点时应只算一次并传给 ``fun_K03_config_log_likelihood``。

   .. rubric:: 调用注意

   - 重建这一项在多频点扫描中会成为主要开销，务必复用。

   .. rubric:: 算法说明

   .. math::

      G(\mathbf{K}) = K_x\chi_x + K_y\chi_y

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/09/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Return the cross phase a configuration would measure at every point of the wavenumber grid.

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
        - Separation vector.
        - metres
        - Components ordered :math:`(\chi_x,\chi_y)`.
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

   ``numpy.ndarray``, shape ``(nky, nkx)``, the unwrapped predicted phase in radians.

   .. rubric:: Local Assumptions and Preconditions

   - The forward model is :math:`\mathbf{K}\cdot\boldsymbol{\chi}`, the same quantity ``fun_K01_cross_phase`` measures, with no sign change.
   - The output is indexed ``[iy, ix]``, matching the ``numpy.meshgrid`` default ordering.

   .. rubric:: Implementation Notes

   - The grid is formed by broadcasting rather than by materialising two full coordinate arrays.
   - The term does not depend on frequency, so a caller sweeping many frequencies on one geometry should build it once and pass it to ``fun_K03_config_log_likelihood``.

   .. rubric:: Calling Notes

   - Rebuilding this term dominates the cost of a multi-frequency sweep, so it must be reused.

   .. rubric:: Algorithm Notes

   .. math::

      G(\mathbf{K}) = K_x\chi_x + K_y\chi_y

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/09/02) · Harbin Institute of Technology</p>
      </div>
