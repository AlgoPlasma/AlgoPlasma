F_IO
====

.. toctree::
    :maxdepth: 1

    F_IO/F01_par_load
    F_IO/F02_par_output
    F_IO/F03_field_load
    F_IO/F04_field_output

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   ``F_IO`` 提供 AlgoPlasma 中按 MPI rank 组织的数据输入输出例程。它不负责全局重排或可视化，
   而是把本 rank 的粒子相空间数组、局部场数组或由网格节点平均得到的 cell-centered 场写入约定文件名，并在读回时恢复同一 rank 的本地数据。

   .. list-table:: 模块关系
      :header-rows: 1
      :widths: 18 26 34 22

      * - 模块
        - 数据对象
        - 主要职责
        - 格式
      * - :doc:`F01_par_load <F_IO/F01_par_load>`
        - 粒子 ``par(nvar,np)``
        - 从每个 rank 的粒子文件读回本地粒子数组，并提供本地粒子数统计辅助例程。
        - ``dat`` / ``bin`` / ``h5``
      * - :doc:`F02_par_output <F_IO/F02_par_output>`
        - 粒子 ``par(nvar,np)``
        - 将本地粒子相空间数组写成每 rank 一个文件；dispatcher 按 tag 选择具体格式。
        - ``dat`` / ``bin`` / ``h5``
      * - :doc:`F03_field_load <F_IO/F03_field_load>`
        - 场 ``F(1:N)`` 或 ``F(i,j,k)``
        - 读取 F04 写出的本地场文件；支持 1D packed 和 3D cell-centered 布局。
        - ``dat`` / ``bin``
      * - :doc:`F04_field_output <F_IO/F04_field_output>`
        - 场 ``F(1:N)``、``F(i,j,k)`` 或 grid-defined ``F(il-1:iu)``
        - 输出本地场文件；grid 输出会把 8 个节点值平均成 cell-centered 值。
        - ``dat`` / ``bin``

   .. rubric:: 文件命名和边界

   F_IO 采用 per-rank 文件策略，典型文件名为：

   .. code-block:: text

      label/label_IIIIIIIIII_RRRRR.ext

   其中 ``IIIIIIIIII`` 是 ``it`` 的 10 位编号，``RRRRR`` 是 MPI rank 的 5 位编号，
   ``ext`` 是 ``dat``、``bin`` 或 ``h5``。``label`` 同时作为目录名和文件名前缀，
   因此应使用简单名字，不要传入包含 ``/`` 的路径。输出例程通常由 rank 0 创建目录，
   随后用 ``MPI_BARRIER`` 同步。

   .. rubric:: 数据约定

   - 粒子文件不保存 ``np`` 或 ``nvar`` 这样的通用头信息；读者需要由调用方提供数组形状和本地粒子数。
   - ``sub_F01_load_par_count`` 可按 ``dat`` 行数、``bin`` 文件大小或 HDF5 数据集形状推断本 rank 粒子数。
   - 场文件在 payload 前保存 6 个整数：``il(1:3)`` 和 ``iu(1:3)``。
   - 二进制文件使用 Fortran unformatted stream，依赖一致的默认 ``integer``/``real`` 字节宽度和端序。
   - HDF5 粒子路径受 ``USE_HDF5=1`` 预处理宏控制，需要 HDF5 Fortran 绑定。

   .. rubric:: 测试入口

   当前回归测试见 :doc:`003_F_IO 测试说明 </tests/003_F_IO/index>`。该测试覆盖粒子
   ``dat/bin/h5`` round-trip、dispatcher fallback、场 ``1d/3d/grid`` round-trip，
   并用逐元素比较触发 ``MPI_ABORT`` 来保证失败可见。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   ``F_IO`` provides MPI-rank-local input and output routines for AlgoPlasma. It does not
   perform global reassembly or visualization. Instead, each routine writes or
   loads the current rank's particle phase-space array, local field array, or
   cell-centered values reconstructed from a grid-defined field using a shared
   file naming convention.

   .. list-table:: Module Map
      :header-rows: 1
      :widths: 18 26 34 22

      * - Module
        - Data object
        - Main responsibility
        - Formats
      * - :doc:`F01_par_load <F_IO/F01_par_load>`
        - Particle ``par(nvar,np)``
        - Load local particle arrays from per-rank files and provide a local particle-count helper.
        - ``dat`` / ``bin`` / ``h5``
      * - :doc:`F02_par_output <F_IO/F02_par_output>`
        - Particle ``par(nvar,np)``
        - Write local particle phase-space arrays, with a dispatcher selecting the concrete format.
        - ``dat`` / ``bin`` / ``h5``
      * - :doc:`F03_field_load <F_IO/F03_field_load>`
        - Field ``F(1:N)`` or ``F(i,j,k)``
        - Read local field files written by F04 for 1D packed and 3D cell-centered layouts.
        - ``dat`` / ``bin``
      * - :doc:`F04_field_output <F_IO/F04_field_output>`
        - Field ``F(1:N)``, ``F(i,j,k)``, or grid-defined ``F(il-1:iu)``
        - Write local field files; grid output averages eight node values to cell centers.
        - ``dat`` / ``bin``

   .. rubric:: File Naming and Scope

   F_IO uses one file per MPI rank. A typical name is:

   .. code-block:: text

      label/label_IIIIIIIIII_RRRRR.ext

   Here ``IIIIIIIIII`` is the 10-digit iteration index, ``RRRRR`` is the 5-digit
   MPI rank, and ``ext`` is ``dat``, ``bin``, or ``h5``. ``label`` is used both as
   the directory name and file prefix, so callers should pass a simple name rather
   than a string containing ``/``. Output routines usually let rank 0 create the
   directory and then synchronize with ``MPI_BARRIER``.

   .. rubric:: Data Conventions

   - Particle files do not store universal header metadata such as ``np`` or ``nvar``; callers provide the buffer shape and local particle count.
   - ``sub_F01_load_par_count`` can infer the local particle count from ``dat`` line counts, ``bin`` file size, or an HDF5 dataset shape.
   - Field files store six header integers before the payload: ``il(1:3)`` and ``iu(1:3)``.
   - Binary files use Fortran unformatted stream I/O and require matching default ``integer``/``real`` sizes and endianness.
   - Particle HDF5 paths are guarded by the ``USE_HDF5=1`` preprocessor macro and require the HDF5 Fortran bindings.

   .. rubric:: Test Entry

   The current regression test is documented in :doc:`003_F_IO test overview
   </tests/003_F_IO/index>`. It covers particle ``dat/bin/h5`` round trips,
   dispatcher fallback behavior, and field ``1d/3d/grid`` round trips, with
   element-wise comparisons that call ``MPI_ABORT`` on failure.
