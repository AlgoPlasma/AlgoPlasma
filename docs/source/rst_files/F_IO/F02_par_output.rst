F02_par_output
==============

.. toctree::
    :maxdepth: 1
    :hidden:

    F02_par_output/mod_F02_par_output
    F02_par_output/sub_F02_par_output
    F02_par_output/sub_F02_par_output_dat
    F02_par_output/sub_F02_par_output_bin
    F02_par_output/sub_F02_par_output_h5

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``F02_par_output`` 是粒子输出层。它将本 rank 的 ``par(:,1:np)`` 写入独立文件，
   统一入口 ``sub_F02_par_output`` 根据 ``tag`` 选择 ASCII、binary 或 HDF5 writer。
   未知 tag 会提示并回退到 ``dat``。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 角色
      * - :doc:`mod_F02_par_output.f90 <F02_par_output/mod_F02_par_output>`
        - 模块包装器，include dispatcher、ASCII、binary 和可选 HDF5 输出例程。
      * - :doc:`sub_F02_par_output.f90 <F02_par_output/sub_F02_par_output>`
        - 按 ``tag`` 分发粒子输出。
      * - :doc:`sub_F02_par_output_dat.f90 <F02_par_output/sub_F02_par_output_dat>`
        - 每个粒子一行写成 ASCII ``.dat``。
      * - :doc:`sub_F02_par_output_bin.f90 <F02_par_output/sub_F02_par_output_bin>`
        - 写 raw Fortran stream ``.bin``，无 record markers。
      * - :doc:`sub_F02_par_output_h5.f90 <F02_par_output/sub_F02_par_output_h5>`
        - 写 HDF5 文件和数据集 ``par``。

   .. rubric:: 调用注意

   输出例程会使用 ``label`` 作为目录和文件名前缀。不要把目录路径作为 ``label`` 传入；
   需要整理目录结构时应由外层脚本或调用方处理。粒子 HDF5 writer 只在 ``USE_HDF5=1`` 时编译进模块。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵隐剑 (2025/04/16; 2025/12/02; 2026/02/28) · 哈尔滨工业大学</p>
        <p class="ap-home-contact">刘哲 (2025/11/04; 2025/12/02) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``F02_par_output`` is the particle output layer. It writes the current rank's
   ``par(:,1:np)`` to a separate file. The common entry ``sub_F02_par_output``
   selects the ASCII, binary, or HDF5 writer by ``tag``. Unknown tags warn and
   fall back to ``dat``.

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`mod_F02_par_output.f90 <F02_par_output/mod_F02_par_output>`
        - Module wrapper including dispatcher, ASCII, binary, and optional HDF5 writers.
      * - :doc:`sub_F02_par_output.f90 <F02_par_output/sub_F02_par_output>`
        - Dispatch particle output by ``tag``.
      * - :doc:`sub_F02_par_output_dat.f90 <F02_par_output/sub_F02_par_output_dat>`
        - Write one ASCII ``.dat`` record per particle.
      * - :doc:`sub_F02_par_output_bin.f90 <F02_par_output/sub_F02_par_output_bin>`
        - Write raw Fortran stream ``.bin`` without record markers.
      * - :doc:`sub_F02_par_output_h5.f90 <F02_par_output/sub_F02_par_output_h5>`
        - Write an HDF5 file with dataset ``par``.

   .. rubric:: Calling Notes

   Output routines use ``label`` both as the directory and file prefix. Do not
   pass a directory path as ``label``; organize higher-level paths outside this
   routine layer. The particle HDF5 writer is compiled into the module only when
   ``USE_HDF5=1`` is defined.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO (2025/04/16; 2025/12/02; 2026/02/28) · Harbin Institute of Technology</p>
        <p class="ap-home-contact">Zhe LIU (2025/11/04; 2025/12/02) · Harbin Institute of Technology</p>
      </div>
