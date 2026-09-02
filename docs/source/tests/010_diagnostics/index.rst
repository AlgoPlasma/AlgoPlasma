010_diagnostics
===============

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 宽带色散链路测试

   ``tests/010_diagnostics/case_broadband_dispersion`` 用一份合成宽带信号同时驱动
   :doc:`K_Diagnostics </rst_files/K_Diagnostics>` 的三个单元，并把每一个的输出对回生成该信号的
   参数。``K_Diagnostics`` 的单元只是子程序、不做任何计算调度，计算全部发生在这个案例里。

   信号模型取自 ``simulation/simulation_beall/02宽频``：氙、``T_e = 20 eV``、``c_s = 3825 m/s``、
   无离子漂移，色散支为 ``ω = k·c_s``；100 kHz–2 MHz 频带内**每个频点一个模态**，幅度律
   ``A ∝ 1/f``，随机相位只抽一次由全部分段共用，时域逐模态叠加后每路探针加独立白高斯噪声，
   宽带信噪比为 10。反演阵列是 35 个构型（3.0–5.0 mm × 0–90°），Beall 另用一对**故意选粗的
   20 mm 探针**——可见折叠条数为 ``f_max/f_alias``、``f_alias = c_s/(2d)``，所以加粗间距与
   加宽频带等效，而前者不会推高反演网格的成本。

   .. list-table:: 判据
      :header-rows: 1
      :widths: 12 52 36

      * - 单元
        - 判据
        - 实测
      * - K01
        - 从测得的谱里拟合回生成器的谱指数
        - −2.015 对 −2
      * - K01
        - 下带边，以及谱与噪声底相交的频率是否符合 ``1/f²`` 律的预言
        - 104 kHz；816 kHz 对预言的 733 kHz
      * - K02
        - 每个模态是否被归到正确的折叠阶
        - 最大圆周残差为折叠周期的 11%；238 个模态全部混叠，10 个折叠阶
      * - K03
        - 把 ``f`` 对 ``|k̂|`` 拟合成过原点的直线，斜率还原离子声速
        - 3829.6 对 3824.6 m/s，相对误差 1.3e-3

   每条判据形式相同：把生成信号时用到的某个量从测量里测回来再对比，而不是取一个能让测试通过的容差。

   .. rubric:: 运行方式

   案例是纯 Python，所以 ``make.sh`` 不编译而是生成合成记录，``run.sh`` 把它们送过三个单元。
   仓库中不存放任何信号：记录每次运行时由 ``source_py/config.py`` 的常量重建，并由 ``clean.sh`` 删除。

   .. code-block:: bash

      cd tests/010_diagnostics/case_broadband_dispersion
      bash run.sh

   ``make.sh`` 把记录写进 ``build/``，``source_py/analyze.py`` 把结果写进 ``output/summary.json``
   和 ``output/figures/`` 下的四张图。三项检验全部通过时退出码为 0。整次运行约数秒，
   ``build/`` 约 11 MB。

.. container:: ap-lang ap-lang-en

   .. rubric:: Broadband Dispersion Chain Test

   ``tests/010_diagnostics/case_broadband_dispersion`` drives all three units of
   :doc:`K_Diagnostics </rst_files/K_Diagnostics>` from one synthetic broadband dataset and
   checks each output against the parameters that produced it. The ``K_Diagnostics`` units are
   subroutines that schedule no computation of their own; all of it happens in this case.

   The signal model is taken from ``simulation/simulation_beall/02宽频``: xenon at
   ``T_e = 20 eV`` giving ``c_s = 3825 m/s`` with no ion drift, on the branch ``omega = k c_s``;
   **one mode per frequency bin** across 100 kHz to 2 MHz, an amplitude law ``A ~ 1/f``, random
   phases drawn once and shared by every segment, superposed mode by mode in the time domain,
   with independent white Gaussian noise on each probe at a broadband ratio of 10. The inversion
   array is 35 configurations (3.0–5.0 mm at 0–90 deg); the Beall map uses a separate,
   **deliberately coarse 20 mm pair**, since the number of visible folds is ``f_max / f_alias``
   with ``f_alias = c_s / (2 d)``, so coarsening the separation and widening the band are
   equivalent and only the former leaves the inversion grid untouched.

   .. list-table:: Criteria
      :header-rows: 1
      :widths: 12 52 36

      * - Unit
        - Criterion
        - Measured
      * - K01
        - The generator's spectral exponent is fitted back out of the measured spectrum
        - −2.015 against −2
      * - K01
        - The lower band edge, and the frequency at which the spectrum meets the noise floor as the ``1/f^2`` law predicts
        - 104 kHz; 816 kHz against 733 kHz predicted
      * - K02
        - Every mode is assigned to the correct aliasing fold
        - Largest circular residual 11 % of one fold period; all 238 modes aliased across 10 fold orders
      * - K03
        - Fitting ``f`` against ``|k_hat|`` through the origin returns the ion sound speed
        - 3829.6 against 3824.6 m/s, relative error 1.3e-3

   Every criterion has the same shape: a quantity the generator was built from is recovered from
   the measurement and compared back, rather than a tolerance chosen to make the test pass.

   .. rubric:: Running

   The case is pure Python, so ``make.sh`` generates the synthetic records instead of compiling
   and ``run.sh`` reduces them through the three units. No signal is stored in the repository:
   the records are rebuilt from the constants in ``source_py/config.py`` on every run and
   removed by ``clean.sh``.

   .. code-block:: bash

      cd tests/010_diagnostics/case_broadband_dispersion
      bash run.sh

   ``make.sh`` writes the records into ``build/`` and ``source_py/analyze.py`` writes
   ``output/summary.json`` together with four figures under ``output/figures/``. The exit code
   is 0 when all three checks pass. A full run takes a few seconds and leaves about 11 MB in
   ``build/``.
