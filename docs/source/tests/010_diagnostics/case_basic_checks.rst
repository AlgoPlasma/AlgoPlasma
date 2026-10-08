basic_numerical tests
=====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-diagnostics-foundations

   这三组测试检查诊断程序在已知输入下是否按定义工作。每组给出测试目的、输入与操作、
   预期及依据，再展示本次核对和结论。读者可以先看每组的问题与通过条件，再核对数值。
   原理通过链接查看，辅助图按需展开。相位统一用度（°）、相位方差用度平方（°²）展示；
   代码与完整原始记录保留弧度，波数仍用 rad/m。

   .. include:: _generated/case_basic_checks/checks_zh.rst
      :start-after: .. checks-overview-start
      :end-before: .. checks-overview-end

   - :ref:`频谱功率与互相位 <basic-checks-zh-spectrum>`
   - :ref:`相位统计量 <basic-checks-zh-phase>`
   - :ref:`Beall 权重与谱峰 <basic-checks-zh-beall>`

   :ref:`数值容差的选择依据 <basic-checks-zh-tolerances>`

   .. _basic-checks-zh-spectrum:

   .. rubric:: 1. 频谱功率与互相位

   **测试目的：** 检查功率归一化和互相位的符号、计算是否正确，防止出现谱形看似合理、数值却算错的情况。

   **输入与操作：** 固定种子42生成四段64点记录，逐段去均值，分别应用矩形窗和 Hann 窗，
   调用分段 FFT 与功率谱函数，计算 :math:`\sum P(f)\Delta f`。采样率64 Hz，故 :math:`\Delta f=1` Hz。
   另构造两路相差约45.83662°的余弦，记录分别含2周期和1.25周期，读取最近频点的互相位。

   **预期及依据：** 每种窗口的积分功率应等于时域窗口加权平方和除以窗口平方和，再对各段取平均；
   这是离散 Parseval 关系。整周期互谱 :math:`X_1X_2^*` 的相位应约为 −45.83662°。
   两种周期记录还分别与直接求和 :math:`X_k=\sum_n(x_n-\bar{x})e^{-2\pi i kn/N}` 的参考相位比较，
   参考计算不调用被测 FFT 和互相位函数。

   **通过条件：** 两行功率和三行相位均在所列容差内符合参考。
   任一行不符即失败；泄漏偏差是否大于某个角度不作为通过条件。

   .. include:: _generated/case_basic_checks/checks_zh.rst
      :start-after: .. checks-spectrum-start
      :end-before: .. checks-spectrum-end

   两种窗口各自与对应的时域参考比较，不要求窗口之间功率相等。
   非整周期相位即使符合直接 DFT，也可能偏离输入相位差（约 −45.83662°）：前者检查计算是否正确，后者反映读数方法的局限。

   :ref:`查看六面板图：截取、重复拼接与谱泄漏 <knowledge-leakage-zh-record>` ·
   :ref:`返回频谱原理 <foundations-zh-spectrum>`

   .. _basic-checks-zh-phase:

   .. rubric:: 2. 相位统计量

   **测试目的：** 用两个独立案例检查众数格中心和样本方差。每个案例内部保持同一组输入，
   只改变统计定义或角度边界处理；案例 A 和 B 之间不作方法优劣比较。

   **案例 A：同一组样本，比较两种统计定义。** 输入约为 [0.63°, 0.69°, 0.74°, 12.61°]，
   图中两种方法都使用这四个样本的未舍入值。算术平均约为3.66693°；
   60个分箱每格宽6°，前三个样本落在 [0°, 6°)，最后一个落在 [12°, 18°)，
   所以程序应返回最高格的中心3°。3°是分箱中心，不是三个密集样本的平均值。
   本例没有指定真实相位，不能据此判断哪种估计更准确。

   **案例 B：同一组观测，只改变周期边界处理。** 输入为 [179°, −179°, 178°, 179°]。
   直接作为普通数值计算，样本方差约为31981.58333 °²；将 −179° 写成等价的181°，
   四个相位仍是原来的四次观测，方差应为 :math:`19/12` °²，约1.58333 °²。
   两种计算都用 :math:`n-1` 分母，并计入相同的正则化下限（约 :math:`3.28280635\times10^{-9}` °²）。
   程序还应返回最高格 [174°, 180°) 的中心177°。

   **预期及通过条件：** 案例 A 的中心与方差应分别为3°和约35.509022 °²；案例 B 为177°和约1.5833333 °²。
   方差参考均包含上述下限，它不是允许误差。四项都须在所列容差内符合独立手算参考。
   算术平均和不处理边界的方差作为对照帮助理解，程序通过与否仍由下表的参考比较决定。

   .. include:: _generated/case_basic_checks/checks_zh.rst
      :start-after: .. checks-phase-start
      :end-before: .. checks-phase-end

   .. raw:: html

      <details><summary>展开两个独立案例：每张图内部使用相同输入</summary>

   .. figure:: _generated/case_basic_checks/figures/phase_statistics.png
      :width: 100%
      :alt: 案例A左右使用相同四个相位，算术平均约3.66693度，众数格中心3度；不据此比较估计准确性。

      **案例 A：比较统计定义。** 左右使用同一组四个样本，分别计算算术平均和众数格中心。
      输入角度仅在显示时舍入，计算使用原始精度。左图将靠得很近的三个点竖向错开以便辨认。
      右图返回值与手算中心比较；格宽6°会影响返回值，不能把3°视为已知真实相位。

   .. figure:: _generated/case_basic_checks/figures/phase_branch_cut.png
      :width: 100%
      :alt: 案例B左右保持样本身份和顺序，只将负179度写成等价的181度；方差从普通数值算法的约31981.58度平方变为约1.58333度平方。

      **案例 B：比较边界处理。** 每一行是同一次观测，橙色点在左图写作 −179°、右图写作181°。
      只改变角度表示，不替换观测；两图横轴范围与刻度相同，均为 −210° 至210°。
      左侧是普通数值方差的对照计算，右侧程序方差和参考值来自测试记录；均使用 :math:`n-1` 分母与相同下限。

   .. raw:: html

      </details>

   :ref:`返回相位统计原理 <foundations-zh-noise>`

   .. _basic-checks-zh-beall:

   .. rubric:: 3. Beall 权重与谱峰

   **测试目的：** 检查 Beall 谱确实采用平均自功率权重，并正确分箱、除以段数和寻找谱峰。

   当前 Beall 流程规定使用平均自功率作为权重。互相位函数虽然也返回互谱幅值，
   但不能直接把它当作这里的权重。本例特意选择两种权重会产生不同谱峰的输入，
   用来识别权重混用：规定权重的峰应在 −0.5 rad/m，误用互谱幅值时会移到 +0.5 rad/m。
   **互谱幅值在这里是误用对照，不是另一种推荐方案。**

   **输入与操作：** 同一频率取两段 FFT 幅值 (10, 0.1) 与 (2, 2)，相位约为 [−28.64789°, +28.64789°]，
   基线长1 m，波数格边界为 [−1, 0, 1] rad/m。先用规定的平均自功率计算谱及峰位，
   再保持输入不变，故意换成互谱幅值作为误用对照。

   **预期及依据：** 手算 :math:`(|X_1|^2+|X_2|^2)/2` 得到 [50.005, 4]；
   每格各收一个权重，再除以两段，谱值应为 [25.0025, 2]，峰在 −0.5 rad/m。
   误用对照的权重为 [1, 4]，谱值应为 [0.5, 2]，峰在 +0.5 rad/m。

   **通过条件：** 权重和逐格谱值符合各自的手算值，两个离散峰位各自与对应参考精确相等。
   误用互谱幅值会改变主测试的峰位；遗漏除以段数虽不改变峰位，也会在谱值检查中失败。
   对照项通过仅表示其结果符合对照的手算参考，不表示该权重适用于当前 Beall 流程。

   .. include:: _generated/case_basic_checks/checks_zh.rst
      :start-after: .. checks-beall-start
      :end-before: .. checks-beall-end

   两段样本用于构造可手算的案例；通过后可以确认这些步骤在本例中正确，但不能据此认定实际数据中的统计谱峰已稳定。

   .. raw:: html

      <details><summary>展开：规定权重与误用对照</summary>

   .. figure:: _generated/case_basic_checks/figures/beall_weights.png
      :width: 100%
      :alt: 左图为规定的平均自功率权重，峰在负0.5；右图为误用互谱幅值的对照，峰在正0.5。黑色横线标出各自的手算参考。

      左图使用规定的平均自功率权重，峰在 −0.5 rad/m；右图故意误用互谱幅值，峰移到 +0.5 rad/m。
      两图输入相同，右图用于展示传错权重的后果。
      柱高读取保存的谱值，黑色横线为手算参考，并非误差棒。两图纵轴尺度不同，以便看清各自的峰位；数值标在柱顶。

   .. raw:: html

      </details>

   :ref:`返回 Beall 谱原理 <foundations-zh-alias>`

   .. _basic-checks-zh-tolerances:

   .. rubric:: 数值容差为什么这样选

   相位值、误差和绝对容差一起换算为°，方差及其绝对容差换算为°²；相对容差不变，判定与原始记录等价。
   相等性检查要求 :math:`|a-b|\leq\mathrm{atol}+\mathrm{rtol}|b|`。
   本页采用 float64 的机器精度 :math:`\epsilon\approx2.22\times10^{-16}`，
   令 :math:`u=64\epsilon`，对64点累积计算令 :math:`v=64u`：

   - 权重和 Beall 谱值：``rtol=u, atol=0``，随功率数值尺度比较。
   - 积分功率：``rtol=v, atol=0``，为64点变换与求和留出更多舍入余量。
   - 众数格中心：``rtol=0, atol=360u`` （°）；样本方差：``rtol=u, atol=360²u`` （°²）。
   - 直接 DFT 和解析相位：``rtol=0, atol=360v`` （°）；本例相位远离分支边界，直接比较相位值。
   - Beall 谱的离散峰位：精确比较，不使用数值容差。

   系数64是为短计算链和不同求值顺序选择的保守工程余量，**不是严格推导的误差上界，也不是物理精度指标**。
   分箱中心和离散峰位的预期来自已知输入，不能用一个分箱宽度掩盖选错分箱。
   这些容差用于区分舍入差异与实现错误；含噪声测量的精度需要单独的误差模型。

   .. _basic-checks-zh-report:

   .. rubric:: 复现与完整报告

   从仓库根目录运行：

   .. code-block:: bash

      bash tests/010_diagnostics/case_basic_checks/run.sh

   ``output/summary.json`` 保存实际检查记录，``report.py`` 从同一记录生成本页的中英文表格。
   发布快照后，网页构建只读取文件，不重新运行算法。
   波矢恢复、几何约束、网格分块及其余回归检查见 :doc:`完整测试记录 <_generated/case_basic_checks/results>`。
   :download:`完整精度数值报告 <_generated/case_basic_checks/summary.json>` 和
   :download:`运行时间与源码哈希 <_generated/case_basic_checks/provenance.json>` 可用于核查。

   .. code-block:: bash

      bash tests/010_diagnostics/case_basic_checks/run.sh --publish-docs

.. container:: ap-lang ap-lang-en ap-diagnostics-foundations

   These three groups check whether the diagnostics code follows its definitions for known inputs.
   Each gives a purpose, setup, expected behavior and its basis, followed by recorded checks and a conclusion.
   Theory is linked separately; supporting figures can be expanded. Phases are displayed in degrees (°)
   and phase variances in °²; code and full raw records retain radians, and wavenumbers retain rad/m.

   .. include:: _generated/case_basic_checks/checks_en.rst
      :start-after: .. checks-overview-start
      :end-before: .. checks-overview-end

   - :ref:`Spectral power and cross phase <basic-checks-en-spectrum>`
   - :ref:`Phase statistics <basic-checks-en-phase>`
   - :ref:`Beall weights and peaks <basic-checks-en-beall>`

   :ref:`Numerical tolerance policy <basic-checks-en-tolerances>`

   .. _basic-checks-en-spectrum:

   .. rubric:: 1. Spectral power and cross phase

   **Purpose:** Check power normalization and the sign and calculation of cross phase, so a plausible
   spectrum cannot hide incorrect numerical values.

   **Setup:** Generate four demeaned 64-sample records with seed 42. Apply boxcar or Hann windows,
   compute segmented FFTs and power spectra, and integrate :math:`\sum P(f)\Delta f`.
   Sampling at 64 Hz gives :math:`\Delta f=1` Hz. Separately, construct paired cosines differing by
   approximately 45.83662°, with either 2 or 1.25 cycles per record, and read the nearest-bin cross phase.

   **Expected behavior and basis:** For each window, integrated power equals the segment average of
   window-weighted time-domain squares divided by the sum of squared window weights (discrete Parseval).
   Two-cycle records have analytic phase approximately −45.83662° for :math:`X_1X_2^*`. Both records are also compared
   with direct sums :math:`X_k=\sum_n(x_n-\bar{x})e^{-2\pi i kn/N}` that use neither the tested FFT
   nor the cross-phase routine.

   **Pass condition:** Both power values and all three phase comparisons must agree within their stated
   tolerances. Any mismatch fails; the size of leakage bias is not a pass/fail threshold.

   .. include:: _generated/case_basic_checks/checks_en.rst
      :start-after: .. checks-spectrum-start
      :end-before: .. checks-spectrum-end

   Each window is compared with its own time-domain reference; powers need not match across windows.
   An off-bin phase can agree with the direct DFT yet differ from approximately −45.83662°: the former verifies the
   calculation, while the latter describes a limitation of the readout.

   :ref:`Six-panel explanation: cropping, repetition, and leakage <knowledge-leakage-en-record>` ·
   :ref:`Return to spectral theory <foundations-en-spectrum>`

   .. _basic-checks-en-phase:

   .. rubric:: 2. Phase statistics

   **Purpose:** Check the modal bin center and sample variance in two independent cases.
   Within each case the observations are fixed; only the statistical definition or treatment of the
   angular boundary changes. Cases A and B are not a head-to-head accuracy comparison.

   **Case A: same samples, two definitions.** The inputs are approximately [0.63°, 0.69°, 0.74°, 12.61°].
   Both methods use the same unrounded values. The arithmetic mean is approximately 3.66693°.
   With 60 bins of width 6°, three samples fall in [0°, 6°) and one in [12°, 18°), so the program
   should return the modal bin center, 3°. This is not the mean of the three clustered samples.
   No true phase is specified, so this case does not rank estimation accuracy.

   **Case B: same observations, change only boundary handling.** Inputs are [179°, −179°, 178°, 179°].
   Treating them as ordinary numbers gives sample variance approximately 31981.58333 °².
   Rewriting −179° as the equivalent 181° preserves every observation and gives :math:`19/12` °²,
   approximately 1.58333 °². Both calculations use denominator :math:`n-1` and the same regularization
   floor (approximately :math:`3.28280635\times10^{-9}` °²). The program should also return 177°,
   the center of the most populated bin [174°, 180°).

   **Expected behavior and pass condition:** Case A should return center 3° and variance approximately
   35.509022 °²; case B should return 177° and approximately 1.5833333 °². Both variance references
   include the floor, which is not an error tolerance. All four values must agree with independent
   hand calculations within the stated tolerances. Arithmetic means and uncorrected variances serve
   as explanatory controls; pass/fail decisions come from the reference comparisons below.

   .. include:: _generated/case_basic_checks/checks_en.rst
      :start-after: .. checks-phase-start
      :end-before: .. checks-phase-end

   .. raw:: html

      <details><summary>Show two independent cases, with identical inputs within each figure</summary>

   .. figure:: _generated/case_basic_checks/figures/phase_statistics.png
      :width: 100%
      :alt: Case A uses the same four phases on both sides, giving an arithmetic mean of about 3.66693 degrees and a modal bin center of 3 degrees without ranking accuracy.

      **Case A: compare definitions.** Both panels use the same four samples. Input labels are rounded
      for display only. Three tightly spaced points are separated vertically in the left panel.
      The right panel compares the returned center with its reference. The 6° bin width affects the
      returned value; 3° is not a known true phase.

   .. figure:: _generated/case_basic_checks/figures/phase_branch_cut.png
      :width: 100%
      :alt: Case B preserves sample identities and order; only minus 179 degrees becomes the equivalent 181 degrees, changing a naive variance of about 31981.58 square degrees to about 1.58333 square degrees.

      **Case B: compare boundary handling.** Each row is the same observation; the orange point is
      labelled −179° on the left and 181° on the right. No observation is replaced. Both horizontal
      axes use the same limits (−210° to 210°) and ticks. The left variance is an explanatory control; the right
      program variance and reference come from the test record. Both use :math:`n-1` and the same floor.

   .. raw:: html

      </details>

   :ref:`Return to phase statistics <foundations-en-noise>`

   .. _basic-checks-en-beall:

   .. rubric:: 3. Beall weights and peaks

   **Purpose:** Check that Beall uses mean pair auto-power, bins contributions correctly, divides by
   segment count, and selects the correct peak.

   This Beall workflow requires mean pair auto-power as its weight. The cross-phase routine also
   returns cross magnitude, but that output must not be passed directly as the weight here.
   These inputs deliberately produce different peaks under the two weights: −0.5 rad/m with the
   required weight and +0.5 rad/m when cross magnitude is substituted.
   **Cross magnitude is a misuse control here, not an alternative recommended option.**

   **Setup:** Two segments have FFT amplitudes (10, 0.1) and (2, 2), phases approximately [−28.64789°, +28.64789°],
   a 1 m baseline, and wavenumber edges [−1, 0, 1] rad/m. Compute spectra and peaks with the required
   mean auto-power weights, then deliberately substitute cross magnitude with all inputs unchanged.

   **Expected behavior and basis:** Hand evaluation of :math:`(|X_1|^2+|X_2|^2)/2` gives
   [50.005, 4]. Each bin receives one weight divided by two segments, giving [25.0025, 2] and a
   peak at −0.5 rad/m. The misuse-control weights [1, 4] give [0.5, 2] and a peak at +0.5 rad/m.

   **Pass condition:** Weights and both sets of bin values must match the hand calculations within
   tolerance; each discrete peak must match its own reference exactly. Substituting cross-magnitude weights changes
   the main peak. Omitting division by segment count preserves peak position but fails the bin-value checks.
   A passing control only means it matches the control's hand calculation; it does not make that
   weight appropriate for this Beall workflow.

   .. include:: _generated/case_basic_checks/checks_en.rst
      :start-after: .. checks-beall-start
      :end-before: .. checks-beall-end

   Two segments make this case hand-checkable. Passing verifies these steps for this case; it does
   not establish that a statistical peak is stable in practical data.

   .. raw:: html

      <details><summary>Show the required weight and the misuse control</summary>

   .. figure:: _generated/case_basic_checks/figures/beall_weights.png
      :width: 100%
      :alt: The required mean auto-power weight selects minus 0.5; deliberately misusing cross magnitude selects plus 0.5. Black caps mark each case's hand-calculated reference.

      Left: the required mean auto-power weight selects −0.5 rad/m. Right: deliberate misuse of
      cross magnitude moves the peak to +0.5 rad/m for identical inputs, showing the consequence of
      passing the wrong weight. Bars show saved spectra; black caps are hand-calculated references, not error bars.
      Vertical scales differ to make each peak visible; exact values are labelled above the bars.

   .. raw:: html

      </details>

   :ref:`Return to Beall theory <foundations-en-alias>`

   .. _basic-checks-en-tolerances:

   .. rubric:: Why these numerical tolerances

   Values, errors, and absolute tolerances are converted together to ° or °²; relative tolerances
   and pass/fail decisions are unchanged. Equality checks require :math:`|a-b|\leq\mathrm{atol}+\mathrm{rtol}|b|`.
   With float64 machine epsilon :math:`\epsilon\approx2.22\times10^{-16}`, define
   :math:`u=64\epsilon` and, for 64-point reductions, :math:`v=64u`:

   - Weights and Beall bin values: ``rtol=u, atol=0``, relative to the power scale.
   - Integrated power: ``rtol=v, atol=0``, allowing more rounding margin for transforms and sums.
   - Modal bin centers: ``rtol=0, atol=360u`` (°); variances: ``rtol=u, atol=360²u`` (°²).
   - Direct-DFT and analytic phases: ``rtol=0, atol=360v`` (°); these phases lie away from the branch cut.
   - Discrete Beall peak positions: exact comparison.

   The factor 64 is a conservative engineering margin for short calculation chains and differing
   evaluation orders, **not a rigorous error bound or a physical accuracy target**. Bin centers and
   discrete peaks have known references; a whole bin width must not hide a wrong selection.
   These tolerances distinguish rounding differences from implementation errors; accuracy for noisy
   measurements requires a separate error model.

   .. _basic-checks-en-report:

   .. rubric:: Reproduction and complete report

   Run from the repository root:

   .. code-block:: bash

      bash tests/010_diagnostics/case_basic_checks/run.sh

   ``output/summary.json`` holds recorded assertions; ``report.py`` generates both language tables
   from that same record. After publication, Sphinx reads the snapshot without rerunning algorithms.
   Wavevector recovery, geometry, grid-block checks, and remaining assertions are in the
   :doc:`complete verification table <_generated/case_basic_checks/results>`.
   Download the :download:`full-precision report <_generated/case_basic_checks/summary.json>` or
   :download:`run time and source hashes <_generated/case_basic_checks/provenance.json>` to audit them.

   .. code-block:: bash

      bash tests/010_diagnostics/case_basic_checks/run.sh --publish-docs
