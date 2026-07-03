mod_D04_hypre_3Draz_nonuniform.f90
----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_D04_hypre_3Draz_nonuniform`` 汇总非均匀 ``(r,alpha,z)`` 柱坐标 3D
   HYPRE Poisson 求解、矩阵装配和边界修正入口。

   .. rubric:: 公开入口与 include 关系

   下列文件在 ``mod_D04_hypre_3Draz_nonuniform`` 的 ``contains`` 作用域内 include。
   调用方应 ``use mod_D04_hypre_3Draz_nonuniform`` 后调用具体例程；不要把这些
   include 文件单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_D04_hypre_3Draz_nonuniform.f90``
        - 用 HYPRE Struct PFMG 求解已装配的非均匀柱坐标 Poisson 系统。
        - ``A_values`` 和 RHS 已准备好，需要执行求解阶段。
      * - ``sub_D04_hypre_3Draz_nonuniform_A.f90``
        - 装配单域非均匀柱坐标 cell-centered 7 点矩阵和 RHS。
        - 非 MPI 或整体域装配场景，网格间距由方向数组给出。
      * - ``sub_D04_hypre_3Draz_nonuniform_A_mpi.f90``
        - 装配 MPI-local 非均匀柱坐标矩阵和 RHS，并使用 halo/邻接间距信息。
        - 区域分解后每个 rank 只装配本地 owned cells。
      * - ``sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric.f90``
        - 对单域非均匀柱坐标矩阵/RHS 施加 dielectric/surface-charge 修正。
        - 边界类型需要介质表面电荷贡献。
      * - ``sub_D04_hypre_3Draz_nonuniform_bc_A_outflow.f90``
        - 对单域非均匀柱坐标矩阵/RHS 施加 outflow/Robin 型修正。
        - 需要在非均匀网格上处理开放边界或远场近似。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 柱坐标 ``(r,alpha,z)``；flattened 数组只覆盖调用方给定的 owned/active cells。非均匀版本的 ``dr``、``da``、``dz`` 是方向相关间距数组，MPI 版本需要包含相邻 ghost/halo 间距。HYPRE 句柄的生命周期由 ``do_init``、``do_updateA``、``do_finalize`` 或 C 包装器控制。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_D04_hypre_3Draz_nonuniform`` groups nonuniform cylindrical
   ``(r,alpha,z)`` 3D HYPRE Poisson solve, matrix-assembly, and
   boundary-correction routines.

   .. rubric:: Public Entries And Includes

   The following files are included inside the ``contains`` scope of
   ``mod_D04_hypre_3Draz_nonuniform``. Callers should
   ``use mod_D04_hypre_3Draz_nonuniform`` and call concrete routines through the
   module; do not compile these include files separately.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_D04_hypre_3Draz_nonuniform.f90``
        - Solves the assembled nonuniform cylindrical Poisson system with HYPRE Struct PFMG.
        - Run the solve stage after ``A_values`` and RHS are ready.
      * - ``sub_D04_hypre_3Draz_nonuniform_A.f90``
        - Assembles the single-domain nonuniform cylindrical 7-point matrix and RHS.
        - Use for whole-domain assembly with directional spacing arrays.
      * - ``sub_D04_hypre_3Draz_nonuniform_A_mpi.f90``
        - Assembles MPI-local nonuniform cylindrical matrix/RHS using halo spacing data.
        - Use after domain decomposition when each rank owns only local cells.
      * - ``sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric.f90``
        - Applies dielectric/surface-charge corrections to the single-domain matrix/RHS.
        - Add surface-charge boundary contributions on a nonuniform grid.
      * - ``sub_D04_hypre_3Draz_nonuniform_bc_A_outflow.f90``
        - Applies outflow/Robin-type corrections to the single-domain matrix/RHS.
        - Represent open boundaries or far-field behavior on a nonuniform grid.

   .. rubric:: Local Assumptions

   These routines use a cell-centered cylindrical ``(r,alpha,z)`` layout. Flattened arrays cover only the caller-provided owned/active cells. In the nonuniform variant, ``dr``, ``da``, and ``dz`` are directional spacing arrays; MPI-local assembly needs neighboring halo spacings. HYPRE handle lifetime is controlled by ``do_init``, ``do_updateA``, ``do_finalize``, or by the C wrapper.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_D04_hypre_3Draz_nonuniform.f90
