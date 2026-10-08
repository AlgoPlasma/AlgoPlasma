J01 Tests
==========================================================================================

.. toctree::
   :maxdepth: 1
   :hidden:

   01 Local Processes <J01_fm_tests>
   02 Complete FM Solve <J01_solver_tests>
   03 Legacy Updates <J01_tests>

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 从抽样到完整粒子计算

   J01 通过粒子历史计算稳态密度和面通量。测试分两层：
   先固定输入验证采样、反射、跟踪和统计各过程，再由完整主入口把这些过程连接起来。
   保留的三维连续性更新和二维给定速度通量位于第三页。

   .. list-table::
      :header-rows: 1
      :widths: 22 38 40

      * - 阅读顺序
        - 怎样构造测试
        - 怎样判定
      * - 01 Local Processes
        - 给定入口区间、速度或统计数组，直接调用一个过程；对采样增加三组固定种子的概率检查
        - 面积积分、正态/Rayleigh 累积概率、直线轨迹时间、粒子率归一化
      * - 02 Complete FM Solve
        - 单单元镜面通道，调用完整主入口生成 200 条粒子历史；另用受限事件数检查失败状态
        - 所有历史完整、注入与逃逸粒子率相等、场量有效；错误输入返回指定状态
      * - 03 Legacy Updates
        - 三维指定密度和速度；二维指定通量与源损
        - 单步公式、整格平移、保护层、周期守恒及四面符号

   例如，局部统计测试直接指定驻留时间 2；完整计算则让轨迹过程累计驻留时间。
   前者检查归一化公式，后者检查粒子历史到场数组的完整计算过程。

   .. rubric:: 程序与运行顺序

   测试源码位于 ``tests/012_fluid/J01_free_molecular/source_f90``。
   ``run.sh`` 依次执行：

   1. ``test_J01_continuity_freeflow``：原三维单步过程。
   2. ``test_J01_faceflux_2Drz_units``：二维通量、单步及单单元完整 FM。
   3. ``test_J01_fm_units``：入口、反射、轨迹、统计及主入口失败状态。
   4. ``test_J01_corner_crossings``：四种速度符号下的角点与阶梯边界。
   5. ``test_J01_sampling_distribution``：入口和四面漫反射的解析概率。

   文档按“过程→组装→保留接口”阅读；脚本按上述程序清单执行。
   各程序自行建立输入，运行时彼此独立。

   .. code-block:: bash

      bash tests/012_fluid/J01_free_molecular/run.sh

   单项复查时，可先执行同目录 ``make.sh``，再运行 ``build/测试程序名.out``。
   全部五个程序在 2026-10-06 通过；每项容差见相应测试页。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Test progression

   Verify inlet sampling, reflection, trajectories and tally normalization with
   prescribed inputs first. Then call the complete FM driver in a reflecting one-cell
   channel and check particle-rate conservation and failure reporting.
   The retained 3D update and 2D velocity-to-flux utilities are documented separately.

   The five programs under ``J01_free_molecular/source_f90`` run in this order:
   ``test_J01_continuity_freeflow``, ``test_J01_faceflux_2Drz_units``,
   ``test_J01_fm_units``, ``test_J01_corner_crossings`` and
   ``test_J01_sampling_distribution``. Each builds its own inputs.

   .. code-block:: bash

      bash tests/012_fluid/J01_free_molecular/run.sh

   All five passed on 2026-10-06. For individual execution, run the local
   ``make.sh`` and the corresponding ``build/test_*.out``.
