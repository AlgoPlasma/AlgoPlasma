mod_D04_hypre_3Draz_nonuniform.f90
----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_D04_hypre_3Draz_nonuniform`` 是该目录的模块包装器，集中 include 或暴露本组公开入口。

   .. rubric:: 公开入口与 include 关系

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - 文件/符号
        - 角色
        - 调用约定
      * - ``sub_D04_hypre_3Draz_nonuniform.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_D04_hypre_3Draz_nonuniform_A.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_D04_hypre_3Draz_nonuniform_A_mpi.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_D04_hypre_3Draz_nonuniform_bc_A_outflow.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 柱坐标 ``(r,alpha,z)``；flattened 数组只覆盖调用方给定的 owned/active cells。非均匀版本的 ``dr``、``da``、``dz`` 是方向相关间距数组，MPI 版本需要包含相邻 ghost/halo 间距。HYPRE 句柄的生命周期由 ``do_init``、``do_updateA``、``do_finalize`` 或 C 包装器控制。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_D04_hypre_3Draz_nonuniform`` group the cylindrical 3D nonuniform HYPRE Poisson routines.

   .. rubric:: Public Entries And Includes

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - File/symbol
        - Role
        - Calling convention
      * - ``sub_D04_hypre_3Draz_nonuniform.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_D04_hypre_3Draz_nonuniform_A.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_D04_hypre_3Draz_nonuniform_A_mpi.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_D04_hypre_3Draz_nonuniform_bc_A_dielectric.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_D04_hypre_3Draz_nonuniform_bc_A_outflow.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.

   .. rubric:: Local Assumptions

   These routines use a cell-centered cylindrical ``(r,alpha,z)`` layout. Flattened arrays cover only the caller-provided owned/active cells. In the nonuniform variant, ``dr``, ``da``, and ``dz`` are directional spacing arrays; MPI-local assembly needs neighboring halo spacings. HYPRE handle lifetime is controlled by ``do_init``, ``do_updateA``, ``do_finalize``, or by the C wrapper.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_D04_hypre_3Draz_nonuniform.f90
