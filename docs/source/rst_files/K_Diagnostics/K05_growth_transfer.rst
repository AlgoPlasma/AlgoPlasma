08 · Comparing growth and transfer with the reference
==========================================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-rates-en:

   .. rubric:: From fitted coefficients to the five comparison panels

   :ref:`Page 06 <k05-experiment-en>` obtained the measured statistics, and
   :ref:`page 07 <k05-experiment-coefficients-en>` estimated the linear and quadratic
   coefficients. Here we calculate the counterparts of Figures 2 and 3 in Brown and
   Jorns [1], in the same panel order. Each comparison separates **what the paper
   reports**, **what our voltage records give**, and **what requires a physical assumption**.

   The reference curves below are **approximate redraws from points read off the
   published graphics**, with new colors and line styles. The coefficient map is
   an image-derived approximation. Neither is the authors' raw data, an independent
   simulation, or a new measurement. The original figure images are not displayed.
   The redraws support qualitative reading; small features and exact values are
   limited by image resolution.

   .. rubric:: 1. Prepare one consistent calculation, including 5–20 MHz

   C1 and C3 are separated by :math:`\Delta y=3.7` mm. We use the same four synchronized
   records and preprocessing as page 06: 2048 samples per nonoverlapping segment,
   segment-mean removal, a periodic Hann window, and Fourier coefficients with
   positive exponent divided by 2048. The sample rate is 100 MHz.
   The native frequency spacing is 48.828125 kHz.

   For this page, **all 399 target frequencies, from 0.537 to 19.971 MHz, use the
   same quadratic input limit of 19.971 MHz**. Each of four fits leaves one complete
   record out. Only the other three supply the scaling, reference phase and fitted
   coefficients; the held-out record supplies the prediction error and transfer moments.
   The expanded input basis also changes the results below 5 MHz. We therefore
   refit the entire band rather than join two incompatible sets of coefficients.
   Inputs above 20 MHz, including difference-frequency pairs that could feed this
   band, remain outside the model. No frequency is removed for low coherence.

   At target :math:`f`, write :math:`\widehat Y_f=L_fX_f+\sum_jQ_{fj}Z_j`, where
   :math:`X_f,Y_f` are the C1 and C3 Fourier coefficients in volts (V), the hat denotes
   prediction, and :math:`Z_j=X_{f_{1j}}X_{f_{2j}}` with :math:`f_{1j}+f_{2j}=f`.
   The index :math:`j` counts each nonzero signed input pair once, with
   :math:`f_{1j}\le f_{2j}`. Negative-frequency coefficients are conjugates of
   positive-frequency coefficients. :math:`L_f` is dimensionless; :math:`Q_{fj}` is
   in V⁻¹. “Joint LS” below means these coefficients are fitted together by complex
   least squares, not a linear-only fit. “Kim” means the stationary correction
   explained on page 07; its necessary common-power bound must still be checked.

   Before interpreting growth, remove a reference rotation:
   :math:`\delta_f=\arg\langle Y_fX_f^*\rangle_{\rm train}` in radians.
   The star denotes conjugation; brackets average segments. Define
   :math:`\widetilde L_f=e^{-i\delta_f}L_f` and its increment
   :math:`\ell_f=\widetilde L_f-1`. The lowercase :math:`\ell_f` is a change from
   the unit multiplier. :math:`\operatorname{Re}\ell_f` is the component along the
   reference signal, while :math:`\operatorname{Im}\ell_f` is perpendicular to it,
   not an angle. This rotation does not calibrate probe response or determine
   propagation direction. The rotated quadratic prediction is
   :math:`N_f=\sum_j e^{-i\delta_f}Q_{fj}Z_j`, in V. The full modeled increment
   is :math:`H_f=\ell_fX_f+N_f`; the rotated residual is
   :math:`R_f=e^{-i\delta_f}(Y_f-\widehat Y_f)`.

   .. raw:: html

      <details class="k05-note"><summary>Keep the quadratic prediction and residual in the same notation</summary>

   .. k05:equation:: rates-rotated-model
      :lang: en

      \begin{aligned}
      \ell_f&=e^{-i\delta_f}L_f-1,\qquad
      N_f=\sum_j e^{-i\delta_f}Q_{fj}Z_j,\\
      H_f&=\ell_fX_f+N_f,\qquad
      R_f=e^{-i\delta_f}(Y_f-\widehat Y_f),\\
      e^{-i\delta_f}Y_f&=X_f+H_f+R_f .
      \end{aligned}

   Here :math:`i^2=-1`, :math:`N_f` is the rotated quadratic prediction,
   :math:`H_f` the complete modeled increment, and :math:`R_f` the rotated residual;
   all three have units V. This identity includes the prediction error and needs
   no small-step approximation. The exact linear amplitude multiplier is
   :math:`|\widetilde L_f|=\sqrt{(1+\operatorname{Re}\ell_f)^2+(\operatorname{Im}\ell_f)^2}`.
   Thus a real increment alone describes amplitude change only when the remaining
   imaginary component is negligible.

   .. raw:: html

      </details>

   .. rubric:: 2. Figure 2(a): a dispersion model supplies a time scale

   A fitted multiplier describes a change **between positions**. A growth rate
   describes a change **per second**. Connecting them requires a travel time.
   The paper uses a theoretical dispersion relation to obtain a group velocity;
   its Figure 2(a) is not simply an unwrapped two-probe phase measurement.

   .. figure:: /_static/K_Diagnostics/k05-compare-dispersion.svg
      :width: 100%
      :alt: Source-derived dispersion curve and our assumed kinetic branch, with the same displayed axis limits.

      Figure 1. Counterparts of [1], Figure 2(a). Left: approximate reference redraw.
      Right: a calculated branch under the assumptions below, not measured dispersion.

   The left panel rises through a much larger displayed frequency range. The right
   curve lies near the bottom of the same frame. **This alone does not establish
   a measured speed ratio.** The paper labels its ordinate :math:`\omega_k` in Hz;
   we explicitly plot :math:`f=\omega_r/(2\pi)` in Hz. That source convention must
   be resolved before using digitized slopes quantitatively. Our branch also uses
   different, partly assumed plasma parameters.

   Our kinetic scenario uses the reported slow-scan temperature 9.1689 eV and
   magnetic components 39.48 and 80.34 G. It assumes Xe⁺, density
   :math:`n_0=10^{17}` m⁻³, electron drift +100 km/s,
   :math:`k_\parallel\lambda_{De}=0.03`, and zero ion Doppler shift.
   The density, drift, field-aligned geometry and applicability of the slow scan to
   these fast records are assumptions. The retained branch covers only about
   **0.179–5.592 MHz**. It cannot supply a group velocity throughout 5–20 MHz.

   .. raw:: html

      <details class="k05-note"><summary>See our branch on a suitable scale, and compare its slope with the assumed speed</summary>

   .. figure:: /_static/K_Diagnostics/k05-compare-dispersion-local.svg
      :width: 100%
      :alt: Local-scale kinetic dispersion and its group-velocity derivative; a separate horizontal line marks the assumed reference speed.

      The same branch on a local scale. The derivative varies with frequency;
      the dashed constant is a separate assumption, not an extrapolation.

   At 2.001953125 MHz this model gives about 2148 m/s. This motivates the rounded
   **reference value** 2150 m/s used below, but does not validate that value at high
   frequency. Multiplying the assumed speed by two would multiply all converted
   rates by two, without changing the fits or the across-gap contribution signs.

   .. raw:: html

      </details>

   .. _k05-rates-group-velocity-en:

   .. raw:: html

      <details class="k05-note"><summary>How is the group velocity in the kinetic scenario calculated from the dispersion relation?</summary>

   The kinetic scenario uses the slope of a calculated dispersion curve. Start with the
   parameters stated above and solve for the frequency associated with each
   azimuthal wave number :math:`k_y`. The model assumes magnetized Maxwellian
   electrons and cold unmagnetized ions. With the ion Doppler shift set to zero,
   its dispersion relation is

   .. k05:equation:: rates-model-dispersion
      :lang: en

      \mathcal E(\omega,k_y)
      =1+k^2\lambda_{De}^2+g(\omega,k_y)
       -\frac{k^2\lambda_{De}^2\omega_{pi}^2}{\omega^2}=0,
      \qquad k^2=k_y^2+k_\parallel^2.

   This repeats :k05:eq:`comparison-dispersion`; the
   :ref:`comparison with reference [1], Eq. (7) <k05-source-7-en>` shows the
   original equation and the geometric simplifications. Here :math:`\mathcal E`
   is a dimensionless dispersion function, :math:`\lambda_{De}` is the electron
   Debye length in m, and :math:`\omega_{pi}` is the ion plasma angular frequency
   in rad/s. :math:`k_y` and :math:`k_\parallel` are wave numbers in m⁻¹, across
   and along the magnetic field in this model. The dimensionless
   :math:`g(\omega,k_y)` describes the electron response, evaluated by the
   Gordeev series in :k05:eq:`comparison-gordeev`; it is different from the
   power-balance quantity :math:`g_f` introduced below.

   The root is complex: :math:`\omega=\omega_r+i\gamma_{\rm th}`.
   Its real part :math:`\omega_r` is the oscillation angular frequency; the
   imaginary part :math:`\gamma_{\rm th}` is the model growth rate for the
   :math:`e^{-i\omega t}` convention. Following one continuous root as
   :math:`k_y` varies gives a dispersion curve. With
   :math:`k_\parallel` and all background parameters held fixed, its slope gives
   the **group velocity**:

   .. k05:equation:: rates-group-slope
      :lang: en

      v_{g,y}=\frac{\partial\omega_r}{\partial k_y}
             =2\pi\frac{\partial f}{\partial k_y},
      \qquad f=\frac{\omega_r}{2\pi}.

   Here :math:`f` is frequency in Hz and :math:`v_{g,y}` has units m/s.
   The factor :math:`2\pi` matters when the dispersion plot uses Hz rather
   than rad/s. The phase velocity :math:`v_{\rm ph,y}=\omega_r/k_y` describes
   a constant-phase surface; it is generally different from this slope.

   To obtain the slope without fitting a line to the plot, differentiate
   :math:`\mathcal E(\omega(k_y),k_y)=0` along the selected root. The chain rule
   gives the first line below; rearrange it and take the real part to obtain
   the second:

   .. k05:equation:: rates-group-implicit
      :lang: en

      \begin{aligned}
      \frac{\partial\mathcal E}{\partial\omega}
      \frac{d\omega}{dk_y}
      +\frac{\partial\mathcal E}{\partial k_y}&=0,\\
      v_{g,y}
      &=\operatorname{Re}\!\left[
        -\frac{\partial\mathcal E/\partial k_y}
              {\partial\mathcal E/\partial\omega}\right].
      \end{aligned}

   Evaluate both partial derivatives at the same complex root, with
   :math:`\partial\mathcal E/\partial\omega\ne0`. In the numerator, vary
   :math:`k_y` while holding :math:`\omega` fixed; in the denominator, vary
   :math:`\omega` while holding :math:`k_y` fixed. The total derivative
   :math:`d\omega/dk_y` instead follows the root, so both change together.
   The code evaluates the partial derivatives with central differences. This is
   the same calculation as :k05:eq:`comparison-branch`.

   Each root now supplies a pair :math:`(f,v_{g,y})`. On the single monotone
   branch used here, interpolate these pairs onto the measured Fourier
   frequencies without extrapolating beyond the branch. This produces the
   local branch plot above. At :math:`f=2.001953125` MHz the model gives
   :math:`k_y\approx5095.6` m⁻¹ and :math:`v_{g,y}\approx2148` m/s.
   Across 3.7 mm, the corresponding time is about 1.72 μs.

   A straight dispersion curve :math:`\omega_r=v k_y`, with constant
   :math:`v`, would give the same group velocity at every frequency. The
   selected model curve changes slope, producing the frequency dependence along the branch. These speeds depend on the stated parameters and selected branch;
   they are not an independent measurement of propagation speed. The four-fold ranges of converted rates do not include uncertainty in those assumptions.

   .. raw:: html

      </details>

   For a common comparison across the whole fitted band, we use the explicitly
   assumed constant :math:`v_*=2150` m/s, directed from C1 to C3. The corresponding
   time is :math:`\tau_* =0.0037/2150\approx1.72` μs. This is a **conditional
   conversion scenario**, not a high-frequency dispersion prediction. No measured
   channel gain, delay or frequency-response correction has been applied.

   .. rubric:: 3. Figure 2(b): compare the measured spectral features

   The spectrum uses the same records as page 06. Average the squared windowed
   Fourier coefficients, then convert to the one-sided, Hann-corrected power
   spectral density (PSD). Here the preserved Welch result uses 16384 samples per
   segment for finer spectral resolution; it is not the 2048-point coefficient fit.
   See :ref:`page 06 <k05-experiment-en>` for the processing and normalization.

   .. figure:: /_static/K_Diagnostics/k05-compare-spectra.svg
      :width: 100%
      :alt: Approximate source spectra and the four-record mean C1 and C3 voltage PSD, on the reference log-log axis ranges.

      Figure 2. Counterparts of [1], Figure 2(b). Our spectrum extends to the
      50 MHz Nyquist frequency; the remaining reference frame is left empty.

   In the paper, the broad low-frequency component coexists with several
   high-frequency resonances separated by roughly 7 MHz. The authors interpret
   them in the context of prior EDI measurements. In our panel, inspect the
   falling broadband level and differences between C1 and C3. The spectrum itself
   does not say which frequency supplies energy to another.
   The source plots :math:`P` in Hz⁻¹; our ordinate is
   :math:`S^+(f)` in μV²/Hz, using only the exact conversion from V²/Hz by
   :math:`10^{12}`. We do not renormalize either probe to make its height resemble
   the source. **The absolute heights are not the same physical observable.**

   .. rubric:: 4. Figure 2(c): calculate apparent growth, then compare it

   The time conversion and signed quadratic contribution use
   :math:`B_{fj}^{\rm test}=\langle X_f^*Z_j\rangle_{\rm test}`, a complex
   third-order moment in V³, and :math:`P_X=\langle|X_f|^2\rangle_{\rm test}` in V².
   For compactness, let :math:`g_f=2\operatorname{Re}\ell_f` and
   :math:`t_f=2\operatorname{Re}\langle X_f^*N_f\rangle_{\rm test}/P_X`.
   They are dimensionless **across-gap contributions**, not rates or fractions of
   the number of waves. With a chosen group velocity, the conversion is

   .. container:: k05-paper-match

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

      :math:`\gamma_{y,\rm app}` is an apparent **amplitude** rate in s⁻¹.
      The subscript “app” preserves its measured-voltage and assumed-propagation
      status. :math:`T_f^{(1/2)}` is in V²/s. Its superscript denotes the
      half-power convention, not a square root. In this page's broad-band plots,
      substitute :math:`v_{g,y}=v_*` and :math:`\tau_f=\tau_*`.

      **Reference [1], Eq. (4), in its original notation:**

      .. k05:equation:: rates-paper-coefficients
         :lang: en

         \begin{aligned}
         L_f&=\left[\left(\frac{\gamma_{f(y)}}{v_{g(y)}}+ik_y\right)\Delta y
                +1-i\Delta\Theta_f\right]e^{i\Delta\Theta_f},\\
         Q_f^{1,2}&=e^{i\Delta\Theta_f}V_{1,2}^{Q}\Delta y/v_{g(y)} .
         \end{aligned}

      Our :math:`\delta_f` corresponds to :math:`\Delta\Theta_f`, and
      :math:`v_{g,y}` to :math:`v_{g(y)}`. Remove the exponential phase factor,
      subtract one and take the real part to obtain the apparent rate.
      :math:`k_y` is a real wave number; :math:`V^Q_{1,2}` is the continuous
      quadratic coefficient. The imaginary terms do not enter this real part.

   .. figure:: /_static/K_Diagnostics/k05-compare-growth.svg
      :width: 100%
      :alt: Source growth-rate redraw and joint-LS/Kim apparent growth using an assumed constant speed; separate right axes show theoretical growth.

      Figure 3. Counterparts of [1], Figure 2(c), using the source axis limits.
      Left axes: diagnosed/apparent rates. Right axes: theoretical rates, with
      a ten-times-larger range. Triangles at the lower/upper edge mark means outside the frame.
      Open circles retain Kim results that fail the necessary bound in at least
      one fold. Shading shows the four-fold range, not a confidence interval.

   The paper's main diagnosed growth peak lies near 7 MHz; its frequency structure
   resembles the theoretical result, while the diagnosed rates are about an order
   of magnitude smaller. The separate vertical axes make similarly tall curves
   look closer than their numerical values are. A low-frequency negative region
   represents damping in the paper's interpretation.

   Our curves are the real parts of **two estimates of the same type of coefficient**:
   joint LS and Kim. The dotted theoretical curve is a separate kinetic calculation,
   only on the existing branch; it is not fitted to the observed apparent rate.
   Negative apparent growth may include spatial decorrelation, input noise or
   unequal channel response. It is not automatically plasma damping.
   The extended fits include 5–20 MHz even where coherence is low.

   .. raw:: html

      <details class="k05-note"><summary>Show the apparent rates on their own scale, including clipped values</summary>

   .. figure:: /_static/K_Diagnostics/k05-compare-growth-local.svg
      :width: 100%
      :alt: All four-fold mean apparent growth values on local axes with the same coefficients and assumed speed.

      Same numbers and time scale as Figure 3; only the plotting limits change.

   Inspect the signed values, disagreement between estimators, and fold spread.
   The extra visibility is not extra physical validation. The theoretical curve
   retains its own axis and ends at the computed branch limit; there is no hidden
   extension to 20 MHz.

   .. raw:: html

      </details>

   .. rubric:: 5. Figure 3(a): where are the large quadratic coefficients?

   Each pair supplies a coefficient, so we place its magnitude at
   :math:`(f_1,f_2)`. The target is :math:`f=f_1+f_2`. Our fit counts an unordered
   product once. For a symmetric ordered-pair map, an off-diagonal coefficient is
   split equally between the two exchanged cells; a diagonal coefficient is
   unchanged. Negative targets are reconstructed by conjugation, not independently
   fitted. Color displays the logarithm of the mean magnitude over four folds.

   .. figure:: /_static/K_Diagnostics/k05-compare-coupling.svg
      :width: 100%
      :alt: Image-derived source coupling map and our Kim coefficient magnitude map, with matching plus/minus 50 MHz limits and log color ranges.

      Figure 4. Counterparts of [1], Figure 3(a), with color range −2 to 1.
      Right: :math:`\log_{10}(|Q^{\rm sym}|/\mathrm{V}^{-1})`.
      White means not fitted, not zero coupling. Dark values can be below the
      color-scale minimum; the brightest color also includes values above the maximum.
      Kim values remain displayed even where its bound fails.

   In the source map, bright structures in the opposite-sign quadrants close to
   :math:`f_1+f_2=0` associate two large, nearly cancelling input frequencies with
   a small target frequency: a **difference-frequency geometry**. This motivates
   checking transfer toward lower frequencies. Brightness alone gives neither
   the transfer sign nor proof that energy travels along that pair.
   The authors also discuss a high-sum-frequency feature as potentially noise related.

   Our fitted region is smaller because both inputs and the target are limited
   to 20 MHz, with targets below 0.5 MHz excluded. The diagonal blank strip around
   :math:`f_1+f_2=0` is therefore an analysis choice. A large coefficient can also
   multiply a weak product, or arise in an inadequately specified model.
   The source and our measured-voltage coefficients do not share a demonstrated
   physical normalization; matching the numerical color range does not make
   their absolute magnitudes directly comparable.

   .. raw:: html

      <details class="k05-note"><summary>Enlarge our fitted region and compare joint LS with Kim</summary>

   .. figure:: /_static/K_Diagnostics/k05-compare-coupling-local.svg
      :width: 100%
      :alt: The joint-LS and Kim maps within plus/minus 20 MHz, using the full joint finite log-magnitude range.

      A shared local color scale spans all finite values of both experimental maps.
      This changes the view, not the coefficient values or the fitted pair set.

   Compare the location of structure between estimators before interpreting it.
   The Kim map is not a validated noise-free result: the frequency-wise bound
   check below applies to its entire diagonal of pairs with that target sum.

   .. raw:: html

      </details>

   .. rubric:: 6. Figure 3(b): phase information supplies a signed contribution

   To proceed from a coefficient map to a transfer curve, multiply each complex
   coefficient by its corresponding complex bispectral moment, remove the same
   reference phase, take the real part, and sum the pairs. Explicitly,

   .. k05:equation:: rates-pair-contribution
      :lang: en

      B_{fj}^{\rm test}=\langle Z_jX_f^*\rangle_{\rm test},\qquad
      t_{fj}=\frac{2\operatorname{Re}(e^{-i\delta_f}Q_{fj}B_{fj}^{\rm test})}{P_X},\qquad
      t_f=\sum_j t_{fj}.

   The pair contribution :math:`t_{fj}` can be positive or negative even at the
   same :math:`|Q_{fj}|`, because the product phase matters. Its sum is
   :math:`t_f=\sum_j t_{fj}`. All bispectral moments here are evaluated on the
   held-out capture, not reused from training.

   .. container:: k05-paper-match

      **Reference [1], Eq. (6), in its original notation:**

      .. k05:equation:: rates-paper-transfer
         :lang: en

         T_f=(v_{g(y)}/\Delta y)\operatorname{Re}\left[
          \sum_{f=f_1+f_2}e^{-i\Delta\Theta_f}Q_f^{1,2}X_{f_1}X_{f_2}X_f^*\right].

      Replacing the triple product by its ensemble mean gives our
      :math:`B_{fj}^{\rm test}`. Our grouped pairs and grouped :math:`Q_{fj}`
      must be used together without double counting. The printed expression
      corresponds to our :math:`T_f^{(1/2)}`; the full first-order rate of change
      of the explicitly defined mean square :math:`P_X` contains
      :math:`2T_f^{(1/2)}`. This factor is distinct from amplitude growth.

   .. figure:: /_static/K_Diagnostics/k05-compare-transfer.svg
      :width: 100%
      :alt: Approximate signed transfer from the source and the conditional voltage-domain transfer on matching reference axis ranges.

      Figure 5. Counterparts of [1], Figure 3(b). The common ±4×10⁷ numerical
      range makes our V²/s result look almost flat. The units and normalization
      are different; the apparent height ratio has no direct physical meaning.

   In the paper, negative transfer around 5–10 MHz and positive transfer below
   about 2 MHz, considered together with growth and damping, support transfer
   from higher-frequency instability modes toward lower-frequency modes in the
   saturated state. This is a statistical interpretation, not a time-lapse
   movie of a wave moving through frequency.

   Our four-fold mean half-power values span about −0.119 to +3.164 V²/s for
   joint LS and −6.268 to +7.223 V²/s for Kim. The near-zero-looking line on
   the reference frame is a scale effect. Open the local
   view to determine its actual sign and size. A sign change or a bright
   difference-frequency band alone is insufficient to establish the same inverse
   cascade: the reference response, propagation, local-step and stationarity
   assumptions must also apply.

   .. raw:: html

      <details class="k05-note"><summary>Read the actual values below and above 5 MHz, without hiding the smaller band</summary>

   .. figure:: /_static/K_Diagnostics/k05-compare-transfer-local.svg
      :width: 100%
      :alt: Separate local views below 5 MHz and from 5 to 20 MHz, showing conditional half-power rates and dimensionless across-gap quadratic contributions.

      Top: :math:`T_f^{(1/2)}` with the assumed speed. Bottom: :math:`t_f`, which
      needs no velocity. Each column has a suitable vertical range; the 20 MHz
      input basis is unchanged throughout. Shading is the four-fold range.

   The lower row is the most direct place to compare the signed modeled change
   between probes. The upper row additionally weights it by the target's input
   power and the assumed inverse travel time. Thus a large fractional effect at
   a weak high-frequency target need not produce a large V²/s value.
   Both experimental estimates contain alternating signs, but their sizes and
   even some signs disagree: around 1.5–2 MHz, for example, the positive-to-negative
   pattern is estimator dependent. This is not a reproduction of the source
   transfer pattern. Changing a positive assumed speed rescales the upper row but cannot reverse
   its signs or repair a failed Kim bound.

   .. raw:: html

      </details>

   .. rubric:: 7. Which parts of this comparison are reliable?

   The four complete-record holdouts provide an independent check of prediction.
   They do not independently calibrate the physical interpretation. The extended
   analysis uses between 204 and 403 quadratic products per target, with 14646
   training segments and 4882 held-out segments per fold. Rank and conditioning
   are checked after training-only RMS scaling; the numerical audit and all
   frequencies are preserved.

   All 1596 joint fits are full rank; the largest scaled condition number is
   68.55. Across 5–20 MHz, quadratic inputs lower the held-out total mean-square
   error by **7.84%–7.96%** across the four folds. The denominator is the
   linear-only residual, not total wave power. Summing residual power within
   each band before taking the relative reduction gives:

   .. list-table:: Held-out error reduction with the common 20 MHz input basis
      :header-rows: 1
      :widths: 35 35 30

      * - Target band
        - Four-fold reduction range
        - Kim passes in all four folds
      * - 0.5–5 MHz
        - 0.30%–0.86%
        - 7 / 92 frequencies
      * - 5–10 MHz
        - 10.66%–10.88%
        - 41 / 102 frequencies
      * - 10–15 MHz
        - 0.92%–1.20%
        - 73 / 103 frequencies
      * - 15–20 MHz
        - 1.46%–1.64%
        - 78 / 102 frequencies

   Overall, **199 of 399** targets pass the necessary Kim bound in every fold;
   192 of the 307 high-frequency targets do. Passing is necessary, not sufficient:
   the prediction and measurement assumptions remain separate checks.

   For Figure 6, :math:`C_{XY}^2=|\langle Y_fX_f^*\rangle_{\rm train}|^2/(P_X^{\rm train}P_Y^{\rm train})` is squared coherence. The training powers
   are the corresponding mean squared coefficients. :math:`P_*` is Kim's
   proposed common signal power. The held-out error is
   :math:`\epsilon_f=\langle|Y_f-\widehat Y_f|^2\rangle_{\rm test}/P_Y`;
   a value near one is comparable to predicting zero for that frequency.

   .. figure:: /_static/K_Diagnostics/k05-compare-reliability.svg
      :width: 100%
      :alt: Training coherence, held-out normalized prediction error, Kim common-power fraction, and retained finite-step and residual contributions across 0.5 to 20 MHz.

      Figure 6. Four-fold means and ranges. Top left: squared coherence.
      Top right: normalized mean-square prediction error (NMSE; smaller is better).
      Bottom left: Kim requires a common-power ratio between 0 and 1.
      Bottom right: joint-LS normalized quadratic, finite-step and residual terms.

   Here :math:`s_f=\langle|H_f|^2\rangle_{\rm test}/P_X` is the finite-step
   squared increment and :math:`r_f=\langle|R_f|^2\rangle_{\rm test}/P_X` is
   the residual contribution. Neither is discarded in the complete balance.

   Low coherence means little same-frequency linear information is shared by
   the two measured records. Nonlinear terms may still improve prediction;
   they cannot reconstruct independent noise or all spatially decorrelated
   fluctuations. This explains why adding quadratic terms need not bring the
   predicted high-frequency power onto the measured spectrum.

   **A full-rank fit can still have an invalid physical interpretation.** Values
   above one in the common-power panel fail a necessary Kim condition. The
   plotted Kim rates then remain algebraic outputs, not accepted noise-corrected
   growth or transfer. Joint LS does not require this bound to predict voltages,
   but it does not thereby remove input noise or become a validated physical
   growth estimate. The fold range covers record-to-record variability, not
   uncertainty in velocity, channel response or model choice.

   The finite-step contribution also matters. The linear and signed quadratic
   terms alone are not the full measured power difference. In particular, a
   small quadratic contribution should not be interpreted while silently
   discarding a larger finite-step correction.

   .. raw:: html

      <details class="k05-note"><summary>Check the complete power balance rather than keeping only two terms</summary>

   Using :k05:eq:`rates-rotated-model`, define

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

   :math:`s_f` retains the full squared modeled increment, including
   :math:`|N_f|^2`; :math:`r_f` is residual power; :math:`c_f` is the signed
   prediction–residual cross term. The latter need not vanish on held-out data.
   All five contributions are dimensionless. The exact identity is

   .. k05:equation:: rates-exact-balance
      :lang: en

      D_f\equiv\frac{P_Y-P_X}{P_X}=g_f+t_f+s_f+r_f+c_f.

   It follows by expanding the square before averaging:

   .. k05:equation:: rates-expand-square
      :lang: en

      \begin{aligned}
      |X+H+R|^2&=|X|^2+2\operatorname{Re}(X^*H)+|H|^2
                   +|R|^2+2\operatorname{Re}[(X+H)^*R],\\
      \langle X^*H\rangle&=\ell P_X+\langle X^*N\rangle .
      \end{aligned}

   Dividing the same identity by the assumed travel time gives

   .. k05:equation:: rates-rate-balance
      :lang: en

      \frac{D_f}{\tau_f}
      =2\gamma_{y,\mathrm{app}}+\frac{2T_f^{(1/2)}}{P_X}
       +\frac{s_f+r_f+c_f}{\tau_f}.

   Agreement of this identity is an algebra check, not proof that the two-rate
   continuous physical model is adequate. The measured power change also includes
   finite-step and residual terms; it is not a conserved plasma-energy budget.

   .. raw:: html

      </details>

   The calculation is now closed for the **retained measured-voltage model**:
   records → statistics → coefficients → signed across-gap contributions →
   conditional rates. A quantitative EDI or inverse-cascade claim still needs a
   supported propagation direction and branch, channel/probe response, and a
   justified relation between the measured signal and the wave quantity.
   The :ref:`probe-response supplement <k05-response-en>` examines that measurement
   chain. The :ref:`dispersion and comparison supplement <k05-comparison-en>` retains
   the narrower 5 MHz input scenario; its numbers are not the expanded fit here.

   .. raw:: html

      <details class="k05-note"><summary>Reproduce the extended fits and the paired figures</summary>

   .. code-block:: bash

      OPENBLAS_NUM_THREADS=2 python K_Diagnostics/K05_bispectral_transfer/analyze_extended_comparison.py \
        --data /path/to/raw-captures --output /path/to/new-extended-results
      python K_Diagnostics/K05_bispectral_transfer/plot_extended_comparison.py \
        --extended /path/to/new-extended-results \
        --comparison /path/to/z5p5_a3p7_paper_comparison \
        --output /path/to/new-comparison-plots

   The first script saves coefficients, pairs, moments, powers, holdout errors,
   rank/conditioning, Kim checks, configuration and hashes. QR compression of the
   augmented training matrix preserves all inner products, including target
   residual power, before the existing SVD/Kim solve. Tests compare it with the
   uncompressed calculation. No random split mixes segments from a held-out record
   into training. The second script reads these outputs and the preserved kinetic
   branch/PSD. The source-derived reference readings and provenance are in
   ``reference_digitization``; the article images are not required to replot them.

   .. raw:: html

      </details>

   .. rubric:: Reference

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.
   Source graphics © 2023 American Physical Society; the reference panels here
   are attributed, approximate image-derived redraws, not supplied raw data.

.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-rates-zh:

   .. rubric:: 从拟合系数，走到五幅逐项对照图

   :ref:`第06页 <k05-experiment-zh>` 算出了测量统计量，
   :ref:`第07页 <k05-experiment-coefficients-zh>` 估计了线性与二次系数。
   现在按照 Brown 与 Jorns [1] 图2、图3的面板顺序，计算对应结果。
   每一项都分清 **文献报告了什么、我们的电压记录算出了什么、哪些解释依赖物理假设**。

   下面的文献曲线是 **从已发表图中描点后近似重绘** 的，使用了不同的颜色与线型；
   系数热图是从图像读数得到的近似重绘。它们都不是作者原始数据，不是独立模拟，也不是新的测量结果。
   本页面不展示文献原图。重绘用于帮助理解总体结构，细小起伏和精确数值受原图分辨率限制。

   .. rubric:: 1．先准备一套一致的计算，包含5–20 MHz

   C1与C3相隔 :math:`\Delta y=3.7` mm。继续使用第06页的四组同步记录：
   每个不重叠短段取2048个样本，去段均值，乘周期Hann窗，再采用正指数、除以2048的Fourier系数。
   采样率为100 MHz，原生频点间隔为48.828125 kHz。

   本页 **399个目标频点统一覆盖0.537–19.971 MHz，二次输入的绝对频率上限也统一为19.971 MHz**。
   四轮拟合每次留出一整组记录；其余三组提供列缩放、参考相位和拟合系数，留出组提供预测误差和转移矩。
   扩大输入频带后，5 MHz以下的系数也会改变，因此这里重新拟合整个频段，而不是拼接两套不同的系数。
   20 MHz以上的输入，包括可能向本频带贡献的差频组合，仍不在模型内。
   **没有按低相干度删除频点。**

   在目标频率 :math:`f`，预测模型为 :math:`\widehat Y_f=L_fX_f+\sum_jQ_{fj}Z_j`，
   其中 :math:`X_f,Y_f` 是C1、C3的Fourier系数，单位为伏特V；帽号表示预测值。
   :math:`Z_j=X_{f_{1j}}X_{f_{2j}}`，且 :math:`f_{1j}+f_{2j}=f`。
   下标 :math:`j` 只计一次非零的有符号波对，约定 :math:`f_{1j}\le f_{2j}`；
   负频率系数由正频率系数取共轭获得。
   :math:`L_f` 无量纲，:math:`Q_{fj}` 的单位为V⁻¹。
   下面的“Joint LS”表示联合拟合这两类系数的复数最小二乘（joint least squares），不是只含线性项的拟合。
   “Kim”表示第07页的平稳性修正，其共同功率的必要条件仍需检查。

   解释增长之前，先去掉一个参考旋转：
   :math:`\delta_f=\arg\langle Y_fX_f^*\rangle_{\rm train}`，单位为弧度。
   星号表示共轭，尖括号表示对短段取平均。定义
   :math:`\widetilde L_f=e^{-i\delta_f}L_f`，再定义相对单位乘数的增量
   :math:`\ell_f=\widetilde L_f-1`。小写 :math:`\ell_f` 不是另一种大写L。
   :math:`\operatorname{Re}\ell_f` 是沿参考信号方向的分量，
   :math:`\operatorname{Im}\ell_f` 是垂直方向的分量，不能直接当成相位角。
   这个旋转不等于校准探针响应，也不能确定传播方向。旋转后的二次预测记为
   :math:`N_f=\sum_j e^{-i\delta_f}Q_{fj}Z_j`，单位V。完整模型增量为
   :math:`H_f=\ell_fX_f+N_f`；旋转后的残差为
   :math:`R_f=e^{-i\delta_f}(Y_f-\widehat Y_f)`。

   .. raw:: html

      <details class="k05-note"><summary>把二次预测和残差也写进同一套符号</summary>

   .. k05:equation:: rates-rotated-model
      :lang: zh

      \begin{aligned}
      \ell_f&=e^{-i\delta_f}L_f-1,\qquad
      N_f=\sum_j e^{-i\delta_f}Q_{fj}Z_j,\\
      H_f&=\ell_fX_f+N_f,\qquad
      R_f=e^{-i\delta_f}(Y_f-\widehat Y_f),\\
      e^{-i\delta_f}Y_f&=X_f+H_f+R_f .
      \end{aligned}

   :math:`i^2=-1`；:math:`N_f` 是旋转后的二次预测，:math:`H_f` 是完整模型增量，
   :math:`R_f` 是旋转后的残差，三者单位都是V。这是包含预测误差的恒等式，不需要“小步长”近似。
   准确的线性幅值乘数是
   :math:`|\widetilde L_f|=\sqrt{(1+\operatorname{Re}\ell_f)^2+(\operatorname{Im}\ell_f)^2}`。
   因此只有剩余虚部分量足够小时，实部增量才可以直接用来描述幅值增减。

   .. raw:: html

      </details>

   .. rubric:: 2．对照图2(a)：色散模型怎样提供时间尺度

   拟合乘数描述的是 **从一个位置到另一个位置** 的变化；增长率描述的是 **每秒** 的变化。
   连接这两者需要传播时间。文献用理论色散关系（dispersion relation）得到群速度（group velocity）；
   其图2(a)并不是直接把双探针相位展开后得到的实测曲线。

   .. figure:: /_static/K_Diagnostics/k05-compare-dispersion.svg
      :width: 100%
      :alt: 文献色散曲线的近似重绘与本实验假设动力学分支，采用相同的坐标范围。

      图1．对照文献[1]图2(a)。左：文献近似重绘。右：下述假设下算出的色散分支，不是实测色散。

   左图跨越了更大的显示频率范围，右图则贴近相同图框的底部。
   **不能仅据此说实测波速比文献低多少。** 原文纵轴写的是 :math:`\omega_k`、单位Hz，
   我们明确画的是 :math:`f=\omega_r/(2\pi)`，单位Hz。
   在用描点斜率定量比较之前，还需要核清原文的频率约定；右图也使用了不同且部分假设的等离子体参数。

   本实验的动力学情景采用已报告的慢扫描温度9.1689 eV和磁场分量39.48、80.34 G；
   另外假设Xe⁺、密度 :math:`n_0=10^{17}` m⁻³、电子漂移+100 km/s、
   :math:`k_\parallel\lambda_{De}=0.03`，并忽略离子多普勒频移。
   密度、漂移、沿磁场分解的几何，以及慢扫描结果能否代表高频记录，都是假设。
   现有分支只覆盖约 **0.179–5.592 MHz**，不能用它给整个5–20 MHz频段提供群速度。

   .. raw:: html

      <details class="k05-note"><summary>换成本实验适合的量程，看清色散曲线及其斜率</summary>

   .. figure:: /_static/K_Diagnostics/k05-compare-dispersion-local.svg
      :width: 100%
      :alt: 同一动力学分支的局部量程，以及由导数得到的群速度和独立假设的恒定参考速度。

      同一分支的局部量程。导数得到的速度随频率改变；水平虚线是另一个假设，不是曲线的外推。

   在2.001953125 MHz，这个模型给出的群速度约为2148 m/s，下面将它取整为
   **参考值** 2150 m/s。但这不能验证高频也具有相同速度。
   若把假设速度加倍，换算后的各变化率会加倍，拟合结果和跨距贡献的符号都不改变。

   .. raw:: html

      </details>

   .. _k05-rates-group-velocity-zh:

   .. raw:: html

      <details class="k05-note"><summary>动力学情景的群速度如何从色散关系算出来？</summary>

   动力学情景使用的是计算得到的色散曲线的斜率。先取上面列出的参数，
   再求每个周向波数 :math:`k_y` 对应什么频率。
   当前模型假设电子受磁场约束、服从 Maxwell 分布，离子为非磁化冷离子。
   暂时忽略离子多普勒频移（Doppler shift）后，使用的色散关系（dispersion relation）为

   .. k05:equation:: rates-model-dispersion
      :lang: zh

      \mathcal E(\omega,k_y)
      =1+k^2\lambda_{De}^2+g(\omega,k_y)
       -\frac{k^2\lambda_{De}^2\omega_{pi}^2}{\omega^2}=0,
      \qquad k^2=k_y^2+k_\parallel^2.

   这是 :k05:eq:`comparison-dispersion` 的重复列出，方便就地读图；
   :ref:`与文献[1]式(7)的对照 <k05-source-7-zh>` 给出了原式及几何简化。
   :math:`\mathcal E` 是无量纲色散函数；:math:`\lambda_{De}` 为电子德拜长度，单位m；
   :math:`\omega_{pi}` 为离子等离子体角频率，单位rad/s。
   :math:`k_y`、:math:`k_\parallel` 分别是本模型中垂直、平行于磁场的波数分量，单位m⁻¹。
   无量纲函数 :math:`g(\omega,k_y)` 描述电子响应，用 :k05:eq:`comparison-gordeev`
   的 Gordeev 级数计算；它与前面功率收支中的 :math:`g_f` 是不同的量。

   求出的根是复数：:math:`\omega=\omega_r+i\gamma_{\rm th}`。
   实部 :math:`\omega_r` 是振荡角频率；在 :math:`e^{-i\omega t}` 约定下，
   虚部 :math:`\gamma_{\rm th}` 是模型的增长率。
   改变 :math:`k_y` 并连续跟踪同一条根，就得到色散曲线。
   固定 :math:`k_\parallel` 和所有背景参数，对这条曲线求斜率，得到 **群速度（group velocity）**：

   .. k05:equation:: rates-group-slope
      :lang: zh

      v_{g,y}=\frac{\partial\omega_r}{\partial k_y}
             =2\pi\frac{\partial f}{\partial k_y},
      \qquad f=\frac{\omega_r}{2\pi}.

   :math:`f` 是普通频率，单位Hz；:math:`v_{g,y}` 的单位为m/s。
   如果色散图的纵轴用Hz而不是rad/s，斜率换成群速度时就要保留 :math:`2\pi`。
   相速度（phase velocity） :math:`v_{\rm ph,y}=\omega_r/k_y` 描述等相位面的移动，
   一般不等于这里的曲线斜率。

   实际计算斜率时，对 :math:`\mathcal E(\omega(k_y),k_y)=0` 沿所选的根求导。
   链式法则（chain rule）给出下面第一行；移项、相除，再取实部，得到第二行：

   .. k05:equation:: rates-group-implicit
      :lang: zh

      \begin{aligned}
      \frac{\partial\mathcal E}{\partial\omega}
      \frac{d\omega}{dk_y}
      +\frac{\partial\mathcal E}{\partial k_y}&=0,\\
      v_{g,y}
      &=\operatorname{Re}\!\left[
        -\frac{\partial\mathcal E/\partial k_y}
              {\partial\mathcal E/\partial\omega}\right].
      \end{aligned}

   两个偏导都在同一个复根处计算，且要求 :math:`\partial\mathcal E/\partial\omega\ne0`。
   分子的偏导固定 :math:`\omega`、只改变 :math:`k_y`；分母的偏导固定
   :math:`k_y`、只改变 :math:`\omega`。
   而 :math:`d\omega/dk_y` 是沿着根的变化求导，两者一起改变。
   代码用中心差分（central difference）计算这两个偏导，
   与 :k05:eq:`comparison-branch` 是同一个计算。

   现在每个根都给出一对 :math:`(f,v_{g,y})`。
   本例使用的单条分支上，频率单调变化，因此可以把这些点插值到实测 Fourier 频点，
   不向分支覆盖范围之外外推，就得到上面的局部分支速度图。
   在 :math:`f=2.001953125` MHz处，模型给出 :math:`k_y\approx5095.6` m⁻¹、
   :math:`v_{g,y}\approx2148` m/s；跨过3.7 mm对应的时间约为1.72 μs。

   如果色散关系是一条直线 :math:`\omega_r=v k_y`，其中 :math:`v` 为常数，
   各频率的群速度就相同。本例所选曲线的斜率在变化，所以动力学情景中的群速度随频率变化。
   这些速度依赖上述参数和所选分支，尚不是独立测量得到的传播速度；
   右图阴影也没有包含这些假设的不确定性。

   .. raw:: html

      </details>

   为了在整个拟合频带使用一套明确的时间换算，下面统一假设
   :math:`v_*=2150` m/s，方向从C1指向C3，对应
   :math:`\tau_*=0.0037/2150\approx1.72` μs。
   这是 **条件性的换算情景**，不是高频色散预测。未应用实测的通道增益、延迟或频率响应校正。

   .. rubric:: 3．对照图2(b)：先比较测量谱中有哪些结构

   功率谱继续使用第06页的同一批记录：对加窗后的Fourier系数模平方取平均，
   再按单边谱和Hann窗归一化得到功率谱密度（power spectral density, PSD）。
   这里保留的Welch结果使用每段16384点，提供较细的谱分辨率；
   它不同于拟合系数时的2048点分段。具体处理与归一化见 :ref:`第06页 <k05-experiment-zh>`。

   .. figure:: /_static/K_Diagnostics/k05-compare-spectra.svg
      :width: 100%
      :alt: 文献功率谱近似重绘与C1、C3四组平均电压功率谱，使用相同的双对数坐标范围。

      图2．对照文献[1]图2(b)。本实验谱覆盖到50 MHz奈奎斯特频率，文献图框中其余区域留白。

   文献中，低频宽带成分与多个高频共振峰同时出现，峰间隔约为7 MHz。
   作者结合先前的EDI测量研究解释这些峰。我们的右图首先应看随频率下降的宽带背景，以及C1、C3的差异；
   **功率谱本身不能告诉我们哪个频率向哪个频率输送能量。**
   左图的 :math:`P` 单位为Hz⁻¹，右图的 :math:`S^+(f)` 单位为μV²/Hz，
   只使用了V²/Hz乘 :math:`10^{12}` 的准确单位换算，没有把两支探针分别缩放到与文献相似的高度。
   两边的绝对高度不是同一个物理观测量。

   .. rubric:: 4．对照图2(c)：先算表观增长，再读两种估计

   时间换算和有符号二次贡献需要
   :math:`B_{fj}^{\rm test}=\langle X_f^*Z_j\rangle_{\rm test}`，这是单位V³的复三阶矩；
   还需要 :math:`P_X=\langle|X_f|^2\rangle_{\rm test}`，单位V²。
   为简写，定义 :math:`g_f=2\operatorname{Re}\ell_f` 和
   :math:`t_f=2\operatorname{Re}\langle X_f^*N_f\rangle_{\rm test}/P_X`。
   它们是无量纲的 **跨距贡献**，不是每秒的速率，也不是波的数量占比。
   给定群速度后，换算关系为

   .. container:: k05-paper-match

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

      :math:`\gamma_{y,\rm app}` 是表观 **幅值** 增长率，单位s⁻¹。
      “app”提醒我们它仍来自测量电压与假设传播。
      :math:`T_f^{(1/2)}` 的单位为V²/s，上标表示半功率约定，不是平方根。
      本页宽频带图统一代入 :math:`v_{g,y}=v_*`、:math:`\tau_f=\tau_*`。

      **文献[1]式(4)，保留原符号：**

      .. k05:equation:: rates-paper-coefficients
         :lang: zh

         \begin{aligned}
         L_f&=\left[\left(\frac{\gamma_{f(y)}}{v_{g(y)}}+ik_y\right)\Delta y
                +1-i\Delta\Theta_f\right]e^{i\Delta\Theta_f},\\
         Q_f^{1,2}&=e^{i\Delta\Theta_f}V_{1,2}^{Q}\Delta y/v_{g(y)} .
         \end{aligned}

      我们的 :math:`\delta_f` 对应 :math:`\Delta\Theta_f`，
      :math:`v_{g,y}` 对应 :math:`v_{g(y)}`。
      先去掉指数相位因子，再减去1并取实部，就得到上面的表观增长率。
      :math:`k_y` 是实波数，:math:`V^Q_{1,2}` 是连续方程的二次系数；纯虚项不进入这个实部。

   .. figure:: /_static/K_Diagnostics/k05-compare-growth.svg
      :width: 100%
      :alt: 文献增长率近似重绘与恒定假设速度下的联合最小二乘和Kim表观增长率，理论增长使用独立右轴。

      图3．对照文献[1]图2(c)，沿用原图范围。左轴：诊断／表观增长率；右轴：理论增长率，量程大十倍。
      下／上边缘三角形标出超出图框范围的均值。空心圆保留至少一轮未通过Kim必要条件的结果。
      阴影是四轮结果的范围，不是置信区间。

   文献中的主要诊断增长峰在约7 MHz附近，频率结构与理论有相似之处，但数值约小一个数量级。
   两套纵轴会让相近的曲线高度看起来比数值更接近，读图时必须分开看。
   文献也把低频的一段负增长解释为阻尼。

   我们的两条曲线是 **同一类系数的两种估计**：联合最小二乘与Kim修正。
   点线理论曲线来自独立的动力学计算，仅覆盖已有分支，不是对表观增长曲线的拟合。
   负的表观增长还可能包含空间失相关、输入噪声、两路响应不同等影响，不能直接等同于等离子体阻尼。
   本次扩展保留了5–20 MHz，即使相干度低也照样显示计算结果。

   .. raw:: html

      <details class="k05-note"><summary>使用本实验的量程，看清被原图范围截去的增长率</summary>

   .. figure:: /_static/K_Diagnostics/k05-compare-growth-local.svg
      :width: 100%
      :alt: 同一组表观增长率改用本实验适合的量程，保留全部四轮均值及范围。

      数值与时间尺度和图3相同，只改变显示范围。

   看清实际正负、两种估计之间的差别和四轮离散程度，但不能把“看得清”当作物理验证。
   理论曲线仍使用独立纵轴，并在已有分支的频率上限停止，没有暗中延伸到20 MHz。

   .. raw:: html

      </details>

   .. rubric:: 5．对照图3(a)：哪些波对的二次系数较大

   每个波对都有一个系数，将其模放在 :math:`(f_1,f_2)` 平面中，目标频率就是
   :math:`f=f_1+f_2`。拟合中交换顺序后的同一个乘积只计一次；
   画成对称的有序波对图时，非对角线系数平分给两个交换位置，对角线系数不变。
   负目标频率由共轭重建，不是独立拟合。颜色表示四轮系数模平均值的对数。

   .. figure:: /_static/K_Diagnostics/k05-compare-coupling.svg
      :width: 100%
      :alt: 文献系数热图的图像近似重绘与本实验Kim系数模，坐标统一到正负50 MHz，对数色标统一为负2到1。

      图4．对照文献[1]图3(a)，色标统一为−2到1。右图是
      :math:`\log_{10}(|Q^{\rm sym}|/\mathrm{V}^{-1})`。
      白色表示未拟合，不表示耦合为零；最暗／最亮的颜色也包括超出色标下／上限的数值。
      未通过Kim条件的数值仍保留显示。

   文献热图在异号象限、接近 :math:`f_1+f_2=0` 的亮结构，表示两个较大且几乎互相抵消的输入频率
   对应一个较低的目标频率，这是 **差频组合（difference-frequency pair）** 的几何关系。
   它提示我们接下来检查向低频的转移，但亮度本身既不给出转移方向，也不能证明这条波对正在输送能量。
   作者还指出一条较高和频位置的结构可能与噪声有关。

   本实验有数据的区域较小，因为输入与目标都限制在20 MHz内，且不拟合0.5 MHz以下的目标。
   因此 :math:`f_1+f_2=0` 附近的对角留白带是分析范围造成的。
   较大的系数也可能乘上很弱的输入乘积，或来自不充分的模型。
   文献系数与电压系数没有经过相同物理归一化；数值色标相同不意味着可以直接比较绝对强弱。

   .. raw:: html

      <details class="k05-note"><summary>放大本实验的拟合区域，同时比较联合最小二乘与Kim</summary>

   .. figure:: /_static/K_Diagnostics/k05-compare-coupling-local.svg
      :width: 100%
      :alt: 正负20 MHz内的联合最小二乘和Kim系数图，两图使用覆盖全部有限值的同一局部对数色标。

      局部色标覆盖两幅实验结果中全部有限值。只调整显示，不改变系数或波对集合。

   先比较结构位置是否在两种估计中都存在，再考虑解释。
   Kim图不等于已经验证的无噪声结果：下面按目标频率做的必要条件检查，
   同时约束该目标和频对应的一整条对角线上的系数。

   .. raw:: html

      </details>

   .. rubric:: 6．对照图3(b)：补上相位，才能算有正负的贡献

   从系数图走到转移曲线，需要把每个复系数乘以对应的复双谱矩，去掉相同的参考相位，
   取实部，再对波对求和。具体写成

   .. k05:equation:: rates-pair-contribution
      :lang: zh

      B_{fj}^{\rm test}=\langle Z_jX_f^*\rangle_{\rm test},\qquad
      t_{fj}=\frac{2\operatorname{Re}(e^{-i\delta_f}Q_{fj}B_{fj}^{\rm test})}{P_X},\qquad
      t_f=\sum_j t_{fj}.

   同样大小的 :math:`|Q_{fj}|` 可以给出正或负的 :math:`t_{fj}`，因为乘积的相位也参与决定实部。
   求和得到 :math:`t_f=\sum_jt_{fj}`。这里的双谱矩全部来自留出组，没有重复使用训练组的矩。

   .. container:: k05-paper-match

      **文献[1]式(6)，保留原符号：**

      .. k05:equation:: rates-paper-transfer
         :lang: zh

         T_f=(v_{g(y)}/\Delta y)\operatorname{Re}\left[
          \sum_{f=f_1+f_2}e^{-i\Delta\Theta_f}Q_f^{1,2}X_{f_1}X_{f_2}X_f^*\right].

      把三重乘积替换为集合平均，就是我们的 :math:`B_{fj}^{\rm test}`。
      合并后的波对必须和合并后的 :math:`Q_{fj}` 配套使用，避免重复计数。
      文献所印表达式对应我们的 :math:`T_f^{(1/2)}`；对于这里明确定义的均方
      :math:`P_X`，完整一阶二次功率变化率包含 :math:`2T_f^{(1/2)}`。
      这个因子与幅值增长率的定义要分开。

   .. figure:: /_static/K_Diagnostics/k05-compare-transfer.svg
      :width: 100%
      :alt: 文献有符号转移曲线的近似重绘与本实验条件性电压转移结果，使用相同的文献坐标范围。

      图5．对照文献[1]图3(b)。共同的±4×10⁷数值量程使我们的V²/s结果看起来几乎是一条零线。
      两边单位与归一化不同，外观高度比没有直接的物理意义。

   文献中，5–10 MHz附近的负转移与约2 MHz以下的正转移，结合增长和阻尼结果，
   支持饱和态下从高频不稳定性模态向低频模态的转移。
   这是统计解释，不是拍到了一个波沿频率轴移动的动画。

   四轮均值的实际半功率范围约为：联合LS −0.119到+3.164 V²/s，Kim −6.268到+7.223 V²/s。
   右图“近似零线”的外观是量程造成的，实际正负与大小应打开局部图查看。
   即使出现正负转换或差频亮带，也不能单凭它们确认相同的逆级联（inverse cascade）：
   还需要测量响应、传播、局部小步长和平稳性等假设成立。

   .. raw:: html

      <details class="k05-note"><summary>分别查看5 MHz以下和5–20 MHz的实际数值，避免弱频段被压扁</summary>

   .. figure:: /_static/K_Diagnostics/k05-compare-transfer-local.svg
      :width: 100%
      :alt: 分别展示低于5 MHz与5到20 MHz的条件性半功率速率，以及不依赖速度的无量纲跨距贡献。

      上排：使用假设速度的 :math:`T_f^{(1/2)}`；下排：不需要群速度的 :math:`t_f`。
      每列采用适合的纵轴范围，输入频带始终统一为20 MHz。阴影是四轮结果范围。

   下排最直接反映模型给出的跨探针有符号变化；上排还乘了目标频点的输入功率和假设的逆传播时间。
   因此，一个很弱的高频目标即使有较大的相对贡献，也不一定对应很大的V²/s数值。
   两种实验估计都有正负交替，但大小乃至部分符号并不一致，例如约1.5–2 MHz的正负结构明显依赖估计方法。
   这不能说已经复现了文献的转移模式。改变正的假设速度会缩放上排，却不能改变符号，也不能修复Kim必要条件的失败。

   .. raw:: html

      </details>

   .. rubric:: 7．这些对照结果，哪些可以信到什么程度

   四轮整组留出检验能独立检查预测，却不能独立校准物理解释。
   扩展分析中，每个目标包含204–403个二次乘积，每轮有14646个训练短段、4882个测试短段。
   使用训练列RMS缩放后检查秩和条件数，保留全部频点及数值审计。

   1596次联合拟合全部满秩，缩放后最大条件数为68.55。
   5–20 MHz内，二次输入使四轮留出总均方误差降低 **7.84%–7.96%**。
   分母是仅线性模型的残差，不是总波动功率。先在每个频段内加总残差功率，再计算相对降低比例，得到：

   .. list-table:: 统一20 MHz输入基底下的留出误差降低
      :header-rows: 1
      :widths: 35 35 30

      * - 目标频段
        - 四轮改善范围
        - 四轮全部通过Kim条件
      * - 0.5–5 MHz
        - 0.30%–0.86%
        - 7 / 92个频点
      * - 5–10 MHz
        - 10.66%–10.88%
        - 41 / 102个频点
      * - 10–15 MHz
        - 0.92%–1.20%
        - 73 / 103个频点
      * - 15–20 MHz
        - 1.46%–1.64%
        - 78 / 102个频点

   总计399个目标中，**199个** 在四轮都通过Kim必要界限；高频307个目标中有192个通过。
   通过只是必要条件，不是充分验证，仍要分别检查预测能力和测量解释。

   图6中的 :math:`C_{XY}^2=|\langle Y_fX_f^*\rangle_{\rm train}|^2/(P_X^{\rm train}P_Y^{\rm train})`
   是平方相干度；两个训练功率分别是训练组对应系数的模平方平均，:math:`P_*` 是Kim给出的共同信号功率。
   留出误差为 :math:`\epsilon_f=\langle|Y_f-\widehat Y_f|^2\rangle_{\rm test}/P_Y`，
   接近1意味着误差已接近该频率直接预测零值的水平。

   .. figure:: /_static/K_Diagnostics/k05-compare-reliability.svg
      :width: 100%
      :alt: 0.5到20 MHz的训练相干度、留出预测误差、Kim共同功率比以及保留的有限步长和残差贡献。

      图6．四轮均值及范围。左上：平方相干度；右上：归一化均方预测误差（NMSE，越小越好）。
      左下：Kim共同功率比需要在0到1之间；右下：联合最小二乘的归一化二次、有限步长和残差贡献。

   这里 :math:`s_f=\langle|H_f|^2\rangle_{\rm test}/P_X` 是有限步长增量的平方贡献，
   :math:`r_f=\langle|R_f|^2\rangle_{\rm test}/P_X` 是残差贡献；完整收支中两者都保留。

   低相干意味着两处记录共享的同频线性信息较少。二次项仍可能改善预测，但不能重建独立噪声，
   也不能恢复所有在空间上已失去关联的波动。这解释了为什么增加二次项后，
   高频预测功率仍不一定能与测量谱重合。

   **拟合矩阵满秩，不等于物理解释成立。** 共同功率比超过1，意味着Kim的一项必要条件失败。
   此时画出的Kim速率只是代数结果，不能当作已接受的去噪增长率或转移率。
   联合最小二乘预测电压时不要求这个界限，但这并不让它自动消除输入噪声，或自动成为可靠的物理增长估计。
   四轮范围只反映记录之间的离散，不包含速度、通道响应与模型选择的不确定性。

   有限步长贡献也不能忽略：线性项和有符号二次项不是全部实测功率差。
   尤其当二次贡献很小时，不能保留它，却悄悄丢掉一个更大的有限步长修正。

   .. raw:: html

      <details class="k05-note"><summary>保留完整功率收支，检查两项近似漏掉了什么</summary>

   由 :k05:eq:`rates-rotated-model`，定义

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

   :math:`s_f` 保留完整模型增量的平方，其中包含 :math:`|N_f|^2`；
   :math:`r_f` 是残差功率，:math:`c_f` 是有正负的预测—残差交叉项，在留出组上不必为零。
   五项均无量纲，满足准确恒等式

   .. k05:equation:: rates-exact-balance
      :lang: zh

      D_f\equiv\frac{P_Y-P_X}{P_X}=g_f+t_f+s_f+r_f+c_f.

   先展开模平方，再取平均即可得到：

   .. k05:equation:: rates-expand-square
      :lang: zh

      \begin{aligned}
      |X+H+R|^2&=|X|^2+2\operatorname{Re}(X^*H)+|H|^2
                   +|R|^2+2\operatorname{Re}[(X+H)^*R],\\
      \langle X^*H\rangle&=\ell P_X+\langle X^*N\rangle .
      \end{aligned}

   将同一恒等式除以假设传播时间，得到

   .. k05:equation:: rates-rate-balance
      :lang: zh

      \frac{D_f}{\tau_f}
      =2\gamma_{y,\mathrm{app}}+\frac{2T_f^{(1/2)}}{P_X}
       +\frac{s_f+r_f+c_f}{\tau_f}.

   收支对得上是代数核对，不是证明只保留两个速率的连续物理模型已经充分。
   实测变化还包含有限步长和残差项；这里也不是一个守恒的等离子体能量收支。

   .. raw:: html

      </details>

   至此，**保留频带内的测量电压模型** 已形成闭合的计算链：
   记录→统计量→系数→有符号跨距贡献→条件性变化率。
   定量EDI或逆级联结论仍需要有依据的传播方向与色散分支、通道／探针响应，以及测量信号与波变量的关系。
   :ref:`探针响应补充页 <k05-response-zh>` 继续检查这条测量链；
   :ref:`色散与对照补充页 <k05-comparison-zh>` 保留较窄的5 MHz输入情景，其数值不能与本页扩展拟合混用。

   .. raw:: html

      <details class="k05-note"><summary>复现扩展拟合和逐项对照图</summary>

   .. code-block:: bash

      OPENBLAS_NUM_THREADS=2 python K_Diagnostics/K05_bispectral_transfer/analyze_extended_comparison.py \
        --data /path/to/raw-captures --output /path/to/new-extended-results
      python K_Diagnostics/K05_bispectral_transfer/plot_extended_comparison.py \
        --extended /path/to/new-extended-results \
        --comparison /path/to/z5p5_a3p7_paper_comparison \
        --output /path/to/new-comparison-plots

   第一个脚本保存系数、波对、矩、功率、留出误差、秩／条件数、Kim检查、配置和哈希。
   先对增广训练矩阵做QR压缩，保留包括目标残差功率在内的全部内积，再使用既有的SVD／Kim求解器；
   测试核对了它与未压缩计算的一致性。没有把留出记录的短段随机分到训练集。
   第二个脚本读取这些结果及此前保存的色散分支／PSD。
   ``reference_digitization`` 保存文献图像读数及来源，重新绘图不需要嵌入文献原图。

   .. raw:: html

      </details>

   .. rubric:: 参考文献

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.
   来源图形©2023 American Physical Society；本页文献面板是注明来源的图像近似重绘，不是作者提供的原始数据。
