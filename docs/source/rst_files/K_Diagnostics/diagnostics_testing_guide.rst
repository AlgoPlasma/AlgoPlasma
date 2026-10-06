=========================
Diagnostics Testing Guide
=========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 1. 范围

   本页介绍两类互补测试：

   - :doc:`基础数值测试 </tests/010_diagnostics/case_basic_checks>`：按频谱功率与相位、相位统计、
     Beall 权重与谱峰展示三组验证。参考值、实测值、误差、判据和状态
     从同次运行记录生成；底层 16 项检查的完整报告另附链接。
   - :doc:`宽频色散综合测试 </tests/010_diagnostics/case_broadband_dispersion>`：从合成波形出发，
     依次调用 K01、K02、K03，将输出与生成器参数比较。MLE 阵列每构型使用 256 段。

   两个案例各自提供 run.sh。基础测试以单进程向量化计算完成小型检查；
   宽频测试按频点并行进行网格搜索。宽频结果统一发布在案例页面。

   .. rubric:: 2. 测试矩阵

   K01 验证频谱、阈值交点和相干度；K02 验证折叠谱峰；K03 同时验证整体色散关系、逐频点波矢和搜索标记。
   :doc:`宽带测试页 </tests/010_diagnostics/case_broadband_dispersion>` 提供同次运行生成的完整判据、图表及逐频点下载，避免多处手工复制结果。

   .. rubric:: 3. 快速运行命令

   .. code-block:: bash

      bash tests/010_diagnostics/case_basic_checks/run.sh
      bash tests/010_diagnostics/case_broadband_dispersion/run.sh

   .. rubric:: 4. 建议验证顺序

   - 先看 ``output/summary.json`` 里 K01 的谱指数：它只依赖 ``fun_K01_segment_ffts`` 和
     ``fun_K01_power_spectrum``，若这一条不过，后面两个单元的结果都不必看。
   - 再看 K02 有效频段的循环波数残差，按直方图格宽归一化。它只验证折叠波数趋势，不能恢复原始折叠阶。
   - 最后同时检查 K03 声速、波数模长和方向；只看声速无法发现波矢整体反号。
   - 图上再核一遍：``beall_skf.png`` 应看到重复锯齿，``mle_dispersion.png`` 应看到同一支被还原成直线。

   .. rubric:: 5. 结果解读

   summary.json 记录验收状态、逐频点误差及失败原因，modes.csv 便于逐行检查。先对照输入参数与参考量，再查看超出容差的频段或构型，
   可定位误差来自频谱估计、相位统计还是波矢搜索。图件用于观察相应的谱形和色散关系。

   .. rubric:: 6. 说明

   案例是纯 Python，``make.sh`` 不编译而是生成合成记录。仓库中不存放任何信号：记录每次运行时由
   ``source_py/config.py`` 的常量重建，并由 ``clean.sh`` 删除。运行耗时取决于网格和并行资源。

.. container:: ap-lang ap-lang-en

   .. rubric:: 1. Scope

   Two complementary cases exercise the diagnostics:

   - :doc:`basic_numerical tests </tests/010_diagnostics/case_basic_checks>`:
     three verification groups for spectral power and phase, phase statistics, and Beall weights and peaks.
     References, measurements, errors, criteria,
     and status come from the same run; the complete report retains all sixteen regression checks.
   - :doc:`Broadband dispersion </tests/010_diagnostics/case_broadband_dispersion>`:
     synthetic waveforms pass through K01, K02 and K03; outputs are compared with generator
     parameters. The MLE array uses 256 segments per configuration.

   Each case has its own run.sh. Basic checks use small vectorized calculations in one process;
   the broadband case searches frequency grids in parallel. Broadband results are published on the case page.

   .. rubric:: 2. Test Matrix

   K01 checks spectra, the assessment-threshold crossing and coherence; K02 checks folded peaks;
   K03 checks aggregate dispersion, each recovered vector and search flags.
   The :doc:`broadband page </tests/010_diagnostics/case_broadband_dispersion>` contains acceptance limits,
   figures and per-mode downloads from one run.

   .. rubric:: 3. Quick Run Commands

   .. code-block:: bash

      bash tests/010_diagnostics/case_basic_checks/run.sh
      bash tests/010_diagnostics/case_broadband_dispersion/run.sh

   .. rubric:: 4. Suggested Validation Order

   - Start with the K01 spectral exponent in ``output/summary.json``: it depends only on
     ``fun_K01_segment_ffts`` and ``fun_K01_power_spectrum``, and if it fails the other two
     units need not be read.
   - Next inspect grid-normalized circular residuals in valid K02 bins. These test the folded trend, not recovery of the original fold order.
   - Finally inspect K03 sound speed, magnitude and direction. Sound speed alone cannot detect reversal of the wavevector.
   - Confirm on the figures as well: ``beall_skf.png`` should show the repeating sawtooth and
     ``mle_dispersion.png`` the same branch recovered straight.

   .. rubric:: 5. Reading the Results

   summary.json records acceptance, per-mode errors and failure reasons; modes.csv provides the same per-mode records. Compare inputs and reference values, then inspect
   frequencies or configurations outside the tolerance to locate differences in spectral estimation,
   phase statistics or wavevector search. Figures show the corresponding spectra and dispersion.

   .. rubric:: 6. Notes

   The case is pure Python, so ``make.sh`` generates the synthetic records instead of compiling.
   No signal is stored in the repository: the records are rebuilt from the constants in
   ``source_py/config.py`` on every run and removed by ``clean.sh``. Runtime depends on the grid and parallel resources.
