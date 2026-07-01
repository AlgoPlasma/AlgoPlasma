mod_F04_field_output.f90
------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_F04_field_output`` 是该目录的模块包装器，集中 include 或暴露本组公开入口。

   .. rubric:: 公开入口与 include 关系

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - 文件/符号
        - 角色
        - 调用约定
      * - ``sub_F04_field_output_1d_dat.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_F04_field_output_1d_bin.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_F04_field_output_3d_dat.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_F04_field_output_3d_bin.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_F04_field_output_3d_grid_dat.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。
      * - ``sub_F04_field_output_3d_grid_bin.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。

   .. rubric:: 局部假设

   I/O 例程不改变数据物理含义，只按约定文件名和数组内存顺序读写。raw ``.bin`` 文件使用默认 Fortran ``real`` 的 stream 数据；读写双方必须使用一致的实数精度、端序和数组 shape。HDF5 入口依赖 ``USE_HDF5`` 构建宏和 HDF5 模块。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_F04_field_output`` module wrapper for F04 field output subroutines. Included files: - ``sub_F04_field_output_1d_dat.f90`` - ``sub_F04_field_output_1d_bin.f90`` - ``sub_F04_field_output_3d_dat.f90`` - ``sub_F04_field_output_3d_bin.f90`` - ``sub_F04_field_output_3d_grid_dat.f90`` - ``sub_F04_field_output_3d_grid_bin.f90``

   .. rubric:: Public Entries And Includes

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - File/symbol
        - Role
        - Calling convention
      * - ``sub_F04_field_output_1d_dat.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_F04_field_output_1d_bin.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_F04_field_output_3d_dat.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_F04_field_output_3d_bin.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_F04_field_output_3d_grid_dat.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.
      * - ``sub_F04_field_output_3d_grid_bin.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.

   .. rubric:: Local Assumptions

   I/O routines do not change the physical meaning of data; they only read or write arrays using the naming and memory-order conventions. Raw ``.bin`` files store default Fortran ``real`` stream data, so readers and writers must agree on real kind, endianness, and array shape. HDF5 entries depend on the ``USE_HDF5`` build macro and HDF5 module.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_F04_field_output.f90
