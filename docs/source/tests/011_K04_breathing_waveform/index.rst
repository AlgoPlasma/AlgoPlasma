011_K04_breathing_waveform Tests
================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: K04 的代码、测试与画图

   本页说明如何运行 :doc:`K04 学习页 </rst_files/K_Diagnostics/K04_breathing_waveform>` 中的人工示例。计算函数位于 ``K_Diagnostics/K04_breathing_waveform/``，一个 ``fun_`` 文件提供一个函数，``mod_`` 只汇总导入。
   本页的人工数据、测试、画图与清理脚本均位于 ``tests/011_K04_breathing_waveform/``。

   .. rubric:: 1. 环境与最短运行步骤

   需要 Python 3.10+ 和 NumPy；画图还需要 Matplotlib。无需编译，无需显示器，也不依赖学习工作区里的文件。以下命令均从仓库根目录执行。

   .. code-block:: bash

      python -m pip install -r tests/011_K04_breathing_waveform/requirements.txt
      python -B -m unittest discover -s tests/011_K04_breathing_waveform -v
      python -B tests/011_K04_breathing_waveform/source_py/run_example.py
      python -B tests/011_K04_breathing_waveform/source_py/plot_figures.py

   也可用 ``bash tests/011_K04_breathing_waveform/run.sh`` 一次完成 17 项测试、两个示例和 14 张图；
   只跑测试用 ``bash tests/011_K04_breathing_waveform/test.sh``。脚本默认使用 ``python3``，可用 ``PYTHON=python`` 选择当前环境中的解释器。
   入口脚本关闭字节码写入，避免在算法目录生成缓存。

   .. rubric:: 2. 哪个脚本负责什么？

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - 文件
        - 用途
      * - ``run.sh`` / ``test.sh``
        - 完整复现 / 只运行本地测试
      * - ``source_py/generate.py``
        - 生成正文及省点知识点的人工数据
      * - ``source_py/run_example.py``
        - 运行正文示例，保存数组与误差指标
      * - ``source_py/plot_figures.py``
        - 读取结果，重画正文图 1–12
      * - ``source_py/run_compact_phase.py``
        - 运行附录 B 链接的省点示例
      * - ``source_py/plot_compact_phase.py``
        - 重画知识点的移频图和相位误差图
      * - ``test_K04_breathing_waveform.py``
        - 数值验证及文内代码一致性测试
      * - ``clean.sh``
        - 清理默认结果和缓存，包括 Git 忽略的文件
      * - ``test_clean.py``
        - 在临时目录验证清理范围和符号链接处理
      * - ``requirements.txt``
        - NumPy、Matplotlib 依赖
      * - ``output/``
        - 运行后生成的结果；Git 忽略

   .. rubric:: 3. 输出、误差及图号

   默认结果在 ``tests/011_K04_breathing_waveform/output/``，被 Git 忽略；重复运行覆盖同名文件。``synthetic_result.npz`` 保存数据与中间数组，``metrics.json`` 保存误差指标，``figures/`` 保存正文图 1–12。读取结果可用：

   .. code-block:: python

      import numpy as np
      with np.load("tests/011_K04_breathing_waveform/output/synthetic_result.npz", allow_pickle=False) as data:
          print(data.files)
          C, R = data["C"], data["R"]

   默认参数与正文完全相同：种子 20261004、10 条记录、8 MHz、每条 160000 点、留出第 0 条、256 箱、4096 个查表点、名义上限 3 MHz。得到主频 39750 Hz、H=75、最少训练计数 5566，C 的 RMSE 约 4.934 mV。C_known 仅为生成器答案，提取不读取它。R 是剩余电压；error 是 C−C_known。

   图文件按正文顺序为 ``r3_01_x``、``r3_02_F``、``r3_03_Fhat``、``r3_04_z``、``r3_05_phase``、``r3_06_fold``、``r3_07_mu``、``r3_08_a``、``r3_09_W``、``r3_10_replay``、``r3_11_result``、``r3_12_residual``，扩展名都是 ``.png``。

   运行脚本可用 ``--output-dir``，主例还可用 ``--seed``；画图脚本可用 ``--input`` 和 ``--output-dir``。修改输出目录后，请把画图的输入同步指向新结果。示例：

   .. code-block:: bash

      python -B tests/011_K04_breathing_waveform/source_py/run_example.py --output-dir /tmp/k04-demo
      python -B tests/011_K04_breathing_waveform/source_py/plot_figures.py --input /tmp/k04-demo/synthetic_result.npz --output-dir /tmp/k04-demo/figures

   .. rubric:: 4. 从自己的脚本调用

   .. code-block:: python

      from K_Diagnostics.K04_breathing_waveform.mod_K04_breathing_waveform import (
          fun_K04_extract_waveform,
      )
      # records: at least three 1-D voltage arrays supplied by the caller; fs in Hz.
      result = fun_K04_extract_waveform(records, fs, held_out=0)
      C, R = result["C"], result["R"]
      print(C.shape, result["H"])

   records 由调用方提供自己的电压数组。至少 3 条，采样率一致，同一空间位置与可比较工况；长度可以不同。函数无文件读写，不会修改输入。核心入口的完整签名是：

   .. code-block:: python

      fun_K04_extract_waveform(records, fs, held_out=0, bins=256, cutoff=3e6,
                               grid_size=4096, search=(35e3,45e3), band=(25e3,55e3))

   .. list-table::
      :header-rows: 1
      :widths: 22 78

      * - 参数
        - 含义与约束
      * - ``records``
        - J 条实数一维数组，各 N_j 点，单位 V；J≥3
      * - ``fs``
        - 共同采样率，Hz，有限且大于零
      * - ``held_out``
        - 从 0 开始的留出记录序号；其电压不参与共同形状训练
      * - ``bins``
        - 偶数 B≥4；所有训练相位箱必须有样本
      * - ``cutoff``
        - 名义谐波上限，Hz；0<cutoff<fs/2，H=floor(cutoff/f0)<B/2
      * - ``grid_size``
        - 查表点数 M，整数且 2H<M
      * - ``search / band``
        - 找峰/取相位的正频率范围，Hz；band 必须覆盖找到的主频

   返回字典中的 ``C``、``R`` 为 (N_r,) V，与留出记录对齐；``positions`` 是 J 条 (N_j,) rad 相位位置；``frequencies`` 为 (J,) Hz；``mu``、``K_train`` 为 (B,) V/样本数；``a`` 为 (B/2+1,) 复数 V；``gamma``、``w`` 为 (M,) rad/V。其余中间量、每个基础函数的输入输出均见源码内 docstring。可逐记录改变 held_out，得到每条记录自己的留出结果。

   .. rubric:: 5. 基础函数与源码

   - :download:`fun_K04_find_frequency.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_find_frequency.py>`：找峰及原始 FFT。
   - :download:`fun_K04_make_complex_signal.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_make_complex_signal.py>`：筛出正频率并做复数逆 FFT。
   - :download:`fun_K04_mark_position.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_mark_position.py>`：完整相位与周期内位置。
   - :download:`fun_K04_put_into_bins.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_put_into_bins.py>`：累加 S 和 K。
   - :download:`fun_K04_mean_other_records.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_mean_other_records.py>`：排除一整条记录后求 μ。
   - :download:`fun_K04_mean_to_coefficients.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_mean_to_coefficients.py>`：半箱修正后求 a_n。
   - :download:`fun_K04_coefficients_to_grid.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_coefficients_to_grid.py>`：按上限保留阶数，构造 W 网格。
   - :download:`fun_K04_grid_to_time.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_grid_to_time.py>`：周期插值回原采样点。
   - :download:`fun_K04_extract_waveform.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_extract_waveform.py>`：串起正文完整计算流程。
   - :download:`fun_K04_compact_phase.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_compact_phase.py>`：省点计算及其中间结果字典。

   测试目录说明可下载 :download:`中文 README <../../../../tests/011_K04_breathing_waveform/README.zh-CN.md>`。基础函数可从 ``mod_K04_breathing_waveform`` 统一导入。

   .. rubric:: 6. 省点知识点与文档图片重画

   对应 :doc:`窄带相位的省点计算 </knowledge/compact_phase>`，运行：

   .. code-block:: bash

      python -B tests/011_K04_breathing_waveform/source_py/run_compact_phase.py
      python -B tests/011_K04_breathing_waveform/source_py/plot_compact_phase.py

   结果保存为 ``compact_phase_result.npz``、``compact_phase_metrics.json``，两张图在 ``compact_figures/``。4096 个粗网格点对 160000 个原始点，相位 RMSE 约 6.8351e-7 rad；这个误差比较省点法与直接法。``fun_K04_compact_phase(x, fs, oversample=4, search=..., band=...)`` 返回字典，``phi_compact`` 是最终 (N,) rad 相位；``v``、``q``、``tau``、``delta_extended`` 等供核对移频与插值。

   默认只画到 output。需要更新网页里的 12+2 张静态图片时，先生成上述数值结果，再运行下面两行，覆盖对应图片后重建 Sphinx：

   .. code-block:: bash

      python -B tests/011_K04_breathing_waveform/source_py/plot_figures.py --output-dir docs/source/images/K_Diagnostics/k04
      python -B tests/011_K04_breathing_waveform/source_py/plot_compact_phase.py --output-dir docs/source/images/knowledge

   .. rubric:: 7. 自动测试检查了什么？

   测试在本地运行，共 14 项数值测试与 3 项清理测试。从仓库根目录执行：

   .. code-block:: bash

      python -B -m unittest discover -s tests/011_K04_breathing_waveform -v

   14 项数值测试检查已知相位、半振幅、原始电压分箱、按样本加权、整条记录留出、半箱相位修正、谐波选择、周期插值与输入约束；还核对完整人工例子及省点移频、幅值归一化、插值收敛和首尾整圈数。测试直接读取中英两版正文与知识点的 Python 片段并执行，检查它们与导入函数的结果相符。

   固定人工数据的回归阈值为 C 的 RMSE <10 mV、省点相位 RMSE <1e-6 rad；公式等价检查采用浮点误差量级的容差。通过显示 OK，失败返回非零退出码。这里没有声称验证了所有实验工况：仍需按实际数据选择频带、箱数和上限，检查相位是否可靠；残差的强弱仍可能依赖呼吸相位。


   .. rubric:: 8. 清理运行生成的文件

   从仓库根目录运行以下命令；需要 Bash，可用于 Linux、macOS 和 WSL：

   .. code-block:: bash

      bash tests/011_K04_breathing_waveform/clean.sh

   也可在测试目录中运行 ``bash clean.sh``，脚本根据自身位置定位。
   它删除本测试目录的整个默认 ``output/`` 及其中的数据、指标和图片，以及测试目录下的 Python ``__pycache__/``；
   **被 Git 忽略的运行产物同样会清除**。可重复运行，让默认生成文件恢复到刚克隆时不存在的状态。
   源码、README、文档中保存的图片和用户修改会保留；用 ``--output-dir`` 写到其他目录的结果需要单独清理。
   该命令不重置 Git，也不清理其他模块或整个文档构建目录。
   3 项清理测试在临时目录检查删除范围、重复运行、符号链接及脚本位置；非 POSIX/Bash 环境跳过它们，数值测试照常运行。

.. container:: ap-lang ap-lang-en

   .. rubric:: K04 code, tests, and figures

   This page explains how to run the artificial examples in the :doc:`K04 learning page </rst_files/K_Diagnostics/K04_breathing_waveform>`. Numerical routines live in ``K_Diagnostics/K04_breathing_waveform/``: one routine per ``fun_`` file, with ``mod_`` only re-exporting them.
   Artificial data, tests, plots and cleanup scripts live in ``tests/011_K04_breathing_waveform/``.

   .. rubric:: 1. Environment and minimal commands

   Use Python 3.10+ and NumPy; figures also require Matplotlib. No compilation, display, or files from a separate learning workspace are needed. Run every command below from the repository root.

   .. code-block:: bash

      python -m pip install -r tests/011_K04_breathing_waveform/requirements.txt
      python -B -m unittest discover -s tests/011_K04_breathing_waveform -v
      python -B tests/011_K04_breathing_waveform/source_py/run_example.py
      python -B tests/011_K04_breathing_waveform/source_py/plot_figures.py

   Alternatively, ``bash tests/011_K04_breathing_waveform/run.sh`` runs all 17 tests, both examples and all 14 figures.
   Use ``bash tests/011_K04_breathing_waveform/test.sh`` for tests only. Shell scripts use ``python3`` by default;
   ``PYTHON=python`` selects another interpreter from the current environment. Entry scripts disable bytecode writing to keep caches out of the algorithm directory.

   .. rubric:: 2. Which file does what?

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - File
        - Purpose
      * - ``run.sh`` / ``test.sh``
        - Full reproduction / local tests only
      * - ``source_py/generate.py``
        - Generate the main and compact-phase synthetic inputs
      * - ``source_py/run_example.py``
        - Run the main example; save arrays and error metrics
      * - ``source_py/plot_figures.py``
        - Read saved results and redraw Figures 1–12
      * - ``source_py/run_compact_phase.py``
        - Run the compact-phase example linked from Appendix B
      * - ``source_py/plot_compact_phase.py``
        - Redraw the frequency-shift and phase-error figures
      * - ``test_K04_breathing_waveform.py``
        - Numerical checks and agreement with documentation snippets
      * - ``clean.sh``
        - Remove default results and caches, including ignored files
      * - ``test_clean.py``
        - Test cleanup scope and symlinks in temporary directories
      * - ``requirements.txt``
        - NumPy and Matplotlib dependencies
      * - ``output/``
        - Generated results; ignored by Git

   .. rubric:: 3. Outputs, errors, and figure numbers

   Outputs default to the ignored ``tests/011_K04_breathing_waveform/output/`` directory. Reruns overwrite matching filenames. ``synthetic_result.npz`` contains inputs and intermediate arrays, ``metrics.json`` contains metrics, and ``figures/`` contains Figures 1–12. Read saved arrays with:

   .. code-block:: python

      import numpy as np
      with np.load("tests/011_K04_breathing_waveform/output/synthetic_result.npz", allow_pickle=False) as data:
          print(data.files)
          C, R = data["C"], data["R"]

   Defaults exactly match the learning page: seed 20261004, ten records, 8 MHz, 160000 samples per record, held-out record 0, 256 bins, 4096 lookup points, and nominal cutoff 3 MHz. The result has f0=39750 Hz, H=75, minimum training count 5566, and waveform RMSE about 4.934 mV. C_known is checking truth, unused by extraction. R is remaining voltage; error is C−C_known.

   Figure filenames follow the page order: ``r3_01_x``, ``r3_02_F``, ``r3_03_Fhat``, ``r3_04_z``, ``r3_05_phase``, ``r3_06_fold``, ``r3_07_mu``, ``r3_08_a``, ``r3_09_W``, ``r3_10_replay``, ``r3_11_result``, and ``r3_12_residual``, all with extension ``.png``.

   Run scripts accept ``--output-dir``; the main example also accepts ``--seed``. Plot scripts accept ``--input`` and ``--output-dir``. When changing output locations, point the plotter to the new result, for example:

   .. code-block:: bash

      python -B tests/011_K04_breathing_waveform/source_py/run_example.py --output-dir /tmp/k04-demo
      python -B tests/011_K04_breathing_waveform/source_py/plot_figures.py --input /tmp/k04-demo/synthetic_result.npz --output-dir /tmp/k04-demo/figures

   .. rubric:: 4. Call the routines from Python

   .. code-block:: python

      from K_Diagnostics.K04_breathing_waveform.mod_K04_breathing_waveform import (
          fun_K04_extract_waveform,
      )
      # records: at least three 1-D voltage arrays supplied by the caller; fs in Hz.
      result = fun_K04_extract_waveform(records, fs, held_out=0)
      C, R = result["C"], result["R"]
      print(C.shape, result["H"])

   Supply records as measured voltage arrays: at least three records, one sampling rate, the same spatial point and comparable conditions. Lengths may differ. The routine performs no file I/O and does not modify inputs. Its complete signature is:

   .. code-block:: python

      fun_K04_extract_waveform(records, fs, held_out=0, bins=256, cutoff=3e6,
                               grid_size=4096, search=(35e3,45e3), band=(25e3,55e3))

   .. list-table::
      :header-rows: 1
      :widths: 22 78

      * - Parameter
        - Meaning and constraints
      * - ``records``
        - J real 1-D arrays of N_j samples, V; J>=3
      * - ``fs``
        - Common sampling rate, Hz, finite and positive
      * - ``held_out``
        - Zero-based held-out index; its voltages do not train the shape
      * - ``bins``
        - Even B>=4; every training bin must contain samples
      * - ``cutoff``
        - Nominal harmonic limit, Hz; 0<cutoff<fs/2, H=floor(cutoff/f0)<B/2
      * - ``grid_size``
        - Integer lookup count M with 2H<M
      * - ``search / band``
        - Positive peak-search/phase bands, Hz; band must contain the selected peak

   Returned ``C`` and ``R`` have shape (N_r,) in V, aligned with the held-out record. ``positions`` contains J arrays (N_j,) in rad; ``frequencies`` is (J,) Hz; ``mu``/``K_train`` are (B,) V/counts; ``a`` is (B/2+1,) complex V; ``gamma``/``w`` are (M,) rad/V. Source docstrings describe all intermediate quantities and individual routine contracts. Repeat with each held_out index to obtain separate holdout results for every record.

   .. rubric:: 5. Individual routines and source

   - :download:`fun_K04_find_frequency.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_find_frequency.py>`: Peak search and full FFT.
   - :download:`fun_K04_make_complex_signal.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_make_complex_signal.py>`: Positive-band selection and complex IFFT.
   - :download:`fun_K04_mark_position.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_mark_position.py>`: Unwrapped phase and cycle position.
   - :download:`fun_K04_put_into_bins.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_put_into_bins.py>`: Accumulate S and K.
   - :download:`fun_K04_mean_other_records.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_mean_other_records.py>`: Pool mu while excluding a complete record.
   - :download:`fun_K04_mean_to_coefficients.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_mean_to_coefficients.py>`: Fourier coefficients with half-bin correction.
   - :download:`fun_K04_coefficients_to_grid.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_coefficients_to_grid.py>`: Retain harmonic orders and evaluate W.
   - :download:`fun_K04_grid_to_time.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_grid_to_time.py>`: Periodic lookup on native sample phases.
   - :download:`fun_K04_extract_waveform.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_extract_waveform.py>`: Orchestrate the main extraction.
   - :download:`fun_K04_compact_phase.py <../../../../K_Diagnostics/K04_breathing_waveform/fun_K04_compact_phase.py>`: Compact phase and its intermediate-result dictionary.

   Download the :download:`test-case README <../../../../tests/011_K04_breathing_waveform/README.en.md>`. Individual routines can all be imported from ``mod_K04_breathing_waveform``.

   .. rubric:: 6. Compact-phase example and documentation figures

   For the :doc:`compact-phase knowledge note </knowledge/compact_phase>`, run:

   .. code-block:: bash

      python -B tests/011_K04_breathing_waveform/source_py/run_compact_phase.py
      python -B tests/011_K04_breathing_waveform/source_py/plot_compact_phase.py

   Outputs are ``compact_phase_result.npz``, ``compact_phase_metrics.json``, and two PNGs under ``compact_figures/``. With 4096 coarse points versus 160000 original points, phase RMSE is about 6.8351e-7 rad, comparing the compact and direct methods. ``fun_K04_compact_phase(x, fs, oversample=4, search=..., band=...)`` returns a dictionary: ``phi_compact`` is the final (N,) phase in rad; ``v``, ``q``, ``tau``, and ``delta_extended`` expose the shifts and interpolation.

   Plots default to output. To update the 12+2 static documentation figures, generate both numerical results first, run the following commands to overwrite those assets, then rebuild Sphinx:

   .. code-block:: bash

      python -B tests/011_K04_breathing_waveform/source_py/plot_figures.py --output-dir docs/source/images/K_Diagnostics/k04
      python -B tests/011_K04_breathing_waveform/source_py/plot_compact_phase.py --output-dir docs/source/images/knowledge

   .. rubric:: 7. What do the automated tests check?

   Run the 14 numerical tests and 3 cleanup tests locally from the repository root:

   .. code-block:: bash

      python -B -m unittest discover -s tests/011_K04_breathing_waveform -v

   Fourteen numerical tests check known phase, half amplitude, original-voltage bins, sample weighting, complete-record holdout, half-bin phase correction, harmonic selection, periodic interpolation, and invalid inputs. They also check full synthetic recovery plus compact shifts, normalization, interpolation convergence, and endpoint winding. Tests execute both languages of the actual page/note snippets and compare results with the imported routines.

   Regression budgets for the fixed synthetic data are waveform RMSE <10 mV and compact phase RMSE <1e-6 rad; formula comparisons use floating-point tolerances. Success prints OK; failures exit nonzero. These checks do not validate every experimental condition: choose bands, bin count, and cutoff for the data and assess phase quality. Residual strength can still depend on breathing phase.

   .. rubric:: 8. Clean generated files

   From the repository root, run with Bash on Linux, macOS, or WSL:

   .. code-block:: bash

      bash tests/011_K04_breathing_waveform/clean.sh

   Running ``bash clean.sh`` inside the test directory also works: paths are relative to the script.
   It removes this test case's entire default ``output/`` with its data, metrics and figures, plus Python ``__pycache__/``
   directories under the test case. **Git-ignored generated files are removed too.** Repeated cleaning succeeds and restores
   the absence of default generated files expected in a fresh clone. Source, READMEs, saved documentation figures,
   and user edits remain; results written elsewhere with ``--output-dir`` require separate cleanup.
   The command does not reset Git or clean other modules or the documentation build directory.
   Three cleanup tests use temporary directories to check deletion scope, repeat runs, symlinks and script location.
   They are skipped outside POSIX/Bash environments; numerical tests still run.
