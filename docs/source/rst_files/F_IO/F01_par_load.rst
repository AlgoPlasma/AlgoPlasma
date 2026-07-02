F01_par_load
============

.. toctree::
    :maxdepth: 1
    :hidden:

    F01_par_load/mod_F01_par_load
    F01_par_load/sub_F01_par_load
    F01_par_load/sub_F01_par_load_dat
    F01_par_load/sub_F01_par_load_bin
    F01_par_load/sub_F01_par_load_h5
    F01_par_load/sub_F01_par_load_count

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``F01_par_load`` 是粒子输入层。它按当前 MPI rank 构造文件名，读取本 rank 的粒子相空间数组 ``par(:,1:np)``。统一入口 ``sub_F01_par_load`` 根据 ``tag`` 分发到
   ``dat``、``bin`` 或 ``h5/hdf5`` 具体读入例程；未知 tag 会提示并回退到 ``dat``。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 角色
      * - :doc:`mod_F01_par_load.f90 <F01_par_load/mod_F01_par_load>`
        - 模块包装器，include dispatcher、ASCII、binary、count，以及可选 HDF5 读入例程。
      * - :doc:`sub_F01_par_load.f90 <F01_par_load/sub_F01_par_load>`
        - 按 ``tag`` 选择具体粒子读入路径。
      * - :doc:`sub_F01_par_load_dat.f90 <F01_par_load/sub_F01_par_load_dat>`
        - 从每 rank ASCII 文件逐行读入 ``par(:,p)``。
      * - :doc:`sub_F01_par_load_bin.f90 <F01_par_load/sub_F01_par_load_bin>`
        - 从 raw Fortran stream binary 文件读入 ``par(:,1:np)``。
      * - :doc:`sub_F01_par_load_h5.f90 <F01_par_load/sub_F01_par_load_h5>`
        - 从 HDF5 数据集 ``par`` 的 hyperslab 读入粒子数组。
      * - :doc:`sub_F01_par_load_count.f90 <F01_par_load/sub_F01_par_load_count>`
        - 按格式推断当前 rank 文件中的粒子数。

   .. rubric:: 调用注意

   粒子输入例程假设调用方已经知道或已经通过 count helper 得到本地 ``np``，并且提供了足够大的
   ``par`` 缓冲区。``dat/bin`` 文件没有保存通用头信息；HDF5 文件需要在编译时启用 ``USE_HDF5=1``。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵隐剑 (2025/04/16; 2025/12/02; 2026/02/28; 2026/03/03) · 哈尔滨工业大学</p>
        <p class="ap-home-contact">刘哲 (2025/11/04; 2025/12/02; 2025/12/03) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``F01_par_load`` is the particle input layer. It constructs the current MPI
   rank's file name and loads the local particle phase-space array
   ``par(:,1:np)``. The common entry ``sub_F01_par_load`` dispatches by ``tag`` to
   ``dat``, ``bin``, or ``h5/hdf5`` readers; unknown tags warn and fall back to
   ``dat``.

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`mod_F01_par_load.f90 <F01_par_load/mod_F01_par_load>`
        - Module wrapper including dispatcher, ASCII, binary, count, and optional HDF5 readers.
      * - :doc:`sub_F01_par_load.f90 <F01_par_load/sub_F01_par_load>`
        - Dispatch particle loading by ``tag``.
      * - :doc:`sub_F01_par_load_dat.f90 <F01_par_load/sub_F01_par_load_dat>`
        - Read ``par(:,p)`` from per-rank ASCII files.
      * - :doc:`sub_F01_par_load_bin.f90 <F01_par_load/sub_F01_par_load_bin>`
        - Read ``par(:,1:np)`` from raw Fortran stream binary files.
      * - :doc:`sub_F01_par_load_h5.f90 <F01_par_load/sub_F01_par_load_h5>`
        - Read a hyperslab from HDF5 dataset ``par``.
      * - :doc:`sub_F01_par_load_count.f90 <F01_par_load/sub_F01_par_load_count>`
        - Infer the local particle count for the current rank file.

   .. rubric:: Calling Notes

   Particle input routines assume that the caller already knows, or has inferred
   with the count helper, the local ``np`` and has provided a large enough
   ``par`` buffer. ``dat/bin`` files do not store universal header metadata; HDF5
   requires ``USE_HDF5=1`` at compile time.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO (2025/04/16; 2025/12/02; 2026/02/28; 2026/03/03) · Harbin Institute of Technology</p>
        <p class="ap-home-contact">Zhe LIU (2025/11/04; 2025/12/02; 2025/12/03) · Harbin Institute of Technology</p>
      </div>
