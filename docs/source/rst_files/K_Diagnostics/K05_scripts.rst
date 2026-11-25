.. K05 contribution history (Git author dates; edit times include timezone).
   2026-11-17 13:54 +08:00 | Yinjian Zhao | git 9085032adbf6
   2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

09 · Scripts and reproduction guide
====================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-scripts-en:

   .. rubric:: From an explanation to the script that produces its figure

   Pages 01–05 explain the equations; pages 06–08 apply them to measurements.
   This page connects those steps to ``K_Diagnostics/K05_bispectral_transfer``.
   The Python programs are **reproducible analysis examples for four synchronous
   C1/C3 captures**, with reusable numerical functions. They are not an installed
   package or an automatic adapter for arbitrary instruments. Keep the module
   folder intact: individual downloads below are for inspecting the source.

   .. list-table:: Choose the calculation you need
      :header-rows: 1
      :class: k05-reading-table
      :widths: 30 36 34

      * - Script
        - Input → result
        - Explanation and figures
      * - :download:`analyze_spectral_walkthrough.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_spectral_walkthrough.py>`
        - Raw captures → Fourier coefficients, power, cross statistics and complex bispectra; eight figure pairs.
        - :ref:`06: measured statistics <k05-experiment-en>`; implements the conventions of :ref:`03 <k05-probe-signals-en>` and :ref:`04 <k05-statistics-en>`.
      * - :download:`validate_experiment.py <../../../../K_Diagnostics/K05_bispectral_transfer/validate_experiment.py>` and :download:`analyze_transfer_budget.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_transfer_budget.py>`
        - Raw captures → whole-capture validation, linear/quadratic fits, Kim estimates and complete power budgets. These are parent results for the next script.
        - :ref:`05: coefficient inference <k05-inference-en>` and :ref:`07: measured fits <k05-experiment-coefficients-en>`.
      * - :download:`analyze_coefficient_walkthrough.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_coefficient_walkthrough.py>`
        - Raw captures + both parent result folders → worked matrices, L/Q, Kim checks and held-out predictions; seven figure pairs.
        - :ref:`07: follow one measured calculation <k05-experiment-coefficients-en>`.
      * - :download:`analyze_extended_comparison.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_extended_comparison.py>`
        - Raw captures → four held-out fits with a common 20 MHz input basis, complex moments and errors.
        - :ref:`08: extend the fitted frequency band <k05-rates-en>`.
      * - :download:`analyze_physical_scenario.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_physical_scenario.py>`
        - Extended fits + physical configuration → dispersion roots, group velocity and conditional growth/transfer rates.
        - :ref:`02: response and growth <k05-coefficients-en>`; :ref:`08: the selected kinetic scenario <k05-source-7-en>`.
      * - :download:`plot_physical_comparison.py <../../../../K_Diagnostics/K05_bispectral_transfer/plot_physical_comparison.py>`
        - Saved extended/physical results + spectrum parent + reference digitization → the paired comparisons and detail views.
        - :ref:`08: reference Figures 2 and 3, panel by panel <k05-rates-en>`.

   **Changing only a plot style** requires the last plotter and its saved inputs;
   **changing the predictor frequency band** requires new fits first. The 5 MHz
   basis used on page 07 and the 20 MHz basis on page 08 are different models.
   Opening an HTML page does not run either calculation.

   .. rubric:: Start with page 06

   Use a Python environment with NumPy, SciPy and Matplotlib. From the repository
   root, install :download:`requirements.txt <../../../../K_Diagnostics/K05_bispectral_transfer/requirements.txt>` and run:

   .. code-block:: bash

      python -m pip install -r K_Diagnostics/K05_bispectral_transfer/requirements.txt
      python K_Diagnostics/K05_bispectral_transfer/analyze_spectral_walkthrough.py \
        --data /path/to/raw-captures --output /path/to/new-statistics

   ``--data`` is the directory containing the eight original files named
   ``SDS814X_HD_Binary_C1_2.bin`` through ``C1_5.bin`` and their ``C3`` partners.
   Subdirectories are searched; each channel/capture name must occur exactly once.
   The supported reader expects single-channel SIGLENT V4 records, probe factor 1,
   with matching timing within each pair. The example uses 100 MS/s records with
   10,000,000 samples. Raw files are external inputs, not bundled with the code.

   ``--output`` is a new directory outside the raw-data tree. Keep its
   ``walkthrough_arrays.npz`` (numerical arrays), ``walkthrough_summary.json``
   (settings, input/source hashes and checks), and SVG/PNG figures together.
   Use ``--help`` for each executable. ``--metadata`` selects acquisition facts;
   ``--config`` on the physical script selects model assumptions. Editing metadata
   alone does not change fixed capture IDs, segment lengths or frequency limits.

   For pages 07–08, follow the complete command sequence in :download:`EXPERIMENT.md <../../../../K_Diagnostics/K05_bispectral_transfer/EXPERIMENT.md>`.
   In particular, ``analyze_experiment.py`` produces the 16384-point spectra and
   ``analyze_paper_comparison.py`` packages the spectrum parent read by the final
   plotter. Its older kinetic roots do not replace the selected physical scenario.
   Plotters can replace figures in their output folder; use a separate folder to
   keep a previous rendering. Sphinx and Doxygen are needed only to rebuild the
   website, not to run these analyses.

   .. raw:: html

      <details class="k05-note"><summary>Match numerical functions to the mathematical quantities</summary>

   Here ``M`` is the number of segments, ``N`` samples per segment, ``F`` retained
   nonnegative Fourier bins, and ``J`` unique signed input pairs. Arrays are
   NumPy arrays; sample arrays are real and coefficient/design arrays are complex.

   .. list-table:: Calling conventions used by the examples
      :header-rows: 1
      :class: k05-reading-table
      :widths: 35 65

      * - Function / source
        - Input, output and convention
      * - ``read_capture(path)`` in :download:`siglent_v4.py <../../../../K_Diagnostics/K05_bispectral_transfer/siglent_v4.py>`
        - Returns metadata and a one-dimensional voltage array in V. Default: remove the record mean; do not infer the DC level.
      * - ``coefficients(x, N)`` in :download:`analyze_experiment.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py>`
        - Real voltage samples → ``c[M, N//2+1]`` and window ``w[N]``. Segment demeaning, periodic Hann, positive exponent divided by N. Incomplete trailing samples are discarded; c remains in V.
      * - ``psd_from_coefficients(c, w, fs)`` and ``bicoherence(c, fs, N)`` in the same file
        - PSD is per segment, in V²/Hz; average its segment axis. Bispectrum B is in V³; squared bicoherence is dimensionless. Their matrix axes are the two input frequency bins; only the stated sum-frequency triangle is evaluated.
      * - ``signed_pairs`` / ``design_matrix`` / ``fit_scaled`` in :download:`validate_experiment.py <../../../../K_Diagnostics/K05_bispectral_transfer/validate_experiment.py>`
        - ``c[M,F]`` → ``D[M,J+1] = [X, Z1, …]``; target ``y[M]`` → coefficients ``[L,Q1,…]`` and rank/conditioning diagnostics. L is dimensionless, Q has units V⁻¹. Negative bins are conjugates; pair order is not counted twice. Supply training rows only.
      * - ``fit_kim(D, y)`` / ``power_budget(D, y, coef, phase)`` in :download:`analyze_transfer_budget.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_transfer_budget.py>`
        - Kim returns coefficients, common power and separate identification/admissibility flags. The budget retains quadratic squares and residual cross terms; its arrays are normalized power contributions. Use radians for phase and held-out rows to evaluate predictions.

   The sign convention, conjugation and normalization are explained on
   :ref:`03 <k05-probe-signals-en>`, :ref:`04 <k05-statistics-en>` and
   :ref:`05 <k05-inference-en>`. Saved array keys and axes are listed in
   :download:`EXPERIMENT.md <../../../../K_Diagnostics/K05_bispectral_transfer/EXPERIMENT.md>`. These contracts describe the example inputs; adapting a new
   instrument or acquisition requires checking the reader and fixed analysis settings.

   .. raw:: html

      </details>

   .. rubric:: Check the calculation before interpreting it

   The ``test_*.py`` files are small, deterministic numerical checks, independent
   of the private recordings. Run all eight test files from the repository root:

   .. code-block:: bash

      python -m unittest discover -s K_Diagnostics/K05_bispectral_transfer -p 'test_*.py' -v

   :download:`test_experiment.py <../../../../K_Diagnostics/K05_bispectral_transfer/test_experiment.py>` checks binary scaling and spectral normalization;
   :download:`test_validation.py <../../../../K_Diagnostics/K05_bispectral_transfer/test_validation.py>` checks coefficient recovery, units and holdout isolation;
   :download:`test_transfer_budget.py <../../../../K_Diagnostics/K05_bispectral_transfer/test_transfer_budget.py>` checks Kim moments and exact power balances.
   :download:`test_extended_comparison.py <../../../../K_Diagnostics/K05_bispectral_transfer/test_extended_comparison.py>` checks the compressed solve against the full
   matrix, and :download:`test_physical_scenario.py <../../../../K_Diagnostics/K05_bispectral_transfer/test_physical_scenario.py>` checks geometry, group velocity and
   unit conversion. The remaining tests cover the earlier kinetic model and
   optional swept-probe tools. Passing these checks establishes the tested
   numerical properties, not a physical identification of EDI or an inverse cascade.
   Those conditions remain in :ref:`08 <k05-rates-en>`.

   .. raw:: html

      <details class="k05-note"><summary>Other files: illustrations, optional analyses and maintenance</summary>

   - :download:`draw_probe_schematics.py <../../../../K_Diagnostics/K05_bispectral_transfer/draw_probe_schematics.py>`: geometry and circuit drawings; the geometry is used on :ref:`06 <k05-experiment-geometry-en>`.
   - :download:`analyze_experiment.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py>` / :download:`analyze_paper_comparison.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_paper_comparison.py>`: spectrum/parent-result producers described above. :download:`plot_paper_comparison.py <../../../../K_Diagnostics/K05_bispectral_transfer/plot_paper_comparison.py>` and :download:`plot_extended_comparison.py <../../../../K_Diagnostics/K05_bispectral_transfer/plot_extended_comparison.py>` retain earlier comparison renderings; the current 08 uses ``plot_physical_comparison.py``.
   - :download:`validate_high_frequency.py <../../../../K_Diagnostics/K05_bispectral_transfer/validate_high_frequency.py>`, :download:`analyze_rate_walkthrough.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_rate_walkthrough.py>` and :download:`plot_transfer_budget.py <../../../../K_Diagnostics/K05_bispectral_transfer/plot_transfer_budget.py>`: earlier single-holdout or narrower-band checks. They do not replace the current four-holdout page-08 calculation.
   - :download:`analyze_probe_sweep.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_probe_sweep.py>`, :download:`analyze_probe_response.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_probe_response.py>` and :download:`yokogawa_wdf.py <../../../../K_Diagnostics/K05_bispectral_transfer/yokogawa_wdf.py>`: optional slow-sweep I–V and response analyses, separate from the fast two-probe pipeline. :download:`plot_probe_sweep.py <../../../../K_Diagnostics/K05_bispectral_transfer/plot_probe_sweep.py>` is a helper imported by the sweep analysis, not a standalone CLI.
   - :download:`plot_reading_schematics.py <../../../../K_Diagnostics/K05_bispectral_transfer/plot_reading_schematics.py>`: earlier analytical illustrations, not measured data. The interactive wave diagrams on :ref:`01 <k05-wave-overview-en>` and :ref:`02 <k05-coefficients-en>` instead run JavaScript under ``docs/source/_static/K_Diagnostics``.
   - :download:`experiment_z5p5_a3p7.json <../../../../K_Diagnostics/K05_bispectral_transfer/experiment_z5p5_a3p7.json>` stores acquisition facts; :download:`physical_scenario_config.json <../../../../K_Diagnostics/K05_bispectral_transfer/physical_scenario_config.json>` stores the selected physical assumptions. The latter is not a calibration file.
   - :download:`Tracked JSON files / data provenance <../../../../K_Diagnostics/K05_bispectral_transfer/DATA_FILES.md>`; :download:`extended-fit summary <../../_data/k05_extended_comparison_summary.json>` and :download:`physical-scenario summary <../../_data/k05_physical_scenario_summary.json>`.
   - :download:`reference_digitization/README.md <../../../../K_Diagnostics/K05_bispectral_transfer/reference_digitization/README.md>`: provenance of the approximate reference redraws; they are not author-supplied data.
   - :download:`renumber_equations.py <../../../../K_Diagnostics/K05_bispectral_transfer/renumber_equations.py>` and :download:`EQUATIONS.md <../../../../K_Diagnostics/K05_bispectral_transfer/EQUATIONS.md>`: maintain equation numbering and semantic links; they do not process probe measurements.

   .. raw:: html

      </details>

.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-scripts-zh:

   .. rubric:: 从一段讲解，找到生成对应图的脚本

   01–05页解释公式，06–08页把公式用于实测记录。本页把这些步骤与
   ``K_Diagnostics/K05_bispectral_transfer`` 中的程序对应起来。
   这些Python程序是 **四组同步C1/C3记录的可复现分析示例**，其中包含可复用的数值函数；
   目前通过命令行运行，并非已经安装的Python包，也不会自动适配任意仪器。
   请保留整个模块目录：下面的单文件下载链接方便查看源码，运行时仍需要其依赖文件。

   .. list-table:: 按要完成的计算选择脚本
      :header-rows: 1
      :class: k05-reading-table
      :widths: 30 36 34

      * - 脚本
        - 输入→结果
        - 对应讲解与图形
      * - :download:`analyze_spectral_walkthrough.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_spectral_walkthrough.py>`
        - 原始记录→Fourier系数、功率、互谱统计与复双谱；生成八组SVG/PNG图。
        - :ref:`06：实测统计量 <k05-experiment-zh>`，使用 :ref:`03 <k05-probe-signals-zh>` 和 :ref:`04 <k05-statistics-zh>` 的约定。
      * - :download:`validate_experiment.py <../../../../K_Diagnostics/K05_bispectral_transfer/validate_experiment.py>` 与 :download:`analyze_transfer_budget.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_transfer_budget.py>`
        - 原始记录→整组留出验证、线性／二次拟合、Kim估计和完整功率收支；为下一脚本提供父结果。
        - :ref:`05：系数反演 <k05-inference-zh>` 与 :ref:`07：实测拟合 <k05-experiment-coefficients-zh>`。
      * - :download:`analyze_coefficient_walkthrough.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_coefficient_walkthrough.py>`
        - 原始记录＋上述两份结果目录→展开矩阵、L/Q、Kim检查和留出预测；生成七组SVG/PNG图。
        - :ref:`07：跟随一组实测计算 <k05-experiment-coefficients-zh>`。
      * - :download:`analyze_extended_comparison.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_extended_comparison.py>`
        - 原始记录→统一20 MHz输入基底下的四轮整组留出拟合、复统计矩与误差。
        - :ref:`08：扩展拟合频带 <k05-rates-zh>`。
      * - :download:`analyze_physical_scenario.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_physical_scenario.py>`
        - 扩展拟合＋物理配置→色散根、群速度、条件性的增长率和转移率。
        - :ref:`02：响应与增长 <k05-coefficients-zh>`；:ref:`08：所选动理学情景 <k05-source-7-zh>`。
      * - :download:`plot_physical_comparison.py <../../../../K_Diagnostics/K05_bispectral_transfer/plot_physical_comparison.py>`
        - 保存的扩展／物理结果＋谱的父结果＋文献描点→逐项对照图及局部量程图。
        - :ref:`08：逐项对照文献图2、图3 <k05-rates-zh>`。

   **只改图形样式**，可以用最后一个绘图脚本读取已有结果；
   **改变二次输入频带**，则需要先重新拟合。第07页的5 MHz基底和第08页的20 MHz基底是不同模型。
   打开HTML不会自动运行这些计算。

   .. rubric:: 先复现第06页

   准备含NumPy、SciPy、Matplotlib的Python环境。在仓库根目录安装 :download:`requirements.txt <../../../../K_Diagnostics/K05_bispectral_transfer/requirements.txt>` 并运行：

   .. code-block:: bash

      python -m pip install -r K_Diagnostics/K05_bispectral_transfer/requirements.txt
      python K_Diagnostics/K05_bispectral_transfer/analyze_spectral_walkthrough.py \
        --data /path/to/raw-captures --output /path/to/new-statistics

   ``--data`` 指向八份原始文件所在目录，文件名为 ``SDS814X_HD_Binary_C1_2.bin`` 至
   ``C1_5.bin``，以及对应的四份 ``C3`` 文件。程序会搜索子目录，每个通道／组号只能找到一份。
   当前读取器支持单通道SIGLENT V4记录、探头倍率1，并检查每对记录的时间信息一致。
   本例记录为100 MS/s、每路10,000,000点。原始数据由使用者提供，不随代码打包。

   ``--output`` 指向原始数据目录之外的新目录。请一起保存
   ``walkthrough_arrays.npz`` （数值数组）、``walkthrough_summary.json``
   （设置、输入／源码哈希及检查结果）和SVG/PNG图。可执行脚本的参数可用 ``--help`` 查看。
   ``--metadata`` 选择采集事实，物理计算脚本的 ``--config`` 选择模型假设。
   仅修改元数据不会改变程序中固定的组号、分段长度或频带限制。

   第07、08页需要按 :download:`EXPERIMENT.md <../../../../K_Diagnostics/K05_bispectral_transfer/EXPERIMENT.md>` 中的完整命令顺序生成父结果。
   其中 ``analyze_experiment.py`` 生成16384点分段的谱，``analyze_paper_comparison.py``
   把它整理为最后绘图脚本读取的谱父结果；其中的旧色散根不会替代当前所选物理情景。
   绘图程序可能替换输出目录中的同名图，保留旧版本时另选目录。
   只有重建网站才需要Sphinx和Doxygen，运行这些数值分析不需要它们。

   .. raw:: html

      <details class="k05-note"><summary>把数值函数与公式中的量对应起来</summary>

   下面 ``M`` 是短段数，``N`` 是每段样本数，``F`` 是保留的非负频点数，
   ``J`` 是唯一有符号波对数。数组均为NumPy数组；时域样本是实数，Fourier系数和设计矩阵是复数。

   .. list-table:: 示例使用的函数接口
      :header-rows: 1
      :class: k05-reading-table
      :widths: 35 65

      * - 函数／源码
        - 输入、输出与约定
      * - :download:`siglent_v4.py <../../../../K_Diagnostics/K05_bispectral_transfer/siglent_v4.py>` 中的 ``read_capture(path)``
        - 返回元数据与一维电压数组，单位V。默认去整段均值，不据此确定直流电平。
      * - :download:`analyze_experiment.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py>` 中的 ``coefficients(x, N)``
        - 实电压样本 → ``c[M, N//2+1]`` 与窗 ``w[N]``。去段均值、周期Hann窗、正指数除以N；舍弃末尾不足一段的样本，c的单位仍为V。
      * - 同文件中的 ``psd_from_coefficients(c, w, fs)`` 与 ``bicoherence(c, fs, N)``
        - 前者给出逐段PSD，单位V²/Hz，再沿段轴平均。后者给出V³单位的复双谱B和无量纲平方双相干；矩阵两轴是输入频率下标，只计算约定的和频三角区域。
      * - :download:`validate_experiment.py <../../../../K_Diagnostics/K05_bispectral_transfer/validate_experiment.py>` 中的 ``signed_pairs``、``design_matrix``、``fit_scaled``
        - ``c[M,F]`` → ``D[M,J+1] = [X, Z1, …]``；目标 ``y[M]`` → ``[L,Q1,…]`` 及秩／条件数诊断。L无量纲，Q单位V⁻¹；负频点取共轭，交换波对不重复计数。拟合只传入训练行。
      * - :download:`analyze_transfer_budget.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_transfer_budget.py>` 中的 ``fit_kim(D, y)`` 与 ``power_budget(D, y, coef, phase)``
        - Kim返回系数、共同功率以及可辨识／满足必要界限的标志。收支保留二次部分平方和残差交叉项，输出是归一化功率贡献。相位用弧度，评价预测时使用留出记录的行。

   符号正负、共轭与归一化见 :ref:`03 <k05-probe-signals-zh>`、
   :ref:`04 <k05-statistics-zh>`、:ref:`05 <k05-inference-zh>`；保存的数组字段及轴顺序见
   :download:`EXPERIMENT.md <../../../../K_Diagnostics/K05_bispectral_transfer/EXPERIMENT.md>`。这些接口说明对应本例输入；换用仪器或采集方式时，还需检查读取器和固定分析设置。

   .. raw:: html

      </details>

   .. rubric:: 先检查计算，再解释结果

   ``test_*.py`` 是维护者使用的小型确定性数值测试，不依赖未公开的实验记录。
   在仓库根目录运行全部八份测试文件：

   .. code-block:: bash

      python -m unittest discover -s K_Diagnostics/K05_bispectral_transfer -p 'test_*.py' -v

   :download:`test_experiment.py <../../../../K_Diagnostics/K05_bispectral_transfer/test_experiment.py>` 检查二进制换算与谱归一化；
   :download:`test_validation.py <../../../../K_Diagnostics/K05_bispectral_transfer/test_validation.py>` 检查系数恢复、单位和训练／测试隔离；
   :download:`test_transfer_budget.py <../../../../K_Diagnostics/K05_bispectral_transfer/test_transfer_budget.py>` 检查Kim统计矩和精确功率收支；
   :download:`test_extended_comparison.py <../../../../K_Diagnostics/K05_bispectral_transfer/test_extended_comparison.py>` 对照压缩求解与完整矩阵；
   :download:`test_physical_scenario.py <../../../../K_Diagnostics/K05_bispectral_transfer/test_physical_scenario.py>` 检查几何、群速度和单位换算。
   其余测试覆盖较早的动理学模型及可选慢扫描工具。
   通过测试说明所检验的数值性质正确，不等于已经识别EDI或逆级联；物理解释条件仍见
   :ref:`08 <k05-rates-zh>`。

   .. raw:: html

      <details class="k05-note"><summary>其他文件：示意图、可选分析与维护工具</summary>

   - :download:`draw_probe_schematics.py <../../../../K_Diagnostics/K05_bispectral_transfer/draw_probe_schematics.py>`：绘制几何和电路示意，其中几何图用于 :ref:`06 <k05-experiment-geometry-zh>`。
   - :download:`analyze_experiment.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py>`、:download:`analyze_paper_comparison.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_paper_comparison.py>`：生成前述谱与父结果；:download:`plot_paper_comparison.py <../../../../K_Diagnostics/K05_bispectral_transfer/plot_paper_comparison.py>`、:download:`plot_extended_comparison.py <../../../../K_Diagnostics/K05_bispectral_transfer/plot_extended_comparison.py>` 保留较早的对照绘图。当前08使用 ``plot_physical_comparison.py``。
   - :download:`validate_high_frequency.py <../../../../K_Diagnostics/K05_bispectral_transfer/validate_high_frequency.py>`、:download:`analyze_rate_walkthrough.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_rate_walkthrough.py>`、:download:`plot_transfer_budget.py <../../../../K_Diagnostics/K05_bispectral_transfer/plot_transfer_budget.py>`：较早的单次留出或较窄频带检查，不替代当前08的四轮分析。
   - :download:`analyze_probe_sweep.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_probe_sweep.py>`、:download:`analyze_probe_response.py <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_probe_response.py>`、:download:`yokogawa_wdf.py <../../../../K_Diagnostics/K05_bispectral_transfer/yokogawa_wdf.py>`：可选的慢扫描I–V及响应分析，与高频双探针流程分开；:download:`plot_probe_sweep.py <../../../../K_Diagnostics/K05_bispectral_transfer/plot_probe_sweep.py>` 是扫描分析导入的绘图函数文件，没有独立命令行入口。
   - :download:`plot_reading_schematics.py <../../../../K_Diagnostics/K05_bispectral_transfer/plot_reading_schematics.py>`：较早的解析示意图，不是实验数据。:ref:`01 <k05-wave-overview-zh>` 与 :ref:`02 <k05-coefficients-zh>` 的互动波形则使用 ``docs/source/_static/K_Diagnostics`` 中的JavaScript。
   - :download:`experiment_z5p5_a3p7.json <../../../../K_Diagnostics/K05_bispectral_transfer/experiment_z5p5_a3p7.json>` 保存采集事实；:download:`physical_scenario_config.json <../../../../K_Diagnostics/K05_bispectral_transfer/physical_scenario_config.json>` 保存所选物理假设，后者不是标定文件。
   - :download:`保留JSON与用途 <../../../../K_Diagnostics/K05_bispectral_transfer/DATA_FILES.md>`；:download:`扩展拟合来源 <../../_data/k05_extended_comparison_summary.json>` 与 :download:`物理情景来源 <../../_data/k05_physical_scenario_summary.json>`。
   - :download:`reference_digitization/README.md <../../../../K_Diagnostics/K05_bispectral_transfer/reference_digitization/README.md>`：文献近似重绘的来源说明，重绘结果不是作者提供的原始数据。
   - :download:`renumber_equations.py <../../../../K_Diagnostics/K05_bispectral_transfer/renumber_equations.py>` 与 :download:`EQUATIONS.md <../../../../K_Diagnostics/K05_bispectral_transfer/EQUATIONS.md>`：维护公式编号和语义链接，不处理探针记录。

   .. raw:: html

      </details>

