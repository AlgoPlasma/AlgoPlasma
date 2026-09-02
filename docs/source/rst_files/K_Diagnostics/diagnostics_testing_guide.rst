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

   本页说明 ``K_Diagnostics`` 的验证方式。三个单元共用一个测试案例
   :doc:`case_broadband_dispersion </tests/010_diagnostics/index>`：一份合成宽带信号同时驱动
   K01、K02、K03，每个单元的输出对回生成该信号的参数。单元本身只是子程序、不做任何计算调度，
   计算全部发生在案例里。

   .. rubric:: 2. 测试矩阵

   .. list-table::
      :header-rows: 1
      :widths: 12 50 38

      * - 单元
        - 判据
        - 实测
      * - K01
        - 从测得的谱里拟合回生成器的谱指数
        - −2.015 对 −2
      * - K01
        - 下带边；谱与噪声底相交的频率是否符合 :math:`1/f^2` 律的预言
        - 104 kHz；816 kHz 对预言的 733 kHz
      * - K01
        - 相干度在高出噪声底的频点上接近 1，带外落到 :math:`1/n_{\rm seg}` 的底
        - 0.932 与 0.038，底为 0.0625
      * - K02
        - 每个模态是否被归到正确的折叠阶
        - 最大圆周残差为折叠周期的 11%
      * - K02
        - 色散支确实被多次折叠
        - 238 个模态全部混叠，10 个折叠阶
      * - K03
        - 把 :math:`f` 对 :math:`|\hat k|` 拟合成过原点的直线，斜率还原离子声速
        - 3829.6 对 3824.6 m/s，相对误差 1.3e-3

   .. rubric:: 3. 快速运行命令

   .. code-block:: bash

      cd tests/010_diagnostics/case_broadband_dispersion
      bash run.sh

   .. rubric:: 4. 建议验证顺序

   - 先看 ``output/summary.json`` 里 K01 的谱指数：它只依赖 ``fun_K01_segment_ffts`` 和
     ``fun_K01_power_spectrum``，若这一条不过，后面两个单元的结果都不必看。
   - 再看 K02 的折叠残差相对折叠周期的比例。归错阶会差近整整一个周期，因此这个比例远小于 1
     才说明 ``fun_K02_fold_order`` 与实测峰位一致。
   - 最后看 K03 的拟合声速。它是整条链路的端到端判据：任何一环的符号、归一化或加权出错，
     这个数都会明显偏离。
   - 图上再核一遍：``beall_skf.png`` 应看到重复锯齿，``mle_dispersion.png`` 应看到同一支被还原成直线。

   .. rubric:: 5. 结果解读

   每条判据的形式都是"把生成信号时用到的某个量从测量里测回来"，而不是取一个能让测试通过的容差。
   所以判据失败时应先怀疑实现，而不是先放宽阈值。若确实需要调整，应说明该量的解析预期为何改变。

   .. rubric:: 6. 说明

   案例是纯 Python，``make.sh`` 不编译而是生成合成记录。仓库中不存放任何信号：记录每次运行时由
   ``source_py/config.py`` 的常量重建，并由 ``clean.sh`` 删除。整次运行约数秒。

.. container:: ap-lang ap-lang-en

   .. rubric:: 1. Scope

   This page describes how ``K_Diagnostics`` is validated. The three units share one test case,
   :doc:`case_broadband_dispersion </tests/010_diagnostics/index>`: a single synthetic broadband
   dataset drives K01, K02 and K03, and each output is checked against the parameters that
   produced the signal. The units are subroutines that schedule no computation; all of it
   happens in the case.

   .. rubric:: 2. Test Matrix

   .. list-table::
      :header-rows: 1
      :widths: 12 50 38

      * - Unit
        - Criterion
        - Measured
      * - K01
        - The generator's spectral exponent fitted back out of the measured spectrum
        - −2.015 against −2
      * - K01
        - The lower band edge; the frequency at which the spectrum meets the noise floor as the
          :math:`1/f^2` law predicts
        - 104 kHz; 816 kHz against 733 kHz predicted
      * - K01
        - Coherence near 1 where modes stand clear of the floor, at the
          :math:`1/n_{\rm seg}` floor outside the band
        - 0.932 and 0.038, against a floor of 0.0625
      * - K02
        - Every mode assigned to the correct aliasing fold
        - Largest circular residual 11 % of one fold period
      * - K02
        - The branch is genuinely folded, many times over
        - All 238 modes aliased across 10 fold orders
      * - K03
        - Fitting :math:`f` against :math:`|\hat k|` through the origin returns the ion sound
          speed
        - 3829.6 against 3824.6 m/s, relative error 1.3e-3

   .. rubric:: 3. Quick Run Commands

   .. code-block:: bash

      cd tests/010_diagnostics/case_broadband_dispersion
      bash run.sh

   .. rubric:: 4. Suggested Validation Order

   - Start with the K01 spectral exponent in ``output/summary.json``: it depends only on
     ``fun_K01_segment_ffts`` and ``fun_K01_power_spectrum``, and if it fails the other two
     units need not be read.
   - Next read the K02 fold residual as a fraction of one fold period. A misassigned order is
     off by nearly a whole period, so a small fraction is what shows ``fun_K02_fold_order``
     agreeing with the measured peak.
   - Finally read the fitted sound speed from K03. It is the end-to-end criterion of the whole
     chain: a sign, normalisation or weighting error anywhere will move it visibly.
   - Confirm on the figures as well: ``beall_skf.png`` should show the repeating sawtooth and
     ``mle_dispersion.png`` the same branch recovered straight.

   .. rubric:: 5. Reading the Results

   Every criterion has the same shape, a quantity the generator was built from recovered from
   the measurement, rather than a tolerance chosen to make the test pass. A failure should
   therefore raise suspicion of the implementation before the threshold. If a threshold really
   must change, the analytic expectation for that quantity should be restated.

   .. rubric:: 6. Notes

   The case is pure Python, so ``make.sh`` generates the synthetic records instead of compiling.
   No signal is stored in the repository: the records are rebuilt from the constants in
   ``source_py/config.py`` on every run and removed by ``clean.sh``. A full run takes a few
   seconds.
