case_broadband_dispersion Test
==============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本页说明 ``tests/010_diagnostics/case_broadband_dispersion`` 中的参考测试。
   测试用一份合成宽带信号同时驱动 :doc:`K_Diagnostics </rst_files/K_Diagnostics>`
   的三个单元，并把每一个的输出对回生成该信号的参数：

   - :doc:`K01_signal_spectra </rst_files/K_Diagnostics/K01_signal_spectra>`：分段谱、功率谱、
     相干度、互相位及其众数参考的均值与方差。
   - :doc:`K02_beall </rst_files/K_Diagnostics/K02_beall>`：混叠几何的闭式关系与 Beall 统计
     色散谱 ``S(k, f)``。
   - :doc:`K03_mle_k2d </rst_files/K_Diagnostics/K03_mle_k2d>`：多构型联合似然的二维波矢反演。

   ``K_Diagnostics`` 的单元只是子程序、不做任何文件读写和计算调度，计算全部发生在这个案例里。

   .. rubric:: 信号模型

   信号模型取自 ``simulation/simulation_beall/02宽频``：氙、``T_e = 20 eV``、``c_s = 3825 m/s``、
   无离子漂移，色散支为 ``ω = k·c_s``；104 kHz–2 MHz 频带内**每个频点一个模态**（共 238 个，
   ``df = 8 kHz``），幅度律 ``A ∝ 1/f``，随机相位只抽一次由全部分段共用，时域逐模态叠加后
   每路探针加独立白高斯噪声，宽带信噪比为 10。

   反演阵列是 35 个构型（3.0–5.0 mm × 0–90°）。Beall 另用一对**故意选粗的 20 mm 探针**：
   可见折叠条数为 ``f_max/f_alias``、``f_alias = c_s/(2d)``，所以加粗间距与加宽频带等效，
   而前者不会推高反演网格的成本。

   .. rubric:: 程序结构

   - ``source_py/config.py`` 集中存放全部生成常量；信号由它每次重建，仓库中不存放任何信号文件。
   - ``source_py/generate.py`` 按上述模型合成 36 个构型的探针记录，写入 ``build/``。
   - ``source_py/analyze.py`` 把记录送过 K01/K02/K03，写出 ``output/summary.json`` 和四张图。
   - ``make.sh`` 不编译，只负责生成合成记录；``run.sh`` 负责归约。

   .. rubric:: 运行方式

   .. code-block:: bash

      cd tests/010_diagnostics/case_broadband_dispersion
      bash clean.sh && bash make.sh && bash run.sh

   ``make.sh`` 把记录写进 ``build/``，``run.sh`` 把结果写进 ``output/summary.json`` 和
   ``output/figures/`` 下的四张图。三项检验全部通过时退出码为 0。整次运行约数秒，
   ``build/`` 约 11 MB，由 ``clean.sh`` 删除。

   .. rubric:: 判据

   .. list-table::
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
        - 104 kHz 对 104 kHz；816 kHz 对预言的 733 kHz
      * - K01
        - 生成频带以外的相干度应落在 ``1/n_segments`` 底线上
        - 带外 0.038、带内 0.932，底线 0.0625
      * - K02
        - 每个模态是否被归到正确的折叠阶
        - 238 个模态全部混叠，10 个折叠阶；最大圆周残差为折叠周期的 11%
      * - K03
        - 把 ``f`` 对 ``|k̂|`` 拟合成过原点的直线，斜率还原离子声速
        - 3829.6 对 3824.6 m/s，相对误差 1.3e-3
      * - K03
        - 波数模长与方向的逐模态误差
        - ``|k|`` 相对误差中位数 0.28%、p95 0.83%；方向误差中位数 0.26°、p95 0.62°

   每条判据形式相同：把生成信号时用到的某个量从测量里测回来再对比，而不是取一个能让测试通过的容差。

   .. rubric:: 参考图

   .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/raw_waveform.png
      :align: center
      :width: 92%

      原始波形。左图为 1 号探针加噪前后的对比，宽带信噪比为 10；右图为 3.0 mm、0° 构型下
      两路探针的无噪波形，可直接看出一对探针之间的时移，即互相位的来源。

   .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/power_spectrum.png
      :align: center
      :width: 92%

      功率谱。两路探针的谱在生成频带内与 ``∝ f⁻²`` 的生成器律重合，拟合斜率 −2.01；
      下带边落在 104 kHz，谱在 816 kHz 附近沉入噪声底，与 ``1/f²`` 律的预言 733 kHz 同量级。

   .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/beall_skf.png
      :align: center
      :width: 92%

      Beall 统计色散谱 ``S(k, f)``，取 20 mm 粗间距探针对、512 个分段。一条直的色散支被
      混叠切成锯齿状的多条折叠支；青线为混叠理论，白圈为 K02 闭式预言，两者与谱的亮脊逐条重合。
      ``k_Nyq = 157 rad/m``，全带共 21 条折叠。

   .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/mle_dispersion.png
      :align: center
      :width: 92%

      K03 的二维 MLE 反演结果，35 个构型联合。上一张图里被折叠成锯齿的色散支在这里被展直，
      橙点为反演所得，蓝线为理论支 ``f = c_s|k|/2π``。拟合斜率还原出的离子声速与生成值相差
      1.3e-3，这是全案例最核心的一条判据。

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This page documents the reference test under
   ``tests/010_diagnostics/case_broadband_dispersion``. One synthetic broadband dataset drives
   all three units of :doc:`K_Diagnostics </rst_files/K_Diagnostics>`, and each output is checked
   against the parameters that produced it:

   - :doc:`K01_signal_spectra </rst_files/K_Diagnostics/K01_signal_spectra>`: segment spectra,
     power spectra, coherence, and cross phase with its mode-referenced mean and variance.
   - :doc:`K02_beall </rst_files/K_Diagnostics/K02_beall>`: the closed-form aliasing geometry and
     the Beall statistical dispersion spectrum ``S(k, f)``.
   - :doc:`K03_mle_k2d </rst_files/K_Diagnostics/K03_mle_k2d>`: two-dimensional wavevector
     inversion from the joint likelihood of many configurations.

   The ``K_Diagnostics`` units are subroutines that perform no file I/O and schedule no
   computation of their own; all of it happens in this case.

   .. rubric:: Signal Model

   The signal model is taken from ``simulation/simulation_beall/02宽频``: xenon at
   ``T_e = 20 eV`` giving ``c_s = 3825 m/s`` with no ion drift, on the branch ``omega = k c_s``;
   **one mode per frequency bin** across 104 kHz to 2 MHz (238 modes, ``df = 8 kHz``), an
   amplitude law ``A ~ 1/f``, random phases drawn once and shared by every segment, superposed
   mode by mode in the time domain, with independent white Gaussian noise on each probe at a
   broadband ratio of 10.

   The inversion array is 35 configurations (3.0–5.0 mm at 0–90 deg). The Beall map uses a
   separate, **deliberately coarse 20 mm pair**: the number of visible folds is
   ``f_max / f_alias`` with ``f_alias = c_s / (2 d)``, so coarsening the separation and widening
   the band are equivalent and only the former leaves the inversion grid untouched.

   .. rubric:: Program Structure

   - ``source_py/config.py`` holds every generator constant; the signals are rebuilt from it on
     each run and no signal file is stored in the repository.
   - ``source_py/generate.py`` synthesises probe records for 36 configurations into ``build/``.
   - ``source_py/analyze.py`` reduces them through K01/K02/K03 and writes ``output/summary.json``
     together with the four figures.
   - ``make.sh`` compiles nothing and only generates the records; ``run.sh`` reduces them.

   .. rubric:: Run Command

   .. code-block:: bash

      cd tests/010_diagnostics/case_broadband_dispersion
      bash clean.sh && bash make.sh && bash run.sh

   ``make.sh`` writes the records into ``build/`` and ``run.sh`` writes ``output/summary.json``
   together with four figures under ``output/figures/``. The exit code is 0 when all three
   checks pass. A full run takes a few seconds and leaves about 11 MB in ``build/``, removed by
   ``clean.sh``.

   .. rubric:: Criteria

   .. list-table::
      :header-rows: 1
      :widths: 12 52 36

      * - Unit
        - Criterion
        - Measured
      * - K01
        - The generator's spectral exponent is fitted back out of the measured spectrum
        - −2.015 against −2
      * - K01
        - The lower band edge, and the frequency at which the spectrum meets the noise floor as
          the ``1/f^2`` law predicts
        - 104 kHz against 104 kHz; 816 kHz against 733 kHz predicted
      * - K01
        - Coherence outside the generated band must sit at the ``1/n_segments`` floor
        - 0.038 out of band against 0.932 in band, floor 0.0625
      * - K02
        - Every mode is assigned to the correct aliasing fold
        - All 238 modes aliased across 10 fold orders; largest circular residual 11 % of one
          fold period
      * - K03
        - Fitting ``f`` against ``|k_hat|`` through the origin returns the ion sound speed
        - 3829.6 against 3824.6 m/s, relative error 1.3e-3
      * - K03
        - Per-mode error in wavenumber magnitude and direction
        - ``|k|`` relative error median 0.28 %, p95 0.83 %; angle error median 0.26 deg, p95
          0.62 deg

   Every criterion has the same shape: a quantity the generator was built from is recovered from
   the measurement and compared back, rather than a tolerance chosen to make the test pass.

   .. rubric:: Reference Figures

   .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/raw_waveform.png
      :align: center
      :width: 92%

      Raw waveforms. Left: probe 1 before and after noise is added, at a broadband ratio of 10.
      Right: the noiseless pair for the 3.0 mm, 0 deg configuration, where the time shift
      between the two probes — the origin of the cross phase — is directly visible.

   .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/power_spectrum.png
      :align: center
      :width: 92%

      Power spectra. Both probes follow the generator's ``~ f^-2`` law across the generated
      band, with a fitted slope of −2.01. The lower band edge sits at 104 kHz and the spectrum
      sinks into the noise floor near 816 kHz, the same order as the 733 kHz predicted by the
      ``1/f^2`` law.

   .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/beall_skf.png
      :align: center
      :width: 92%

      The Beall statistical dispersion spectrum ``S(k, f)`` for the coarse 20 mm pair over 512
      segments. A single straight dispersion branch is cut by aliasing into a sawtooth of folded
      branches; the cyan lines are the aliasing theory and the white circles are K02's
      closed-form prediction, both tracking the bright ridges branch by branch.
      ``k_Nyq = 157 rad/m``, with 21 folds across the band.

   .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/mle_dispersion.png
      :align: center
      :width: 92%

      K03's two-dimensional MLE inversion from the 35 configurations jointly. The branch that
      the previous figure shows folded into a sawtooth is recovered straight: orange points are
      the inversion, the blue line is the theoretical branch ``f = c_s |k| / 2 pi``. The ion
      sound speed recovered from the fitted slope differs from the generated value by 1.3e-3,
      the central criterion of the whole case.
