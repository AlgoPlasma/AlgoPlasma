010_diagnostics Tests
=====================

.. toctree::
   :maxdepth: 1
   :hidden:

   case_broadband_dispersion

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   本节整理 ``tests/010_diagnostics`` 中的 :doc:`K_Diagnostics </rst_files/K_Diagnostics>` 测试。
   与其他测试分类不同，这里被测算法的输入是探针时间序列而不是粒子或场；``K_Diagnostics``
   的计算函数不做文件读写；示例与测试的主程序负责调度计算。

   .. list-table:: 当前测试页面
      :header-rows: 1
      :widths: 10 38 52

      * - ID
        - 测试页面
        - 说明
      * - K01–K03
        - :doc:`case_broadband_dispersion 测试 <case_broadband_dispersion>`
        - 用一份合成宽带信号把 K01、K02、K03 串成一条链驱动，并把每个单元的输出对回生成
          该信号的参数。判据比较谱指数、折叠波数峰和离子声速；单探针对的 K02 检查不声称
          恢复混叠所丢失的折叠阶。

   K04 有独立测试目录 ``tests/011_K04_breathing_waveform/``；
   命令及判据见 :doc:`K04 代码与运行说明 </tests/011_K04_breathing_waveform/index>`。

   静态图片来自一次参考运行，并保存到 ``docs/source/images/tests/010_diagnostics``。
   如果修改了测试程序或绘图脚本，应重新运行并更新这些图片。

.. container:: ap-lang ap-lang-en

   This section collects the :doc:`K_Diagnostics </rst_files/K_Diagnostics>` tests under
   ``tests/010_diagnostics``. Unlike the other test categories, the algorithms under test take
   probe time series rather than particles or fields, and the ``K_Diagnostics`` units are
   numerical routines only: they perform no file I/O; examples and test drivers orchestrate
   the computation.

   .. list-table:: Available test pages
      :header-rows: 1
      :widths: 10 38 52

      * - ID
        - Test page
        - Description
      * - K01–K03
        - :doc:`case_broadband_dispersion test <case_broadband_dispersion>`
        - Drives K01, K02 and K03 as one chain from a single synthetic broadband dataset and
          checks each unit's output against the parameters that produced it. The criteria are
          generator-fixed quantities — a spectral exponent, folded-wavenumber peaks and an ion
          sound speed. The single-pair K02 check does not claim to recover the lost fold order.

   K04 tests live in the separate ``tests/011_K04_breathing_waveform/`` directory;
   see the :doc:`K04 running guide </tests/011_K04_breathing_waveform/index>` for commands and criteria.

   The static figures come from one reference run and are stored under
   ``docs/source/images/tests/010_diagnostics``. Regenerate and update them if the test program
   or the plotting script changes.
