sub_D02_hypre_3Dxyz_bc_A_dielectric.f90
---------------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_D02_hypre_3Dxyz_bc_A_dielectric`` 在已组装矩阵/RHS 上加入 dielectric 或 surface-charge 边界修正。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``il``
        - in
        - ``(1:3)``
        - 本地 active cell 下界索引。
      * - ``iu``
        - in
        - ``(1:3)``
        - 本地 active cell 上界索引。
      * - ``A_values``
        - inout
        - ``(1:N)``
        - flattened 7 点 stencil 矩阵系数；每个 cell 按 center、负/正方向邻点顺序存放。
      * - ``rho1d``
        - inout
        - ``(1:N)``
        - flattened 电荷密度或 Poisson RHS 源项数组。
      * - ``bc``
        - in
        - ``(1:6)``
        - 六个边界面的类型码，顺序按 x/r 下/上、y/a 下/上、z 下/上。
      * - ``sx1``
        - in
        - ``(:,:)``
        - 对应边界面的 surface-charge / dielectric 修正系数；仅在该边界类型需要时使用。
      * - ``sx2``
        - in
        - ``(:,:)``
        - 对应边界面的 surface-charge / dielectric 修正系数；仅在该边界类型需要时使用。
      * - ``sy1``
        - in
        - ``(:,:)``
        - 对应边界面的 surface-charge / dielectric 修正系数；仅在该边界类型需要时使用。
      * - ``sy2``
        - in
        - ``(:,:)``
        - 对应边界面的 surface-charge / dielectric 修正系数；仅在该边界类型需要时使用。
      * - ``sz1``
        - in
        - ``(:,:)``
        - 对应边界面的 surface-charge / dielectric 修正系数；仅在该边界类型需要时使用。
      * - ``sz2``
        - in
        - ``(:,:)``
        - 对应边界面的 surface-charge / dielectric 修正系数；仅在该边界类型需要时使用。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 3D Cartesian 逻辑网格和 7 点 stencil。``rho1d``/``RHS`` 与 ``A_values`` 必须采用相同 cell 遍历顺序；边界类型只在对应边界面上修改矩阵系数和 RHS。

   .. rubric:: 实现逻辑

   实现只扫描边界 cell，并在匹配的边界类型上修正已经存在的 ``A_values`` 和 ``RHS``/``rho1d``；它应在基础矩阵组装之后、HYPRE solve 之前调用。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_D02_hypre_3Dxyz_bc_A_dielectric`` assemble dielectric (surface–charge) boundary contributions to the Poisson matrix and RHS.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``il``
        - in
        - ``(1:3)``
        - integer (1:3), cell-center lower indices in x,y,z.
      * - ``iu``
        - in
        - ``(1:3)``
        - integer (1:3), cell-center upper indices in x,y,z.
      * - ``A_values``
        - inout
        - ``(1:N)``
        - real (1:N), 1D coefficient matrix A, where ``N = 7 *
          (iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)``. The traversal
          order is ``m = 1; do k = il(3),iu(3); do j = il(2),iu(2);
          do i = il(1),iu(1); do l = 0,6; A_values(m); m = m + 1``. The
          dielectric modifications are applied additively to the existing entries.
      * - ``rho1d``
        - inout
        - ``(1:N)``
        - real (1:N), 1D right-hand side (charge density) term array, where
          ``N = (iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)``. Before
          calling this routine, assign :math:`\mathrm{rho1d}=h^2\rho/\varepsilon_0`;
          boundary handling then modifies the array using ``phibc``. Here
          :math:`h=\Delta x=\Delta y=\Delta z` is the cell size, :math:`\rho`
          is the cell-centered charge density, and :math:`\varepsilon_0` is the
          vacuum permittivity. The traversal order is ``m = 1; do k = il(3),iu(3);
          do j = il(2),iu(2); do i = il(1),iu(1); rho1d(m); m = m + 1``.
          Surface-charge corrections for dielectric faces are added in place.
      * - ``bc``
        - in
        - ``(1:6)``
        - integer (1:6), boundary types for ``xmin, xmax, ymin, ymax, zmin, zmax``. Here only
          bc(*) = 3 (dielectric with surface charge) is handled. Other values are ignored in
          this routine.
      * - ``sx1``
        - in
        - ``(:,:)``
        - real (:,:), optional surface-charge term on the lower x face; dimensions follow the source declaration and the local ``j,k`` boundary plane.
      * - ``sx2``
        - in
        - ``(:,:)``
        - real (:,:), at ``xmax``, dimension ``(il(2)-1:iu(2),il(3)-1:iu(3))``, it stores \f$ - h
          \sigma / \varepsilon_0 \f$ on the upper x-face.
      * - ``sy1``
        - in
        - ``(:,:)``
        - real (:,:), at ``ymin``, dimension ``(il(1)-1:iu(1),il(3)-1:iu(3))``.
      * - ``sy2``
        - in
        - ``(:,:)``
        - real (:,:), at ``ymax``, dimension ``(il(1)-1:iu(1),il(3)-1:iu(3))``.
      * - ``sz1``
        - in
        - ``(:,:)``
        - real (:,:), at ``zmin``, dimension ``(il(1)-1:iu(1),il(2)-1:iu(2))``.
      * - ``sz2``
        - in
        - ``(:,:)``
        - real (:,:), at ``zmax``, dimension ``(il(1)-1:iu(1),il(2)-1:iu(2))``.

   .. rubric:: Local Assumptions

   These routines use a cell-centered 3D Cartesian logical grid and a 7-point stencil. ``rho1d``/``RHS`` and ``A_values`` must use the same cell traversal order. Boundary types modify matrix coefficients and RHS only on matching boundary faces.

   .. rubric:: Implementation Notes

   The implementation scans boundary cells and modifies existing ``A_values`` plus ``RHS``/``rho1d`` only for matching boundary types. Call it after base assembly and before the HYPRE solve.

   .. rubric:: Generated API

   .. doxygenfile:: sub_D02_hypre_3Dxyz_bc_A_dielectric.f90
