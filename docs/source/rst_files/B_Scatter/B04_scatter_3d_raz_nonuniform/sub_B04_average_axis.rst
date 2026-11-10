sub_B04_average_axis
====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-b04-doc

   .. admonition:: 输入 → 加权平均 → 直接输出

      **输入：** 全周 ``r=0`` 轴线的密度平面和角向积分权重，已经完成所需的共享节点贡献求和。

      **处理：** 对每个轴向位置，沿角向计算体积等价的加权平均。

      **输出：** 原位覆写轴平面，使同一轴向位置的全部角索引具有相同密度；交给后续节点运算或单元平均。

   .. code-block:: fortran

      call sub_B04_average_axis(phi_measure, density(0,:,:), ierr)

   这里 ``density`` 的实际下界为零；若采用其他下界，传入对应真实 ``r=0`` 的平面。

   .. rubric:: 为什么按角向积分权重平均？

   轴线上不同角索引表示同一个物理位置。非均匀角网格中，各索引对应的有效体积不同，
   应按 :math:`A_j=\int S_j(\phi)\,d\phi` 加权：

   .. math::

      \overline D_{0,k}=\frac{\sum_j A_jD_{0,j,k}}{\sum_j A_j},\qquad
      D_{0,j,k}\leftarrow\overline D_{0,k}.

   固定 ``k`` 时 :math:`V_{0jk}=R_0 A_j Z_k`，因此该平均保持 :math:`\sum_j V_{0jk}D_{0jk}` （浮点舍入范围内）。
   对全周周期均匀角网格，所有 :math:`A_j` 相同，公式退化为算术平均。

   代码中，``phi_measure(j)`` 对应 :math:`A_j`，``axis_density(j,k)`` 对应 :math:`D_{0,j,k}`。
   循环之前计算 ``total=sum(phi_measure)``，因此 ``phi_measure/total`` 就是归一化角向权重。

   .. literalinclude:: ../../../../../B_Scatter/B04_scatter_3d_raz_nonuniform/sub_B04_average_axis.f90
      :language: fortran
      :start-at:     do k = 0, size(axis_density,2)-1
      :end-at:     ierr = B04_OK

   ``mean(k)`` 暂存平均值 :math:`\overline D_{0,k}`，检查后再覆写该轴向位置的全部角节点。输出仍保留原来的角向节点布局；统计总量时，各角索引继续使用其自身的有效体积。

   .. rubric:: 参数与调用条件

   .. list-table::
      :header-rows: 1
      :widths: 24 12 64

      * - 参数
        - 方向
        - 形状、含义与单位
      * - ``phi_measure``
        - in
        - 一维，每个独立角节点一项，正且有限，单位 rad；来自同一网格的 :doc:`build_geometry <sub_B04_build_geometry>`
      * - ``axis_density``
        - inout
        - 二维，角节点 × 轴向节点；两个维度均非空，第一维长度与 ``phi_measure`` 一致；单位保持为数密度或电荷密度
      * - ``ierr``
        - out
        - 整数；见 :ref:`公共状态码 <b04-status-zh>`

   - **调用方确认几何：** 例程只接收平面，调用方确保它来自全周 ``r=0`` 轴线。环域的内径节点按普通节点使用。
   - **完整且不重复：** 各独立角节点只出现一次，去除重复周期端点和重复进程副本；先完成贡献求和。
   - **输出安全：** 检查形状、正有限权重、权重和、输入密度及平均结果；非零返回保留整个平面。选择合适数值尺度，模块与调用方使用相同精度。

   已有 :ref:`非均匀轴点测试 <b04-axis-validation-zh>` 检查加权均值及正负密度的总量保持；具体输入与结果集中列在测试页。


   返回 :doc:`B04 总览 </rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform>` · :doc:`调用示例 <usage>` · :doc:`测试与结果 </tests/004_scatter/B04_scatter_3d_raz_nonuniform>`

.. container:: ap-lang ap-lang-en ap-b04-doc

   .. admonition:: Inputs → weighted average → output

      **Inputs:** the complete full-circle ``r=0`` density plane after shared-node summation, with angular basis integrals.

      **Operation:** take a volume-equivalent angular mean at each axial node.

      **Output:** replaces the plane with one density per axial location, retaining the array layout for nodal operations or cell averaging.

   .. code-block:: fortran

      call sub_B04_average_axis(phi_measure, density(0,:,:), ierr)

   This call assumes zero-based actual density. For other bounds, pass the actual plane at physical ``r=0``.

   .. rubric:: Why angular weights?

   All angular indices on an axis identify the same physical location, but their effective volumes differ on a nonuniform angular grid.
   With :math:`A_j=\int S_j(\phi)\,d\phi`, use

   .. math::

      \overline D_{0,k}=\frac{\sum_j A_jD_{0,j,k}}{\sum_j A_j},\qquad
      D_{0,j,k}\leftarrow\overline D_{0,k}.

   At fixed ``k``, :math:`V_{0jk}=R_0 A_j Z_k`; the update preserves :math:`\sum_j V_{0jk}D_{0jk}` to roundoff.
   Equal spacing on a full-circle periodic mesh makes all :math:`A_j` equal, giving the arithmetic mean.

   In code, ``phi_measure(j)`` is :math:`A_j` and ``axis_density(j,k)`` is :math:`D_{0,j,k}`.
   Before the loop, ``total=sum(phi_measure)`` is computed, so ``phi_measure/total`` gives normalized angular weights.

   .. literalinclude:: ../../../../../B_Scatter/B04_scatter_3d_raz_nonuniform/sub_B04_average_axis.f90
      :language: fortran
      :start-at:     do k = 0, size(axis_density,2)-1
      :end-at:     ierr = B04_OK

   ``mean(k)`` stages :math:`\overline D_{0,k}` before checks and writeback to all angular entries at that axial node. Retain each angular entry's own volume in later total-amount sums.

   .. rubric:: Parameters and calling conditions

   .. list-table::
      :header-rows: 1
      :widths: 24 12 64

      * - Parameter
        - Direction
        - Shape, meaning and units
      * - ``phi_measure``
        - in
        - One positive finite value per independent angular node, in rad, from :doc:`build_geometry <sub_B04_build_geometry>` on the same grid
      * - ``axis_density``
        - inout
        - Angular nodes × axial nodes; both nonempty, first extent matches ``phi_measure``; number/charge-density units retained
      * - ``ierr``
        - out
        - Integer :ref:`shared status <b04-status-en>`

   - The caller establishes that the supplied plane is the full-circle axis. An annular inner surface uses ordinary nodes.
   - Include independent angular nodes once, after contribution summation, without duplicate periodic endpoints or MPI copies.
   - Shape, weights, their sum, densities and computed means are checked. A nonzero returned status preserves the plane. Use suitable numerical scales and consistent real precision.

   The :ref:`nonuniform-axis test <b04-axis-validation-en>` checks the weighted mean and total preservation for positive and negative densities; its inputs and results are collected on the test page.


   :doc:`B04 overview </rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform>` · :doc:`Usage example <usage>` · :doc:`Tests and results </tests/004_scatter/B04_scatter_3d_raz_nonuniform>`

   .. raw:: html

      <details class="ap-b04-api">
      <summary>Generated API — source reference</summary>

   .. doxygenfile:: sub_B04_average_axis.f90

   .. raw:: html

      </details>
