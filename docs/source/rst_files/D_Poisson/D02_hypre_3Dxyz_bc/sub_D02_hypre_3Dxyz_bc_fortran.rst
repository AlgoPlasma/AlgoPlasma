sub_D02_hypre_3Dxyz_bc_fortran.f90
----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_D02_hypre_3Dxyz_bc_fortran`` 是 HYPRE Struct PFMG 求解驱动，使用已组装的 7 点系数和 RHS 得到 Poisson 势函数解。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``fcomm``
        - in
        - scalar or caller-provided array
        - Fortran MPI communicator 句柄。
      * - ``il``
        - in
        - ``(1:3)``
        - 本地 active cell 下界索引。
      * - ``iu``
        - in
        - ``(1:3)``
        - 本地 active cell 上界索引。
      * - ``phi1d``
        - in/out
        - ``(:)``
        - flattened 势函数数组；求解器入口通常输入初值、输出收敛解。
      * - ``rho1d``
        - in
        - ``(:)``
        - flattened 电荷密度或 Poisson RHS 源项数组。
      * - ``tolerance``
        - in
        - scalar or caller-provided array
        - 迭代求解收敛阈值。
      * - ``A_values``
        - in
        - ``(:)``
        - flattened 7 点 stencil 矩阵系数；每个 cell 按 center、负/正方向邻点顺序存放。
      * - ``period``
        - in
        - ``(1:3)``
        - HYPRE periodicity 向量；0 表示该方向非周期。
      * - ``do_init``
        - in
        - scalar or caller-provided array
        - 是否创建并初始化持久 HYPRE 对象。
      * - ``do_updateA``
        - in
        - scalar or caller-provided array
        - 是否用新的 ``A_values`` 更新矩阵。
      * - ``do_finalize``
        - in
        - scalar or caller-provided array
        - 是否销毁持久 HYPRE 对象。
      * - ``grid``
        - in/out
        - HYPRE handle, ``integer(8)``
        - HYPRE StructGrid 句柄。
      * - ``stencil``
        - in/out
        - HYPRE handle, ``integer(8)``
        - HYPRE StructStencil 句柄。
      * - ``A``
        - in/out
        - HYPRE handle, ``integer(8)``
        - HYPRE StructMatrix 句柄。
      * - ``b``
        - in/out
        - HYPRE handle, ``integer(8)``
        - HYPRE RHS 向量句柄。
      * - ``x``
        - in/out
        - HYPRE handle, ``integer(8)``
        - 粒子位置或 HYPRE solution 句柄，具体取决于接口上下文。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 3D Cartesian 逻辑网格和 7 点 stencil。``rho1d``/``RHS`` 与 ``A_values`` 必须采用相同 cell 遍历顺序；边界类型只在对应边界面上修改矩阵系数和 RHS。

   .. rubric:: 实现逻辑

   求解入口创建或复用 HYPRE StructGrid、StructStencil、StructMatrix、RHS/solution vector 和 PFMG solver；矩阵系数来自调用方已经组装好的 flattened arrays。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_D02_hypre_3Dxyz_bc_fortran`` solve a 3D structured linear system using the HYPRE Struct PFMG solver with a 7-point finite-difference stencil (Fortran interface).

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``fcomm``
        - in
        - scalar or caller-provided array
        - integer, MPI communicator (Fortran handle) used by HYPRE
      * - ``il``
        - in
        - ``(1:3)``
        - integer (1:3), cell-center lower indices in x,y,z
      * - ``iu``
        - in
        - ``(1:3)``
        - integer (1:3), cell-center upper indices in x,y,z
      * - ``phi1d``
        - in/out
        - ``(:)``
        - real(:), initial values on input, solution on output
      * - ``rho1d``
        - in
        - ``(:)``
        - real(:), right-hand-side values on ``il:iu``
      * - ``tolerance``
        - in
        - scalar or caller-provided array
        - real, solver convergence tolerance
      * - ``A_values``
        - in
        - ``(:)``
        - real(:), matrix coefficients for ``il:iu`` (7 entries)
      * - ``period``
        - in
        - ``(1:3)``
        - integer (1:3), periodicity lengths for x,y,z
      * - ``do_init``
        - in
        - scalar or caller-provided array
        - logical, create/assemble persistent HYPRE objects
      * - ``do_updateA``
        - in
        - scalar or caller-provided array
        - logical, update matrix coefficients from ``A_values``
      * - ``do_finalize``
        - in
        - scalar or caller-provided array
        - logical, destroy persistent HYPRE objects
      * - ``grid``
        - in/out
        - HYPRE handle, ``integer(8)``
        - integer(8), HYPRE ``StructGrid`` handle
      * - ``stencil``
        - in/out
        - HYPRE handle, ``integer(8)``
        - integer(8), HYPRE ``StructStencil`` handle
      * - ``A``
        - in/out
        - HYPRE handle, ``integer(8)``
        - integer(8), HYPRE ``StructMatrix`` handle
      * - ``b``
        - in/out
        - HYPRE handle, ``integer(8)``
        - integer(8), HYPRE ``StructVector`` (RHS) handle
      * - ``x``
        - in/out
        - HYPRE handle, ``integer(8)``
        - integer(8), HYPRE ``StructVector`` (solution) handle

   .. rubric:: Local Assumptions

   These routines use a cell-centered 3D Cartesian logical grid and a 7-point stencil. ``rho1d``/``RHS`` and ``A_values`` must use the same cell traversal order. Boundary types modify matrix coefficients and RHS only on matching boundary faces.

   .. rubric:: Implementation Notes

   The solve entry creates or reuses HYPRE StructGrid, StructStencil, StructMatrix, RHS/solution vectors, and a PFMG solver. Matrix coefficients come from caller-assembled flattened arrays.

   .. rubric:: Generated API

   .. doxygenfile:: sub_D02_hypre_3Dxyz_bc_fortran.f90
