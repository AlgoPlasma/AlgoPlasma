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

   本节整理 ``tests/010_diagnostics`` 中的 :doc:`K_Diagnostics </rst_files/K_Diagnostics>` 测试。
   与其他测试分类不同，这里被测算法的输入是探针时间序列而不是粒子或场；``K_Diagnostics``
   的单元只是子程序，不做任何文件读写，也不调度计算——计算全部发生在测试里。

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

   基础数值测试的数值与图件快照存放在本目录的 ``_generated/case_basic_checks``，由 run.sh --publish-docs 更新。
   宽频页面保留一组参考运行图，存放在 ``docs/source/images/tests/010_diagnostics``，图注说明对应结果。

.. container:: ap-lang ap-lang-en

   This section collects the :doc:`K_Diagnostics </rst_files/K_Diagnostics>` tests under
   ``tests/010_diagnostics``. Unlike the other test categories, the algorithms under test take
   probe time series rather than particles or fields, and the ``K_Diagnostics`` units are
   subroutines only: they perform no file I/O and schedule no computation of their own — all of
   it happens in the test.

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

   The basic_numerical tests snapshot is stored under ``_generated/case_basic_checks`` and refreshed with run.sh --publish-docs.
   Broadband reference-run figures are stored under ``docs/source/images/tests/010_diagnostics``; their captions identify the results.
