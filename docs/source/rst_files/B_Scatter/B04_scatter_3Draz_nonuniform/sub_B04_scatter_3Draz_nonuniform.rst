sub_B04_scatter_3Draz_nonuniform
=================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-b04-doc

   .. admonition:: 输入 → 八节点分配 → 直接输出

      **输入：** 已定位的单个粒子、贡献量及配套逆体积。

      **处理：** 计算三个方向的线性权重，组合八项密度增量并检查累加范围。

      **输出：** 原位累加节点 ``density`` ；下一步由调用方求和共享节点，或交给轴点平均、节点运算。

   .. code-block:: fortran

      call sub_B04_scatter_3Draz_nonuniform(r, phi, z, periodic_phi, &
          cell, position, amount, inv_volume, density, ierr)

   .. _b04-local-weights-zh:

   .. rubric:: 局部坐标与张量积权重

   **非均匀网格保留三个方向的线性分配构造，位置比例按各单元的实际宽度计算。**
   调用方给出包含粒子的单元 ``cell=[i,j,k]``，再用该单元两端节点坐标定义

   .. math::

      \xi_r=\frac{r_p-r_i}{r_{i+1}-r_i},\quad
      \xi_\phi=\frac{\phi_p-\phi_j}{\phi_{j+1}-\phi_j},\quad
      \xi_z=\frac{z_p-z_k}{z_{k+1}-z_k}.

   令 :math:`b_0(\xi)=1-\xi`、:math:`b_1(\xi)=\xi`，则

   .. math::

      S_{abc}=b_a(\xi_r)b_b(\xi_\phi)b_c(\xi_z),\quad
      \Delta D_{i+a,j+b,k+c}=\frac{c_p S_{abc}}{V_{i+a,j+b,k+c}},\quad a,b,c\in\{0,1\}.

   这里 :math:`a,b,c` 分别是径向、角向、轴向的顶点偏移，取 0 或 1；
   :math:`S_{abc}` 是当前单元的局部顶点权重。将局部顶点映射到存储节点后，
   同一节点收到的权重相加，便得到总览中的 :math:`S_{ijk}^{(p)}`。

   **分配量由粒子在当前单元内的位置决定；归一化体积还包括目标节点其他相邻单元的贡献。**
   :math:`V` 由同一形函数的柱坐标积分得到，推导见 :ref:`有效节点体积 <b04-matching-volume-zh>`。
   均匀网格的每个方向使用相同步长，以上位置比例便化为固定步长的表达式；参见 :ref:`总览中的对照 <b04-grid-difference-zh>`。

   **公式与下面两段代码的对应关系：** ``amount`` 是粒子贡献量 :math:`c_p`，局部数组按下表使用。

   .. list-table::
      :header-rows: 1
      :widths: 32 68

      * - 代码变量
        - 含义与公式对应
      * - ``lo(1:3), hi(1:3)``；``h=hi-lo``
        - 当前单元在径向、角向、轴向的下端与上端坐标；``h`` 为三个方向的单元宽度
      * - ``fraction(1:3)``
        - 粒子在单元内的局部坐标 :math:`(\xi_r,\xi_\phi,\xi_z)`
      * - ``weights(0:1,1:3)``
        - 第一维 0/1 选下端/上端权重，第二维 1/2/3 选径向/角向/轴向；三方向权重相乘得到 :math:`S_{abc}`
      * - ``ix(0:1), iy(0:1), iz(0:1)``
        - 两个径向、角向、轴向目标节点的索引；周期时，末角单元的上端 ``iy(1)`` 映射到零号节点
      * - ``delta(0:1,0:1,0:1)``
        - 暂存八个局部顶点对应的密度增量 :math:`\Delta D`，检查后累加到目标节点

   .. literalinclude:: ../../../../../B_Scatter/B04_scatter_3Draz_nonuniform/sub_B04_scatter_3Draz_nonuniform.f90
      :language: fortran
      :start-at:     fraction = (position-lo)/h
      :end-at:     weights(1,:) = fraction

   .. literalinclude:: ../../../../../B_Scatter/B04_scatter_3Draz_nonuniform/sub_B04_scatter_3Draz_nonuniform.f90
      :language: fortran
      :start-at:         delta(a,b,c) = amount
      :end-at:         if (.not. ieee_is_finite(delta(a,b,c))) return

   八个权重之和为一，因此按配套体积加回去可恢复粒子贡献量。密度已完成体积归一化，可直接参与后续密度运算。

   .. rubric:: 参数与前置条件

   .. list-table::
      :header-rows: 1
      :widths: 24 12 64

      * - 参数
        - 方向
        - 形状、含义与单位
      * - ``r, phi, z``
        - in
        - 节点坐标 ``(0:nr), (0:nphi), (0:nz)`` ；严格递增且有限，``r>=0`` ；真实长度坐标与 rad
      * - ``periodic_phi``
        - in
        - logical；与几何准备时相同
      * - ``cell``
        - in
        - integer(3)；各方向相对单元号 ``0:nr-1, 0:nphi-1, 0:nz-1``
      * - ``position``
        - in
        - real(3)；物理 ``(r,phi,z)`` ，位于所给单元的闭区间内，与坐标数组同单位
      * - ``amount``
        - in
        - 有限实数；``wp`` 表示真实粒子数，``qp*wp`` 表示带符号电荷；允许逐粒子改变权重
      * - ``inv_volume``
        - in
        - 正且有限，与 ``density`` 同形；取自同一网格的 :doc:`build_geometry <sub_B04_build_geometry>`
      * - ``density``
        - inout
        - 周期 ``(0:nr,0:nphi-1,0:nz)`` ，非周期 ``(0:nr,0:nphi,0:nz)`` ；数密度或电荷密度
      * - ``ierr``
        - out
        - 整数；见 :ref:`公共状态码 <b04-status-zh>`

   每方向至少一个单元；实参数组的首元素映射为零，单元号遵循同一约定。
   按上述物理节点范围传入数组；所需的八个节点和完整体积必须可访问。
   首次沉积前初始化密度，后续调用保留并累加已有内容。长度为 m 时，输出单位为 :math:`\mathrm{m}^{-3}` 或 :math:`\mathrm{C\,m}^{-3}`。

   .. rubric:: 周期接缝、轴线和错误返回

   - 最后角单元先按未回绕的坐标区间计算权重，再把上端节点映射到零号节点。位置回绕和单元搜索由调用方完成。
   - 粒子恰在内部共享面时可选任一相邻单元，零权重给出相同分配。
   - 单个周期角单元的两个局部角顶点共用目标节点，两个贡献仍按顺序累加。
   - 先在八项临时值中检查最终密度加法，再统一写回。非零返回保留整个数组；中间乘积应处于所选精度范围。
   - 全部粒子和共享节点贡献就绪后，含轴全周区域调用 :doc:`average_axis <sub_B04_average_axis>`；并发调用使用独立数组或同步。

   完整坐标检查在几何准备时完成；逐粒子入口检查局部单元及实际访问的数据。模块与调用方采用相同默认实数精度。


   返回 :doc:`B04 总览 </rst_files/B_Scatter/B04_scatter_3Draz_nonuniform>` · :doc:`调用示例 <usage>` · :doc:`测试与结果 </tests/004_scatter/B04_scatter_3Draz_nonuniform>`

.. container:: ap-lang ap-lang-en ap-b04-doc

   .. admonition:: Inputs → eight-node assignment → output

      **Inputs:** one located particle, its represented amount and matching inverse volumes.

      **Operation:** form linear tensor-product weights and range-check density additions.

      **Output:** adds to ``density`` in place, for caller summation or axis/nodal operations.

   .. code-block:: fortran

      call sub_B04_scatter_3Draz_nonuniform(r, phi, z, periodic_phi, &
          cell, position, amount, inv_volume, density, ierr)

   .. _b04-local-weights-en:

   .. rubric:: Local coordinates and weights

   **A nonuniform mesh retains linear assignment in each direction, with position fractions computed from the actual cell widths.**
   The caller supplies the containing cell ``[i,j,k]``. Its endpoint coordinates give

   .. math::

      \xi_r=\frac{r_p-r_i}{r_{i+1}-r_i},\quad
      \xi_\phi=\frac{\phi_p-\phi_j}{\phi_{j+1}-\phi_j},\quad
      \xi_z=\frac{z_p-z_k}{z_{k+1}-z_k}.

   For :math:`b_0(\xi)=1-\xi` and :math:`b_1(\xi)=\xi`, the increments are

   .. math::

      S_{abc}=b_a(\xi_r)b_b(\xi_\phi)b_c(\xi_z),\quad
      \Delta D_{i+a,j+b,k+c}=\frac{c_p S_{abc}}{V_{i+a,j+b,k+c}},\quad a,b,c\in\{0,1\}.

   Here :math:`a,b,c` are the radial, angular and axial vertex offsets, each 0 or 1.
   :math:`S_{abc}` is a local vertex weight. After mapping vertices to stored nodes,
   summing weights that reach the same node gives :math:`S_{ijk}^{(p)}` in the overview.

   **Assignment depends on the particle position in its cell; normalization also includes contributions from the target node's other adjacent cells.**
   :math:`V` integrates the same basis with the cylindrical volume element; see :ref:`matching volumes <b04-matching-volume-en>`.
   Constant spacing in each direction reduces the position fractions to the uniform-grid expressions; see the :ref:`overview comparison <b04-grid-difference-en>`.

   **The formulas map to the two code excerpts below.** ``amount`` is the particle contribution :math:`c_p`; the local arrays are:

   .. list-table::
      :header-rows: 1
      :widths: 32 68

      * - Code variable
        - Meaning and formula correspondence
      * - ``lo(1:3), hi(1:3)``; ``h=hi-lo``
        - Lower and upper cell coordinates in radial, angular and axial order; ``h`` holds the three cell widths
      * - ``fraction(1:3)``
        - Local particle coordinates :math:`(\xi_r,\xi_\phi,\xi_z)`
      * - ``weights(0:1,1:3)``
        - First index 0/1 selects the lower/upper weight; second index 1/2/3 selects radial/angular/axial. Their product gives :math:`S_{abc}`
      * - ``ix(0:1), iy(0:1), iz(0:1)``
        - Target node indices in each direction; periodic indexing maps the last angular cell's upper index ``iy(1)`` to zero
      * - ``delta(0:1,0:1,0:1)``
        - Stages the eight local density increments :math:`\Delta D` before checks and accumulation at target nodes

   .. literalinclude:: ../../../../../B_Scatter/B04_scatter_3Draz_nonuniform/sub_B04_scatter_3Draz_nonuniform.f90
      :language: fortran
      :start-at:     fraction = (position-lo)/h
      :end-at:     weights(1,:) = fraction

   .. literalinclude:: ../../../../../B_Scatter/B04_scatter_3Draz_nonuniform/sub_B04_scatter_3Draz_nonuniform.f90
      :language: fortran
      :start-at:         delta(a,b,c) = amount
      :end-at:         if (.not. ieee_is_finite(delta(a,b,c))) return

   The eight weights sum to one. Multiplying density increments by their matching volumes recovers the particle amount; the stored result is already a density.

   .. rubric:: Parameters and prerequisites

   .. list-table::
      :header-rows: 1
      :widths: 24 12 64

      * - Parameter
        - Direction
        - Shape, meaning and units
      * - ``r, phi, z``
        - in
        - Node arrays ``(0:nr), (0:nphi), (0:nz)``; finite, strictly increasing, ``r>=0``; physical lengths and radians
      * - ``periodic_phi``
        - in
        - logical; the same topology used for geometry preparation
      * - ``cell``
        - in
        - integer(3); relative cell indices ``0:nr-1, 0:nphi-1, 0:nz-1``
      * - ``position``
        - in
        - real(3); physical ``(r,phi,z)`` inside the supplied closed cell intervals, with matching units
      * - ``amount``
        - in
        - Finite real; ``wp`` for represented number, ``qp*wp`` for signed charge; weights may vary per particle
      * - ``inv_volume``
        - in
        - Positive finite array matching ``density``, from :doc:`build_geometry <sub_B04_build_geometry>`
      * - ``density``
        - inout
        - Periodic ``(0:nr,0:nphi-1,0:nz)``, otherwise ``(0:nr,0:nphi,0:nz)``; number or charge per physical volume
      * - ``ierr``
        - out
        - Integer :ref:`shared status <b04-status-en>`

   Each direction has at least one cell. Actual first elements map to index zero, as do cell indices.
   Pass the physical-node extents with all eight accessed nodes and complete volumes available.
   Initialize before first accumulation; later calls retain contributions. Metre coordinates give :math:`\mathrm{m}^{-3}` or :math:`\mathrm{C\,m}^{-3}`.

   .. rubric:: Seams, axis and returned errors

   - Compute last-cell weights on the unwrapped interval, then map its upper angular node to zero. The caller wraps positions and finds cells.
   - An internal-face particle can use either neighboring cell; zero weights give the same result.
   - For one periodic angular cell, both local angular vertices contribute to the same target in sequence.
   - Final sums are checked in eight temporary values before writeback. A nonzero returned status preserves the whole array; intermediate products must fit the selected precision.
   - After particle accumulation and shared-node summation, apply :doc:`average_axis <sub_B04_average_axis>` to a full-circle axis where present. Concurrent calls need separate buffers or synchronization.

   Geometry preparation validates complete coordinates; this per-particle entry checks local geometry and accessed data. Compile module and caller with the same default real precision.


   :doc:`B04 overview </rst_files/B_Scatter/B04_scatter_3Draz_nonuniform>` · :doc:`Usage example <usage>` · :doc:`Tests and results </tests/004_scatter/B04_scatter_3Draz_nonuniform>`

   .. raw:: html

      <details class="ap-b04-api">
      <summary>Generated API — source reference</summary>

   .. doxygenfile:: sub_B04_scatter_3Draz_nonuniform.f90

   .. raw:: html

      </details>
