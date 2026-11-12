07 · From measured statistics to linear and quadratic coefficients
==================================================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-experiment-coefficients-en:

   .. rubric:: Turn the measured averages into a prediction

   The :ref:`previous page <k05-experiment-en>` produced complex Fourier
   coefficients and their averages. Now use them to answer a concrete question:
   **given C1 in one short segment, how much of the simultaneous C3 coefficient
   can we predict?** Start with one multiplier, then add products of two input
   frequencies. This applies the :ref:`coefficient calculation from page 05
   <k05-inference-en>` to measured data, using the two-probe model in [1].

   Keep the same preprocessing: 2048 samples, segment-mean removal, a periodic
   Hann window, and the positive Fourier exponent divided by 2048. The target
   :math:`f_*=2.001953125\ \mathrm{MHz}` is still bin 41, the nearest bin to 2 MHz.
   :math:`X_f^{(r)}` and :math:`Y_f^{(r)}` are the C1 and C3 coefficients in segment
   :math:`r`, both in volts. The :ref:`probe geometry <k05-experiment-geometry-en>`
   is unchanged; C1-to-C3 prediction does not by itself determine propagation.

   **Fit on captures 3, 4 and 5; test on capture 2.** A capture is one complete
   simultaneous recording. Each supplies 4882 segments, so the fit uses 14646
   rows and the test uses 4882. Below, unmarked angle brackets average training
   rows; a “test” subscript means the separate held-out recording. Page 06 used
   capture 2 for its worked statistics, so the training averages here are
   slightly different even at the same frequency.

   .. rubric:: 1. First fit one complex multiplier

   With only a linear term, :math:`\widehat Y=L_0X`. A hat means prediction,
   and the subscript 0 identifies this restricted model. Omit the product columns in
   :k05:eq:`inference-matrix` and use the training power
   :math:`P_X=\langle|X|^2\rangle` and cross moment
   :math:`G=\langle YX^*\rangle`; the star denotes complex conjugation.

   .. k05:equation:: experiment-fit-linear
      :lang: en

      \begin{aligned}
      P_X&=8.27538\times10^{-5}\ \mathrm{V^2},\\
      G&=(6.83756-2.38867i)\times10^{-5}\ \mathrm{V^2},\\
      L_0&=\frac{G}{P_X}=0.826254-0.288647i
          =0.87522\,e^{-0.33609i}.
      \end{aligned}

   Multiplication by :math:`L_0` scales each complex input by about 0.875 and
   rotates it by about −0.336 rad. Here :math:`i^2=-1`. It is one fitted relation shared by all
   segments, not one multiplier fitted separately to each point.

   .. figure:: /_static/K_Diagnostics/k05-fit-linear-example.svg
      :width: 100%
      :alt: Real parts and complex-plane positions of measured and linearly predicted coefficients at 2.002 MHz.

      Figure 1. The first 80 segments of held-out capture 2 at the fixed target frequency.

   The left panel plots the real part against segment number; it is not the
   original voltage waveform. The right panel locates the same measured and
   predicted complex coefficients. Short connecting lines show the discrepancy
   for each segment. Their closeness means the linear relation already captures
   much of this frequency component. It does not say what produced that relation.

   .. rubric:: 2. Give the model two explicit frequency products

   A quadratic input is a product :math:`Z_j=X_{f_{1j}}X_{f_{2j}}`, where
   :math:`j` labels a frequency pair and :math:`f_{1j}+f_{2j}=f_*`. Start with
   two fixed examples on the same grid. Write :math:`X_k` for the coefficient
   at bin :math:`k`; the grid spacing is :math:`\Delta f=48.828125\ \mathrm{kHz}`.

   .. k05:equation:: experiment-fit-pairs
      :lang: en

      \begin{aligned}
      Z_1^{(r)}&=X_{10}^{(r)}X_{31}^{(r)},\\
      f_1+f_2&=(0.48828125+1.513671875)\ \mathrm{MHz}=f_*,\\
      Z_2^{(r)}&=X_{-10}^{(r)}X_{51}^{(r)}
                =(X_{10}^{(r)})^*X_{51}^{(r)},\\
      f_1+f_2&=(-0.48828125+2.490234375)\ \mathrm{MHz}=f_* .
      \end{aligned}

   The first is a sum-frequency pair; the second is a difference-frequency
   pair, represented with a negative input. Because the measured signal is real,
   :math:`X_{-k}=X_k^*`. Both products use coefficients from **the same segment**
   and have units V².

   .. figure:: /_static/K_Diagnostics/k05-fit-products.svg
      :width: 100%
      :alt: Real and imaginary parts of two actual quadratic inputs across training segments.

      Figure 2. The two products in the first 80 training segments of capture 3.

   These are the extra inputs that the fit can use. Neither curve is a
   coupling coefficient yet. For each pair, average its relation to the target:
   :math:`b_j=\langle XZ_j^*\rangle` and
   :math:`d_j=\langle YZ_j^*\rangle`, both in V³.
   Also compute :math:`F_{ij}=\langle Z_i^*Z_j\rangle` in V⁴.
   The matrix :math:`\mathbf F` retains cross terms between different products;
   its diagonal is :math:`\langle|Z_j|^2\rangle`.
   For the positive pair, :math:`b_1=B_X(f_1,f_2)^*`, connecting directly to
   the complex bispectrum on page 06.

   .. raw:: html

      <details class="k05-note"><summary>Put these measured numbers into a small matrix</summary>

   The two-pair version of :k05:eq:`inference-matrix` is

   .. k05:equation:: experiment-fit-small-matrix
      :lang: en

      \begin{pmatrix}
      P_X&b_1^*&b_2^*\\ b_1&F_{11}&F_{12}\\ b_2&F_{21}&F_{22}
      \end{pmatrix}
      \begin{pmatrix}L\\Q_1\\Q_2\end{pmatrix}
      =\begin{pmatrix}G\\d_1\\d_2\end{pmatrix}.

   The first row uses the input :math:`X`, and the next two rows use
   :math:`Z_1,Z_2`. Thus the first row has units V² and the other rows V³
   after multiplication by the unknowns. :math:`L` is dimensionless;
   :math:`Q_1,Q_2` have units V⁻¹.

   To make the numerical entries easy to compare, divide each input column
   :math:`D_i` by its training RMS :math:`s_i=\sqrt{\langle|D_i|^2\rangle}`,
   where :math:`(D_0,D_1,D_2)=(X,Z_1,Z_2)`.
   Here :math:`s_0=9.09691\times10^{-3}\ \mathrm V`,
   :math:`s_1=1.00478\times10^{-4}\ \mathrm{V^2}` and
   :math:`s_2=8.87445\times10^{-5}\ \mathrm{V^2}`.
   Let :math:`M_{ij}=\langle(D_i/s_i)^*(D_j/s_j)\rangle` and
   :math:`h_i=\langle(D_i/s_i)^*Y\rangle`. The scaled unknowns
   :math:`\boldsymbol\theta=(s_0L,s_1Q_1,s_2Q_2)^{\mathsf T}` are all in volts.

   .. k05:equation:: experiment-fit-numerical-matrix
      :lang: en

      \begin{aligned}
      \mathbf M&=\begin{pmatrix}
      1&-0.06136-0.02910i&0.00775+0.02425i\\
      -0.06136+0.02910i&1&-0.00121-0.00190i\\
      0.00775-0.02425i&-0.00121+0.00190i&1
      \end{pmatrix},\\
      \mathbf h&=\begin{pmatrix}
      7.51636-2.62580i\\-0.37656+0.39334i\\-0.00606-0.20365i
      \end{pmatrix}10^{-3}\ \mathrm V,\qquad
      \mathbf M\boldsymbol\theta=\mathbf h .
      \end{aligned}

   Solving with unrounded numbers and dividing by the respective :math:`s_i`
   gives :math:`L=0.826264-0.288527i`,
   :math:`Q_1=(0.082514+0.134931i)\ \mathrm{V^{-1}}` and
   :math:`Q_2=(-0.006596-0.011556i)\ \mathrm{V^{-1}}`.
   These belong to the two-pair teaching model. Adding more columns changes
   the fit; these two values must not be spliced into the full model below.

   .. figure:: /_static/K_Diagnostics/k05-fit-matrix.svg
      :width: 100%
      :alt: Magnitudes and phases of the scaled three-by-three measured moment matrix.

      Figure 3. Magnitude and phase of the matrix just written out numerically.

   The unit diagonal follows from RMS scaling. The off-diagonal entries retain
   both strength and phase. Replacing them by bicoherence magnitudes would
   change the equations.

   .. raw:: html

      </details>

   .. rubric:: 3. Fit all retained pairs together

   Now repeat the calculation for targets from 0.5 to 5 MHz, using every nonzero
   signed input bin with :math:`|f_1|,|f_2|\leq5\ \mathrm{MHz}` and
   :math:`f_1+f_2=f`. Keep only :math:`f_1\leq f_2`: exchanging the two
   inputs gives the same product, so count it once. The actual target bins
   span 0.537109375–4.98046875 MHz.

   .. k05:equation:: experiment-fit-joint
      :lang: en

      \begin{aligned}
      \widehat Y_f^{(r)}&=L_fX_f^{(r)}
       +\sum_{j=1}^{J_f}Q_{fj}Z_j^{(r)},\\
      &\min_{L_f,\{Q_{fj}\}}\ \sum_{r\in\mathrm{train}}
           \left|Y_f^{(r)}-\widehat Y_f^{(r)}\right|^2 .
      \end{aligned}

   :math:`J_f` is the number of retained pairs, 81 at :math:`f_*`.
   This is a complex least-squares fit (LS), with no intercept. **Fit all coefficients together:** :math:`L_f` and every :math:`Q_{fj}`. Keeping the earlier
   :math:`L_0` fixed and fitting only the residual would solve a different problem.

   .. figure:: /_static/K_Diagnostics/k05-fit-linear-coefficients.svg
      :width: 100%
      :alt: Linear-only and jointly fitted linear coefficient magnitudes and phases versus target frequency.

      Figure 4. Linear coefficients. Strong curves fit captures 3/4/5; faint curves show the other three training splits.

   The upper panel is a dimensionless amplitude multiplier, and the lower panel
   is its angle in radians. At the dotted example frequency the joint fit gives
   :math:`L=0.824588-0.285865i`, close to :math:`L_0`.
   Closeness means that introducing these extra inputs changes the fitted
   same-frequency relation only slightly. Neither :math:`|L|<1` nor the sign
   of its phase alone establishes plasma damping or a propagation direction.

   .. figure:: /_static/K_Diagnostics/k05-fit-quadratic-map.svg
      :width: 100%
      :alt: Magnitude and phase of unique-pair quadratic coefficients, with signed input frequencies on the axes.

      Figure 5. Joint-LS quadratic coefficients fitted on captures 3/4/5.

   Every colored cell is one pair :math:`(f_1,f_2)` whose target is
   :math:`f=f_1+f_2`. The negative left half contains difference pairs;
   the positive half contains sum pairs. Gray cells were not fitted, not
   measured to have zero coupling. The dashed line selects the 81 pairs
   feeding the same 2.002 MHz target. The magnitude panel uses a logarithmic
   color scale, with a display floor of :math:`0.01\ \mathrm{V^{-1}}`;
   the phase panel uses radians.

   This is a **fitted coefficient map**, unlike page 06's bicoherence map.
   A bright cell means a larger :math:`|Q|` per unit input product under this
   voltage normalization. The actual predicted term is :math:`Q_jZ_j`:
   a large coefficient with a weak input can still contribute little.
   Its magnitude also lacks the target's phase relation needed for signed transfer.
   Figure 3(a) of [1] is a coefficient-magnitude plot of this type; the
   :ref:`paper comparison <k05-comparison-en>` explains its different normalization
   and the conversion from unique pairs to a symmetric ordered-pair display.

   .. raw:: html

      <details class="k05-note"><summary>How the solver checks whether the columns can be distinguished</summary>

   The matrix above explains the moments. The numerical fit uses the
   singular value decomposition (SVD) of the scaled segment-by-column design
   matrix directly, rather than explicitly inverting its moment matrix.
   Only training rows determine the RMS scales; divide the solved coefficients
   by those scales to restore their units. The fixed singular-value cutoff is
   :math:`10^{-10}` times the largest value.

   At :math:`f_*` the full design has 82 columns and rank 82; the scaled
   condition number is 6.323. Across all 92 targets and four splits,
   the conditions range from 4.888 to 10.765 and all fits have full column rank.
   They pass the chosen numerical threshold of :math:`10^8`. This rules out
   an obvious numerical degeneracy in these fits, not experimental noise,
   omitted inputs, or systematic probe-response errors. The four fits share
   training captures; their spread is not a confidence interval.

   .. raw:: html

      </details>

   .. rubric:: 4. Apply the Kim calculation, then check its common power

   Ordinary LS chooses coefficients for a small prediction residual. The
   stationary model of Kim et al. [2] additionally seeks a common underlying
   power :math:`P_*`, with nonnegative extra power at each probe. It uses the same
   measured moments, but imposes different conditions. Follow
   :k05:eq:`kim-computation-quantities` and :k05:eq:`kim-stationary-solution`
   from page 05, using all 81 pairs at the example frequency.

   .. raw:: html

      <details class="k05-note"><summary>Carry out the Kim recipe with the measured moments</summary>

   First solve :math:`\mathbf F\mathbf u_b=\mathbf b` and
   :math:`\mathbf F\mathbf u_d=\mathbf d`. Form
   :math:`\alpha=\mathbf b^\dagger\mathbf u_b`,
   :math:`\beta=\mathbf d^\dagger\mathbf u_d` and
   :math:`\eta=G-\mathbf b^\dagger\mathbf u_d`; the dagger means conjugate transpose.
   These are intermediate combinations of the measured moments, all in V²,
   not additional experimental parameters.

   .. k05:equation:: experiment-fit-kim
      :lang: en

      \begin{aligned}
      \alpha&=2.38913\times10^{-5}\ \mathrm{V^2},\\
      \beta&=1.85809\times10^{-5}\ \mathrm{V^2},\\
      \eta&=(4.85374-1.68267i)\times10^{-5}\ \mathrm{V^2},\\
      P_*&=\frac{\alpha+\beta+
        \sqrt{(\alpha-\beta)^2+4|\eta|^2}}{2}
        =7.26760\times10^{-5}\ \mathrm{V^2},\\
      L_{\mathrm{Kim}}&=\frac{\eta}{P_*-\alpha}
         =0.994929-0.344918i,\\
      \mathbf q_{\mathrm{Kim}}&=\mathbf u_d-L_{\mathrm{Kim}}\mathbf u_b .
      \end{aligned}

   :math:`\mathbf q` collects the 81 quadratic coefficients. This formula
   uses the full :math:`\mathbf F`, including off-diagonal entries; it does not
   assume independent pair products. The saved arrays contain every complex
   coefficient and the input moments. Substitution satisfies the moment
   equations numerically, but a second check is essential.

   .. raw:: html

      </details>

   **A common underlying power cannot exceed either measured power in this
   model:** :math:`0\leq P_*\leq\min(P_X,P_Y)`.
   Here :math:`P_Y=6.37467\times10^{-5}\ \mathrm{V^2}`, so
   :math:`P_*/\min(P_X,P_Y)=1.14008`. It fails: subtracting this
   common power from C3's measured power would require a negative extra power.

   .. figure:: /_static/K_Diagnostics/k05-fit-kim.svg
      :width: 100%
      :alt: Kim common power divided by the smaller measured power, and linear magnitudes compared with least squares.

      Figure 6. The common-power check above, and the resulting linear coefficients below.

   Read the upper panel first. The allowed interval is 0–1; its upper portion
   is shaded green. Open circles mark failures above 1. Only 8 of 92 targets
   pass in this training split, and 35 of 368 pass across all four splits.
   Passing is necessary, not sufficient, for this interpretation. The lower
   panel preserves the algebraic Kim output so the difference from LS is visible;
   the open circles are **not validated corrected coefficients**.
   Equality of the recorded discharge condition does not establish equal
   underlying fluctuation powers or the assumed uncorrelated noise at the probes.

   .. _k05-kim-failure-en:

   **For most frequencies here, the Kim output cannot be accepted as a
   physically admissible noise correction under the assumptions used.**
   The estimated moments do not permit the assumed common-power split with
   nonnegative extra powers. This is a failure of that interpretation for
   these data and this normalization, not a general failure of the Kim method.
   Possible causes include unequal underlying powers at the two positions,
   different channel responses, or nonzero noise-related mixed moments that
   the model neglects; finite-sample uncertainty can also affect the estimates.
   Figure 6 alone does not identify which cause dominates. Clipping the ratio
   to 1 would not repair the assumptions.

   **For prediction of these measured signals, use Joint LS as the baseline
   and check its held-out errors in Figure 7.** “Joint” means fitting the
   linear and quadratic coefficients together; it is not the Kim correction.
   Joint LS does not require equal underlying powers at the two probes, so
   failure of the Kim bound does not invalidate that predictive fit.
   However, input noise and channel response can still bias its coefficients.
   Returning to the Joint LS curve therefore does not, by itself, establish
   physical growth or energy transfer.

   .. rubric:: 5. Return to the recording that was not used for fitting

   Apply the three fitted relations to C1 from capture 2, then compare with its
   measured C3. The residual is :math:`Y-\widehat Y`. The upper panel divides
   its mean squared magnitude by :math:`P_{Y,\mathrm{test}}`, as in
   :k05:eq:`validation-nmse`; smaller is better. The lower panel retains V².

   .. figure:: /_static/K_Diagnostics/k05-fit-heldout.svg
      :width: 100%
      :alt: Held-out normalized prediction error and residual power for linear, joint least-squares and algebraic Kim coefficients.

      Figure 7. Prediction errors. Strong curves test capture 2; faint curves in the upper panel show the other three held-out captures.

   At :math:`f_*`, the normalized errors are **0.5737%** for the linear-only
   model, **0.5412%** for joint LS, and **3.6268%** for the algebraic Kim result.
   The LS error reduction is 5.67% of the linear residual, or only 0.0325
   percentage points of the measured target power. These are different denominators.
   The reduction is not a measurement of the fraction of wave energy transferred
   nonlinearly.

   For capture 2, the relative LS improvement spans −0.17% to 12.18% across the
   retained targets; its frequency median is 5.09%. The four fold medians range
   from 4.70% to 5.09%. Thus quadratic inputs give a modest, repeatable
   predictive improvement over much of this band, not an improvement at every
   frequency. Kim is not designed to minimize this held-out error, and its
   failed common-power check already prevents the proposed stationary-noise
   interpretation at the example frequency.

   .. rubric:: What the coefficients allow us to do next

   The statistical calculation is now closed: the records supply the moments,
   and the specified input set supplies enough equations to fit :math:`L,Q`.
   To turn them into physical growth and signed transfer, the measurement
   response, spatial phase interpretation and a justified group velocity still
   matter. Continue with :ref:`what the probe measures <k05-response-en>`,
   then the :ref:`comparison with Figures 2 and 3 <k05-comparison-en>`.
   For the full four-fold validation, bandwidth/segment sensitivity and the
   5–20 MHz example, see the :ref:`validation supplement <k05-validation-en>`.

   .. raw:: html

      <details class="k05-note"><summary>Reproduce the calculations and figures</summary>

   The script reads the four raw capture pairs and the previously saved
   validation and Kim-budget results. It verifies input hashes, matching grids
   and LS coefficients, recomputes the training moments, and independently
   refits the fixed example. It does not refit the entire grid just to redraw it.

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_coefficient_walkthrough.py \
        --data /path/to/experiment-data \
        --validation /path/to/validation-results \
        --budget /path/to/transfer-budget-results \
        --output /path/to/new-coefficient-walkthrough

   Use a new empty output directory. The result contains seven SVG/PNG figures,
   coefficient_walkthrough_arrays.npz and coefficient_walkthrough_summary.json.
   Parent runs can be generated with validate_experiment.py and
   analyze_transfer_budget.py; exact commands and dependencies are in
   :download:`EXPERIMENT.md <../../../../K_Diagnostics/K05_bispectral_transfer/EXPERIMENT.md>`.
   The arrays save the small measured matrix, complete example moments,
   coefficients and held-out predictions. The manifest records hashes,
   training/test groups, units and numerical checks.

   :download:`Calculation script <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_coefficient_walkthrough.py>`
   · :download:`Figure provenance <../../_static/K_Diagnostics/k05-fit-summary.json>`.
   Run in a checkout containing the shared readers and fit functions.
   Opening this page does not run Python.

   .. raw:: html

      </details>

   .. rubric:: References

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.
   The source-model and moment-equation comparisons are on :ref:`page 05
   <k05-source-3-en>` and :ref:`its moment comparison <k05-source-5-en>`.

   [2] J. S. Kim, R. D. Durst, R. J. Fonck, E. Fernandez, A. Ware and P. W. Terry,
   “Technique for the experimental estimation of nonlinear energy transfer in
   fully developed turbulence,” *Physics of Plasmas* **3**, 3998–4009 (1996).
   `doi:10.1063/1.871572 <https://doi.org/10.1063/1.871572>`_.

.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-experiment-coefficients-zh:

   .. rubric:: 从实测统计量求线性与二次系数

   :ref:`上一页 <k05-experiment-zh>` 已经算出复 Fourier 系数及其平均量。
   现在用它们回答一个具体问题：**已知一个短段的 C1，能预测出多少同时测得的 C3 系数？**
   先用一个乘数，再加入两个输入频率的乘积。本页把
   :ref:`第 05 页的系数算法 <k05-inference-zh>` 用到真实数据，
   对应文献 [1] 的双探针模型（two-probe model）。

   预处理保持一致：每段 2048 点、去段均值、周期 Hann 窗、正指数 Fourier 变换并除以 2048。
   目标仍是最接近 2 MHz 的第 41 个频点，记作 :math:`f_*=2.001953125\ \mathrm{MHz}`。
   :math:`X_f^{(r)}`、:math:`Y_f^{(r)}` 分别是第 :math:`r` 段的 C1、C3 复系数，
   单位都是 V。:ref:`探针几何 <k05-experiment-geometry-zh>` 不变；
   从 C1 预测 C3 这个计算方向本身不确定波的传播方向。

   **用第 3、4、5 组拟合，第 2 组检验。** 一组是一整次双通道同步记录，
   每组给出 4882 个短段，因此拟合用 14646 行，检验用另外 4882 行。
   下面不带说明的尖括号表示对训练段平均；带“test”的量才对留出组平均。
   第 06 页的示例统计用第 2 组，所以这里即使频点相同，训练平均值也略有不同。

   .. rubric:: 1. 先求一个复数乘数

   只有线性项时，:math:`\widehat Y=L_0X`。帽子表示预测值，
   下标 0 表示这个仅含线性项的模型。把训练数据的功率
   :math:`P_X=\langle|X|^2\rangle` 和互矩
   :math:`G=\langle YX^*\rangle` 用于 :k05:eq:`inference-matrix` 去掉乘积列后的第一行，
   星号表示复共轭：

   .. k05:equation:: experiment-fit-linear
      :lang: zh

      \begin{aligned}
      P_X&=8.27538\times10^{-5}\ \mathrm{V^2},\\
      G&=(6.83756-2.38867i)\times10^{-5}\ \mathrm{V^2},\\
      L_0&=\frac{G}{P_X}=0.826254-0.288647i
          =0.87522\,e^{-0.33609i}.
      \end{aligned}

   乘以 :math:`L_0`，就是把每个复数输入的长度缩为约 0.875 倍，
   并旋转约 −0.336 rad，其中 :math:`i^2=-1`。所有短段共用这一个拟合关系，
   不是对每个点分别调一个乘数。

   .. figure:: /_static/K_Diagnostics/k05-fit-linear-example.svg
      :width: 100%
      :alt: 2.002 MHz 处，实测与线性预测复系数的实部及复平面位置。

      图 1．固定目标频率，展示留出第 2 组的前 80 个短段。

   左图横轴是短段编号，纵轴是复系数的实部，不是原始电压波形。
   右图把同一批实测与预测系数放到复平面，细线连接同一段的两个点。
   两者接近，说明这个频率成分已经能被线性关系预测得较好；
   至于这种关系由什么物理过程形成，仅凭接近还不能判断。

   .. rubric:: 2. 给模型加入两个看得见的频率乘积

   二次输入是乘积 :math:`Z_j=X_{f_{1j}}X_{f_{2j}}`，
   :math:`j` 是波对编号，两个频率满足 :math:`f_{1j}+f_{2j}=f_*`。
   先固定两个简单例子。用 :math:`X_k` 表示第 :math:`k` 个频点的系数，
   频点间隔为 :math:`\Delta f=48.828125\ \mathrm{kHz}`：

   .. k05:equation:: experiment-fit-pairs
      :lang: zh

      \begin{aligned}
      Z_1^{(r)}&=X_{10}^{(r)}X_{31}^{(r)},\\
      f_1+f_2&=(0.48828125+1.513671875)\ \mathrm{MHz}=f_*,\\
      Z_2^{(r)}&=X_{-10}^{(r)}X_{51}^{(r)}
                =(X_{10}^{(r)})^*X_{51}^{(r)},\\
      f_1+f_2&=(-0.48828125+2.490234375)\ \mathrm{MHz}=f_* .
      \end{aligned}

   第一对是和频（sum frequency），第二对用负频率写出差频（difference frequency）。
   实测信号为实数，所以 :math:`X_{-k}=X_k^*`。
   两个乘积都取自 **同一个短段**，单位都是 V²。

   .. figure:: /_static/K_Diagnostics/k05-fit-products.svg
      :width: 100%
      :alt: 两个真实二次输入在训练短段中的实部与虚部。

      图 2．第 3 组最前面 80 段中的两个乘积。

   这两条复数序列就是模型增加的输入，此时还没有求出耦合系数。
   对每个乘积，分别计算它与目标频点的平均关系：
   :math:`b_j=\langle XZ_j^*\rangle`、
   :math:`d_j=\langle YZ_j^*\rangle`，两者单位都是 V³。
   再计算 :math:`F_{ij}=\langle Z_i^*Z_j\rangle`，单位 V⁴。
   矩阵 :math:`\mathbf F` 包含不同乘积之间的交叉项，对角线是
   :math:`\langle|Z_j|^2\rangle`。对于正频率的第一对，
   :math:`b_1=B_X(f_1,f_2)^*`，这就接上了第 06 页的复双谱。

   .. raw:: html

      <details class="k05-note"><summary>把实测的数放进一个小矩阵</summary>

   :k05:eq:`inference-matrix` 在只有两个波对时写成：

   .. k05:equation:: experiment-fit-small-matrix
      :lang: zh

      \begin{pmatrix}
      P_X&b_1^*&b_2^*\\ b_1&F_{11}&F_{12}\\ b_2&F_{21}&F_{22}
      \end{pmatrix}
      \begin{pmatrix}L\\Q_1\\Q_2\end{pmatrix}
      =\begin{pmatrix}G\\d_1\\d_2\end{pmatrix}.

   第一行来自输入 :math:`X`，后两行分别来自 :math:`Z_1,Z_2`。
   矩阵乘上未知系数以后，第一行单位是 V²，后两行是 V³；
   :math:`L` 无量纲，:math:`Q_1,Q_2` 的单位为 V⁻¹。

   为了让数值容易比较，先把每列输入 :math:`D_i` 除以它在训练集上的
   均方根（RMS） :math:`s_i=\sqrt{\langle|D_i|^2\rangle}`，
   这里 :math:`(D_0,D_1,D_2)=(X,Z_1,Z_2)`。
   算得 :math:`s_0=9.09691\times10^{-3}\ \mathrm V`、
   :math:`s_1=1.00478\times10^{-4}\ \mathrm{V^2}`、
   :math:`s_2=8.87445\times10^{-5}\ \mathrm{V^2}`。
   定义 :math:`M_{ij}=\langle(D_i/s_i)^*(D_j/s_j)\rangle`、
   :math:`h_i=\langle(D_i/s_i)^*Y\rangle`。
   缩放后的未知量
   :math:`\boldsymbol\theta=(s_0L,s_1Q_1,s_2Q_2)^{\mathsf T}` 单位统一为 V：

   .. k05:equation:: experiment-fit-numerical-matrix
      :lang: zh

      \begin{aligned}
      \mathbf M&=\begin{pmatrix}
      1&-0.06136-0.02910i&0.00775+0.02425i\\
      -0.06136+0.02910i&1&-0.00121-0.00190i\\
      0.00775-0.02425i&-0.00121+0.00190i&1
      \end{pmatrix},\\
      \mathbf h&=\begin{pmatrix}
      7.51636-2.62580i\\-0.37656+0.39334i\\-0.00606-0.20365i
      \end{pmatrix}10^{-3}\ \mathrm V,\qquad
      \mathbf M\boldsymbol\theta=\mathbf h .
      \end{aligned}

   用未舍入的数求解，再分别除以 :math:`s_i`，得到
   :math:`L=0.826264-0.288527i`、
   :math:`Q_1=(0.082514+0.134931i)\ \mathrm{V^{-1}}`、
   :math:`Q_2=(-0.006596-0.011556i)\ \mathrm{V^{-1}}`。
   它们属于这个只有两个波对的教学模型。加入更多列会改变拟合，
   不能把这两个 Q 直接拼到下面的完整模型里。

   .. figure:: /_static/K_Diagnostics/k05-fit-matrix.svg
      :width: 100%
      :alt: 实测三乘三矩阵缩放后的模与相位。

      图 3．把刚写出的数值矩阵画成模与相位。

   对角线为 1，是按列 RMS 缩放的结果；非对角线同时保留强度和相位。
   把这些复数换成双相干的模，会改变待求的方程。

   .. raw:: html

      </details>

   .. rubric:: 3. 把保留的波对放在一起求解

   现在对 0.5–5 MHz 的目标频点重复计算，输入包含所有非零的带符号频点：
   :math:`|f_1|,|f_2|\leq5\ \mathrm{MHz}`，且 :math:`f_1+f_2=f`。
   只保留 :math:`f_1\leq f_2`，因为交换两个输入仍是同一个乘积，
   不再重复计数。网格上实际覆盖 0.537109375–4.98046875 MHz。

   .. k05:equation:: experiment-fit-joint
      :lang: zh

      \begin{aligned}
      \widehat Y_f^{(r)}&=L_fX_f^{(r)}
       +\sum_{j=1}^{J_f}Q_{fj}Z_j^{(r)},\\
      &\min_{L_f,\{Q_{fj}\}}\ \sum_{r\in\mathrm{train}}
           \left|Y_f^{(r)}-\widehat Y_f^{(r)}\right|^2 .
      \end{aligned}

   :math:`J_f` 是保留的波对数，在 :math:`f_*` 处有 81 对。
   这是没有截距项的复数最小二乘（least squares，LS）。
   **全部系数一起重新拟合**，包括线性系数 :math:`L_f` 和所有二次系数 :math:`Q_{fj}`。
   如果固定前面的 :math:`L_0`，只对残差拟合 Q，就变成了另一个问题。

   .. figure:: /_static/K_Diagnostics/k05-fit-linear-coefficients.svg
      :width: 100%
      :alt: 仅线性模型与联合拟合的线性系数幅值、相位随目标频率的变化。

      图 4．线性系数。深色曲线用第 3/4/5 组拟合，浅色曲线对应另外三种训练组划分。

   上图是无量纲的幅值乘数，下图是以 rad 表示的相位角。
   虚线标出的示例频率上，联合拟合给出
   :math:`L=0.824588-0.285865i`，与 :math:`L_0` 很接近。
   这说明增加二次输入后，拟合出的同频率关系变化不大。
   单凭 :math:`|L|<1` 不能确认等离子体中的阻尼，单凭相位正负也不能确定传播方向。

   .. figure:: /_static/K_Diagnostics/k05-fit-quadratic-map.svg
      :width: 100%
      :alt: 以两个带符号输入频率为坐标，显示唯一波对的二次系数幅值与相位。

      图 5．用第 3/4/5 组联合最小二乘拟合的二次系数。

   每个有色格点是一对 :math:`(f_1,f_2)`，对应的目标频率为
   :math:`f=f_1+f_2`。左半边的负频率输入组成差频对，正频率部分组成和频对。
   灰色区域没有拟合，不是测得系数为零。虚线选出共同通向 2.002 MHz 目标的 81 对。
   模长图用对数色标，显示下限为 :math:`0.01\ \mathrm{V^{-1}}`；
   相位图的单位是 rad。

   这里是 **拟合系数图**，与第 06 页的双相干图不同。
   亮格表示在当前电压归一化下，每单位输入乘积对应更大的 :math:`|Q|`。
   实际预测项是 :math:`Q_jZ_j`，输入很弱时，即使 Q 较大，贡献也可能很小。
   此外，只有模长还缺少与目标的相位关系，不能给出转移方向。
   文献 [1] 图 3(a) 属于这一类系数模长图；后面的
   :ref:`论文对照页 <k05-comparison-zh>` 会说明归一化差别，
   以及如何把这里的唯一波对转换为对称的有序波对显示。

   .. raw:: html

      <details class="k05-note"><summary>计算时怎样检查这些输入列能否分开？</summary>

   上面的矩阵用于说明统计量。实际求解直接对“短段 × 输入列”的缩放设计矩阵
   做奇异值分解（singular value decomposition，SVD），不显式求矩矩阵的逆。
   缩放 RMS 只由训练段决定，解完后除以相应尺度恢复系数单位。
   奇异值截断固定为最大奇异值的 :math:`10^{-10}`。

   :math:`f_*` 处有 82 列，秩为 82，缩放后的条件数（condition number）为 6.323。
   全部 92 个目标频点、四种训练划分都满列秩，条件数为 4.888–10.765，
   通过本计算选定的 :math:`10^8` 数值阈值。
   这排除了这些拟合中明显的数值退化，不代表排除了实验噪声、遗漏输入或探针响应误差。
   四次拟合共用部分训练记录，其离散范围不是置信区间。

   .. raw:: html

      </details>

   .. rubric:: 4. 按 Kim 步骤计算，再检查共同功率

   普通最小二乘追求较小的预测残差。Kim 等人 [2] 的平稳模型还要找一个
   共同的底层功率 :math:`P_*`，并要求每支探针的额外功率非负。
   输入仍是同一套实测统计量，但施加的条件不同。
   沿第 05 页的 :k05:eq:`kim-computation-quantities` 和
   :k05:eq:`kim-stationary-solution`，在示例频点用全部 81 对继续计算。

   .. raw:: html

      <details class="k05-note"><summary>把实测统计量代入 Kim 的计算步骤</summary>

   先解 :math:`\mathbf F\mathbf u_b=\mathbf b`、
   :math:`\mathbf F\mathbf u_d=\mathbf d`。
   然后算 :math:`\alpha=\mathbf b^\dagger\mathbf u_b`、
   :math:`\beta=\mathbf d^\dagger\mathbf u_d`、
   :math:`\eta=G-\mathbf b^\dagger\mathbf u_d`，其中匕首表示共轭转置。
   这些都是由实测统计量组合出的中间量，单位为 V²，不是额外需要测量的实验参数：

   .. k05:equation:: experiment-fit-kim
      :lang: zh

      \begin{aligned}
      \alpha&=2.38913\times10^{-5}\ \mathrm{V^2},\\
      \beta&=1.85809\times10^{-5}\ \mathrm{V^2},\\
      \eta&=(4.85374-1.68267i)\times10^{-5}\ \mathrm{V^2},\\
      P_*&=\frac{\alpha+\beta+
        \sqrt{(\alpha-\beta)^2+4|\eta|^2}}{2}
        =7.26760\times10^{-5}\ \mathrm{V^2},\\
      L_{\mathrm{Kim}}&=\frac{\eta}{P_*-\alpha}
         =0.994929-0.344918i,\\
      \mathbf q_{\mathrm{Kim}}&=\mathbf u_d-L_{\mathrm{Kim}}\mathbf u_b .
      \end{aligned}

   :math:`\mathbf q` 收集全部 81 个二次系数。这里使用完整的
   :math:`\mathbf F`，保留非对角项，不假定不同波对乘积彼此独立。
   输出数组保存了每个复系数和输入矩。代回后，统计矩方程在数值上成立，
   但还必须做下面这一步检查。

   .. raw:: html

      </details>

   **在这个模型里，共同底层功率不能比任何一路实测功率更大：**
   :math:`0\leq P_*\leq\min(P_X,P_Y)`。
   这里 :math:`P_Y=6.37467\times10^{-5}\ \mathrm{V^2}`，
   算得 :math:`P_*/\min(P_X,P_Y)=1.14008`，超过上界。
   若从 C3 的实测功率中减去这个共同功率，就会要求一个负的额外功率。

   .. figure:: /_static/K_Diagnostics/k05-fit-kim.svg
      :width: 100%
      :alt: Kim 共同功率与较小实测功率之比，以及对应线性系数与最小二乘结果的比较。

      图 6．上图检查共同功率，下图比较由此得到的线性系数。

   先读上图：允许区间是 0–1，图中绿色显示它靠近上界的部分，超过 1 的空心圆表示失败。
   这次训练划分只有 92 个目标中的 8 个通过；四次合计 368 个中有 35 个通过。
   通过只是必要条件，还不能独立证明模型成立。
   下图保留 Kim 的代数解，使它与最小二乘的差别可见；
   空心圆 **不是已经验证的修正系数**。
   放电工况相同，不意味着两处底层波动功率相等，也不意味着噪声符合所需的不相关假设。

   .. _k05-kim-failure-zh:

   **对这里的大多数频点，在当前假设下，不能把 Kim 输出当作物理上可接受的噪声修正。**
   估计出的统计矩无法同时满足“共同底层功率＋两路非负额外功率”这一分解。
   这说明这套解释与当前数据及归一化不相容，不是说 Kim 方法对所有实验都无效。
   可能的原因包括两处底层波动功率本来就不同、通道响应不同，或被模型忽略的噪声混合矩并不为零；
   有限样本的不确定性也会影响估计。仅凭图 6 还不能确定哪种原因占主导，
   把比值强行截到 1 也不能修复这些假设。

   **若要评价当前实测信号的预测能力，应以 Joint LS 为基准，并结合图 7 的留出误差判断。**
   “Joint”指线性与二次系数一起拟合，不是 Kim 修正。
   Joint LS 不要求两支探针的底层功率相等，因此 Kim 上界失败并不会直接否定这个预测拟合。
   但输入噪声和通道响应仍可能使其系数有偏差，
   所以改看 Joint LS 曲线，也不能直接确认物理增长率或能量转移。

   .. rubric:: 5. 回到没有参加拟合的记录

   把三种拟合关系用于第 2 组 C1，再与同组实测 C3 比较。
   残差是 :math:`Y-\widehat Y`。上图用其模平方平均除以
   :math:`P_{Y,\mathrm{test}}`，对应 :k05:eq:`validation-nmse`，
   越小表示预测越接近；下图保留 V² 单位。

   .. figure:: /_static/K_Diagnostics/k05-fit-heldout.svg
      :width: 100%
      :alt: 仅线性、联合最小二乘和 Kim 代数解在留出记录上的归一化预测误差及残差功率。

      图 7．留出预测误差。深色曲线检验第 2 组，上图浅色曲线展示另外三组依次留出的结果。

   :math:`f_*` 处，仅线性模型的归一化误差为 **0.5737%**，
   联合最小二乘为 **0.5412%**，Kim 代数解为 **3.6268%**。
   LS 相对于线性残差改善了 5.67%，但相对于目标实测功率只下降了 0.0325 个百分点。
   两种说法的分母不同；这个改善比例也不是测得的非线性波能转移份额。

   对第 2 组，所保留频点的相对 LS 改善从 −0.17% 到 12.18%，频率中位数为 5.09%；
   四轮的中位数为 4.70%–5.09%。
   因而，二次输入在这个频带的大部分位置提供了幅度不大、可重复的预测改善，
   但不是每个频点都改善。Kim 的目标并非最小化留出误差；
   示例频点已经没有通过共同功率检查，不能赋予它所假定的平稳噪声解释。

   .. rubric:: 有了系数，下一步接什么？

   统计计算现在已经闭合：记录给出矩，明确的输入集合给出足够的方程，从而拟合出
   :math:`L,Q`。要进一步转成物理增长率和有符号转移，还需要测量响应、
   空间相位的解释和有依据的群速度。
   接着读 :ref:`探针实际测到了什么 <k05-response-zh>`，
   再进入 :ref:`文献图 2、图 3 的对照 <k05-comparison-zh>`。
   完整四轮验证、分段和频带敏感性，以及 5–20 MHz 示例保留在
   :ref:`验证补充页 <k05-validation-zh>`。

   .. raw:: html

      <details class="k05-note"><summary>复现计算与绘图</summary>

   脚本读取四组原始双通道记录，以及已保存的验证和 Kim 收支结果；
   核对输入哈希、频率网格和 LS 系数，重算训练矩，并独立重拟合固定频点的例子。
   完整频率网格直接复用已有结果，不因重绘而全部重新求解。

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_coefficient_walkthrough.py \
        --data /path/to/experiment-data \
        --validation /path/to/validation-results \
        --budget /path/to/transfer-budget-results \
        --output /path/to/new-coefficient-walkthrough

   输出必须选择新的空目录，内含七张 SVG/PNG、
   coefficient_walkthrough_arrays.npz 和 coefficient_walkthrough_summary.json。
   上游结果可分别用 validate_experiment.py、analyze_transfer_budget.py 生成；
   完整命令和依赖见
   :download:`EXPERIMENT.md <../../../../K_Diagnostics/K05_bispectral_transfer/EXPERIMENT.md>`。
   数组保存小矩阵、完整示例矩、系数和留出预测；
   清单记录哈希、训练／检验分组、单位和数值核查。

   :download:`计算脚本 <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_coefficient_walkthrough.py>`
   · :download:`绘图来源 <../../_static/K_Diagnostics/k05-fit-summary.json>`。
   在包含共享读取器和拟合函数的仓库中运行；打开网页不会执行 Python。

   .. raw:: html

      </details>

   .. rubric:: 参考文献

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_。
   原文模型及统计矩的对应关系见 :ref:`第 05 页模型对照 <k05-source-3-zh>`
   和 :ref:`统计矩对照 <k05-source-5-zh>`。

   [2] J. S. Kim, R. D. Durst, R. J. Fonck, E. Fernandez, A. Ware and P. W. Terry,
   “Technique for the experimental estimation of nonlinear energy transfer in
   fully developed turbulence,” *Physics of Plasmas* **3**, 3998–4009 (1996).
   `doi:10.1063/1.871572 <https://doi.org/10.1063/1.871572>`_。
