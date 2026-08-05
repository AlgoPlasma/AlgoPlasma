F04_field_output
================

.. toctree::
    :maxdepth: 1
    :hidden:

    F04_field_output/mod_F04_field_output
    F04_field_output/sub_F04_field_output_1d_dat
    F04_field_output/sub_F04_field_output_1d_bin
    F04_field_output/sub_F04_field_output_3d_dat
    F04_field_output/sub_F04_field_output_3d_bin
    F04_field_output/sub_F04_field_output_3d_grid_dat
    F04_field_output/sub_F04_field_output_3d_grid_bin

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``F04_field_output`` 是场输出层。它把本 rank 的局部场写为 ASCII 或 binary 文件，
   支持一维 packed、三维 cell-centered，以及 grid-defined 到 cell-centered 的 8 点平均输出。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 角色
      * - :doc:`mod_F04_field_output.f90 <F04_field_output/mod_F04_field_output>`
        - 模块包装器，include 全部场输出例程。
      * - :doc:`sub_F04_field_output_1d_dat.f90 <F04_field_output/sub_F04_field_output_1d_dat>`
        - 将一维 packed 场写成 ASCII 文件。
      * - :doc:`sub_F04_field_output_1d_bin.f90 <F04_field_output/sub_F04_field_output_1d_bin>`
        - 将一维 packed 场写成 binary stream 文件。
      * - :doc:`sub_F04_field_output_3d_dat.f90 <F04_field_output/sub_F04_field_output_3d_dat>`
        - 将 3D cell-centered 场写成 ASCII 文件。
      * - :doc:`sub_F04_field_output_3d_bin.f90 <F04_field_output/sub_F04_field_output_3d_bin>`
        - 将 3D cell-centered 场写成 binary stream 文件。
      * - :doc:`sub_F04_field_output_3d_grid_dat.f90 <F04_field_output/sub_F04_field_output_3d_grid_dat>`
        - 对 grid-defined 场做 8 点平均后写 ASCII cell-centered 值。
      * - :doc:`sub_F04_field_output_3d_grid_bin.f90 <F04_field_output/sub_F04_field_output_3d_grid_bin>`
        - 对 grid-defined 场做 8 点平均后写 binary cell-centered 值。

   .. rubric:: 调用注意

   ``1d`` 和 ``3d`` 例程按调用方提供的数据原样写出；``3d_grid`` 例程会改变数据含义，
   输出的是 cell-centered 平均值而不是原始节点值。需要保留原始节点场时，应使用 ``1d`` 或 ``3d`` 路径自行打包/指定范围。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">刘哲 (2025/12/28; 2025/12/29) · 哈尔滨工业大学</p>
        <p class="ap-home-contact">赵隐剑 (2025/05/14; 2025/12/28; 2026/02/26) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``F04_field_output`` is the field output layer. It writes the current rank's
   local field as ASCII or binary files and supports packed 1D, 3D cell-centered,
   and grid-defined-to-cell-centered 8-point average outputs.

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`mod_F04_field_output.f90 <F04_field_output/mod_F04_field_output>`
        - Module wrapper including all field output routines.
      * - :doc:`sub_F04_field_output_1d_dat.f90 <F04_field_output/sub_F04_field_output_1d_dat>`
        - Write a packed 1D field to ASCII files.
      * - :doc:`sub_F04_field_output_1d_bin.f90 <F04_field_output/sub_F04_field_output_1d_bin>`
        - Write a packed 1D field to binary stream files.
      * - :doc:`sub_F04_field_output_3d_dat.f90 <F04_field_output/sub_F04_field_output_3d_dat>`
        - Write a 3D cell-centered field to ASCII files.
      * - :doc:`sub_F04_field_output_3d_bin.f90 <F04_field_output/sub_F04_field_output_3d_bin>`
        - Write a 3D cell-centered field to binary stream files.
      * - :doc:`sub_F04_field_output_3d_grid_dat.f90 <F04_field_output/sub_F04_field_output_3d_grid_dat>`
        - Average a grid-defined field to cell centers and write ASCII values.
      * - :doc:`sub_F04_field_output_3d_grid_bin.f90 <F04_field_output/sub_F04_field_output_3d_grid_bin>`
        - Average a grid-defined field to cell centers and write binary values.

   .. rubric:: Calling Notes

   ``1d`` and ``3d`` routines write the caller-provided data directly. ``3d_grid``
   routines change the data semantics: the output is the cell-centered average,
   not the original nodal field. If the original nodal field must be preserved,
   pack it or provide its bounds through the ``1d`` or ``3d`` paths.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zhe LIU (2025/12/28; 2025/12/29) · Harbin Institute of Technology</p>
        <p class="ap-home-contact">Yinjian ZHAO (2025/05/14; 2025/12/28; 2026/02/26) · Harbin Institute of Technology</p>
      </div>
