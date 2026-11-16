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
   explained on page 07. A Kim target is shown only when every fold is identifiable
   and passes :math:`0\le P_*\le\min(P_X^{\rm train},P_Y^{\rm train})`.
   If any fold fails, all four Kim values at that target are masked in result plots;
   passing folds are never selectively averaged. Blank intervals are not zeros.

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

   .. rubric:: 2. Figure 2(a): build the physical scenario before converting rates

   A fitted multiplier describes a change between positions. A rate describes a
   change per second. We need a propagation model to connect them. Start with the
   reported slow-scan electron temperature :math:`T_e=9.1689` eV, the prescribed
   density :math:`n_0=2.2\times10^{16}` m⁻³, and cold, singly charged xenon ions.
   The measured magnetic component magnitudes are :math:`B_r=39.48` G radially and
   :math:`B_x=80.34` G axially, giving :math:`B=89.52` G. The resulting Debye length
   is 0.152 mm, ion sound speed 2.60 km/s, and ion plasma frequency 2.72 MHz.
   The temperature is used as a local Maxwellian proxy; the slow scan is not a
   simultaneous measurement of the fluctuating electron distribution.

   **Ion energy fixes a speed, but not a unique local electric field.** Assume the
   ions have gained half of the energy available from the 200 V discharge at this
   location. Neglect injection energy and collisions in this estimate. Introduce
   an effective acceleration length :math:`L_E=1` cm.
   This is an estimated length, not the probe separation or a measured field profile.

   .. k05:equation:: rates-energy-field-drift
      :lang: en

      \begin{aligned}
      U_i&=\eta U_d=0.5\times200\ \mathrm{V}=100\ \mathrm{V},\\
      u_i&=\sqrt{2eU_i/m_i}=12.12\ \mathrm{km/s},\\
      E_x&\simeq U_i/L_E=10.0\ \mathrm{kV/m},\\
      V_d&=\frac{|E_xB_r|}{B_x^2+B_r^2}=492.7\ \mathrm{km/s}.
      \end{aligned}

   Here :math:`U_d` is discharge voltage, :math:`\eta` the assumed gained-energy
   fraction, :math:`U_i` its equivalent accelerating potential drop, :math:`e` the
   elementary charge and :math:`m_i` the Xe⁺ mass. :math:`u_i` is axial ion speed;
   :math:`E_x` is the average accelerating field used as a local proxy. :math:`V_d`
   is the magnitude of the electron :math:`E\times B` drift. The full vector relation
   is :math:`\mathbf v_E=\mathbf E\times\mathbf B/B^2`; with a tilted magnetic field,
   substituting :math:`E_x/B` would give the wrong azimuthal component.
   Parallel electron bulk flow, pressure-gradient drifts and collisions remain outside this local model.

   The wavelength **along the magnetic field** is set to 1 cm. Thus
   :math:`k_\parallel=2\pi/0.01=628.3` m⁻¹ and
   :math:`k_\parallel\lambda_{De}=0.09536`; it is not the distance between the probes.
   One geometric choice is still missing: the perpendicular wavevector need not
   point entirely along the azimuthal direction. We use a **15° perpendicular-plane
   tilt as an unmeasured scenario**. This is not a fitted angle and is not the
   axial angle used in [1].

   .. figure:: /_static/K_Diagnostics/k05-compare-dispersion.svg
      :width: 100%
      :alt: Reference dispersion redraw and the moving cold-ion scenario on the reference axis ranges.

      Figure 1. Counterparts of [1], Figure 2(a). Left: approximate redraw.
      Right: the selected cold-ion branch, including axial ion advection.

   Over the calculated range :math:`k_y=10`–100000 m⁻¹, the selected branch covers
   **1.349–26.607 MHz**, including 5–20 MHz. Only its part within the common frame
   appears above. This coverage follows the chosen ion speed and wavevector
   geometry; it is not evidence that this branch has been identified experimentally.
   The source ordinate is labeled
   :math:`\omega_k` in Hz, whereas our ordinate is explicitly
   :math:`f=\omega_r/(2\pi)`. Until that source convention is resolved, its digitized
   slope must not be used to infer a quantitative speed ratio.

   .. _k05-rates-group-velocity-en:

   The conversion uses the calculated azimuthal group velocity (wave-envelope
   propagation speed) :math:`v_{g,y}(f)`, in m/s, with the other wavevector components
   held fixed. The positive model direction is provisionally assigned from C1 to C3.
   The selected branch supports **382 of 399** fitted targets; rates below about
   1.35 MHz remain blank, while their velocity-independent coefficients and
   across-gap contributions remain available. Channel/probe response and the
   branch identification remain independent conditions for a physical interpretation.

   .. rubric:: 3. Figure 2(b): compare the measured spectral features

   The spectrum uses the same records as page 06. Average the squared windowed
   Fourier coefficients, then convert to the one-sided, Hann-corrected power
   spectral density (PSD). Here the preserved Welch result uses 16384 samples per
   segment for finer spectral resolution; it is not the 2048-point coefficient fit.
   See :ref:`page 06 <k05-experiment-en>` for the processing and normalization.

   .. figure:: /_static/K_Diagnostics/k05-compare-spectra.svg
      :width: 100%
      :alt: Approximate source spectra and the four-record mean C1 and C3 nominal current PSD with common frequency ranges.

      Figure 2. Counterparts of [1], Figure 2(b). Our spectrum extends to the
      50 MHz Nyquist frequency; the remaining reference frame is left empty.

   In the paper, the broad low-frequency component coexists with several
   high-frequency resonances separated by roughly 7 MHz. The authors interpret
   them in the context of prior EDI measurements. In our panel, inspect the
   falling broadband level and differences between C1 and C3. The spectrum itself
   does not say which frequency supplies energy to another.
   Both panels use frequency in Hz. The source labels its spectrum Hz⁻¹; our
   panel uses nominal current PSD in mA²/Hz and its own vertical range. Both probes
   use the same 1 kΩ conversion, preserving their amplitude ratio without peak or
   RMS matching. A unit label alone does not specify the source normalization.

   .. raw:: html

      <details class="k05-note"><summary>Which units can be unified without inventing a normalization?</summary>

   Let :math:`a_I=1/R` in A/V, with :math:`R=1000\ \Omega`. Superscript :math:`I`
   denotes nominal current. A common constant gain gives

   .. k05:equation:: rates-current-conversion
      :lang: en

      \begin{aligned}
      X_f^I&=a_I X_f,\quad Y_f^I=a_I Y_f,\quad L_f^I=L_f,\quad Q_{fj}^I=Q_{fj}/a_I,\\
      S_I^+&=a_I^2 S_V^+,\quad P_X^I=a_I^2P_X,\quad
      T_{I,f}^{(1/2)}=a_I^2T_f^{(1/2)},\\
      \gamma_{y,\mathrm{app}}^I&=\gamma_{y,\mathrm{app}},\qquad
      T_{I,f}^{(1/2)}/P_X^I=T_f^{(1/2)}/P_X.
      \end{aligned}

   Substitute :math:`X^I=a_I X` and :math:`Y^I=a_I Y` into the same prediction to
   obtain these relations. SI units are A² for power, A²/Hz for its PSD, A⁻¹ for
   :math:`Q^I`, and A²/s for :math:`T_I`. For readable numbers, figures use mA,
   mA² and mA⁻¹: 1 V across 1 kΩ corresponds to 1 mA. The original symbols
   :math:`X,Y,Q,T` in the text remain in voltage units, connecting to page 07.
   This nominal conversion is not a measured MHz amplitude/phase calibration.

   Frequencies and growth rates share Hz and s⁻¹ with the reference. Absolute
   source :math:`Q,T` amplitudes still lack a verified common normalization;
   Figure 3(b) does not label a unit for :math:`T_f`. A relative signal
   :math:`\delta I/I_0` could give a PSD in Hz⁻¹, but needs a trustworthy mean
   ion current and response. The prescribed density alone does not provide them.
   We do not assign our current units to the source or normalize each probe by
   its own RMS to force agreement.

   .. raw:: html

      </details>

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
      half-power convention, not a square root. Substitute the computed azimuthal
      group velocity on the supported branch. Figures show its nominal current
      counterpart :math:`T_{I,f}^{(1/2)}` in mA²/s.

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
      :alt: Source growth-rate redraw and joint-LS/filtered-Kim rates using computed azimuthal group velocity; separate right axes show theoretical growth.

      Figure 3. Counterparts of [1], Figure 2(c), using the source axis limits.
      Left axes: diagnosed/apparent rates. Right axes: theoretical rates, with
      a ten-times-larger range. Triangles at the lower/upper edge mark means outside the frame.
      Kim gaps remove targets failing the necessary bound in any fold; other gaps
      indicate unsupported branch frequencies. Shading is the four-fold range,
      not a confidence interval. All rate axes use s⁻¹; note their multipliers.

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

   **When LS and Kim disagree, distinguish prediction from physical inference.**
   For predicting observed records, use held-out errors instead of assuming a
   correction must improve the result. Even among the 78 targets in 15–20 MHz
   passing the Kim bound in all folds, the equal-frequency, four-fold mean NMSE
   is about 0.86 for joint LS and 2.07 for Kim. Above one is worse than predicting
   zero. This prediction evidence favors joint LS. Retained Kim points have passed
   a necessary check, not a validation of their physical interpretation.

   Neither estimator automatically gives the latent plasma coefficients. LS can
   suffer input-noise bias; Kim depends on stationary signal power and its
   noise/moment assumptions. Their disagreement is model uncertainty, not an
   error bar to average away. Physical preference requires supported measurement
   response and signal/noise assumptions, beyond the prediction score.

   .. raw:: html

      <details class="k05-note"><summary>Show the apparent rates on their own scale, including clipped values</summary>

   .. figure:: /_static/K_Diagnostics/k05-compare-growth-local.svg
      :width: 100%
      :alt: All four-fold mean apparent growth values on local axes with the same coefficients and assumed speed.

      Same numbers and time scale as Figure 3; only the plotting limits change.

   Inspect the signed values, disagreement between estimators, and fold spread.
   The extra visibility is not extra physical validation. The theoretical curve
   retains its own axis and ends at the computed branch limit; no extrapolation
   supplies any displayed frequency-dependent speed.

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
      :alt: Image-derived source coupling map and our joint-LS current coefficient magnitude map, with matching plus/minus 50 MHz limits and log color ranges.

      Figure 4. Counterparts of [1], Figure 3(a), with color range −2 to 1.
      Right: joint-LS :math:`\log_{10}(|Q_I^{\rm sym}|/(\mathrm{mA}^{-1}))`.
      White means not fitted, not zero coupling. Extreme colors include values
      beyond the limits. Filtered Kim results appear in the local comparison.

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
   The source and our nominal-current coefficients do not share a demonstrated
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
   check applies to its entire diagonal of pairs with that target sum. Any fold
   failing removes that target diagonal and its conjugate counterpart from the
   displayed map. These gaps are not evidence for zero coupling.

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
      :alt: Approximate source transfer and nominal-current transfer, sharing the frequency range with separately labeled vertical scales.

      Figure 5. Counterparts of [1], Figure 3(b), with frequency in Hz on both sides.
      The source keeps its published vertical range; the right panel displays
      nominal current :math:`T_{I,f}^{(1/2)}` on a readable scale. The unresolved
      source normalization prevents a common absolute-amplitude scale.

   In the paper, negative transfer around 5–10 MHz and positive transfer below
   about 2 MHz, considered together with growth and damping, support transfer
   from higher-frequency instability modes toward lower-frequency modes in the
   saturated state. This is a statistical interpretation, not a time-lapse
   movie of a wave moving through frequency.

   On supported frequencies, the joint-LS four-fold mean spans approximately
   −0.1125 to +0.1379 mA²/s; retained Kim means span −0.0243 to +0.00872 mA²/s.
   These numbers depend on the stated normalization and group velocity. No rate
   is supplied below the selected branch's 1.35 MHz limit. The remaining sign
   pattern alone cannot establish the same inverse cascade without measurement,
   propagation, local-step and stationarity conditions.

   .. raw:: html

      <details class="k05-note"><summary>Read the actual values below and above 5 MHz, without hiding the smaller band</summary>

   .. figure:: /_static/K_Diagnostics/k05-compare-transfer-local.svg
      :width: 100%
      :alt: Separate local views below 5 MHz and from 5 to 20 MHz, showing conditional half-power rates and dimensionless across-gap quadratic contributions.

      Top: :math:`T_{I,f}^{(1/2)}` with computed :math:`v_{g,y}(f)`. Bottom: :math:`t_f`, which
      needs no velocity. Each column has a suitable vertical range; the 20 MHz
      input basis is unchanged throughout. Shading is the four-fold range.

   The lower row is the most direct place to compare the signed modeled change
   between probes. The upper row additionally weights it by the target's input
   power and the assumed inverse travel time. Thus a large fractional effect at
   a weak high-frequency target need not produce a large mA²/s value.
   Small high-frequency rates also reflect this branch's small azimuthal group
   velocity, not vanishing across-gap contributions. Kim failures are masked in
   both rows. A different positive velocity rescales the rate but cannot repair
   a failed Kim condition or reverse a given contribution's sign.

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
   corresponding Kim results are removed from the result curves and maps. Only
   this diagnostic panel retains failed ratios to explain the missing regions. Joint LS does not require this bound to predict voltages,
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
      python K_Diagnostics/K05_bispectral_transfer/analyze_physical_scenario.py \
        --extended /path/to/new-extended-results --output /path/to/new-physical-results
      python K_Diagnostics/K05_bispectral_transfer/plot_physical_comparison.py \
        --extended /path/to/new-extended-results \
        --comparison /path/to/z5p5_a3p7_paper_comparison \
        --physical /path/to/new-physical-results --output /path/to/new-comparison-plots

   The first script saves coefficients, pairs, moments, powers, holdout errors,
   rank/conditioning, Kim checks, configuration and hashes. QR compression of the
   augmented training matrix preserves all inner products, including target
   residual power, before the existing SVD/Kim solve. Tests compare it with the
   uncompressed calculation. No random split mixes segments from a held-out record
   into training. The physical-scenario script reuses the fits and computes moving-ion
   branches from ``physical_scenario_config.json``. The plotter reads the new branches
   and preserved PSD; no re-fitting is needed for these physical scenarios. The source-derived reference readings and provenance are in
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
   “Kim”表示第07页的平稳性修正。只有四轮拟合都可辨识，且都满足
   :math:`0\le P_*\le\min(P_X^{\rm train},P_Y^{\rm train})`，才显示该目标的Kim结果。
   任一轮失败，结果图将该目标的四轮全部留白，不只挑通过的轮次求平均。留白不等于零。

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

   .. rubric:: 2．对照图2(a)：先建立物理情景，再换算时间

   拟合乘数描述 **两处之间** 的变化，速率描述 **每秒** 的变化，因此还需要传播模型。
   先固定慢扫描报告的电子温度 :math:`T_e=9.1689` eV、给定密度
   :math:`n_0=2.2\times10^{16}` m⁻³，离子采用单电荷Xe⁺并保持冷离子近似。
   已报告的径向、轴向磁场分量大小分别为 :math:`B_r=39.48` G、:math:`B_x=80.34` G，
   合成磁场约89.52 G。相应德拜长度为0.152 mm、离子声速为2.60 km/s、离子等离子体频率为2.72 MHz。
   温度作为局部Maxwell分布的参数；慢扫描并不等于同时测到了高频记录期间的电子分布。

   **离子能量可以确定速度，但不能单独确定局部电场。** 这里假设离子在测量位置已获得200 V放电
   所能提供能量的一半，忽略初始动能和这一步估计中的碰撞损失。
   再取有效加速长度 :math:`L_E=1` cm。
   这是明确的长度估计，不是探针间距，也不是已测出的电场分布。

   .. k05:equation:: rates-energy-field-drift
      :lang: zh

      \begin{aligned}
      U_i&=\eta U_d=0.5\times200\ \mathrm{V}=100\ \mathrm{V},\\
      u_i&=\sqrt{2eU_i/m_i}=12.12\ \mathrm{km/s},\\
      E_x&\simeq U_i/L_E=10.0\ \mathrm{kV/m},\\
      V_d&=\frac{|E_xB_r|}{B_x^2+B_r^2}=492.7\ \mathrm{km/s}.
      \end{aligned}

   :math:`U_d` 是放电电压；:math:`\eta` 是已获得能量占比；:math:`U_i` 是对应的加速电势差；
   :math:`e` 是元电荷；:math:`m_i` 是Xe⁺质量。:math:`u_i` 是轴向离子速度；
   :math:`E_x` 是用来近似局部场的平均加速电场；:math:`V_d` 是电子 :math:`E\times B` 漂移速度大小。
   完整矢量关系是 :math:`\mathbf v_E=\mathbf E\times\mathbf B/B^2`。
   磁场有倾斜，因此不能直接用 :math:`E_x/B` 代替周向分量。
   本局部模型仍未包含电子沿磁场的平均流动、压力梯度漂移和碰撞。

   **沿磁场的波长** 取1 cm，因此 :math:`k_\parallel=2\pi/0.01=628.3` m⁻¹，
   :math:`k_\parallel\lambda_{De}=0.09536`；这不是两支探针之间的距离。
   波矢还缺少一个几何信息：垂直磁场的分量是否完全沿周向。
   这里选取 **垂直磁场平面内偏离周向15°** 作为未测量的几何情景。
   这个角度没有从数据拟合，也不等同于文献[1]的轴向传播角度。

   .. figure:: /_static/K_Diagnostics/k05-compare-dispersion.svg
      :width: 100%
      :alt: 文献色散近似重绘与包含轴向离子流的冷离子情景，沿用原图坐标范围。

      图1．对照文献[1]图2(a)。左：文献近似重绘。右：包含轴向离子对流的所选冷离子分支。

   在计算的 :math:`k_y=10`–100000 m⁻¹范围内，所选分支覆盖 **1.349–26.607 MHz**，
   已包含5–20 MHz；上图只显示落在共同图框内的部分。
   这一覆盖范围来自所选的离子速度和波矢几何，不表示已经在实验中识别出这一分支。
   原文纵轴标为 :math:`\omega_k`、单位Hz，这里明确使用 :math:`f=\omega_r/(2\pi)`。
   原图约定未核清之前，不能从描点斜率定量判断两种实验的波速比。

   .. _k05-rates-group-velocity-zh:

   后面使用计算得到的周向群速度（group velocity） :math:`v_{g,y}(f)`，单位m/s，
   表示波包包络沿周向的传播速度；计算时保持其他波矢分量不变。
   模型正方向暂对应C1到C3；所选分支支持399个拟合目标中的 **382个**。
   低于约1.35 MHz的速率留白，但不依赖速度的系数与跨距贡献仍保留。
   通道／探针响应、传播方向以及分支识别，仍需单独满足物理解释条件。

   .. rubric:: 3．对照图2(b)：先比较测量谱中有哪些结构

   功率谱继续使用第06页的同一批记录：对加窗后的Fourier系数模平方取平均，
   再按单边谱和Hann窗归一化得到功率谱密度（power spectral density, PSD）。
   这里保留的Welch结果使用每段16384点，提供较细的谱分辨率；
   它不同于拟合系数时的2048点分段。具体处理与归一化见 :ref:`第06页 <k05-experiment-zh>`。

   .. figure:: /_static/K_Diagnostics/k05-compare-spectra.svg
      :width: 100%
      :alt: 文献功率谱近似重绘与C1、C3四组平均标称电流功率谱，频率范围相同。

      图2．对照文献[1]图2(b)。本实验谱覆盖到50 MHz奈奎斯特频率，文献图框中其余区域留白。

   文献中，低频宽带成分与多个高频共振峰同时出现，峰间隔约为7 MHz。
   作者结合先前的EDI测量研究解释这些峰。我们的右图首先应看随频率下降的宽带背景，以及C1、C3的差异；
   **功率谱本身不能告诉我们哪个频率向哪个频率输送能量。**
   两边频率统一为Hz。文献谱标为Hz⁻¹，本实验改画标称电流谱，单位mA²/Hz，并采用适合的纵轴范围。
   两路都使用同一个1 kΩ电阻值换算，因此保留原有幅值比例，不按峰值或RMS对齐。
   单位标签本身还不能确定文献信号的归一化。

   .. raw:: html

      <details class="k05-note"><summary>哪些单位可以统一？哪些还缺少归一化信息？</summary>

   令 :math:`a_I=1/R`，单位A/V，:math:`R=1000\ \Omega`；上标 :math:`I` 表示标称电流形式。
   对两路使用同一个常数换算系数，有

   .. k05:equation:: rates-current-conversion
      :lang: zh

      \begin{aligned}
      X_f^I&=a_I X_f,\quad Y_f^I=a_I Y_f,\quad L_f^I=L_f,\quad Q_{fj}^I=Q_{fj}/a_I,\\
      S_I^+&=a_I^2 S_V^+,\quad P_X^I=a_I^2P_X,\quad
      T_{I,f}^{(1/2)}=a_I^2T_f^{(1/2)},\\
      \gamma_{y,\mathrm{app}}^I&=\gamma_{y,\mathrm{app}},\qquad
      T_{I,f}^{(1/2)}/P_X^I=T_f^{(1/2)}/P_X.
      \end{aligned}

   把 :math:`X^I=a_I X`、:math:`Y^I=a_I Y` 代入原预测式就得到这些关系。
   SI单位下，电流功率为A²、PSD为A²/Hz、:math:`Q^I` 为A⁻¹、:math:`T_I` 为A²/s。
   图中使用mA、mA²及mA⁻¹方便读数；1 kΩ电阻上的1 V对应1 mA。
   正文原有 :math:`X,Y,Q,T` 仍沿用电压形式，便于与第07页衔接。
   这只是标称电阻换算，并未校准MHz频段的幅值与相位响应。

   频率与增长率已经和文献统一为Hz、s⁻¹。
   文献 :math:`Q,T` 的绝对幅值仍缺少已核实的共同归一化，图3(b)也没有明示 :math:`T_f` 的单位。
   使用 :math:`\delta I/I_0` 可以得到Hz⁻¹的谱，但需要可靠的平均离子电流和测量响应；
   仅给定密度不能补齐这一步标定。因此不把原图纵轴直接重标为本实验电流单位，
   也不把两支探针各自除以RMS来强行对齐。

   .. raw:: html

      </details>

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
      在分支支持的频点代入随频率改变的周向群速度；图中显示标称电流形式
      :math:`T_{I,f}^{(1/2)}`，单位mA²/s。

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
      :alt: 文献增长率近似重绘与计算周向群速度下的联合最小二乘和筛选后Kim表观增长率，理论增长使用独立右轴。

      图3．对照文献[1]图2(c)，沿用原图范围。左轴：诊断／表观增长率；右轴：理论增长率，量程大十倍。
      下／上边缘三角形标出超出图框范围的均值。Kim留白去掉任一轮未通过必要条件的目标；
      分支不覆盖的频率也留白。阴影是四轮范围，不是置信区间；各速率轴均为s⁻¹，注意倍率。

   文献中的主要诊断增长峰在约7 MHz附近，频率结构与理论有相似之处，但数值约小一个数量级。
   两套纵轴会让相近的曲线高度看起来比数值更接近，读图时必须分开看。
   文献也把低频的一段负增长解释为阻尼。

   我们的两条曲线是 **同一类系数的两种估计**：联合最小二乘与Kim修正。
   点线理论曲线来自独立的动力学计算，仅覆盖已有分支，不是对表观增长曲线的拟合。
   负的表观增长还可能包含空间失相关、输入噪声、两路响应不同等影响，不能直接等同于等离子体阻尼。
   本次扩展保留5–20 MHz，不因相干度低就删除拟合。

   **最小二乘与Kim分歧很大时，先区分要相信哪一件事。**
   若问题是“谁能更好预测另一支探针实际记录的信号”，应比较留出误差，不能因为叫“修正”就优先相信它。
   即使只看15–20 MHz内四轮都通过Kim界限的78个频点，按频点等权、再对四轮平均，
   联合最小二乘的NMSE约为0.86，Kim约为2.07；大于1意味着比直接预测零值还差。
   当前预测证据因此支持优先使用联合最小二乘，保留的Kim只通过了必要检查。

   若问题是“谁更接近真实等离子体的系数”，则不能只凭预测比较裁定：
   最小二乘会受输入噪声偏差影响；Kim依赖真实信号功率平稳及相应噪声／统计矩假设。
   两者分歧是模型不确定性，不能平均成一个“更可靠”的答案。
   响应标定和信号／噪声假设得到支持后，才有依据优先接受其中一种物理解释。

   .. raw:: html

      <details class="k05-note"><summary>使用本实验的量程，看清被原图范围截去的增长率</summary>

   .. figure:: /_static/K_Diagnostics/k05-compare-growth-local.svg
      :width: 100%
      :alt: 同一组表观增长率改用本实验适合的量程，保留全部四轮均值及范围。

      数值与时间尺度和图3相同，只改变显示范围。

   看清实际正负、两种估计之间的差别和四轮离散程度，但不能把“看得清”当作物理验证。
   理论曲线仍使用独立纵轴，并在计算分支上限停止；用于换算的速度均来自已求出的根，不外推。

   .. raw:: html

      </details>

   .. rubric:: 5．对照图3(a)：哪些波对的二次系数较大

   每个波对都有一个系数，将其模放在 :math:`(f_1,f_2)` 平面中，目标频率就是
   :math:`f=f_1+f_2`。拟合中交换顺序后的同一个乘积只计一次；
   画成对称的有序波对图时，非对角线系数平分给两个交换位置，对角线系数不变。
   负目标频率由共轭重建，不是独立拟合。颜色表示四轮系数模平均值的对数。

   .. figure:: /_static/K_Diagnostics/k05-compare-coupling.svg
      :width: 100%
      :alt: 文献系数热图的图像近似重绘与本实验联合最小二乘标称电流系数模，坐标统一到正负50 MHz，对数色标统一为负2到1。

      图4．对照文献[1]图3(a)，色标统一为−2到1。右图是
      联合最小二乘的 :math:`\log_{10}(|Q_I^{\rm sym}|/(\mathrm{mA}^{-1}))`。
      白色表示未拟合，不表示耦合为零；最暗／最亮颜色也包括超出色标的值。
      筛去不合格目标后的Kim图放在下面的局部对照中。

   文献热图在异号象限、接近 :math:`f_1+f_2=0` 的亮结构，表示两个较大且几乎互相抵消的输入频率
   对应一个较低的目标频率，这是 **差频组合（difference-frequency pair）** 的几何关系。
   它提示我们接下来检查向低频的转移，但亮度本身既不给出转移方向，也不能证明这条波对正在输送能量。
   作者还指出一条较高和频位置的结构可能与噪声有关。

   本实验有数据的区域较小，因为输入与目标都限制在20 MHz内，且不拟合0.5 MHz以下的目标。
   因此 :math:`f_1+f_2=0` 附近的对角留白带是分析范围造成的。
   较大的系数也可能乘上很弱的输入乘积，或来自不充分的模型。
   本实验按 :k05:eq:`rates-current-conversion` 换算标称电流单位；
   原图幅值归一化尚未核实，数值色标相同不能直接比较绝对强弱。

   .. raw:: html

      <details class="k05-note"><summary>放大本实验的拟合区域，同时比较联合最小二乘与Kim</summary>

   .. figure:: /_static/K_Diagnostics/k05-compare-coupling-local.svg
      :width: 100%
      :alt: 正负20 MHz内的联合最小二乘和Kim系数图，两图使用覆盖全部有限值的同一局部对数色标。

      局部色标覆盖两幅实验结果中全部有限值。只调整显示，不改变系数或波对集合。

   先比较结构位置是否在两种估计中都存在，再考虑解释。
   Kim图不等于已经验证的无噪声结果：下面按目标频率做的必要条件检查，
   同时约束该目标和频对应的一整条对角线上的系数。
   任一轮失败，就将该目标整条对角线及其共轭对应区域留白；缺口不表示零耦合。

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
      :alt: 文献转移近似重绘与本实验标称电流转移，频率范围相同、纵轴分别明确标注。

      图5．对照文献[1]图3(b)，两边频率均为Hz。
      文献保留原纵轴范围，右图使用标称电流量 :math:`T_{I,f}^{(1/2)}` 及可读量程。
      原图幅值归一化尚未核实，因此不强行赋予共同的绝对幅值刻度。

   文献中，5–10 MHz附近的负转移与约2 MHz以下的正转移，结合增长和阻尼结果，
   支持饱和态下从高频不稳定性模态向低频模态的转移。
   这是统计解释，不是拍到了一个波沿频率轴移动的动画。

   在支持的频点上，联合最小二乘四轮均值约为−0.1125到+0.1379 mA²/s；
   保留的Kim均值约为−0.0243到+0.00872 mA²/s。
   这些数值依赖明确的归一化和群速度假设；所选分支低于约1.35 MHz时不提供速率。
   剩余正负结构不能单独确认文献中的逆级联，需要测量响应、传播、局部小步长和平稳性等条件支持。

   .. raw:: html

      <details class="k05-note"><summary>分别查看5 MHz以下和5–20 MHz的实际数值，避免弱频段被压扁</summary>

   .. figure:: /_static/K_Diagnostics/k05-compare-transfer-local.svg
      :width: 100%
      :alt: 分别展示低于5 MHz与5到20 MHz的条件性半功率速率，以及不依赖速度的无量纲跨距贡献。

      上排：计算群速度下的 :math:`T_{I,f}^{(1/2)}`；下排：不需要速度的 :math:`t_f`。Kim不合格目标均留白。
      每列采用适合的纵轴范围，输入频带始终统一为20 MHz。阴影是四轮结果范围。

   下排最直接反映模型给出的跨探针有符号变化；上排还乘了目标频点的输入功率和假设的逆传播时间。
   因此，一个很弱的高频目标即使有较大的相对贡献，也不一定对应很大的mA²/s数值。
   高频速率较小也受到这一分支周向群速度很小的影响，不表示跨距贡献消失。
   即使已有传播模型，Kim不合格目标仍在两排留白。
   换用另一个正速度会缩放速率，却不能修复Kim条件失败，也不能改变同一贡献的符号。

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
   对应Kim结果已从速率曲线及系数图中移除，仅在诊断面板保留失败的比值，用于解释留白原因。
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
      python K_Diagnostics/K05_bispectral_transfer/analyze_physical_scenario.py \
        --extended /path/to/new-extended-results --output /path/to/new-physical-results
      python K_Diagnostics/K05_bispectral_transfer/plot_physical_comparison.py \
        --extended /path/to/new-extended-results \
        --comparison /path/to/z5p5_a3p7_paper_comparison \
        --physical /path/to/new-physical-results --output /path/to/new-comparison-plots

   第一个脚本保存系数、波对、矩、功率、留出误差、秩／条件数、Kim检查、配置和哈希。
   先对增广训练矩阵做QR压缩，保留包括目标残差功率在内的全部内积，再使用既有的SVD／Kim求解器；
   测试核对了它与未压缩计算的一致性。没有把留出记录的短段随机分到训练集。
   物理情景脚本复用系数，按 ``physical_scenario_config.json`` 计算含离子流的分支；
   绘图脚本读取新分支与保留的PSD，不重新拟合记录。
   ``reference_digitization`` 保存文献图像读数及来源，重新绘图不需要嵌入文献原图。

   .. raw:: html

      </details>

   .. rubric:: 参考文献

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.
   来源图形©2023 American Physical Society；本页文献面板是注明来源的图像近似重绘，不是作者提供的原始数据。
