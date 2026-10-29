06 · First analysis of experimental probe signals
=================================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. |brown-en| raw:: html

   <a class="k05-cite" href="#k05-data-reference-1-en">[1]</a>

.. |siglent-en| raw:: html

   <a class="k05-cite" href="#k05-data-reference-2-en">[2]</a>

.. |scipy-en| raw:: html

   <a class="k05-cite" href="#k05-data-reference-3-en">[3]</a>

.. |phaseguide-en| raw:: html

   <a class="k05-cite" href="#k05-data-reference-4-en">[4]</a>

.. |brown-zh| raw:: html

   <a class="k05-cite" href="#k05-data-reference-1-zh">[1]</a>

.. |siglent-zh| raw:: html

   <a class="k05-cite" href="#k05-data-reference-2-zh">[2]</a>

.. |scipy-zh| raw:: html

   <a class="k05-cite" href="#k05-data-reference-3-zh">[3]</a>

.. |phaseguide-zh| raw:: html

   <a class="k05-cite" href="#k05-data-reference-4-zh">[4]</a>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-experiment-en:

   .. rubric:: Turn eight files into quantities we can inspect

   The preceding pages explained the mathematics. We now apply it to four
   synchronized C1–C3 recordings from two ion-saturation-current probes. Start by
   looking at the signals, then ask which frequencies carry their fluctuations,
   whether the two probes share them, and which frequency triplets have a repeatable
   phase relationship. Each figure below is calculated from these measurements.

   This follows the measurement-to-statistics path used by Brown and Jorns
   |brown-en|. These are a separate experiment, so a spectral feature must be
   identified from this experiment's conditions before it is called an EDI mode.

   .. rubric:: 1. Establish what one file contains

   Each file stores one oscilloscope channel. The suffixes **2, 3, 4 and 5** identify
   four captures; C1 and C3 with the same suffix were sampled simultaneously.
   The data owner confirms the same operating condition for all four captures.
   The probes are **5.5 mm downstream** of the exit plane and **3.7 mm apart
   azimuthally**. Their physical ordering around the thruster is unspecified.

   .. list-table:: Acquisition facts
      :header-rows: 1
      :widths: 42 58

      * - Quantity
        - Value
      * - Sample rate :math:`f_s`
        - 100 MS/s, read from all eight headers
      * - Samples per channel and capture
        - 10,000,000
      * - Sample interval / record duration
        - 10 ns / 0.1 s
      * - Nyquist frequency :math:`f_s/2`
        - 50 MHz
      * - Stored codes / vertical scale
        - Unsigned 16-bit codes; 7680 codes/div and 2 V/div
      * - Measured quantity used here
        - Voltage fluctuations from an ion-current diagnostic, in V

   The 16-bit file representation is distinct from the oscilloscope's nominal
   12-bit ADC resolution. The voltage-to-current conversion and channel frequency
   responses are not calibrated here. In particular, these voltages are **not
   direct measurements of plasma potential**.

   .. raw:: html

      <details class="k05-note"><summary>Why start with fluctuations rather than quote an absolute DC level?</summary>

   The supplied laboratory reader subtracts the header's vertical offset; the
   vendor's V4 example |siglent-en| adds it. The laboratory script cites a DC
   calibration, but its underlying calibration records are not included here.
   The post-experiment scope photo confirms the acquisition scales, not the mean
   of the stored plasma waveforms. For capture 2, the two sign conventions give
   C1 means of −0.100665 or +0.899335 V, and C3 means of +0.283286 or +1.549953 V.
   Neither candidate is used as a calibrated DC current.

   The difference is a constant for each channel. Subtracting the record or
   segment mean cancels it exactly. The reader therefore returns record-centred
   fluctuations by default; its output manifest preserves both candidate DC levels.
   This does not cancel a gain, polarity or frequency-response error.

   .. raw:: html

      </details>


   Let :math:`c_j[n]` be the stored integer at sample :math:`n` of channel
   :math:`j=1,3`. Subtract the mean code :math:`\overline{c_j}` of that whole
   record and multiply by its voltage-per-code scale :math:`g_j`:

   .. k05:equation:: experiment-code-fluctuation
      :lang: en

      x_j[n]=g_j\bigl(c_j[n]-\overline{c_j}\bigr),\qquad g_j=\frac{2\ \mathrm{V/div}}{7680\ \mathrm{codes/div}}.


   The result :math:`x_j[n]` is a voltage fluctuation about the record mean.
   This removes one constant; it does not smooth the waveform. We retain the
   original files and their hashes. The horizontal origin below is the start of
   each record, rather than the scope's trigger origin.

   .. figure:: /_static/K_Diagnostics/k05-experiment-raw.svg
      :alt: Figure 1. All four captures after subtracting each record mean. Cyan: C1; orange: C3.
      :width: 100%

      Figure 1. All four captures after subtracting each record mean. Cyan: C1; orange: C3.



   The translucent bands contain the minimum and maximum of every 10,000-sample
   display bin, or 0.1 ms. The thin lines are bin means. Simply plotting every
   ten-thousandth point could hide a narrow excursion; these bands keep it visible.
   All samples, not the display bins, enter the analysis. No stored code equals
   0 or 65535. This checks file-code rails, not every possible analog overload.

   .. raw:: html

      <details class="k05-note"><summary>Zoom in: what was hidden in the full-length bands?</summary>

   .. figure:: /_static/K_Diagnostics/k05-experiment-zoom.svg
      :alt: Figure 2. A 20-microsecond zoom into capture 2 at 50 ms.
      :width: 100%

      Figure 2. A 20-microsecond zoom into capture 2 at 50 ms.

   The two panels use exactly the same samples in time. Individual excursions now become visible; similar shapes alone do not establish their propagation mechanism.

   .. raw:: html

      </details>


   .. rubric:: 2. Check whether the statistics drift during a record

   A full-record picture can conceal a change in mean or fluctuation strength.
   Divide it into 100 consecutive **1 ms blocks**, each containing
   :math:`M=100{,}000` samples. In block :math:`r`, calculate its mean
   :math:`\mu_{j,r}` and fluctuation RMS :math:`\sigma_{j,r}`:

   .. k05:equation:: experiment-block-statistics
      :lang: en

      \mu_{j,r}=\frac{1}{M}\sum_{n=0}^{M-1}x_{j,r}[n],\qquad \sigma_{j,r}=\sqrt{\frac{1}{M}\sum_{n=0}^{M-1}\bigl(x_{j,r}[n]-\mu_{j,r}\bigr)^2}.


   The RMS is the square root of the mean squared deviation from the local mean.
   It measures the typical fluctuation size, in V. Here :math:`r` labels a block
   and :math:`n` a sample within it.

   .. figure:: /_static/K_Diagnostics/k05-experiment-stability.svg
      :alt: Figure 3. Local mean relative to the record mean, and local fluctuation RMS.
      :width: 100%

      Figure 3. Local mean relative to the record mean, and local fluctuation RMS.



   Within each channel, the four captures have similar levels and RMS ranges.
   Across whole records, C1 has RMS 0.626–0.629 V and C3 0.756–0.758 V:
   the measured voltage fluctuations in C3 are about 20% larger. This compares
   the spread around each channel's own mean, not their DC levels.
   Subtracting the mean removes an offset; it does not make the two fluctuation
   amplitudes equal.

   .. raw:: html

      <details class="k05-note"><summary>Why can the two probes have different RMS values?</summary>

   RMS describes the size of a measured fluctuation, not the identity of a wave.
   Even if both probes respond to the same disturbance, the complete measurement
   responses need not be equal. Different probe collection areas or sensitivities,
   current-to-voltage conversion, or channel gains can change the recorded amplitude.
   For a simple illustration, multiplying every fluctuation by 1.2 also multiplies
   its RMS by 1.2, without requiring any physical growth of the wave.
   The same oscilloscope V/div setting does not establish equal responses of the
   probes and their entire measurement circuits.

   The actual local fluctuations may also differ between the two positions, and
   measurement noise contributes to RMS. Figure 3 alone cannot separate these
   possibilities. Its clear result is repeatability within each channel together
   with a persistent amplitude difference between channels; the cause of that
   difference remains undetermined.

   A pure time delay changes the alignment of a waveform, not its fluctuation size:
   equal-amplitude, stationary signals have the same RMS in the long-record limit.
   Finite 1 ms blocks can differ because their endpoints contain different samples,
   but a stable RMS ratio is not itself evidence of a propagation direction or a
   growth rate. Moreover, this RMS combines all recorded frequencies; growth of
   one mode requires separating its frequency-dependent behavior from the
   measurement response.

   .. raw:: html

      </details>

   Temporal steadiness and the spatial stationarity assumption in the
   :ref:`Kim correction <k05-inference-en>` are different requirements.

   .. rubric:: 3. Make short records and inspect what the window changes

   For a spectrum, use **16,384 samples per segment**, starting at the same sample
   in both channels. Each segment lasts 163.84 microseconds. One capture gives
   610 complete, nonoverlapping segments. The final 5760 samples, or 57.6
   microseconds, are omitted. We keep captures separate rather than joining their
   endpoints into an artificial continuous signal.

   Subtract each segment's mean, then multiply it by a **periodic Hann window**.
   This tapers the endpoints and reduces spectral leakage caused by cutting a
   finite record. It also changes amplitudes, so the normalization must include
   the window. The figure shows the first C1 segment of capture 2.

   .. figure:: /_static/K_Diagnostics/k05-experiment-segments.svg
      :alt: Figure 4. The same segment before and after Hann weighting.
      :width: 100%

      Figure 4. The same segment before and after Hann weighting.



   .. k05:equation:: experiment-windowed-coefficients
      :lang: en

      X_k^{(r)}=\frac{1}{N}\sum_{n=0}^{N-1}w_n\bigl(x_{1,r}[n]-\overline{x_{1,r}}\bigr)e^{+i2\pi kn/N},\qquad f_k=\frac{k f_s}{N}.


   :math:`N` is the samples per segment, :math:`r` the segment number,
   :math:`w_n` the window, and :math:`k` an integer frequency index.
   :math:`X_k^{(r)}` is the complex C1 coefficient in V; applying the same operation
   to C3 gives :math:`Y_k^{(r)}`. The bar now means the mean of that segment.
   The positive exponential and :math:`1/N` normalization are unchanged from
   :k05:eq:`time-fourier-series`. Here the frequency-bin spacing is **6.104 kHz**.

   .. raw:: html

      <details class="k05-note"><summary>The transform in Python, with the same sign as the equation</summary>

   .. code-block:: python

      blocks = voltage[:R*N].reshape(R, N)
      centered = blocks - blocks.mean(axis=1, keepdims=True)
      window = scipy.signal.windows.hann(N, sym=False)
      X = np.fft.rfft(centered * window, axis=1).conj() / N
      f = np.fft.rfftfreq(N, d=1/fs)

   For real input, conjugating NumPy's negative-exponent transform gives the
   positive-exponent coefficients used here. The division by N sets their units
   and normalization. No zero padding or resampling is applied. The bin spacing
   is not the full resolving width of a Hann spectral peak; its equivalent noise
   bandwidth is 1.5 bins. Segmentation and windowing are introduced in
   :doc:`the existing processing guide <K01_signal_spectra/fun_K01_segment_ffts>`.

   .. raw:: html

      </details>


   .. rubric:: 4. Average squared coefficients to obtain the power spectrum

   For each frequency, square the coefficient magnitude and average over the
   610 segments. To express this as a one-sided power spectral density (PSD),
   correct for the window and the frequency-bin width:

   .. k05:equation:: experiment-hann-psd
      :lang: en

      w_n=\frac12\left(1-\cos\frac{2\pi n}{N}\right),\quad U=\frac1N\sum_n w_n^2=\frac38,\qquad S_{XX}^{+}(f_k)=\frac{s_k N}{f_s U}\left\langle|X_k|^2\right\rangle_R.


   :math:`U` is the window's mean square; :math:`s_k=2` at interior positive
   frequencies and :math:`s_k=1` at DC and Nyquist. The brackets average over
   :math:`R=610` segments. The superscript :math:`+` denotes a one-sided spectrum.
   :math:`S_{XX}^{+}` has units :math:`\mathrm{V^2/Hz}`. Use Y for the C3 spectrum.
   This PSD scaling is distinct from a correction for the peak amplitude of a
   single sinusoid. See :doc:`window and spectrum normalization <K01_signal_spectra/fun_K01_power_spectrum>`.

   .. figure:: /_static/K_Diagnostics/k05-experiment-psd.svg
      :alt: Figure 5. Separate one-sided voltage PSDs for all four captures.
      :width: 100%

      Figure 5. Separate one-sided voltage PSDs for all four captures.



   The horizontal axis is frequency; the vertical axis measures voltage variance
   per unit frequency. Both axes are logarithmic. The four lines in each panel
   nearly overlap, so the spectral shape is reproducible across captures.
   The spectrum contains low-frequency peaks and structure at higher frequencies.
   A peak alone does not identify its plasma mechanism or exclude electrical pickup.
   The complete spectrum is retained up to 50 MHz; the Nyquist bound does not prove
   that out-of-band analog signals were adequately rejected.

   .. raw:: html

      <details class="k05-note"><summary>Before averaging: does the frequency content change over time?</summary>

   .. figure:: /_static/K_Diagnostics/k05-experiment-spectrogram.svg
      :alt: Figure 6. The segment spectra before averaging over time, capture 2.
      :width: 100%

      Figure 6. The segment spectra before averaging over time, capture 2.


   Each vertical column is a segment spectrum. Its horizontal position is the
   segment's midpoint; color is log10 of the PSD in V²/Hz. A horizontal band
   indicates sustained power near a frequency, whereas a vertical streak indicates
   a short event spanning frequencies. The 0–5 MHz view exposes temporal variation
   that a single averaged curve hides. Similar appearance supports checking a
   stationary window; it is not a formal stationarity test.

   .. raw:: html

      </details>


   .. rubric:: 5. Compare the two probes without discarding phase

   At each frequency calculate cross power :math:`G`, magnitude-squared coherence
   :math:`C_{13}^2`, and cross phase :math:`\delta`:

   .. k05:equation:: experiment-coherence-phase
      :lang: en

      C_{13}^2(f)=\frac{|G(f)|^2}{P_X(f)P_Y(f)},\qquad G(f)=\langle Y_fX_f^*\rangle_R,\qquad \delta(f)=\arg G(f).


   :math:`P_X=\langle|X|^2\rangle_R` and :math:`P_Y=\langle|Y|^2\rangle_R`
   are the windowed bin powers, in :math:`\mathrm{V^2}`. Coherence is dimensionless
   and lies between zero and one: large values mean a repeatable linear relation
   between the channels at that frequency. The asterisk denotes conjugation and
   :math:`\arg` extracts phase in radians.

   .. figure:: /_static/K_Diagnostics/k05-experiment-cross.svg
      :alt: Figure 7. Coherence and cross phase: full 0–50 MHz band (left), 0–5 MHz detail (right).
      :width: 100%

      Figure 7. Coherence and cross phase: full 0–50 MHz band (left), 0–5 MHz detail (right).



   At 100 MS/s, the Nyquist frequency is 50 MHz. The left column shows the
   **full 0–50 MHz range**, matching the range of the PSD; the right column
   magnifies **0–5 MHz** so its structure remains visible. Both columns use the
   same calculated frequency points, with no additional filtering or resampling.
   Five megahertz is only the edge of the detail view, not a sampling or analysis limit.

   Over 0.5–5 MHz, the median coherence is **0.988–0.989** across the four captures.
   This describes only that interval, not the full band. For readability, phase is
   drawn only where coherence is at least 0.5, whereas coherence itself is shown
   at every frequency. Blank phase regions therefore do not mean those frequencies
   were omitted from the calculation. The 0.5 cutoff is a display choice, not a
   significance threshold. No delay was removed by shifting one trace to maximize agreement.

   In the **25–50 MHz** interval, the median coherence drops to **0.0017–0.0020**
   across captures. The measured channels have very little repeatable linear
   association there. Figure 5 also shows much smaller voltage PSDs at these
   frequencies. A weak shared signal with relatively stronger independent noise is
   one possible explanation; these measurements alone do not establish the noise
   floor or prove that high-frequency plasma fluctuations are absent.

   Positive and negative phase values are relative angles wrapped into the interval
   from :math:`-\pi` to :math:`\pi`. Beyond about **16.83 MHz**, no frequency point
   passes the phase-display threshold in any capture, so the phase panel is blank.
   The phases were calculated, but low coherence makes their interpretation as a
   stable lag unreliable |phaseguide-en|. The two disclosures below explain why.

   High coherence can arise from a propagating fluctuation, a common source,
   electrical pickup or cross-talk. To interpret the phase, write the linear
   measurement response explicitly:

   .. k05:equation:: experiment-measurement-phase
      :lang: en

      X_f=H_1(f)I_{1,f},\quad Y_f=H_3(f)I_{3,f},\qquad \delta_V=\delta_I+\arg H_3-\arg H_1\pmod{2\pi}.


   :math:`I_{j,f}` is the Fourier coefficient of probe current in A,
   :math:`H_j(f)` its complex current-to-voltage response in V/A,
   :math:`\delta_I` the current cross phase, and :math:`\delta_V` the measured
   voltage cross phase. A channel delay contributes to :math:`\arg H_j`.
   Thus a small, smooth measured phase is not by itself an unambiguous wavelength
   or group velocity. Physical probe order, relative channel response, and the
   spatial aliasing branch must be established first.

   .. raw:: html

      <details class="k05-note"><summary>What makes high-frequency coherence small?</summary>

   Start with the average in :k05:eq:`experiment-coherence-phase`. In segment
   :math:`r`, let :math:`\psi_{X,r}` and :math:`\psi_{Y,r}` be the angles of the
   C1 and C3 Fourier coefficients, in radians. Writing those coefficients in polar
   form gives:

   .. k05:equation:: experiment-cross-phase-average
      :lang: en

      G(f)=\left\langle |Y_f^{(r)}|\,|X_f^{(r)}|\,e^{i\left(\psi_{Y,r}-\psi_{X,r}\right)}\right\rangle_R,\qquad \delta(f)=\arg G(f).


   Each product is a complex arrow. If the relative angles vary across segments,
   the arrows can cancel in the average even though both probes have nonzero
   power. Coherence also depends on the amplitudes, so it is not merely a count
   of matching angles. A repeatable linear relation requires a consistent complex
   ratio between the channels at that frequency.

   One possible cause is **low signal-to-noise ratio (SNR)**. To isolate this effect,
   consider a shared Fourier component :math:`S_f` and noise components
   :math:`N_{1,f}` and :math:`N_{3,f}`, all in V. Assume the noises are uncorrelated
   with the shared signal and with each other. Let :math:`T_f` be a fixed,
   dimensionless complex voltage ratio. Define the nonnegative powers
   :math:`P_s=\langle|S_f|^2\rangle`,
   :math:`P_{n1}=\langle|N_{1,f}|^2\rangle`, and
   :math:`P_{n3}=\langle|N_{3,f}|^2\rangle`, all in V². Then:

   .. k05:equation:: experiment-noisy-coherence
      :lang: en

      \begin{aligned}X_f&=S_f+N_{1,f},\qquad Y_f=T_fS_f+N_{3,f},\\ C_{13}^2(f)&=\frac{|T_f|^2P_s^2}{(P_s+P_{n1})(|T_f|^2P_s+P_{n3})}.\end{aligned}


   The uncorrelated cross terms vanish, leaving :math:`G=T_fP_s`,
   :math:`P_X=P_s+P_{n1}`, and :math:`P_Y=|T_f|^2P_s+P_{n3}`.
   Substituting these into :k05:eq:`experiment-coherence-phase` gives the result.
   Independent noise adds to each measured power without adding a repeatable
   cross term. If its power equals the shared-signal power in each channel, the
   coherence is 1/4. If its power is nine times larger in each channel, coherence
   is 1/100. These illustrate the mechanism; they are not fitted noise levels
   for this experiment.

   There are other possibilities: spatially decorrelated fluctuations, several
   components at the same frequency with different propagation phases, or a
   channel relationship that changes during the record. Finite windows and
   unresolved spectral structure can also affect the estimate. A short wavelength
   alone does not require low coherence: an ideal single coherent wave can retain
   unit coherence across a large phase difference.

   In the ideal resolved-frequency model, a fixed nonzero gain, phase shift, or
   linear filtering alone cancels out of normalized coherence. A high-frequency
   response roll-off can lower coherence indirectly if it weakens the shared
   signal relative to added noise. Thus neither the RMS difference in Figure 3
   nor proximity to the Nyquist frequency alone explains the drop. Distinguishing
   these causes requires, for example, measured background noise, repeatability
   under different segment lengths, or probe-spacing comparisons.

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>Why can phase be positive or negative, and why does it disappear?</summary>

   The plotted quantity is the angle of the averaged cross power,
   :math:`\delta=\arg\langle Y_fX_f^*\rangle`, not an average of the wrapped
   segment angles. A positive or negative value places this relative angle on
   one side or the other of zero. It does not indicate positive or negative
   energy transfer.

   To relate an angle to timing, first fix the convention. This page uses the
   positive-exponent Fourier transform. For a pure delay :math:`\tau` in seconds,
   with C3 recording an otherwise identical signal later than C1 when
   :math:`\tau>0`, a change of integration variable gives:

   .. k05:equation:: experiment-delay-phase
      :lang: en

      x_3(t)=x_1(t-\tau)\quad\Longrightarrow\quad Y_f=e^{+i2\pi f\tau}X_f,\qquad \delta(f)=\operatorname{wrap}_{[-\pi,\pi]}(2\pi f\tau).


   Here :math:`f` is frequency in Hz; :math:`\operatorname{wrap}` adds or subtracts
   whole multiples of :math:`2\pi` to put the result between :math:`-\pi` and
   :math:`\pi`. Before wrapping, a positive delay gives positive phase under this
   convention. For a 1 MHz sinusoid delayed by 0.6 microseconds, the unwrapped angle
   is :math:`1.2\pi`, but the displayed angle is :math:`-0.8\pi`. A negative
   displayed angle can therefore still describe a delayed signal. Phase wrapping
   and the channel responses must be resolved before interpreting a sign as a
   propagation direction; the pure-delay example is not a fit to Figure 7.

   The high-frequency gaps have a different cause: the plotting code masks
   low-coherence points. In this snippet, ``G`` and ``coherence`` are the arrays
   defined in :k05:eq:`experiment-coherence-phase`:

   .. code-block:: python

      phase = np.angle(G)  # Calculate at every frequency, in radians.
      phase_for_plot = np.where(coherence >= 0.5, phase, np.nan)

   ``np.nan`` leaves a gap in the plot. It does not mean zero phase, zero power,
   or no calculation. When the normalized cross-power vector is very small,
   small statistical changes can rotate its angle substantially. At exactly zero
   cross power, phase is mathematically undefined, regardless of the value a
   software routine returns. The cutoff of 0.5 is a display rule, not a physical
   cutoff or a confidence test; the last visible point near 16.83 MHz is therefore
   not a measured plasma cutoff frequency.

   .. raw:: html

      </details>

   .. rubric:: 6. Look for a relation between three frequencies

   Now choose two frequencies :math:`f_1,f_2` and their sum :math:`f_3=f_1+f_2`.
   The bispectrum averages :math:`X_{f_1}X_{f_2}X_{f_3}^*`, as in
   :k05:eq:`auto-bispectrum`. Its normalized magnitude squared is the
   **squared bicoherence** :math:`b^2` in :k05:eq:`bicoherence`.
   It measures repeatability of a three-frequency relation, not a transfer rate.

   For this exploratory map use 2048-sample segments: 20.48 microseconds,
   48.828 kHz frequency-bin spacing, and 4882 segments per capture. The last
   1664 samples are omitted. Shorter segments supply more averages but coarser
   frequency resolution. The same mean removal, Hann window and Fourier sign are
   used; the coefficients are recomputed on this new grid.

   .. figure:: /_static/K_Diagnostics/k05-experiment-bicoherence.svg
      :alt: Figure 8. C1 squared-bicoherence maps, with a shared logarithmic color scale.
      :width: 100%

      Figure 8. C1 squared-bicoherence maps, with a shared logarithmic color scale.



   The horizontal coordinate is :math:`f_2`; the vertical is :math:`f_1`.
   The third frequency is their sum, :math:`f_3=f_1+f_2`. Each colored cell
   therefore compares three components of the **same C1 record**, not C1 with C3.
   We show only :math:`0<f_1\leq f_2` with :math:`f_1+f_2\leq5\ \mathrm{MHz}`
   to avoid duplicating swapped pairs. White areas are outside this domain, not
   measured zeros. The triangular outline is an analysis boundary, not a wave branch.

   **What does a brighter region mean?** It means a larger normalized correlation
   between the product :math:`X(f_1)X(f_2)` and the sum-frequency component
   :math:`X(f_3)`, as defined in :k05:eq:`bicoherence`. To see the role of phase,
   call the phase of a Fourier coefficient :math:`\phi(f)`. The three phases enter
   through :math:`\Delta\phi=\phi(f_1)+\phi(f_2)-\phi(f_3)`.
   When this combination remains concentrated around a preferred angle across
   segments, the complex products tend to reinforce one another when averaged.
   When it wanders around the circle, they tend to cancel. This is called
   **quadratic phase coupling**. The amplitudes also weight the average, so
   :math:`b^2` is not a pure phase-locking score; stable phase alone does not
   guarantee :math:`b^2=1`.

   Unlike the PSD, **brightness does not measure how much wave power is present**.
   Here a value of 0.1 cannot be read as “10% of plasma energy is being transferred.”
   The three Fourier components may also be harmonics of one nonsinusoidal
   oscillation rather than three separately identified plasma modes
   :ref:`[5] <k05-data-reference-5-en>`.

   **A band represents a family of frequency combinations.** Let :math:`F`
   denote a fixed frequency in the following guide; it is not a fitted parameter.

   .. list-table:: Read the direction of a band using these axes
      :header-rows: 1
      :widths: 24 27 49

      * - Pattern
        - What stays fixed
        - What the associated combinations share
      * - Horizontal band
        - :math:`f_1\simeq F`
        - One component near F; the other two are near :math:`f_2` and :math:`f_2+F`.
      * - Vertical band
        - :math:`f_2\simeq F`
        - One component near F; the other two are near :math:`f_1` and :math:`f_1+F`.
      * - Downward-sloping diagonal band
        - :math:`f_1+f_2\simeq F`
        - Many different pairs share the same sum frequency near F.

   In Figure 8, all four captures show a brighter region close to the bottom edge.
   Here :math:`f_1` is small, so :math:`f_2` and :math:`f_3` are close together:
   the pattern links a low-frequency component to a range of higher-frequency
   components and their nearby sum components. A possible mechanism is modulation:
   if a low-frequency fluctuation is itself present in the record and the amplitude
   of faster fluctuations varies with its phase, it can produce such relations.
   This is a candidate explanation, not a mechanism identified by this map.
   The band does **not** establish that low frequencies feed high frequencies,
   nor the reverse. The two lowest rows also deserve particular care because
   their spacing is only 48.828 kHz; the segment-length comparison below shows
   how this narrow region changes with the analysis window.

   .. raw:: html

      <details class="k05-note"><summary>Why is this a clue to wave interactions, but not proof of energy transfer?</summary>

   A quadratic term multiplies two fluctuations. Multiplying two sinusoidal
   components produces sum and difference frequencies whose phases are tied to
   the original phases. Wave interactions described by such terms can therefore
   leave the phase relations that a bicoherence map detects. A bright band is a
   useful place to investigate that possibility.

   But the measurement only establishes a statistical relation. A repeating
   nonsinusoidal waveform, a shared modulating process, or a nonlinear probe or
   electronics response can also produce related Fourier components. Finite
   records and spectral leakage can spread structure over neighboring bins.
   Repetition in four captures supports reproducibility of the pattern; it does
   not distinguish these causes or supply a significance test.

   The nonnegative quantity :math:`b^2` also discards the bispectrum's phase.
   Determining transfer requires a dynamical coupling coefficient and its phase
   relative to the bispectrum, as in :k05:eq:`spectral-power-balance`, together with
   the measurement-response assumptions. Even a bright region alone supplies
   neither a transfer direction nor a rate. Conversely, dark regions need not
   rule out dynamics obscured by noise or phase cancellation.

   .. raw:: html

      </details>

   **Read the numerical color scale as well as the pattern.** Figures 8–10 share
   a logarithmic scale from :math:`10^{-4}` to :math:`1`; ticks are actual
   :math:`b^2` values. Each equal colorbar interval is a factor of ten, not an
   equal increase in correlation. Values below :math:`10^{-4}`, including zero,
   use the darkest color; the lower arrow marks that display floor. A clearly
   visible band can therefore still have a small :math:`b^2`. The floor is not a
   significance threshold. The positive-frequency view also does not exclude
   difference interactions or frequencies above 5 MHz from the physical model.

   .. raw:: html

      <details class="k05-note"><summary>Compare the other probe on exactly the same scale</summary>

   .. figure:: /_static/K_Diagnostics/k05-experiment-bicoherence-c3.svg
      :alt: Figure 9. C3 maps on the same logarithmic color scale as C1.
      :width: 100%

      Figure 9. C3 maps on the same logarithmic color scale as C1.

   Similar maps show repeatable spectral relations at both measurement channels. They do not determine the direction of nonlinear transfer.

   .. raw:: html

      </details>


   .. raw:: html

      <details class="k05-note"><summary>Check the choice of segment length before interpreting a bright band</summary>

   .. figure:: /_static/K_Diagnostics/k05-experiment-sensitivity.svg
      :alt: Figure 10. Segment-length comparison, using the same logarithmic color scale as Figures 8–9.
      :width: 100%

      Figure 10. Segment-length comparison, using the same logarithmic color scale as Figures 8–9.


   Here the raw C1 record is fixed and N changes from 1024 to 2048 to 4096.
   The color scale remains identical to Figures 8–9; no panel is rescaled to its own peak.
   The narrow low-frequency region changes markedly. These three estimates do
   not have the same bin bandwidth or number of realizations. Therefore a bright
   cell, its maximum value and the first positive-frequency row should not be
   treated as resolution-independent evidence. A narrower band is not automatically
   more accurate: fewer averages also increase scatter. Nonoverlap does not ensure
   statistically independent segments in a signal with long correlations.

   .. raw:: html

      </details>


   .. rubric:: 7. Connect these figures to growth and transfer inference

   The spectra correspond to the type of observable in Fig. 2(b) of |brown-en|,
   with our explicitly stated voltage-PSD units. To reach the growth curve and
   nonlinear-transfer results, the next calculation uses the
   :ref:`joint two-probe model <k05-inference-en>`: construct the cross bispectrum
   and full fourth-order matrix, estimate coefficients, and check prediction
   errors on a different capture. The :ref:`next page <k05-validation-en>` compares
   linear-only and joint predictions by fitting three captures and testing on the
   fourth, then examines residuals, conditioning and analysis-setting sensitivity.
   Kim's additional stationarity assumptions are a separate inference choice.

   Two distinctions matter for these measurements. First, ion-current voltage
   requires a justified current–density–potential response before the result can
   be expressed as potential or plasma energy. Second, a spatial coefficient
   needs the signed separation and appropriate group velocity to become a temporal
   growth or transfer rate. The 3.7 mm separation alone supplies neither velocity
   nor a unique spatial phase branch. A larger C3 RMS or a nonzero bicoherence
   must not be substituted for those steps.

   .. raw:: html

      <details class="k05-note"><summary>Reproduce the calculations and inspect their provenance</summary>

   The analysis needs NumPy, SciPy and Matplotlib. From the repository root:

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py \
        --data /path/to/experiment-data \
        --output /path/to/derived-results

   The data directory is searched recursively for the eight named binary files.
   Outputs include figures, ``spectral_arrays.npz`` and ``analysis_summary.json``
   with input hashes, header scales, processing choices and explicit unknowns.
   The original binary captures are required to recompute; they are not embedded
   in this page. The displayed figures are saved outputs, so a page load does not
   rerun Python. The PSD is checked numerically against SciPy's Welch estimator
   |scipy-en| with the same window, detrending and zero overlap.

   Download the :download:`analysis script <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py>`,
   :download:`binary reader <../../../../K_Diagnostics/K05_bispectral_transfer/siglent_v4.py>` and
   :download:`acquisition metadata <../../../../K_Diagnostics/K05_bispectral_transfer/experiment_z5p5_a3p7.json>`
   into one folder if running outside the repository.
   The :download:`figure provenance <../../_static/K_Diagnostics/k05-experiment-summary.json>`
   records the run used on this page.

   .. raw:: html

      </details>


   .. rubric:: References

   .. _k05-data-reference-1-en:

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**, 115101
   (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   .. _k05-data-reference-2-en:

   [2] SIGLENT, *How to Extract Data from the Binary File of SIGLENT Oscilloscope*,
   EN03A (2024), V4.0, pp. 38–46.
   `Format specification <https://siglentna.com/wp-content/uploads/dlm_uploads/2024/06/How-to-Extract-Data-from-the-Binary-File.pdf>`_.

   .. _k05-data-reference-3-en:

   [3] SciPy, ``scipy.signal.welch``.
   `Estimator documentation <https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.welch.html>`_.

   .. _k05-data-reference-4-en:

   [4] MathWorks, *Cross Spectrum and Magnitude-Squared Coherence*.
   `Phase interpretation and low-coherence masking <https://www.mathworks.com/help/signal/ug/cross-spectrum-and-magnitude-squared-coherence.html>`_.

   .. _k05-data-reference-5-en:

   [5] T. J. Maccarone, “The biphase explained: understanding the asymmetries in
   coupled Fourier components of astronomical time series,” *Monthly Notices of
   the Royal Astronomical Society* **435**, 3547–3558 (2013), Sections 2–4.
   `doi:10.1093/mnras/stt1546 <https://doi.org/10.1093/mnras/stt1546>`_.


.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-experiment-zh:

   .. rubric:: 把八个文件变成可以逐步检查的物理统计量

   前面的页面介绍了数学方法。现在用两支离子饱和电流探针（ion saturation current probes）
   的四组同步 C1–C3 记录，从波形开始实际计算：先看波动长什么样，再看它包含哪些频率、
   两支探针是否记录到共同的波动，最后查看三个频率之间是否存在稳定的相位关系。
   下面的图都来自这组实验数据。

   这条分析路线与 Brown 和 Jorns |brown-zh| 从测量走向谱统计量的过程相衔接。
   这里是另一组实验，频谱中的峰需要结合本实验工况识别，不能直接套用文献中的 EDI 模式名称。

   .. rubric:: 1. 先弄清一个文件装了什么

   每个文件保存一个示波器通道。文件后缀 **2、3、4、5** 对应四次记录；
   相同后缀的 C1 与 C3 同步采集。数据提供者确认四组工况相同。
   探针位于出口平面下游 **5.5 mm**，两探针周向距离 **3.7 mm**；
   C1 到 C3 沿推力器周向的具体方向暂未确定。

   .. list-table:: 采样信息
      :header-rows: 1
      :widths: 42 58

      * - 量
        - 数值
      * - 采样率 :math:`f_s`
        - 100 MS/s，八个文件头一致
      * - 每路每组采样点数
        - 10,000,000
      * - 采样间隔／记录时长
        - 10 ns／0.1 s
      * - 奈奎斯特频率 :math:`f_s/2`
        - 50 MHz
      * - 存储码／竖直比例
        - 16 位无符号整数；7680 码/格，2 V/格
      * - 本页面实际分析的量
        - 离子电流诊断输出的电压波动，单位 V

   文件中的 16 位存储格式与示波器标称的 12 位 ADC 分辨率是不同概念。
   电压到电流的换算和两路频率响应还没有在这里标定。这些电压尤其不能直接视为
   **等离子体电势**。

   .. raw:: html

      <details class="k05-note"><summary>为什么先看波动，而不直接报告绝对直流电平？</summary>

   实验人员提供的读取脚本对文件头竖直偏置取减号；厂商 V4 示例 |siglent-zh| 则写加号。
   脚本注释称减号经过直流标定，但本数据包尚未包含那次标定的原始记录。
   实验结束后的示波器照片可以印证采样和量程设置，不能当作这些等离子体记录的均值。
   例如第 2 组，两个符号会给出 C1 均值 −0.100665 或 +0.899335 V，
   C3 均值 +0.283286 或 +1.549953 V；这里不把任一候选值当作已标定直流电流。

   这个差别对每路只是一个常数，减去整段或短段均值后恰好消失。
   所以读取器默认返回相对整段均值的波动，并在输出清单中保留两种直流候选值。
   去均值不能消除增益、极性或频率响应误差。

   .. raw:: html

      </details>


   用 :math:`c_j[n]` 表示通道 :math:`j=1,3` 的第 :math:`n` 个存储整数。
   先减去整段记录的平均码值 :math:`\overline{c_j}`，再乘以每个码对应的电压 :math:`g_j`：

   .. k05:equation:: experiment-code-fluctuation
      :lang: zh

      x_j[n]=g_j\bigl(c_j[n]-\overline{c_j}\bigr),\qquad g_j=\frac{2\ \mathrm{V/div}}{7680\ \mathrm{codes/div}}.


   得到的 :math:`x_j[n]` 是相对该记录均值的电压波动。这一步只减去常数，没有平滑波形。
   原文件及其哈希保留；下图把每次记录的起点设为零时刻，而不是使用示波器的触发时刻。

   .. figure:: /_static/K_Diagnostics/k05-experiment-raw.svg
      :alt: 图 1．四组记录分别减去整段均值后的波动。青色为 C1，橙色为 C3。
      :width: 100%

      图 1．四组记录分别减去整段均值后的波动。青色为 C1，橙色为 C3。



   半透明带保留每 10,000 点（0.1 ms 显示区间）的最小值与最大值，细线表示该区间均值。
   如果仅每隔一万点抽取一个点，可能漏掉很短的尖峰；这里的范围带能把它们保留下来。
   后续计算使用全部原始采样点，不使用这些显示区间代替波形。八个文件中都没有码值达到
   0 或 65535；这只能排除触及存储码上下限，不能排除所有模拟电路过载。

   .. raw:: html

      <details class="k05-note"><summary>放大后，全长范围带中藏着什么？</summary>

   .. figure:: /_static/K_Diagnostics/k05-experiment-zoom.svg
      :alt: 图 2．第 2 组记录在 50 ms 处展开的 20 μs 波形。
      :width: 100%

      图 2．第 2 组记录在 50 ms 处展开的 20 μs 波形。

   两个面板使用完全相同的采样时刻。现在能看清单次起伏；形状接近本身不能判断它们的传播机制。

   .. raw:: html

      </details>


   .. rubric:: 2. 检查一段记录内部是否在缓慢变化

   全长图可能掩盖均值或波动强弱的变化。把每份记录分成 100 个连续的 **1 ms 小段**，
   每段 :math:`M=100{,}000` 点。对第 :math:`r` 段计算均值 :math:`\mu_{j,r}`
   和波动的均方根（root mean square, RMS） :math:`\sigma_{j,r}`：

   .. k05:equation:: experiment-block-statistics
      :lang: zh

      \mu_{j,r}=\frac{1}{M}\sum_{n=0}^{M-1}x_{j,r}[n],\qquad \sigma_{j,r}=\sqrt{\frac{1}{M}\sum_{n=0}^{M-1}\bigl(x_{j,r}[n]-\mu_{j,r}\bigr)^2}.


   RMS 的计算就是：减去局部均值、平方、平均、开方。它表示典型波动幅度，单位仍为 V。
   这里 :math:`r` 是小段序号，:math:`n` 是小段内的采样点序号。

   .. figure:: /_static/K_Diagnostics/k05-experiment-stability.svg
      :alt: 图 3．相对整段均值的局部均值，以及局部波动 RMS。
      :width: 100%

      图 3．相对整段均值的局部均值，以及局部波动 RMS。



   对同一通道而言，四组记录的均值变化和 RMS 范围相近。
   对整份记录计算，C1 的 RMS 为 0.626–0.629 V，C3 为 0.756–0.758 V：
   也就是 **C3 测到的电压波动幅度约大 20%**。这里比较的是各自均值附近的波动大小，
   不是两路直流电压的高低。减去均值只去掉一个偏置，不会让两路波动幅度自动相等。

   .. raw:: html

      <details class="k05-note"><summary>为什么两支探针的 RMS 可以不同？</summary>

   RMS 描述的是测量波动有多大，不是在辨认它是不是同一列波。
   即使两支探针响应的是同一个扰动，完整的测量响应也不一定相同。
   例如，探针收集面积或灵敏度、电流到电压的转换、通道增益（gain）有差异，
   都可能改变记录的幅度。举一个简单例子：把每个波动值都乘以 1.2，
   它的 RMS 也会乘以 1.2，这并不要求波在等离子体中真的增长。
   示波器设置相同的 V/div，也不能证明探针及整条测量电路的响应相同。

   两个位置的真实局部波动也可能不同，测量噪声同样会计入 RMS。
   仅凭图 3 无法区分这些原因。目前清楚的事实是：每个通道内部的四组记录具有较好的重复性，
   而两个通道之间持续存在幅度差；这个幅度差的具体来源尚不能确定。

   单纯的时间延迟改变波形的先后位置，不改变它本身的波动大小：
   对于等幅、统计平稳的信号，足够长记录的 RMS 应相同。
   有限的 1 ms 小段可能因为两端包含不同采样点而略有差别，
   但稳定的 RMS 比值本身不能证明传播方向或增长率。
   此外，这里的 RMS 汇总了记录中所有频率的波动；
   若要判断某个模式是否增长，还需要按频率分析，并区分实际波动和测量响应。

   .. raw:: html

      </details>

   同一点随时间统计稳定，与 :ref:`Kim 修正 <k05-inference-zh>` 使用的空间平稳假设，
   是两件需要分别检查的事。

   .. rubric:: 3. 截取短记录，先看看加窗究竟改了什么

   计算频谱时，每段取 **16,384 点**，两路从相同采样点起切分。
   每段时长 163.84 μs；每组得到 610 个完整、不重叠的短段。
   末尾不足一段的 5760 点，即 57.6 μs，舍去。四组分别计算，不把不同采集的端点
   拼成一条人为连续的信号。

   先减去每个短段自身的均值，再乘以 **周期 Hann 窗（periodic Hann window）**。
   这个窗让两端逐渐变小，减轻有限截取引起的谱泄漏（spectral leakage）。
   它也会改变幅度，所以计算功率谱时必须考虑窗的归一化。下图展示第 2 组 C1 的第一个短段。

   .. figure:: /_static/K_Diagnostics/k05-experiment-segments.svg
      :alt: 图 4．同一个短段在加 Hann 窗前后的形状。
      :width: 100%

      图 4．同一个短段在加 Hann 窗前后的形状。



   .. k05:equation:: experiment-windowed-coefficients
      :lang: zh

      X_k^{(r)}=\frac{1}{N}\sum_{n=0}^{N-1}w_n\bigl(x_{1,r}[n]-\overline{x_{1,r}}\bigr)e^{+i2\pi kn/N},\qquad f_k=\frac{k f_s}{N}.


   :math:`N` 是每段采样点数，:math:`r` 是短段序号，:math:`w_n` 是窗函数，
   :math:`k` 是整数频点序号。:math:`X_k^{(r)}` 是 C1 的复数傅里叶系数，单位 V；
   对 C3 做同样运算得到 :math:`Y_k^{(r)}`。此处横线表示该短段的均值。
   正指数和 :math:`1/N` 归一化沿用 :k05:eq:`time-fourier-series`。
   当前相邻频点间隔为 **6.104 kHz**。

   .. raw:: html

      <details class="k05-note"><summary>公式对应的 Python 代码：保持同一傅里叶符号</summary>

   .. code-block:: python

      blocks = voltage[:R*N].reshape(R, N)
      centered = blocks - blocks.mean(axis=1, keepdims=True)
      window = scipy.signal.windows.hann(N, sym=False)
      X = np.fft.rfft(centered * window, axis=1).conj() / N
      f = np.fft.rfftfreq(N, d=1/fs)

   对实数输入，NumPy 负指数变换结果取共轭，就得到这里的正指数系数；除以 N 设置归一化。
   没有补零或重采样。频点间隔也不等于 Hann 谱峰的完整分辨宽度；
   其等效噪声带宽（equivalent noise bandwidth）是 1.5 个频点。
   分段和加窗基础可参见 :doc:`已有处理页面 <K01_signal_spectra/fun_K01_segment_ffts>`。

   .. raw:: html

      </details>


   .. rubric:: 4. 平方后平均，得到功率谱

   对每个频点，把 610 个短段的系数模长平方后取平均。
   若要写成单边功率谱密度（one-sided power spectral density, PSD），
   还要计入窗函数和频点间隔：

   .. k05:equation:: experiment-hann-psd
      :lang: zh

      w_n=\frac12\left(1-\cos\frac{2\pi n}{N}\right),\quad U=\frac1N\sum_n w_n^2=\frac38,\qquad S_{XX}^{+}(f_k)=\frac{s_k N}{f_s U}\left\langle|X_k|^2\right\rangle_R.


   :math:`U` 是窗函数的均方值；正频率内部频点取 :math:`s_k=2`，
   零频率和奈奎斯特频点取 :math:`s_k=1`。尖括号对 :math:`R=610` 个短段平均。
   上标 :math:`+` 表示单边谱；:math:`S_{XX}^{+}` 的单位是 :math:`\mathrm{V^2/Hz}`。
   把 X 换成 Y 就得到 C3 的功率谱。这里校正的是 PSD，
   与恢复单一正弦波峰值幅度的校正不同，参见
   :doc:`窗函数与功率谱归一化 <K01_signal_spectra/fun_K01_power_spectrum>`。

   .. figure:: /_static/K_Diagnostics/k05-experiment-psd.svg
      :alt: 图 5．四组分别计算的单边电压功率谱密度。
      :width: 100%

      图 5．四组分别计算的单边电压功率谱密度。



   横轴是频率，纵轴表示单位频率内的电压方差，两轴都使用对数尺度。
   每个面板的四条曲线非常接近，表明四次采集得到的谱形具有重复性。
   低频有峰，高频也有结构；仅凭峰的位置还不能确定其等离子体机制或排除电路干扰。
   这里保留到 50 MHz 的完整单边谱；奈奎斯特上限本身也不保证模拟信号中超出该范围的成分
   已被充分滤除。

   .. raw:: html

      <details class="k05-note"><summary>平均之前：这些频率成分是否随时间改变？</summary>

   .. figure:: /_static/K_Diagnostics/k05-experiment-spectrogram.svg
      :alt: 图 6．第 2 组记录在时间平均之前的分段频谱。
      :width: 100%

      图 6．第 2 组记录在时间平均之前的分段频谱。


   每一竖列是一段频谱，横坐标为该段的中心时刻，颜色为以 V²/Hz 表示的 PSD 的十进制对数。
   水平条带表示某个频率附近持续有功率；竖直条纹则表示短时间内多个频率同时变化。
   这张 0–5 MHz 时频图（spectrogram）保留了平均曲线掩盖的时间变化。
   外观相近是选择统计区间的线索，还不是严格的平稳性检验。

   .. raw:: html

      </details>


   .. rubric:: 5. 保留相位，比较两支探针

   对每个频率，计算互谱 :math:`G`、平方相干度（magnitude-squared coherence）
   :math:`C_{13}^2` 和互谱相位 :math:`\delta`：

   .. k05:equation:: experiment-coherence-phase
      :lang: zh

      C_{13}^2(f)=\frac{|G(f)|^2}{P_X(f)P_Y(f)},\qquad G(f)=\langle Y_fX_f^*\rangle_R,\qquad \delta(f)=\arg G(f).


   :math:`P_X=\langle|X|^2\rangle_R`、:math:`P_Y=\langle|Y|^2\rangle_R`
   是加窗后的频点功率，单位 :math:`\mathrm{V^2}`。
   相干度无量纲，范围 0–1；较大值意味着两路在该频率上存在可重复的线性关系。
   星号表示复共轭，:math:`\arg` 表示取相位角，单位弧度。

   .. figure:: /_static/K_Diagnostics/k05-experiment-cross.svg
      :alt: 图 7．同步双通道的相干度和互谱相位：左列为 0–50 MHz 全范围，右列为 0–5 MHz 局部放大。
      :width: 100%

      图 7．同步双通道的相干度和互谱相位：左列为 0–50 MHz 全范围，右列为 0–5 MHz 局部放大。



   采样率为 100 MS/s，奈奎斯特频率就是 50 MHz。
   左列展示与功率谱对应的 **0–50 MHz 全范围**，右列把 **0–5 MHz 局部放大**，
   便于看清低频细节。两列使用同一组计算频点，没有额外滤波或重新采样。
   5 MHz 只是局部放大图的边界，不是采样或分析上限。

   在 0.5–5 MHz 内，四组相干度的中位数为 **0.988–0.989**；这个数只描述该频段，
   不能代表全频段。为了避免图中充满低相干频点的散乱相位，只显示相干度不低于 0.5 的相位点，
   相干度本身则保留全部频点。因此，相位图中的空白不表示这些频率没有参与计算。
   0.5 是显示门槛，不是统计显著性阈值。计算没有为了让两路更相似而人为平移某一路信号。

   在 **25–50 MHz** 区间，四组相干度的中位数降到 **0.0017–0.0020**，
   说明两路测量在这些频率上几乎没有稳定、可重复的线性关联。
   图 5 中这些频率的电压功率谱也低得多。一种可能是共同信号变弱，独立噪声的相对占比上升；
   但现有测量没有独立确定噪声底（noise floor），也不能据此证明高频等离子体波动不存在。

   相位的正负是相对角度被包裹在 :math:`-\pi` 到 :math:`\pi` 之间的结果。
   约 **16.83 MHz** 以上，四组都没有频点通过相位的显示门槛，所以相位图留白。
   这些相位已经计算，但低相干时不能可靠地把它们解释成稳定的滞后关系 |phaseguide-zh|。
   下面两个折叠区分别解释相干度降低，以及相位正负和留白的含义。

   高相干既可能来自传播波动，也可能来自共同源、电路干扰或串扰。
   要把相位解释为传播，先写清测量链路：

   .. k05:equation:: experiment-measurement-phase
      :lang: zh

      X_f=H_1(f)I_{1,f},\quad Y_f=H_3(f)I_{3,f},\qquad \delta_V=\delta_I+\arg H_3-\arg H_1\pmod{2\pi}.


   :math:`I_{j,f}` 是探针电流的傅里叶系数，单位 A；:math:`H_j(f)` 是电流到电压的复响应，
   单位 V/A；:math:`\delta_I` 是电流互谱相位，:math:`\delta_V` 是测得的电压互谱相位。
   通道延迟会进入 :math:`\arg H_j`。因此，小而平滑的相位差还不能唯一给出波长或群速度。
   需要确认探针方向、两路相对响应，以及空间混叠（spatial aliasing）对应的相位分支。

   .. raw:: html

      <details class="k05-note"><summary>高频相干度为什么会变小？</summary>

   先看 :k05:eq:`experiment-coherence-phase` 中的平均。
   对第 :math:`r` 段，用 :math:`\psi_{X,r}` 和 :math:`\psi_{Y,r}`
   表示 C1、C3 傅里叶系数的角度，单位为弧度。把系数写成“模长乘相位因子”，就得到：

   .. k05:equation:: experiment-cross-phase-average
      :lang: zh

      G(f)=\left\langle |Y_f^{(r)}|\,|X_f^{(r)}|\,e^{i\left(\psi_{Y,r}-\psi_{X,r}\right)}\right\rangle_R,\qquad \delta(f)=\arg G(f).


   每一段的乘积可以看成复平面上的一个箭头。如果各段的相对角度变化很大，
   这些箭头平均时就会相互抵消，即使两支探针各自仍有非零功率。
   相干度也受幅度关系影响，不能只理解成“角度相同的次数”。
   稳定的线性关系要求两路在该频率上具有一致的复数比例。

   一种可能的原因是 **信噪比（signal-to-noise ratio, SNR）降低**。
   为单独说明这个机制，设 :math:`S_f` 是共同信号的傅里叶系数，
   :math:`N_{1,f}`、:math:`N_{3,f}` 是两路噪声系数，单位均为 V。
   假设两路噪声彼此不相关，也都与共同信号不相关。
   用 :math:`T_f` 表示固定、无量纲的复数电压比例。
   定义功率 :math:`P_s=\langle|S_f|^2\rangle`、
   :math:`P_{n1}=\langle|N_{1,f}|^2\rangle`、
   :math:`P_{n3}=\langle|N_{3,f}|^2\rangle`，单位均为 V²，则：

   .. k05:equation:: experiment-noisy-coherence
      :lang: zh

      \begin{aligned}X_f&=S_f+N_{1,f},\qquad Y_f=T_fS_f+N_{3,f},\\ C_{13}^2(f)&=\frac{|T_f|^2P_s^2}{(P_s+P_{n1})(|T_f|^2P_s+P_{n3})}.\end{aligned}


   由于不相关的交叉项平均为零，:math:`G=T_fP_s`，
   :math:`P_X=P_s+P_{n1}`，:math:`P_Y=|T_f|^2P_s+P_{n3}`。
   把这三项代回 :k05:eq:`experiment-coherence-phase`，就得到上式。
   独立噪声增加各通道测到的功率，却不增加稳定的互谱项。
   如果每一路的噪声功率恰好等于其中的共同信号功率，相干度就是 1/4；
   如果噪声功率都是共同信号功率的九倍，相干度就是 1/100。
   这两个数用于解释机制，不是对本实验噪声水平的拟合。

   还可能有其他原因：两处波动在空间上失去关联、同一频率混合了具有不同传播相位的成分，
   或者两路关系在记录期间发生变化。有限窗口和分辨不开的频谱结构也会影响估计。
   不能仅因为“高频波长较短”就断言低相干：理想的单一相干波即使相位差很大，
   仍可以保持相干度为 1。

   在理想、频率已分辨的模型中，固定的非零增益、相位差或线性滤波本身会在归一化中抵消，
   并不自动降低相干度。高频响应的衰减若让共同信号相对附加噪声变弱，才可能间接降低相干度。
   所以，图 3 的 RMS 差异或接近奈奎斯特频率本身，都不能单独解释这个下降。
   要区分这些原因，可以对照实测背景噪声、不同分段长度下的重复性，或不同探针间距的结果。

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>相位为什么有正有负，高频又为什么不见了？</summary>

   图中取的是平均互谱的角度 :math:`\delta=\arg\langle Y_fX_f^*\rangle`，
   不是把每段已包裹的角度直接算术平均。正负表示这个相对角度落在零的哪一侧，
   不表示能量转移的正负。

   要把角度解释为时间先后，先固定符号约定。本页面的傅里叶正变换使用正指数。
   考虑一个纯时间延迟 :math:`\tau`，单位为秒：若 :math:`\tau>0`，
   表示完全相同的信号在 C3 中比 C1 晚到。对变换积分作变量代换可得：

   .. k05:equation:: experiment-delay-phase
      :lang: zh

      x_3(t)=x_1(t-\tau)\quad\Longrightarrow\quad Y_f=e^{+i2\pi f\tau}X_f,\qquad \delta(f)=\operatorname{wrap}_{[-\pi,\pi]}(2\pi f\tau).


   这里 :math:`f` 是频率，单位 Hz；:math:`\operatorname{wrap}`
   表示加减整圈 :math:`2\pi`，把角度放回 :math:`-\pi` 到 :math:`\pi` 之间，
   即相位包裹（phase wrapping）。在此约定下，未包裹的正延迟对应正相位。
   例如，一个 1 MHz 的正弦波晚到 0.6 μs，未包裹的相位为 :math:`1.2\pi`，
   图上却显示成 :math:`-0.8\pi`。因此，负的显示角度也可能对应晚到的信号。
   解释传播方向前需要确定相位分支和通道响应；这个纯延迟例子并不是对图 7 的拟合。

   高频留白是另一个原因：绘图时隐藏了低相干点。
   下面代码中，``G`` 和 ``coherence`` 分别是 :k05:eq:`experiment-coherence-phase`
   定义的互谱与平方相干度数组：

   .. code-block:: python

      phase = np.angle(G)  # 每个频点都计算相位，单位为弧度。
      phase_for_plot = np.where(coherence >= 0.5, phase, np.nan)

   ``np.nan`` 让图中该处留白，不代表相位为零、功率为零或没有计算。
   当归一化后的互谱箭头很短时，小的统计变化就可能让它的方向明显改变。
   若互谱恰好为零，相位在数学上没有定义，不能把软件返回的数值当作物理相位。
   这里的 0.5 只是显示规则，不是物理截止或置信度检验；
   最后一个可见点约为 16.83 MHz，也不能解释成测得了等离子体的截止频率。

   .. raw:: html

      </details>

   .. rubric:: 6. 再看三个频率之间的关系

   取两个频率 :math:`f_1,f_2`，第三个为 :math:`f_3=f_1+f_2`。
   按照 :k05:eq:`auto-bispectrum`，对乘积 :math:`X_{f_1}X_{f_2}X_{f_3}^*` 平均得到双谱。
   其归一化模平方就是 :k05:eq:`bicoherence` 中的 **平方双相干度（squared bicoherence）**
   :math:`b^2`。它衡量三频关系的重复性，还不是转移率。

   这张探索图改用每段 2048 点：时长 20.48 μs，频点间隔 48.828 kHz，
   每组有 4882 段，舍去末尾 1664 点。短段增加平均次数，但降低频率分辨能力。
   仍使用相同的去均值、Hann 窗和傅里叶符号，在新频率网格上重新计算系数。

   .. figure:: /_static/K_Diagnostics/k05-experiment-bicoherence.svg
      :alt: 图 8．C1 四组平方双相干图，使用统一的对数色标。
      :width: 100%

      图 8．C1 四组平方双相干图，使用统一的对数色标。



   横轴为 :math:`f_2`，纵轴为 :math:`f_1`，第三个频率是两者之和 :math:`f_3=f_1+f_2`。
   每个着色格点比较的是 **同一条 C1 记录内部的三个频率成分**，不是 C1 与 C3 的相干度。
   只画 :math:`0<f_1\leq f_2` 且 :math:`f_1+f_2\leq5\ \mathrm{MHz}`，避免交换前两个频率后重复画图。
   白色区域是未计算的域，不是测得的零；三角形轮廓由选取的频率范围决定，不是一条波的分支。

   **亮的区域代表什么？** 代表两个频率成分的乘积 :math:`X(f_1)X(f_2)`，
   与和频成分 :math:`X(f_3)` 之间的归一化关联较大，定义见 :k05:eq:`bicoherence`。
   把 Fourier 系数的相位记为 :math:`\phi(f)`，这里比较的是三者的相位组合
   :math:`\Delta\phi=\phi(f_1)+\phi(f_2)-\phi(f_3)`。
   如果这个角度在不同短段中较集中，平均时各段的复数乘积容易同向累加；
   如果角度在整个圆周上游走，它们就容易相互抵消。
   这称为 **二次相位耦合（quadratic phase coupling）**。
   幅度也参与加权，因此 :math:`b^2` 不是只看相位的指标；相位稳定也不保证它等于 1。

   与功率谱不同，**越亮不等于该处波能量越大**。
   这里的 0.1 也不能解释成“有 10% 的等离子体能量正在转移”。
   这三个 Fourier 成分还可能是同一个非正弦振荡的谐波，
   并不自动对应三个已经辨认出的独立等离子体波模 :ref:`[5] <k05-data-reference-5-zh>`。

   **亮带代表一整族相关的频率组合。** 下表用 :math:`F` 表示一个固定频率，
   它只是读图用的符号，不是拟合参数。

   .. list-table:: 按本图的坐标方向理解亮带
      :header-rows: 1
      :widths: 24 27 49

      * - 形状
        - 保持不变的量
        - 这些频率组合共有的特征
      * - 水平亮带
        - :math:`f_1\simeq F`
        - 都包含 F 附近的一个成分，另两个在 :math:`f_2` 和 :math:`f_2+F` 附近。
      * - 竖直亮带
        - :math:`f_2\simeq F`
        - 都包含 F 附近的一个成分，另两个在 :math:`f_1` 和 :math:`f_1+F` 附近。
      * - 向右下方倾斜的亮带
        - :math:`f_1+f_2\simeq F`
        - 不同频率对都与同一个 F 附近的和频成分关联。

   图 8 四组在靠近底边处都有较亮的区域。这里 :math:`f_1` 很小，
   所以 :math:`f_2` 和 :math:`f_3` 很接近：
   它显示低频成分与多个较高频成分及其邻近和频成分之间存在关联。
   一种可能的机制是 **调制（modulation）**：如果记录中有这个低频波动，
   而较快波动的幅度又随着它的相位变化，就可能留下这样的关系。
   这是候选解释，尚不能仅凭图确认。
   亮带 **不能判定低频在给高频供能，也不能判定反向供能**。
   最下面两行还需特别谨慎：频点间隔只有 48.828 kHz，
   后面的分段长度对比会显示，这个窄区域如何随分析窗口改变。

   .. raw:: html

      <details class="k05-note"><summary>为什么它是波—波相互作用的线索，却还不是能量转移的证据？</summary>

   二次项会把两个波动相乘。两个正弦成分相乘会产生和频与差频，
   其相位由原来的两个相位共同决定。因此，由二次项描述的波—波相互作用
   （wave–wave interaction）确实可能留下双相干能够检测的相位关系。
   亮带告诉我们，哪些频率组合值得进一步检查这种可能性。

   但测量直接给出的仍是统计关系。重复出现的非正弦波形、共同的调制过程，
   以及探针或电路的非线性响应，也可能产生相关的 Fourier 成分。
   有限记录和谱泄漏还可能把结构扩散到邻近频点。
   四组中重复出现说明这个图案具有可重复性，不能单凭这一点区分上述来源，也不构成显著性检验。

   此外，:math:`b^2` 非负，并且舍去了双谱本身的相位。
   要判断转移，还需要动力学耦合系数及其相对双谱的相位，
   如 :k05:eq:`spectral-power-balance` 所示，并核查测量响应假设。
   因此，单靠亮区既得不到转移方向，也得不到转移速率。
   反过来，暗区也不能排除被噪声或相位抵消掩盖的动力学过程。

   .. raw:: html

      </details>

   **读图案时也要看色条上的实际数值。** 图 8–10 统一使用
   :math:`10^{-4}` 到 :math:`1` 的对数色标（logarithmic color scale），刻度仍是实际 :math:`b^2`。
   色条上每段相等距离表示数值增加十倍，不是关联强度等量增加。
   小于 :math:`10^{-4}` 的值（包括零）使用最暗颜色，底部箭头标示这个显示下限。
   所以，看起来很清楚的亮带，实际 :math:`b^2` 仍可能较小；显示下限不是显著性阈值。
   这张正频率图也没有从物理模型中排除差频作用或 5 MHz 以上的频率。

   .. raw:: html

      <details class="k05-note"><summary>用完全相同的色标，再看另一支探针</summary>

   .. figure:: /_static/K_Diagnostics/k05-experiment-bicoherence-c3.svg
      :alt: 图 9．C3 的平方双相干图，对数色标与 C1 相同。
      :width: 100%

      图 9．C3 的平方双相干图，对数色标与 C1 相同。

   相似的图说明两路都存在可重复的谱关系；它们仍不能确定非线性转移的方向。

   .. raw:: html

      </details>


   .. raw:: html

      <details class="k05-note"><summary>解释亮带之前，先改变一下分段长度</summary>

   .. figure:: /_static/K_Diagnostics/k05-experiment-sensitivity.svg
      :alt: 图 10．不同分段长度的比较，对数色标与图 8–9 相同。
      :width: 100%

      图 10．不同分段长度的比较，对数色标与图 8–9 相同。


   固定同一条 C1 原始记录，把 N 从 1024 改为 2048、4096。
   色标与图 8–9 完全相同，没有按各子图的峰值单独缩放。
   低频窄区域的变化很明显；这三个估计的频点带宽和平均次数都不同。
   所以不能把某个亮点、最大数值或第一行正频率格点，当成与分辨能力无关的证据。
   更窄的频点并非必然更准确，因为平均次数减少也会增大随机散布。
   即使短段不重叠，信号具有较长相关时间时，各段仍可能并不独立。

   .. raw:: html

      </details>


   .. rubric:: 7. 怎样接到增长率和转移率

   上面的功率谱已经对应 |brown-zh| 图 2(b) 所分析的那类观测量，
   这里明确采用电压 PSD 单位。要进一步得到增长曲线和非线性转移结果，
   接下来需要实际建立 :ref:`双探针联合模型 <k05-inference-zh>`：构造交叉双谱和完整四阶矩阵，
   求线性、二次系数，再用另一组记录检验预测误差。
   :ref:`下一页面 <k05-validation-zh>` 用三组估计、另一组检验，比较仅线性与联合模型的预测，
   并检查残差、矩阵条件及分析设置的敏感性。Kim 额外的平稳约束属于另一项推断选择。

   对本实验有两个关键转换。首先，离子电流的电压信号需要经过有依据的电流—密度—电势响应，
   才能写成电势或等离子体能量。其次，空间系数需要带方向的间距和相应群速度，
   才能换算成随时间的增长率或转移率。3.7 mm 间距本身并不能提供速度或唯一的空间相位分支。
   C3 的 RMS 较大、或者双相干不为零，都不能替代这些步骤。

   .. raw:: html

      <details class="k05-note"><summary>重算这些图，并查看每一步的来源</summary>

   计算依赖 NumPy、SciPy 和 Matplotlib。在仓库根目录运行：

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py \
        --data /path/to/experiment-data \
        --output /path/to/derived-results

   脚本递归寻找八个指定名称的二进制文件，输出图、``spectral_arrays.npz`` 和
   ``analysis_summary.json``。清单包含原文件哈希、文件头比例、处理参数及明确的未知项。
   重算需要原始 bin 文件，页面没有内嵌这些原始记录。页面展示的是保存后的计算图，
   打开网页不会重新运行 Python。PSD 已与相同窗、去均值方式和零重叠设置的
   SciPy Welch 实现 |scipy-zh| 做数值对照。

   也可把 :download:`分析脚本 <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py>`、
   :download:`二进制读取器 <../../../../K_Diagnostics/K05_bispectral_transfer/siglent_v4.py>` 和
   :download:`采集元数据 <../../../../K_Diagnostics/K05_bispectral_transfer/experiment_z5p5_a3p7.json>`
   下载到同一文件夹运行。
   :download:`本页图的来源清单 <../../_static/K_Diagnostics/k05-experiment-summary.json>`
   记录了本页所用计算结果。

   .. raw:: html

      </details>


   .. rubric:: 参考文献

   .. _k05-data-reference-1-zh:

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**, 115101
   (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   .. _k05-data-reference-2-zh:

   [2] SIGLENT, *How to Extract Data from the Binary File of SIGLENT Oscilloscope*,
   EN03A (2024), V4.0, pp. 38–46.
   `Format specification <https://siglentna.com/wp-content/uploads/dlm_uploads/2024/06/How-to-Extract-Data-from-the-Binary-File.pdf>`_.

   .. _k05-data-reference-3-zh:

   [3] SciPy, ``scipy.signal.welch``.
   `Estimator documentation <https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.welch.html>`_.

   .. _k05-data-reference-4-zh:

   [4] MathWorks, *Cross Spectrum and Magnitude-Squared Coherence*.
   `Phase interpretation and low-coherence masking <https://www.mathworks.com/help/signal/ug/cross-spectrum-and-magnitude-squared-coherence.html>`_.

   .. _k05-data-reference-5-zh:

   [5] T. J. Maccarone, “The biphase explained: understanding the asymmetries in
   coupled Fourier components of astronomical time series,” *Monthly Notices of
   the Royal Astronomical Society* **435**, 3547–3558 (2013), Sections 2–4.
   `doi:10.1093/mnras/stt1546 <https://doi.org/10.1093/mnras/stt1546>`_.


