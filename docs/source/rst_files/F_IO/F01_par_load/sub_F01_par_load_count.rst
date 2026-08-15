sub_F01_par_load_count.f90
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_F01_par_load_count`` 读取指定粒子文件的列数/粒子数，用于调用者分配或检查粒子数组容量。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``tag``
        - in
        - scalar or caller-provided array
        - I/O 格式选择标签，调度到 dat/bin/h5 等具体读写例程。
      * - ``label``
        - in
        - scalar or caller-provided array
        - 文件目录名和文件名前缀；通常是简单名字，不应包含路径分隔符。
      * - ``it``
        - in
        - scalar or caller-provided array
        - 时间步或迭代编号，会按固定宽度编码到文件名中。
      * - ``nvar``
        - in
        - scalar or caller-provided array
        - 粒子变量数或文件中的变量列数。
      * - ``np``
        - out
        - scalar or caller-provided array
        - 粒子数；读写例程只处理 ``par(:,1:np)``，碰撞/交换例程可能更新它。

   .. rubric:: 局部假设

   I/O 例程不改变数据物理含义，只按约定文件名和数组内存顺序读写。raw ``.bin`` 文件使用默认 Fortran ``real`` 的 stream 数据；读写双方必须使用一致的实数精度、端序和数组 shape。HDF5 入口依赖 ``USE_HDF5`` 构建宏和 HDF5 模块。

   .. rubric:: 实现逻辑

   调度入口根据 ``tag`` 选择具体文件格式例程，不直接改变数组内容。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_F01_par_load_count`` get local particle count np from per-rank dat/bin/h5 file.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``tag``
        - in
        - scalar or caller-provided array
        - 'dat'|'bin'|'h5'|'hdf5'
      * - ``label``
        - in
        - scalar or caller-provided array
        - directory and file prefix
      * - ``it``
        - in
        - scalar or caller-provided array
        - iteration index encoded in file name
      * - ``nvar``
        - in
        - scalar or caller-provided array
        - number of particle variables (required for 'bin'; optional check for 'h5'; ignored
          for 'dat')
      * - ``np``
        - out
        - scalar or caller-provided array
        - particle count inferred from file

   .. rubric:: Local Assumptions

   I/O routines do not change the physical meaning of data; they only read or write arrays using the naming and memory-order conventions. Raw ``.bin`` files store default Fortran ``real`` stream data, so readers and writers must agree on real kind, endianness, and array shape. HDF5 entries depend on the ``USE_HDF5`` build macro and HDF5 module.

   .. rubric:: Implementation Notes

   The dispatch entry selects the concrete file-format routine from ``tag`` and does not otherwise transform the array content.

   .. rubric:: Generated API

   .. doxygenfile:: sub_F01_par_load_count.f90
