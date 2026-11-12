08 · From fitted coefficients to growth and transfer
=====================================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-rates-en:

   .. rubric:: What do the fitted coefficients say about the change between probes?

   :ref:`Page 06 <k05-experiment-en>` turned records into Fourier statistics;
   :ref:`page 07 <k05-experiment-coefficients-en>` fitted the linear and quadratic
   coefficients. We now use those coefficients to explain a measured change in
   fluctuation power, then connect it to the growth and transfer plots in Brown
   and Jorns [1]. The central distinction is between **a change across 3.7 mm**,
   which we can calculate, and **a rate per second**, which also requires a
   propagation model.

   Keep the same example: captures 3, 4 and 5 fit the joint least-squares (LS)
   model; capture 2 supplies the test moments. Segments contain 2048 samples,
   with segment-mean removal, a periodic Hann window and the positive-exponent
   Fourier convention divided by 2048. The target band is 0.537–4.980 MHz;
   nonzero quadratic inputs have absolute frequency at most 5 MHz.
   The detailed example remains 2.001953125 MHz. We retain volts as the measured
   signal unit. A squared Fourier coefficient has units V², not joules.

   .. rubric:: 1. Separate a rotation from a change in amplitude

   The fitted model is :math:`\widehat Y_f=L_fX_f+\sum_jQ_{fj}Z_j`, where
   :math:`Z_j=X_{f_{1j}}X_{f_{2j}}` and :math:`f_{1j}+f_{2j}=f`.
   :math:`X_f,Y_f` are the C1 and C3 coefficients, :math:`j` labels a unique
   unordered input pair, and a hat denotes prediction. :math:`L_f` is dimensionless
   and :math:`Q_{fj}` has units V⁻¹. Both are fitted together on the training records.

   Take :math:`\delta_f=\arg\langle Y_fX_f^*\rangle_{\rm train}` as the reference
   angle, in radians. A star means conjugation; the brackets here average the
   training segments. Multiplying by :math:`e^{-i\delta_f}` removes this reference
   rotation, as explained in :k05:eq:`phase-aligned-transfer`. It does not calibrate
   the channel response or determine an unaliased wave number.

   .. figure:: /_static/K_Diagnostics/k05-rate-phase.svg
      :width: 100%
      :alt: The raw and rotated linear coefficient at the fixed example frequency, followed by the real and imaginary increments throughout the fitted band.

      Figure 1. Rotate the jointly fitted linear coefficient, then subtract one.
      The left panel uses the fixed 2 MHz example; the right uses the same training split.

   At the example frequency, :math:`L_f=0.82459-0.28586i` and
   :math:`\delta_f=-0.33609` rad. After rotation,
   :math:`\widetilde L_f=0.87273+0.00208i`. The arrow rotates without changing
   length. The reference value one means unchanged amplitude and phase for the
   linear part. Its difference from the rotated arrow is the increment
   :math:`\ell_f=\widetilde L_f-1`, not the total measured change: quadratic terms
   and the prediction residual remain.

   Write that distinction explicitly:

   .. k05:equation:: rates-rotated-model
      :lang: en

      \begin{aligned}
      \ell_f&=e^{-i\delta_f}L_f-1,\qquad
      N_f=\sum_j e^{-i\delta_f}Q_{fj}Z_j,\\
      H_f&=\ell_fX_f+N_f,\qquad
      R_f=e^{-i\delta_f}(Y_f-\widehat Y_f),\\
      e^{-i\delta_f}Y_f&=X_f+H_f+R_f .
      \end{aligned}

   Here :math:`i^2=-1`; :math:`N_f` is the rotated quadratic prediction,
   :math:`H_f` is the total modelled increment relative to :math:`X_f`, and
   :math:`R_f` is the rotated residual. These three quantities have units V.
   The final line is an exact identity for the fitted prediction and its residual;
   no small-change approximation has been used yet.

   .. rubric:: 2. Account for the measured power difference

   Squaring the last line produces more than a linear term and a quadratic term.
   Define the following dimensionless contributions, using **only held-out
   segments** for every average in this section:

   .. k05:equation:: rates-increment-defs
      :lang: en

      \begin{aligned}
      P_X&=\langle|X_f|^2\rangle_{\rm test},\qquad
      P_Y=\langle|Y_f|^2\rangle_{\rm test},\\
      g_f&=2\operatorname{Re}\ell_f,\qquad
      t_f=\frac{2\operatorname{Re}\langle X_f^*N_f\rangle_{\rm test}}{P_X},\\
      s_f&=\frac{\langle|H_f|^2\rangle_{\rm test}}{P_X},\qquad
      r_f=\frac{\langle|R_f|^2\rangle_{\rm test}}{P_X},\\
      c_f&=\frac{2\operatorname{Re}\langle(X_f+H_f)^*R_f\rangle_{\rm test}}{P_X}.
      \end{aligned}

   :math:`g_f` is the first-order linear contribution; :math:`t_f` is the
   first-order quadratic contribution. :math:`s_f` retains the square of the
   finite modelled increment, including its linear–quadratic cross term.
   :math:`r_f` is residual power; :math:`c_f` is the residual–prediction cross
   contribution and can be negative. None is a fraction of the number of waves.
   For :math:`P_X>0`, the complete measured balance is

   .. k05:equation:: rates-exact-balance
      :lang: en

      D_f\equiv\frac{P_Y-P_X}{P_X}=g_f+t_f+s_f+r_f+c_f.

   .. figure:: /_static/K_Diagnostics/k05-rate-balance.svg
      :width: 100%
      :alt: Five signed contributions sum to the held-out measured power difference; a frequency plot compares the first-order sum with the complete identity.

      Figure 2. All contributions use the same held-out C1 power as denominator.
      Values are percentages. The sum and measured bars should coincide; the
      first-order curve need not coincide with the full measured change.

   At 2.001953 MHz, C3 has **23.096% less Fourier-bin power** than C1.
   The first-order linear term contributes −25.454%, and the quadratic term
   +0.524%. The remaining terms are +1.583% (finite-step square), +0.416%
   (residual power) and −0.166% (residual cross term). They sum to −23.096%.
   Thus the quadratic term partly offsets the decrease in this example, while
   the finite-step correction is larger than that quadratic contribution.
   This is a measured-voltage balance; unequal channel responses can also affect it.

   The excellent prediction on page 07 and the decrease here describe different
   things: a model can accurately predict a second-probe signal whose power is
   lower. Equality of the five-term sum is an algebra check, not independent
   evidence that the model captures all physical mechanisms.

   .. raw:: html

      <details class="k05-note"><summary>Where do the five terms come from?</summary>

   Suppress the frequency label for one line and expand the modulus squared:

   .. k05:equation:: rates-expand-square
      :lang: en

      \begin{aligned}
      |X+H+R|^2&=|X|^2+2\operatorname{Re}(X^*H)+|H|^2
                   +|R|^2+2\operatorname{Re}[(X+H)^*R],\\
      \langle X^*H\rangle&=\ell P_X+\langle X^*N\rangle .
      \end{aligned}

   Average, subtract :math:`P_X`, then divide by :math:`P_X`.
   The rotation has unit magnitude, so it does not change :math:`P_Y`.
   On a held-out record the residual need not be orthogonal to the prediction;
   therefore :math:`c_f` must be retained. Also, :math:`s_f` contains
   :math:`\langle|N_f|^2\rangle/P_X`; retaining a signed cross term while dropping
   this square would not give the exact model-power balance.

   .. raw:: html

      </details>

   .. rubric:: 3. A large quadratic coefficient does not fix the transfer sign

   The map on page 07 shows :math:`|Q_{fj}|`. To calculate a signed contribution,
   we also need the complex third-order moment of the same input pair and target:

   .. k05:equation:: rates-pair-contribution
      :lang: en

      B_{fj}^{\rm test}=\langle Z_jX_f^*\rangle_{\rm test},\qquad
      t_{fj}=\frac{2\operatorname{Re}(e^{-i\delta_f}Q_{fj}B_{fj}^{\rm test})}{P_X},\qquad
      t_f=\sum_j t_{fj}.

   :math:`B_{fj}^{\rm test}` is a bispectral moment in V³, with the convention
   used on page 06. It is not the conjugated :math:`b_j` used in the matrix on
   page 05. :math:`t_{fj}` is one pair's contribution to :math:`t_f`.
   The real part depends on the phases of both :math:`Q` and :math:`B`, as well
   as their magnitudes. Here the coefficient and reference angle come from
   training; the bispectral moment and denominator come from the held-out capture.

   .. figure:: /_static/K_Diagnostics/k05-rate-pairs.svg
      :width: 90%
      :alt: Magnitudes of all 81 fitted pair coefficients at the fixed target, and the corresponding positive or negative held-out contributions.

      Figure 3. The same 81 pairs viewed as coefficient magnitudes (top) and
      signed contributions (bottom). The second input is always
      :math:`f_2=f-f_1`; no pair is selected by its apparent strength.

   Read the two panels vertically at the same :math:`f_1`. A tall coefficient
   does not necessarily make a large positive bar. Negative :math:`f_1` denotes
   the conjugate component of a real signal and gives a difference-frequency pair.
   The bars sum to +0.524% for this target. This explains the extra information
   needed to go from the type of plot in [1], Figure 3(a), to Figure 3(b).
   It does not by itself prove a donor-to-receiver energy pathway or an inverse cascade.

   .. rubric:: 4. Introduce a time scale, then plot conditional rates

   The changes above do not require a group velocity. To express them per second,
   introduce :math:`v_{g,y}(f)`, the group velocity along the probe separation,
   and :math:`\tau_f=\Delta y/v_{g,y}(f)`. Take :math:`\Delta y=0.0037` m
   from C1 to C3. The following scenario assumes propagation in that positive
   direction, so :math:`\tau_f>0`. The measured phase alone does not establish
   that direction or the group velocity.

   .. figure:: /_static/K_Diagnostics/k05-rate-conversion.svg
      :width: 100%
      :alt: An assumed frequency-dependent group velocity and conditional joint-LS amplitude and normalized half-power transfer rates with four-holdout ranges.

      Figure 4. Left: an estimated kinetic scenario supplies the time scale.
      Right: joint-LS rates calculated with it. Lines are four-holdout means;
      shading is their observed range, not a confidence interval.

   The scenario uses a slow-scan effective temperature of 9.1689 eV and reported
   magnetic components 39.48 and 80.34 G. It additionally assumes Xe⁺ ions,
   :math:`n_0=10^{17}` m⁻³, electron drift +100 km/s,
   :math:`k_\parallel\lambda_{De}=0.03`, and zero ion Doppler shift in a
   field-aligned slab. The density, drift, geometry and applicability to the fast
   records are **assumptions**. The resulting speed is about 0.32–2.49 km/s in
   this band. See :ref:`the dispersion calculation <k05-source-7-en>` for the
   model and :ref:`the probe-response supplement <k05-response-en>` for the
   temperature and measurement chain. No measured gain or phase-response correction
   has been applied.

   .. container:: k05-paper-match

      .. rubric:: Connect to reference [1], Eqs. (4) and (6)

      .. k05:equation:: rates-time-conversion
         :lang: en

         \begin{aligned}
         \tau_f&=\frac{\Delta y}{v_{g,y}(f)},\\
         \gamma_{y,\mathrm{app}}(f)&=\frac{\operatorname{Re}\ell_f}{\tau_f}
                                  =\frac{g_f}{2\tau_f},\\
         T_f^{(1/2)}&=\frac{1}{\tau_f}\operatorname{Re}
            \sum_j e^{-i\delta_f}Q_{fj}B_{fj}^{\rm test}
            =\frac{P_Xt_f}{2\tau_f}.
         \end{aligned}

      :math:`\gamma_{y,\mathrm{app}}` is an apparent **amplitude** growth rate in
      s⁻¹. :math:`T_f^{(1/2)}` has units V²/s; the superscript records the
      half-power convention, not a square root. Figure 4 divides it by
      :math:`P_X` so both plotted quantities have units s⁻¹.

      **Original notation — [1], Eq. (4):**

      .. k05:equation:: rates-paper-coefficients
         :lang: en

         \begin{aligned}
         L_f&=\left[\left(\frac{\gamma_{f(y)}}{v_{g(y)}}+ik_y\right)\Delta y
                +1-i\Delta\Theta_f\right]e^{i\Delta\Theta_f},\\
         Q_f^{1,2}&=e^{i\Delta\Theta_f}V_{1,2}^{Q}\Delta y/v_{g(y)} .
         \end{aligned}

      Our :math:`\delta_f` corresponds to :math:`\Delta\Theta_f`, and our
      :math:`v_{g,y}` to :math:`v_{g(y)}`. Take the real part **after removing
      the printed phase factor** to obtain the first rate above.
      :math:`k_y` is the real azimuthal wave number; :math:`V^Q_{1,2}` is the
      continuous quadratic coefficient. The subscript “app” records that our
      coefficients still describe measured voltages and assumed propagation.

      **Original notation — [1], Eq. (6):**

      .. k05:equation:: rates-paper-transfer
         :lang: en

         T_f=(v_{g(y)}/\Delta y)\operatorname{Re}\left[
          \sum_{f=f_1+f_2}e^{-i\Delta\Theta_f}Q_f^{1,2}X_{f_1}X_{f_2}X_f^*\right].

      Replace its triple product by the measured ensemble moment
      :math:`B_{fj}^{\rm test}`. The label :math:`j` groups identical swapped
      products; use the matching grouped :math:`Q_{fj}` and count each once.
      Our :math:`T_f^{(1/2)}` corresponds to the printed :math:`T_f` expression.
      For the explicitly defined mean square :math:`P_X=\langle|X_f|^2\rangle`,
      the full first-order nonlinear power rate is :math:`2T_f^{(1/2)}`.
      This keeps the factor of two explicit rather than treating amplitude
      growth, mean-square growth and the article's transfer label as identical.

   For capture 2 at the example frequency, :math:`v_{g,y}=2148` m/s gives
   :math:`\tau_f=1.72` μs, :math:`\gamma_{y,\mathrm{app}}=-7.39\times10^4` s⁻¹,
   and :math:`T_f^{(1/2)}=0.1231` V²/s. Dividing the latter by
   :math:`P_X=8.0928\times10^{-5}` V² gives :math:`1.52\times10^3` s⁻¹.
   Positive transfer partly offsets the negative linear contribution; it does
   not balance it in this example.

   The exact finite-step check in these same units is

   .. k05:equation:: rates-rate-balance
      :lang: en

      \frac{D_f}{\tau_f}
      =2\gamma_{y,\mathrm{app}}+\frac{2T_f^{(1/2)}}{P_X}
       +\frac{s_f+r_f+c_f}{\tau_f}.

   Calling the first two terms continuous physical rates requires the local
   small-step approximation and an adequate wave/response model. The non-negligible
   :math:`s_f` in Figure 2 is a reason to examine that approximation, particularly
   for the much smaller quadratic effect. Varying the assumed speed rescales
   the converted rates without improving the original fit.

   .. rubric:: 5. What can now be compared with the paper?

   The calculation chain is complete for the **retained measured-voltage model**:
   records → moments → jointly fitted coefficients → signed contributions →
   conditional rates. Its physical interpretation is still conditional.
   Most frequencies failed the Kim common-power bound on page 07; we therefore
   use joint LS here as a prediction model, not as an automatically noise-corrected
   replacement for Kim. Passing a prediction test alone does not remove input
   noise or establish EDI growth.

   .. list-table::
      :header-rows: 1
      :widths: 25 40 35

      * - Panel in [1]
        - Corresponding calculation
        - What to compare
      * - Figure 2(a): dispersion
        - Assumed branch and its slope; see the linked dispersion supplement.
        - The model and frequency convention before comparing slopes.
      * - Figure 2(b): spectra
        - :ref:`Page 06 <k05-experiment-en>`, from the same Fourier convention.
        - Spectral features; absolute levels require matching physical normalization.
      * - Figure 2(c): growth
        - Figure 4 and the phase-removed linear coefficient.
        - Sign and structure within the fitted band, with the velocity assumption visible.
      * - Figure 3(a): coefficient map
        - :ref:`Page 07 <k05-experiment-coefficients-en>`; Figure 3 here explains one target.
        - The same pair convention and coefficient units.
      * - Figure 3(b): signed transfer
        - Multiply each Q by its complex bispectral moment, rotate, sum and convert.
        - Signed contribution, not coefficient magnitude or bicoherence alone.

   The :ref:`full comparison panels <k05-comparison-en>` retain the reference's
   plot ranges and show uncovered frequencies as blank. They also display the
   theoretical branch and flagged Kim algebraic results separately. The
   :ref:`reading supplement <k05-synthesis-en>` uses independently constructed
   schematics to explain the article's interpretation; those diagrams contain
   neither paper measurements nor C1/C3 measurements.
   For a physical conclusion, the remaining inputs are the channel/probe response,
   a supported propagation direction and dispersion branch, and a justified
   conversion from the measured proxy to the wave quantity of interest.

   .. raw:: html

      <details class="k05-note"><summary>Reproduce the numbers and figures</summary>

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_rate_walkthrough.py \
        --data /path/to/raw-captures \
        --budget /path/to/z5p5_a3p7_transfer_budget \
        --comparison /path/to/z5p5_a3p7_paper_comparison \
        --validation /path/to/z5p5_a3p7_validation \
        --output /path/to/new-rate-output

   The script verifies the eight raw hashes, regenerates the segment coefficients,
   and uses the existing training-only L/Q and phase. It recomputes held-out
   bispectral moments for all four splits and all 92 targets, checks both power
   identities against the parent arrays, and saves arrays, configuration, hashes,
   SVG and PNG figures. No coefficient is refitted to improve these results.

   .. raw:: html

      </details>

   .. rubric:: Reference

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-rates-zh:

   .. rubric:: 拟合出的系数，怎样解释两支探针之间的变化？

   :ref:`第06页 <k05-experiment-zh>` 从记录算出 Fourier 统计量，
   :ref:`第07页 <k05-experiment-coefficients-zh>` 得到了线性与二次系数。
   本页用这些系数解释实测波动功率的变化，再连接 Brown 与 Jorns [1] 的增长和转移图。
   先分清两件事：**跨过3.7 mm后改变了多少**，可以从当前数据计算；
   **每秒改变多少**，还需要传播模型给出时间尺度。

   继续同一个例子：第3、4、5组用于联合最小二乘（joint least squares，LS）拟合，
   第2组作为留出记录（held-out record）计算检验统计量。每段2048点、去段均值、
   周期 Hann 窗、正指数 Fourier 系数除以2048。目标频带为0.537–4.980 MHz，
   二次输入保留绝对频率不超过5 MHz的非零频点。细节例子固定在2.001953125 MHz。
   信号仍以伏特表示；Fourier 系数的模平方单位是V²，不是焦耳。

   .. rubric:: 1．先把相位旋转与幅值变化分开

   拟合模型为 :math:`\widehat Y_f=L_fX_f+\sum_jQ_{fj}Z_j`，其中
   :math:`Z_j=X_{f_{1j}}X_{f_{2j}}`，且 :math:`f_{1j}+f_{2j}=f`。
   :math:`X_f,Y_f` 分别是C1、C3的复系数；:math:`j` 标记一个不重复的输入波对；
   帽号表示预测。:math:`L_f` 无量纲，:math:`Q_{fj}` 的单位为V⁻¹，二者在训练记录上一起拟合。

   由训练互谱取参考角 :math:`\delta_f=\arg\langle Y_fX_f^*\rangle_{\rm train}`，
   单位为弧度。星号表示复共轭，尖括号在这里表示训练段平均。
   乘 :math:`e^{-i\delta_f}` 消去这个参考旋转，正是 :k05:eq:`phase-aligned-transfer` 的操作。
   这一步本身不校准通道响应，也不确定没有空间混叠的波数。

   .. figure:: /_static/K_Diagnostics/k05-rate-phase.svg
      :width: 100%
      :alt: 固定频点的原始和去相位线性系数，以及整个拟合频带内的实部和虚部增量。

      图1．先旋转联合拟合的线性系数，再减去1。左图为固定2 MHz例子，右图使用同一训练分组。

   在示例频点，:math:`L_f=0.82459-0.28586i`，:math:`\delta_f=-0.33609` rad。
   旋转后 :math:`\widetilde L_f=0.87273+0.00208i`。箭头方向变了，长度没有变。
   参考值1表示线性部分既不改幅值，也不改相位。
   旋转后系数与1的差记作 :math:`\ell_f=\widetilde L_f-1`。
   它还不是信号的总变化，因为二次部分和预测残差仍然存在。

   把这几部分明确写出来：

   .. k05:equation:: rates-rotated-model
      :lang: zh

      \begin{aligned}
      \ell_f&=e^{-i\delta_f}L_f-1,\qquad
      N_f=\sum_j e^{-i\delta_f}Q_{fj}Z_j,\\
      H_f&=\ell_fX_f+N_f,\qquad
      R_f=e^{-i\delta_f}(Y_f-\widehat Y_f),\\
      e^{-i\delta_f}Y_f&=X_f+H_f+R_f .
      \end{aligned}

   :math:`i^2=-1`；:math:`N_f` 是旋转后的二次预测，
   :math:`H_f` 是模型相对 :math:`X_f` 给出的总增量，
   :math:`R_f` 是旋转后的残差。这三个量的单位都是V。
   最后一行是预测加残差构成的精确恒等式，目前还没有使用“小变化”的近似。

   .. rubric:: 2．把实测功率差完整算出来

   将最后一行取模平方，会得到比线性项和二次项更多的贡献。
   本节所有尖括号都只对 **留出组的分段** 求平均，定义以下无量纲量：

   .. k05:equation:: rates-increment-defs
      :lang: zh

      \begin{aligned}
      P_X&=\langle|X_f|^2\rangle_{\rm test},\qquad
      P_Y=\langle|Y_f|^2\rangle_{\rm test},\\
      g_f&=2\operatorname{Re}\ell_f,\qquad
      t_f=\frac{2\operatorname{Re}\langle X_f^*N_f\rangle_{\rm test}}{P_X},\\
      s_f&=\frac{\langle|H_f|^2\rangle_{\rm test}}{P_X},\qquad
      r_f=\frac{\langle|R_f|^2\rangle_{\rm test}}{P_X},\\
      c_f&=\frac{2\operatorname{Re}\langle(X_f+H_f)^*R_f\rangle_{\rm test}}{P_X}.
      \end{aligned}

   :math:`g_f` 是一阶线性贡献，:math:`t_f` 是一阶二次贡献。
   :math:`s_f` 保留有限模型增量的平方，其中也包含线性与二次部分的交叉项。
   :math:`r_f` 是残差功率；:math:`c_f` 是残差与预测的交叉贡献，可以为负。
   它们都不是“多少个波所占的比例”。当 :math:`P_X>0` 时，完整实测收支为

   .. k05:equation:: rates-exact-balance
      :lang: zh

      D_f\equiv\frac{P_Y-P_X}{P_X}=g_f+t_f+s_f+r_f+c_f.

   .. figure:: /_static/K_Diagnostics/k05-rate-balance.svg
      :width: 100%
      :alt: 五个有符号贡献相加等于留出组的实测功率差，并比较一阶近似与完整收支的频率曲线。

      图2．所有贡献统一除以留出组C1的功率，以百分比表示。
      “Sum”与实测柱应重合；只保留一阶项的曲线不一定与实测变化重合。

   在2.001953 MHz，C3的频点功率比C1 **低23.096%**。
   一阶线性项为−25.454%，二次项为+0.524%；其余依次为+1.583%（有限步长平方项）、
   +0.416%（残差功率）和−0.166%（残差交叉项）。相加就是−23.096%。
   这个例子的二次贡献部分抵消了下降，但有限步长修正比二次贡献本身还大。
   这是测量电压的收支，通道响应不同也可能影响这些数值。

   第07页“预测很好”和这里“功率下降”说的是两件事：模型可以准确预测一个功率较小的第二探针信号。
   五项相加能对上，是代数核对；不能单凭这一点证明模型已包含全部物理机制。

   .. raw:: html

      <details class="k05-note"><summary>这五项怎样展开得到？</summary>

   暂时省去频率下标，把模平方展开：

   .. k05:equation:: rates-expand-square
      :lang: zh

      \begin{aligned}
      |X+H+R|^2&=|X|^2+2\operatorname{Re}(X^*H)+|H|^2
                   +|R|^2+2\operatorname{Re}[(X+H)^*R],\\
      \langle X^*H\rangle&=\ell P_X+\langle X^*N\rangle .
      \end{aligned}

   求平均、减去 :math:`P_X`、再除以 :math:`P_X`，就得到上式。
   旋转因子的模为1，所以不改变 :math:`P_Y`。
   留出组的残差不一定与预测正交，不能自动令 :math:`c_f=0`。
   而且 :math:`s_f` 包含 :math:`\langle|N_f|^2\rangle/P_X`；
   只保留有符号交叉项却删掉这个平方项，就不再是完整的模型功率收支。

   .. raw:: html

      </details>

   .. rubric:: 3．二次系数很大，不代表转移一定为正

   第07页的图显示 :math:`|Q_{fj}|`。要算一个有符号的贡献，还要用同一输入波对与目标频点的复三阶矩：

   .. k05:equation:: rates-pair-contribution
      :lang: zh

      B_{fj}^{\rm test}=\langle Z_jX_f^*\rangle_{\rm test},\qquad
      t_{fj}=\frac{2\operatorname{Re}(e^{-i\delta_f}Q_{fj}B_{fj}^{\rm test})}{P_X},\qquad
      t_f=\sum_j t_{fj}.

   :math:`B_{fj}^{\rm test}` 是单位为V³的双谱矩（bispectral moment），约定与第06页一致；
   它不是第05页矩阵里已经取过共轭的 :math:`b_j`。
   :math:`t_{fj}` 是单个波对对 :math:`t_f` 的贡献。
   乘积的实部同时取决于 :math:`Q` 和 :math:`B` 的相位与幅值。
   这里系数、参考角来自训练组，双谱矩、归一化功率来自留出组，没有用测试数据重新拟合系数。

   .. figure:: /_static/K_Diagnostics/k05-rate-pairs.svg
      :width: 90%
      :alt: 固定目标频率下81个波对的系数幅值，以及它们在留出组中的正负贡献。

      图3．同样的81个波对，上图看系数幅值，下图看有符号贡献。
      第二个输入始终为 :math:`f_2=f-f_1`，没有按强弱挑选波对。

   沿同一个 :math:`f_1` 上下对照：高的系数不一定对应大的正柱。
   负的 :math:`f_1` 是实信号的共轭分量，与正频率配成差频。
   这些柱相加，在该目标频点给出+0.524%。
   这就说明从文献[1]图3(a)的系数幅值走到图3(b)的有符号转移，还需要什么信息。
   单凭这些柱，仍不能证明确定的供能—受能路径或逆级联（inverse cascade）。

   .. rubric:: 4．引入时间尺度，才能得到条件性的变化率

   前面的变化量不需要群速度。要改写成“每秒”，引入沿探针间距方向的群速度
   :math:`v_{g,y}(f)` 和 :math:`\tau_f=\Delta y/v_{g,y}(f)`。
   取C1到C3为正方向，:math:`\Delta y=0.0037` m。
   下面的情景假定波沿这一正方向传播，所以 :math:`\tau_f>0`。
   测得的相位本身不能独立确定这个方向或群速度。

   .. figure:: /_static/K_Diagnostics/k05-rate-conversion.svg
      :width: 100%
      :alt: 估计动理学情景提供随频率变化的群速度，再给出联合最小二乘的条件幅值增长率与归一化半功率转移率。

      图4．左图的估计动理学情景提供时间尺度，右图使用它换算联合LS结果。
      实线为四轮留出计算的平均，阴影为四轮的实际范围，不是置信区间。

   该情景使用慢扫描得到的有效温度9.1689 eV、实验报告的磁场分量39.48和80.34 G；
   另假设Xe⁺离子、:math:`n_0=10^{17}` m⁻³、电子漂移+100 km/s、
   :math:`k_\parallel\lambda_{De}=0.03`，在沿磁场定义坐标的平板模型中忽略离子多普勒项。
   密度、漂移、几何以及慢扫描温度是否代表高频记录，均属于 **假设**。
   在本频带得到约0.32–2.49 km/s。模型和求导方法见 :ref:`色散计算 <k05-source-7-zh>`，
   温度和测量链见 :ref:`探针响应补充页 <k05-response-zh>`。
   当前没有施加实测的通道增益或相位响应校正。

   .. container:: k05-paper-match

      .. rubric:: 对照文献[1]式(4)、式(6)

      .. k05:equation:: rates-time-conversion
         :lang: zh

         \begin{aligned}
         \tau_f&=\frac{\Delta y}{v_{g,y}(f)},\\
         \gamma_{y,\mathrm{app}}(f)&=\frac{\operatorname{Re}\ell_f}{\tau_f}
                                  =\frac{g_f}{2\tau_f},\\
         T_f^{(1/2)}&=\frac{1}{\tau_f}\operatorname{Re}
            \sum_j e^{-i\delta_f}Q_{fj}B_{fj}^{\rm test}
            =\frac{P_Xt_f}{2\tau_f}.
         \end{aligned}

      :math:`\gamma_{y,\mathrm{app}}` 是表观 **幅值增长率**，单位为s⁻¹。
      :math:`T_f^{(1/2)}` 的单位为V²/s，上标表示半功率约定，不是开平方。
      图4将它除以 :math:`P_X`，让两条曲线都使用s⁻¹。

      **原文符号——[1]式(4)：**

      .. k05:equation:: rates-paper-coefficients
         :lang: zh

         \begin{aligned}
         L_f&=\left[\left(\frac{\gamma_{f(y)}}{v_{g(y)}}+ik_y\right)\Delta y
                +1-i\Delta\Theta_f\right]e^{i\Delta\Theta_f},\\
         Q_f^{1,2}&=e^{i\Delta\Theta_f}V_{1,2}^{Q}\Delta y/v_{g(y)} .
         \end{aligned}

      本页 :math:`\delta_f` 对应 :math:`\Delta\Theta_f`，
      :math:`v_{g,y}` 对应 :math:`v_{g(y)}`。
      **先消去原式中的相位因子，再取实部**，便得到上面的增长率。
      :math:`k_y` 是实数周向波数，:math:`V^Q_{1,2}` 是连续二次耦合系数。
      下标“app”提醒读者：当前系数描述测量电压，传播条件又有假设。

      **原文符号——[1]式(6)：**

      .. k05:equation:: rates-paper-transfer
         :lang: zh

         T_f=(v_{g(y)}/\Delta y)\operatorname{Re}\left[
          \sum_{f=f_1+f_2}e^{-i\Delta\Theta_f}Q_f^{1,2}X_{f_1}X_{f_2}X_f^*\right].

      将原式的三系数乘积换成实测系综矩 :math:`B_{fj}^{\rm test}`。
      本页用 :math:`j` 将交换顺序后相同的乘积归组，使用配套的归组系数 :math:`Q_{fj}`，只计一次。
      :math:`T_f^{(1/2)}` 对应原文写出的 :math:`T_f` 表达式。
      对明确定义的模平方 :math:`P_X=\langle|X_f|^2\rangle`，
      完整的一阶非线性功率变化率是 :math:`2T_f^{(1/2)}`。
      这样把因子2写清楚，不将幅值增长、模平方增长和文献的转移记号混为一谈。

   对第2组示例频点，:math:`v_{g,y}=2148` m/s给出 :math:`\tau_f=1.72` μs，
   :math:`\gamma_{y,\mathrm{app}}=-7.39\times10^4` s⁻¹，
   :math:`T_f^{(1/2)}=0.1231` V²/s。
   后者除以 :math:`P_X=8.0928\times10^{-5}` V²得到 :math:`1.52\times10^3` s⁻¹。
   正转移部分抵消负的线性贡献，但在这个例子里两者没有平衡。

   用相同单位核查完整有限步长收支：

   .. k05:equation:: rates-rate-balance
      :lang: zh

      \frac{D_f}{\tau_f}
      =2\gamma_{y,\mathrm{app}}+\frac{2T_f^{(1/2)}}{P_X}
       +\frac{s_f+r_f+c_f}{\tau_f}.

   将前两项解释为连续物理变化率，还需要局部小步长近似以及适合的波动、测量响应模型。
   图2里不可忽略的 :math:`s_f` 提醒我们检查这个近似，尤其是相对小得多的二次效应。
   改变假设群速度只会重缩放这些变化率，不会让原始预测变得更准确。

   .. rubric:: 5．现在能与文献对比到哪一步？

   对 **当前保留频带内的测量电压模型**，计算链已经闭合：
   记录 → 统计矩 → 联合拟合系数 → 有符号贡献 → 条件变化率。
   物理解释仍带有条件。第07页多数频点没有通过Kim共同功率上界，
   因此本页将联合LS作为预测模型，并没有把它当成自动消除噪声偏差的Kim替代品。
   通过预测检验本身不能去掉输入噪声，也不能直接确认EDI增长。

   .. list-table::
      :header-rows: 1
      :widths: 25 40 35

      * - 文献[1]的面板
        - 对应计算
        - 怎样比较
      * - 图2(a)：色散
        - 假设分支及其斜率，详见链接的色散补充。
        - 先核对模型和频率约定，再比较斜率。
      * - 图2(b)：频谱
        - :ref:`第06页 <k05-experiment-zh>`，使用一致的Fourier约定。
        - 比较谱形；比较绝对高度还需统一物理归一化。
      * - 图2(c)：增长
        - 本页图4，由去相位的线性系数换算。
        - 比较拟合频带内的符号与结构，同时保留群速度假设。
      * - 图3(a)：系数图
        - :ref:`第07页 <k05-experiment-coefficients-zh>`；本页图3展开一个目标频点。
        - 先统一波对计数方式与系数单位。
      * - 图3(b)：有符号转移
        - 每个Q乘复双谱矩，旋转、求实部、求和、换算。
        - 比较有符号贡献，不能用系数幅值或双相干代替。

   :ref:`完整对照面板 <k05-comparison-zh>` 保留了文献图框量程，未覆盖的频率留白，
   并把理论分支、带失败标记的Kim代数结果分别显示。
   :ref:`论文解读补充页 <k05-synthesis-zh>` 使用独立绘制的示意图解释原文的论证，
   示意图既不是原文测量，也不是C1/C3实验数据。
   若要形成物理结论，还需要通道／探针响应、有依据的传播方向和色散分支，
   以及从测量代理量到所研究波动量的可靠转换。

   .. raw:: html

      <details class="k05-note"><summary>复现数值与图片</summary>

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_rate_walkthrough.py \
        --data /path/to/raw-captures \
        --budget /path/to/z5p5_a3p7_transfer_budget \
        --comparison /path/to/z5p5_a3p7_paper_comparison \
        --validation /path/to/z5p5_a3p7_validation \
        --output /path/to/new-rate-output

   脚本核对八份原始文件的哈希，重新生成分段系数，使用此前仅从训练组得到的L/Q和参考相位。
   四轮、全部92个目标频点的留出双谱矩都重新计算，并将两种功率恒等式与上游数组核对。
   输出数组、配置、哈希及SVG／PNG图，不为改善当前结果而重新拟合系数。

   .. raw:: html

      </details>

   .. rubric:: 参考文献

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_。

