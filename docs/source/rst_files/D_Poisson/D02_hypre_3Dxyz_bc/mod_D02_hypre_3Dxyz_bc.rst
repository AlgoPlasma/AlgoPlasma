mod_D02_hypre_3Dxyz_bc.f90
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_D02_hypre_3Dxyz_bc`` 汇总 Cartesian 3D HYPRE Poisson 求解、矩阵装配
   和边界修正入口。

   .. rubric:: 公开入口与 include 关系

   下列文件在 ``mod_D02_hypre_3Dxyz_bc`` 的 ``contains`` 作用域内 include。
   调用方应 ``use mod_D02_hypre_3Dxyz_bc`` 后调用具体例程；不要把这些
   include 文件单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_D02_hypre_3Dxyz_bc.f90``
        - 调用 C/HYPRE 包装器完成 3D Cartesian 结构网格 Poisson 求解。
        - 已有 ``A_values`` 和 ``rho1d``，需要把求解交给 C/HYPRE 层。
      * - ``sub_D02_hypre_3Dxyz_bc_A.f90``
        - 装配 Cartesian cell-centered 7 点 stencil 的矩阵系数和 RHS。
        - 求解前根据 charge density 和基础边界条件生成 ``A_values``/``rho1d``。
      * - ``sub_D02_hypre_3Dxyz_bc_A_dielectric.f90``
        - 对已装配矩阵和 RHS 施加 dielectric/surface-charge 边界修正。
        - 边界面存在介质表面电荷贡献，需要修改相邻 stencil 和 RHS。
      * - ``sub_D02_hypre_3Dxyz_bc_A_outflow.f90``
        - 对已装配矩阵和 RHS 施加 outflow 型边界修正。
        - 远场势 ``phi_infty`` 和参考点 ``r0`` 已知，需要处理开边界。
      * - ``sub_D02_hypre_3Dxyz_bc_fortran.f90``
        - 使用 HYPRE Fortran 接口创建、更新、求解和释放 Struct PFMG 对象。
        - 希望全程使用 Fortran HYPRE 接口并复用持久 HYPRE 句柄。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 3D Cartesian 逻辑网格和 7 点 stencil。``rho1d``/``RHS`` 与 ``A_values`` 必须采用相同 cell 遍历顺序；边界类型只在对应边界面上修改矩阵系数和 RHS。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_D02_hypre_3Dxyz_bc`` groups Cartesian 3D HYPRE Poisson solve, matrix
   assembly, and boundary-correction routines.

   .. rubric:: Public Entries And Includes

   The following files are included inside the ``contains`` scope of
   ``mod_D02_hypre_3Dxyz_bc``. Callers should ``use mod_D02_hypre_3Dxyz_bc`` and
   call concrete routines through the module; do not compile these include files
   separately.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_D02_hypre_3Dxyz_bc.f90``
        - Calls the C/HYPRE wrapper to solve the Cartesian 3D structured Poisson system.
        - Solve after ``A_values`` and ``rho1d`` have been assembled.
      * - ``sub_D02_hypre_3Dxyz_bc_A.f90``
        - Assembles Cartesian cell-centered 7-point matrix coefficients and RHS values.
        - Build ``A_values``/``rho1d`` from charge density and base boundary conditions.
      * - ``sub_D02_hypre_3Dxyz_bc_A_dielectric.f90``
        - Applies dielectric/surface-charge corrections to an assembled matrix and RHS.
        - Modify boundary-face stencil entries and RHS surface-charge terms.
      * - ``sub_D02_hypre_3Dxyz_bc_A_outflow.f90``
        - Applies outflow-type boundary corrections to an assembled matrix and RHS.
        - Handle open boundaries using ``phi_infty`` and the reference point ``r0``.
      * - ``sub_D02_hypre_3Dxyz_bc_fortran.f90``
        - Uses the HYPRE Fortran interface to create, update, solve, and finalize Struct PFMG objects.
        - Keep the HYPRE object lifecycle on the Fortran side with persistent handles.

   .. rubric:: Local Assumptions

   These routines use a cell-centered 3D Cartesian logical grid and a 7-point stencil. ``rho1d``/``RHS`` and ``A_values`` must use the same cell traversal order. Boundary types modify matrix coefficients and RHS only on matching boundary faces.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_D02_hypre_3Dxyz_bc.f90
