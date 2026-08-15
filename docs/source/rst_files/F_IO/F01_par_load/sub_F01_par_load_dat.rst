sub_F01_par_load_dat.f90
------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_F01_par_load_dat`` 读取粒子数组 ``par``，文件名由 ``label``、``it`` 和 MPI rank 或格式标签决定。

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
      * - ``np``
        - in
        - scalar or caller-provided array
        - 粒子数；读写例程只处理 ``par(:,1:np)``，碰撞/交换例程可能更新它。
      * - ``par``
        - out
        - ``(:,:)``
        - 粒子数组；通常 ``1:3`` 为位置，``4:6`` 为速度，列或第二维为粒子编号。

   .. rubric:: 局部假设

   I/O 例程不改变数据物理含义，只按约定文件名和数组内存顺序读写。raw ``.bin`` 文件使用默认 Fortran ``real`` 的 stream 数据；读写双方必须使用一致的实数精度、端序和数组 shape。HDF5 入口依赖 ``USE_HDF5`` 构建宏和 HDF5 模块。

   .. rubric:: 实现逻辑

   实现使用格式化文本文件顺序读写，适合检查和调试；大型数据建议使用 binary 或 HDF5 入口。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_F01_par_load_dat`` load particle data from per-rank ASCII files.

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
        - integer, current time step or iteration index.
      * - ``np``
        - in
        - scalar or caller-provided array
        - integer, number of particle records (columns) to read on this MPI rank.
      * - ``par``
        - out
        - ``(:,:)``
        - real,dimension(:,:), particle data array read into ``par(:,p)`` for ``p = 1..np``.

   .. rubric:: Local Assumptions

   I/O routines do not change the physical meaning of data; they only read or write arrays using the naming and memory-order conventions. Raw ``.bin`` files store default Fortran ``real`` stream data, so readers and writers must agree on real kind, endianness, and array shape. HDF5 entries depend on the ``USE_HDF5`` build macro and HDF5 module.

   .. rubric:: Implementation Notes

   The implementation uses formatted text I/O, useful for inspection and debugging. For large data, prefer binary or HDF5 entries.

   .. rubric:: Generated API

   .. doxygenfile:: sub_F01_par_load_dat.f90
