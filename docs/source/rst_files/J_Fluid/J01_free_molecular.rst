J01_free_molecular
=================================================================

.. toctree::
   :maxdepth: 1

   J01_free_molecular/particle_transport
   J01_free_molecular/continuity

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>


.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 这部分代码做什么

   J01 的文件统一放在 ``J_Fluid/J01_free_molecular``。其中有两类计算：
   一类从入口发射粒子，得到稳态中性场；另一类使用给定速度，计算连续性方程的通量或密度更新。
   两类计算各自保留一个 mod 文件，避免把不同的输入和算法混在同一个调用入口。

   .. list-table::
      :header-rows: 1
      :widths: 30 35 35

      * - 计算
        - 输入
        - 输出
      * - :doc:`粒子前处理 <J01_free_molecular/particle_transport>`
        - 网格、入口分布、壁面条件、采样参数
        - 参考密度、平均速度、带符号面通量
      * - :doc:`连续性与通量工具 <J01_free_molecular/continuity>`
        - 已有密度、给定速度或面通量、源损项
        - 面通量或一步更新后的密度

   .. rubric:: 如何选择

   要从入口和壁面条件计算自由分子场，调用 ``mod_J01_neutral_free_molecular_2Drz``。
   它的采样、轨迹、反射和统计各有一个 sub 文件，主过程负责按顺序调用。
   计算完成后，应用驱动将参考场传给 J03，继续求解连续性方程。

   要沿用三维连续性更新，或在已有速度场上计算二维 LF 通量，调用 ``mod_J01_continuity_freeflow``。
   它不跟踪粒子，也不替代粒子前处理。原过程名与参数保留。

   .. rubric:: 与 J02、J03 的区别

   J01 的粒子方法通过多条轨迹统计输运；J02 用离散纵标和 DG 求解分布。
   二者是不同的前处理方法，各自将密度和面通量交给 J03。
   J03 根据参考密度和通量确定面速度，再用当前密度更新通量。
   因此后续冻结的是面速度，不是通量本身。

   当前 FM 模型只有 r、z 两个速度分量，不含周向运动和体内电离；入口采用截断正态事件分布。
   这些条件会影响结果，不能只因网格相同就认为 FM 与 SN 的物理模型相同。
   各过程页面分别给出公式、单位、数组形状、前置条件和对应测试。

   .. rubric:: 编译与测试

   源码目录内的两个 mod 文件分别包含所需 sub 文件，编译器需启用预处理。
   不单独编译 sub 文件；同时引入两个模块时用 ``only`` 选择过程，避免同名常量冲突。
   所有 J01 小测试统一由以下命令运行：

   .. code-block:: bash

      bash tests/011_fluid/J01_free_molecular/run.sh

   测试说明：:doc:`连续性与通量 </tests/011_fluid/J01_tests>`、
   :doc:`粒子模块 </tests/011_fluid/J01_fm_tests>`。
   FM 与 J03 的完整连接算例见 :doc:`应用测试 </tests/011_fluid/application_tests>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   All J01 sources are in one directory. ``mod_J01_neutral_free_molecular_2Drz`` computes particle
   preprocessing fields from inlet and wall conditions. ``mod_J01_continuity_freeflow`` retains
   the existing 3D continuity update and 2D prescribed-velocity utilities.
   Compile the required modules, not individual include files. Use selective imports when using both.

   J01 particle transport and J02 SN transport are alternative preprocessors. Both provide reference
   density and face fluxes to J03, which freezes face velocity rather than flux. The FM model is
   reduced two-velocity r-z transport without volume ionization or azimuthal motion.

   Run ``bash tests/011_fluid/J01_free_molecular/run.sh`` for all J01 unit tests.
