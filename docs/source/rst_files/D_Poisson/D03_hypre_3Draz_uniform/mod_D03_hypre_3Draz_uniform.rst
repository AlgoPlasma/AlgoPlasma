mod_D03_hypre_3Draz_uniform.f90
-------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_D03_hypre_3Draz_uniform`` 是该目录的模块包装器，集中 include 或暴露本组公开入口。

   .. rubric:: 公开入口与 include 关系

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - 文件/符号
        - 角色
        - 调用约定
      * - ``sub_D03_hypre_3Draz_uniform.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_D03_hypre_3Draz_uniform_A.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_D03_hypre_3Draz_uniform_A_mpi.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_D03_hypre_3Draz_uniform_bc_A_dielectric.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_D03_hypre_3Draz_uniform_bc_A_outflow.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 柱坐标 ``(r,alpha,z)`` 和 7 点 stencil。``dr``、``da``、``dz`` 为均匀网格间距；flattened 数组顺序必须在矩阵、RHS 和解向量之间一致。HYPRE 句柄生命周期由调用方通过逻辑开关管理。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_D03_hypre_3Draz_uniform`` module that groups the cylindrical 3D uniform HYPRE Poisson solver routines.

   .. rubric:: Public Entries And Includes

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - File/symbol
        - Role
        - Calling convention
      * - ``sub_D03_hypre_3Draz_uniform.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_D03_hypre_3Draz_uniform_A.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_D03_hypre_3Draz_uniform_A_mpi.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_D03_hypre_3Draz_uniform_bc_A_dielectric.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_D03_hypre_3Draz_uniform_bc_A_outflow.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.

   .. rubric:: Local Assumptions

   These routines use a cell-centered cylindrical ``(r,alpha,z)`` layout and a 7-point stencil. ``dr``, ``da``, and ``dz`` are uniform spacings; flattened matrix, RHS, and solution arrays must use the same order. HYPRE object lifetime is managed by the caller through logical switches.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_D03_hypre_3Draz_uniform.f90
