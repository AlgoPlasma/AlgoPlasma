mod_F01_par_load.f90
--------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_F01_par_load`` 是该目录的模块包装器，集中 include 或暴露本组公开入口。

   .. rubric:: 公开入口与 include 关系

   下列源码文件由 ``mod_F01_par_load`` 在 ``contains`` 中 include；调用方通常
   ``use mod_F01_par_load`` 后调用具体例程，不应把这些 include 文件当作独立
   translation unit 编译。``sub_F01_par_load_h5.f90`` 只在启用 ``USE_HDF5``
   时参与编译。

   .. list-table::
      :header-rows: 1
      :widths: 32 38 30

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_F01_par_load.f90``
        - 按 ``tag`` 分发到 ``dat``、``bin`` 或 ``h5/hdf5`` 具体读取例程。
        - 调用方希望用一个统一入口根据格式读取粒子数据。
      * - ``sub_F01_par_load_dat.f90``
        - 从每个 MPI rank 对应的 ASCII ``.dat`` 文件逐行读取 ``par(:,p)``。
        - 调试、人工检查或与 ``sub_F02_par_output_dat`` 配套读取文本粒子文件。
      * - ``sub_F01_par_load_bin.f90``
        - 从 raw stream ``.bin`` 文件读取 ``par(:,1:np)``，不读取额外头信息。
        - 读取与 ``sub_F02_par_output_bin`` 配套的轻量二进制粒子文件。
      * - ``sub_F01_par_load_count.f90``
        - 根据格式推断本 rank 粒子数：``dat`` 数行、``bin`` 查文件大小、``h5`` 查 ``par`` 数据集维度。
        - 在分配 ``par`` 或调用读取例程前先确定 ``np``。
      * - ``sub_F01_par_load_h5.f90``
        - 从每个 MPI rank 对应的 HDF5 ``.h5`` 文件中读取二维数据集 ``par`` 的前 ``np`` 列。
        - 启用 HDF5 构建后读取与 ``sub_F02_par_output_h5`` 配套的粒子文件。

   .. rubric:: 局部假设

   I/O 例程不改变数据物理含义，只按约定文件名和数组内存顺序读写。raw ``.bin`` 文件使用默认 Fortran ``real`` 的 stream 数据；读写双方必须使用一致的实数精度、端序和数组 shape。HDF5 入口依赖 ``USE_HDF5`` 构建宏和 HDF5 模块。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_F01_par_load`` is the module wrapper for F01 particle-loading
   routines. It exposes the format dispatcher, format-specific readers, and the
   particle-count helper through one module.

   .. rubric:: Public Entries And Includes

   The following source files are included inside ``mod_F01_par_load`` under
   ``contains``. Callers normally ``use mod_F01_par_load`` and call the
   concrete routines; the include files are not standalone translation units.
   ``sub_F01_par_load_h5.f90`` is compiled only when ``USE_HDF5`` is enabled.

   .. list-table::
      :header-rows: 1
      :widths: 32 38 30

      * - File
        - Function
        - Typical use
      * - ``sub_F01_par_load.f90``
        - Dispatches to the concrete ``dat``, ``bin``, or ``h5/hdf5`` reader according to ``tag``.
        - Use one format-neutral entry point to load particle data.
      * - ``sub_F01_par_load_dat.f90``
        - Reads ``par(:,p)`` line by line from the per-rank ASCII ``.dat`` file.
        - Debuggable text input paired with ``sub_F02_par_output_dat``.
      * - ``sub_F01_par_load_bin.f90``
        - Reads ``par(:,1:np)`` from a raw stream ``.bin`` file with no extra header.
        - Lightweight binary input paired with ``sub_F02_par_output_bin``.
      * - ``sub_F01_par_load_count.f90``
        - Infers the local particle count: line count for ``dat``, file size for ``bin``, or ``par`` dataset shape for ``h5``.
        - Determine ``np`` before allocating ``par`` or calling a reader.
      * - ``sub_F01_par_load_h5.f90``
        - Reads the first ``np`` columns from the HDF5 dataset ``par`` in the per-rank ``.h5`` file.
        - HDF5 particle input paired with ``sub_F02_par_output_h5``.

   .. rubric:: Local Assumptions

   I/O routines do not change the physical meaning of data; they only read or write arrays using the naming and memory-order conventions. Raw ``.bin`` files store default Fortran ``real`` stream data, so readers and writers must agree on real kind, endianness, and array shape. HDF5 entries depend on the ``USE_HDF5`` build macro and HDF5 module.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_F01_par_load.f90
