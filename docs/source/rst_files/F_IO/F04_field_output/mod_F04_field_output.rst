mod_F04_field_output.f90
------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_F04_field_output`` 汇总场数据输出入口，把 cell-centered 场或由
   grid-defined 场平均得到的 cell-centered 值写到 per-rank 文件。

   .. rubric:: 公开入口与 include 关系

   下列文件在 ``mod_F04_field_output`` 的 ``contains`` 作用域内 include。调用方应
   ``use mod_F04_field_output`` 后调用具体例程；不要把这些 include 文件单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_F04_field_output_1d_dat.f90``
        - 以 ASCII ``.dat`` 写出 1D 场向量和 index header。
        - 场数据已由调用方打包为线性数组，且希望文本可读。
      * - ``sub_F04_field_output_1d_bin.f90``
        - 以 raw stream ``.bin`` 写出 1D 场向量和 index header。
        - 场数据已线性打包，且希望输出紧凑二进制文件。
      * - ``sub_F04_field_output_3d_dat.f90``
        - 以 ASCII ``.dat`` 写出 3D cell-centered 场数组。
        - 需要直接输出 ``F(il:iu,...)`` 形式的文本场数据。
      * - ``sub_F04_field_output_3d_bin.f90``
        - 以 raw stream ``.bin`` 写出 3D cell-centered 场数组。
        - 需要直接输出 3D 场数组，并由匹配 reader 读取。
      * - ``sub_F04_field_output_3d_grid_dat.f90``
        - 将 grid-defined 3D 场在八个相邻节点上平均后，以 ASCII 写出 cell-centered 值。
        - 需要把节点/网格量转换成便于查看的 cell-centered 文本结果。
      * - ``sub_F04_field_output_3d_grid_bin.f90``
        - 将 grid-defined 3D 场平均为 cell-centered 值后，以 raw stream ``.bin`` 写出。
        - 需要保存由网格量重构的紧凑二进制 cell-centered 结果。

   .. rubric:: 局部假设

   I/O 例程不改变数据物理含义，只按约定文件名和数组内存顺序读写。raw ``.bin`` 文件使用默认 Fortran ``real`` 的 stream 数据；读写双方必须使用一致的实数精度、端序和数组 shape。HDF5 入口依赖 ``USE_HDF5`` 构建宏和 HDF5 模块。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_F04_field_output`` groups field-output entry points for cell-centered
   fields and for cell-centered values reconstructed from grid-defined fields.

   .. rubric:: Public Entries And Includes

   The following files are included inside the ``contains`` scope of
   ``mod_F04_field_output``. Callers should ``use mod_F04_field_output`` and call
   the concrete routines through the module; do not compile these include files
   separately.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_F04_field_output_1d_dat.f90``
        - Writes a 1D field vector and index header to ASCII ``.dat`` files.
        - Output readable text data after the caller has packed the field linearly.
      * - ``sub_F04_field_output_1d_bin.f90``
        - Writes a 1D field vector and index header to raw stream ``.bin`` files.
        - Output compact binary data from a caller-defined linear layout.
      * - ``sub_F04_field_output_3d_dat.f90``
        - Writes a 3D cell-centered field array to ASCII ``.dat`` files.
        - Output readable text data directly from ``F(il:iu,...)``.
      * - ``sub_F04_field_output_3d_bin.f90``
        - Writes a 3D cell-centered field array to raw stream ``.bin`` files.
        - Output compact 3D field data for a matching reader.
      * - ``sub_F04_field_output_3d_grid_dat.f90``
        - Averages a grid-defined 3D field to cell centers and writes ASCII ``.dat`` files.
        - Inspect grid-defined quantities as cell-centered text output.
      * - ``sub_F04_field_output_3d_grid_bin.f90``
        - Averages a grid-defined 3D field to cell centers and writes raw stream ``.bin`` files.
        - Store reconstructed cell-centered values in compact binary form.

   .. rubric:: Local Assumptions

   I/O routines do not change the physical meaning of data; they only read or write arrays using the naming and memory-order conventions. Raw ``.bin`` files store default Fortran ``real`` stream data, so readers and writers must agree on real kind, endianness, and array shape. HDF5 entries depend on the ``USE_HDF5`` build macro and HDF5 module.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_F04_field_output.f90
