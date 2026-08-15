F03_field_load
==============

.. toctree::
    :maxdepth: 1
    :hidden:

    F03_field_load/mod_F03_field_load
    F03_field_load/sub_F03_field_load_1d_dat
    F03_field_load/sub_F03_field_load_1d_bin
    F03_field_load/sub_F03_field_load_3d_dat
    F03_field_load/sub_F03_field_load_3d_bin

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``F03_field_load`` 读取 F04 写出的场文件。它支持两类布局：调用方已经打包好的一维
   ``F(1:N)``，以及 cell-centered 三维数组 ``F(il(1):iu(1), il(2):iu(2), il(3):iu(3))``。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 角色
      * - :doc:`mod_F03_field_load.f90 <F03_field_load/mod_F03_field_load>`
        - 模块包装器，include 1D/3D 的 ASCII 和 binary 读入例程。
      * - :doc:`sub_F03_field_load_1d_dat.f90 <F03_field_load/sub_F03_field_load_1d_dat>`
        - 从 ASCII 文件读入一维 packed 场。
      * - :doc:`sub_F03_field_load_1d_bin.f90 <F03_field_load/sub_F03_field_load_1d_bin>`
        - 从 binary stream 文件读入一维 packed 场。
      * - :doc:`sub_F03_field_load_3d_dat.f90 <F03_field_load/sub_F03_field_load_3d_dat>`
        - 从 ASCII 文件读入 3D cell-centered 场。
      * - :doc:`sub_F03_field_load_3d_bin.f90 <F03_field_load/sub_F03_field_load_3d_bin>`
        - 从 binary stream 文件读入 3D cell-centered 场。

   .. rubric:: 调用注意

   F03 先读文件头 ``il/iu``，并检查它是否和调用方传入的本地范围一致。F04 的 ``3d_grid`` 输出只保存平均后的 cell-centered 值，所以没有“恢复原始 grid-defined 场”的对称读入例程；读回时使用普通 3D loader。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">刘哲 (2025/12/29; 2026/01/10) · 哈尔滨工业大学</p>
        <p class="ap-home-contact">赵隐剑 (2026/02/27) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``F03_field_load`` reads field files written by F04. It supports two layouts:
   a caller-packed 1D vector ``F(1:N)`` and a 3D cell-centered array
   ``F(il(1):iu(1), il(2):iu(2), il(3):iu(3))``.

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`mod_F03_field_load.f90 <F03_field_load/mod_F03_field_load>`
        - Module wrapper including 1D/3D ASCII and binary loaders.
      * - :doc:`sub_F03_field_load_1d_dat.f90 <F03_field_load/sub_F03_field_load_1d_dat>`
        - Read a packed 1D field from ASCII files.
      * - :doc:`sub_F03_field_load_1d_bin.f90 <F03_field_load/sub_F03_field_load_1d_bin>`
        - Read a packed 1D field from binary stream files.
      * - :doc:`sub_F03_field_load_3d_dat.f90 <F03_field_load/sub_F03_field_load_3d_dat>`
        - Read a 3D cell-centered field from ASCII files.
      * - :doc:`sub_F03_field_load_3d_bin.f90 <F03_field_load/sub_F03_field_load_3d_bin>`
        - Read a 3D cell-centered field from binary stream files.

   .. rubric:: Calling Notes

   F03 reads the ``il/iu`` header first and checks it against the caller's local
   range. F04 ``3d_grid`` output stores only averaged cell-centered values, so
   there is no symmetric loader that reconstructs the original grid-defined field;
   read those files with the regular 3D loaders.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zhe LIU (2025/12/29; 2026/01/10) · Harbin Institute of Technology</p>
        <p class="ap-home-contact">Yinjian ZHAO (2026/02/27) · Harbin Institute of Technology</p>
      </div>
