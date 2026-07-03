mod_F03_field_load.f90
----------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_F03_field_load`` 汇总场数据载入入口，从 per-rank ``.dat`` 或 ``.bin``
   文件恢复 cell-centered 场数组。

   .. rubric:: 公开入口与 include 关系

   下列文件在 ``mod_F03_field_load`` 的 ``contains`` 作用域内 include。调用方应
   ``use mod_F03_field_load`` 后调用具体例程；不要把这些 include 文件单独编译。
   本模块没有 ``3d_grid`` 对称载入入口，因为对应输出已经把 grid-defined 数据平均为
   cell-centered 值，不能恢复原始网格量。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_F03_field_load_1d_dat.f90``
        - 从 ASCII ``.dat`` 文件读取 header 和 1D 场向量。
        - 输入数据以线性数组保存，且需要文本格式便于检查。
      * - ``sub_F03_field_load_1d_bin.f90``
        - 从 raw stream ``.bin`` 文件读取 header 和 1D 场向量。
        - 输入数据以线性数组保存，且希望使用紧凑二进制格式。
      * - ``sub_F03_field_load_3d_dat.f90``
        - 从 ASCII ``.dat`` 文件读取 3D cell-centered 场数组。
        - 需要直接恢复 ``F(il:iu,...)`` 形式的文本场数据。
      * - ``sub_F03_field_load_3d_bin.f90``
        - 从 raw stream ``.bin`` 文件读取 3D cell-centered 场数组，并校验 index header。
        - 需要直接恢复 3D 场数组，且读写双方约定实数精度和端序。

   .. rubric:: 局部假设

   I/O 例程不改变数据物理含义，只按约定文件名和数组内存顺序读写。raw ``.bin`` 文件使用默认 Fortran ``real`` 的 stream 数据；读写双方必须使用一致的实数精度、端序和数组 shape。HDF5 入口依赖 ``USE_HDF5`` 构建宏和 HDF5 模块。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_F03_field_load`` groups field-loading entry points that restore
   cell-centered fields from per-rank ``.dat`` or ``.bin`` files.

   .. rubric:: Public Entries And Includes

   The following files are included inside the ``contains`` scope of
   ``mod_F03_field_load``. Callers should ``use mod_F03_field_load`` and call
   the concrete routines through the module; do not compile these include files
   separately. No symmetric ``3d_grid`` loader is provided because the matching
   output routines write reconstructed cell-centered values, not the original
   grid-defined field.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_F03_field_load_1d_dat.f90``
        - Reads an ASCII ``.dat`` header and a 1D field vector.
        - Restore text field data stored in a caller-defined linear layout.
      * - ``sub_F03_field_load_1d_bin.f90``
        - Reads a raw stream ``.bin`` header and a 1D field vector.
        - Restore compact binary field data stored in a linear layout.
      * - ``sub_F03_field_load_3d_dat.f90``
        - Reads an ASCII ``.dat`` file into a 3D cell-centered field array.
        - Restore readable text data directly into ``F(il:iu,...)``.
      * - ``sub_F03_field_load_3d_bin.f90``
        - Reads a raw stream ``.bin`` file into a 3D field array and checks index headers.
        - Restore compact binary 3D data when real kind and endianness match.

   .. rubric:: Local Assumptions

   I/O routines do not change the physical meaning of data; they only read or write arrays using the naming and memory-order conventions. Raw ``.bin`` files store default Fortran ``real`` stream data, so readers and writers must agree on real kind, endianness, and array shape. HDF5 entries depend on the ``USE_HDF5`` build macro and HDF5 module.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_F03_field_load.f90
