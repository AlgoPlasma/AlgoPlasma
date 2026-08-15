sub_D01_hypre_3Dxyz_interface.f90
---------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_D01_hypre_3Dxyz_interface`` 是 Poisson/HYPRE 调用链中的包装或组装入口。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``n``
        - in
        - scalar or caller-provided array
        - 密度或数组长度，具体含义见接口上下文。
      * - ``phi1d``
        - out
        - ``(:)`` / flattened owned cells
        - flattened 势函数数组；求解器入口通常输入初值、输出收敛解。
      * - ``rho1d``
        - in
        - ``(:)`` / flattened owned cells
        - flattened 电荷密度或 Poisson RHS 源项数组。
      * - ``ilower``
        - in
        - ``(1:3)``
        - HYPRE/C 侧本 rank 结构化网格 box 下界。
      * - ``iupper``
        - in
        - ``(1:3)``
        - HYPRE/C 侧本 rank 结构化网格 box 上界，闭区间。
      * - ``il0``
        - in
        - ``(1:3)``
        - 全局物理网格下界索引。
      * - ``iu0``
        - in
        - ``(1:3)``
        - 全局物理网格上界索引。
      * - ``tolerance``
        - in
        - scalar or caller-provided array
        - 迭代求解收敛阈值。
      * - ``bc``
        - in
        - ``(1:6)``
        - 六个边界面的类型码，顺序按 x/r 下/上、y/a 下/上、z 下/上,0:内部边界；1为Dirichlet；2为Neumann。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 3D Cartesian 逻辑网格和 7 点 stencil。``rho1d``/``RHS`` 与 ``A_values`` 必须采用相同 cell 遍历顺序；边界类型只在对应边界面上修改矩阵系数和 RHS。

   .. rubric:: 实现逻辑

   求解入口创建或复用 HYPRE StructGrid、StructStencil、StructMatrix、RHS/solution vector 和 PFMG solver；矩阵系数来自调用方已经组装好的 flattened arrays。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_D01_hypre_3Dxyz_interface`` an interface between Fortran and C language to complete data transmission

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``n``
        - in
        - scalar or caller-provided array
        - size of 1D array (local grid nodes per MPI process)
      * - ``phi1d``
        - out
        - ``(:)`` / flattened owned cells
        - electric potential array
      * - ``rho1d``
        - in
        - ``(:)`` / flattened owned cells
        - charge density
      * - ``ilower``
        - in
        - ``(1:3)``
        - lower physical indices (3D array, of this MPI rank)
      * - ``iupper``
        - in
        - ``(1:3)``
        - upper physical indices (3D array, of this MPI rank)
      * - ``il0``
        - in
        - ``(1:3)``
        - lower physical indices (3D array, of global model)
      * - ``iu0``
        - in
        - ``(1:3)``
        - upper physical indices (3D array, of global model)
      * - ``tolerance``
        - in
        - scalar or caller-provided array
        - Convergence threshold (stops iteration when error is below this value)
      * - ``bc``
        - in
        - ``(1:6)``
        - Boundary condition flag on the lower/upper x and z faces. 0: inner; 1: Dirichlet; 2:
          Neumann; y is periodic.

   .. rubric:: Local Assumptions

   These routines use a cell-centered 3D Cartesian logical grid and a 7-point stencil. ``rho1d``/``RHS`` and ``A_values`` must use the same cell traversal order. Boundary types modify matrix coefficients and RHS only on matching boundary faces.

   .. rubric:: Implementation Notes

   The solve entry creates or reuses HYPRE StructGrid, StructStencil, StructMatrix, RHS/solution vectors, and a PFMG solver. Matrix coefficients come from caller-assembled flattened arrays.

   .. rubric:: Generated API

   .. doxygenfile:: sub_D01_hypre_3Dxyz_interface.f90
