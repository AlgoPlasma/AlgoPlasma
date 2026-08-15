sub_D03_hypre_3Draz_uniform.f90
-------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_D03_hypre_3Draz_uniform`` 是 HYPRE Struct PFMG 求解驱动，使用已组装的 7 点系数和 RHS 得到 Poisson 势函数解。

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
      * - ``RHS``
        - in
        - ``(:)``
        - flattened 右端项数组，顺序必须和矩阵组装顺序一致。
      * - ``tolerance``
        - in
        - scalar or caller-provided array
        - 迭代求解收敛阈值。
      * - ``A_values``
        - in
        - ``(:)``
        - flattened 7 点 stencil 矩阵系数；每个 cell 按 center、负/正方向邻点顺序存放。
      * - ``periodic``
        - in
        - ``(1:3)``
        - 周期长度向量；0 表示该方向非周期。
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
      * - ``solver``
        - in/out
        - HYPRE handle, ``integer(8)``
        - HYPRE PFMG solver 句柄。
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

   本页例程使用 cell-centered 柱坐标 ``(r,alpha,z)`` 和 7 点 stencil。``dr``、``da``、``dz`` 为均匀网格间距；flattened 数组顺序必须在矩阵、RHS 和解向量之间一致。HYPRE 句柄生命周期由调用方通过逻辑开关管理。

   .. rubric:: 实现逻辑

   求解入口创建或复用 HYPRE StructGrid、StructStencil、StructMatrix、RHS/solution vector 和 PFMG solver；矩阵系数来自调用方已经组装好的 flattened arrays。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_D03_hypre_3Draz_uniform`` solve the assembled system for the single-domain 3D cylindrical uniform-grid Poisson solver using HYPRE Struct PFMG.

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
        - integer, Fortran MPI communicator passed to HYPRE.
      * - ``il``
        - in
        - ``(1:3)``
        - integer (1:3), lower cell-center indices in ``r,alpha,z``.
      * - ``iu``
        - in
        - ``(1:3)``
        - integer (1:3), upper cell-center indices in ``r,alpha,z``.
      * - ``phi1d``
        - in/out
        - ``(:)``
        - real (:), flattened solution array. On input it provides the initial guess; on
          output it is overwritten by the solved potential.
      * - ``RHS``
        - in
        - ``(:)``
        - real (:), flattened right-hand-side array.
      * - ``tolerance``
        - in
        - scalar or caller-provided array
        - real scalar, convergence tolerance passed to the HYPRE Struct PFMG solver.
      * - ``A_values``
        - in
        - ``(:)``
        - real (:), flattened 7-point stencil coefficients used to assemble the HYPRE
          structured matrix.
      * - ``periodic``
        - in
        - ``(1:3)``
        - integer (1:3), periodic lengths in ``r,alpha,z`` passed to
          ``HYPRE_StructGridSetPeriodic``.
      * - ``do_init``
        - in
        - scalar or caller-provided array
        - logical, whether to create and initialize the HYPRE grid, stencil, matrix, vectors,
          and solver.
      * - ``do_updateA``
        - in
        - scalar or caller-provided array
        - logical, whether to rebuild the HYPRE matrix from the current ``A_values``.
      * - ``do_finalize``
        - in
        - scalar or caller-provided array
        - logical, whether to destroy all HYPRE objects and return immediately.
      * - ``solver``
        - in/out
        - HYPRE handle, ``integer(8)``
        - integer(8), HYPRE Struct PFMG solver handle.
      * - ``grid``
        - in/out
        - HYPRE handle, ``integer(8)``
        - integer(8), HYPRE structured grid handle.
      * - ``stencil``
        - in/out
        - HYPRE handle, ``integer(8)``
        - integer(8), HYPRE structured stencil handle.
      * - ``A``
        - in/out
        - HYPRE handle, ``integer(8)``
        - integer(8), HYPRE structured matrix handle.
      * - ``b``
        - in/out
        - HYPRE handle, ``integer(8)``
        - integer(8), HYPRE structured RHS vector handle.
      * - ``x``
        - in/out
        - HYPRE handle, ``integer(8)``
        - integer(8), HYPRE structured solution vector handle.

   .. rubric:: Local Assumptions

   These routines use a cell-centered cylindrical ``(r,alpha,z)`` layout and a 7-point stencil. ``dr``, ``da``, and ``dz`` are uniform spacings; flattened matrix, RHS, and solution arrays must use the same order. HYPRE object lifetime is managed by the caller through logical switches.

   .. rubric:: Implementation Notes

   The solve entry creates or reuses HYPRE StructGrid, StructStencil, StructMatrix, RHS/solution vectors, and a PFMG solver. Matrix coefficients come from caller-assembled flattened arrays.

   .. rubric:: Generated API

   .. doxygenfile:: sub_D03_hypre_3Draz_uniform.f90
