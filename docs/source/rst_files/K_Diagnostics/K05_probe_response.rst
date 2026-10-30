08 · What the probe measures
============================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-response-en:

   .. rubric:: From a recorded voltage to what the probe measures

   The :ref:`previous page <k05-validation-en>` predicted one probe's voltage from the
   other. To interpret those coefficients physically, start one step earlier:
   **how does collected current become recorded voltage?** Here we use eight slow
   probe sweeps to build I–V curves, estimate an electron-temperature slope, and
   examine the fast probe's bias and possible electrical response.

   C1 is the **left, fixed probe** in the experimental diagram; C3 is the right probe,
   3.7 mm away in the azimuthal direction. This identifies the measurement locations,
   not a measured wave-propagation direction. The exposed probe is 0.5 mm in diameter
   and 2.5 mm long. Both tips are 5.5 mm downstream of the exit plane.
   The supplied circuit uses a 1 kΩ sampling resistor.

   .. figure:: /_static/K_Diagnostics/k05-response-layout-en.svg
      :alt: Figure A. Probe positions, redrawn from the experimental layout. Left: the 5.5 mm axial offset and 3.7 mm local azimuthal spacing. Right: the two probes viewed against the annular exit. Not to scale.
      :width: 100%

      Figure A. Probe positions, redrawn from the experimental layout. Left: the 5.5 mm axial offset and 3.7 mm local azimuthal spacing. Right: the two probes viewed against the annular exit. Not to scale.


   .. rubric:: 1. Begin with the two voltages that were actually recorded

   Call the resistor voltage :math:`u_R` (V), measured from the oscilloscope tip to
   its clip, and the resistance :math:`R` (Ω). At low frequency, the current
   :math:`i_R` (A), positive through the resistor from tip to clip, follows Ohm's law:

   .. k05:equation:: response-nominal-current
      :lang: en

      i_R=\frac{u_R}{R},\qquad R=1000\ \Omega\quad\Longrightarrow\quad 1\ \mathrm{V}\ \leftrightarrow\ 1\ \mathrm{mA}.


   This is a nominal conversion. The resistor alone does not specify the response
   of the entire circuit at MHz frequencies; we will return to that after reading
   the slow scan.

   .. figure:: /_static/K_Diagnostics/k05-response-raw.svg
      :alt: Figure 1. Sweep 008: supply and resistor voltages; shading selects the upward ramp.
      :width: 100%

      Figure 1. Sweep 008: supply and resistor voltages; shading selects the upward ramp.


   The WDF headers [1] identify a Yokogawa DL350: each selected trace has 500001 samples
   at 50 kHz, spanning 10 s. Channel CH3_2 measures the sweep-source voltage
   :math:`V_s`; CH4_2 measures :math:`u_R`. These channel names belong to the slow
   recorder, and are different from C1/C3 on the fast oscilloscope. Figure 1 shows
   record 008 as 2 ms block medians. The band shows the within-block 16–84% spread,
   not a confidence interval. The calculations retain the full-resolution samples.

   .. rubric:: 2. Reconstruct the actual probe voltage and current

   Figure B separates the fast and slow circuits. The fast probe uses a 40.5 V
   rechargeable battery; the slow sweep uses a **100 V DC bias power supply** and
   a separate 0–350 V variable power supply. In the figure, :math:`V_p` is the probe
   potential and :math:`V_c` the cathode-negative potential, both relative to the
   chamber; :math:`V_s` is the variable supply voltage. The bias supply voltage is
   :math:`V_b=100` V, where the subscript :math:`b` denotes **bias** .

   .. figure:: /_static/K_Diagnostics/k05-response-circuits-en.svg
      :alt: Figure B. The fast circuit uses a battery and a cathode-negative reference; the slow circuit uses power supplies and a chamber reference. Coloured branches show voltage measurements, with the tip-minus-clip polarity assumed here. The drawing does not establish channel isolation or calibration.
      :width: 100%

      Figure B. The fast circuit uses a battery and a cathode-negative reference; the slow circuit uses power supplies and a chamber reference. Coloured branches show voltage measurements, with the tip-minus-clip polarity assumed here. The drawing does not establish channel isolation or calibration.


   Read the lower circuit from the chamber reference towards the probe. The variable
   supply raises the potential to :math:`V_s`; crossing the bias supply from its
   positive to its negative terminal subtracts :math:`V_b`.
   The resistor's source-side node is therefore
   at :math:`V_s-V_b`, relative to the chamber. The probe-side node differs by
   :math:`u_R`, so the probe potential :math:`V_p` is:

   .. k05:equation:: response-sweep-circuit
      :lang: en

      V_p=V_s-V_b+u_R,\qquad I=-\frac{u_R}{R}=I_e-I_i,\qquad V_b=100\ \mathrm{V}.


   Here :math:`I` is **electron-positive net collection current** : electron collection
   contributes :math:`+I_e` and ion collection :math:`-I_i`, with :math:`I_e,I_i`
   nonnegative magnitudes in A. Thus :math:`I=-i_R` at low frequency. This sign makes
   the electron branch increase as the probe becomes more positive. For example,
   :math:`V_s=150` V and :math:`u_R=-5` V give :math:`V_p=45` V and :math:`I=5` mA.
   Using only :math:`V_s-100` V would miss the resistor voltage drop.

   **Polarity assumption:** the saved CH4_2 voltage has the tip-minus-clip polarity
   shown in the circuit, with no additional inversion. The rising electron branch
   is consistent with this choice; it is not an independent polarity calibration.

   .. figure:: /_static/K_Diagnostics/k05-response-iv.svg
      :alt: Figure 2. Reconstructed I–V curves, with the two sets of sweeps shown separately.
      :width: 100%

      Figure 2. Reconstructed I–V curves, with the two sets of sweeps shown separately.


   For each file, take the first upward sweep from the first crossing of
   :math:`V_s=5` V to the first crossing of 345 V. Group reconstructed :math:`V_p`
   into 2 V bins, retaining bins with at least 20 samples, and plot the median current.
   The hold and return are excluded: Figure 1 already shows that the current changes
   when the ramp stops. The top-end downturn is displayed but is not used in the
   temperature fit, and is not identified as a plasma saturation law.

   Files 008–011 are the sweeps explicitly associated with the supplied circuit note.
   Files 015–018 are a **repeated measurement set** and remain a separate group.
   The experimenter has raised a data-quality concern about 008–011; its cause has
   not been established, so those curves are retained for comparison. The repeat set's
   **floating potential** :math:`V_f`, where :math:`I=0`, is about −18 V, compared
   with about −26 V for 008–011. These are chamber-referenced floating potentials,
   not plasma potentials. The two groups are not merged into one stationary scan.

   .. rubric:: 3. Obtain a temperature estimate from the slope

   At sufficiently negative probe voltage, few electrons are collected and the
   current is mainly ionic. Fit that part first, then subtract it [2]:

   .. k05:equation:: response-ion-subtraction
      :lang: en

      I_{\mathrm{ion,fit}}(V_p)=aV_p+b,\qquad I_e(V_p)=I(V_p)-I_{\mathrm{ion,fit}}(V_p).


   The signed ion background :math:`I_{\mathrm{ion,fit}}` is negative; :math:`a` has
   units A/V and :math:`b` units A. We fit it over −90 to −70 V. The remainder
   :math:`I_e` is the estimated electron current. In a local Maxwellian retarding
   region, a more positive probe admits exponentially more electrons:

   .. k05:equation:: response-temperature-slope
      :lang: en

      I_e=I_*\exp\!\left(\frac{V_p-V_*}{\Theta_e}\right),\qquad \ln\!\left(\frac{I_e}{I_{\mathrm{ref}}}\right)=mV_p+c,\qquad \Theta_e=\frac{1}{m}=\frac{k_B T_e}{e}.


   :math:`I_*` is a reference electron current at voltage :math:`V_*`;
   :math:`I_{\mathrm{ref}}=1` mA makes the logarithm dimensionless. The slope
   :math:`m` has units V⁻¹ and :math:`c` is a dimensionless intercept.
   :math:`k_B` is Boltzmann's constant and :math:`e` the positive elementary charge.
   :math:`\Theta_e=k_BT_e/e` is a temperature expressed as a voltage: a fitted
   :math:`\Theta_e=6.36` V corresponds to an electron temperature of 6.36 eV.
   The plotted :math:`T_{e,\mathrm{fit}}` uses this conventional eV notation.

   .. figure:: /_static/K_Diagnostics/k05-response-temperature.svg
      :alt: Figure 3. Electron-current logarithmic fits and sensitivity to three fixed voltage windows.
      :width: 100%

      Figure 3. Electron-current logarithmic fits and sensitivity to three fixed voltage windows.


   Use three fixed windows relative to each curve's own :math:`V_f`:
   :math:`[-10,+5]`, :math:`[-5,+10]` and :math:`[0,+15]` V. Window 2 is the central
   choice. Applying the same rule to the repeated measurements 015–018 gives
   **6.73, 6.14, 6.72 and 6.00 eV** , respectively, with a mean of **6.40 eV** .
   The first set, 008–011, gives **5.78–6.52 eV** , with a mean of **6.23 eV** .
   Figure 3 already includes both sets. Using the repeat set therefore does not,
   by itself, reproduce the experimentally reported **9.17 eV** ; the subtraction
   and fitting choices also need to be compared.

   .. raw:: html

      <details class="k05-note"><summary>How sensitive is this estimate to the subtraction and fit windows?</summary>

   For each window, fit the natural logarithm of positive electron-current bin
   medians with equal bin weights. No temperature fit uses the high-positive-bias
   plateau or return sweep. For 008, the central window gives 6.36 eV and a log-fit
   R² of 0.999; that describes straightness within this interval, not proof of a
   Maxwellian electron distribution.

   Repeat with ion-background windows −95 to −75 V and −85 to −65 V, retaining all
   three electron windows each time. The last column below spans all nine choices;
   it is a sensitivity range, not a confidence interval.

   .. list-table::
      :header-rows: 1
      :widths: auto

      * - File
        - Floating potential [V]
        - Central fit [eV]
        - Three electron windows [eV]
        - All nine fit choices [eV]
      * - 008
        - -26.26
        - 6.36
        - 6.36–7.00
        - 5.97–8.84
      * - 009
        - -26.33
        - 6.26
        - 6.19–7.24
        - 6.13–8.67
      * - 010
        - -25.72
        - 6.52
        - 6.52–7.36
        - 5.75–9.25
      * - 011
        - -26.78
        - 5.78
        - 5.78–6.46
        - 5.72–7.64
      * - 015
        - -18.07
        - 6.73
        - 6.73–7.29
        - 6.66–8.73
      * - 016
        - -17.47
        - 6.14
        - 6.14–7.22
        - 6.14–8.30
      * - 017
        - -17.22
        - 6.72
        - 6.72–7.52
        - 6.64–9.48
      * - 018
        - -18.19
        - 6.00
        - 6.00–6.13
        - 5.96–8.06



   For the repeated measurements 015–018, all nine choices span **5.96–9.48 eV** ;
   for 008–011 they span **5.72–9.25 eV** . In the repeat set, 9.48 eV comes from
   017 with an ion-background window of −95 to −75 V and an electron window
   of :math:`V_f+[-10,+5]` V. This is one preset sensitivity case, not the central
   estimate or a reason to prefer that window. A range containing 9.17 eV does not
   independently reproduce that value. Ion-background subtraction matters as well
   as the electron fit window. The
   reported 9.17 eV may use different regions or corrections; its processing details
   are not available here. We retain both the reported value and these reproducible
   local-slope estimates. Neither is silently declared the uniquely correct bulk
   temperature. A long sweep also mixes time evolution with voltage dependence.


   .. raw:: html

      </details>


   .. rubric:: 4. Locate the fast probe's operating point

   The upper circuit in Figure B uses a 40.5 V rechargeable battery referenced to the cathode, while the sweep
   uses the chamber as reference. Define :math:`V_c` as cathode potential minus
   chamber potential. It has not been measured in the supplied material. Use an
   **estimated baseline of 0 V** , and show −20 and +20 V as sensitivity scenarios.
   These are illustrative choices, not measured bounds.

   Using the reconstructed I–V curve, the operating point must also include the
   resistor drop:

   .. k05:equation:: response-fast-bias
      :lang: en

      V_p=V_c-40.5\ \mathrm{V}-R I(V_p).


   The current :math:`I(V_p)` comes from the curve, so solve for the voltage at which
   both sides agree. This is a **load-line intersection** . The estimates below use
   008 as an illustrative curve; that assumes comparable plasma for the slow and
   fast recordings, which were not simultaneous. The quality concern about 008–011 is a further reason not to treat this example as a verified fast operating point.

   .. figure:: /_static/K_Diagnostics/k05-response-bias.svg
      :alt: Figure 4. Conditional fast-probe operating points for three assumed cathode-to-chamber voltages.
      :width: 100%

      Figure 4. Conditional fast-probe operating points for three assumed cathode-to-chamber voltages.


   The three assumed :math:`V_c` values give :math:`V_p` near **−60.1, −40.2 and
   −21.0 V**, respectively. The estimated electron/ion-current ratios are about
   **0.02, 0.17 and 2.48** , using the same extrapolated ion background. They are
   sensitive to that subtraction. The baseline is ion-dominated in this model but
   not a demonstration of pure ion saturation; the +20 V scenario is electron-dominated.
   A negative battery voltage alone therefore does not establish the collection regime.

   .. rubric:: 5. A slow I–V scan cannot calibrate a MHz waveform

   A cable and voltage probe add capacitance. As a first electrical estimate, put
   an effective capacitance :math:`C` in parallel with :math:`R`. This simple model
   illustrates capacitive loading [3]; it does not include the full sheath, bias
   supply, cable inductance or oscilloscope response.

   Use **estimated** :math:`C=100` pF, with 20 and 200 pF as alternatives. None was
   measured for this circuit. Part of a rapidly changing current can charge the
   capacitance rather than pass through the resistor:

   .. k05:equation:: response-rc
      :lang: en

      i_R=\frac{u_R}{R}+C\frac{\mathrm{d}u_R}{\mathrm{d}t},\qquad Z_+(f)\equiv\frac{\widehat u_R}{\widehat i_R}=\frac{R}{1-i2\pi fRC},\qquad f_c=\frac{1}{2\pi RC}.


   Here :math:`t` is time (s), :math:`f` frequency (Hz), hats denote the positive-exponent
   Fourier coefficients used throughout K05, and :math:`i` is the imaginary unit.
   :math:`Z_+` is the complex current-to-voltage response (transimpedance, Ω);
   :math:`f_c` is the frequency at which its magnitude falls to :math:`R/\sqrt{2}`.
   For the baseline, :math:`f_c=1.59` MHz.

   .. figure:: /_static/K_Diagnostics/k05-response-rc.svg
      :alt: Figure 5. Estimated R–C response scenarios: amplitude and phase in the K05 Fourier convention.
      :width: 100%

      Figure 5. Estimated R–C response scenarios: amplitude and phase in the K05 Fourier convention.


   The upper axis shows :math:`|Z_+|/R`, the recorded amplitude relative to an ideal
   resistor. With the estimated 100 pF, it is **0.303 at 5 MHz** and **0.079 at 20 MHz** .
   This is an assumed response, not a measured attenuation of these data. The lower
   axis is its phase in our Fourier convention. The shading marks the 5–20 MHz band
   examined on the preceding page.

   .. raw:: html

      <details class="k05-note"><summary>Why is the plotted phase positive, and should this curve correct the data?</summary>

   The forward transform uses :math:`\exp(+i2\pi ft)`, so a time derivative becomes
   :math:`-i2\pi f`. Substitution into the capacitor current gives
   :math:`\widehat i_R=(1/R-i2\pi fC)\widehat u_R`, yielding the negative sign in the
   denominator of :k05:eq:`response-rc`. A positive plotted phase therefore does not
   mean the passive circuit leads in time; the reconstructed waveform uses
   :math:`\exp(-i2\pi ft)`.

   Neither the illustrative curves nor a nominal 100 MS/s fast sampling rate prove
   an analog bandwidth. Dividing a spectrum by a small assumed response amplifies
   noise as well as signal. We therefore show response scenarios separately instead
   of applying an unmeasured inverse filter to the experimental records. A fixed
   linear filter by itself does not reduce ideal magnitude-squared coherence; added
   noise or other changes in the signal relationship would be needed.


   .. raw:: html

      </details>


   .. rubric:: 6. Connect the response back to the two-probe model

   The previous coefficients describe **recorded voltage** . A relative channel gain
   can look like a change in wave amplitude, while a relative delay can look like
   propagation phase. Until measured, use **relative gain 1 and relative delay 0 ns**
   as explicit baseline estimates. As a scale check, a gain of 1.1 changes amplitude
   by 10%, and a 5 ns delay adds 36° at 20 MHz in the positive-exponent convention.
   These scenarios do not change the earlier fitted coefficients or calibrate them.

   .. raw:: html

      <details class="k05-note"><summary>How a measurement response enters L and Q</summary>

   Let :math:`\widehat i_1,\widehat i_3` be probe currents, positive toward the
   resistor return as :math:`i_R` above, and let the measured voltages be
   :math:`X_f=Z_1(f)\widehat i_1(f)` and :math:`Y_f=Z_3(f)\widehat i_3(f)`.
   Subscripts 1 and 3 identify C1 and C3. The complex responses :math:`Z_j` have units
   Ω. Substituting these relations into the quadratic current model gives:

   .. k05:equation:: response-model-coefficients
      :lang: en

      L_f^{\mathrm{meas}}=\frac{Z_3(f)}{Z_1(f)}L_f^{i},\qquad Q_{f;1,2}^{\mathrm{meas}}=\frac{Z_3(f)}{Z_1(f_1)Z_1(f_2)}Q_{f;1,2}^{i}.


   Superscript :math:`i` denotes coefficients in the current model and
   :math:`\mathrm{meas}` those fitted to measured voltage; the linear coefficient
   is dimensionless, while :math:`Q^i` has units A⁻¹ and :math:`Q^{\mathrm{meas}}`
   V⁻¹. The input frequencies :math:`f_1,f_2` add to the target :math:`f`.
   The semicolon separates the target from the input pair. This assumes linear,
   time-invariant measurement responses; instrument nonlinearities are not removed
   by this relation. Unequal frequency responses can reshape both inferred terms.

   The replaceable configuration also records relative-gain scenarios 0.9/1/1.1
   and relative-delay scenarios −5/0/+5 ns. These are illustrative, not measured
   uncertainties. The supplied magnetic-component magnitudes at C1 are 39.48 G
   radial and 80.34 G axial; a purely radial-field geometry should not be presumed.
   Neither a group velocity nor an EDI branch is assigned from those numbers alone.


   .. raw:: html

      </details>


   Even after electrical calibration, ion-current fluctuations depend on more than
   density. In a simplified ion-saturation model with fixed collection area,
   ion species and a constant sheath coefficient:

   .. k05:equation:: response-density-temperature
      :lang: en

      I_i\propto A_{\mathrm{eff}}n_i\sqrt{\frac{k_B T_e}{m_i}},\qquad \frac{\delta I_i}{I_i}\simeq\frac{\delta n_i}{n_i}+\frac{1}{2}\frac{\delta T_e}{T_e}\quad(A_{\mathrm{eff}},m_i\ \mathrm{fixed}).


   :math:`A_{\mathrm{eff}}` is effective collection area (m²), :math:`n_i` ion density
   (m⁻³), :math:`m_i` ion mass (kg), and :math:`\delta` a small perturbation about the
   mean. The second relation keeps first-order changes. Density is a useful proxy
   only if temperature and collection-response variations are sufficiently small.
   The slow scan supplies a background estimate, not a measurement of MHz
   :math:`\delta T_e`. In a drifting, magnetized plasma, the assumed collection law
   itself also needs checking.

   The next inference step can therefore use a stated response model and test how
   its inferred growth and transfer change across these assumptions. Identifying
   EDI and interpreting a frequency transfer as a spatial inverse cascade also
   requires a suitable dispersion branch and group velocity, as in [4].

   .. raw:: html

      <details class="k05-note"><summary>Reproduce the calculation and replace estimated inputs</summary>

   The numerical inputs and their status are in ``probe_response_config.json``.
   The assumed offset, capacitance, gain, delay and fitting windows can be replaced
   without editing the plotting code. These defaults are provisional assumptions,
   not values fitted to make a desired growth or cascade appear.

   Run from the repository root (replace the two example paths):

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_probe_response.py \
        --data /path/to/supplementary_scans \
        --output /path/to/separate_output \
        --config K_Diagnostics/K05_bispectral_transfer/probe_response_config.json

   The output contains source/configuration and raw-file hashes, extracted headers,
   binned curves, fits, all nine fit choices, operating-point scenarios, and SVG/PNG
   figures. Raw files are read-only. The summary reports unusual raw extrema even
   when the displayed block medians suppress short spikes; e.g. file 015 has a
   CH4_2 maximum near 119.9 V. The assumed-response figures are not calibration data.

   :download:`Download the numerical summary </_static/K_Diagnostics/k05-response-summary.json>`.


   .. raw:: html

      </details>


   .. rubric:: References

   [1] Yokogawa, *DL350 ScopeCorder User's Manual*, IM DL350-01EN,
   Appendix 9, App-19–24.
   `WDF file structure and voltage/time scales <https://cdn.tmi.yokogawa.com/1/10105/files/IMDL350-00EN.pdf>`_.

   [2] R. L. Stenzel, UCLA Plasma Physics Laboratory (1997),
   `Langmuir Probe Trace Evaluation <https://www.physics.ucla.edu/plasma-exp/180E-W97/LprobeAnalysis.html>`_
   and `The Retardation Region <https://www.physics.ucla.edu/plasma-exp/180E-W97/RetRegAnalysis.html>`_.

   [3] Tektronix, `ABCs of Probes Primer <https://www.tek.com/en/documents/whitepaper/abcs-probes-primer>`_.

   [4] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**, 115101 (2023).
   `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-response-zh:

   .. rubric:: 从记录的电压，回到探针实际测量的量

   :ref:`上一页面 <k05-validation-zh>` 用一支探针的电压预测另一支探针。
   要把拟合系数解释成物理过程，先往前走一步： **探针收集的电流，怎样变成记录中的电压？**
   本页面使用八份慢扫描数据，依次重建 I–V 曲线、估计电子温度，再检查高频探针的工作点和可能的电路响应。

   C1 是实验图中 **左侧的固定探针** ，C3 是右侧探针，两者周向间距 3.7 mm。
   这确定了测点位置，还没有测出波的传播方向。暴露在等离子体中的探针直径为 0.5 mm、长度为 2.5 mm；
   两个测点都位于出口平面下游 5.5 mm。
   电路使用 1 kΩ 取样电阻（sampling resistor）。

   .. figure:: /_static/K_Diagnostics/k05-response-layout-zh.svg
      :alt: 图 A．依据实验布置重绘的探针位置。左：距出口 5.5 mm 的轴向位置与 3.7 mm 的局部周向间距；右：面对环形出口时的两探针位置。示意图不按比例绘制。
      :width: 100%

      图 A．依据实验布置重绘的探针位置。左：距出口 5.5 mm 的轴向位置与 3.7 mm 的局部周向间距；右：面对环形出口时的两探针位置。示意图不按比例绘制。


   .. rubric:: 1. 先看真正记录下来的两路电压

   把示波器尖端相对地夹的电阻两端电压记为 :math:`u_R` （V），电阻记为 :math:`R` （Ω）。
   低频下，沿电阻从尖端节点流向地夹节点的电流 :math:`i_R` （A）满足欧姆定律：

   .. k05:equation:: response-nominal-current
      :lang: zh

      i_R=\frac{u_R}{R},\qquad R=1000\ \Omega\quad\Longrightarrow\quad 1\ \mathrm{V}\ \leftrightarrow\ 1\ \mathrm{mA}.


   这是名义换算。一个电阻值还不能说明整个电路在 MHz 频段怎样响应；先看完慢扫描，再回到高频。

   .. figure:: /_static/K_Diagnostics/k05-response-raw.svg
      :alt: 图 1．008 扫描的电源与电阻电压；阴影选择上升扫描段。
      :width: 100%

      图 1．008 扫描的电源与电阻电压；阴影选择上升扫描段。


   WDF 文件头 [1] 表明仪器是 Yokogawa DL350：每个选定通道有 500001 个点，采样率 50 kHz，覆盖 10 s。
   CH3_2 测扫描电源电压 :math:`V_s`，CH4_2 测电阻电压 :math:`u_R`。
   这些是慢扫描记录仪的通道名，与高频示波器的 C1/C3 不同。图 1 以 008 为例，画每 2 ms 的中位数，
   色带为该小段内的 16–84% 分位范围， **不是置信区间** ；实际计算仍使用完整采样点。

   .. rubric:: 2. 得到探针的实际电压和电流

   图 B 把高频与慢扫描电路分开画出。高频波探针使用 40.5 V **蓄电池** ；
   慢扫描使用 **100 V 直流偏置电源** （DC bias power supply），再串联一个 0–350 V 可调电源。
   图中 :math:`V_p` 是探针电势，:math:`V_c` 是阴极负端电势，两者都以真空罐为参考；
   :math:`V_s` 是可调电源电压。偏置电源电压记为 :math:`V_b=100` V，下标 :math:`b` 表示偏置（bias）。

   .. figure:: /_static/K_Diagnostics/k05-response-circuits-zh.svg
      :alt: 图 B．高频电路使用蓄电池、参考阴极负端；慢扫描电路使用电源、参考真空罐。彩色支路表示电压测量，极性按本文采用的“尖端减地夹”约定；图示不代表已确认通道隔离或完成标定。
      :width: 100%

      图 B．高频电路使用蓄电池、参考阴极负端；慢扫描电路使用电源、参考真空罐。彩色支路表示电压测量，极性按本文采用的“尖端减地夹”约定；图示不代表已确认通道隔离或完成标定。


   沿下图从真空罐参考点走向探针：经过可调电源，电势升到 :math:`V_s`；
   再从偏置电源正端走到负端，电势减去 :math:`V_b`。
   所以电阻靠电源一端相对真空罐的电位为 :math:`V_s-V_b`，
   探针一端再与它相差 :math:`u_R`，因此探针电势 :math:`V_p` 为：

   .. k05:equation:: response-sweep-circuit
      :lang: zh

      V_p=V_s-V_b+u_R,\qquad I=-\frac{u_R}{R}=I_e-I_i,\qquad V_b=100\ \mathrm{V}.


   这里采用 **电子收集为正的净电流** :math:`I`：收集电子贡献 :math:`+I_e`，收集离子贡献 :math:`-I_i`，
   其中 :math:`I_e,I_i` 都是非负的电流大小，单位 A。因此低频下 :math:`I=-i_R`。
   这个约定使探针变得更正时，电子支的曲线向上。
   例如 :math:`V_s=150` V、:math:`u_R=-5` V，则 :math:`V_p=45` V、:math:`I=5` mA。
   若横轴直接用 :math:`V_s-100` V，就漏掉了电阻压降。

   **极性假设：** 保存的 CH4_2 是图中尖端减地夹的电压，没有额外反相。
   重建后随偏压上升的电子支与此一致，但这不是独立的极性标定。

   .. figure:: /_static/K_Diagnostics/k05-response-iv.svg
      :alt: 图 2．重建的 I–V 曲线；两组扫描分别展示。
      :width: 100%

      图 2．重建的 I–V 曲线；两组扫描分别展示。


   每份记录取第一次上升扫描：从 :math:`V_s` 首次超过 5 V，到首次超过 345 V。
   按重建的 :math:`V_p` 划分 2 V 宽的小区间，至少有 20 点才保留，画区间电流中位数。
   保持和返回阶段不进入拟合；图 1 已能看到停止扫描后电流发生改变。
   曲线最右侧的下降保留显示，但不用于温度拟合，也不将它认定为等离子体的饱和规律。

   008–011 是第一组扫描；015–018 是 **重复测量的一组扫描** ，两组分开显示。
   实验人员对 008–011 提出了数据质量疑问，具体原因尚未查明，因此保留这些曲线供比较。
   后者的 **浮动电势（floating potential）** :math:`V_f`，即净电流 :math:`I=0` 的位置，约为 −18 V；
   008–011 则约为 −26 V。它们是相对真空罐的浮动电势，不是等离子体电势。
   两组不合并成一条假定平稳的曲线。

   .. rubric:: 3. 从斜率得到一个温度估计

   探针电势足够负时，能到达探针的电子较少，电流主要由离子贡献。
   先拟合这部分背景，再把它从净电流中扣除 [2]：

   .. k05:equation:: response-ion-subtraction
      :lang: zh

      I_{\mathrm{ion,fit}}(V_p)=aV_p+b,\qquad I_e(V_p)=I(V_p)-I_{\mathrm{ion,fit}}(V_p).


   带符号的离子背景 :math:`I_{\mathrm{ion,fit}}` 为负；:math:`a` 的单位是 A/V，:math:`b` 的单位是 A。
   本例在 −90 至 −70 V 拟合这条直线，扣除后得到电子电流估计 :math:`I_e`。
   在局部麦克斯韦电子的阻滞区（electron-retarding region），探针越正，能越过势垒的电子按指数增加：

   .. k05:equation:: response-temperature-slope
      :lang: zh

      I_e=I_*\exp\!\left(\frac{V_p-V_*}{\Theta_e}\right),\qquad \ln\!\left(\frac{I_e}{I_{\mathrm{ref}}}\right)=mV_p+c,\qquad \Theta_e=\frac{1}{m}=\frac{k_B T_e}{e}.


   :math:`I_*` 是参考电压 :math:`V_*` 处的电子电流；取 :math:`I_{\mathrm{ref}}=1` mA，
   使对数内是无量纲比值。斜率 :math:`m` 的单位为 V⁻¹，截距 :math:`c` 无量纲。
   :math:`k_B` 是玻尔兹曼常数，:math:`e` 是正的元电荷。
   :math:`\Theta_e=k_BT_e/e` 是用电压表示的温度尺度：拟合得到 :math:`\Theta_e=6.36` V，
   对应常用能量单位下的电子温度 6.36 eV。图中的 :math:`T_{e,\mathrm{fit}}` 使用这种 eV 记法。

   .. figure:: /_static/K_Diagnostics/k05-response-temperature.svg
      :alt: 图 3．电子电流的对数拟合，以及三个固定电压区间的敏感性比较。
      :width: 100%

      图 3．电子电流的对数拟合，以及三个固定电压区间的敏感性比较。


   相对各条曲线自身的 :math:`V_f`，固定使用三个拟合区间：
   :math:`[-10,+5]`、:math:`[-5,+10]`、:math:`[0,+15]` V，以第二个为中心选择。
   用完全相同的规则处理重复测量 015–018，分别得到 **6.73、6.14、6.72、6.00 eV，平均 6.40 eV** 。
   第一组 008–011 则为 **5.78–6.52 eV，平均 6.23 eV** 。图 3 已同时展示这两组。
   因此，换用重复测量这一项还不足以复现实验报告的 **9.17 eV** ；还需要比较离子背景扣除和拟合区间。

   .. raw:: html

      <details class="k05-note"><summary>背景扣除与拟合区间会让结果变化多少？</summary>

   每个区间只对正的电子电流中位数取自然对数，各电压小区间等权拟合。
   高正偏压平台和返回扫描均不参与温度拟合。008 的中心区间给出 6.36 eV，对数拟合 R² 约 0.999；
   它说明这一小段较直，不证明电子分布一定为麦克斯韦分布。

   再把离子背景拟合区间分别改为 −95 至 −75 V、−85 至 −65 V，每次都保留三个电子区间。
   下表最后一列覆盖九种组合，是敏感性范围，不是置信区间。

   .. list-table::
      :header-rows: 1
      :widths: auto

      * - 文件
        - 浮动电势 [V]
        - 中心拟合 [eV]
        - 三个电子区间 [eV]
        - 全部九种拟合 [eV]
      * - 008
        - -26.26
        - 6.36
        - 6.36–7.00
        - 5.97–8.84
      * - 009
        - -26.33
        - 6.26
        - 6.19–7.24
        - 6.13–8.67
      * - 010
        - -25.72
        - 6.52
        - 6.52–7.36
        - 5.75–9.25
      * - 011
        - -26.78
        - 5.78
        - 5.78–6.46
        - 5.72–7.64
      * - 015
        - -18.07
        - 6.73
        - 6.73–7.29
        - 6.66–8.73
      * - 016
        - -17.47
        - 6.14
        - 6.14–7.22
        - 6.14–8.30
      * - 017
        - -17.22
        - 6.72
        - 6.72–7.52
        - 6.64–9.48
      * - 018
        - -18.19
        - 6.00
        - 6.00–6.13
        - 5.96–8.06



   重复测量 015–018 的九种组合合并为 **5.96–9.48 eV** ；008–011 为 **5.72–9.25 eV** 。
   其中，017 在离子背景区间 −95 至 −75 V、电子区间 :math:`V_f+[-10,+5]` V 下得到 9.48 eV。
   这是预先列出的一个敏感性情景，不是中心结果，也不说明该区间更正确。
   范围包含 9.17 eV，不等于独立复现了 9.17 eV；离子背景扣除与电子拟合区间都需要核对。
   报告的 9.17 eV 可能采用了不同的区间或修正；当前没有其处理细节。
   这里同时保留报告值与可复现的局部斜率估计，不默认为哪一个就是唯一正确的整体电子温度。
   此外，一次较长扫描可能同时混入等离子体随时间的变化。


   .. raw:: html

      </details>


   .. rubric:: 4. 高频探针工作在曲线的什么位置？

   图 B 上方高频电路的 40.5 V 蓄电池参考阴极负端，扫描电路参考真空罐。
   定义 :math:`V_c` 为“阴极电位减真空罐电位”。补充材料尚未给出这个量。
   这里采用 **估计基准 0 V** ，并展示 −20、+20 V 两种敏感性情景。
   它们是示例选择，不是测量得到的上下界。

   利用重建的 I–V 曲线，工作点还要计入电阻压降：

   .. k05:equation:: response-fast-bias
      :lang: zh

      V_p=V_c-40.5\ \mathrm{V}-R I(V_p).


   电流 :math:`I(V_p)` 本身依赖电压，所以要求出让等式两侧一致的 :math:`V_p`，
   这叫 **负载线交点（load-line intersection）** 。
   下面仍用 008 演示负载线计算，额外假定慢扫描与高频记录的等离子体状态可比较；它们不是同时采集的。
   由于 008–011 的数据质量也有待核查，这个示例不能用来确认真实高频工作点。

   .. figure:: /_static/K_Diagnostics/k05-response-bias.svg
      :alt: 图 4．三种假设阴极—罐体电位差下，高频探针的条件工作点。
      :width: 100%

      图 4．三种假设阴极—罐体电位差下，高频探针的条件工作点。


   三种 :math:`V_c` 假设分别得到 :math:`V_p` 约 **−60.1、−40.2、−21.0 V** 。
   沿用同一离子背景，电子电流与离子电流的比值估计为 **0.02、0.17、2.48** ，对背景扣除方式敏感。
   基准情景下离子贡献较大，但不能据此证明处于纯离子饱和区；+20 V 情景甚至已经由电子贡献主导。
   因此，仅知道电池提供负偏压，还不能确定实际收集状态。

   .. rubric:: 5. 慢扫描还不能标定 MHz 波形

   电缆和示波器探头会引入电容。先用一个简单模型：在 :math:`R` 两端并联等效电容 :math:`C`。
   这个模型说明电容加载（capacitive loading）的影响 [3]，还没有包含完整鞘层、偏置电源、
   电缆电感和示波器响应。

   采用 **估计值** :math:`C=100` pF，同时画出 20 和 200 pF；这些数值都不是本电路的实测电容。
   变化较快的电流，有一部分会给电容充电，不再全部流过电阻：

   .. k05:equation:: response-rc
      :lang: zh

      i_R=\frac{u_R}{R}+C\frac{\mathrm{d}u_R}{\mathrm{d}t},\qquad Z_+(f)\equiv\frac{\widehat u_R}{\widehat i_R}=\frac{R}{1-i2\pi fRC},\qquad f_c=\frac{1}{2\pi RC}.


   :math:`t` 是时间（s），:math:`f` 是频率（Hz），帽号表示 K05 一直采用的正指数 Fourier 系数，
   :math:`i` 是虚数单位。:math:`Z_+` 是从电流到电压的复响应，即跨阻（transimpedance），单位 Ω。
   :math:`f_c` 是幅值降到 :math:`R/\sqrt{2}` 的频率，基准情景给出 :math:`f_c=1.59` MHz。

   .. figure:: /_static/K_Diagnostics/k05-response-rc.svg
      :alt: 图 5．估计的 R–C 响应情景：幅值和 K05 Fourier 约定下的相位。
      :width: 100%

      图 5．估计的 R–C 响应情景：幅值和 K05 Fourier 约定下的相位。


   上图的 :math:`|Z_+|/R` 表示相对理想电阻的电压幅值。
   估计电容为 100 pF 时， **5 MHz 处为 0.303，20 MHz 处为 0.079** 。
   这些是模型情景的响应，不是已经测出的本实验衰减。下图是本 Fourier 约定下的相位；
   浅色区域标出前一页面讨论的 5–20 MHz。

   .. raw:: html

      <details class="k05-note"><summary>相位为什么是正的？能直接拿这条曲线修正数据吗？</summary>

   正变换采用 :math:`\exp(+i2\pi ft)`，因此时间导数变为 :math:`-i2\pi f`。
   代入电容电流，得到 :math:`\widehat i_R=(1/R-i2\pi fC)\widehat u_R`，
   所以 :k05:eq:`response-rc` 的分母带负号。图中的正相位不意味着无源电路在时间上超前，
   因为重建波形采用 :math:`\exp(-i2\pi ft)`。

   示例响应曲线和高频记录的 100 MS/s 采样率都不能证明模拟带宽。
   用一个很小的假设响应去除频谱，会同时放大噪声。
   因此，这里独立展示响应情景，没有把未实测的逆滤波直接施加到实验数据。
   固定线性滤波本身也不会降低理想的幅值平方相干度；还需要附加噪声或信号关系的其他改变。


   .. raw:: html

      </details>


   .. rubric:: 6. 再接回双探针模型

   前一页拟合的是 **记录电压** 。两路增益差可能看起来像波幅变化，两路延迟差可能看起来像传播相位。
   在实测标定之前，先采用 **相对增益 1、相对延迟 0 ns** 作为明确的估计基准。
   例如增益 1.1 会改变 10% 的幅值，延迟 5 ns 在 20 MHz 对应正指数约定下 +36° 的附加相位。
   这些情景并未改写或标定前面已经算出的系数。

   .. raw:: html

      <details class="k05-note"><summary>测量响应怎样进入 L 和 Q</summary>

   令 :math:`\widehat i_1,\widehat i_3` 为探针电流，其正方向与前面的 :math:`i_R` 一致，
   测得的电压为 :math:`X_f=Z_1(f)\widehat i_1(f)`、:math:`Y_f=Z_3(f)\widehat i_3(f)`。
   下标 1、3 标记 C1、C3，复响应 :math:`Z_j` 的单位是 Ω。
   把这两个关系代入电流的二次模型，得到：

   .. k05:equation:: response-model-coefficients
      :lang: zh

      L_f^{\mathrm{meas}}=\frac{Z_3(f)}{Z_1(f)}L_f^{i},\qquad Q_{f;1,2}^{\mathrm{meas}}=\frac{Z_3(f)}{Z_1(f_1)Z_1(f_2)}Q_{f;1,2}^{i}.


   上标 :math:`i` 表示电流模型的系数，:math:`\mathrm{meas}` 表示对测量电压拟合的系数。
   线性系数无量纲；:math:`Q^i` 的单位为 A⁻¹，:math:`Q^{\mathrm{meas}}` 为 V⁻¹。
   两个输入频率 :math:`f_1,f_2` 相加得到目标频率 :math:`f`；分号用来分开目标与输入波对。
   这里假定测量响应线性且不随时间改变，仪器非线性不由这条关系消除。
   不同的频率响应会改变两个反演项的形状。

   可替换配置还记录相对增益 0.9/1/1.1、相对延迟 −5/0/+5 ns 情景；它们不是实测不确定度。
   C1 位置给出的径向、轴向磁场分量的模分别为 39.48 G 和 80.34 G，不应默认磁场只有径向分量。
   这里不由这两个数值直接指定群速度或 EDI 分支。


   .. raw:: html

      </details>


   即使完成电路标定，离子电流波动也不只取决于密度。
   在简化的离子饱和模型中，固定有效收集面积、离子种类和鞘层系数时：

   .. k05:equation:: response-density-temperature
      :lang: zh

      I_i\propto A_{\mathrm{eff}}n_i\sqrt{\frac{k_B T_e}{m_i}},\qquad \frac{\delta I_i}{I_i}\simeq\frac{\delta n_i}{n_i}+\frac{1}{2}\frac{\delta T_e}{T_e}\quad(A_{\mathrm{eff}},m_i\ \mathrm{fixed}).


   :math:`A_{\mathrm{eff}}` 为有效收集面积（m²），:math:`n_i` 为离子密度（m⁻³），
   :math:`m_i` 为离子质量（kg），:math:`\delta` 表示相对均值的小扰动；第二式只保留一阶变化。
   只有温度和收集响应的变化足够小时，电流才适合作为密度的代理量（proxy）。
   慢扫描提供背景估计，没有测出 MHz 频段的 :math:`\delta T_e`；在磁化且存在漂移的等离子体中，
   这个简化收集规律本身也需要检验。

   接下来的反演可以在明确的响应模型下展开，再比较不同假设得到的增长与转移是否稳定。
   若进一步识别 EDI，或把频率转移解释成空间尺度上的逆级联，还要接入合适的色散分支和群速度依据 [4]。

   .. raw:: html

      <details class="k05-note"><summary>复现计算与替换估计参数</summary>

   数值和来源状态保存在 ``probe_response_config.json``。
   参考电位差、电容、增益、延迟和拟合区间都可替换，无需改绘图代码。
   默认值是暂用假设，不是为出现某个增长或级联结论而调出来的参数。

   从仓库根目录运行，替换下面的输入、输出路径：

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_probe_response.py \
        --data /path/to/supplementary_scans \
        --output /path/to/separate_output \
        --config K_Diagnostics/K05_bispectral_transfer/probe_response_config.json

   输出保存源码／配置／原始文件哈希、提取的文件头、分箱曲线、全部九种拟合、工作点情景和 SVG/PNG 图。
   原始文件只读。报告保留原始极值，即使图中的小段中位数会抑制短时尖峰；例如 015 的 CH4_2 最大值约 119.9 V。
   假设响应曲线不作为标定数据。

   :download:`下载数值报告 </_static/K_Diagnostics/k05-response-summary.json>`。


   .. raw:: html

      </details>


   .. rubric:: 参考文献

   [1] Yokogawa, *DL350 ScopeCorder User's Manual*, IM DL350-01EN,
   Appendix 9, App-19–24.
   `WDF file structure and voltage/time scales <https://cdn.tmi.yokogawa.com/1/10105/files/IMDL350-00EN.pdf>`_.

   [2] R. L. Stenzel, UCLA Plasma Physics Laboratory (1997),
   `Langmuir Probe Trace Evaluation <https://www.physics.ucla.edu/plasma-exp/180E-W97/LprobeAnalysis.html>`_
   and `The Retardation Region <https://www.physics.ucla.edu/plasma-exp/180E-W97/RetRegAnalysis.html>`_.

   [3] Tektronix, `ABCs of Probes Primer <https://www.tek.com/en/documents/whitepaper/abcs-probes-primer>`_.

   [4] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**, 115101 (2023).
   `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.
