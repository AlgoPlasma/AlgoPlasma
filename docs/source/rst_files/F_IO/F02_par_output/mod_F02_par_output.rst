mod_F02_par_output.f90
----------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_F02_par_output`` 汇总粒子输出入口，并按格式标签把本地粒子数组写到
   对应的 per-rank 文件中。

   .. rubric:: 公开入口与 include 关系

   下列文件在 ``mod_F02_par_output`` 的 ``contains`` 作用域内 include。调用方应
   ``use mod_F02_par_output`` 后调用具体例程；不要把这些 include 文件单独编译。
   HDF5 入口只在启用 ``USE_HDF5`` 时参与构建。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_F02_par_output.f90``
        - 根据 ``tag`` 分派到 ``dat``、``bin`` 或 ``h5/hdf5`` 输出例程。
        - 调用方希望用统一入口选择粒子输出格式。
      * - ``sub_F02_par_output_dat.f90``
        - 逐粒子写出 ASCII ``.dat`` 文件，每个 MPI rank 一个文件。
        - 需要可读文本结果，便于调试或小规模后处理。
      * - ``sub_F02_par_output_bin.f90``
        - 写出 raw stream ``.bin`` 文件，只保存 ``par(:,1:np)`` 数据块。
        - 需要紧凑二进制输出，且读写双方已约定实数精度和数组 shape。
      * - ``sub_F02_par_output_h5.f90``
        - 写出 HDF5 ``.h5`` 文件，在 ``par`` 数据集上附带 ``it`` 和 ``rank`` 属性。
        - 需要带元数据的并行粒子输出，并且构建环境启用了 HDF5。

   .. rubric:: 局部假设

   I/O 例程不改变数据物理含义，只按约定文件名和数组内存顺序读写。raw ``.bin`` 文件使用默认 Fortran ``real`` 的 stream 数据；读写双方必须使用一致的实数精度、端序和数组 shape。HDF5 入口依赖 ``USE_HDF5`` 构建宏和 HDF5 模块。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_F02_par_output`` groups particle-output entry points and writes local
   particle arrays to per-rank files selected by a format tag.

   .. rubric:: Public Entries And Includes

   The following files are included inside the ``contains`` scope of
   ``mod_F02_par_output``. Callers should ``use mod_F02_par_output`` and call
   the concrete routines through the module; do not compile these include files
   separately. The HDF5 entry is available only when ``USE_HDF5`` is enabled.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_F02_par_output.f90``
        - Dispatches by ``tag`` to the ``dat``, ``bin``, or ``h5/hdf5`` writer.
        - Use a single format-neutral particle-output entry point.
      * - ``sub_F02_par_output_dat.f90``
        - Writes ASCII ``.dat`` files, one particle record per line and one file per MPI rank.
        - Prefer readable text output for debugging or small post-processing jobs.
      * - ``sub_F02_par_output_bin.f90``
        - Writes raw stream ``.bin`` files containing only ``par(:,1:np)``.
        - Prefer compact binary output when real kind and array shape are already agreed on.
      * - ``sub_F02_par_output_h5.f90``
        - Writes HDF5 ``.h5`` files with a ``par`` dataset and ``it``/``rank`` attributes.
        - Use metadata-carrying particle output when HDF5 is enabled.

   .. rubric:: Local Assumptions

   I/O routines do not change the physical meaning of data; they only read or write arrays using the naming and memory-order conventions. Raw ``.bin`` files store default Fortran ``real`` stream data, so readers and writers must agree on real kind, endianness, and array shape. HDF5 entries depend on the ``USE_HDF5`` build macro and HDF5 module.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_F02_par_output.f90
