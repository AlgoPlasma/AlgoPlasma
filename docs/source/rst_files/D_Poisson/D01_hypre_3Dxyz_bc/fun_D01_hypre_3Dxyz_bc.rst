fun_D01_hypre_3Dxyz_bc.c
------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``fun_D01_hypre_3Dxyz_bc`` 是 C/HYPRE 结构化网格求解入口，负责把已经准备好的网格、矩阵、RHS 和初值交给 HYPRE PFMG 求解。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``fComm``
        - in
        - scalar or caller-provided array
        - Fortran MPI communicator 句柄。
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
        - 六个边界面的类型码，顺序按 x/r 下/上、y/a 下/上、z 下/上。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 3D Cartesian 逻辑网格和 7 点 stencil。``rho1d``/``RHS`` 与 ``A_values`` 必须采用相同 cell 遍历顺序；边界类型只在对应边界面上修改矩阵系数和 RHS。

   .. rubric:: 实现逻辑

   求解入口创建或复用 HYPRE StructGrid、StructStencil、StructMatrix、RHS/solution vector 和 PFMG solver；矩阵系数来自调用方已经组装好的 flattened arrays。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``fun_D01_hypre_3Dxyz_bc`` calls the HYPRE to solve AX = b, where A is the discretized Laplacian, b is the source term, and X is the electric potential, and supports MPI parallelism, with each process responsible for a local portion of the grid.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``fComm``
        - in
        - scalar or caller-provided array
        - MPI communicator, set to mpi_comm_world for global parallel communication
      * - ``n``
        - in
        - scalar or caller-provided array
        - size of 3D array (local grid nodes per MPI process)
      * - ``phi1d``
        - out
        - ``(:)`` / flattened owned cells
        - electric potential array.
      * - ``rho1d``
        - in
        - ``(:)`` / flattened owned cells
        - charge density array
      * - ``ilower``
        - in
        - ``(1:3)``
        - lower physical indices(3D array, of this mpi rank)
      * - ``iupper``
        - in
        - ``(1:3)``
        - upper physical indices(3D array, of this mpi rank)
      * - ``il0``
        - in
        - ``(1:3)``
        - lower physical indices(3D array, of global model)
      * - ``iu0``
        - in
        - ``(1:3)``
        - upper physical indices(3D array, of global model)
      * - ``tolerance``
        - in
        - scalar or caller-provided array
        - Convergence threshold (stops iteration when error is below this value)
      * - ``bc``
        - in
        - ``(1:6)``
        - boundary condition flag in x,z small and big. 0: inner; 1: Dirichlet; 2: Neumann; y
          is set to be periodic.

   .. rubric:: Local Assumptions

   These routines use a cell-centered 3D Cartesian logical grid and a 7-point stencil. ``rho1d``/``RHS`` and ``A_values`` must use the same cell traversal order. Boundary types modify matrix coefficients and RHS only on matching boundary faces.

   .. rubric:: Implementation Notes

   The solve entry creates or reuses HYPRE StructGrid, StructStencil, StructMatrix, RHS/solution vectors, and a PFMG solver. Matrix coefficients come from caller-assembled flattened arrays.

   .. rubric:: Generated API

   .. doxygenfile:: fun_D01_hypre_3Dxyz_bc.c
