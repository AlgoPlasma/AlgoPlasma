mod_G01_collision.f90
---------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_G01_collision`` 是该目录的模块包装器，集中 include 或暴露本组公开入口。

   .. rubric:: 公开入口与 include 关系

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - 文件/符号
        - 角色
        - 调用约定
      * - ``sub_G01_load_cross_section.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_G01_collision1.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_G01_collision2.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_G01_electron.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``fun_G01_cross_section.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。

   .. rubric:: 局部假设

   碰撞例程假定粒子数组 ``par(1:6,...)`` 中 ``1:3`` 是位置、``4:6`` 是速度。随机数来自 Fortran ``random_number``；能量、截面、密度和时间步单位必须由调用方保持自洽。这里不替调用方设置随机种子。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_G01_collision`` is documented by its generated API and local notes on this page.

   .. rubric:: Public Entries And Includes

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - File/symbol
        - Role
        - Calling convention
      * - ``sub_G01_load_cross_section.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_G01_collision1.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_G01_collision2.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_G01_electron.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``fun_G01_cross_section.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.

   .. rubric:: Local Assumptions

   Collision routines assume ``par(1:6,...)`` stores position in ``1:3`` and velocity in ``4:6``. Random numbers come from Fortran ``random_number``. Units of energy, cross section, density, and time step must be kept self-consistent by the caller. These routines do not seed the RNG.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_G01_collision.f90
