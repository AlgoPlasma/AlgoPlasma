sub_B04_build_geometry
======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-b04-doc

   .. admonition:: 输入 → 几何积分 → 直接输出

      **输入：** 三组节点坐标及角向周期设置。

      **处理：** 逐单元积分节点线性基函数与柱坐标体积元。

      **输出：** 覆写 ``inv_volume=1/V`` ，供沉积使用；覆写 ``phi_measure`` ，供轴点平均使用。

   .. code-block:: fortran

      call sub_B04_build_geometry(r, phi, z, periodic_phi, &
          inv_volume, phi_measure, ierr)

   .. _b04-matching-volume-zh:

   .. rubric:: 为什么节点体积要与分配权重配套？

   沉积用节点形函数 :math:`S_{ijk}` 分配粒子数或电荷，再除以有效节点体积得到密度。
   可以从一个明确的要求确定这个体积：**均匀物理密度在非均匀网格上也应恢复为相同的密度值。**

   设连续物理密度为常数 :math:`D_0`，节点接收到的分配量为 :math:`M_{ijk}`。
   按同一形函数分配整个物理域中的贡献，得到

   .. math::

      M_{ijk}=\int_\Omega D_0 S_{ijk}\,dV
             =D_0\int_\Omega S_{ijk}\,r\,dr\,d\phi\,dz.

   因而取

   .. math::

      V_{ijk}=\int_\Omega S_{ijk}\,r\,dr\,d\phi\,dz,
      \qquad D_{ijk}=\frac{M_{ijk}}{V_{ijk}}=D_0.

   **有效节点体积是该节点形函数覆盖区域内的加权体积**，其范围包括节点相邻的单元。
   计算实际粒子密度时，:math:`M_{ijk}` 由粒子分配量求和得到；有限随机粒子会带来采样波动。
   现有 :ref:`均匀密度恢复测试 <b04-test-constant-density-zh>` 使用确定性积分贡献，检查这一配套关系。

   .. _b04-radial-support-zh:

   .. rubric:: 左右单元不等宽，径向积分怎样变化？

   考察一个 **内部径向节点** :math:`r_i`。它的形函数在该节点为一，在两个相邻节点为零，
   中间按直线变化；这两段所在的单元共同提供节点的径向积分。

   .. figure:: /images/B_Scatter/B04_scatter_3d_raz_nonuniform/radial_support_zh.svg
      :alt: 径向线性形函数的对照：左图两个相邻单元等宽，右图右侧单元为左侧的两倍宽；两图节点形函数的峰值均为一
      :width: 100%

      横轴为径向坐标，竖线标出网格节点及相邻径向区间的分界。阴影表示形函数的非零范围；径向有效体积因子还需在积分中乘以半径 r。

   记左右宽度为 :math:`h_-=r_i-r_{i-1}` 和 :math:`h_+=r_{i+1}-r_i`，则

   .. math::

      R_i=\int_{r_{i-1}}^{r_i}\frac{r-r_{i-1}}{h_-}\,r\,dr
         +\int_{r_i}^{r_{i+1}}\frac{r_{i+1}-r}{h_+}\,r\,dr.

   两段分别给出 :math:`r_i h_-/2-h_-^2/6` 和 :math:`r_i h_+/2+h_+^2/6`。相加得到

   .. math::

      \boxed{R_i=\frac{r_i(h_-+h_+)}{2}+\frac{h_+^2-h_-^2}{6}}.

   - **均匀网格：** :math:`h_-=h_+=h`，平方项抵消，得到 :math:`R_i=r_i h`。这与 B02 电荷沉积中内部径向节点的体积因子一致。
   - **非均匀网格：** 左右宽度不同时，保留两侧积分的差异项。例如图中 :math:`r_{i-1},r_i,r_{i+1}=1,2,4` m，得到 :math:`R_i=3+0.5=3.5\ \mathrm{m}^2`。

   上式适用于两侧都有单元的内部节点。物理端点仅积分域内的一侧；从轴线开始时，首个单元给出
   :math:`R_0=(r_1-r_0)^2/6`，其中 :math:`r_0=0`，因此轴节点具有有限的正有效体积。

   .. _b04-geometry-assembly-zh:

   .. rubric:: 为什么可以先算一维几何量，再供沉积复用？

   本网格由三组一维坐标组合构成，节点形函数也可写为
   :math:`S_{ijk}=S_i^r(r)S_j^\phi(\phi)S_k^z(z)`。在本接口的张量积区域内，体积积分分解为

   .. math::

      R_i=\int S_i^r(r)\,r\,dr,\qquad
      A_j=\int S_j^\phi(\phi)\,d\phi,\qquad
      Z_k=\int S_k^z(z)\,dz,\qquad V_{ijk}=R_iA_jZ_k.

   各积分覆盖该节点形函数在物理域内的非零范围；周期接缝处合并两端贡献。
   **这三个因子由网格决定，可以在粒子循环之前计算。** 本例程保存三维逆体积，
   :ref:`沉积例程 <b04-local-weights-zh>` 随后只需按粒子位置计算权重并乘以该逆体积。

   为统一处理内部节点和物理端点，代码按 **逐单元计算 → 分别累加到左右节点 → 组合三个方向** 的顺序组织。
   径向单元 :math:`[r_L,r_R]` 的宽度为 :math:`h=r_R-r_L`，它给左右节点的贡献为

   .. math::

      \int_{r_L}^{r_R}\frac{r_R-r}{h}\,r\,dr=\frac{h(2r_L+r_R)}6,\qquad
      \int_{r_L}^{r_R}\frac{r-r_L}{h}\,r\,dr=\frac{h(r_L+2r_R)}6.

   下列循环把这两个积分分别加到 ``vr(i)`` 和 ``vr(i+1)``；同一内部节点会收到相邻两个单元的贡献。
   ``na`` 是角向单元数 ``nphi``。局部变量 ``h`` 在径向循环中保存完整单元宽度，
   在角向循环中改为半个角宽，用于分别累加两端的积分。

   .. literalinclude:: ../../../../../B_Scatter/B04_scatter_3d_raz_nonuniform/sub_B04_build_geometry.f90
      :language: fortran
      :start-at:     do i = 0, size(r)-2
      :end-at:     if (periodic_phi) va(0) = va(0)+va(na)

   ``vr`` 对应 :math:`R_i`，``va`` 对应 :math:`A_j`，``vz`` 对应 :math:`Z_k`；量纲分别为长度平方、弧度、长度。
   角向和轴向积分的每个单元向两端各提供半个坐标宽度。最后写出 ``inv_volume=1/(vr*va*vz)``，
   并把独立角节点的 ``va`` 写入 ``phi_measure``，供 :doc:`轴点加权平均 <sub_B04_average_axis>` 使用。

   回看 :ref:`B04 的构造思路 <b04-grid-difference-zh>` · 继续阅读 :ref:`粒子位置到分配权重 <b04-local-weights-zh>`。

   .. rubric:: 参数与储存约定

   .. list-table::
      :header-rows: 1
      :widths: 23 13 64

      * - 参数
        - 方向
        - 形状、含义与单位
      * - ``r, phi, z``
        - in
        - ``(0:nr), (0:nphi), (0:nz)`` ；有限且严格递增，每向至少一个单元，``r(0)>=0`` ；半径/轴向同长度单位，角度 rad
      * - ``periodic_phi``
        - in
        - logical；真时合并角向两端点。坐标数组仍包含两个端点
      * - ``inv_volume``
        - inout
        - 已分配；周期 ``(0:nr,0:nphi-1,0:nz)`` ，非周期 ``(0:nr,0:nphi,0:nz)`` ；长度为 m 时单位为 :math:`\mathrm{m}^{-3}`
      * - ``phi_measure``
        - inout
        - 周期 ``(0:nphi-1)`` ，非周期 ``(0:nphi)`` ；单位 rad，供轴点加权
      * - ``ierr``
        - out
        - 整数；检查 :ref:`公共状态码 <b04-status-zh>`

   ``inout`` 输出成功时全部覆写，初值不参与计算；返回非零状态时两个数组保留原值。
   数组实参的首元素映射为例程内索引零。所有数组按物理节点范围传入；无额外外侧节点要求。

   .. rubric:: 端点、周期和并行分区

   - 径向、轴向和非周期角向端点只计域内一侧的基函数支撑。
   - 角向周期时，末端节点的积分加入零号节点；即使仅一个角单元，也保留来自两个端点的积分。
   - MPI 接口节点需包括接口两侧支撑。调用方可由全局几何准备完整体积，再按本地索引分发；共享节点贡献使用相同体积。
   - 检查包括全部坐标、形状和体积的有限性与可求倒数范围。网格或拓扑变化后重新调用；编译精度与调用方一致。


   返回 :doc:`B04 总览 </rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform>` · :doc:`调用示例 <usage>` · :doc:`测试与结果 </tests/004_scatter/B04_scatter_3d_raz_nonuniform>`

.. container:: ap-lang ap-lang-en ap-b04-doc

   .. admonition:: Inputs → geometry integrals → outputs

      **Inputs:** three node arrays and angular topology.

      **Operation:** integrate linear nodal bases with the cylindrical volume measure.

      **Outputs:** replaces ``inv_volume=1/V`` for scatter and ``phi_measure`` for axis averaging.

   .. code-block:: fortran

      call sub_B04_build_geometry(r, phi, z, periodic_phi, &
          inv_volume, phi_measure, ierr)

   .. _b04-matching-volume-en:

   .. rubric:: Why must volume match the assignment basis?

   Deposition assigns number or charge with a nodal basis :math:`S_{ijk}`, then divides by an effective volume to obtain density.
   A physical requirement determines this volume: **a constant physical density should retain its value on a nonuniform mesh.**

   Let :math:`D_0` be a constant continuous density and :math:`M_{ijk}` the amount assigned to a node.
   Integrating contributions from the physical domain with this basis gives

   .. math::

      M_{ijk}=\int_\Omega D_0 S_{ijk}\,dV
             =D_0\int_\Omega S_{ijk}\,r\,dr\,d\phi\,dz.

   Choose

   .. math::

      V_{ijk}=\int_\Omega S_{ijk}\,r\,dr\,d\phi\,dz,
      \qquad D_{ijk}=\frac{M_{ijk}}{V_{ijk}}=D_0.

   **The effective nodal volume is the physical volume weighted by that node's basis**, over its neighboring cells.
   For particles, :math:`M_{ijk}` is a sum of assigned amounts; finite random samples introduce sampling fluctuations.
   The existing :ref:`constant-density recovery test <b04-test-constant-density-en>` uses deterministic quadrature contributions to check the matching relation.

   .. _b04-radial-support-en:

   .. rubric:: How do unequal adjacent widths change the radial integral?

   Consider an **interior radial node** :math:`r_i`. Its basis equals one there and zero at the two neighboring nodes,
   with linear variation between them. Both adjacent cells contribute to its radial integral.

   .. figure:: /images/B_Scatter/B04_scatter_3d_raz_nonuniform/radial_support_en.svg
      :alt: Radial linear bases: equal adjacent widths on the left, and a right cell twice as wide on the right; both nodal bases peak at one
      :width: 100%

      The horizontal axis is radius; vertical lines mark nodes and the boundaries of adjacent radial intervals. Shading shows the basis support. The effective radial measure also includes radius as a factor in the integral.

   Write :math:`h_-=r_i-r_{i-1}` and :math:`h_+=r_{i+1}-r_i`. Then

   .. math::

      R_i=\int_{r_{i-1}}^{r_i}\frac{r-r_{i-1}}{h_-}\,r\,dr
         +\int_{r_i}^{r_{i+1}}\frac{r_{i+1}-r}{h_+}\,r\,dr.

   The two terms are :math:`r_i h_-/2-h_-^2/6` and :math:`r_i h_+/2+h_+^2/6`. Their sum is

   .. math::

      \boxed{R_i=\frac{r_i(h_-+h_+)}{2}+\frac{h_+^2-h_-^2}{6}}.

   - **Uniform spacing:** :math:`h_-=h_+=h` cancels the squared terms, giving :math:`R_i=r_i h`, as used for interior radial nodes by the B02 charge routine.
   - **Nonuniform spacing:** unequal widths retain the difference between the two integrals. For the illustrated nodes :math:`r_{i-1},r_i,r_{i+1}=1,2,4` m, :math:`R_i=3+0.5=3.5\ \mathrm{m}^2`.

   This expression applies to interior nodes with cells on both sides. A physical endpoint receives the integral from inside the domain.
   At :math:`r_0=0`, the first cell contributes :math:`R_0=(r_1-r_0)^2/6`, giving a finite positive axis volume.

   .. _b04-geometry-assembly-en:

   .. rubric:: Why prepare one-dimensional geometry before deposition?

   Three one-dimensional coordinate arrays form this mesh, and the basis factors as
   :math:`S_{ijk}=S_i^r(r)S_j^\phi(\phi)S_k^z(z)`. Over the tensor-product domain used by this interface,

   .. math::

      R_i=\int S_i^r(r)\,r\,dr,\qquad
      A_j=\int S_j^\phi(\phi)\,d\phi,\qquad
      Z_k=\int S_k^z(z)\,dz,\qquad V_{ijk}=R_iA_jZ_k.

   Each integral covers the basis support inside the physical domain; periodic endpoints combine their contributions.
   **These factors depend only on the mesh and can be computed before the particle loop.** This routine stores inverse volumes;
   the :ref:`scatter routine <b04-local-weights-en>` then computes weights from each particle position and multiplies by those inverse volumes.

   The implementation handles interior nodes and physical endpoints by **integrating each cell → adding to its endpoint nodes → combining the three directions**.
   For a radial cell :math:`[r_L,r_R]` of width :math:`h=r_R-r_L`, the endpoint contributions are

   .. math::

      \int_{r_L}^{r_R}\frac{r_R-r}{h}\,r\,dr=\frac{h(2r_L+r_R)}6,\qquad
      \int_{r_L}^{r_R}\frac{r-r_L}{h}\,r\,dr=\frac{h(r_L+2r_R)}6.

   The loop adds these two integrals to ``vr(i)`` and ``vr(i+1)``; an interior node receives contributions from both adjacent cells.
   ``na`` is the angular cell count ``nphi``. The local variable ``h`` holds the full radial cell width
   in the radial loop, then half the angular width in the angular loop for the two endpoint integrals.

   .. literalinclude:: ../../../../../B_Scatter/B04_scatter_3d_raz_nonuniform/sub_B04_build_geometry.f90
      :language: fortran
      :start-at:     do i = 0, size(r)-2
      :end-at:     if (periodic_phi) va(0) = va(0)+va(na)

   ``vr``, ``va`` and ``vz`` correspond to :math:`R_i`, :math:`A_j` and :math:`Z_k`, with units of length squared, radians and length.
   Angular and axial cells contribute half their coordinate width to each endpoint. The routine writes ``inv_volume=1/(vr*va*vz)``
   and the independent angular entries of ``va`` to ``phi_measure`` for :doc:`axis averaging <sub_B04_average_axis>`.

   Return to :ref:`B04 construction <b04-grid-difference-en>` · Continue to :ref:`particle positions and weights <b04-local-weights-en>`.

   .. rubric:: Parameters and layout

   .. list-table::
      :header-rows: 1
      :widths: 23 13 64

      * - Parameter
        - Direction
        - Shape, meaning and units
      * - ``r, phi, z``
        - in
        - ``(0:nr), (0:nphi), (0:nz)``; finite and strictly increasing; at least one cell per direction; ``r(0)>=0``; common length unit and radians
      * - ``periodic_phi``
        - in
        - logical; identifies angular endpoints; the coordinate array keeps both
      * - ``inv_volume``
        - inout
        - Preallocated; periodic ``(0:nr,0:nphi-1,0:nz)``, otherwise ``(0:nr,0:nphi,0:nz)``; :math:`\mathrm{m}^{-3}` for metre coordinates
      * - ``phi_measure``
        - inout
        - Periodic ``(0:nphi-1)``, otherwise ``(0:nphi)``; angular basis integrals in rad
      * - ``ierr``
        - out
        - Integer :ref:`shared status <b04-status-en>`

   Output initial values are unused; success overwrites both arrays and a nonzero returned status preserves them.
   The first actual element maps to index zero. Pass physical-node extents; no additional exterior nodes are required.

   .. rubric:: Endpoints and partitioning

   - Physical endpoints receive support from inside the domain.
   - Periodic node zero receives the last endpoint contribution, including when one angular cell has only one independent angular node.
   - MPI interfaces require complete support from both sides. One option is to prepare global geometry and distribute the matching complete volumes to local nodes.
   - Checks cover coordinates, shapes, finite volumes and the reciprocal range. Rebuild on mesh/topology changes and compile with the caller's real precision.


   :doc:`B04 overview </rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform>` · :doc:`Usage example <usage>` · :doc:`Tests and results </tests/004_scatter/B04_scatter_3d_raz_nonuniform>`

   .. raw:: html

      <details class="ap-b04-api">
      <summary>Generated API — source reference</summary>

   .. doxygenfile:: sub_B04_build_geometry.f90

   .. raw:: html

      </details>
