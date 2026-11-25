Boundary Geometry
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J02_sn_boundary.f90`` 处理边界的位置与分类，不定义入口速度分布或壁面反射规律。
   它接收已建立的网格，求出下端环形入口与各单元面的交集，
   并提供读取、检查边界数据的辅助过程。几何边界准备正确后，才能在相应区域施加入流或反射条件。

   .. rubric:: 1. 面的编号、类型与入射方向

   每个有效单元有四个面，编号和外法向固定如下。

   .. list-table::
      :header-rows: 1
      :widths: 28 17 25 30

      * - 常量
        - 编号
        - 外法向 :math:`\boldsymbol n_f`
        - 入射条件
      * - ``SN_R_LO``
        - 1
        - :math:`(-1,0)`
        - :math:`\mu_m>0`
      * - ``SN_R_HI``
        - 2
        - :math:`(1,0)`
        - :math:`\mu_m<0`
      * - ``SN_Z_LO``
        - 3
        - :math:`(0,-1)`
        - :math:`\eta_m>0`
      * - ``SN_Z_HI``
        - 4
        - :math:`(0,1)`
        - :math:`\eta_m<0`

   面类型则表示数据从哪里来：INTERIOR 从相邻有效单元取值，
   OPEN 从给定的外部入流取值，WALL 从壁面反射关系取值。
   空间分区还使用 REMOTE，表示有效邻居在另一进程；数据来自本轮迎风通信，
   它不是新增物理边界条件。
   同一个 OPEN 面既允许入射也允许出射；所谓无外部入射的出口，是 OPEN 类型加零入流，
   出射粒子仍可自由离开计算域。

   判断当前速度是否入射使用
   :math:`\beta_{f,m}=\boldsymbol\Omega_m\cdot\boldsymbol n_f` 的符号。
   负值代表进入本单元，正值代表离开本单元。这一约定贯穿入口、壁面和 DG 组装。

   .. rubric:: 2. 下端部分入口的精确几何

   当前支持在第一排单元的轴向低端面上设置部分入口。
   给定物理入口径向范围 :math:`[r_{\min},r_{\max}]`，
   对第 :math:`i` 个径向单元求交集：

   .. math::

      r_L=\max(r_{i-1/2},r_{\min}),\qquad
      r_H=\min(r_{i+1/2},r_{\max}).

   若 :math:`r_H\leq r_L`，该面没有入口。否则，入口占完整轴向面的面积比例为

   .. math::

      \chi_i=
      \frac{\Theta\int_{r_L}^{r_H}r\,\mathrm dr}
           {\Theta\int_{r_{i-1/2}}^{r_{i+1/2}}r\,\mathrm dr}
      =\frac{r_H^2-r_L^2}{r_{i+1/2}^2-r_{i-1/2}^2}.

   这不是径向长度比例。程序还输出同一交集在局部坐标中的端点：

   .. math::

      \xi_L=\frac{r_L-r_c}{h_r},\qquad
      \xi_H=\frac{r_H-r_c}{h_r},\qquad -1\leq\xi_L\leq\xi_H\leq1.

   求入口总面积只需 :math:`\chi_i`：

   .. math::

      A_{\mathrm{in}}=\sum_{\text{有效 }(i,1)}\chi_iA_{z-,i,1}.

   但 DG 右端需要将检验函数也积分进去，仅有一个面积比例并不够。
   因此求解器接收 :math:`[\xi_L,\xi_H]`，在该区间施加入口条件，
   在其余两段 :math:`[-1,\xi_L]` 和 :math:`[\xi_H,1]` 施加壁面条件。
   这三段区间共同组成一个完整单元面。分别积分可保留入口的实际位置；
   若只将整面入流乘以面积比例，会丢失这个位置信息。

   .. figure:: /_static/J_Fluid/sn_partial_inlet.svg
      :alt: 单个下端面分成入口区间及两段反射壁面补集，入射分别积分
      :width: 900px

      入射条件由面内的位置决定，出射项覆盖整个面。
      后面的 DG 区间积分分别处理图中的三段；若入口贴到单元边缘，
      一侧补集长度为零，相应贡献自然为零。

   .. rubric:: 3. 入口构造过程

   ``sub_J02_build_partial_zlo_inlet`` —— 求入口与下端面的交集。

   - 输入 ``mesh``，以及 ``r_min``、``r_max``，单位 :math:`\mathrm m`。
     要求前者小于后者，且区间位于网格径向范围内。
   - 输出并分配三个长度为 ``nr`` 的实数数组：
     ``face_fraction`` 为 :math:`\chi_i`，
     ``xi_lo``、``xi_hi`` 为局部区间端点，均无量纲。
   - 无效的第一排单元或无交集单元输出零比例、零端点；零端点代表空区间，
     并不是在面中心设置了一个具有有限面积的入口。
   - 输出 ``ierr``。网格不完整、物理范围不合法或所有有效面均无交集时返回错误。
     本过程不修改 ``boundary``；得到比例后，还需调用 geometry 文件中的
     ``sub_J02_configure_zlo_partial_inlet_boundary`` 更新面类型。

   .. rubric:: 4. 边界读取过程

   ``fun_J02_face_type`` —— 读取指定面的整数类型。

   - 输入 ``boundary``、``face_id``、``i``、``k``；返回该面的类型。
   - 未知面编号返回 :math:`-1`。单元索引必须由调用者保证有效，
     不能把它作为数组越界检查器。

   ``fun_J02_has_reflecting_faces`` —— 判断有效单元是否有整面壁面标记。

   - 输入 ``mesh``、``boundary``；返回逻辑值。
   - 只统计有效单元的 WALL 标记。部分入口面可能标为 OPEN、却仍含壁面补集，
     所以完整求解接口还会依据是否传入部分入口区间，决定启用反射迭代。

   .. rubric:: 5. 后续模块使用哪些结果

   入口分布与归一化过程使用面外法向和总入口面积，
   但不需要知道每个交集端点。扫描和反射需要精确区间，
   以区分同一面上的开放部分和壁面部分。
   重构也必须接收相同区间，才能只统计真实开口上的逸出粒子率。
   当前没有实现任意面上任意多个分离入口区间；扩展这类几何时，
   边界构造、面积分和开放通量统计都应使用相同的入口区间。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J02_sn_boundary.f90`` handles boundary locations and classification. It takes an initialized mesh, intersects the lower
   annular inlet with each cell face, and supplies routines for inspecting and checking boundary data. Inlet
   velocity distributions and wall reflection laws are specified separately and applied to the regions
   identified here.

   .. rubric:: 1. Face numbering, face types and incoming directions

   Each active cell has four faces with the following fixed indices and outward normals.

   .. list-table::
      :header-rows: 1
      :widths: 28 17 25 30

      * - Constant
        - Index
        - Outward normal :math:`\boldsymbol n_f`
        - Incoming direction
      * - ``SN_R_LO``
        - 1
        - :math:`(-1,0)`
        - :math:`\mu_m>0`
      * - ``SN_R_HI``
        - 2
        - :math:`(1,0)`
        - :math:`\mu_m<0`
      * - ``SN_Z_LO``
        - 3
        - :math:`(0,-1)`
        - :math:`\eta_m>0`
      * - ``SN_Z_HI``
        - 4
        - :math:`(0,1)`
        - :math:`\eta_m<0`

   The face type identifies where incoming data come from. INTERIOR reads the adjacent active cell, OPEN
   uses the prescribed exterior inflow, and WALL uses the reflection relation. In spatially partitioned
   runs, REMOTE identifies an active neighbour on another process whose data arrive during the current
   upwind sweep. An OPEN face permits both inflow and outflow. An open outlet with zero external inflow
   therefore lets outgoing particles leave freely.

   The sign of :math:`\beta_{f,m}=\boldsymbol\Omega_m\cdot\boldsymbol n_f` determines whether the current velocity enters the cell. Negative values are incoming and
   positive values are outgoing. Inlet, wall and DG assembly routines all use this convention.

   .. rubric:: 2. Exact geometry of a partial lower inlet

   A partial inlet can be placed on the lower axial faces of the first cell row. Given the physical radial
   interval :math:`[r_{\min},r_{\max}]`, intersect it with radial cell :math:`i`.

   .. math::

      r_L=\max(r_{i-1/2},r_{\min}),\qquad
      r_H=\min(r_{i+1/2},r_{\max}).

   For :math:`r_H\leq r_L` there is no inlet on the face. Otherwise the inlet occupies the following fraction of the full
   axial face area.

   .. math::

      \chi_i=
      \frac{\Theta\int_{r_L}^{r_H}r\,\mathrm dr}
           {\Theta\int_{r_{i-1/2}}^{r_{i+1/2}}r\,\mathrm dr}
      =\frac{r_H^2-r_L^2}{r_{i+1/2}^2-r_{i-1/2}^2}.

   The fraction accounts for the radial variation in area. The routine also returns the endpoints of the
   same intersection in local coordinates.

   .. math::

      \xi_L=\frac{r_L-r_c}{h_r},\qquad
      \xi_H=\frac{r_H-r_c}{h_r},\qquad -1\leq\xi_L\leq\xi_H\leq1.

   The fraction :math:`\chi_i` suffices to calculate the total inlet area.

   .. math::

      A_{\mathrm{in}}=\sum_{\text{active }(i,1)}\chi_iA_{z-,i,1}.

   The DG right-hand side also integrates the test functions, so it needs the location of the opening. The
   solver applies the inlet condition on :math:`[\xi_L,\xi_H]` and the wall condition on the complementary intervals :math:`[-1,\xi_L]` and :math:`[\xi_H,1]`.
   Together these intervals cover the full face. Integrating them separately retains information that would
   be lost by multiplying the whole-face inflow by a single area fraction.

   .. figure:: ../../../images/J_Fluid/sn_partial_inlet_en.svg
      :alt: Lower face split into an inlet interval and two reflecting wall segments, each with its own incoming integral
      :width: 900px

      The incoming condition depends on position along the face. The outgoing term covers the whole face.
      The DG face integrals use the three intervals shown. Where an inlet reaches a cell edge, the adjacent
      wall segment has zero length and contributes zero.

   .. rubric:: 3. Constructing the inlet

   ``sub_J02_build_partial_zlo_inlet`` finds the intersection of the inlet and the lower faces.

   - Inputs are ``mesh`` and the interval bounds ``r_min`` and ``r_max`` in :math:`\mathrm m`. The first bound must be less than the second,
     and both must lie within the radial extent of the mesh.
   - The routine allocates three dimensionless real arrays of length ``nr``. ``face_fraction`` contains :math:`\chi_i`, and ``xi_lo`` and ``xi_hi`` are
     the local interval endpoints.
   - For an inactive cell in the first row or a face without an intersection, the fraction and both
     endpoints are zero. Those endpoints denote an empty interval and give zero inlet area.
   - Output ``ierr`` reports an incomplete mesh, invalid physical interval or an inlet that misses every active
     face. The routine leaves ``boundary`` unchanged. After obtaining the fractions, call ``sub_J02_configure_zlo_partial_inlet_boundary`` in the geometry file to
     update the face types.

   .. rubric:: 4. Reading boundary data

   ``fun_J02_face_type`` returns the integer type of a specified face.

   - Inputs are ``boundary``, ``face_id``, ``i`` and ``k``. The return value is the face type.
   - An unknown face index gives :math:`-1`. The caller must supply valid cell indices, since this routine does not
     check their bounds.

   ``fun_J02_has_reflecting_faces`` tests whether any active cell has a whole face marked as a wall.

   - Inputs are ``mesh`` and ``boundary``. The result is logical.
   - The routine checks WALL markers on active cells. A partial inlet may have an OPEN marker and still
     contain a reflecting wall segment, so the full solver also checks whether partial inlet intervals were
     supplied when deciding to enable reflection iteration.

   .. rubric:: 5. Using the results downstream

   Inlet distribution and normalization use the outward normal and total inlet area and do not require the
   intersection endpoints. Sweeping and reflection need the exact intervals to distinguish openings from
   wall segments on the same face. Reconstruction must use those intervals to count escaping particles only
   over the physical opening. The current geometry supports one connected lower-face inlet interval. An
   extension to multiple disjoint intervals on arbitrary faces would need consistent intervals in boundary
   construction, face integration and open-flux diagnostics.
