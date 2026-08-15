sub_D02_hypre_3Dxyz_bc_A_outflow.f90
------------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_D02_hypre_3Dxyz_bc_A_outflow`` 在已组装矩阵/RHS 上加入 outflow/Robin 类型边界修正。

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
        - in/out
        - ``(:)``
        - flattened 7 点 stencil 矩阵系数；每个 cell 按 center、负/正方向邻点顺序存放。
      * - ``rho1d``
        - in/out
        - ``(:)``
        - flattened 电荷密度或 Poisson RHS 源项数组。
      * - ``bc``
        - in
        - ``(1:6)``
        - 六个边界面的类型码，顺序按 x/r 下/上、y/a 下/上、z 下/上。
      * - ``phi_infty``
        - in
        - scalar or caller-provided array
        - real, far-field potential value used in outflow BC.
      * - ``r0``
        - in
        - ``(1:3)``
        - real (1:3), reference point (e.g. sphere center) for computing radial direction and
          kb.

   .. rubric:: 局部假设

   本页例程使用 cell-centered 3D Cartesian 逻辑网格和 7 点 stencil。``rho1d``/``RHS`` 与 ``A_values`` 必须采用相同 cell 遍历顺序；边界类型只在对应边界面上修改矩阵系数和 RHS。

   .. rubric:: 实现逻辑

   实现只扫描边界 cell，并在匹配的边界类型上修正已经存在的 ``A_values`` 和 ``RHS``/``rho1d``；它应在基础矩阵组装之后、HYPRE solve 之前调用。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_D02_hypre_3Dxyz_bc_A_outflow`` apply 3D outflow boundary conditions to Hypre matrix and RHS.

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
        - in/out
        - ``(:)``
        - real(:), flattened 7-point stencil coefficients for all cells in the domain,
          modified in-place.
      * - ``rho1d``
        - in/out
        - ``(:)``
        - real(:), right-hand side vector for all cells, modified in-place by boundary
          contributions.
      * - ``bc``
        - in
        - ``(1:6)``
        - integer (1:6), boundary condition type per face: (xmin,xmax,ymin,ymax,zmin,zmax); 4
          indicates outflow.
      * - ``phi_infty``
        - in
        - scalar or caller-provided array
        - real, far-field potential value used in outflow BC.
      * - ``r0``
        - in
        - ``(1:3)``
        - real (1:3), reference point (e.g. sphere center) for computing radial direction and
          kb.

   .. rubric:: Local Assumptions

   These routines use a cell-centered 3D Cartesian logical grid and a 7-point stencil. ``rho1d``/``RHS`` and ``A_values`` must use the same cell traversal order. Boundary types modify matrix coefficients and RHS only on matching boundary faces.

   .. rubric:: Implementation Notes

   The implementation scans boundary cells and modifies existing ``A_values`` plus ``RHS``/``rho1d`` only for matching boundary types. Call it after base assembly and before the HYPRE solve.

   .. rubric:: Generated API

   .. doxygenfile:: sub_D02_hypre_3Dxyz_bc_A_outflow.f90
