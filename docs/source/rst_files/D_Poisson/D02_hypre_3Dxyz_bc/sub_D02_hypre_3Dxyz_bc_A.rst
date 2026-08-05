sub_D02_hypre_3Dxyz_bc_A.f90
----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_D02_hypre_3Dxyz_bc_A`` 为单域 Poisson 问题组装 7 点矩阵系数和 RHS。

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
        - out
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
      * - ``phibc``
        - in
        - ``(1:6)``
        - Dirichlet 或 Neumann 边界值数组。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 3D Cartesian 逻辑网格和 7 点 stencil。``rho1d``/``RHS`` 与 ``A_values`` 必须采用相同 cell 遍历顺序；边界类型只在对应边界面上修改矩阵系数和 RHS。

   .. rubric:: 实现逻辑

   实现按 cell 循环写入每个 cell 的 7 个 stencil entry，并同步构造 RHS。MPI 版本只处理本 rank owned cells，并用 neighbor flags 区分内部邻居和物理边界。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_D02_hypre_3Dxyz_bc_A`` set the coefficient matrix A with boundary conditions for Hypre.

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
        - out
        - ``(1:N)``
        - real (1:N), 1D coefficient matrix A, where ``N = 7 *
          (iu(1)-il(1)+1)*(iu(2)-il(2)+1)*(iu(3)-il(3)+1)``. The traversal
          order is ``m = 1; do k = il(3),iu(3); do j = il(2),iu(2);
          do i = il(1),iu(1); do l = 0,6; A_values(m); m = m + 1``.
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
      * - ``bc``
        - in
        - ``(1:6)``
        - integer (1:6), boundary types considered here: 1 (Dirichlet), 2 (Neumann), for xmin,
          xmax, ymin, ymax, zmin, zmax.
      * - ``phibc``
        - in
        - ``(1:6)``
        - real (1:6), boundary values. - For Dirichlet, phibc = the fixed potentials right on
          the boundary surfaces (in between two cell-centered grids). - For Neumann, phibc =
          h*E, h is the cell size, E is the electric field at the boundary. The correct sign
          of E should be provided.

   .. rubric:: Local Assumptions

   These routines use a cell-centered 3D Cartesian logical grid and a 7-point stencil. ``rho1d``/``RHS`` and ``A_values`` must use the same cell traversal order. Boundary types modify matrix coefficients and RHS only on matching boundary faces.

   .. rubric:: Implementation Notes

   The implementation loops over cells, writes seven stencil entries per cell, and builds the RHS in the same traversal. MPI variants handle only owned cells and use neighbor flags to distinguish internal neighbors from physical boundaries.

   .. rubric:: Generated API

   .. doxygenfile:: sub_D02_hypre_3Dxyz_bc_A.f90
