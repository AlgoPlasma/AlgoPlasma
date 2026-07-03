mod_D01_hypre_3Dxyz_bc.f90
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_D01_hypre_3Dxyz_bc`` 汇总 Cartesian HYPRE Poisson 的 Fortran-C
   接口入口，用于把 Fortran 侧数组传给底层 HYPRE 调用。

   .. rubric:: 公开入口与 include 关系

   下列文件在 ``mod_D01_hypre_3Dxyz_bc`` 的 ``contains`` 作用域内 include。
   调用方应 ``use mod_D01_hypre_3Dxyz_bc`` 后调用具体例程；不要把这些
   include 文件单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_D01_hypre_3Dxyz_interface.f90``
        - 在 Fortran 与 C/HYPRE 包装层之间传递网格、矩阵、RHS 和解向量。
        - 需要从 Fortran 侧调用 Cartesian 3D HYPRE Poisson 求解流程。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 3D Cartesian 逻辑网格和 7 点 stencil。``rho1d``/``RHS`` 与 ``A_values`` 必须采用相同 cell 遍历顺序；边界类型只在对应边界面上修改矩阵系数和 RHS。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_D01_hypre_3Dxyz_bc`` module wrapper for the D01 Cartesian HYPRE Poisson interface.

   .. rubric:: Public Entries And Includes

   The following file is included inside the ``contains`` scope of
   ``mod_D01_hypre_3Dxyz_bc``. Callers should ``use mod_D01_hypre_3Dxyz_bc`` and
   call the concrete routine through the module; do not compile the include file
   separately.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_D01_hypre_3Dxyz_interface.f90``
        - Transfers grid, matrix, RHS, and solution arrays between Fortran and the C/HYPRE wrapper.
        - Call a Cartesian 3D HYPRE Poisson solve from Fortran-side code.

   .. rubric:: Local Assumptions

   These routines use a cell-centered 3D Cartesian logical grid and a 7-point stencil. ``rho1d``/``RHS`` and ``A_values`` must use the same cell traversal order. Boundary types modify matrix coefficients and RHS only on matching boundary faces.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_D01_hypre_3Dxyz_bc.f90
