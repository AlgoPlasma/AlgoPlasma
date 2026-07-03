mod_D03_hypre_3Draz_uniform.f90
-------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_D03_hypre_3Draz_uniform`` 汇总均匀 ``(r,alpha,z)`` 柱坐标 3D
   HYPRE Poisson 求解、矩阵装配和边界修正入口。

   .. rubric:: 公开入口与 include 关系

   下列文件在 ``mod_D03_hypre_3Draz_uniform`` 的 ``contains`` 作用域内 include。
   调用方应 ``use mod_D03_hypre_3Draz_uniform`` 后调用具体例程；不要把这些
   include 文件单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_D03_hypre_3Draz_uniform.f90``
        - 用 HYPRE Struct PFMG 求解已装配的均匀柱坐标 Poisson 系统。
        - ``A_values`` 和 RHS 已准备好，需要执行求解阶段。
      * - ``sub_D03_hypre_3Draz_uniform_A.f90``
        - 装配单域均匀柱坐标 cell-centered 7 点矩阵和 RHS。
        - 非 MPI 或整体域装配场景。
      * - ``sub_D03_hypre_3Draz_uniform_A_mpi.f90``
        - 装配 MPI-local 均匀柱坐标矩阵和 RHS，并考虑邻接子域。
        - 区域分解后每个 rank 只装配本地 owned cells。
      * - ``sub_D03_hypre_3Draz_uniform_bc_A_dielectric.f90``
        - 对单域均匀柱坐标矩阵/RHS 施加 dielectric/surface-charge 修正。
        - 边界类型需要介质表面电荷贡献。
      * - ``sub_D03_hypre_3Draz_uniform_bc_A_outflow.f90``
        - 对单域均匀柱坐标矩阵/RHS 施加 outflow/Robin 型修正。
        - 需要处理开放边界或远场近似。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 柱坐标 ``(r,alpha,z)`` 和 7 点 stencil。``dr``、``da``、``dz`` 为均匀网格间距；flattened 数组顺序必须在矩阵、RHS 和解向量之间一致。HYPRE 句柄生命周期由调用方通过逻辑开关管理。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_D03_hypre_3Draz_uniform`` groups uniform cylindrical ``(r,alpha,z)``
   3D HYPRE Poisson solve, matrix-assembly, and boundary-correction routines.

   .. rubric:: Public Entries And Includes

   The following files are included inside the ``contains`` scope of
   ``mod_D03_hypre_3Draz_uniform``. Callers should
   ``use mod_D03_hypre_3Draz_uniform`` and call concrete routines through the
   module; do not compile these include files separately.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_D03_hypre_3Draz_uniform.f90``
        - Solves the assembled uniform cylindrical Poisson system with HYPRE Struct PFMG.
        - Run the solve stage after ``A_values`` and RHS are ready.
      * - ``sub_D03_hypre_3Draz_uniform_A.f90``
        - Assembles the single-domain uniform cylindrical 7-point matrix and RHS.
        - Use for non-MPI or whole-domain assembly.
      * - ``sub_D03_hypre_3Draz_uniform_A_mpi.f90``
        - Assembles MPI-local uniform cylindrical matrix/RHS with neighbor awareness.
        - Use after domain decomposition when each rank owns only local cells.
      * - ``sub_D03_hypre_3Draz_uniform_bc_A_dielectric.f90``
        - Applies dielectric/surface-charge corrections to the single-domain matrix/RHS.
        - Add surface-charge boundary contributions.
      * - ``sub_D03_hypre_3Draz_uniform_bc_A_outflow.f90``
        - Applies outflow/Robin-type corrections to the single-domain matrix/RHS.
        - Represent open boundaries or far-field behavior.

   .. rubric:: Local Assumptions

   These routines use a cell-centered cylindrical ``(r,alpha,z)`` layout and a 7-point stencil. ``dr``, ``da``, and ``dz`` are uniform spacings; flattened matrix, RHS, and solution arrays must use the same order. HYPRE object lifetime is managed by the caller through logical switches.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_D03_hypre_3Draz_uniform.f90
