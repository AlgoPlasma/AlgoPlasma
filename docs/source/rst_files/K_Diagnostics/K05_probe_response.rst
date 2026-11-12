09 · Supplement: what the probe measures
========================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-response-en:

   .. rubric:: Use a swept-probe record to obtain a temperature estimate

   .. container:: k05-text

      The :ref:`coefficient page <k05-experiment-coefficients-en>` compared simultaneous
      high-frequency signals from two probes held at fixed bias. Each probe can also
      be connected separately to a **voltage-sweep circuit** : vary its bias slowly
      and measure a mean current–voltage characteristic (I–V curve).
      This gives background quantities such as an effective electron temperature.
      Here, “sweep” refers to voltage, not mechanical motion.

   .. container:: k05-text

      Different processing choices can give substantially different temperatures
      from the same record. We first build the mean characteristic using
      **arithmetic means in imposed-voltage bins** , then subtract the ion background
      and fit the electron-current slope. This is the recommended baseline for an
      average I–V curve; sensitivity checks remain necessary to assess its accuracy.

   .. container:: k05-text

      C1 is the **left, fixed probe** ; C3 is the **right, movable probe** , held
      stationary during these records, 3.7 mm away azimuthally. Both tips are
      5.5 mm downstream of the exit, with exposed diameter 0.5 mm and length 2.5 mm.
      These positions do not establish the wave propagation direction.

   :ref:`Probe positions and dimensions <k05-experiment-geometry-en>` are shown on page 06.


   .. rubric:: 1. Select one sweep and identify the two measured voltages

   A slow sweep changes the probe bias and records the resulting current.
   CH3_2 measures the variable supply voltage :math:`V_s` in volts;
   CH4_2 measures the voltage :math:`u_R` across a sampling resistor
   :math:`R=1000\ \Omega`. These slow-recorder channel names are distinct from
   the fast oscilloscope's C1/C3.

   .. figure:: /_static/K_Diagnostics/k05-sweep-raw.svg
      :alt: Figure 1. The example record: supply and resistor voltages. The shaded ramp is used to build the characteristic.
      :width: 100%

      Figure 1. The example record: supply and resistor voltages. The shaded ramp is used to build the characteristic.


   .. container:: k05-text

      The example record contains 500001 samples at 50 kHz, covering 10 s [1].
      Use only the upward ramp: from the first :math:`V_s>5` V to just before the first
      :math:`V_s>349` V, here **2.40860–6.33114 s** .
      Do not mix the high-voltage hold or return into this ramp's characteristic.
      The plotted lines are 2 ms block means and the band is the 16–84% sample spread,
      not an uncertainty interval. The analysis uses the original samples.

   Figure B shows the voltage references. The slow circuit has a **100 V DC bias
   power supply**, :math:`V_b`, and a separate 0–350 V variable supply.
   The fast circuit instead uses a **40.5 V rechargeable battery** .

   .. figure:: /_static/K_Diagnostics/k05-response-circuits-en.svg
      :alt: Figure B. Fast battery circuit and slow power-supply circuit, with different references. Assumed polarity: tip minus clip. The drawing does not establish isolation or calibration.
      :width: 100%

      Figure B. Fast battery circuit and slow power-supply circuit, with different references. Assumed polarity: tip minus clip. The drawing does not establish isolation or calibration.


   For the slow circuit, :math:`V_p` is the probe voltage relative to the chamber.
   Take net collected current :math:`I` as positive for electron collection.
   With the recorded tip-minus-clip polarity, use:

   .. k05:equation:: response-sweep-circuit
      :lang: en

      V_p=V_s-V_b+u_R,\qquad I=-\frac{u_R}{R}=I_e-I_i,\qquad V_b=100\ \mathrm{V}.


   :math:`I_e` and :math:`I_i` are positive electron and ion current magnitudes in A.
   Net current can be negative because the ion contribution carries a minus sign.
   For example, :math:`V_s=150` V and :math:`u_R=-5` V give
   :math:`V_p=45` V and :math:`I=5` mA.
   **The supply setting alone is not the probe voltage** ; both the 100 V bias
   and the measured resistor voltage enter. The subscript :math:`b` means bias.

   .. raw:: html

      <details class="k05-note"><summary>Keep the two current signs distinct</summary>

   For resistor current :math:`i_R` positive from scope tip toward clip, use:

   .. k05:equation:: response-nominal-current
      :lang: en

      i_R=\frac{u_R}{R},\qquad R=1000\ \Omega\quad\Longrightarrow\quad 1\ \mathrm{V}\ \leftrightarrow\ 1\ \mathrm{mA}.


   The electron-positive net probe current is :math:`I=-i_R`.
   The sign distinguishes reference directions, not two measured current magnitudes.
   This low-frequency conversion alone does not specify MHz response.

   .. raw:: html

      </details>


   .. rubric:: 2. Make one curve point from a small voltage bin

   Divide the selected ramp into 1 V bins of the imposed voltage :math:`V_s`:
   5–6 V, 6–7 V, and so on. In each bin, average both recorded channels and apply
   the same conversion:

   .. k05:equation:: response-mean-sweep-point
      :lang: en

      \bar V_{p,j}=\bar V_{s,j}-V_b+\bar u_{R,j},\qquad \bar I_j=-\frac{\bar u_{R,j}}{R}.


   The bar denotes an arithmetic mean and :math:`j` labels a bin.
   Each pair :math:`(\bar V_{p,j},\bar I_j)` is one point on the mean I–V curve.
   Bins with fewer than eight samples are omitted. All samples in the other bins
   are retained; a large current alone does not make a sample an outlier.

   .. figure:: /_static/K_Diagnostics/k05-sweep-bin.svg
      :alt: Figure 2. One source-voltage bin: raw current samples and their distribution. The same samples have different mean and median currents.
      :width: 100%

      Figure 2. One source-voltage bin: raw current samples and their distribution. The same samples have different mean and median currents.


   The bin :math:`75\le V_s<76` V contains **576 samples** .
   Its mean current is **−0.0243 mA** , whereas its median is **−0.2083 mA** .
   The mean takes the sum divided by the count; the median is the middle value
   after sorting. The positive tail in Figure 2 moves the mean upward.
   The mean curve point is :math:`\bar V_p=-24.4578` V,
   :math:`\bar I=-0.02427` mA.

   This distinction matters before temperature fitting. A median can describe a
   typical sample, but does not preserve average collected current.
   **For a mean I–V characteristic, use arithmetic means as the baseline.**
   The asymmetric fluctuations' origin is not established by this plot.
   Below, :math:`V_p` and :math:`I` denote the mean curve's coordinates,
   with bars omitted for readability.

   .. rubric:: 3. Separate the electron current before taking a logarithm

   .. figure:: /_static/K_Diagnostics/k05-sweep-background.svg
      :alt: Figure 3. Mean I–V curve and the negative-current interval used to fit the ion background.
      :width: 100%

      Figure 3. Mean I–V curve and the negative-current interval used to fit the ion background.


   .. container:: k05-text

      The full positive-bias branch extends to about 233 V. Current rises much
      more slowly there: mean values over 40–80 and 180–230 V are about 14.07
      and 15.36 mA. This flattening is a useful collection-regime check, but not
      proof of accuracy: geometry, magnetic fields, or instrument current limiting
      can also affect the shape. The right panel magnifies the ion-background fit.

   .. container:: k05-text

      The curve's zero crossing is the **floating potential**
      :math:`V_f=-24.1458` V: electron and ion currents balance there.
      It is not the plasma potential.
      At sufficiently negative bias, the negative ion contribution dominates.
      Fit a straight background line over **−80 to −50 V** , then evaluate that line
      over the electron-fit region:

   .. k05:equation:: response-ion-subtraction
      :lang: en

      I_{\mathrm{ion,fit}}(V_p)=aV_p+b,\qquad I_e(V_p)=I(V_p)-I_{\mathrm{ion,fit}}(V_p).


   :math:`I_{\mathrm{ion,fit}}` is a **signed, negative background** , not the positive
   magnitude :math:`I_i`. The slope :math:`a` has units A/V; the intercept :math:`b`
   has units A. Here they are :math:`2.4161\times10^{-6}` A/V and
   :math:`-2.8955\times10^{-4}` A.
   For example, net current 1.0 mA minus background −0.3 mA gives electron current 1.3 mA.

   Use the corrected :math:`I_e` for the logarithm [2].
   Do not take the logarithm of negative net current, use an absolute value to hide
   its sign, or replace nonpositive corrected current by a tiny number.
   Revisit the subtraction or fit interval instead.
   The background is an extrapolated approximation; its effect is tested below.

   .. rubric:: 4. Choose an interval, fit its slope, and convert the units

   We need a region where corrected electron current rises approximately
   exponentially with voltage: the **electron-retarding region** .
   Two landmarks place a trial interval without selecting it for a desired temperature.
   The lower landmark is :math:`V_f`. For the upper landmark, smooth the mean curve
   and locate the peak in its slope :math:`\mathrm{d}I/\mathrm{d}V_p`.
   Call this **plasma-potential candidate** :math:`V_{\mathrm{pl}}^*`:
   the star marks an estimate for interval selection, not an independently measured potential.

   .. figure:: /_static/K_Diagnostics/k05-sweep-fit.svg
      :alt: Figure 4. Locate an upper landmark using smoothed derivatives, then fit the logarithm of corrected electron current in the selected interval.
      :width: 100%

      Figure 4. Locate an upper landmark using smoothed derivatives, then fit the logarithm of corrected electron current in the selected interval.


   .. container:: k05-text

      For this sweep the candidate is **4.5 V** . Keep a 2 V margin above :math:`V_f` and a
      5 V margin below the candidate. The requested fit interval is therefore
      **−22.1458 to −0.5 V** . It contains 26 binned points, with actual endpoints
      −21.5728 and −0.6814 V. The margins are choices to check, not universal constants.

   .. raw:: html

      <details class="k05-note"><summary>How is the 4.5 V candidate obtained?</summary>

   Interpolate the mean curve onto a 0.5 V grid from −80 to 60 V.
   Use a cubic Savitzky–Golay local polynomial to calculate a smoothed first derivative.
   For nominal smoothing spans of 5, 7, 9, 11, 15, 19, and 23 V, find the largest
   derivative between :math:`V_f+5` V and 45 V.
   The peak positions are 4.5, 3.5, 4.0, 4.5, 4.5, 4.5, and 4.5 V.
   The median of the six positions for spans of at least 7 V is 4.5 V.

   This median summarizes peak locations; it does not replace the current mean
   in each source bin. Smoothing locates the feature; the electron fit still uses
   the unsmoothed binned mean curve. If the peak is ambiguous or shifts strongly
   with smoothing, inspect the curve before trusting its upper fit boundary.

   .. raw:: html

      </details>


   For the selected points, plot :math:`\ln[I_e/(1\,\mathrm{mA})]` against
   :math:`V_p` and fit a straight line. Use its slope, rather than its height:

   .. k05:equation:: response-temperature-slope
      :lang: en

      I_e=I_*\exp\!\left(\frac{V_p-V_*}{\Theta_e}\right),\qquad \ln\!\left(\frac{I_e}{I_{\mathrm{ref}}}\right)=mV_p+c,\qquad \Theta_e=\frac{1}{m}=\frac{k_B T_e}{e}.


   :math:`I_*` is an electron-current scale at reference voltage :math:`V_*`;
   :math:`I_{\mathrm{ref}}=1` mA makes the logarithm dimensionless.
   :math:`m` is the slope in V⁻¹ and :math:`c` a dimensionless intercept.
   :math:`\Theta_e` is temperature expressed as a voltage;
   :math:`k_B` is Boltzmann's constant, :math:`T_e` temperature in kelvin, and
   :math:`e` the positive elementary charge.
   The numerical value of :math:`\Theta_e` in volts equals that of electron temperature
   in eV, denoted :math:`T_{e,\mathrm{fit}}` in the figures.

   Here :math:`m=0.1090643\ \mathrm{V}^{-1}`, so **the fitted temperature is
   1/0.1090643 = 9.1689 eV**. A larger slope gives a smaller temperature.
   Under the approximate single-temperature, Maxwellian interpretation, this is an effective slope temperature.
   The line's :math:`R^2=0.9928` describes this interval's straightness;
   it does not validate every physical assumption of the diagnostic.

   .. raw:: html

      <details class="k05-note"><summary>The short Python calculation, with units specified</summary>

   Arrays ``Vp`` and ``I`` are the binned mean probe voltage in V and net current
   in A. ``Vf`` and ``Vpl_candidate`` are also in V:

   .. code-block:: python

      ion = (Vp >= -80) & (Vp <= -50)
      a, b = np.polyfit(Vp[ion], I[ion], 1)
      Ie = I - (a * Vp + b)
      use = (Vp >= Vf + 2) & (Vp <= Vpl_candidate - 5)
      assert use.sum() >= 8 and np.all(Ie[use] > 0)
      m, c = np.polyfit(Vp[use], np.log(Ie[use] / 1e-3), 1)
      assert m > 0
      Te_eV = 1 / m

   ``np.log`` is the natural logarithm. Using ``np.log10`` without changing the
   conversion gives the wrong temperature. Consistently changing current units
   changes the intercept, not the slope.
   Each binned point has equal fit weight, regardless of its raw sample count.

   .. raw:: html

      </details>


   .. rubric:: 5. Why does another choice give about 6 rather than 9 eV?

   .. container:: k05-text

      Keep the raw record fixed at **the example sweep** . Compare the mean workflow above with one
      that first reconstructs each instantaneous :math:`V_p`, groups those values in
      2 V bins, and takes medians. These are different summaries before either fit.

   .. figure:: /_static/K_Diagnostics/k05-sweep-comparison.svg
      :alt: Figure 5. The same example sweep samples, summarized and fitted in two ways. Thick fitted segments have different slopes, giving 9.17 and 6.73 eV.
      :width: 100%

      Figure 5. The same example sweep samples, summarized and fitted in two ways. Thick fitted segments have different slopes, giving 9.17 and 6.73 eV.


   .. list-table::
      :header-rows: 1
      :widths: auto

      * - Curve construction
        - Ion interval; electron interval [V]
        - Fit [eV]
      * - Mean in 1 V source bins
        - [−80, −50]; [Vf+2, Vpl*−5]
        - 9.17
      * - Median in 2 V instantaneous probe bins
        - [−90, −70]; [Vf−5, Vf+10]
        - 6.73
      * - Mean in 1 V source bins
        - [−90, −70]; [Vf−5, Vf+10]
        - 9.14



   The first two rows change several choices together. The third row is a useful
   check: **the mean curve still gives 9.14 eV with the older fitting rules** .
   Conversely, applying the present absolute fit interval and background to the old
   median curve gives 6.81 eV. For this record, the main 6-to-9 difference comes from
   constructing a different I–V curve, not simply moving the fit endpoints.

   There are two effects. The current distribution is asymmetric, so mean and median
   differ. Also, instantaneous :math:`V_p=V_s-V_b+u_R` contains the same fluctuating
   :math:`u_R` used to calculate current. Grouping by it and by imposed :math:`V_s`
   selects different samples.
   Keeping the 1 V source bins but replacing means by medians gives **7.06 eV**
   with the same absolute fit intervals, isolating much of the averaging effect.

   The median calculation is not an arithmetic failure; it fits a different
   characteristic. For an **average** characteristic, the mean workflow is the
   appropriate main result. Neither number alone establishes the unperturbed bulk
   temperature: averaging a fluctuating nonlinear I–V response can alter its shape [5].

   .. raw:: html

      <details class="k05-note"><summary>The exact comparison settings</summary>

   The old median workflow uses a linear ion background over −90 to −70 V and
   electron window :math:`[V_f-5,V_f+10]`. Its :math:`V_f=-18.0667` V differs from
   the mean curve's zero crossing. “Mean curve with old rules” recalculates
   :math:`V_f` on the mean curve, retaining the relative rule rather than the old
   absolute endpoints.

   .. container:: k05-text

      The complementary checks fix both electron bounds [−22.1458, −0.5] V and ion
      bounds [−80, −50] V: the old 2 V probe-bin median gives 6.81 eV; the 1 V source-bin
      median gives 7.06 eV. Both readers decode identical CH3_2/CH4_2 samples for this sweep,
      and both workflows use the same signs and conversion. The difference is not a
      readout scale error or a missing factor of 3/2.

   .. raw:: html

      </details>


   .. rubric:: 6. Check the choices and the repeated measurements

   Keep the mean curve and vary the choices systematically. Figure 6 first varies
   the electron-fit margins, then holds them fixed while changing the ion background.
   In the axes, :math:`V_{\mathrm{low}}` and :math:`V_{\mathrm{high}}` are the lower
   and upper electron-fit endpoints.

   .. figure:: /_static/K_Diagnostics/k05-sweep-sensitivity.svg
      :alt: Figure 6. Electron-fit margins (left) and ion-background choices (right). The outlined cell is the main setting; all 72 combinations are retained in the report.
      :width: 100%

      Figure 6. Electron-fit margins (left) and ion-background choices (right). The outlined cell is the main setting; all 72 combinations are retained in the report.


   .. container:: k05-text

      All **72 predefined combinations** give **8.65–10.15 eV** for this sweep:
      three lower margins × three upper margins × four ion intervals × two backgrounds
      (linear or constant). All 72 results are retained.
      This is a processing-sensitivity range, **not a confidence interval** .
      Changing only source-bin width to 0.5, 1, or 2 V, with the physical fit endpoints
      fixed, gives **9.13, 9.17, and 9.16 eV** .
      These ordinary width and interval variations do not explain the full 6.7-to-9.2 difference.

   Apply the same mean workflow separately to the repeated sweeps:

   .. list-table::
      :header-rows: 1
      :widths: auto

      * - Sweep
        - Mean-curve fit [eV]
        - 72-choice range [eV]
      * - 1
        - 9.17
        - 8.65–10.15
      * - 2
        - 9.05
        - 8.73–10.03
      * - 3
        - 9.06
        - 8.57–10.24
      * - 4
        - 8.97
        - 8.35–9.81



   .. container:: k05-text

      Their mean is **9.06 eV** , with a range of **8.97–9.17 eV** .
      The 9.17 eV value belongs to **the example sweep alone** , not the four-record average.
      Do not pool records first or substitute an average for individual results.

   .. raw:: html

      <details class="k05-note"><summary>What happens to the earlier sweeps?</summary>

   .. container:: k05-text

      The earlier set and repeat set are kept separate.
      The same mean workflow gives:

   .. list-table::
      :header-rows: 1
      :widths: auto

      * - Sweep
        - Mean-curve fit [eV]
        - 72-choice range [eV]
      * - 1
        - 8.77
        - 7.92–10.13
      * - 2
        - 8.96
        - 8.13–9.85
      * - 3
        - 8.64
        - 7.92–9.75
      * - 4
        - 8.67
        - 7.38–9.55



   .. container:: k05-text

      The median workflow gave 5.78–6.52 eV (mean 6.23 eV) for the earlier set, and
      6.00–6.73 eV (mean 6.40 eV) for the repeat set.
      The mean workflow raises both sets; choosing the repeat measurement alone
      does not explain the change. An experimental quality concern about the earlier set
      has no established cause. These records remain available but are not pooled
      with the repeat set or used to establish its accuracy.

   .. raw:: html

      </details>


   .. container:: k05-text

      The late mean current of the example sweep's high-voltage hold is about **26.9% below** its
      early value. The hold is excluded from the fit, but the change prompts a check
      of time dependence. It does not identify the cause as plasma, surface, or instrument.
      A defensible report states **the example record, source-bin arithmetic mean, specified
      background and fit interval, slope temperature 9.17 eV, and the sensitivity tests**.
      A precise decimal is not an accuracy guarantee.

   .. rubric:: 7. Use the characteristic to check the fast probe's bias

   .. container:: k05-text

      **Why check this?** The high-frequency signal is intended to represent ion
      collection. That interpretation requires the probe to sit on a sufficiently
      negative part of the characteristic, where electron current is small.
      Near the floating potential or electron-retarding region, electron-current
      fluctuations can also affect the signal. The slow curve locates this working
      point before we interpret fast fluctuations as an ion-current proxy.

   The fast probe's 40.5 V battery is referenced to the cathode negative terminal.
   Let :math:`V_c` be that terminal's voltage relative to the chamber.
   With electron-positive net current, the operating point must satisfy the I–V
   curve and this load-line condition:

   .. k05:equation:: response-fast-bias
      :lang: en

      V_p=V_c-40.5\ \mathrm{V}-R I(V_p).


   Choose a candidate :math:`V_c`, draw
   :math:`I=(V_c-40.5\,\mathrm{V}-V_p)/R`, and find its intersection with the curve.
   The battery voltage alone does not locate it.

   .. figure:: /_static/K_Diagnostics/k05-sweep-bias.svg
      :alt: Figure 7. Intersections of the example sweep mean curve and three load lines. Cathode-to-chamber voltages are assumed, not measured.
      :width: 100%

      Figure 7. Intersections of the example sweep mean curve and three load lines. Cathode-to-chamber voltages are assumed, not measured.


   :math:`V_c=-20,0,+20` V are **illustrative assumptions** .
   For the example sweep mean curve the intersections are
   :math:`V_p=-60.07,-40.14,-20.68` V.
   The fitted electron-to-ion current ratios there are approximately **0.02, 0.07, 1.53** .
   Whether this is mainly an ion-current signal therefore depends on the reference
   voltage and working point. These examples also assume the slow characteristic
   represents the fast probe's location and plasma conditions.

   .. rubric:: 8. Separate a slow current conversion from a MHz response

   .. container:: k05-text

      A 1 kΩ resistor gives a nominal conversion at low frequency.
      No discrete capacitor is specified in the experimental circuit. Nevertheless,
      the cable conductor and shield, voltage probe, and oscilloscope input can
      introduce **parasitic or input capacitance** [3]. At MHz frequencies it may
      alter amplitude and phase. Its effective value has not been measured here.
      The simple R–C model below illustrates sensitivity, not a diagnosed cause
      of the observed high-frequency residuals.

   .. raw:: html

      <details class="k05-note"><summary>How to use the simple R–C response model</summary>

   .. container:: k05-text

      Illustrative effective capacitances are 20, 100 and 200 pF; none is a measured value.

   .. figure:: /_static/K_Diagnostics/k05-response-rc.svg
      :alt: Figure 8. Estimated R–C response: magnitude and phase in the K05 Fourier convention.
      :width: 100%

      Figure 8. Estimated R–C response: magnitude and phase in the K05 Fourier convention.



   Assume an effective capacitance :math:`C` in parallel with :math:`R`.
   Use frequency :math:`f` in Hz, capacitance in F, and resistance in Ω:

   .. k05:equation:: response-rc
      :lang: en

      i_R=\frac{u_R}{R}+C\frac{\mathrm{d}u_R}{\mathrm{d}t},\qquad Z_+(f)\equiv\frac{\widehat u_R}{\widehat i_R}=\frac{R}{1-i2\pi fRC},\qquad f_c=\frac{1}{2\pi RC}.


   :math:`i_R` is total current into the parallel circuit, :math:`u_R` its voltage,
   and :math:`t` time. A hat denotes a Fourier coefficient; :math:`i` in the denominator
   is the imaginary unit. :math:`Z_+` is the current-to-voltage response in Ω,
   using the positive-exponent Fourier convention of page 03.
   :math:`f_c` is where the response magnitude falls to :math:`R/\sqrt{2}`.

   For :math:`C=100` pF and :math:`R=1` kΩ, :math:`f_c=1.59` MHz.
   At 5 MHz, :math:`|Z_+|/R=0.303` and phase is about +72.3° in this convention.
   With a calibrated response, divide voltage coefficients by :math:`Z_+` to
   obtain current coefficients, or voltage power by :math:`|Z_+|^2` for current power.
   Do not use these estimated curves as measured corrections: cables, inputs and
   probes may differ, and division can amplify noise.

   .. raw:: html

      </details>


   Each channel's response matters when interpreting two-probe model coefficients.
   A current-related signal is also not automatically a density-only signal.
   The following expressions state conditions needed to use those interpretations [4].

   .. raw:: html

      <details class="k05-note"><summary>Use the response in L and Q; distinguish current from density</summary>

   Assume channel voltage equals current times a linear frequency response,
   :math:`Z_1` or :math:`Z_3`. For pairs satisfying :math:`f=f_1+f_2`:

   .. k05:equation:: response-model-coefficients
      :lang: en

      L_f^{\mathrm{meas}}=\frac{Z_3(f)}{Z_1(f)}L_f^{i},\qquad Q_{f;1,2}^{\mathrm{meas}}=\frac{Z_3(f)}{Z_1(f_1)Z_1(f_2)}Q_{f;1,2}^{i}.


   “meas” denotes voltage-model coefficients and superscript :math:`i` denotes
   current-model coefficients, not the imaginary unit.
   :math:`L` is linear and :math:`Q` quadratic; :math:`f_1,f_2` are input frequencies.
   To obtain current coefficients, multiply measured :math:`L` by :math:`Z_1/Z_3`
   and measured :math:`Q` by :math:`Z_1(f_1)Z_1(f_2)/Z_3(f)`.
   Even equal channel responses do not generally cancel from :math:`Q`.

   Under an ion-collection approximation, also check:

   .. k05:equation:: response-density-temperature
      :lang: en

      I_i\propto A_{\mathrm{eff}}n_i\sqrt{\frac{k_B T_e}{m_i}},\qquad \frac{\delta I_i}{I_i}\simeq\frac{\delta n_i}{n_i}+\frac{1}{2}\frac{\delta T_e}{T_e}\quad(A_{\mathrm{eff}},m_i\ \mathrm{fixed}).


   :math:`A_{\mathrm{eff}}` is effective collecting area, :math:`n_i` ion density,
   and :math:`m_i` ion mass; :math:`\delta` denotes a small fluctuation about the mean.
   The second expression assumes fixed area and mass.
   Temperature fluctuations can therefore contribute even to ion-dominated current.
   An appropriate collection model and working point are required. Voltage-model
   coefficients alone are not calibrated density growth or plasma-energy transfer.

   .. raw:: html

      </details>


   .. raw:: html

      <details class="k05-note"><summary>Reproduce this workflow</summary>

   From the repository root, use configuration
   ``K_Diagnostics/K05_bispectral_transfer/probe_sweep_config.json``:

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_probe_sweep.py \
        --data /path/to/supplementary_scans \
        --output /path/to/separate_output

   .. container:: k05-text

      File mapping: the example and repeat sweeps 1–4 are 10140015–10140018.WDF;
      the earlier sweeps 1–4 are 10140008–10140011.WDF.
      Outputs include source/configuration/raw-file hashes, averaged arrays, intervals,
      all sensitivity cases, comparisons, and SVG/PNG figures. Raw files are read-only.
      The original median workflow remains available for the controlled comparison;
      it is not the main temperature method on this page.

   :download:`Download the numerical report </_static/K_Diagnostics/k05-sweep-summary.json>`.

   .. raw:: html

      </details>


   .. rubric:: Next: compare the experimental figures

   :ref:`The next page <k05-comparison-en>` displays counterparts of the
   spectra, dispersion, growth and coupling figures in Brown and Jorns (2023),
   then explains how each panel is calculated. The following
   :ref:`supplement <k05-budget-en>` checks the interpretation and complete power budget.

   .. rubric:: References

   [1] Yokogawa, *DL350 ScopeCorder User's Manual*, IM DL350-01EN,
   Appendix 9, App-19–24.
   `WDF file structure and voltage/time scales <https://cdn.tmi.yokogawa.com/1/10105/files/IMDL350-00EN.pdf>`_.

   [2] R. L. Stenzel, UCLA Plasma Physics Laboratory (1997),
   `Langmuir Probe Trace Evaluation <https://www.physics.ucla.edu/plasma-exp/180E-W97/LprobeAnalysis.html>`_
   and `The Retardation Region <https://www.physics.ucla.edu/plasma-exp/180E-W97/RetRegAnalysis.html>`_.

   [3] Tektronix, `ABCs of Probes Primer <https://www.tek.com/en/documents/whitepaper/abcs-probes-primer>`_.

   .. container:: k05-text

      [4] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
      Instability in a Crossed Field Plasma,” *Physical Review Letters* **130** , 115101 (2023).
      `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   [5] F. F. Chen (2012), *Langmuir probe measurements in the intense RF field of a helicon discharge*,
   UCLA report LTP-1205, pp. 1–2 and 5–7.
   `Probe characteristics and fluctuations <https://www.seas.ucla.edu/~ffchen/Publs/Chen232R.pdf>`_.

.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-response-zh:

   .. rubric:: 怎样用一次探针扫描，得到一个温度估计

   .. container:: k05-text

      前面的 :ref:`实测系数计算 <k05-experiment-coefficients-zh>` 使用两支探针在固定偏压下
      同步记录高频波动。同一支探针也可以单独改接 **电压扫描电路** ：
      缓慢改变偏压，测得平均电流—电压特性（I–V characteristic），
      从中估计电子温度等背景平均量。本页的“扫描”指改变电压，不是移动探针。

   .. container:: k05-text

      同一份记录采用不同处理方法，可能得到差别很大的温度。
      下面先按 **外加电源电压分箱取算术平均** 整理平均 I–V 曲线，
      再扣除离子背景、拟合电子电流斜率。这是估计平均特性的推荐基准；
      是否准确仍要结合拟合区间、波动和重复测量检查，不能只看结果接近某个预期值。

   .. container:: k05-text

      C1 是 **左侧固定探针** ，C3 是 **右侧可移动探针** ，
      但在本组采集中保持位置不变。两者周向间距 3.7 mm，距出口轴向 5.5 mm，
      暴露尖端直径 0.5 mm、长度 2.5 mm。探针位置本身不能确定波传播方向。

   :ref:`探针位置与尺寸示意图 <k05-experiment-geometry-zh>` 见第 06 页。


   .. rubric:: 1．先选一次扫描，认清两路实际测到的电压

   慢扫描改变探针的偏压，同时记录收集电流如何变化。
   CH3_2 测量可调电源电压 :math:`V_s`，CH4_2 测量采样电阻两端电压
   :math:`u_R`，两者单位都是 V；电阻为 :math:`R=1000\ \Omega`。
   这些慢扫描通道名称与高频示波器的 C1/C3 不同。

   .. figure:: /_static/K_Diagnostics/k05-sweep-raw.svg
      :alt: 图 1．本例扫描的电源与电阻电压。阴影选中的上升段用于整理 I–V 曲线。
      :width: 100%

      图 1．本例扫描的电源与电阻电压。阴影选中的上升段用于整理 I–V 曲线。


   .. container:: k05-text

      本例扫描含 500001 个采样点，采样率 50 kHz，记录长 10 s [1]。
      只取上升扫描段：从首次 :math:`V_s>5` V，到首次 :math:`V_s>349` V 之前，
      对应 **2.40860–6.33114 s** 。高压保持段和回落段属于另外的测量阶段，
      不混进这次上升扫描的曲线。
      图中线条为 2 ms 小段的均值，色带为段内采样点的 16–84% 分布范围，
      不是误差区间；计算使用原始采样点。

   图 B 标出了电压参考。慢扫描使用 **100 V 直流偏置电源**
   :math:`V_b` 和另一台 0–350 V 可调电源；
   高频电路则使用 **40.5 V 蓄电池** 。

   .. figure:: /_static/K_Diagnostics/k05-response-circuits-zh.svg
      :alt: 图 B．高频蓄电池电路与慢扫描电源电路，注意两者参考不同。极性按“尖端减地夹”；图示不代表已确认隔离或完成标定。
      :width: 100%

      图 B．高频蓄电池电路与慢扫描电源电路，注意两者参考不同。极性按“尖端减地夹”；图示不代表已确认隔离或完成标定。


   在慢扫描电路中，:math:`V_p` 是探针相对真空罐的电压，
   净收集电流 :math:`I` 采用电子收集为正的约定。
   按记录的“示波器尖端电位减地夹电位”极性，直接使用：

   .. k05:equation:: response-sweep-circuit
      :lang: zh

      V_p=V_s-V_b+u_R,\qquad I=-\frac{u_R}{R}=I_e-I_i,\qquad V_b=100\ \mathrm{V}.


   :math:`I_e` 和 :math:`I_i` 是取正值的电子、离子电流大小，单位 A。
   因此净电流可以为负：离子贡献带负号。
   例如 :math:`V_s=150` V、:math:`u_R=-5` V 时，
   :math:`V_p=45` V、:math:`I=5` mA。
   **电源读数不等于探针电压** ：还要计入 100 V 偏置和实际电阻电压。
   下标 :math:`b` 表示 bias（偏置）。

   .. raw:: html

      <details class="k05-note"><summary>两个电流符号为什么相反？</summary>

   若电阻电流 :math:`i_R` 取示波器尖端流向地夹为正，低频换算为：

   .. k05:equation:: response-nominal-current
      :lang: zh

      i_R=\frac{u_R}{R},\qquad R=1000\ \Omega\quad\Longrightarrow\quad 1\ \mathrm{V}\ \leftrightarrow\ 1\ \mathrm{mA}.


   电子收集为正的探针净电流则是 :math:`I=-i_R`。
   负号来自参考方向不同，不是测出了两个大小不同的电流。
   这一换算本身不规定 MHz 下的电路响应。

   .. raw:: html

      </details>


   .. rubric:: 2．把一小段电压范围内的采样点，整理成一个曲线点

   按照外加电源电压 :math:`V_s`，把上升段分成 1 V 宽的小区间
   （voltage bin，电压分箱）：5–6 V、6–7 V，依次排列。
   在每个区间内，分别对两路电压取算术平均，再做相同的换算：

   .. k05:equation:: response-mean-sweep-point
      :lang: zh

      \bar V_{p,j}=\bar V_{s,j}-V_b+\bar u_{R,j},\qquad \bar I_j=-\frac{\bar u_{R,j}}{R}.


   上横线表示算术平均，下标 :math:`j` 是区间编号。
   每个 :math:`(\bar V_{p,j},\bar I_j)` 就是平均 I–V 曲线上的一个点。
   少于 8 个采样点的区间不使用；其余区间保留全部采样点，
   不会仅因某点电流偏大就将它剔除。

   .. figure:: /_static/K_Diagnostics/k05-sweep-bin.svg
      :alt: 图 2．一个电源电压分箱内的原始电流采样及分布：同一批数值的均值与中位数不同。
      :width: 100%

      图 2．一个电源电压分箱内的原始电流采样及分布：同一批数值的均值与中位数不同。


   :math:`75\le V_s<76` V 这个区间有 **576 个采样点** 。
   电流均值是 **−0.0243 mA** ，中位数却是 **−0.2083 mA** 。
   均值（mean）是全部数值相加后除以个数；
   中位数（median）是排序后居中的数值。
   图 2 中电流分布向正方向拖着一条尾巴，这些较大值把均值向上拉。
   由此得到的平均曲线点为 :math:`\bar V_p=-24.4578` V、
   :math:`\bar I=-0.02427` mA。

   这一步在拟合温度之前就已经改变了曲线。
   中位数可以描述“典型采样值”，但不保留平均收集电流。
   **若目标是平均 I–V 特性，主分析应采用算术平均。**
   这张图尚不能确定不对称波动的来源，也不能把正向尾部自动当作仪器坏点。
   为便于阅读，下文把平均曲线的坐标简写为 :math:`V_p` 和 :math:`I`，省略上横线。

   .. rubric:: 3．先扣除离子背景，再对电子电流取对数

   .. figure:: /_static/K_Diagnostics/k05-sweep-background.svg
      :alt: 图 3．平均 I–V 特性，以及用于拟合离子背景的负电流区间。
      :width: 100%

      图 3．平均 I–V 特性，以及用于拟合离子背景的负电流区间。


   .. container:: k05-text

      完整正偏压支延伸到约 233 V。高电压处电流上升明显趋缓：
      40–80 V 与 180–230 V 区间平均电流约为 14.07 和 15.36 mA。
      这种趋平现象有助于检查收集区间，但不能单凭平台就认定实验准确；
      探针几何、磁场或仪器限流也可能改变形状。右图放大离子背景拟合区。

   .. container:: k05-text

      电流过零的位置称为 **浮动电势（floating potential）**
      :math:`V_f=-24.1458` V：这里电子与离子电流相互抵消。它不是等离子体电势。
      在足够负的偏压处，负的离子贡献占主导。
      本例选 **−80 到 −50 V** 的曲线点，用直线拟合离子背景，
      再把这条直线延伸到准备分析的电子区间：

   .. k05:equation:: response-ion-subtraction
      :lang: zh

      I_{\mathrm{ion,fit}}(V_p)=aV_p+b,\qquad I_e(V_p)=I(V_p)-I_{\mathrm{ion,fit}}(V_p).


   :math:`I_{\mathrm{ion,fit}}` 是 **带负号的背景电流** ，
   与取正值的离子电流大小 :math:`I_i` 要区分。
   :math:`a` 为斜率，单位 A/V；:math:`b` 为截距，单位 A。
   本例分别是 :math:`2.4161\times10^{-6}` A/V 和
   :math:`-2.8955\times10^{-4}` A。
   例如净电流 1.0 mA，拟合背景 −0.3 mA，
   电子电流就是 1.0−(−0.3)=1.3 mA。

   后面取对数的是扣除后的 :math:`I_e` [2]。
   不能对负的净电流直接取对数，也不能取绝对值掩盖符号，
   或把非正的电子电流替换为很小的正数后继续拟合；
   应重新检查背景扣除和拟合区间。
   离子背景外推是一种近似，后面会检查换背景时结果变化多少。

   .. rubric:: 4．选定电压区间，拟合斜率，再换成温度

   需要找到一段区域：探针电压增加时，电子电流近似按指数增长。
   这叫 **电子阻滞区（electron-retarding region）** 。
   先用两个位置给出试用区间，再检查拟合，避免为了得到某个温度而选点。
   下端参考浮动电势 :math:`V_f`。
   上端参考平均曲线平滑后斜率 :math:`\mathrm{d}I/\mathrm{d}V_p` 的峰值位置，
   记作 **等离子体电势候选值（plasma-potential candidate）**
   :math:`V_{\mathrm{pl}}^*`。星号表示它是选区间时使用的估计，
   尚不是独立测得的等离子体电势。

   .. figure:: /_static/K_Diagnostics/k05-sweep-fit.svg
      :alt: 图 4．先用平滑导数找上端参考位置，再在选定区间内拟合扣除背景后的电子电流对数。
      :width: 100%

      图 4．先用平滑导数找上端参考位置，再在选定区间内拟合扣除背景后的电子电流对数。


   .. container:: k05-text

      本例扫描的候选值为 **4.5 V** 。下端选在 :math:`V_f` 之上 2 V，
      上端选在候选值之下 5 V，因此请求的拟合区间为 **−22.1458 到 −0.5 V** 。
      其中实际落入 26 个分箱点，最左和最右点为 −21.5728、−0.6814 V。
      这两个余量是需要检查的分析选择，并非普适常数。

   .. raw:: html

      <details class="k05-note"><summary>4.5 V 候选值具体怎样选出来？</summary>

   先把均值曲线插值到 −80 至 60 V、步长 0.5 V 的网格，
   用三次 Savitzky–Golay 局部多项式计算平滑的一阶导数。
   依次使用名义宽度 5、7、9、11、15、19、23 V，
   各自在 :math:`V_f+5` V 到 45 V 内寻找最大的导数。
   峰位置分别为 4.5、3.5、4.0、4.5、4.5、4.5、4.5 V；
   对宽度不小于 7 V 的六个峰位置取中位数，得到 4.5 V。

   这里的中位数用于综合几个“峰的位置”，没有把分箱电流均值换成中位数。
   平滑只用于找特征；电子拟合仍使用未平滑的分箱均值曲线。
   若峰不唯一、或随平滑宽度明显跳动，就要先检查曲线，不能直接信任由它确定的上边界。

   .. raw:: html

      </details>


   对这些点，以 :math:`V_p` 为横坐标，
   :math:`\ln[I_e/(1\,\mathrm{mA})]` 为纵坐标拟合直线。
   取它的斜率，而不是直线的高低：

   .. k05:equation:: response-temperature-slope
      :lang: zh

      I_e=I_*\exp\!\left(\frac{V_p-V_*}{\Theta_e}\right),\qquad \ln\!\left(\frac{I_e}{I_{\mathrm{ref}}}\right)=mV_p+c,\qquad \Theta_e=\frac{1}{m}=\frac{k_B T_e}{e}.


   :math:`I_*` 是参考电压 :math:`V_*` 处的电子电流尺度；
   :math:`I_{\mathrm{ref}}=1` mA 让对数内部没有量纲。
   :math:`m` 是拟合斜率，单位 V⁻¹；:math:`c` 是无量纲截距。
   :math:`\Theta_e` 是用电压表示的温度；
   :math:`k_B` 为玻尔兹曼常数，:math:`T_e` 为用 K 表示的温度，
   :math:`e` 为正的元电荷。
   :math:`\Theta_e` 用 V 表示时的数值，就是电子温度用 eV 表示时的数值，
   图中记作 :math:`T_{e,\mathrm{fit}}`。

   本例 :math:`m=0.1090643\ \mathrm{V}^{-1}`，
   所以 **拟合温度为 1/0.1090643 = 9.1689 eV** 。
   斜率越大，得到的温度越小。
   这里按近似单温 Maxwell 分布来解释，得到的是有效斜率温度。
   直线的 :math:`R^2=0.9928` 说明这段数据接近直线，
   不能单独证明诊断的全部物理假设都成立。

   .. raw:: html

      <details class="k05-note"><summary>对应的 Python 计算：把输入和单位写清楚</summary>

   数组 ``Vp`` 为分箱后的平均探针电压，单位 V；``I`` 为净电流，单位 A。
   ``Vf`` 和 ``Vpl_candidate`` 的单位也都是 V：

   .. code-block:: python

      ion = (Vp >= -80) & (Vp <= -50)
      a, b = np.polyfit(Vp[ion], I[ion], 1)
      Ie = I - (a * Vp + b)
      use = (Vp >= Vf + 2) & (Vp <= Vpl_candidate - 5)
      assert use.sum() >= 8 and np.all(Ie[use] > 0)
      m, c = np.polyfit(Vp[use], np.log(Ie[use] / 1e-3), 1)
      assert m > 0
      Te_eV = 1 / m

   ``np.log`` 是自然对数；换成 ``np.log10`` 却仍直接取斜率倒数，就会算错。
   一致地改变电流单位只改变截距，不改变斜率。
   每个分箱点在拟合中权重相同，不按箱内原始采样点数量加权。

   .. raw:: html

      </details>


   .. rubric:: 5．为什么换一种选择，会得到约 6 而不是约 9 eV？

   .. container:: k05-text

      仍使用 **同一份原始记录**。另一种流程是：
      先逐点计算瞬时 :math:`V_p`，按它分成 2 V 区间，再取中位数。
      两种流程在拟合之前，就把同一批采样点整理成了不同曲线。

   .. figure:: /_static/K_Diagnostics/k05-sweep-comparison.svg
      :alt: 图 5．同一份扫描数据经两种整理与拟合得到不同斜率。粗线为实际拟合段，分别对应 9.17 和 6.73 eV。
      :width: 100%

      图 5．同一份扫描数据经两种整理与拟合得到不同斜率。粗线为实际拟合段，分别对应 9.17 和 6.73 eV。


   .. list-table::
      :header-rows: 1
      :widths: auto

      * - 曲线整理方式
        - 离子区间；电子区间 [V]
        - 温度 [eV]
      * - 1 V 电源分箱，取均值
        - [−80, −50]；[Vf+2, Vpl*−5]
        - 9.17
      * - 2 V 瞬时探针电压分箱，取中位数
        - [−90, −70]；[Vf−5, Vf+10]
        - 6.73
      * - 1 V 电源分箱，取均值
        - [−90, −70]；[Vf−5, Vf+10]
        - 9.14



   前两行同时改变了几项选择。第三行是关键的对照：
   **换成均值曲线后，即使使用原先的拟合规则，仍得到 9.14 eV。**
   反过来，保持原先的中位数曲线，只换成本页的背景与绝对电压区间，得到 6.81 eV。
   对这份记录，6 到 9 的主要差别来自 I–V 曲线如何整理，
   不只是拟合区间的端点挪到了哪里。

   这里有两层原因。第一，电流分布不对称，均值和中位数不同。
   第二，瞬时 :math:`V_p=V_s-V_b+u_R` 中含有波动的 :math:`u_R`，
   而电流也由同一个 :math:`u_R` 计算。
   按这个电压分组，与按外加 :math:`V_s` 分组，选中的采样点就不同。
   若保留 1 V 电源分箱，仅把均值换成中位数，
   在相同的绝对拟合区间内得到 **7.06 eV** ，进一步看出了平均方式的影响。

   中位数流程并不是算术算错，而是在另一条特性曲线上求斜率。
   若目标是 **平均** 特性，均值流程应作为主结果。
   但不能仅凭一个数就认定测到了无扰动的主体电子温度：
   对有波动的非线性 I–V 响应求平均，本身也可能改变曲线形状 [5]。

   .. raw:: html

      <details class="k05-note"><summary>对照时，哪些选择保持相同？</summary>

   原中位数流程用 −90 到 −70 V 拟合直线离子背景，
   电子区间为 :math:`[V_f-5,V_f+10]`。
   其浮动电势 :math:`V_f=-18.0667` V 与均值曲线零点不同。
   “均值曲线＋原规则”在均值曲线上重新计算 :math:`V_f`，
   再应用相同的相对区间规则，不是固定原绝对端点。

   .. container:: k05-text

      另一组比较固定本页电子区间 [−22.1458, −0.5] V、离子区间 [−80, −50] V：
      原 2 V 探针电压分箱中位数得到 6.81 eV，1 V 电源分箱中位数得到 7.06 eV。
      两套读取器对 本例扫描的 CH3_2/CH4_2 给出完全相同的采样值，
      两流程使用相同的电压／电流符号和换算。
      差别不来自读数比例错误，也不是缺少一个 3/2 因子。

   .. raw:: html

      </details>


   .. rubric:: 6．检查选取是否敏感，再比较重复测量

   保持均值曲线，按预定组合逐项改变选择。
   图 6 先改变电子拟合区间的上下端余量，
   再固定这些余量、改变离子背景。图中 :math:`V_{\mathrm{low}}`、
   :math:`V_{\mathrm{high}}` 分别表示电子拟合区间的下、上边界。

   .. figure:: /_static/K_Diagnostics/k05-sweep-sensitivity.svg
      :alt: 图 6．电子区间余量（左）与离子背景选取（右）的敏感性。框出的格点为主设置；完整 72 种组合保存在数值报告中。
      :width: 100%

      图 6．电子区间余量（左）与离子背景选取（右）的敏感性。框出的格点为主设置；完整 72 种组合保存在数值报告中。


   .. container:: k05-text

      本例扫描在全部 **72 种预定组合** 下得到 **8.65–10.15 eV** ：
      3 种下端余量 × 3 种上端余量 × 4 个离子区间 × 2 种背景形式（直线或常数）。
      72 个结果全部保留。
      这个范围是处理选择的敏感性范围， **不是置信区间** 。
      只把电源分箱宽度改成 0.5、1、2 V，保持拟合的实际电压边界不变，
      分别为 **9.13、9.17、9.16 eV** 。
      这些常规分箱宽度与区间变化，不足以解释 6.7 到 9.2 的全部差别。

   再对四次重复扫描分别应用相同的均值流程：

   .. list-table::
      :header-rows: 1
      :widths: auto

      * - 扫描
        - 均值曲线拟合 [eV]
        - 72 种选择范围 [eV]
      * - 1
        - 9.17
        - 8.65–10.15
      * - 2
        - 9.05
        - 8.73–10.03
      * - 3
        - 9.06
        - 8.57–10.24
      * - 4
        - 8.97
        - 8.35–9.81



   .. container:: k05-text

      四次平均为 **9.06 eV** ，范围为 **8.97–9.17 eV** 。
      **9.17 eV 是本例这一条记录的结果** ，不是四次平均。
      不要先把不同记录混在一起，也不要用平均数替代逐次结果。

   .. raw:: html

      <details class="k05-note"><summary>更早的扫描，结果怎样变化？</summary>

   .. container:: k05-text

      较早的四条扫描与重复组分别保留。
      应用同一均值流程得到：

   .. list-table::
      :header-rows: 1
      :widths: auto

      * - 扫描
        - 均值曲线拟合 [eV]
        - 72 种选择范围 [eV]
      * - 1
        - 8.77
        - 7.92–10.13
      * - 2
        - 8.96
        - 8.13–9.85
      * - 3
        - 8.64
        - 7.92–9.75
      * - 4
        - 8.67
        - 7.38–9.55



   .. container:: k05-text

      原中位数流程对早期组得到 5.78–6.52 eV，平均 6.23 eV；
      对重复组得到 6.00–6.73 eV，平均 6.40 eV。
      换成均值流程后，两组都升高，因此不能仅用“换成重复测量了”解释这个变化。
      实验人员对早期组提出过质量疑问，原因尚未确定。
      这些记录继续保留，但不与重复组混合，也不拿它们证明重复组的绝对准确度。

   .. raw:: html

      </details>


   .. container:: k05-text

      本例扫描的高电压保持段，后期平均电流比早期低约 **26.9%** 。
      这段没有参与温度拟合，但这种变化提醒我们检查时间依赖性；
      仅凭它不能断定来自等离子体、探针表面还是仪器。
      比较稳妥的表述是：
      **本例扫描，按电源电压分箱取算术平均，采用所列背景和拟合区间，
      得到斜率温度 9.17 eV，并附上敏感性检查。**
      小数位多不代表物理准确度同样高。

   .. rubric:: 7．用这条曲线，检查高频探针实际偏在哪里

   .. container:: k05-text

      **为什么要检查工作点？** 高频探针希望记录的是以离子收集为主的波动。
      只有偏压足够负、电子电流较小时，这个解释才较合理。
      如果工作点靠近浮动电势或进入电子阻滞区，电子电流的变化也会进入信号。
      因此先用慢扫描曲线定位工作点，是为了判断高频电压能否作为离子电流的代理量，
      而不是再从高频信号中求一次温度。电池的负电压本身不能完成这个判断。

   高频探针的 40.5 V 蓄电池参考阴极负端。
   把该端相对真空罐的电压记为 :math:`V_c`。
   仍采用电子电流为正的约定，工作点必须同时落在 I–V 曲线上，
   并满足下面的负载线（load line）条件：

   .. k05:equation:: response-fast-bias
      :lang: zh

      V_p=V_c-40.5\ \mathrm{V}-R I(V_p).


   使用时，先给定一个候选 :math:`V_c`，画出直线
   :math:`I=(V_c-40.5\,\mathrm{V}-V_p)/R`，再找它与 I–V 曲线的交点。
   只看电池的标称值，还不能确定这个交点。

   .. figure:: /_static/K_Diagnostics/k05-sweep-bias.svg
      :alt: 图 7．本例平均曲线与三条负载线的交点；阴极—罐体电位差为假设值，不是实测值。
      :width: 100%

      图 7．本例平均曲线与三条负载线的交点；阴极—罐体电位差为假设值，不是实测值。


   :math:`V_c=-20,0,+20` V 是 **演示用的估计值** 。
   与本例扫描的平均曲线相交时，分别得到
   :math:`V_p=-60.07,-40.14,-20.68` V。
   用拟合背景计算的电子／离子电流比分别约为 **0.02、0.07、1.53** 。
   能否把信号近似理解为离子电流，取决于实际参考电位和工作点。
   这里还假设慢扫描特性能够代表高频探针所在位置及其等离子体工况。

   .. rubric:: 8．慢扫描的电流换算，与 MHz 响应要分开看

   .. container:: k05-text

      1 kΩ 电阻给出低频下标称的电压—电流换算。实验电路没有注明额外接入电容器，
      但导线／电缆芯线与屏蔽层、示波器测量探头和输入端之间仍有
      **寄生电容或输入电容（parasitic/input capacitance）** [3]。
      到 MHz 频段，它可能影响幅值与相位；本实验尚未测出这个等效电容。
      以下简单 R–C 模型仅用于理解响应敏感性，不是高频预测残差的已确诊原因。

   .. raw:: html

      <details class="k05-note"><summary>这个简单 R–C 响应模型怎样使用？</summary>

   .. container:: k05-text

      图 8 使用有效电容为 20、100、200 pF 的估计情景，都不是实测值。

   .. figure:: /_static/K_Diagnostics/k05-response-rc.svg
      :alt: 图 8．估计的 R–C 响应：幅值和 K05 Fourier 约定下的相位。
      :width: 100%

      图 8．估计的 R–C 响应：幅值和 K05 Fourier 约定下的相位。



   假设有效电容 :math:`C` 与电阻 :math:`R` 并联。
   代入时频率 :math:`f` 用 Hz，电容用 F，电阻用 Ω：

   .. k05:equation:: response-rc
      :lang: zh

      i_R=\frac{u_R}{R}+C\frac{\mathrm{d}u_R}{\mathrm{d}t},\qquad Z_+(f)\equiv\frac{\widehat u_R}{\widehat i_R}=\frac{R}{1-i2\pi fRC},\qquad f_c=\frac{1}{2\pi RC}.


   :math:`i_R` 为进入并联支路的总电流，:math:`u_R` 为支路电压，
   :math:`t` 为时间。上帽表示 Fourier 系数；分母中的 :math:`i` 是虚数单位。
   :math:`Z_+` 是电流到电压的响应，单位 Ω，采用第三页的正指数 Fourier 约定。
   :math:`f_c` 为响应幅值下降到 :math:`R/\sqrt{2}` 的频率。

   例如 :math:`C=100` pF、:math:`R=1` kΩ 时，:math:`f_c=1.59` MHz。
   在 5 MHz，:math:`|Z_+|/R=0.303`，本约定下相位约 +72.3°。
   若响应已经标定，电流 Fourier 系数为电压系数除以 :math:`Z_+`，
   电流功率谱为电压功率谱除以 :math:`|Z_+|^2`。
   但不能把这里的估计当作实测修正：电缆、输入端和探针响应可能不同，
   做除法也会放大噪声。

   .. raw:: html

      </details>


   解释双探针模型系数时，需要考虑两通道响应。
   与电流有关的信号，也不自动等于仅与密度有关的信号。
   下面的公式说明应用这些解释时需要哪些条件 [4]。

   .. raw:: html

      <details class="k05-note"><summary>怎样用于 L、Q，以及怎样区分电流与密度</summary>

   假设每路电压等于电流乘以线性频率响应，分别记为 :math:`Z_1`、:math:`Z_3`。
   对和频配对 :math:`f=f_1+f_2`，使用：

   .. k05:equation:: response-model-coefficients
      :lang: zh

      L_f^{\mathrm{meas}}=\frac{Z_3(f)}{Z_1(f)}L_f^{i},\qquad Q_{f;1,2}^{\mathrm{meas}}=\frac{Z_3(f)}{Z_1(f_1)Z_1(f_2)}Q_{f;1,2}^{i}.


   上标 meas 表示电压模型；上标 :math:`i` 表示电流模型，不是虚数单位。
   :math:`L` 为线性系数，:math:`Q` 为二次系数，:math:`f_1,f_2` 为输入频率。
   求电流系数时，测得的 :math:`L` 乘以 :math:`Z_1/Z_3`，
   测得的 :math:`Q` 乘以 :math:`Z_1(f_1)Z_1(f_2)/Z_3(f)`。
   即使两通道响应相同，在 :math:`Q` 中通常也不会完全抵消。

   在离子收集近似下，还需要检查：

   .. k05:equation:: response-density-temperature
      :lang: zh

      I_i\propto A_{\mathrm{eff}}n_i\sqrt{\frac{k_B T_e}{m_i}},\qquad \frac{\delta I_i}{I_i}\simeq\frac{\delta n_i}{n_i}+\frac{1}{2}\frac{\delta T_e}{T_e}\quad(A_{\mathrm{eff}},m_i\ \mathrm{fixed}).


   :math:`A_{\mathrm{eff}}` 为有效收集面积，:math:`n_i` 为离子密度，
   :math:`m_i` 为离子质量；:math:`\delta` 表示相对均值的小波动。
   第二个关系要求面积和质量固定。
   因此即使以离子电流为主，温度波动仍可能影响信号。
   应用时要满足相应的收集模型和工作点条件，
   电压模型系数本身还不是已经标定的密度增长率或等离子体能量转移。

   .. raw:: html

      </details>


   .. raw:: html

      <details class="k05-note"><summary>复现本页面的计算</summary>

   在仓库根目录运行，使用配置
   ``K_Diagnostics/K05_bispectral_transfer/probe_sweep_config.json``：

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_probe_sweep.py \
        --data /path/to/supplementary_scans \
        --output /path/to/separate_output

   .. container:: k05-text

      复现编号对应：本例及重复扫描 1–4 对应 10140015–10140018.WDF；
      早期扫描 1–4 对应 10140008–10140011.WDF。
      脚本保存源码／配置／原始文件哈希、均值数组、区间、全部敏感性组合、
      方法对照和 SVG/PNG 图；原始文件只读。
      原中位数流程保留用于控制比较，不再作为本页主温度处理方法。

   :download:`下载数值报告 </_static/K_Diagnostics/k05-sweep-summary.json>`。

   .. raw:: html

      </details>


   .. rubric:: 下一步：把实验结果画出来对照

   :ref:`下一页面 <k05-comparison-zh>` 先展示与 Brown 和 Jorns（2023）
   频谱、色散、增长和耦合图相对应的结果，再解释每个面板怎样计算。
   随后的 :ref:`补充页 <k05-budget-zh>` 再核对这些曲线的物理解释和完整功率收支。

   .. rubric:: 参考文献

   [1] Yokogawa, *DL350 ScopeCorder User's Manual*, IM DL350-01EN,
   Appendix 9, App-19–24.
   `WDF file structure and voltage/time scales <https://cdn.tmi.yokogawa.com/1/10105/files/IMDL350-00EN.pdf>`_.

   [2] R. L. Stenzel, UCLA Plasma Physics Laboratory (1997),
   `Langmuir Probe Trace Evaluation <https://www.physics.ucla.edu/plasma-exp/180E-W97/LprobeAnalysis.html>`_
   and `The Retardation Region <https://www.physics.ucla.edu/plasma-exp/180E-W97/RetRegAnalysis.html>`_.

   [3] Tektronix, `ABCs of Probes Primer <https://www.tek.com/en/documents/whitepaper/abcs-probes-primer>`_.

   .. container:: k05-text

      [4] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
      Instability in a Crossed Field Plasma,” *Physical Review Letters* **130** , 115101 (2023).
      `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   [5] F. F. Chen (2012), *Langmuir probe measurements in the intense RF field of a helicon discharge*,
   UCLA report LTP-1205, pp. 1–2 and 5–7.
   `Probe characteristics and fluctuations <https://www.seas.ucla.edu/~ffchen/Publs/Chen232R.pdf>`_.
