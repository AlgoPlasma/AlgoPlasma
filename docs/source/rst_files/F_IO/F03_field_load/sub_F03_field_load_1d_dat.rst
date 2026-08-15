sub_F03_field_load_1d_dat.f90
-----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_F03_field_load_1d_dat`` 从文件读取一维或三维场数组 ``F`` 到调用方给定的索引范围。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``label``
        - in
        - scalar or caller-provided array
        - 文件目录名和文件名前缀；通常是简单名字，不应包含路径分隔符。
      * - ``it``
        - in
        - scalar or caller-provided array
        - 时间步或迭代编号，会按固定宽度编码到文件名中。
      * - ``il``
        - out
        - ``(1:3)``
        - 本地 active cell 下界索引。
      * - ``iu``
        - out
        - ``(1:3)``
        - 本地 active cell 上界索引。
      * - ``F``
        - out
        - ``(1:N)``
        - 场数组；读写或交换范围由 ``il``/``iu`` 和 ghost cell 约定决定。

   .. rubric:: 局部假设

   I/O 例程不改变数据物理含义，只按约定文件名和数组内存顺序读写。raw ``.bin`` 文件使用默认 Fortran ``real`` 的 stream 数据；读写双方必须使用一致的实数精度、端序和数组 shape。HDF5 入口依赖 ``USE_HDF5`` 构建宏和 HDF5 模块。

   .. rubric:: 实现逻辑

   实现使用格式化文本文件顺序读写，适合检查和调试；大型数据建议使用 binary 或 HDF5 入口。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_F03_field_load_1d_dat`` load a 3D cell-centered field stored as a 1D vector from per-rank ASCII files.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``label``
        - in
        - scalar or caller-provided array
        - character(*), input directory and file name prefix; should be a simple name and must
          not contain ``/``.
      * - ``it``
        - in
        - scalar or caller-provided array
        - integer, time step index encoded in the file name.
      * - ``il``
        - out
        - ``(1:3)``
        - integer (1:3), cell-centered lower indices in x,y,z, read from file.
      * - ``iu``
        - out
        - ``(1:3)``
        - integer (1:3), cell-centered upper indices in x,y,z, read from file.
      * - ``F``
        - out
        - ``(1:N)``
        - real, allocatable (1:N), 1D field vector read from file, where ``N = nx*ny*nz``.

   .. rubric:: Local Assumptions

   I/O routines do not change the physical meaning of data; they only read or write arrays using the naming and memory-order conventions. Raw ``.bin`` files store default Fortran ``real`` stream data, so readers and writers must agree on real kind, endianness, and array shape. HDF5 entries depend on the ``USE_HDF5`` build macro and HDF5 module.

   .. rubric:: Implementation Notes

   The implementation uses formatted text I/O, useful for inspection and debugging. For large data, prefer binary or HDF5 entries.

   .. rubric:: Generated API

   .. doxygenfile:: sub_F03_field_load_1d_dat.f90
