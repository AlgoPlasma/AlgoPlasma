.. J_Fluid contribution history (Git author dates; edit times include timezone).
   2026-09-18 12:00 +08:00 | Yingjie Chen | git 69bdc8603906
   2026-10-06 23:50 +08:00 | Yingjie Chen | git fa8cb9f5be05
   2026-10-23 10:58 +08:00 | Yingjie Chen | git cd0d957281af
   2026-11-25 15:14 +08:00 | Yingjie Chen | git 8652258184b5
   2026-11-25 15:59 +08:00 | Yingjie Chen | edit (Codex-assisted)

Mesh and Geometry
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   ``sub_J02_sn_geometry.f90`` 根据径向、轴向边界坐标和有效单元标记，
   计算单元中心、半宽、体积、面面积及径向平均系数。
   这些量分别用于 DG 矩阵积分、入口区间计算和密度、通量重构。

   .. rubric:: 1. 张量积网格与有效单元

   当前方法使用径向、轴向分别划分的矩形截面网格，允许非均匀间距。
   令径向边界为 :math:`r_{i-1/2},r_{i+1/2}`，
   轴向边界为 :math:`z_{k-1/2},z_{k+1/2}`。单元 :math:`K=(i,k)` 的中心和半宽为

   .. math::

      r_c=\frac{r_{i-1/2}+r_{i+1/2}}2,\quad
      h_r=\frac{r_{i+1/2}-r_{i-1/2}}2,\qquad
      z_c=\frac{z_{k-1/2}+z_{k+1/2}}2,\quad
      h_z=\frac{z_{k+1/2}-z_{k-1/2}}2.

   有效标记 ``active(i,k)`` 决定这个单元是否参加输运。
   无效单元位于计算域之外；与它相邻的有效单元面默认标为壁面。

   为在不同大小的单元上使用同一组基函数，引入无量纲局部坐标：

   .. math::

      \xi=\frac{r-r_c}{h_r},\qquad
      \zeta=\frac{z-z_c}{h_z},\qquad
      -1\leq\xi,\zeta\leq1.

   这里的 :math:`\xi,\zeta` 在后面的空间多项式、面区间和矩阵积分中含义不变。
   ``geometry`` 存储径向中心和两方向半宽；不存储轴向中心，
   因为当前局部算子的积分只需要半宽。

   .. rubric:: 2. 单元体积与面面积

   矩形是 :math:`r`–:math:`z` 截面；绕轴展开周向张角 :math:`\Theta` 后，
   它对应一个环形体积。柱坐标微元为
   :math:`\mathrm dV=r\,\mathrm dr\,\mathrm d\varphi\,\mathrm dz`。
   对物理周向角 :math:`\varphi` 积分后，

   .. math::

      V_K=\Theta\int_{z_{k-1/2}}^{z_{k+1/2}}
                      \int_{r_{i-1/2}}^{r_{i+1/2}}r\,\mathrm dr\,\mathrm dz
          =4\Theta r_ch_rh_z.

   积分中的 :math:`r` 来自柱坐标体积元。
   完整一圈取 :math:`\Theta=2\pi`；扇区模型使用实际张角。
   体积单位为 :math:`\mathrm{m^3}`。

   径向面上半径固定，轴向面上轴向坐标固定，故四个物理面积分别为

   .. math::

      \begin{aligned}
      A_{r-}&=\Theta(r_c-h_r)\int_{z_{k-1/2}}^{z_{k+1/2}}\mathrm dz
             =2\Theta(r_c-h_r)h_z,\\
      A_{r+}&=2\Theta(r_c+h_r)h_z,\\
      A_{z-}=A_{z+}&=\Theta\int_{r_{i-1/2}}^{r_{i+1/2}}r\,\mathrm dr
             =2\Theta r_ch_r.
      \end{aligned}

   面通量乘相应物理面积得到粒子率，单位为 :math:`\mathrm{s^{-1}}`。

   .. rubric:: 3. 一次多项式的体积平均

   后续求解的单元内分布写成
   :math:`\psi_m=c_0+c_1\xi+c_2\zeta`。
   重构密度需要计算它的物理体积平均。
   将坐标变换代入体积分，有

   .. math::

      \overline{\xi}
        =\frac{\int_{-1}^{1}\int_{-1}^{1}
                     \xi(r_c+h_r\xi)\,\mathrm d\xi\,\mathrm d\zeta}
               {\int_{-1}^{1}\int_{-1}^{1}
                     (r_c+h_r\xi)\,\mathrm d\xi\,\mathrm d\zeta}
        =\frac{(2h_r/3)\,2}{(2r_c)\,2}
        =\frac{h_r}{3r_c},\qquad
      \overline{\zeta}=0.

   于是

   .. math::

      \overline{\psi}_{K,m}=c_0+\frac{h_r}{3r_c}c_1.

   ``xi_bar(i)`` 保存 :math:`h_r/(3r_c)`。即使局部坐标区间对称，
   柱坐标体积平均也一般不等于 :math:`c_0`；径向外侧的物理体积更大。

   .. rubric:: 4. 各过程的输入、输出与职责

   ``sub_J02_initialize_mesh`` —— 检查并保存网格。

   - 输入 ``r_edge(nr+1)``、``z_edge(nz+1)``：实数边界坐标，单位 :math:`\mathrm m`。
     两者至少各有两个元素，严格递增，首个径向边界非负。
   - 输入 ``active(nr,nz)``：逻辑数组，表示参加计算的单元。
   - 输出 ``mesh``：保存维数、坐标的副本和有效标记。
   - 输出 ``ierr``：成功为零；坐标数量、标记尺寸、负半径或坐标顺序错误分别报告。
     调用者必须检查成功后再使用 ``mesh``。

   ``sub_J02_build_geometry`` —— 由网格计算上述几何量。

   - 输入 ``mesh``、``theta_span``：已初始化网格与正的周向张角。
     当前代码只检查张角大于零，没有实施不大于 :math:`2\pi` 的限制。
   - 输出 ``geometry%rc/hr/xi_bar(nr)``、``hz(nz)``：
     径向中心、半宽、径向平均系数与轴向半宽。
   - 输出 ``volume(nr,nz)`` 和四个 ``area_*(nr,nz)``：
     单位分别为 :math:`\mathrm{m^3}`、:math:`\mathrm{m^2}`。
     无效单元的体积设为零；其面面积仍按坐标计算，因此使用时仍须检查 ``active``。
   - 输出 ``ierr``：网格不完整或张角非正时返回错误。

   ``sub_J02_initialize_boundary_types`` —— 建立初始面类型。

   - 输入 ``mesh``；输出 ``boundary`` 中四个整数数组，尺寸均为 ``(nr,nz)``。
   - 可选输入 ``partition``：MPI 空间分区信息。提供时本过程为集体调用；
     相邻进程的有效单元之间设为 ``SN_FACE_REMOTE``，邻接无效区域仍设为 WALL。
     不提供时使用下述单域分类。分区初始化与数据约定在 13 页说明。
   - 有效单元之间的相邻面设为 ``SN_FACE_INTERIOR``；
     计算网格外边界设为 ``SN_FACE_OPEN``；
     有效单元旁的无效区域设为 ``SN_FACE_WALL``。
   - 所有数组先初始化为壁面，无效单元不继续分类。
     这只是初始面类型，应用仍需把实际反射壁显式设置为壁面。
   - 输出 ``ierr``：报告面类型初始化是否成功。

   ``sub_J02_configure_zlo_partial_inlet_boundary`` —— 根据开口比例更新下端面类型。

   - 输入 ``mesh``、``face_fraction(nr)``，后者为 :math:`[0,1]` 内的面积比例。
   - 输入并修改 ``boundary``：对有效的第一排单元，正比例设为 OPEN，
     零比例设为 WALL；其他面保持原值。
   - 输出 ``ierr``。它只修改整面标记，不保存面内分界；
     部分开口的精确区间必须另外传入求解器，不能只传面积比例。

   .. rubric:: 5. 本文件在计算流程中的位置

   输入边界坐标之后，先初始化网格，再构建几何，随后建立初始面类型。
   下一步的速度求积与空间网格独立；边界几何则使用这里的坐标求入口区间。
   DG 积分使用 :math:`r_c,h_r,h_z`，重构使用 :math:`\overline{\xi}`，
   粒子率统计使用 :math:`V_K,A_f`，三者不能各自采用不同的几何约定。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   ``sub_J02_sn_geometry.f90`` uses radial and axial edge coordinates and the active-cell mask to compute cell centres, half-widths,
   volumes, face areas and a radial averaging coefficient. The DG integrals, inlet intersections and
   reconstruction of density and flux use these quantities.

   .. rubric:: 1. Tensor-product mesh and active cells

   The mesh has rectangular cross-sections formed by independent radial and axial subdivisions. The spacing
   can vary in either direction. With radial edges :math:`r_{i-1/2},r_{i+1/2}` and axial edges :math:`z_{k-1/2},z_{k+1/2}`, the centre and half-widths of cell
   :math:`K=(i,k)` are

   .. math::

      r_c=\frac{r_{i-1/2}+r_{i+1/2}}2,\quad
      h_r=\frac{r_{i+1/2}-r_{i-1/2}}2,\qquad
      z_c=\frac{z_{k-1/2}+z_{k+1/2}}2,\quad
      h_z=\frac{z_{k+1/2}-z_{k-1/2}}2.

   The mask ``active(i,k)`` determines whether a cell participates in transport. An inactive cell lies outside the
   computational domain. A face of an active cell bordering an inactive cell defaults to a wall.

   Dimensionless local coordinates allow the same basis functions to be used on cells of different sizes.

   .. math::

      \xi=\frac{r-r_c}{h_r},\qquad
      \zeta=\frac{z-z_c}{h_z},\qquad
      -1\leq\xi,\zeta\leq1.

   The same :math:`\xi,\zeta` are used in the spatial polynomial, face intervals and matrix integrals. ``geometry`` stores the radial
   centre and both half-widths. The axial centre can be omitted because the local operator integrals only
   need the axial half-width.

   .. rubric:: 2. Cell volume and face areas

   Rotating the rectangular :math:`r`–:math:`z` cross-section through the azimuthal extent :math:`\Theta` produces an annular volume.
   The differential volume is :math:`\mathrm dV=r\,\mathrm dr\,\mathrm d\varphi\,\mathrm dz`. Integration over physical azimuth :math:`\varphi` gives

   .. math::

      V_K=\Theta\int_{z_{k-1/2}}^{z_{k+1/2}}
                      \int_{r_{i-1/2}}^{r_{i+1/2}}r\,\mathrm dr\,\mathrm dz
          =4\Theta r_ch_rh_z.

   The factor :math:`r` comes from the cylindrical volume element. Use :math:`\Theta=2\pi` for a full revolution and the actual
   subtended angle for a sector. Volume has units of :math:`\mathrm{m^3}`.

   On a radial face the radius is constant, and on an axial face the axial coordinate is constant. The four
   physical face areas are therefore

   .. math::

      \begin{aligned}
      A_{r-}&=\Theta(r_c-h_r)\int_{z_{k-1/2}}^{z_{k+1/2}}\mathrm dz
             =2\Theta(r_c-h_r)h_z,\\
      A_{r+}&=2\Theta(r_c+h_r)h_z,\\
      A_{z-}=A_{z+}&=\Theta\int_{r_{i-1/2}}^{r_{i+1/2}}r\,\mathrm dr
             =2\Theta r_ch_r.
      \end{aligned}

   Multiplying a face flux by the corresponding physical area gives a particle rate in :math:`\mathrm{s^{-1}}`.

   .. rubric:: 3. Volume average of a linear polynomial

   The cell solution has the form :math:`\psi_m=c_0+c_1\xi+c_2\zeta`. Density reconstruction requires its physical volume average. Applying
   the coordinate transformation in the volume integral gives

   .. math::

      \overline{\xi}
        =\frac{\int_{-1}^{1}\int_{-1}^{1}
                     \xi(r_c+h_r\xi)\,\mathrm d\xi\,\mathrm d\zeta}
               {\int_{-1}^{1}\int_{-1}^{1}
                     (r_c+h_r\xi)\,\mathrm d\xi\,\mathrm d\zeta}
        =\frac{(2h_r/3)\,2}{(2r_c)\,2}
        =\frac{h_r}{3r_c},\qquad
      \overline{\zeta}=0.

   It follows that

   .. math::

      \overline{\psi}_{K,m}=c_0+\frac{h_r}{3r_c}c_1.

   ``xi_bar(i)`` stores :math:`h_r/(3r_c)`. The radially outer side of the cell occupies more physical volume, so the cylindrical
   volume average can differ from :math:`c_0` even though the local coordinate interval is symmetric.

   .. rubric:: 4. Routine responsibilities, inputs and outputs

   ``sub_J02_initialize_mesh`` validates and stores the mesh.

   - Inputs ``r_edge(nr+1)`` and ``z_edge(nz+1)`` are real edge coordinates in :math:`\mathrm m`. Each array must have at least two strictly increasing
     elements. The first radial edge must be nonnegative.
   - Input ``active(nr,nz)`` is a logical array marking the cells that participate in the calculation.
   - Output ``mesh`` stores the dimensions, copies of the coordinates and the active-cell mask.
   - Output ``ierr`` is zero on success. Separate errors identify insufficient coordinates, a mask shape mismatch,
     a negative radius or invalid coordinate ordering. Check the result before using ``mesh``.

   ``sub_J02_build_geometry`` computes the geometry from the mesh.

   - Inputs ``mesh`` and ``theta_span`` are the initialized mesh and a positive azimuthal extent. The implementation checks
     positivity and imposes no upper bound of :math:`2\pi`.
   - Outputs ``geometry%rc/hr/xi_bar(nr)`` and ``hz(nz)`` hold radial centres, radial half-widths, radial averaging coefficients and axial
     half-widths.
   - Outputs ``volume(nr,nz)`` and the four ``area_*(nr,nz)`` arrays have units of :math:`\mathrm{m^3}` and :math:`\mathrm{m^2}`, respectively. Inactive cells have zero
     volume. Their face areas are still computed from the coordinates, so users of those areas must check
     ``active``.
   - Output ``ierr`` reports an incomplete mesh or nonpositive azimuthal extent.

   ``sub_J02_initialize_boundary_types`` assigns the initial face types.

   - Input ``mesh`` supplies the mesh. Output ``boundary`` contains four integer arrays of shape ``(nr,nz)``.
   - Optional input ``partition`` supplies the MPI spatial partition. With this argument the routine is collective. A
     face between active cells on neighbouring processes is marked ``SN_FACE_REMOTE``, and a face adjacent to an inactive
     region remains WALL. Without a partition the single-domain rules below apply. Page 13 describes
     partition initialization and data conventions.
   - Faces between active cells are ``SN_FACE_INTERIOR``. Outer mesh faces are ``SN_FACE_OPEN``. An active cell facing an inactive region
     has a face of type ``SN_FACE_WALL``.
   - All arrays are initially set to wall, and inactive cells receive no further classification. The
     application must explicitly set any physical reflecting walls on the outer mesh boundary.
   - Output ``ierr`` reports the result of face-type initialization.

   ``sub_J02_configure_zlo_partial_inlet_boundary`` updates lower-face types from the open area fraction.

   - Inputs are ``mesh`` and ``face_fraction(nr)``. The latter is an area fraction in :math:`[0,1]`.
   - Input/output ``boundary`` is updated on the first row of active cells. A positive fraction sets the lower face to
     OPEN and zero sets it to WALL. Other faces retain their previous values.
   - Output ``ierr`` reports status. The routine changes whole-face markers only. Pass the exact within-face
     interval separately to the solver for a partial inlet, since the area fraction alone does not specify
     its location.

   .. rubric:: 5. Geometry in the calculation

   Start with the edge coordinates, initialize the mesh, build the geometry and assign initial face types.
   Velocity quadrature is independent of the spatial mesh, while boundary geometry uses its coordinates to
   locate the inlet interval. DG integration uses :math:`r_c,h_r,h_z`, reconstruction uses :math:`\overline{\xi}`, and particle rates use :math:`V_K,A_f`. All
   three must share the same geometry conventions.
