09 · Experimental counterparts of Figures 2 and 3
=================================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-comparison-en:

   .. rubric:: Put the experimental results into the form of Figures 2 and 3

   Brown and Jorns [1] connect five panels: a dispersion curve, two probe spectra,
   growth rates, a coupling-coefficient map and a signed transfer curve.
   Here are their counterparts for the four synchronized C1/C3 captures.
   Read the plots first, then follow how each quantity was calculated.
   The spectra come from measurements; the rate conversion also uses the
   explicitly estimated plasma scenario given below.

   .. rubric:: 1. Figure 2: from measured spectra to a growth-rate comparison

   .. figure:: /_static/K_Diagnostics/k05-comparison-figure2.svg
      :width: 100%
      :alt: Three panels corresponding to reference Figure 2: an illustrative kinetic dispersion, measured voltage spectra, and conditional growth rates with separate left and right axes matching the reference.

      Figure 2 counterpart. (a) An explicitly assumed kinetic scenario.
      (b) Measured voltage spectra. (c) Coefficient-based apparent rates and
      model growth, on the left and right axes respectively, as in [1].
      Axis limits and ticks follow reference Figure 2; uncovered frequencies
      remain blank. Lines and bands show four-split means and ranges, not
      confidence intervals. Fixed limits clip out-of-range values; they do
      not set those values to zero.

   **Start with panel (b): what is present in the signals?** C1 and C3 are the
   two probe channels. The vertical axis is the voltage power spectral density
   shown as :math:`P_f=S_V(f)` in μV²/Hz. The saved V²/Hz values are
   multiplied by :math:`10^{12}` solely to convert units; both channels use
   the same conversion. Unlike the 1/Hz label in [1], these remain measured
   voltage spectra, without an assumed plasma-amplitude normalization.
   A taller peak means more fluctuation power per unit frequency. We reuse the :ref:`experimental spectra <k05-experiment-en>`:
   remove each segment's mean, apply a periodic Hann window, Fourier transform,
   square the magnitude, correct the window's mean-square gain, and average.
   The plotted line averages the four captures equally. This is a one-sided
   spectrum with 16384-point segments, covering the measured frequencies up to
   50 MHz; the reference axis extends to 100 MHz, leaving 50–100 MHz blank.
   Panel (b) uses the reference's logarithmic ticks and approximately
   0.2–4000 frame limits (the endpoints are not labelled in [1]).
   The two curves share the same voltage scale; neither was rescaled to force agreement.

   The gray strip is the **0.537–4.980 MHz coefficient-fit band**, not the
   measurement bandwidth. The coefficient calculation uses 2048-point segments,
   as on :ref:`page 07 <k05-experiment-coefficients-en>`. It retains nonzero quadratic inputs
   up to 5 MHz in absolute frequency. The 5–20 MHz prediction example in the :ref:`validation supplement <k05-validation-en>` used a different input band and only one holdout; it is not silently
   combined with these four-split Kim results.

   **Panel (a) supplies a frequency-to-wave-number model.** The azimuthal wave
   number :math:`k_y` describes variation with position; its wavelength is
   :math:`2\pi/|k_y|`. A dispersion relation associates it with a frequency
   :math:`f`. The curve here is calculated from a magnetized-electron,
   cold-ion model [1, 2], using the measured temperature proxy and magnetic
   components plus the estimates in the disclosure below.
   It is not a wave-number measurement from the two probe signals.
   The reference labels its ordinate :math:`\omega_k` with Hz; our plot
   explicitly uses :math:`f=\operatorname{Re}\omega/(2\pi)`.
   Its printed label alone does not establish whether the original numerical
   ordinate was divided by :math:`2\pi`. Matching the frame is therefore not
   a verified frequency-convention match. Do not infer a measured speed ratio
   from the two plotted slopes.
   Its slope gives the azimuthal group velocity:
   :math:`v_{g,y}=2\pi\,\partial f/\partial k_y`, with other wave-vector
   components held fixed. This scenario gives about **0.32–2.49 km/s**
   across the fitted frequency band.

   **Panel (c) puts the measured coefficient onto a time scale.** At each
   frequency, the linear-plus-quadratic model supplies a complex linear
   coefficient :math:`L_f`. Blue uses least squares; orange uses the Kim
   stationary estimator. Both include quadratic terms. Define the reference
   angle :math:`\delta_f=\arg\langle Y_fX_f^*\rangle_{\rm train}` from the
   three training captures, where :math:`X_f` and :math:`Y_f` are C1 and C3
   Fourier coefficients, brackets average segments, and a star means conjugation.
   Rotate :math:`L_f` by the opposite angle and calculate

   .. k05:equation:: comparison-rate
      :lang: en

      \gamma_{y,\mathrm{app}}(f)
      =\frac{v_{g,y}(f)}{\Delta y}
       \left[\operatorname{Re}\!\left(e^{-i\delta_f}L_f\right)-1\right].

   Here :math:`\Delta y=0.0037` m, :math:`i^2=-1`, and
   :math:`\operatorname{Re}` takes the real part. The subscript “app” means
   apparent: the inferred value depends on the model and response assumptions.
   The bracket is a dimensionless amplitude increment; multiplying by
   :math:`v_{g,y}/\Delta y` gives s⁻¹. For the green dashed curve, use the
   imaginary part of the model's complex frequency, :math:`\gamma_{\rm th}`,
   and map it to :math:`f` using panel (a).

   A positive coefficient-based value is an apparent linear increase; a
   negative value is an apparent linear decrease. It does not include the
   quadratic contribution or the residual. For one concrete point,
   **2.001953 MHz with capture 2 held out**, the assumed group velocity is
   2148 m/s. The apparent rates are about **+3.08 × 10⁴ s⁻¹ (Kim)** and
   **−7.39 × 10⁴ s⁻¹ (least squares)**; the model gives **5.02 × 10⁵ s⁻¹**.
   These are one split's values, while the lines average four splits.
   As in [1], the left axis is :math:`\gamma_{f(y)}` (here our
   :math:`\gamma_{y,\mathrm{app}}`), from −0.5 to 3 × 10⁵ s⁻¹;
   the right axis is :math:`\gamma_f` (here :math:`\gamma_{\rm th}`),
   from −0.5 to 3 × 10⁶ s⁻¹. The right-axis scale is ten times the left:
   equal plotted heights do not mean equal rates. The horizontal axis extends
   to 35 MHz; these rate curves exist only in the fitted 0.537–4.980 MHz band.
   Both coefficient-based curves use the same assumed group velocity; the
   model curve comes from the imaginary part of a numerical dispersion root.
   Neither least squares nor Kim is a direct growth-versus-time measurement.
   The different signs and magnitudes are results to investigate, not a reason
   to choose whichever curve looks closer to theory.

   Orange open circles mark frequencies where at least one split fails the
   common-power check. Flags and curves are retained wherever they fall inside the fixed axes;
   the :ref:`supplementary page <k05-budget-en>` explains the check after these
   results have been introduced.

   .. raw:: html

      <details class="k05-note"><summary>Which inputs are measured, and which are estimated?</summary>

   .. list-table::
      :header-rows: 1
      :widths: 30 25 45

      * - Quantity
        - Value used
        - Status
      * - Temperature energy :math:`T_e`
        - 9.1689 eV
        - Effective slope from the main slow scan on page 08; assumed representative of the fast records and of a Maxwellian distribution.
      * - Magnetic components :math:`|B_r|,|B_{\rm axial}|`
        - 39.48, 80.34 G
        - Reported local values at C1; magnitude :math:`B_0=89.52` G.
      * - Number density :math:`n_0`
        - :math:`10^{17}` m⁻³
        - Provisional estimate; not fitted to the fluctuation peaks.
      * - Electron drift :math:`V_D`
        - +100 km/s
        - Provisional estimate along model +y; not obtained from discharge voltage alone.
      * - Ion species and charge
        - Xe⁺, :math:`m_i=131.293` u
        - Assumed species; u is the atomic mass unit.
      * - Parallel wave number
        - :math:`k_\parallel\lambda_{De}=0.03`
        - Assumed finite parallel structure, not a measured wavelength.
      * - Remaining geometry and ion Doppler shift
        - :math:`k_\perp=k_y`; :math:`\mathbf k\cdot\mathbf u_i=0`
        - Illustrative field-aligned slab and omitted ion Doppler shift; this does not claim a stationary physical ion beam.
      * - Direction and measurement response
        - Positive model propagation C1 → C3; no response correction
        - Assumed orientation, not a propagation measurement. Raw voltage coefficients retain their measured units.

   The field-aligned parallel direction follows the total magnetic field.
   It is not simply the laboratory radial direction when the reported axial
   field is nonzero. The estimated density, drift and geometry are editable
   inputs, not confidence limits. Reversing the assumed signed group velocity
   reverses the converted apparent rates; selecting a speed does not calibrate
   the probes or establish a wave mode.

   .. raw:: html

      </details>
      <details class="k05-note"><summary>How the dispersion curve and group velocity are calculated</summary>

   In this illustrative slab, magnetized electrons are Maxwellian and ions
   are cold and unmagnetized. With the assumed zero ion Doppler shift, solve

   .. _k05-source-7-en:

   .. container:: k05-paper-match

      .. rubric:: K05 and reference [1], Eq. (7)

      .. k05:equation:: comparison-dispersion
         :lang: en

         \mathcal E(\omega,k_y)
         =1+k^2\lambda_{De}^2+g(\omega,k_y)
           -\frac{k^2\lambda_{De}^2\omega_{pi}^2}{\omega^2}=0,
         \qquad k^2=k_y^2+k_\parallel^2 .

      **Original equation, original notation — [1], (7)**

      .. k05:equation:: paper-equation-7
         :lang: en

         \epsilon^{(1)}=1+k^2\lambda_{De}^2+g(\Omega,X,Y)
         -\frac{k^2\lambda_{De}^2\omega_{pi}^2}{(\omega-k_xv_p)^2}.

      **This is a specialization, not just a symbol change.** The article's
      :math:`x,y,z` are axial, azimuthal and radial, with the magnetic field along
      :math:`z`. Its :math:`k^2=k_x^2+k_y^2+k_z^2`;
      :math:`\Omega=(\omega-k_yV_D)/\omega_{ce}`,
      :math:`X=(k_x^2+k_y^2)\rho^2`, :math:`Y=k_z^2\rho^2`,
      and :math:`\rho=v_{te}/\omega_{ce}`. Capital :math:`X,Y` in this box are
      dimensionless Gordeev arguments, **not probe coefficients**.
      :math:`v_p` is the axial ion beam speed; :math:`k_xv_p` is its Doppler shift.
      :math:`\lambda_{De},\omega_{pi},\omega_{ce}` denote Debye length, ion plasma
      angular frequency and electron gyro angular frequency.

      Our :math:`\mathcal E` corresponds to the printed :math:`\epsilon^{(1)}`:
      both are a dielectric multiplied by :math:`k^2\lambda_{De}^2`, not the
      unscaled :math:`1+\chi_e+\chi_i`. The present calculation sets
      :math:`k_x=0`, :math:`k_z\to k_\parallel`, :math:`X\to b`, and
      :math:`k_xv_p\to0`. It uses the **total tilted field** for the parallel axis,
      so it does not equate the measured laboratory radial direction with parallel.
      The response derivation below explains the common structure without silently
      restoring terms absent from the saved calculation.


   :math:`\mathcal E` is the dielectric multiplied by
   :math:`k^2\lambda_{De}^2`; the multiplication does not change its roots here.
   :math:`\omega` is complex angular frequency in rad/s.
   :math:`\lambda_{De}=\sqrt{\epsilon_0T_e/(n_0e^2)}` is the electron Debye
   length, and :math:`\omega_{pi}=\sqrt{n_0e^2/(\epsilon_0m_i)}` is the ion
   plasma angular frequency. In these formulas :math:`T_e` is an energy in
   joules, converted from the eV input. :math:`e` is the positive elementary
   charge and :math:`\epsilon_0` is the vacuum permittivity.
   The electron response :math:`g` is evaluated through the Gordeev series [2]:

   .. k05:equation:: comparison-gordeev
      :lang: en

      \begin{aligned}
      g&=\frac{\omega-k_yV_D}{\sqrt{2}\,k_\parallel v_{te}}
        \sum_{m=-\infty}^{\infty} e^{-b}I_m(b)\,Z(\zeta_m),\\
      b&=(k_yv_{te}/\omega_{ce})^2,\qquad
      \zeta_m=\frac{\omega-k_yV_D-m\omega_{ce}}
                         {\sqrt{2}\,k_\parallel v_{te}} .
      \end{aligned}

   :math:`v_{te}=\sqrt{T_e/m_e}` is the one-dimensional electron thermal
   speed, :math:`m_e` is electron mass, and
   :math:`\omega_{ce}=eB_0/m_e` is the positive electron gyrofrequency.
   The integer :math:`m` labels cyclotron harmonics;
   :math:`b` and :math:`\zeta_m` are dimensionless arguments.
   :math:`I_m` is a modified Bessel function. :math:`Z` is the plasma
   dispersion function, evaluated as :math:`i\sqrt{\pi}` times SciPy's
   :code:`special.wofz`. :code:`special.ive` directly evaluates the scaled
   Bessel factor, avoiding large intermediate numbers.

   The code follows one positive-frequency root from low :math:`k_y` to high
   :math:`k_y`, using the preceding root as the next initial guess. It does
   not search for all possible branches. For the convention
   :math:`e^{i\mathbf k\cdot\mathbf r-i\omega t}`, calculate

   .. k05:equation:: comparison-branch
      :lang: en

      f=\frac{\operatorname{Re}\omega}{2\pi},\qquad
      \gamma_{\mathrm{th}}=\operatorname{Im}\omega,\qquad
      v_{g,y}=\frac{\partial\operatorname{Re}\omega}{\partial k_y}
      =\operatorname{Re}\!\left[-\frac{\partial_{k_y}\mathcal E}
                                     {\partial_\omega\mathcal E}\right].

   :math:`\operatorname{Im}` takes the imaginary part. Derivatives hold
   :math:`k_\parallel` and the background parameters fixed. For this single
   monotone branch, interpolation supplies :math:`v_{g,y}(f)` and
   :math:`\gamma_{\rm th}(f)` on the measured Fourier grid; no extrapolation is
   used. This uses the full complex root, not an additional weak-growth
   approximation. Root residuals, harmonic-sum convergence and derivative
   checks are saved with the numerical report.

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>Where reference Eq. (7) comes from: response, then Poisson closure</summary>

   The question is simple: **if a small potential is imposed, how much charge
   does each species move, and can that charge sustain the same potential?**
   We use a locally uniform, collisionless, electrostatic model. Electrons are a
   drifting Maxwellian in uniform background fields; ions are a cold unmagnetized
   beam. These are assumptions, not conclusions extracted from a spectrum.

   **1. Linearize the particle response.** Write the distribution of species
   :math:`s` as a stationary :math:`F_{s0}` plus a small :math:`F_{s1}`.
   Keep terms linear in the perturbation in the Vlasov equation:

   .. k05:equation:: kinetic-linear-vlasov
      :lang: en

      \left[\partial_t+\mathbf v\cdot\nabla
      +\frac{q_s}{m_s}(\mathbf E_0+\mathbf v\times\mathbf B_0)\cdot\nabla_{\mathbf v}\right]F_{s1}
      =-\frac{q_s}{m_s}\mathbf E_1\cdot\nabla_{\mathbf v}F_{s0},
      \qquad \mathbf E_1=-\nabla\phi_1.


   :math:`F` is a velocity distribution, not the frequency :math:`f` or the
   fourth-moment matrix on page 05. :math:`q_s,m_s` are charge and mass;
   :math:`\mathbf v` is particle velocity; :math:`\nabla_{\mathbf v}` differentiates
   in velocity space. Subscripts 0 and 1 mean background and first-order response.
   The left side follows the unperturbed particle orbit; the right side is the
   small electric force acting on the background velocity distribution.

   **2. Cold ions supply the beam denominator.** For a perturbation proportional
   to :math:`e^{i\mathbf k\cdot\mathbf r-i\omega t}`, cold-ion continuity and
   momentum reduce to

   .. k05:equation:: kinetic-cold-ion
      :lang: en

      \begin{aligned}
      \Omega_i\,\delta n_i&=n_0\mathbf k\cdot\delta\mathbf u_i,
      &\Omega_i\,\delta\mathbf u_i&=\frac{e}{m_i}\mathbf k\phi_1,\\
      \delta n_i&=\frac{n_0 e k^2\phi_1}{m_i\Omega_i^2},
      &\chi_i&=-\frac{\omega_{pi}^2}{\Omega_i^2},\qquad \Omega_i=\omega-k_xv_p.
      \end{aligned}


   :math:`\delta n_i,\delta\mathbf u_i` are density and velocity perturbations.
   The beam sees the Doppler-shifted angular frequency :math:`\Omega_i`;
   this is not the dimensionless electron argument :math:`\Omega` below.
   The susceptibility :math:`\chi_i` is defined by its induced charge
   :math:`\rho_{i1}=-\epsilon_0 k^2\chi_i\phi_1`.
   Solving momentum first, then inserting it into continuity, explains the square
   in :math:`(\omega-k_xv_p)^{-2}`. In the cold-beam limit these moment equations
   are the corresponding Vlasov response; finite ion temperature changes it.

   **3. Magnetized electrons remember their gyro-orbits.** The electron equation
   can be integrated along an unperturbed orbit, with the causal response selected
   by switching the perturbation on from the remote past. Separate the uniform
   drift from the thermal displacement :math:`\Delta\mathbf r_{\rm th}`.
   For a positive look-back time :math:`s`, a Gaussian velocity average gives

   .. k05:equation:: kinetic-orbit-average
      :lang: en

      \begin{aligned}
      \tau&=\omega_{ce}s,\quad X=k_\perp^2\rho^2,\quad Y=k_\parallel^2\rho^2,\\
      \left\langle e^{i\mathbf k\cdot\Delta\mathbf r_{\rm th}(s)}\right\rangle_{F_{e0}}
      &=\exp\!\left[-X(1-\cos\tau)-\tfrac12Y\tau^2\right].
      \end{aligned}


   Here :math:`s` is a time lag, no longer a species index; :math:`\tau` is the
   dimensionless gyro time, and the brackets average the Maxwellian velocities.
   Parallel particles move freely, giving a Gaussian factor proportional to
   :math:`s^2`. Perpendicular particles orbit, giving :math:`1-\cos\tau`.
   Their one-component thermal variance is :math:`v_{te}^2=T_e/m_e`.
   For example, the perpendicular phase variance is
   :math:`2k_\perp^2\rho^2(1-\cos\tau)`; a zero-mean Gaussian phase has average
   :math:`\langle e^{i\theta}\rangle=e^{-\langle\theta^2\rangle/2}`.

   Integrating the electric-force term over velocity, using
   :math:`\nabla_{\mathbf v}F_{e0}=-(\mathbf v-\mathbf V_D)F_{e0}/v_{te}^2`
   and an integration by parts along the orbit gives [2, Eqs. (2.8)–(2.9)]

   .. k05:equation:: kinetic-electron-response
      :lang: en

      \begin{aligned}
      \chi_e&=\frac{1+g}{k^2\lambda_{De}^2},\\
      g&=i\Omega\int_0^\infty
       \exp\!\left[-X(1-\cos\tau)-\tfrac12Y\tau^2+i\Omega\tau\right]d\tau,\\
      \Omega&=\frac{\omega-k_yV_D}{\omega_{ce}}.
      \end{aligned}


   The constant 1 is the boundary term; the remaining orbit integral is :math:`g`.
   The same susceptibility convention defines the electron induced charge.
   For positive :math:`Y`, the Gaussian factor makes this representation
   convergent; limiting cases require the causal continuation. Expanding
   :math:`e^{X\cos\tau}=\sum_m I_m(X)e^{im\tau}` and integrating each harmonic
   gives the Bessel/plasma-dispersion-function series in
   :k05:eq:`comparison-gordeev`. With :math:`k_\perp=k_y`, its :math:`X` is
   our :math:`b`, and :math:`\sqrt{2Y}=\sqrt2 k_\parallel v_{te}/\omega_{ce}`
   for the positive :math:`k_\parallel` used here. Thus the series and orbit
   picture describe the same response, rather than two independently fitted models.

   **4. Close the response with Poisson's equation.** Add both induced charges
   and require a nonzero potential to reproduce itself:

   .. k05:equation:: kinetic-poisson-closure
      :lang: en

      \begin{aligned}
      \rho_1&=-\epsilon_0 k^2(\chi_e+\chi_i)\phi_1,
      &k^2\phi_1&=\rho_1/\epsilon_0,\\
      \epsilon_L&=1+\chi_e+\chi_i=0,\\
      k^2\lambda_{De}^2\epsilon_L
      &=1+k^2\lambda_{De}^2+g
      -\frac{k^2\lambda_{De}^2\omega_{pi}^2}{(\omega-k_xv_p)^2}=0.
      \end{aligned}


   :math:`\rho_1` is charge density (C/m³), distinct from the Larmor radius
   :math:`\rho`; :math:`\epsilon_L` is the unscaled longitudinal dielectric.
   Dividing out the nonzero perturbation and multiplying by
   :math:`k^2\lambda_{De}^2` gives precisely the structure of reference Eq. (7).
   This derivation explains why both species enter and what was assumed.
   It does not determine which root actually dominates an experiment.

   For the current saved curves, remove the ion Doppler shift and the second
   perpendicular wave-number component as stated in the comparison box.
   Then solve for the complex root, rather than treating the left side as a
   known frequency. Group velocity and growth follow from
   :k05:eq:`comparison-branch`.

   .. raw:: html

      </details>

   .. rubric:: 2. Figure 3: from frequency pairs to a signed transfer curve

   .. figure:: /_static/K_Diagnostics/k05-comparison-figure3.svg
      :width: 100%
      :alt: A logarithmic map of Kim quadratic coefficient magnitudes and signed voltage-domain half-power transfer curves from the same fitted band.

      Figure 3 counterpart. (a) Four-split mean coefficient magnitude, with
      a logarithmic color scale. Gray means unestimated, not zero coupling.
      (b) Conditional signed quadratic contributions in voltage units.
      Open orange points carry the same failed-bound flag as Figure 2.

   **Panel (a) asks which frequency-pair coefficients are large.** In the
   fitted model, a pair :math:`(f_1,f_2)` contributes the product
   :math:`X_{f_1}X_{f_2}` to the target :math:`f=f_1+f_2`, multiplied by
   its complex coefficient :math:`Q`. Read the horizontal coordinate as
   :math:`f_2` and the vertical coordinate as :math:`f_1`.
   Opposite signs describe difference-frequency combinations; both positive
   inputs describe a sum frequency. Negative Fourier coefficients are
   conjugates because the recorded signal is real.

   To draw the map, take the saved Kim coefficients, distribute each unique
   off-diagonal product equally between its two exchanged positions, add the
   conjugate negative-target half, and average the four magnitudes.
   The displayed symmetric coefficient :math:`Q^{\rm sym}` has units V⁻¹.
   A bright point means a larger coefficient multiplying that pair's voltage
   product. **It is not a bicoherence value, and brightness gives neither a
   transfer direction nor the amount of power actually transferred.**
   The input amplitudes and their phases also matter.

   In this example, bright diagonal bands run approximately along constant
   :math:`f_1+f_2`: families of pairs feed the same target frequency in the
   algebraic model. Some bright areas lie in the opposite-sign quadrants.
   This alone does not establish an inverse cascade. The central gray strip
   excludes target frequencies below 0.537 MHz; the outer gray triangles
   exclude targets above 4.980 MHz. The zero-input axes are also excluded.
   They do not assert the absence of interactions outside the fitted domain.
   The display floor 10⁻³ V⁻¹ is a color choice, not a significance threshold.

   **Panel (b) includes the measured three-frequency relation and its sign.**
   Multiply each :math:`Q` by the averaged triple product, remove the same
   reference phase, take the real part, and sum all retained pairs:

   .. k05:equation:: comparison-transfer
      :lang: en

      T^{(1/2)}_{V,f}
      =\frac{v_{g,y}(f)}{\Delta y}
       \operatorname{Re}\!\left[
         e^{-i\delta_f}\!
         \sum_{\substack{f_1+f_2=f\\ \mathrm{unique}}}
         Q_{f;f_1,f_2}
         \left\langle X_{f_1}X_{f_2}X_f^*\right\rangle_{\mathrm{test}}
       \right].

   The subscript V retains the voltage observable. Superscript :math:`(1/2)`
   identifies the half-power convention used in Eq. (6) of [1]:
   the corresponding contribution to the full squared-amplitude derivative is
   :math:`2T^{(1/2)}_{V,f}`. Coefficients and :math:`\delta_f` come from the
   three training captures; the triple average comes from the held-out capture.
   The unique-pair coefficients in this sum are the fitted ones, before the
   symmetric display conversion. :math:`Q` has units V⁻¹ and the triple
   average V³, so the result has units V²/s. It is not a calibrated plasma
   energy-transfer density in J m⁻³ s⁻¹.

   With the assumed positive group velocity, a positive value is a positive
   quadratic contribution to this frequency's signal power, while a negative
   value is a negative contribution. The Kim curve has a positive feature
   near 0.8 MHz and a negative feature near 1.9 MHz. The least-squares curve
   differs substantially. The near-zero values at higher frequencies in this
   plot are net sums: individual pair contributions can cancel.
   This calculation does not identify a unique donor–recipient pair, and it
   does not include quadratic self power or the complete residual budget.

   .. raw:: html

      <details class="k05-note"><summary>Why split a coefficient between exchanged frequency pairs?</summary>

   The fit includes each product only once: :math:`X_{f_1}X_{f_2}=X_{f_2}X_{f_1}`.
   A full square map shows both positions. To preserve the sum,

   .. k05:equation:: comparison-symmetric-q
      :lang: en

      Q^{\mathrm{sym}}_{f;f_1,f_2}=
      \begin{cases}
        Q^{\mathrm{unique}}_{f;f_1,f_2}/2,& f_1\ne f_2,\\
        Q^{\mathrm{unique}}_{f;f_1,f_1},& f_1=f_2 .
      \end{cases}

   Splitting the off-diagonal coefficient prevents double counting;
   a diagonal pair occurs once. Negative-target entries follow
   :math:`Q^{\rm sym}_{-f;-f_1,-f_2}=(Q^{\rm sym}_{f;f_1,f_2})^*`
   and are not independently fitted. Published coefficient magnitudes require
   matching pair-counting and signal-normalization conventions before a
   numerical comparison. A common voltage scale change by :math:`s` divides
   :math:`Q` by :math:`s` and multiplies the voltage-power transfer by
   :math:`s^2`, while leaving :math:`L` unchanged.

   .. raw:: html

      </details>

   .. rubric:: 3. What the comparison shows, and where to go next

   All five counterparts are now visible. The experimental spectra are direct
   statistical results; the coefficient map and rate curves also depend on
   the chosen model, frequency band, observable and, for rates, the assumed
   kinetic branch. The positive and negative features should not be relabelled
   as the same resonances or cascade reported in [1]: this example uses different
   plasma parameters and its four-split coefficient band stops below 5 MHz.

   The immediate question raised by the plots is why two estimators give
   different apparent growth and transfer. The
   :ref:`next supplementary page <k05-budget-en>` addresses that question:
   it checks the inferred common power, explains the reference rotation, and
   restores all terms in the measured power balance. Of 368 frequency–split
   cases, only 35 pass the present Kim common-power bound. This is why the
   figures are labelled conditional rather than accepted measurements of EDI
   growth or inverse cascade.

   .. raw:: html

      <details class="k05-note"><summary>Reproduce the figures and replace the estimated inputs</summary>

   The saved coefficients and moments come from :code:`analyze_transfer_budget.py`;
   their calculation is described on the supplementary page. The new script
   reads those arrays, the validation supplement\'s target powers and the page 06 spectra.
   It does not refit the captures. From the repository root:

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_paper_comparison.py \
        --budget /path/to/budget/transfer_arrays.npz \
        --validation /path/to/validation/validation_arrays.npz \
        --spectra /path/to/spectra/spectral_arrays.npz \
        --config K_Diagnostics/K05_bispectral_transfer/paper_comparison_config.json \
        --output /path/to/new_comparison
      python K_Diagnostics/K05_bispectral_transfer/plot_paper_comparison.py \
        --output /path/to/new_comparison

   Use a new output directory for each scenario. The JSON records all assumed
   values, input hashes, code hashes, units and root checks; the NPZ preserves
   individual splits and unplotted arrays. The SVG/PNG figures share those
   arrays. Changing a plasma parameter changes the theory scenario; it does
   not retroactively calibrate the experimental voltage coefficients.

   :download:`Numerical report </_static/K_Diagnostics/k05-comparison-summary.json>`.

   .. raw:: html

      </details>

   .. rubric:: References

   [1] Z. A. Brown and B. A. Jorns (2023), “Growth and Saturation of the Electron
   Drift Instability in a Crossed Field Plasma,” *Physical Review Letters*
   **130**, 115101, Figs. 2–3 and Eqs. (4), (6), (7).
   `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   [2] J. Cavalier (2013), *Modèles cinétiques et caractérisation expérimentale
   des fluctuations électrostatiques dans un propulseur à effet Hall*,
   PhD thesis, Université de Lorraine, Eqs. (2.7)–(2.9), pp. 31–32.
   `Institutional full text <https://docnum.univ-lorraine.fr/public/DDOC_T_2013_0130_CAVALIER.pdf>`_.

.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-comparison-zh:

   .. rubric:: 把实验数据画成文献图 2、图 3 的形式

   Brown 与 Jorns [1] 用五个面板串起分析：色散曲线、双探针频谱、增长率、
   耦合系数图和有符号转移曲线。下面用四组同步 C1/C3 记录画出对应结果，
   先看图，再说明每个量怎么算、怎么看。
   频谱来自实测信号；把系数换算成速率时，还使用了下文明确列出的等离子体参数情景。

   .. rubric:: 1．对应图 2：从实测频谱到增长率对比

   .. figure:: /_static/K_Diagnostics/k05-comparison-figure2.svg
      :width: 100%
      :alt: 对应文献图2的三个面板：估计参数下的动力学色散、实测电压谱、采用文献左右双纵轴的条件增长率对比。

      图 2 对照图。(a) 明确假设参数下的动力学模型；(b) 实测电压谱；
      (c) 系数换算的表观增长率读左轴，模型增长率读右轴，与 [1] 一致。
      坐标范围和刻度按文献图 2 设置，没有覆盖的频率区域留白。
      数据曲线和色带表示四轮均值与范围，不是置信区间。
      超出固定纵轴范围的数值会被裁出图框，不代表它们等于零。

   **先看 (b)：信号里有哪些频率？** C1、C3 是两支探针的通道。
   纵轴是电压功率谱密度（power spectral density），标为 :math:`P_f=S_V(f)`，
   单位 μV²/Hz；保存的 V²/Hz 数值统一乘 :math:`10^{12}`，只是换单位。
   文献 [1] 标的是 1/Hz；这里保留本实验电压单位，不假设未知的等离子体幅值归一化。
   峰越高，表示该频率附近每单位带宽的波动功率越多。
   这里沿用 :ref:`第六页的实测频谱 <k05-experiment-zh>`：
   每段去均值、乘周期 Hann 窗、作 Fourier 变换、取模平方，
   再校正窗函数的均方增益并平均。图中的实线对四组记录等权平均。
   这是使用 16384 点分段的单边谱，数据到 50 MHz；横轴按文献延伸到 100 MHz，
   所以 50–100 MHz 留白。(b) 使用文献的对数刻度，纵轴图框约为 0.2–4000
   （原图没有标注这两个端点）。两个通道共用电压尺度，没有为了让曲线重合而各自缩放。

   灰色竖带表示 **0.537–4.980 MHz 的系数拟合频段**，不是采集带宽。
   系数计算沿用 :ref:`第七页 <k05-experiment-coefficients-zh>` 的 2048 点分段，
   二次输入保留绝对频率不超过 5 MHz 的非零频点。
   :ref:`验证补充页 <k05-validation-zh>` 的 5–20 MHz 预测示例采用了另一输入频带、且只有一轮留出验证，
   因此没有直接混入这里的四轮 Kim 结果。

   **(a) 提供频率与波数之间的模型关系。**
   周向波数 :math:`k_y` 描述波在空间上变化多快，对应波长为
   :math:`2\pi/|k_y|`；色散关系（dispersion relation）把它与频率
   :math:`f` 联系起来。这条曲线使用磁化电子、冷离子的模型 [1, 2]，
   输入已有温度估计和磁场分量，再加上下方折叠区列出的估计参数。
   它不是用两个探针的相位直接测出的波数。
   原图以 :math:`\omega_k` 标记纵轴并写 Hz；本图明确使用
   :math:`f=\operatorname{Re}\omega/(2\pi)`。
   仅凭原图的印刷标签，尚不能确定其绘图数值是否已除过 :math:`2\pi`。
   图框相同不等于频率约定已经核实一致，不能用两条图线的斜率直接断言实测波速之比。
   曲线斜率给出周向群速度（group velocity）：
   :math:`v_{g,y}=2\pi\,\partial f/\partial k_y`，求导时固定其他波矢分量。
   本参数情景在拟合频段内给出约 **0.32–2.49 km/s**。

   **(c) 把实测系数换成时间变化率。**
   每个频率的线性＋二次模型都给出一个复线性系数 :math:`L_f`。
   蓝色使用最小二乘（least squares），橙色使用 Kim 平稳估计；两者都包含二次项。
   先由三组训练记录计算参考相位
   :math:`\delta_f=\arg\langle Y_fX_f^*\rangle_{\rm train}`。
   :math:`X_f`、:math:`Y_f` 分别是 C1、C3 的 Fourier 系数，
   尖括号表示对分段平均，星号表示共轭。
   把 :math:`L_f` 向相反方向旋转这个角度，再计算

   .. k05:equation:: comparison-rate
      :lang: zh

      \gamma_{y,\mathrm{app}}(f)
      =\frac{v_{g,y}(f)}{\Delta y}
       \left[\operatorname{Re}\!\left(e^{-i\delta_f}L_f\right)-1\right].

   :math:`\Delta y=0.0037` m 是探针间距，:math:`i^2=-1`，
   :math:`\operatorname{Re}` 表示取实部；app 表示表观量（apparent），
   即结果依赖模型和测量响应假设。方括号里是无量纲的幅值增量，
   乘上 :math:`v_{g,y}/\Delta y` 后，单位变为 s⁻¹。
   绿色虚线则取模型复频率的虚部作为理论增长率 :math:`\gamma_{\rm th}`，
   再借助 (a) 换到频率坐标。

   系数换算值为正，表示表观线性增加；为负，表示表观线性减小，
   其中还没有加入二次贡献和残差。
   例如 **2.001953 MHz、第 2 组留出** 时，假设模型给出群速度约 2148 m/s；
   Kim 的表观率约 **+3.08 × 10⁴ s⁻¹**，最小二乘约 **−7.39 × 10⁴ s⁻¹**，
   理论模型约 **5.02 × 10⁵ s⁻¹**。
   这里列的是一轮数值，图中实线为四轮均值。
   现在与 [1] 一样，左轴标 :math:`\gamma_{f(y)}`，对应本页的
   :math:`\gamma_{y,\mathrm{app}}`，范围 −0.5 至 3 × 10⁵ s⁻¹；
   右轴标 :math:`\gamma_f`，对应 :math:`\gamma_{\rm th}`，范围 −0.5 至 3 × 10⁶ s⁻¹。
   **右轴量程是左轴的十倍，曲线画在同一高度不表示增长率相等。**
   横轴延伸到 35 MHz，而这些速率曲线只覆盖拟合过的 0.537–4.980 MHz。
   两条系数换算曲线借用了同一假设群速度；model 曲线来自数值色散复根的虚部。
   Least squares 与 Kim 都不是直接跟踪启动时幅值随时间增长的测量。
   符号和数值的差异是需要解释的结果，不能只挑更接近理论的那条曲线。

   橙色空心圆标出至少一轮未通过共同功率检查的频率。
   固定坐标范围内保留曲线和标记；为什么作这项检查，
   放到看完这些结果之后的 :ref:`补充页 <k05-budget-zh>` 说明。

   .. raw:: html

      <details class="k05-note"><summary>哪些参数来自实验，哪些是暂用估计？</summary>

   .. list-table::
      :header-rows: 1
      :widths: 28 25 47

      * - 物理量
        - 本次取值
        - 来源与含义
      * - 温度能量 :math:`T_e`
        - 9.1689 eV
        - 第八页主扫描的有效斜率温度；暂作高频记录的代表值和 Maxwellian 温度。
      * - 磁场分量 :math:`|B_r|,|B_{\rm axial}|`
        - 39.48、80.34 G
        - 实验人员提供的 C1 局部分量；合成模长 :math:`B_0=89.52` G。
      * - 数密度 :math:`n_0`
        - :math:`10^{17}` m⁻³
        - 暂用数量级估计，没有用波动谱峰拟合。
      * - 电子漂移速度 :math:`V_D`
        - +100 km/s
        - 沿模型 +y 的暂用估计，不是单凭放电电压推算。
      * - 离子种类、电荷与质量
        - Xe⁺，:math:`m_i=131.293` u
        - 暂按一价氙离子；u 为原子质量单位。
      * - 平行波数
        - :math:`k_\parallel\lambda_{De}=0.03`
        - 假设有有限的沿磁场结构，不是实测波长。
      * - 其余几何与离子 Doppler 项
        - :math:`k_\perp=k_y`；:math:`\mathbf k\cdot\mathbf u_i=0`
        - 简化的沿磁场坐标模型，忽略离子 Doppler 项；不表示真实离子束没有运动。
      * - 方向与测量响应
        - 模型正向传播为 C1 → C3；未作响应校正
        - 方向是假设，不是传播测量；系数仍使用实测电压单位。

   平行方向沿总磁场；既然给出的轴向磁场不为零，就不能直接把它等同于实验室径向。
   密度、漂移和几何是可以替换的估计输入，不是置信范围。
   若改成相反的有向群速度，换算率的符号也会反向；
   选择速度数值本身不能完成探针标定，也不能确认波模。

   .. raw:: html

      </details>
      <details class="k05-note"><summary>色散曲线和群速度具体怎样算？</summary>

   这个简化情景采用 Maxwellian 磁化电子和非磁化冷离子。
   在离子 Doppler 项暂取零时，求解

   .. _k05-source-7-zh:

   .. container:: k05-paper-match

      .. rubric:: K05 与文献 [1] 式 (7) 对照

      .. k05:equation:: comparison-dispersion
         :lang: zh

         \mathcal E(\omega,k_y)
         =1+k^2\lambda_{De}^2+g(\omega,k_y)
           -\frac{k^2\lambda_{De}^2\omega_{pi}^2}{\omega^2}=0,
         \qquad k^2=k_y^2+k_\parallel^2 .

      **文献原式与原符号 — [1], (7)**

      .. k05:equation:: paper-equation-7
         :lang: zh

         \epsilon^{(1)}=1+k^2\lambda_{De}^2+g(\Omega,X,Y)
         -\frac{k^2\lambda_{De}^2\omega_{pi}^2}{(\omega-k_xv_p)^2}.

      **这里不只是换符号，还作了模型简化。** 文献的 :math:`x,y,z`
      分别是轴向、周向、径向，磁场沿 :math:`z`。
      原式 :math:`k^2=k_x^2+k_y^2+k_z^2`，
      :math:`\Omega=(\omega-k_yV_D)/\omega_{ce}`，
      :math:`X=(k_x^2+k_y^2)\rho^2`，:math:`Y=k_z^2\rho^2`，
      :math:`\rho=v_{te}/\omega_{ce}`。
      本框大写 :math:`X,Y` 是 Gordeev 函数的无量纲参数，**不是双探针系数**。
      :math:`v_p` 是轴向离子束速度，:math:`k_xv_p` 是离子多普勒频移。
      :math:`\lambda_{De},\omega_{pi},\omega_{ce}` 分别表示 Debye 长度、离子等离子体角频率、电子回旋角频率。

      本页 :math:`\mathcal E` 对应印刷的 :math:`\epsilon^{(1)}`：
      它们是乘过 :math:`k^2\lambda_{De}^2` 的介电表达式，不是未缩放的
      :math:`1+\chi_e+\chi_i`。当前计算取 :math:`k_x=0`、
      :math:`k_z\to k_\parallel`、:math:`X\to b`，并令 :math:`k_xv_p\to0`。
      而且平行方向沿 **倾斜的总磁场**，不能把实验室径向直接当成平行方向。
      下方推导解释两种表达式共有的结构，不会把已保存计算中省略的项悄悄加回来。


   :math:`\mathcal E` 是介电函数乘以 :math:`k^2\lambda_{De}^2`，
   这里该乘法不改变方程的根；:math:`\omega` 是复角频率，单位 rad/s。
   :math:`\lambda_{De}=\sqrt{\epsilon_0T_e/(n_0e^2)}` 是电子德拜长度（Debye length），
   :math:`\omega_{pi}=\sqrt{n_0e^2/(\epsilon_0m_i)}` 是离子等离子体角频率。
   此处 :math:`T_e` 是能量，公式中先把 eV 输入换成 J；
   :math:`e` 为正的元电荷，:math:`\epsilon_0` 为真空介电常数。
   电子响应 :math:`g` 用 Gordeev 级数 [2] 计算：

   .. k05:equation:: comparison-gordeev
      :lang: zh

      \begin{aligned}
      g&=\frac{\omega-k_yV_D}{\sqrt{2}\,k_\parallel v_{te}}
        \sum_{m=-\infty}^{\infty} e^{-b}I_m(b)\,Z(\zeta_m),\\
      b&=(k_yv_{te}/\omega_{ce})^2,\qquad
      \zeta_m=\frac{\omega-k_yV_D-m\omega_{ce}}
                         {\sqrt{2}\,k_\parallel v_{te}} .
      \end{aligned}

   :math:`v_{te}=\sqrt{T_e/m_e}` 是一维电子热速度，:math:`m_e` 是电子质量，
   :math:`\omega_{ce}=eB_0/m_e` 为取正值的电子回旋角频率。
   整数 :math:`m` 标记回旋谐波（cyclotron harmonics）；
   :math:`b`、:math:`\zeta_m` 是无量纲自变量。
   :math:`I_m` 为修正 Bessel 函数，:math:`Z` 为等离子体色散函数，
   代码用 :math:`i\sqrt{\pi}` 乘 SciPy 的 :code:`special.wofz` 得到它，
   并用 :code:`special.ive` 直接计算带指数缩放的 Bessel 因子，避免中间值过大。

   从较小的 :math:`k_y` 开始，代码每次将上一点的复频率作为下一点的初值，
   连续跟踪一条正频率分支，并不是搜索所有可能的波模。
   使用 :math:`e^{i\mathbf k\cdot\mathbf r-i\omega t}` 约定时，

   .. k05:equation:: comparison-branch
      :lang: zh

      f=\frac{\operatorname{Re}\omega}{2\pi},\qquad
      \gamma_{\mathrm{th}}=\operatorname{Im}\omega,\qquad
      v_{g,y}=\frac{\partial\operatorname{Re}\omega}{\partial k_y}
      =\operatorname{Re}\!\left[-\frac{\partial_{k_y}\mathcal E}
                                     {\partial_\omega\mathcal E}\right].

   :math:`\operatorname{Im}` 表示取虚部；求偏导时固定
   :math:`k_\parallel` 和背景参数。
   本例单条分支的频率单调，因而可插值到实测 Fourier 频点，
   得到 :math:`v_{g,y}(f)` 和 :math:`\gamma_{\rm th}(f)`；不作外推。
   这里直接求完整复根，没有再用弱增长近似替代。
   数值报告同时保存方程残差、谐波求和收敛和导数检查。

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>文献式 (7) 从哪里来：先算粒子响应，再用 Poisson 方程闭合</summary>

   问题可以先说得很简单：**给等离子体一个很小的电势扰动，两类粒子各自移动多少电荷？
   这些电荷能否反过来维持同一个电势？** 这里使用局部均匀、无碰撞、静电模型：
   电子是均匀背景场中的漂移 Maxwell 分布，离子是冷的、未磁化的束流。
   这些是模型假设，不是从频谱自动读出的事实。

   **1．先把粒子响应线性化。** 将物种 :math:`s` 的分布函数写成稳态背景
   :math:`F_{s0}` 加上小扰动 :math:`F_{s1}`，在 Vlasov 方程中只保留一阶扰动：

   .. k05:equation:: kinetic-linear-vlasov
      :lang: zh

      \left[\partial_t+\mathbf v\cdot\nabla
      +\frac{q_s}{m_s}(\mathbf E_0+\mathbf v\times\mathbf B_0)\cdot\nabla_{\mathbf v}\right]F_{s1}
      =-\frac{q_s}{m_s}\mathbf E_1\cdot\nabla_{\mathbf v}F_{s0},
      \qquad \mathbf E_1=-\nabla\phi_1.


   :math:`F` 是速度分布函数，不是频率 :math:`f`，也不是第 05 页的四阶矩矩阵。
   :math:`q_s,m_s` 是电荷和质量，:math:`\mathbf v` 是粒子速度，
   :math:`\nabla_{\mathbf v}` 表示在速度空间求导。下标 0、1 分别表示背景和一阶响应。
   左边沿未受扰动的粒子轨道变化，右边是小扰动电场作用于背景速度分布。

   **2．冷离子给出带束流速度的分母。** 扰动采用
   :math:`e^{i\mathbf k\cdot\mathbf r-i\omega t}`，离子的连续性与动量方程化成

   .. k05:equation:: kinetic-cold-ion
      :lang: zh

      \begin{aligned}
      \Omega_i\,\delta n_i&=n_0\mathbf k\cdot\delta\mathbf u_i,
      &\Omega_i\,\delta\mathbf u_i&=\frac{e}{m_i}\mathbf k\phi_1,\\
      \delta n_i&=\frac{n_0 e k^2\phi_1}{m_i\Omega_i^2},
      &\chi_i&=-\frac{\omega_{pi}^2}{\Omega_i^2},\qquad \Omega_i=\omega-k_xv_p.
      \end{aligned}


   :math:`\delta n_i,\delta\mathbf u_i` 是密度与速度扰动。
   离子束感受到的是多普勒频移后的角频率 :math:`\Omega_i`，
   它不同于下文无量纲的电子参数 :math:`\Omega`。
   极化率（susceptibility） :math:`\chi_i` 用诱导电荷
   :math:`\rho_{i1}=-\epsilon_0 k^2\chi_i\phi_1` 定义。
   先由动量方程求速度，再代入连续性方程，分母便出现两次
   :math:`\omega-k_xv_p`。在冷束极限，这组矩方程给出对应的 Vlasov 响应；
   如果保留离子温度，响应会改变。

   **3．磁化电子的响应包含回旋轨道。** 沿未受扰动的轨道积分电子方程，
   并选取从遥远过去缓慢开启扰动的因果响应（causal response）。
   将匀速漂移与热运动位移 :math:`\Delta\mathbf r_{\rm th}` 分开。
   对正的回溯时间 :math:`s`，在 Gaussian 速度分布上平均，得到

   .. k05:equation:: kinetic-orbit-average
      :lang: zh

      \begin{aligned}
      \tau&=\omega_{ce}s,\quad X=k_\perp^2\rho^2,\quad Y=k_\parallel^2\rho^2,\\
      \left\langle e^{i\mathbf k\cdot\Delta\mathbf r_{\rm th}(s)}\right\rangle_{F_{e0}}
      &=\exp\!\left[-X(1-\cos\tau)-\tfrac12Y\tau^2\right].
      \end{aligned}


   这里 :math:`s` 改作时间间隔，不再是物种标签；:math:`\tau` 是无量纲回旋时间，
   尖括号是对 Maxwell 速度分布的平均。平行粒子自由运动，所以出现与
   :math:`s^2` 成正比的 Gaussian 因子；垂直粒子回旋，所以出现
   :math:`1-\cos\tau`。单个速度分量的热方差是 :math:`v_{te}^2=T_e/m_e`。
   例如垂直相位方差为 :math:`2k_\perp^2\rho^2(1-\cos\tau)`，
   而零均值 Gaussian 相位满足
   :math:`\langle e^{i\theta}\rangle=e^{-\langle\theta^2\rangle/2}`。

   再对电场驱动项作速度积分，使用
   :math:`\nabla_{\mathbf v}F_{e0}=-(\mathbf v-\mathbf V_D)F_{e0}/v_{te}^2`，
   沿轨道作一次分部积分，得到 [2，式 (2.8)–(2.9)]

   .. k05:equation:: kinetic-electron-response
      :lang: zh

      \begin{aligned}
      \chi_e&=\frac{1+g}{k^2\lambda_{De}^2},\\
      g&=i\Omega\int_0^\infty
       \exp\!\left[-X(1-\cos\tau)-\tfrac12Y\tau^2+i\Omega\tau\right]d\tau,\\
      \Omega&=\frac{\omega-k_yV_D}{\omega_{ce}}.
      \end{aligned}


   常数 1 来自边界项，剩下的轨道积分就是 :math:`g`；电子诱导电荷使用与离子相同的极化率定义。
   当 :math:`Y>0` 时 Gaussian 因子保证这里的积分收敛，极限情形需要保持因果延拓。
   展开 :math:`e^{X\cos\tau}=\sum_m I_m(X)e^{im\tau}`，逐个回旋谐波积分，
   就得到 :k05:eq:`comparison-gordeev` 的 Bessel 函数／等离子体色散函数级数。
   取 :math:`k_\perp=k_y` 后，:math:`X` 就是本页的 :math:`b`；
   对于当前正的 :math:`k_\parallel`，有
   :math:`\sqrt{2Y}=\sqrt2 k_\parallel v_{te}/\omega_{ce}`。
   因此，级数计算与轨道图像是同一个电子响应的两种写法，不是分别拟合的模型。

   **4．最后用 Poisson 方程闭合。** 将两类诱导电荷相加，要求非零电势扰动能维持自身：

   .. k05:equation:: kinetic-poisson-closure
      :lang: zh

      \begin{aligned}
      \rho_1&=-\epsilon_0 k^2(\chi_e+\chi_i)\phi_1,
      &k^2\phi_1&=\rho_1/\epsilon_0,\\
      \epsilon_L&=1+\chi_e+\chi_i=0,\\
      k^2\lambda_{De}^2\epsilon_L
      &=1+k^2\lambda_{De}^2+g
      -\frac{k^2\lambda_{De}^2\omega_{pi}^2}{(\omega-k_xv_p)^2}=0.
      \end{aligned}


   :math:`\rho_1` 是电荷密度（C/m³），不要与 Larmor 半径 :math:`\rho` 混淆；
   :math:`\epsilon_L` 是未缩放的纵向介电函数。
   除去非零扰动，再乘 :math:`k^2\lambda_{De}^2`，便得到文献式 (7) 的结构。
   这个推导说明了两类粒子怎样进入方程，以及使用了哪些假设；
   它没有决定实验中究竟是哪一条根占主导。

   当前保存的曲线还按对照框所述省略离子 Doppler 项和另一垂直波数分量。
   然后数值求复根，而不是把方程左侧当成已知频率。
   最后由 :k05:eq:`comparison-branch` 得到群速度与增长率。

   .. raw:: html

      </details>

   .. rubric:: 2．对应图 3：从频率波对到有符号转移曲线

   .. figure:: /_static/K_Diagnostics/k05-comparison-figure3.svg
      :width: 100%
      :alt: Kim二次系数模的对数色标图，以及同一拟合频带内带符号的电压半功率转移曲线。

      图 3 对照图。(a) 四轮系数模的均值，采用对数色标；灰色表示未估计，不是零耦合。
      (b) 电压单位下、有条件的二次贡献；橙色空心点沿用图 2 的上界未通过标记。

   **(a) 看的是哪些频率波对的系数较大。**
   在拟合模型中，一对频率 :math:`(f_1,f_2)` 产生乘积
   :math:`X_{f_1}X_{f_2}`，再乘以复系数 :math:`Q`，
   进入目标频率 :math:`f=f_1+f_2` 的预测。
   横坐标是 :math:`f_2`，纵坐标是 :math:`f_1`；
   两者异号时是差频组合，同为正值时是和频组合。
   由于原始信号为实数，负频率 Fourier 系数由共轭获得。

   作图时，读取保存的 Kim 系数，把每个非对角的独立波对系数平分到两个交换位置，
   再用共轭补出负目标频率的一半，最后对四轮的模取平均。
   显示的对称系数 :math:`Q^{\rm sym}` 单位为 V⁻¹。
   亮点表示该波对电压乘积前的系数较大；
   **它不是双相干，也没有单凭亮度给出转移方向或实际转移了多少功率**，
   因为还需要知道输入波的幅值和相位关系。

   本图的亮斜带大致沿 :math:`f_1+f_2` 为常数的方向：
   在代数模型中，一族不同波对都作用于相同的目标频率。
   有些亮区位于异号象限，但不能单凭这一点认定逆级联（inverse cascade）。
   中间灰色带排除了低于 0.537 MHz 的目标频率，外侧灰色三角排除了高于
   4.980 MHz 的目标频率，零输入频率轴也没有参与拟合。
   这些区域不能解释成“没有相互作用”。
   10⁻³ V⁻¹ 只是显示色标的下限，不是显著性阈值。

   **(b) 再把三频率统计量和符号算进去。**
   对每个波对，把 :math:`Q` 乘以实测三阶乘积的平均，
   去掉同一个参考相位、取实部，再对所有保留波对求和：

   .. k05:equation:: comparison-transfer
      :lang: zh

      T^{(1/2)}_{V,f}
      =\frac{v_{g,y}(f)}{\Delta y}
       \operatorname{Re}\!\left[
         e^{-i\delta_f}\!
         \sum_{\substack{f_1+f_2=f\\ \mathrm{unique}}}
         Q_{f;f_1,f_2}
         \left\langle X_{f_1}X_{f_2}X_f^*\right\rangle_{\mathrm{test}}
       \right].

   下标 V 保留电压观测量的含义；上标 :math:`(1/2)` 标明采用文献 [1]
   式 (6) 的半功率约定：若写完整的模平方变化率，相应项是
   :math:`2T^{(1/2)}_{V,f}`。
   系数和 :math:`\delta_f` 来自三组训练数据，尖括号内的三阶平均来自整组留出的检验记录。
   求和使用拟合时的独立波对系数，还没有作二维图的平分处理。
   :math:`Q` 单位为 V⁻¹，三阶平均为 V³，最终得到 V²/s；
   它不是已经标定成 J m⁻³ s⁻¹ 的等离子体能量转移密度。

   在本次正群速度假设下，正值表示二次项对该频率信号功率作正贡献，负值表示负贡献。
   Kim 曲线在约 0.8 MHz 有正峰，约 1.9 MHz 有负谷；
   最小二乘结果与它有明显差别。
   图中较高频率接近零的是求和后的净值，不能据此断言各个波对都没有贡献，
   它们可能相互抵消。
   这项计算没有唯一指定哪一个频率向哪一个频率供能，
   也还没有包括二次部分自身的功率和完整残差收支。

   .. raw:: html

      <details class="k05-note"><summary>为什么交换两个频率后，要把一个系数分成两份？</summary>

   拟合只保留一次相同乘积，因为 :math:`X_{f_1}X_{f_2}=X_{f_2}X_{f_1}`；
   完整正方形图却显示两个交换位置。为保持总和不变，

   .. k05:equation:: comparison-symmetric-q
      :lang: zh

      Q^{\mathrm{sym}}_{f;f_1,f_2}=
      \begin{cases}
        Q^{\mathrm{unique}}_{f;f_1,f_2}/2,& f_1\ne f_2,\\
        Q^{\mathrm{unique}}_{f;f_1,f_1},& f_1=f_2 .
      \end{cases}

   非对角项平分可以防止重复计数，对角项本来就只有一次。
   负目标频率由
   :math:`Q^{\rm sym}_{-f;-f_1,-f_2}=(Q^{\rm sym}_{f;f_1,f_2})^*`
   补出，不是独立拟合。
   与文献定量比较系数大小之前，要统一波对计数和信号归一化。
   例如两通道共同改变电压尺度 :math:`s` 倍，会使 :math:`Q` 变为原来的
   :math:`1/s`，电压功率转移变为 :math:`s^2` 倍，:math:`L` 则不变。

   .. raw:: html

      </details>

   .. rubric:: 3．看完图之后，再判断这些结果意味着什么

   五个对应面板已经齐全。实测频谱是直接的统计结果；
   系数图和速率曲线还依赖所选模型、频带、观测量，速率另依赖假设的动力学分支。
   不能把这里的正负特征直接命名为文献 [1] 的同一组共振或级联：
   两个实验参数不同，而且本页四轮系数的目标频带止于 5 MHz 以下。

   从图中自然出现的下一个问题是：为什么两种估计方法得到的表观增长和转移不同？
   :ref:`下一补充页 <k05-budget-zh>` 按这个问题继续：
   检查推断的共同功率、解释参考相位旋转，再补齐实测功率收支的全部项。
   当前 368 个“频点 × 轮次”中，只有 35 个通过 Kim 共同功率上界，
   因此本页标为有条件的计算结果，还不能称为已确认的 EDI 增长或逆级联测量。

   .. raw:: html

      <details class="k05-note"><summary>复现图形，或者替换暂用估计参数</summary>

   保存的系数和矩来自 :code:`analyze_transfer_budget.py`，详细算法见补充页。
   新脚本读取这些数组、验证补充页的检验组功率和第六页的频谱，不重新拟合原始记录。
   在仓库根目录运行：

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_paper_comparison.py \
        --budget /path/to/budget/transfer_arrays.npz \
        --validation /path/to/validation/validation_arrays.npz \
        --spectra /path/to/spectra/spectral_arrays.npz \
        --config K_Diagnostics/K05_bispectral_transfer/paper_comparison_config.json \
        --output /path/to/new_comparison
      python K_Diagnostics/K05_bispectral_transfer/plot_paper_comparison.py \
        --output /path/to/new_comparison

   每套情景使用新输出目录。JSON 记录所有估计值、输入与代码哈希、单位和根的核验；
   NPZ 保留各轮数据及没有绘出的数组，SVG／PNG 共用这些数值。
   修改等离子体参数改变的是理论情景，并不会自动完成实测电压系数的标定。

   :download:`数值报告 </_static/K_Diagnostics/k05-comparison-summary.json>`。

   .. raw:: html

      </details>

   .. rubric:: 参考文献

   [1] Z. A. Brown and B. A. Jorns (2023), “Growth and Saturation of the Electron
   Drift Instability in a Crossed Field Plasma,” *Physical Review Letters*
   **130**, 115101，图 2–3、式 (4)、(6)、(7)。
   `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_。

   [2] J. Cavalier (2013), *Modèles cinétiques et caractérisation expérimentale
   des fluctuations électrostatiques dans un propulseur à effet Hall*，
   Université de Lorraine 博士论文，式 (2.7)–(2.9)，第 31–32 页。
   `机构全文 <https://docnum.univ-lorraine.fr/public/DDOC_T_2013_0130_CAVALIER.pdf>`_。
