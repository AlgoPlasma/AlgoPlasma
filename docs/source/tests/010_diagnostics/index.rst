010_diagnostics Tests
=====================

.. toctree::
   :maxdepth: 1
   :hidden:

   case_basic_checks
   case_broadband_dispersion

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   本节整理 :doc:`K_Diagnostics </rst_files/K_Diagnostics>` 中 K01–K03 的基础数值与宽带链路测试，
   对应 :doc:`探针波动诊断专题 </rst_files/K_Diagnostics/probe_wave_diagnostics>`。
   基础测试直接构造数值输入，宽带测试从合成探针时序出发，检查频谱、相位统计和波矢反演。
   计算函数不做文件读写；示例与测试的主程序提供数据并调度计算。

   .. list-table:: 当前测试页面
      :header-rows: 1
      :widths: 10 38 52

      * - ID
        - 测试页面
        - 说明
      * - K01–K03
        - :doc:`基础数值测试 <case_basic_checks>`
        - 三组数值验证，直接比较参考值、实测值、误差与判据；表格由运行记录生成，完整报告另附链接。
      * - K01–K03
        - :doc:`case_broadband_dispersion 测试 <case_broadband_dispersion>`
        - 用一份合成宽带信号把 K01、K02、K03 串成一条链驱动，并把每个单元的输出对回生成
          该信号的参数。判据比较谱指数、折叠波数峰和离子声速；单探针对的 K02 检查不声称
          恢复混叠所丢失的折叠阶。

   K04 有独立测试目录 ``tests/011_K04_breathing_waveform/``；
   命令及判据见 :doc:`K04 代码与运行说明 </tests/011_K04_breathing_waveform/index>`。

   基础数值测试的数值与图件快照存放在本目录的 ``_generated/case_basic_checks``，由 run.sh --publish-docs 更新。
   宽频页面保留一组参考运行图，存放在 ``docs/source/images/tests/010_diagnostics``，图注说明对应结果。

.. container:: ap-lang ap-lang-en

   This section collects the basic numerical and broadband-chain tests for K01–K03 in
   :doc:`K_Diagnostics </rst_files/K_Diagnostics>`, supporting the
   :doc:`probe wave diagnostics topic </rst_files/K_Diagnostics/probe_wave_diagnostics>`.
   Basic checks supply numerical inputs directly; the broadband case starts from synthetic
   probe time series and tests spectra, phase statistics and wavevector inversion.
   Numerical routines perform no file I/O; examples and test drivers provide data and
   orchestrate the computation.

   .. list-table:: Available test pages
      :header-rows: 1
      :widths: 10 38 52

      * - ID
        - Test page
        - Description
      * - K01–K03
        - :doc:`basic_numerical tests <case_basic_checks>`
        - Three verification groups with references, measurements, errors, criteria and status from the run record. The complete report is linked separately.
      * - K01–K03
        - :doc:`case_broadband_dispersion test <case_broadband_dispersion>`
        - Drives K01, K02 and K03 as one chain from a single synthetic broadband dataset and
          checks each unit's output against the parameters that produced it. The criteria are
          generator-fixed quantities — a spectral exponent, folded-wavenumber peaks and an ion
          sound speed. The single-pair K02 check does not claim to recover the lost fold order.

   K04 tests live in the separate ``tests/011_K04_breathing_waveform/`` directory;
   see the :doc:`K04 running guide </tests/011_K04_breathing_waveform/index>` for commands and criteria.

   The basic_numerical tests snapshot is stored under ``_generated/case_basic_checks`` and refreshed with run.sh --publish-docs.
   Broadband reference-run figures are stored under ``docs/source/images/tests/010_diagnostics``; their captions identify the results.
