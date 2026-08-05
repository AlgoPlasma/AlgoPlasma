fun_D02_hypre_3Dxyz_bc.c
------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``fun_D02_hypre_3Dxyz_bc`` 是 C/HYPRE 结构化网格求解入口，负责把已经准备好的网格、矩阵、RHS 和初值交给 HYPRE PFMG 求解。

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
      * - ``ilower``
        - in
        - ``(1:3)``
        - HYPRE/C 侧本 rank 结构化网格 box 下界。
      * - ``iupper``
        - in
        - ``(1:3)``
        - HYPRE/C 侧本 rank 结构化网格 box 上界，闭区间。
      * - ``phi1d``
        - in/out
        - ``(:)`` / flattened owned cells
        - flattened 势函数数组；求解器入口通常输入初值、输出收敛解。
      * - ``rho1d``
        - in
        - ``(:)`` / flattened owned cells
        - flattened 电荷密度或 Poisson RHS 源项数组。
      * - ``tolerance``
        - in
        - scalar or caller-provided array
        - 迭代求解收敛阈值。
      * - ``A_values``
        - in
        - ``(:)`` / 7 entries per cell
        - flattened 7 点 stencil 矩阵系数；每个 cell 按 center、负/正方向邻点顺序存放。
      * - ``period``
        - in
        - ``(1:3)``
        - HYPRE periodicity 向量；0 表示该方向非周期。
      * - ``ilower3``
        - in
        - scalar or caller-provided array
        - 调用方提供的接口参数；shape 和物理含义需与源码声明及生成 API 保持一致。
      * - ``iupper3``
        - in
        - scalar or caller-provided array
        - 调用方提供的接口参数；shape 和物理含义需与源码声明及生成 API 保持一致。
      * - ``period3``
        - in
        - scalar or caller-provided array
        - 调用方提供的接口参数；shape 和物理含义需与源码声明及生成 API 保持一致。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 3D Cartesian 逻辑网格和 7 点 stencil。``rho1d``/``RHS`` 与 ``A_values`` 必须采用相同 cell 遍历顺序；边界类型只在对应边界面上修改矩阵系数和 RHS。

   .. rubric:: 实现逻辑

   求解入口创建或复用 HYPRE StructGrid、StructStencil、StructMatrix、RHS/solution vector 和 PFMG solver；矩阵系数来自调用方已经组装好的 flattened arrays。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``fun_D02_hypre_3Dxyz_bc`` c wrapper around HYPRE's structured interface to solve the 3D Poisson equation with boundary conditions.

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
        - Pointer to a Fortran ``MPI_Comm`` (Fortran integer handle). It is converted
          internally to a C ``MPI_Comm`` via
      * - ``ilower``
        - in
        - ``(1:3)``
        - Integer array of size 3. Logical lower indices (ilower[0], ilower[1], ilower[2]) of
          the structured grid box owned by this MPI rank, in HYPRE's index space.
      * - ``iupper``
        - in
        - ``(1:3)``
        - Integer array of size 3. Logical upper indices (iupper[0], iupper[1], iupper[2]) of
          the structured grid box owned by this MPI rank, inclusive. Together with ``ilower``
          they define a rectangular box of local cells.
      * - ``phi1d``
        - in/out
        - ``(:)`` / flattened owned cells
        - 1D array holding the potential :math:`\phi` at cell centers on this MPI process. -
          On input: initial guess for the iterative solver (may be zero or a more informed
          guess). - On output: converged solution after applying PFMG.
      * - ``rho1d``
        - in
        - ``(:)`` / flattened owned cells
        - 1D array holding the right-hand side :math:`h^2 \rho / \varepsilon_0` for each local
          cell center, including contributions from Dirichlet and Neumann boundary conditions
          as assembled in
      * - ``tolerance``
        - in
        - scalar or caller-provided array
        - Convergence tolerance for the PFMG solver. The solve stops once the residual norm is
          below this value.
      * - ``A_values``
        - in
        - ``(:)`` / 7 entries per cell
        - Flattened 1D array of matrix coefficients for the 7-point stencil at all local
          cells. Its layout must match the HYPRE stencil element order: - entry 0: center
          :math:`(i,j,k)`, - entry 1: :math:`(i-1,j,k)` (xmin), - entry 2: :math:`(i+1,j,k)`
          (xmax), - entry 3: :math:`(i,j-1,k)` (ymin), - entry 4: :math:`(i,j+1,k)` (ymax), -
          entry 5: :math:`(i,j,k-1)` (zmin), - entry 6: :math:`(i,j,k+1)` (zmax).
      * - ``period``
        - in
        - ``(1:3)``
        - Periodicity vector for the structured grid as expected by
      * - ``ilower3``
        - in
        - scalar or caller-provided array
        - Caller-provided parameter ``ilower3``; keep shape and meaning consistent with the
          source declaration.
      * - ``iupper3``
        - in
        - scalar or caller-provided array
        - Caller-provided parameter ``iupper3``; keep shape and meaning consistent with the
          source declaration.
      * - ``period3``
        - in
        - scalar or caller-provided array
        - Caller-provided parameter ``period3``; keep shape and meaning consistent with the
          source declaration.

   .. rubric:: Local Assumptions

   These routines use a cell-centered 3D Cartesian logical grid and a 7-point stencil. ``rho1d``/``RHS`` and ``A_values`` must use the same cell traversal order. Boundary types modify matrix coefficients and RHS only on matching boundary faces.

   .. rubric:: Implementation Notes

   The solve entry creates or reuses HYPRE StructGrid, StructStencil, StructMatrix, RHS/solution vectors, and a PFMG solver. Matrix coefficients come from caller-assembled flattened arrays.

   .. rubric:: Generated API

   .. doxygenfile:: fun_D02_hypre_3Dxyz_bc.c
