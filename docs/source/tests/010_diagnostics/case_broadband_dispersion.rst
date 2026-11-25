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
   本例探针对与传播方向平行，首次混叠边界为 ``f_alias = c_s/(2d)``，完整折叠周期为其两倍；加粗间距可增加折叠，
   而前者不会推高反演网格的成本。

   .. rubric:: 程序结构

   - ``source_py/config.py`` 集中存放全部生成常量；信号由它每次重建，仓库中不存放任何信号文件。
   - ``source_py/generate.py`` 按上述模型合成 36 个构型的探针记录，写入 ``build/``。
   - ``source_py/analyze.py`` 把记录送过 K01/K02/K03，写出 ``output/summary.json`` 和四张图。
   - ``make.sh`` 不编译，只负责生成合成记录；``run.sh`` 负责归约。

   .. rubric:: 运行与结果来源

   .. code-block:: bash

      bash tests/010_diagnostics/case_broadband_dispersion/run.sh --publish-docs

   run.sh 先执行四项小型验收反例检查，再生成记录、运行宽带计算；任一步失败均返回非零退出码。
   ``--publish-docs`` 仅在全部通过后更新下方表格和四张图。
   运行输出位于案例的 ``output/``；约 95 MB 的临时波形位于 ``build/``，可用案例的 clean.sh 清理。

   :download:`完整结果与运行来源 <_generated/case_broadband_dispersion/summary.json>` ·
   :download:`逐频点结果 CSV <_generated/case_broadband_dispersion/modes.csv>`

   .. rubric:: 验收要求及依据

   本例固定生成器、随机种子和网格。以下阈值是预先声明的工程验收要求，集中定义于
   ``source_py/config.py`` 的 ``ACCEPTANCE``，不是理论误差上限或统计置信区间。

   - **K01：** 总 PSD 高于 10 倍噪声底的频点用于强信号评价。若 PSD = 信号 + 噪声，
     阈值处信号部分为 9 倍噪声底；交点预言采用这一口径。它是评价频段的阈值，
     不是信号与噪声相等的位置。谱指数误差 0.15、交点相对误差 15% 是允许的拟合偏差；
     下带边允许两格离散误差。带内相干度中位数要求大于 0.8；
     带外使用均值与独立分段零相干条件下的 1/N 比较，允许两倍余量，不把均值当作中位数。
   - **K02：** 有效频点的圆周峰位残差 p95 小于两格。这是带噪直方图谱峰的案例要求，
     不等于无噪量化误差必然小于半格，也不声称单探针对恢复折叠阶。
   - **K03：** 声速相对误差小于 0.5%，模长误差中位数小于 5%，方向误差 p95 小于 2°。
     此外，每个选定频点都必须满足
     ``|K_est - K_true| <= 0.05*|K_true| + grid_step/sqrt(2)``。
     前一项是允许的带噪矢量误差；后一项来自方形网格最近点的最大距离，
     只用于预算网格量化影响，不保证搜索一定选择最近真值的点。允许超限频点数为零。
     本例真值位于搜索域内，因此边界峰或并列网格最大值也使本例验收失败，CSV 保留原因。
     一般实测数据中的边界峰需要核查范围，精确并列计数也不能证明连续解唯一。

   这些要求用于防止当前案例退化。若改变信噪比、构型或传播模型，需重新论证适用范围，
   不能仅为了通过而调宽阈值。当前案例只有每频点一个传播方向，未验证同频多波的可辨识性。

   .. include:: _generated/case_broadband_dispersion/results_zh.rst
      :start-after: .. snapshot-start

   .. rubric:: 同次运行的图

   .. rubric:: K01：原始波形

   .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/raw_waveform.png
      :align: center
      :width: 100%
      :figclass: ap-diagnostics-broadband-figure

   左图叠加探针 1 的含噪记录与无噪信号，右图比较两路无噪信号。
   此处展示 3.0 mm、0° 的参考探针对，生成记录的宽带信噪比为 10。
   这张图帮助辨认输入；K01 是否通过仍由上方的谱与相干度验收值决定。

   .. container:: ap-diagnostics-broadband-triptych

      .. container:: ap-diagnostics-broadband-panel

         .. rubric:: K01：功率谱

         .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/power_spectrum.png
            :align: center
            :width: 100%
            :figclass: ap-diagnostics-broadband-figure

      .. container:: ap-diagnostics-broadband-panel

         .. rubric:: K02：Beall 折叠谱

         .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/beall_skf.png
            :align: center
            :width: 100%
            :figclass: ap-diagnostics-broadband-figure

      .. container:: ap-diagnostics-broadband-panel

         .. rubric:: K03：联合反演色散关系

         .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/mle_dispersion.png
            :align: center
            :width: 100%
            :figclass: ap-diagnostics-broadband-figure

   **K01 功率谱：** 图中黑色虚线对应生成器的 :math:`P(f)\propto f^{-2}`，本次拟合斜率约为 −2.0021；
   灰色虚线是 10 倍噪声底的评价线，红色点线是噪声底。交点按灰线定义；
   谱指数、交点和相干度是否满足要求，以验收表的数值为准。

   **K02 Beall 折叠谱：** 本例使用 20 mm、30° 的探针对和 512 段样本；Nyquist 波数约为 157 rad/m，
   生成模态实际覆盖 10 个折叠阶。图中比较谱的亮脊、青色理论折叠支和绿色 K02 预测点。
   单探针对只能核对折叠后的峰位，不能恢复折叠阶；首次 Nyquist 边界也不是完整折叠周期。
   通过与否由上表的圆周峰位残差判定。

   **K03 联合反演色散关系：** 35 个构型联合反演的波数模长与理论关系 :math:`f=c_s|k|/(2\pi)` 对照，
   其中生成器声速约为 3825 m/s。直线贴合只显示总体趋势；声速误差、
   逐频点矢量误差和搜索标记仍需核对验收表与 CSV。

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
   separate, **deliberately coarse 20 mm pair**: the first alias boundary is
   ``f_alias = c_s / (2 d)`` and the fold period is twice this value for this aligned pair, so coarsening the separation and widening
   the band are equivalent and only the former leaves the inversion grid untouched.

   .. rubric:: Program Structure

   - ``source_py/config.py`` holds every generator constant; the signals are rebuilt from it on
     each run and no signal file is stored in the repository.
   - ``source_py/generate.py`` synthesises probe records for 36 configurations into ``build/``.
   - ``source_py/analyze.py`` reduces them through K01/K02/K03 and writes ``output/summary.json``
     together with the four figures.
   - ``make.sh`` compiles nothing and only generates the records; ``run.sh`` reduces them.

   .. rubric:: Running and provenance

   .. code-block:: bash

      bash tests/010_diagnostics/case_broadband_dispersion/run.sh --publish-docs

   The driver first runs four small acceptance counterexamples, then generates and analyzes the
   records. Any failure gives a nonzero exit code. With ``--publish-docs``, tables and all four
   figures are published together only after every check passes. Runtime results are in ``output/``;
   clean.sh removes these and the approximately 95 MB of temporary waveforms in ``build/``.

   :download:`Full results and provenance <_generated/case_broadband_dispersion/summary.json>` ·
   :download:`Per-mode CSV <_generated/case_broadband_dispersion/modes.csv>`

   .. rubric:: Acceptance requirements and basis

   This fixed generator, seed and grid use declared engineering requirements in
   ``source_py/config.py: ACCEPTANCE``. These are not universal error bounds or confidence intervals.

   - **K01:** Assess strong signals above ten times the noise floor in total PSD. Since total PSD
     is signal plus noise, the signal at this threshold is nine times the floor; the prediction
     uses this same definition. This is an assessment threshold, not a signal/noise equality.
     Exponent error 0.15 and crossing error 15% are allowed fit deviations; the band edge allows
     two frequency bins. In-band median coherence must exceed 0.8. Out-of-band mean coherence is
     compared with the independent-segment zero-coherence expectation 1/N, allowing a factor of two.
     That expectation is not the median.
   - **K02:** Circular peak residual p95 must be below two bins for assessed modes. This is a
     requirement for a noisy histogram, not a half-bin quantization guarantee or recovery of fold order.
   - **K03:** Speed error must be below 0.5%, median magnitude error below 5%, and direction-error
     p95 below 2 degrees. Every selected mode must also satisfy
     ``|K_est - K_true| <= 0.05*|K_true| + grid_step/sqrt(2)``.
     The first term is the allowed noisy vector error; the second is the maximum distance to the
     nearest point on a square grid, budgeting quantization without guaranteeing alias selection.
     Zero over-budget modes are allowed. Boundary or tied maxima fail this reference case, whose
     truth is inside the search domain; reasons remain in the CSV. In general data a boundary peak
     warrants a range check, and exact grid tie counts do not establish continuous uniqueness.

   Changing noise, geometry or propagation requires reconsidering the scope of these requirements,
   not widening them merely to pass. This case has one direction per frequency and does not validate
   identification of multiple waves at the same frequency.

   .. include:: _generated/case_broadband_dispersion/results_en.rst
      :start-after: .. snapshot-start

   .. rubric:: Figures from the same run

   .. rubric:: K01: Raw Waveforms

   .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/raw_waveform.png
      :align: center
      :width: 100%
      :figclass: ap-diagnostics-broadband-figure

   The left panel overlays noisy and clean probe-1 records, while the right
   panel compares the two clean probes. This is the 3.0 mm, 0° reference pair;
   the generated records have a broadband signal-to-noise ratio of 10.
   K01 acceptance comes from the spectral and coherence values in the table above.

   .. container:: ap-diagnostics-broadband-triptych

      .. container:: ap-diagnostics-broadband-panel

         .. rubric:: K01: Power Spectra

         .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/power_spectrum.png
            :align: center
            :width: 100%
            :figclass: ap-diagnostics-broadband-figure

      .. container:: ap-diagnostics-broadband-panel

         .. rubric:: K02: Beall Folded Spectrum

         .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/beall_skf.png
            :align: center
            :width: 100%
            :figclass: ap-diagnostics-broadband-figure

      .. container:: ap-diagnostics-broadband-panel

         .. rubric:: K03: Jointly Recovered Dispersion

         .. figure:: ../../images/tests/010_diagnostics/case_broadband_dispersion/mle_dispersion.png
            :align: center
            :width: 100%
            :figclass: ap-diagnostics-broadband-figure

   **K01 Power Spectra:** The black dashed line is the generator reference
   :math:`P(f)\propto f^{-2}`; the fitted slope is about −2.0021. The gray dashed
   line marks ten times the noise floor, and the red dotted line marks the floor.
   The crossing uses the gray line. Use the table values to assess the exponent,
   crossing, and coherence.

   **K02 Beall Folded Spectrum:** This 20 mm pair at 30° uses 512 segments.
   Its Nyquist wavenumber is about 157 rad/m, and the generated modes occupy
   10 fold orders. The figure compares bright spectral ridges with the cyan
   folded-theory branch and green K02 prediction markers. A single pair checks
   folded peak positions, not fold order; the first Nyquist crossing is not a
   full fold period. The circular peak residual in the table determines acceptance.

   **K03 Jointly Recovered Dispersion:** The 35 configurations jointly recover
   wavenumber magnitudes compared with :math:`f=c_s|k|/(2\pi)` for the generator
   sound speed of about 3825 m/s. Visual agreement is only an overview; the
   table and CSV assess sound-speed error, per-mode vector errors, and search flags.
