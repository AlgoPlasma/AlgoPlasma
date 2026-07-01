mod_D02_hypre_3Dxyz_bc.f90
--------------------------

.. raw:: html

   <div class="pmsl-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="zh">中文</button>
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="en">English</button>
   </div>

.. container:: pmsl-lang pmsl-lang-zh

   .. rubric:: 直接用途

   ``mod_D02_hypre_3Dxyz_bc`` 是该目录的模块包装器，集中 include 或暴露本组公开入口。

   .. rubric:: 公开入口与 include 关系

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - 文件/符号
        - 角色
        - 调用约定
      * - ``sub_D02_hypre_3Dxyz_bc.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_D02_hypre_3Dxyz_bc_A.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_D02_hypre_3Dxyz_bc_A_dielectric.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_D02_hypre_3Dxyz_bc_A_outflow.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_D02_hypre_3Dxyz_bc_fortran.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。

   .. rubric:: 局部假设

   本页例程使用 cell-centered 3D Cartesian 逻辑网格和 7 点 stencil。``rho1d``/``RHS`` 与 ``A_values`` 必须采用相同 cell 遍历顺序；边界类型只在对应边界面上修改矩阵系数和 RHS。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: pmsl-lang pmsl-lang-en

   .. rubric:: Direct Purpose

   ``mod_D02_hypre_3Dxyz_bc`` module wrapper for the D02 Cartesian HYPRE Poisson routines.

   .. rubric:: Public Entries And Includes

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - File/symbol
        - Role
        - Calling convention
      * - ``sub_D02_hypre_3Dxyz_bc.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_D02_hypre_3Dxyz_bc_A.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_D02_hypre_3Dxyz_bc_A_dielectric.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_D02_hypre_3Dxyz_bc_A_outflow.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_D02_hypre_3Dxyz_bc_fortran.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.

   .. rubric:: Local Assumptions

   These routines use a cell-centered 3D Cartesian logical grid and a 7-point stencil. ``rho1d``/``RHS`` and ``A_values`` must use the same cell traversal order. Boundary types modify matrix coefficients and RHS only on matching boundary faces.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_D02_hypre_3Dxyz_bc.f90
