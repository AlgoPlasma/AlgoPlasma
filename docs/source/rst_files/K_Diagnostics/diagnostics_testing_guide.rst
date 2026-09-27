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

   - :doc:`基础与边界条件测试 </tests/010_diagnostics/case_basic_checks>`：用 12 组小型确定性输入
     检查统计量、权重、网格和输入条件，展示实际数值、参考值、验收判据及 4 张解释图。
   - :doc:`宽频色散综合测试 </tests/010_diagnostics/case_broadband_dispersion>`：从合成波形出发，
     依次调用 K01、K02、K03，将输出与生成器参数比较。MLE 阵列每构型使用 256 段。

   两个案例各自提供 run.sh。基础测试以单进程向量化计算完成小型检查；
   宽频测试按频点并行进行网格搜索。下表列出宽频参考运行的结果。

   .. rubric:: 2. 测试矩阵

   .. list-table::
      :header-rows: 1
      :widths: 12 50 38

      * - 单元
        - 判据
        - 实测
      * - K01
        - 从测得的谱里拟合回生成器的谱指数
        - −2.002 对 −2
      * - K01
        - 下带边；谱与噪声底相交的频率是否符合 :math:`1/f^2` 律的预言
        - 104 kHz；752 kHz 对预言的 725 kHz
      * - K01
        - 相干度在高出噪声底的频点上接近 1，带外落到 :math:`1/n_{\rm seg}` 的底
        - 0.933 与 0.00248，底为 0.003906
      * - K02
        - 高于 10 倍噪声底的模态，其折叠波数峰残差的 95 分位是否小于 2 个网格
        - 评价 84 个模态；圆周残差中位数 0.443 格，p95 为 1.466 格
      * - K02
        - 生成的色散支确实被多次折叠
        - 238 个模态全部混叠，跨越 10 个理论折叠阶
      * - K03
        - 把 :math:`f` 对 :math:`|\hat k|` 拟合成过原点的直线，斜率还原离子声速
        - 3833.2 对 3824.6 m/s，相对误差 2.27e-3

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

   summary.json 记录验收状态及误差。先对照输入参数与参考量，再查看超出容差的频段或构型，
   可定位误差来自频谱估计、相位统计还是波矢搜索。图件用于观察相应的谱形和色散关系。

   .. rubric:: 6. 说明

   案例是纯 Python，``make.sh`` 不编译而是生成合成记录。仓库中不存放任何信号：记录每次运行时由
   ``source_py/config.py`` 的常量重建，并由 ``clean.sh`` 删除。运行耗时取决于网格和并行资源。

.. container:: ap-lang ap-lang-en

   .. rubric:: 1. Scope

   Two complementary cases exercise the diagnostics:

   - :doc:`Basic and boundary-condition checks </tests/010_diagnostics/case_basic_checks>`:
     twelve small deterministic cases covering statistics, weights, grids and input conditions,
     with measured values, references, criteria and four explanatory figures.
   - :doc:`Broadband dispersion </tests/010_diagnostics/case_broadband_dispersion>`:
     synthetic waveforms pass through K01, K02 and K03; outputs are compared with generator
     parameters. The MLE array uses 256 segments per configuration.

   Each case has its own run.sh. Basic checks use small vectorized calculations in one process;
   the broadband case searches frequency grids in parallel. The table below reports the broadband run.

   .. rubric:: 2. Test Matrix

   .. list-table::
      :header-rows: 1
      :widths: 12 50 38

      * - Unit
        - Criterion
        - Measured
      * - K01
        - The generator's spectral exponent fitted back out of the measured spectrum
        - −2.002 against −2
      * - K01
        - The lower band edge; the frequency at which the spectrum meets the noise floor as the
          :math:`1/f^2` law predicts
        - 104 kHz; 752 kHz against 725 kHz predicted
      * - K01
        - Coherence near 1 where modes stand clear of the floor, at the
          :math:`1/n_{\rm seg}` floor outside the band
        - 0.933 and 0.00248, against a floor of 0.003906
      * - K02
        - Folded-wavenumber peaks above ten times the noise floor stay within two grid bins at the 95th percentile of
          the closed-form prediction
        - 84 modes assessed; circular-residual median 0.443 bins, p95 1.466 bins
      * - K02
        - The generated branch is genuinely folded, many times over
        - All 238 modes aliased across 10 theoretical fold orders
      * - K03
        - Fitting :math:`f` against :math:`|\hat k|` through the origin returns the ion sound
          speed
        - 3833.2 against 3824.6 m/s, relative error 2.27e-3

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

   summary.json records acceptance status and errors. Compare inputs and reference values, then inspect
   frequencies or configurations outside the tolerance to locate differences in spectral estimation,
   phase statistics or wavevector search. Figures show the corresponding spectra and dispersion.

   .. rubric:: 6. Notes

   The case is pure Python, so ``make.sh`` generates the synthetic records instead of compiling.
   No signal is stored in the repository: the records are rebuilt from the constants in
   ``source_py/config.py`` on every run and removed by ``clean.sh``. Runtime depends on the grid and parallel resources.
