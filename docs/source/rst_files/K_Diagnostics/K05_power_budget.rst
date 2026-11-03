10 · Supplement: interpreting the growth and transfer plots
============================================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-budget-en:

   .. rubric:: Supplement: interpreting the growth and transfer plots

   The :ref:`preceding results page <k05-comparison-en>` displayed the
   counterparts of Figures 2 and 3 in [1]. The two estimators gave different
   apparent growth and transfer, and many Kim points carried open-circle flags.
   This supplement explains those results: first the common-power check,
   then the phase rotation, and finally the complete measured-power balance.
   It uses the same four captures and coefficients, so the checks can be
   read alongside the plotted results rather than before them.

   .. rubric:: 1. Use the same records, but ask a different question

   **The question is: can the common power inferred by Kim's method fit inside
   both measured powers?** This checks a necessary consequence of the method's
   assumptions [2], rather than prediction accuracy. Equal modelled powers are
   already imposed when solving for the coefficients; their equality is not
   an independent test of stationarity. Here we check whether that solution
   is consistent with the measured totals.

   At one frequency, let :math:`X` be the C1 Fourier coefficient and :math:`Y` the
   simultaneous C3 coefficient, both in volts. Frequency subscripts are omitted
   when only one target frequency is discussed. Brackets :math:`\langle\cdot\rangle`
   mean an average over segments; a star means complex conjugation.

   As on page 07, three whole captures fit the model and the fourth tests it.
   There are four splits, each with 14646 training and 4882 test segments.
   Use 2048-point segments, segment-mean removal, a periodic Hann window,
   no overlap, and the positive-exponent Fourier coefficient divided by 2048.
   The 92 target frequencies cover 0.537–4.980 MHz. Nonzero quadratic inputs
   have absolute frequency at most 5 MHz, including sum and difference pairs.
   Each swapped product is counted once.

   Least squares minimizes training prediction error. Kim's estimator instead
   adds a constraint: the part described by the model has the **same power at
   both positions**, denoted :math:`P_\star`. This is spatial statistical homogeneity
   of the modelled part, not equality of instantaneous waveforms. Unmodelled
   power may remain in either measurement.

   .. k05:equation:: budget-common-power
      :lang: en

      P_X=\langle|X|^2\rangle,\quad P_Y=\langle|Y|^2\rangle,\qquad 0\le P_\star\le\min(P_X,P_Y).


   All three powers have units V². They are mean squared Fourier coefficients,
   not electrical watts or total plasma energy. If unmodelled power is nonnegative
   and the assumed cross terms vanish, the common part cannot exceed either total.
   The inequality is therefore a **necessary consistency check**, not a proof of
   all Kim assumptions.

   .. figure:: /_static/K_Diagnostics/k05-budget-admissibility.svg
      :alt: Figure 1. Measured power ratio and inferred common-power bound. Lines use training moments; each line excludes a different whole capture.
      :width: 100%

      Figure 1. Measured power ratio and inferred common-power bound. Lines use training moments; each line excludes a different whole capture.

   **Upper panel: describe the measurements, without a pass band around 1.**
   The ratio :math:`P_Y/P_X` is 1 for equal total powers, above 1 when C3 has
   more power, and below 1 when C1 has more. Kim's assumption concerns the
   common modelled part, not these totals: the two probes may contain
   different unmodelled powers. Thus a departure from 1 alone does not fail
   this check. The blue band shows the four-split range, not an acceptance
   interval or a confidence interval.

   **Lower panel: apply the necessary bound.** For positive measured powers,
   :k05:eq:`budget-common-power` requires
   :math:`0\le P_\star/\min(P_X,P_Y)\le1`.
   A value above the dashed line at 1, in the red shaded area, fails:
   the inferred common part exceeds the smaller measured total.
   Values from 0 to 1 pass **this check only**; negative values would also
   be inadmissible. The displayed vertical range **0.90–1.32 is a zoom,
   not an acceptance interval**. A value near zero leaves little common
   modelled power and is not evidence that the coefficients are useful.

   For example, take :math:`P_X=1` and :math:`P_Y=1.4`, in V².
   A common power :math:`P_\star=0.8` V² passes: the upper ratio is 1.4,
   but the lower ratio is 0.8. A common power of 1.1 V² would fail because
   it exceeds :math:`P_X`. The **35 of 368** passing cases reported below
   refer to the lower-panel bound, not to proximity to 1 in the upper panel.


   Only **35 of 368 frequency–split cases** satisfy the bound with the present
   uncorrected voltage channels: 8, 9, 8 and 10 cases in the four splits.
   The inferred-to-smaller-measured-power ratio reaches **1.295**.
   At the fixed example frequency **2.001953 MHz**, it is about **1.140** in
   every split: a common part cannot account for 114% of a measured total under
   this model's assumptions.

   This does not identify which assumption fails. Unequal channel/probe response,
   real spatial changes, omitted dynamics, and the assumed nonideal cross moments
   are possible causes. Sampling error also matters near the boundary. The four
   curves are repeatability checks, not confidence intervals; the 10⁻⁶ numerical
   tolerance is not a statistical significance threshold. Passing the bound at
   a few frequencies does not validate the remaining physical assumptions.

   .. raw:: html

      <details class="k05-note"><summary>How the Kim calculation uses the measured moments</summary>

   Use the notation and solution in :k05:eq:`kim-stationary-moments` and
   :k05:eq:`kim-stationary-solution`. The full fourth-moment matrix retains
   correlations between all product columns; it is not replaced by a diagonal.
   The product design matrix is solved by SVD after scaling each product by its training RMS, then
   coefficient units are restored. The singular-value cutoff is 10⁻¹⁰.
   All 368 cases have full product-column rank; the maximum scaled design
   condition number is 10.76. Rank or conditioning therefore does not explain the
   power-bound violations in Figure 1.

   The extra assumption is stronger than “noise is uncorrelated between probes”:
   the relevant higher cross moments involving nonideal components must also
   vanish. The measured fourth moments still contain measured product fluctuations.
   The inferred common model power is not simply a denoised version of all data.
   Equal model powers are imposed in solving the equations; an apparent stationary
   balance in that solution is not an independent observation of saturation.
   No gain normalization is chosen to force the bound to pass.

   .. raw:: html

      </details>


   .. rubric:: 2. Separate a phase rotation from a change in amplitude

   Think of a complex Fourier coefficient as an arrow: its length represents
   amplitude, and its angle represents phase. Two probes can see the same
   amplitude at different phases. A change in angle therefore needs to be
   separated from a change in length before interpreting a coefficient.

   A travelling signal can rotate in the complex plane between probes without
   growing. Use the **training cross phase** as a reference:

   .. k05:equation:: budget-reference-phase
      :lang: en

      \delta=\arg\langle YX^*\rangle,\qquad \widetilde Y=e^{-i\delta}Y,\quad \widetilde L=e^{-i\delta}L,\quad \widetilde Q_j=e^{-i\delta}Q_j.


   :math:`\delta` is an angle in radians; :math:`i^2=-1`. A tilde means that the
   same rotation has been applied to the target and its model coefficients.
   :math:`L` is dimensionless and :math:`Q_j` has units V⁻¹. The integer
   :math:`j` labels a retained frequency pair. A pure rotation has
   :math:`L=e^{i\delta}` and hence :math:`\widetilde L=1`.

   .. figure:: /_static/K_Diagnostics/k05-budget-coefficients.svg
      :alt: Figure 2. Linear coefficient magnitude, training cross phase, and apparent amplitude increment after reference-phase removal. Bands show the four-split range, not confidence intervals.
      :width: 100%

      Figure 2. Linear coefficient magnitude, training cross phase, and apparent amplitude increment after reference-phase removal. Bands show the four-split range, not confidence intervals.

   **Read the three panels at the same frequency.** The common horizontal
   axis is :math:`f` in MHz; moving right selects a different frequency,
   not a later time or a position farther from C1.
   Blue means least squares; orange means the Kim algebraic solution.
   **Both estimate the linear coefficient inside a linear-plus-quadratic
   model.** These are not the “linear only” and “linear plus quadratic”
   predictions compared on page 07. Lines are four-split means; shaded bands
   span the four results and can be too narrow to distinguish.

   **Top: how much does the linear term multiply the input amplitude?**
   The vertical axis is :math:`|L|`, the length of the complex coefficient.
   Since :math:`|LX|=|L||X|`, a value 1 means unchanged amplitude for this
   term, 1.1 means a factor 1.1, and 0.9 means a factor 0.9.
   This is not the amplitude ratio of the complete measurements
   :math:`Y` and :math:`X`: the prediction also contains quadratic terms,
   and a residual remains. Thus :math:`|L|>1` alone does not establish
   physical wave growth.

   **Middle: which reference angle is removed?**
   The green curve is :math:`\delta=\arg\langle YX^*\rangle` from the training
   measurements, common to both estimation methods. The plot uses degrees;
   :k05:eq:`budget-reference-phase` uses radians.
   For example, :math:`\delta=-20^\circ` calls for a rotation by
   :math:`+20^\circ` when multiplying by :math:`e^{-i\delta}`.
   A negative phase is an angle, not a negative growth rate; its sign alone
   also does not identify propagation direction.

   **Bottom: after that rotation, how far is the linear coefficient's
   real part from 1?** The axis is
   :math:`g_{\mathrm{app}}=\operatorname{Re}\widetilde L-1`.
   Here :math:`\operatorname{Re}` takes the real part, the projection onto
   the real axis; “app” means apparent.
   The dotted zero line means :math:`\operatorname{Re}\widetilde L=1`.
   Values +0.1 and −0.1 mean real parts 1.1 and 0.9, respectively.
   This dimensionless increment refers to the linear term, not to the total
   measured power change or a growth rate in s⁻¹.
   An orange open circle flags a frequency where **at least one of the four
   splits failed Figure 1's common-power bound**. It is not an error bar
   or an extra measurement. Close agreement between splits indicates
   repeatability, not validity of the physical assumptions.

   .. raw:: html

      <details class="k05-note"><summary>Why does rotation preserve amplitude, yet the bottom panel need not equal the top minus 1?</summary>

   The rotating factor has unit magnitude:
   :math:`|e^{-i\delta}|=1`, so :math:`|\widetilde L|=|L|`.
   In a purely illustrative case, let
   :math:`L=e^{i\pi/3}` and :math:`\delta=\pi/3` (60°).
   Its amplitude factor is 1, although :math:`\operatorname{Re}L=1/2`.
   Rotation gives :math:`\widetilde L=e^{-i\pi/3}e^{i\pi/3}=1`,
   so :math:`g_{\mathrm{app}}=0`. Using
   :math:`\operatorname{Re}L-1=-1/2` before rotating would mistake an angle
   change for an amplitude decrease.

   More generally, write :math:`L=|L|e^{i\phi_L}`, where
   :math:`\phi_L=\arg L` is the fitted coefficient's phase.
   Then :math:`g_{\mathrm{app}}=|L|\cos(\phi_L-\delta)-1`.
   The top panel measures length; the bottom measures a projection minus 1.
   They reduce to :math:`g_{\mathrm{app}}=|L|-1` only when the coefficient
   aligns with the reference phase. In a joint linear-plus-quadratic fit,
   :math:`\arg L` need not equal the measured cross phase :math:`\delta`:
   the cross spectrum can also contain contributions from quadratic terms
   and the residual. The middle panel therefore supplies a reference
   rotation, not a guaranteed removal of every phase contribution.

   .. raw:: html

      </details>


   To read one actual point, take **2.001953 MHz**, with capture 2 held out.
   The middle-panel reference is about −19.26°.
   After rotation, least squares gives
   :math:`\operatorname{Re}\widetilde L=0.8727`, hence
   :math:`g_{\mathrm{app}}=-0.1273` in the bottom panel.
   Kim gives 1.0530, hence :math:`g_{\mathrm{app}}=+0.0530`.
   These are one split's values; the plotted lines average all four.
   The opposite signs show how the estimation assumptions change the inferred
   linear contribution. **The Kim bound already fails here. Neither sign
   establishes physical damping or growth.** Even a positive apparent
   increment does not include the quadratic contribution or the residual.

   The measured phase is defined modulo :math:`2\pi` and may also contain
   channel response and nonlinear correlations. Removing this reference
   phase does not measure a group velocity or resolve spatial aliasing.
   The next section puts the linear term, quadratic terms and residual
   together to check the complete measured power.

   .. rubric:: 3. Put every piece back into the measured power

   Apply each fitted model to the held-out capture. Call its linear contribution
   :math:`A`, its combined quadratic contribution :math:`B`, and the remaining
   complex difference :math:`r`:

   .. k05:equation:: budget-signal-parts
      :lang: en

      Y=A+B+r,\qquad A=LX,\qquad B=\sum_jQ_jZ_j,\qquad Z_j=X_{f_{1j}}X_{f_{2j}}.


   Here :math:`f_{1j}+f_{2j}=f`. The product :math:`Z_j` has units V²;
   :math:`A,B,r` have units V. This local :math:`A` means a predicted contribution,
   not the slowly varying wave envelope of page 01. Here :math:`r` denotes the
   residual, not a segment number. For negative input frequencies use conjugate
   coefficients, as on page 07.

   .. k05:equation:: budget-full-identity
      :lang: en

      \begin{aligned} P_Y&=P_A+C_{AB}+P_B+P_r+C_{pr},\\ P_A&=\langle|A|^2\rangle,\quad P_B=\langle|B|^2\rangle,\quad P_r=\langle|r|^2\rangle,\\ C_{AB}&=2\operatorname{Re}\langle A^*B\rangle,\quad C_{pr}=2\operatorname{Re}\langle(A+B)^*r\rangle.\end{aligned}


   The :math:`P` terms are nonnegative powers. The :math:`C` terms are signed
   cross contributions: they measure reinforcement or cancellation, not separate
   nonnegative stores of energy. Subscript :math:`p` in :math:`C_{pr}` refers to
   the prediction :math:`A+B`. All five terms have units V².

   .. figure:: /_static/K_Diagnostics/k05-budget-closure.svg
      :alt: Figure 3. Five held-out power contributions at the fixed 2 MHz example. Signed cross terms are retained; the final bars are the sums.
      :width: 100%

      Figure 3. Five held-out power contributions at the fixed 2 MHz example. Signed cross terms are retained; the final bars are the sums.


   For least squares the five normalized terms sum to 1, including the small
   residual. The Kim algebraic solution also sums to 1, but its residual cross
   contribution is **−0.356**, about −36% of measured target power.
   Omitting it would leave an apparent excess. A zero sum error here verifies
   the arithmetic identity; it does **not** prove that a physical model is correct.
   The Kim decomposition is shown even though the earlier necessary check fails.

   .. raw:: html

      <details class="k05-note"><summary>Expand the square: why the residual cross term matters</summary>

   Multiply :math:`(A+B+r)(A^*+B^*+r^*)`. The three squares give
   :math:`P_A,P_B,P_r`. The pair :math:`AB^*+A^*B` gives
   :math:`2\operatorname{Re}(A^*B)`; the remaining four terms give
   :math:`2\operatorname{Re}[(A+B)^*r]`. Average to obtain
   :k05:eq:`budget-full-identity`.

   A least-squares residual is orthogonal to the fitted columns on the training
   rows, up to numerical accuracy. This is not guaranteed on held-out data.
   Kim coefficients solve different moment equations, so even training residual
   orthogonality must not be assumed. Also, :math:`P_B` includes interference
   between different quadratic pairs; it is not generally
   :math:`\sum_j\langle|Q_jZ_j|^2\rangle`.

   .. raw:: html

      </details>


   .. rubric:: 4. Is the apparent linear change balanced by quadratic coupling?

   Subtract input power and normalize by the **held-out input power**:

   .. k05:equation:: budget-increment-identity
      :lang: en

      \frac{P_Y-P_X}{P_X}=2g_{\mathrm{app}}+t_{\mathrm{app}}+s_{\mathrm{step}}+e_r.


   The subscript “app” means apparent, before a physical interpretation is justified.
   :math:`g_{\mathrm{app}}` measures the real linear amplitude increment.
   :math:`t_{\mathrm{app}}` is the first-order quadratic cross contribution.
   :math:`s_{\mathrm{step}}` keeps the square of the complete predicted increment.
   :math:`e_r` contains both residual terms. These quantities are dimensionless.
   The factor 2 multiplying :math:`g_{\mathrm{app}}` comes from squaring an amplitude.

   .. figure:: /_static/K_Diagnostics/k05-budget-increments.svg
      :alt: Figure 4. Normalized measured power change and all contributions. Residual power and its cross term are grouped in e_r. Bands span the four splits.
      :width: 100%

      Figure 4. Normalized measured power change and all contributions. Residual power and its cross term are grouped in e_r. Bands span the four splits.


   Near 2 MHz, the Kim algebraic solution gives approximately
   :math:`2g_{\mathrm{app}}=0.106` and :math:`t_{\mathrm{app}}=-0.098`.
   Their near cancellation could look like linear drive balanced by nonlinear
   removal. But the measured normalized difference is about **−0.231**; the
   residual terms contribute about **−0.246**, and the finite-step square about
   **0.0066**. The two-term picture leaves out an essential part of this measurement.
   These are voltage-model power contributions, not measured plasma energy
   transfer rates or evidence of an inverse cascade.

   .. raw:: html

      <details class="k05-note"><summary>Calculate each normalized contribution</summary>

   Define the complex linear increment :math:`\ell`, rotated quadratic signal
   :math:`\widetilde B`, rotated residual :math:`\widetilde r`, and full predicted
   increment :math:`D`. Here :math:`D` is a signal increment, not a dispersion function:

   .. k05:equation:: budget-increment-parts
      :lang: en

      \begin{aligned} \ell&=\widetilde L-1,\quad \widetilde B=e^{-i\delta}B,\quad \widetilde r=e^{-i\delta}r,\quad D=\ell X+\widetilde B,\\ g_{\mathrm{app}}&=\operatorname{Re}\ell,\qquad t_{\mathrm{app}}=\frac{2\operatorname{Re}\langle X^*\widetilde B\rangle}{P_X},\\ s_{\mathrm{step}}&=\frac{\langle|D|^2\rangle}{P_X},\qquad e_r=\frac{\langle|\widetilde r|^2\rangle+2\operatorname{Re}\langle(X+D)^*\widetilde r\rangle}{P_X}.\end{aligned}


   Now :math:`\widetilde Y=X+D+\widetilde r`. Expand its squared magnitude,
   subtract :math:`P_X`, and divide by :math:`P_X` to obtain
   :k05:eq:`budget-increment-identity`. All quantities here use held-out averages;
   the coefficients and rotation come only from training.

   The small-step approximation drops :math:`s_{\mathrm{step}}` only when justified.
   It contains :math:`|\ell X|^2`, :math:`|\widetilde B|^2` and their cross term.
   The term :math:`t_{\mathrm{app}}` uses a full power derivative convention;
   its factor 2 must be tracked when comparing to the half-power transfer
   convention explained on :ref:`page 05 <k05-inference-en>`.
   Neither convention turns an uncalibrated voltage budget into plasma energy.

   .. raw:: html

      </details>


   .. rubric:: 5. What can be converted to a growth rate?

   Choose the coordinate from C1 to C3, so :math:`\Delta y=0.0037` m.
   Dividing an increment by this distance gives a spatial quantity. Only after
   the response, model and weak-step assumptions are justified can a group
   velocity connect it to a temporal amplitude growth rate:

   .. k05:equation:: budget-distance-conversion
      :lang: en

      \kappa_{\mathrm{app}}=\frac{g_{\mathrm{app}}}{\Delta y}\ [\mathrm{m}^{-1}],\qquad \gamma_{y,\mathrm{app}}\simeq v_g\kappa_{\mathrm{app}}\ [\mathrm{s}^{-1}].


   :math:`\kappa_{\mathrm{app}}` is an apparent amplitude increment per metre;
   :math:`v_g` is the signed group velocity in m/s, distinct from phase velocity.
   :math:`\gamma_{y,\mathrm{app}}` is a conditional azimuthal amplitude rate,
   not the full three-dimensional growth rate. The propagation direction and
   :math:`\Delta y/v_g` must be consistent with the propagation model.

   For the 2 MHz example, the two estimators give approximately **−34.4 and
   +14.3 m⁻¹**. These conflicting, uncalibrated values are a demonstration of the
   conversion, not accepted growth measurements. Multiplying by an assumed
   velocity would only rescale them. The 9.17 eV slope temperature from page 08
   does not independently determine :math:`v_g`.

   The preceding results page has already used an explicit kinetic scenario
   for the conditional conversion. To interpret those curves as physical rates,
   examine **relative channel/probe response and spatial homogeneity** and
   constrain the assumed dispersion and group velocity. The current records
   locate where the stationary interpretation fails its power check; choosing
   a speed does not repair that failure.

   .. raw:: html

      <details class="k05-note"><summary>Reproduce the calculation and inspect the saved coefficients</summary>

   From the repository root:

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_transfer_budget.py \
        --data /path/to/experimental_data \
        --metadata K_Diagnostics/K05_bispectral_transfer/experiment_z5p5_a3p7.json \
        --output /path/to/new_budget_output
      python K_Diagnostics/K05_bispectral_transfer/plot_transfer_budget.py \
        --output /path/to/new_budget_output

   The NPZ stores pair frequencies, training powers and moments, RMS scales,
   both sets of coefficients, ranks, conditioning, phase, bound flags and all
   held-out budget terms. The JSON records configuration and input/source hashes.
   The plot script reads the saved arrays without fitting again.
   Raw records and earlier analysis outputs are not overwritten.

   :download:`Numerical report </_static/K_Diagnostics/k05-budget-summary.json>`.

   .. raw:: html

      </details>


   .. rubric:: Continue the reading

   With the conditions separated from the plotted results, return to the original figures and read how the article connects growth, transfer and saturation.

   :ref:`Next page <k05-synthesis-en>`.

   .. rubric:: References

   [1] Z. A. Brown and B. A. Jorns (2023), “Growth and Saturation of the Electron
   Drift Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101, p. 115101-3. `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   [2] J. S. Kim et al. (1996), “Technique for the experimental estimation of
   nonlinear energy transfer in fully developed turbulence,” *Physics of Plasmas*
   **3**, 3998–4009, Secs. II–III.
   `doi:10.1063/1.871572 <https://doi.org/10.1063/1.871572>`_.

.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-budget-zh:

   .. rubric:: 补充：怎样解释增长与转移图

   :ref:`前一结果页 <k05-comparison-zh>` 已经画出文献 [1] 图 2、图 3 的对应结果。
   两种估计方法给出的表观增长和转移不同，许多 Kim 频点还标有空心圆。
   本补充页解释这些现象：先看共同功率检查，再展开相位旋转，
   最后把实测功率收支的全部项放回来。
   使用的仍是同四组记录和同一套系数，可以对照前页的曲线阅读这些检查。

   .. rubric:: 1．使用同一批记录，但换一个要检验的问题

   **这一节要检验：Kim 方法算出的共同功率，能否同时容纳在两路实测总功率之内？**
   检验的是该方法假设所要求的一个必要条件 [2]，而不是再次比较预测是否准确。
   两处模型功率相等，已经作为求解系数时的约束；解满足这个等式，
   不能算独立验证了平稳性（stationarity）。
   这里检查的是：这个解是否与实测总量相容。

   在一个目标频率处，把 C1 的 Fourier 系数记作 :math:`X`，
   同步的 C3 系数记作 :math:`Y`，两者单位均为 V。
   只讨论一个频率时省略频率下标。尖括号 :math:`\langle\cdot\rangle` 表示对分段取平均，
   星号表示复共轭（complex conjugate）。

   与第七页相同，每轮三整组拟合、一整组检验，共四轮。
   每轮有 14646 个训练分段和 4882 个测试分段。
   每段 2048 点，去段均值、加周期 Hann 窗、不重叠，
   采用正指数且除以 2048 的 Fourier 系数。
   92 个目标频率覆盖 0.537–4.980 MHz；二次输入保留绝对频率不超过 5 MHz
   的非零频点，含和频、差频，交换顺序的重复乘积只算一次。

   最小二乘（least squares）让训练预测误差尽量小。
   Kim 方法另加一个条件：模型描述的那部分波动在两位置具有
   **相同的平均功率**，记为 :math:`P_\star`。
   这是模型部分的空间统计均匀性（spatial statistical homogeneity），
   不是要求两条瞬时波形相同；两路测量都还可以有未被模型描述的功率。

   .. k05:equation:: budget-common-power
      :lang: zh

      P_X=\langle|X|^2\rangle,\quad P_Y=\langle|Y|^2\rangle,\qquad 0\le P_\star\le\min(P_X,P_Y).


   三个功率的单位都是 V²，是 Fourier 系数的平均模平方，
   不是电路的瓦特，也不是等离子体总能量。
   如果非模型部分功率非负，且假定的交叉项确实可忽略，
   共同部分就不能比任何一路的总量还大。
   所以这个不等式是 **必要的一致性检查**，通过它也不等于验证了全部 Kim 假设。

   .. figure:: /_static/K_Diagnostics/k05-budget-admissibility.svg
      :alt: 图 1．实测功率比与推断共同功率的上界检查。曲线采用训练集矩，每条线排除一整组不同的记录。
      :width: 100%

      图 1．实测功率比与推断共同功率的上界检查。曲线采用训练集矩，每条线排除一整组不同的记录。

   **上图：描述测量差别，不设“接近 1 才合格”的范围。**
   :math:`P_Y/P_X` 等于 1 表示两路总功率相同，大于 1 表示 C3 较大，
   小于 1 表示 C1 较大。Kim 假设要求相同的是模型描述的共同部分，
   两路未被模型描述的功率可以不同，因此总功率比偏离 1 本身不判为不合格。
   蓝色带是四轮结果的范围，既不是合格区间，也不是置信区间（confidence interval）。

   **下图：才是必要条件的判据。** 当两路实测功率均为正时，
   :k05:eq:`budget-common-power` 要求
   :math:`0\le P_\star/\min(P_X,P_Y)\le1`。
   高于虚线 1、进入红色阴影区，就不满足这个条件：
   推断的共同部分比两路中较小的总量还大。
   落在 0–1 内只表示 **通过这一项检查**；负值同样不允许。
   图中纵轴的 **0.90–1.32 只是放大显示范围，不是合格范围**。
   接近 0 时，共同模型功率很少，也不能因此认定系数有用。

   举例说，若 :math:`P_X=1`、:math:`P_Y=1.4`，单位均为 V²，
   取 :math:`P_\star=0.8` V² 就能通过：上图比值虽然为 1.4，
   下图比值却为 0.8。若共同功率算成 1.1 V²，则因超过 :math:`P_X` 而不能通过。
   下文的 **368 个案例中只有 35 个通过**，指的是下图的界限，
   不是上图是否接近 1。


   对当前尚未作响应校正的电压通道，368 个“频点 × 留出轮次”中，
   只有 **35 个** 满足上界；四轮分别为 8、9、8、10 个。
   模型功率与较小实测功率之比最高达到 **1.295**。
   固定示例频率 **2.001953 MHz** 处，四轮的比值都约为 **1.140**：
   在这套假设下，共同部分不能占一路实测总量的 114%。

   这还不能确定是哪一个假设出了问题。通道／探针响应不等、真实空间变化、
   遗漏的动力学，以及非模型部分的交叉矩不满足假设，都可能参与。
   靠近边界时还要考虑采样误差。四条曲线展示重复性，不是置信区间；
   判据中的 10⁻⁶ 仅为数值容差，不是统计显著性门槛。
   少数频点通过上界，也不能自动获得物理解释。

   .. raw:: html

      <details class="k05-note"><summary>Kim 具体怎样使用这些实测统计量？</summary>

   采用 :k05:eq:`kim-stationary-moments` 和 :k05:eq:`kim-stationary-solution` 的记号与解。
   第四阶矩矩阵保留所有二次乘积列之间的关联，不用对角近似。
   计算时仅按训练集 RMS 缩放乘积列，用奇异值分解（SVD）求解，
   最后还原系数单位，奇异值截断为 10⁻¹⁰。
   368 个情形的乘积列都满秩，缩放后设计矩阵最大条件数为 10.76。
   所以图 1 的上界违反不能归因于这里的秩不足或严重病态。

   所加假设比“两探针噪声不相关”更强：包含非模型部分的相关高阶交叉矩也须可忽略。
   测得的第四阶矩仍包含实际乘积列的全部波动。
   推断的共同模型功率不能简单理解成“所有数据去噪后的功率”。
   求解时已经强加两位置模型功率相等，因此解中出现平稳平衡，
   不能再当作饱和现象的独立实验证据。本页没有选取增益归一化来强行通过上界。

   .. raw:: html

      </details>


   .. rubric:: 2．先区分相位旋转与幅值变化

   可以把复 Fourier 系数想成一支箭头：长度表示幅值（amplitude），
   角度表示相位（phase）。两支探针看到的波即使幅值相同，相位也可能不同。
   因此，解释系数之前，要先分清箭头是“转了一个角度”，还是“长度变了”。

   信号传播到另一支探针时，即使不增长，其复系数也可能旋转。
   本页用 **训练集互谱相位** 作为参考：

   .. k05:equation:: budget-reference-phase
      :lang: zh

      \delta=\arg\langle YX^*\rangle,\qquad \widetilde Y=e^{-i\delta}Y,\quad \widetilde L=e^{-i\delta}L,\quad \widetilde Q_j=e^{-i\delta}Q_j.


   :math:`\delta` 是以弧度计的相位，:math:`i^2=-1`。
   波浪号表示目标和模型系数都转过同一个角度。
   :math:`L` 无量纲，:math:`Q_j` 的单位为 V⁻¹，
   :math:`j` 是保留波对的编号。若只是纯相位旋转，
   :math:`L=e^{i\delta}`，移相后便有 :math:`\widetilde L=1`。

   .. figure:: /_static/K_Diagnostics/k05-budget-coefficients.svg
      :alt: 图 2．线性系数幅值、训练互谱相位，以及移除参考相位后的表观幅值增量。色带为四轮范围，不是置信区间。
      :width: 100%

      图 2．线性系数幅值、训练互谱相位，以及移除参考相位后的表观幅值增量。色带为四轮范围，不是置信区间。

   **先在同一个频率处，从上往下读三个子图。**
   共用横轴是频率 :math:`f`，单位 MHz；向右走是换一个频率，
   不是时间推移，也不是离 C1 更远。
   蓝色表示最小二乘（least squares），橙色表示 Kim 代数解。
   **两者估计的都是“线性＋二次模型”中的线性系数**，
   不是第七页“仅线性”与“线性＋二次”两个预测模型的对比。
   实线是四轮结果的均值，色带覆盖四轮范围；范围很窄时，色带可能看不清。

   **上图：线性项把输入幅值乘了多少？**
   纵轴 :math:`|L|` 是复系数的模，也就是箭头长度。
   因为 :math:`|LX|=|L||X|`，所以 1 表示这个线性项保持输入幅值，
   1.1 表示乘以 1.1，0.9 表示乘以 0.9。
   它不是完整测量 :math:`Y` 与 :math:`X` 的幅值比：
   预测中还有二次项，预测之外还有残差。因此，单凭 :math:`|L|>1`
   不能认定物理波动正在增长。

   **中图：这次移相，准备扣掉哪个参考角度？**
   绿线是由训练记录算出的互谱相位 :math:`\delta=\arg\langle YX^*\rangle`，
   两种估计方法共用它。图中用角度，:k05:eq:`budget-reference-phase` 中用弧度。
   例如 :math:`\delta=-20^\circ` 时，乘以 :math:`e^{-i\delta}`
   就是向相反方向转 :math:`+20^\circ`。
   相位为负只是在说角度，不是负增长率；仅凭这个符号也不能确定传播方向。

   **下图：转过这个角度后，线性系数的实部离 1 还差多少？**
   纵轴是 :math:`g_{\mathrm{app}}=\operatorname{Re}\widetilde L-1`。
   :math:`\operatorname{Re}` 表示取实部，即箭头在实轴上的投影；
   app 表示表观量（apparent）。
   虚线 0 对应 :math:`\operatorname{Re}\widetilde L=1`；
   +0.1、−0.1 分别表示实部为 1.1、0.9。
   这个无量纲增量属于线性项，不是全部实测功率的变化比例，也不是单位为 s⁻¹ 的增长率。
   橙色空心圆表示该频率处 **四轮中至少一轮未通过图 1 的共同功率上界**，
   不是误差棒，也不是额外的测量点。四轮很接近只能说明结果可重复，
   不能证明物理假设成立。

   .. raw:: html

      <details class="k05-note"><summary>移相不改变幅值，为什么下图还不一定等于“上图减 1”？</summary>

   旋转因子的模为 1：:math:`|e^{-i\delta}|=1`，
   因而 :math:`|\widetilde L|=|L|`，箭头长度没有变化。
   用一组示意数字看：设 :math:`L=e^{i\pi/3}`、
   :math:`\delta=\pi/3`，即 60°。幅值乘数是 1，
   但未移相时 :math:`\operatorname{Re}L=1/2`。
   移相后 :math:`\widetilde L=e^{-i\pi/3}e^{i\pi/3}=1`，
   所以 :math:`g_{\mathrm{app}}=0`。
   若直接用未移相的 :math:`\operatorname{Re}L-1=-1/2`，
   就把角度变化误读成了幅值下降。

   一般地，写成 :math:`L=|L|e^{i\phi_L}`，
   其中 :math:`\phi_L=\arg L` 是拟合系数自己的相位，
   则 :math:`g_{\mathrm{app}}=|L|\cos(\phi_L-\delta)-1`。
   上图看长度，下图看投影再减 1；只有系数与参考相位对齐时，
   才有 :math:`g_{\mathrm{app}}=|L|-1`。
   联合拟合线性与二次项时，:math:`\arg L` 不必等于实测互谱相位
   :math:`\delta`：互谱还可能含有二次项和残差的贡献。
   所以中图提供的是统一的参考旋转，不保证消除了所有相位成分。

   .. raw:: html

      </details>


   具体读一个实测频点：**2.001953 MHz，第 2 组留出**。
   中图的参考相位约为 −19.26°。移相后，最小二乘得到
   :math:`\operatorname{Re}\widetilde L=0.8727`，
   所以下图是 :math:`g_{\mathrm{app}}=-0.1273`；
   Kim 得到 1.0530，所以下图是 :math:`g_{\mathrm{app}}=+0.0530`。
   这里列出的是一轮的数值，图中实线则是四轮均值。
   同一数据甚至得到相反符号，说明估计假设会改变推断出的线性贡献。
   但 **此处已未通过 Kim 上界检查，两种符号都不能据此确立物理阻尼或增长**。
   即使表观增量为正，也还没有把二次贡献和残差算进去。

   实测相位只在模 :math:`2\pi` 意义下确定，还可能含有通道响应和非线性关联。
   移除参考相位既没有测出群速度，也没有解决空间混叠（spatial aliasing）。
   下一节把线性项、二次项与残差放在一起，检查完整的实测功率收支。

   .. rubric:: 3．把每一部分放回实测功率中

   现在把拟合系数用到留出的记录上。线性预测部分记为 :math:`A`，
   所有二次项相加记为 :math:`B`，预测后仍剩下的复数差值记为 :math:`r`：

   .. k05:equation:: budget-signal-parts
      :lang: zh

      Y=A+B+r,\qquad A=LX,\qquad B=\sum_jQ_jZ_j,\qquad Z_j=X_{f_{1j}}X_{f_{2j}}.


   这里 :math:`f_{1j}+f_{2j}=f`，波对乘积 :math:`Z_j` 单位为 V²，
   :math:`A,B,r` 单位为 V。本页局部符号 :math:`A` 是预测贡献，
   不是第一页的慢变波包包络；这里 :math:`r` 是残差（residual），不是分段编号。
   负频率输入按第七页的方法用共轭系数取得。

   .. k05:equation:: budget-full-identity
      :lang: zh

      \begin{aligned} P_Y&=P_A+C_{AB}+P_B+P_r+C_{pr},\\ P_A&=\langle|A|^2\rangle,\quad P_B=\langle|B|^2\rangle,\quad P_r=\langle|r|^2\rangle,\\ C_{AB}&=2\operatorname{Re}\langle A^*B\rangle,\quad C_{pr}=2\operatorname{Re}\langle(A+B)^*r\rangle.\end{aligned}


   :math:`P` 项是非负功率；:math:`C` 项是可以正也可以负的交叉贡献，
   表示相互增强或抵消，不能视作各自独立的非负能量。
   :math:`C_{pr}` 中的 :math:`p` 指预测 :math:`A+B`。
   五项单位均为 V²。

   .. figure:: /_static/K_Diagnostics/k05-budget-closure.svg
      :alt: 图 3．固定约 2 MHz 示例的五种留出功率贡献。保留带符号的交叉项；最后两根柱为各自总和。
      :width: 100%

      图 3．固定约 2 MHz 示例的五种留出功率贡献。保留带符号的交叉项；最后两根柱为各自总和。


   最小二乘的五项相加为 1，其中包括小的残差贡献。
   Kim 代数解的五项也相加为 1，但预测—残差交叉项为 **−0.356**，
   相当于实测目标功率的约 −36%；漏掉它，就会出现表观功率过剩。
   这里收支相加一致，只说明代数恒等式算对了，
   **并不证明物理模型正确**。图中 Kim 分解保留展示，尽管它已未通过前面的必要检查。

   .. raw:: html

      <details class="k05-note"><summary>展开模平方：为什么不能漏掉残差交叉项？</summary>

   把 :math:`(A+B+r)(A^*+B^*+r^*)` 相乘。
   三个模平方给出 :math:`P_A,P_B,P_r`；
   :math:`AB^*+A^*B` 合成 :math:`2\operatorname{Re}(A^*B)`；
   剩余四项合成 :math:`2\operatorname{Re}[(A+B)^*r]`。
   最后对分段平均，就得到 :k05:eq:`budget-full-identity`。

   最小二乘残差在训练数据上与拟合列正交，仅有数值误差；
   留出数据上没有这个保证。Kim 求解的是另一组矩方程，
   连训练残差也不能直接假设正交。
   此外 :math:`P_B` 包括不同二次波对之间的交叉贡献，
   通常不等于 :math:`\sum_j\langle|Q_jZ_j|^2\rangle`。

   .. raw:: html

      </details>


   .. rubric:: 4．表观线性变化，真的被二次耦合平衡了吗？

   把输出功率减去输入功率，再除以 **留出组的输入功率**，得到：

   .. k05:equation:: budget-increment-identity
      :lang: zh

      \frac{P_Y-P_X}{P_X}=2g_{\mathrm{app}}+t_{\mathrm{app}}+s_{\mathrm{step}}+e_r.


   下标 app 表示表观量（apparent），其物理解释尚需条件支持。
   :math:`g_{\mathrm{app}}` 是线性幅值的实部增量；
   :math:`t_{\mathrm{app}}` 是一阶二次交叉贡献；
   :math:`s_{\mathrm{step}}` 保留完整预测增量的模平方；
   :math:`e_r` 包含两种残差项。这些量都无量纲。
   :math:`g_{\mathrm{app}}` 前的 2 来自幅值的平方。

   .. figure:: /_static/K_Diagnostics/k05-budget-increments.svg
      :alt: 图 4．归一化实测功率变化及各项贡献。残差功率及其交叉项合并为 e_r；色带覆盖四轮结果。
      :width: 100%

      图 4．归一化实测功率变化及各项贡献。残差功率及其交叉项合并为 e_r；色带覆盖四轮结果。


   约 2 MHz 处，Kim 代数解给出
   :math:`2g_{\mathrm{app}}=0.106`、:math:`t_{\mathrm{app}}=-0.098`，
   二者接近抵消，看起来很像“线性驱动被非线性移除平衡”。
   但实测归一化功率差约为 **−0.231**；
   残差两项合计约为 **−0.246**，有限步长平方项约为 **0.0066**。
   只保留前两项，就遗漏了这次测量中不可忽略的一部分。
   这些是电压模型的功率分解，不是已测定的等离子体能量转移率或逆级联证据。

   .. raw:: html

      <details class="k05-note"><summary>每个归一化贡献具体怎样算？</summary>

   先定义复数线性增量 :math:`\ell`、移相后的二次信号 :math:`\widetilde B`、
   移相残差 :math:`\widetilde r` 和完整预测增量 :math:`D`。
   这里 :math:`D` 是信号增量，不是色散函数：

   .. k05:equation:: budget-increment-parts
      :lang: zh

      \begin{aligned} \ell&=\widetilde L-1,\quad \widetilde B=e^{-i\delta}B,\quad \widetilde r=e^{-i\delta}r,\quad D=\ell X+\widetilde B,\\ g_{\mathrm{app}}&=\operatorname{Re}\ell,\qquad t_{\mathrm{app}}=\frac{2\operatorname{Re}\langle X^*\widetilde B\rangle}{P_X},\\ s_{\mathrm{step}}&=\frac{\langle|D|^2\rangle}{P_X},\qquad e_r=\frac{\langle|\widetilde r|^2\rangle+2\operatorname{Re}\langle(X+D)^*\widetilde r\rangle}{P_X}.\end{aligned}


   此时 :math:`\widetilde Y=X+D+\widetilde r`。
   展开模平方，减去 :math:`P_X`，再除以 :math:`P_X`，
   便得到 :k05:eq:`budget-increment-identity`。
   这里的平均都用留出组；系数和旋转角仅从训练组取得。

   小步长近似只有在足够小时才可略去 :math:`s_{\mathrm{step}}`。
   该项保留 :math:`|\ell X|^2`、:math:`|\widetilde B|^2` 及两者交叉项。
   :math:`t_{\mathrm{app}}` 采用完整功率导数约定；
   与 :ref:`第五页 <k05-inference-zh>` 解释的半功率转移约定比较时须核对因子 2。
   两种约定都不能把未标定电压功率自动变成等离子体能量。

   .. raw:: html

      </details>


   .. rubric:: 5．怎样才能接到增长率？

   把坐标正方向选为 C1 指向 C3，令 :math:`\Delta y=0.0037` m。
   增量除以间距可得到每单位距离的量。
   只有测量响应、模型和小步长近似都有依据时，才可以再用群速度换成时间幅值增长率：

   .. k05:equation:: budget-distance-conversion
      :lang: zh

      \kappa_{\mathrm{app}}=\frac{g_{\mathrm{app}}}{\Delta y}\ [\mathrm{m}^{-1}],\qquad \gamma_{y,\mathrm{app}}\simeq v_g\kappa_{\mathrm{app}}\ [\mathrm{s}^{-1}].


   :math:`\kappa_{\mathrm{app}}` 是每米的表观幅值增量；
   :math:`v_g` 是有方向的群速度（group velocity），单位 m/s，与相速度不同。
   :math:`\gamma_{y,\mathrm{app}}` 是有条件的方位幅值增长率，
   不是完整三维增长率。传播方向及 :math:`\Delta y/v_g` 的符号须与传播模型一致。

   约 2 MHz 的例子中，两种估计分别给出约 **−34.4 和 +14.3 m⁻¹**。
   这些相互矛盾、未标定的数值只是换算示范，不能作为已确认的增长测量。
   乘上一个假设群速度只会缩放它们。
   第八页的 9.17 eV 斜率温度不能独立给出 :math:`v_g`。

   前一结果页已经用明确的动力学参数情景完成了条件换算。
   如果要把那些曲线解释成物理增长与转移，还需检查
   **相对通道／探针响应及空间均匀性**，并约束假设的色散和群速度。
   现有记录已经指出平稳解释在哪些频段不满足功率检查；
   选择速度数值不能修复这个问题。

   .. raw:: html

      <details class="k05-note"><summary>复现计算与查看保存的系数</summary>

   在仓库根目录运行：

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_transfer_budget.py \
        --data /path/to/experimental_data \
        --metadata K_Diagnostics/K05_bispectral_transfer/experiment_z5p5_a3p7.json \
        --output /path/to/new_budget_output
      python K_Diagnostics/K05_bispectral_transfer/plot_transfer_budget.py \
        --output /path/to/new_budget_output

   NPZ 保存波对频率、训练功率与矩、RMS 缩放、两组系数、秩、
   条件数、相位、上界标志以及完整留出功率项。
   JSON 保存设置与输入／源码哈希。绘图脚本直接读取数组，不重新拟合；
   原始记录与之前的分析输出保持不变。

   :download:`数值报告 </_static/K_Diagnostics/k05-budget-summary.json>`。

   .. raw:: html

      </details>


   .. rubric:: 继续阅读

   把适用条件与图形结果分清后，再回到论文原图，阅读作者怎样连接增长、转移和饱和。

   :ref:`下一页面 <k05-synthesis-zh>`.

   .. rubric:: 参考文献

   [1] Z. A. Brown and B. A. Jorns (2023), “Growth and Saturation of the Electron
   Drift Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101, p. 115101-3. `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   [2] J. S. Kim et al. (1996), “Technique for the experimental estimation of
   nonlinear energy transfer in fully developed turbulence,” *Physics of Plasmas*
   **3**, 3998–4009, Secs. II–III.
   `doi:10.1063/1.871572 <https://doi.org/10.1063/1.871572>`_.

