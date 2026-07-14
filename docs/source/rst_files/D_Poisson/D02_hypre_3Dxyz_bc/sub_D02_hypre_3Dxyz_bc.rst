sub_D02_hypre_3Dxyz_bc.f90
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_D02_hypre_3Dxyz_bc`` 是 Poisson/HYPRE 调用链中的包装或组装入口。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
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

   .. rubric:: 局部假设

   本页例程使用 cell-centered 3D Cartesian 逻辑网格和 7 点 stencil。``rho1d``/``RHS`` 与 ``A_values`` 必须采用相同 cell 遍历顺序；边界类型只在对应边界面上修改矩阵系数和 RHS。

   .. rubric:: 实现逻辑

   求解入口创建或复用 HYPRE StructGrid、StructStencil、StructMatrix、RHS/solution vector 和 PFMG solver；矩阵系数来自调用方已经组装好的 flattened arrays。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_D02_hypre_3Dxyz_bc`` fortran wrapper that calls the C/HYPRE solver fun_D02_hypre_3Dxyz_bc() to solve the 3D Poisson equation on a cell-centered structured grid.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``ilower``
        - in
        - ``(1:3)``
        - (1:3), lower logical indices of the local cell-centered grid box on this MPI rank,
          in HYPRE's index space :math:`(i_\text{L}, j_\text{L}, k_\text{L})`.
      * - ``iupper``
        - in
        - ``(1:3)``
        - (1:3), upper logical indices of the local cell-centered grid box on this MPI rank,
          in HYPRE's index space
      * - ``phi1d``
        - in/out
        - ``(:)`` / flattened owned cells
        - 1D array of length
      * - ``rho1d``
        - in
        - ``(:)`` / flattened owned cells
        - 1D array of the same length as ``phi1d``, containing the right-hand side :math:`h^2
          \rho / \varepsilon_0` (charge density plus boundary-condition contributions), as
          assembled by ``sub_D02_hypre_3Dxyz_bc_A``.
      * - ``tolerance``
        - in
        - scalar or caller-provided array
        - Convergence tolerance passed to the HYPRE PFMG solver; the solve stops once the
          residual norm is below this threshold.
      * - ``A_values``
        - in
        - ``(:)`` / 7 entries per cell
        - Flattened 1D array of matrix coefficients for the 7-point stencil at all cells in
          the local box. The length must be
      * - ``period``
        - in
        - ``(1:3)``
        - (1:3), periodicity vector in grid units, as expected by

   .. rubric:: Local Assumptions

   These routines use a cell-centered 3D Cartesian logical grid and a 7-point stencil. ``rho1d``/``RHS`` and ``A_values`` must use the same cell traversal order. Boundary types modify matrix coefficients and RHS only on matching boundary faces.

   .. rubric:: Implementation Notes

   The solve entry creates or reuses HYPRE StructGrid, StructStencil, StructMatrix, RHS/solution vectors, and a PFMG solver. Matrix coefficients come from caller-assembled flattened arrays.

   .. rubric:: Generated API

   .. doxygenfile:: sub_D02_hypre_3Dxyz_bc.f90
