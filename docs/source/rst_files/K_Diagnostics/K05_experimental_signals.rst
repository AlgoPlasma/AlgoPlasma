06 · From probe records to spectral statistics
================================================================

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

   .. rubric:: Use the measured records to calculate the quantities from pages 03–05

   We now follow four synchronous C1/C3 captures from ion-saturation-current probes.
   The task is concrete: turn two voltage traces into Fourier coefficients, average
   their products, and see what each average reveals. The power spectrum is the first
   connection to Figure 2(b) of Brown and Jorns |brown-en|. The complex statistics
   then supply the coefficient calculation introduced on :ref:`page 05 <k05-inference-en>`.

   Capture 2 is the fixed worked example; captures 3–5 show repeatability at the same
   operating condition. The first segment and the frequency bin nearest 2 MHz are
   chosen in advance, not because their results are unusually clear. All main spectral calculations
   use **the same 2048-sample segments and Fourier normalization**.

   .. rubric:: 1. Start with what the two probes recorded

   .. _k05-experiment-geometry-en:

   C1 is the left fixed probe in the experimental front view; C3 is the right movable
   probe, held at one position for these captures. Their azimuthal separation is
   3.7 mm, and both tips are 5.5 mm downstream of the exit. Each exposed tip has
   diameter 0.5 mm and length 2.5 mm. These positions do not establish a wave's
   propagation direction.

   .. figure:: /_static/K_Diagnostics/k05-response-layout-en.svg
      :alt: Probe geometry. C1/C3 positions redrawn from the experimental layout. Axial distance 5.5 mm; local azimuthal separation 3.7 mm. Not to scale.
      :width: 100%

      Probe geometry. C1/C3 positions redrawn from the experimental layout. Axial distance 5.5 mm; local azimuthal separation 3.7 mm. Not to scale.


   The front view identifies the channels and their local azimuthal separation;
   the top view locates the tips relative to the exit plane. The drawing is not
   to scale. Its downstream arrow marks the axial direction, not azimuthal wave propagation.
   The :ref:`measurement circuits <k05-response-en>` are explained separately.

   Each trace contains 10,000,000 samples at :math:`f_s=100` MS/s: 10 ns between samples,
   0.1 s per capture, and a Nyquist frequency of :math:`f_s/2=50` MHz.
   The :doc:`FFT and Nyquist knowledge page </knowledge/fft>` illustrates this sampling limit.
   Write the record-centred voltage fluctuations as :math:`x_1(t)` and :math:`x_3(t)`.
   Subtracting a mean removes a constant; it does not smooth the fluctuations.

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-records.svg
      :width: 100%
      :alt: Figure 1. The same capture at C1 and C3: full-record voltage fluctuations.

      Figure 1. The same capture at C1 and C3: full-record voltage fluctuations.


   Each shaded strip spans the minimum and maximum of 10,000 consecutive samples;
   its thin line is their mean. This compresses the display without hiding every
   short excursion. The calculations below use every sample, not these display strips.

   The vertical axis is **measured voltage**, not plasma potential. The 1 kΩ resistor
   provides a nominal 0.001 A/V conversion, but does not calibrate the whole measurement
   chain at MHz frequencies. We keep V throughout this calculation so the measured
   quantity and its units remain explicit.

   .. raw:: html

      <details class="k05-note"><summary>Do the four captures have comparable fluctuation levels?</summary>

   Use the other captures to check how representative the example is. The following diagnostic uses 1 ms blocks for slow changes only; the spectral calculations still use N=2048. For channel j and block r, compute the local mean μ and fluctuation RMS σ:

   .. k05:equation:: experiment-block-statistics
      :lang: en

      \mu_{j,r}=\frac{1}{M}\sum_{n=0}^{M-1}x_{j,r}[n],\qquad \sigma_{j,r}=\sqrt{\frac{1}{M}\sum_{n=0}^{M-1}\bigl(x_{j,r}[n]-\mu_{j,r}\bigr)^2}.

   Here M=100,000 is the block length, distinct from the spectral segment length N.

   .. figure:: /_static/K_Diagnostics/k05-experiment-stability.svg
      :width: 100%
      :alt: Supplement A. Local means and fluctuation RMS of four captures.

      Supplement A. Local means and RMS, using 1 ms blocks.

   C1 has whole-record RMS 0.626–0.629 V; C3 has 0.756–0.758 V. Each channel is repeatable across captures, but C3's voltage fluctuations are about 20% larger. A gain or collection-response difference can change RMS without physical wave growth. Local fluctuation differences and noise can also contribute; mean subtraction does not remove these effects. Time stability at one location and Kim's equal modelled powers at two locations are separate assumptions.

   .. raw:: html

      </details>


   .. rubric:: 2. Turn one short waveform into complex coefficients

   Split the two channels at identical sample indices. Each segment has :math:`N=2048`
   samples and lasts 20.48 µs. Each capture supplies :math:`R=4882` complete pairs;
   the last 1664 samples, 16.64 µs, are omitted. Captures are processed separately.
   Here :math:`r=1,\ldots,R` labels a segment and :math:`n=0,\ldots,N-1` labels a sample
   inside it. Neither label is a frequency. The channel index is :math:`j=1,3`;
   the time within a segment is :math:`t_n=n/f_s`.

   Subtract each segment's own mean. Then multiply both channels by the same periodic
   Hann window :math:`w_n=\tfrac12[1-\cos(2\pi n/N)]`.
   It tapers the ends, reducing leakage caused by treating a finite segment as periodic.
   See the :ref:`spectral leakage and windows example <knowledge-leakage-en-record>`
   for repeated waveforms and their spectra.
   It also changes amplitudes and spreads narrow spectral features; the power-density
   normalization below accounts for its mean-square gain.

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-window.svg
      :width: 100%
      :alt: Figure 2. The first paired segment before and after the periodic Hann window.

      Figure 2. The first paired segment before and after the periodic Hann window.


   The dashed curve is the dimensionless window, read on the right axis. The coloured
   curves are the voltages before and after multiplication. The lower curves are the
   actual inputs to the transform. Applying :k05:eq:`time-fourier-series` to these inputs gives

   .. k05:equation:: experiment-windowed-coefficients
      :lang: en

      X_k^{(r)}=\frac{1}{N}\sum_{n=0}^{N-1}w_n\bigl(x_{1,r}[n]-\overline{x_{1,r}}\bigr)e^{+i2\pi kn/N},\qquad f_k=\frac{k f_s}{N}.


   :math:`k` selects a frequency bin, :math:`f_k=kf_s/N`, with spacing
   :math:`\Delta f=f_s/N=48.828125` kHz. :math:`X_k^{(r)}` belongs to C1; applying the same
   operation to C3 gives :math:`Y_k^{(r)}`. Both are complex and have units V.
   Their phase is measured relative to that segment's time origin.

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-coefficients.svg
      :width: 100%
      :alt: Figure 3. From a waveform to complex coefficients: vary frequency or vary segment.

      Figure 3. From a waveform to complex coefficients: vary frequency or vary segment.


   The left panel holds the segment fixed and covers 0–50 MHz, including the Nyquist
   endpoint. Its amplitude axis is logarithmic, so smaller high-frequency coefficients
   remain visible; the plotted quantity is still the modulus, not power or PSD.
   The right panel holds
   :math:`f_\ast=2.001953125` MHz fixed and shows the first 80 segments in the complex
   plane. Each point's distance from zero is its modulus; its angle is its phase.
   Squares identify the first segment. At this bin its values are approximately
   :math:`X^{(1)}=(-0.06217+4.03141i)` mV and :math:`Y^{(1)}=(1.41417+3.43763i)` mV.
   We now have numerical values for the :math:`X,Y` used on the previous pages.
   These are windowed coefficients; their moduli are not the uncorrected peak amplitudes
   of individual plasma waves.

   .. raw:: html

      <details class="k05-note"><summary>The Fourier formula in Python</summary>

   For real inputs, conjugating NumPy's negative-exponent transform gives our positive-exponent convention. Division by N sets the normalization. Columns are frequency bins and rows are segments; Y is obtained identically from C3.

   .. code-block:: python

      blocks = voltage[:R*N].reshape(R, N)
      centered = blocks - blocks.mean(axis=1, keepdims=True)
      w = scipy.signal.windows.hann(N, sym=False)
      X = np.fft.rfft(centered * w, axis=1).conj() / N
      f = np.fft.rfftfreq(N, d=1/fs)

   The first 5 MHz contains bins 0–102; the complete array extends to 50 MHz. No zero-padding or resampling is used. The bin spacing is not the full width of a Hann-broadened peak. See :doc:`segmentation and windows <K01_signal_spectra/fun_K01_segment_ffts>`.

   .. raw:: html

      </details>


   .. rubric:: 3. Square each coefficient, then average

   At the same frequency :math:`f_\ast`, first calculate one nonnegative number per
   segment, then average. This is :k05:eq:`record-powers` applied to the real records:

   .. k05:equation:: experiment-running-power
      :lang: en

      p_{X,f}^{(r)}=|X_f^{(r)}|^2,\qquad
      P_X^{[m]}(f)=\frac{1}{m}\sum_{r=1}^{m}p_{X,f}^{(r)},\qquad
      P_X(f)=P_X^{[R]}(f).


   :math:`p_{X,f}^{(r)}` is one segment's squared modulus; :math:`m` is the number of
   segments included so far. The square brackets in :math:`P_X^{[m]}` label this running
   average, not an exponent. At :math:`m=R` it becomes the full :math:`P_X`.
   Replace X by Y for C3. All these quantities have units V².

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-averaging.svg
      :width: 100%
      :alt: Figure 4. Squared coefficients and their running averages at the same fixed frequency.

      Figure 4. Squared coefficients and their running averages at the same fixed frequency.


   The left panel shows why one segment is not the average. On the right, more segments
   are included until the curve reaches the dotted full-record mean. A settling curve
   is a useful visual check, not proof of stationarity or an uncertainty interval.
   At :math:`f_\ast`, :math:`P_X=8.09277\times10^{-5}` V² and
   :math:`P_Y=6.22364\times10^{-5}` V². Repeating this calculation at every bin produces
   the two frequency-bin power spectra.

   To draw a **one-sided power spectral density (PSD)** in V²/Hz, convert those powers:

   .. k05:equation:: experiment-hann-psd
      :lang: en

      w_n=\frac12\left(1-\cos\frac{2\pi n}{N}\right),\quad U=\frac1N\sum_n w_n^2=\frac38,\qquad S_{XX}^{+}(f_k)=\frac{s_k N}{f_s U}\left\langle|X_k|^2\right\rangle_R.


   :math:`U=3/8` is the window's mean-square value. The factor :math:`N/f_s=1/\Delta f`
   converts per-bin power to power density; :math:`s_k=2` combines equal positive and
   negative frequency contributions for real signals. At DC and Nyquist,
   :math:`s_k=1`. The superscript + means one-sided. This normalization is for PSD,
   not for recovering a single sinusoid's peak amplitude.

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-psd.svg
      :width: 100%
      :alt: Figure 5. The resulting one-sided PSD; detail and full band use the same segments.

      Figure 5. The resulting one-sided PSD; detail and full band use the same segments.


   The two panels use the same computed spectrum: 0–5 MHz for detail, 0–50 MHz for the
   full measured band. Capture 2 is emphasized; faint curves show the other three.
   This is the same kind of frequency-distribution plot as Figure 2(b) in |brown-en|,
   with our voltage units stated explicitly. It is not a comparison of identically
   calibrated plasma energies. A spectral peak alone does not identify an EDI mode.

   .. raw:: html

      <details class="k05-note"><summary>Calculate the powers and their PSD normalization</summary>

   .. code-block:: python

      PX = np.mean(np.abs(X)**2, axis=0)
      PY = np.mean(np.abs(Y)**2, axis=0)
      U = np.mean(w**2)
      s = np.full(X.shape[1], 2.0)
      s[[0, -1]] = 1.0  # N is even: DC and Nyquist are not doubled.
      SXX = s * N / (fs * U) * PX
      SYY = s * N / (fs * U) * PY

   The powers are windowed frequency-bin moments; the additional factor produces PSD. The script checks both channels against SciPy Welch |scipy-en| with identical settings, and checks the window-weighted Parseval sum. Integrating this PSD does not exactly undo the window sample by sample. See :doc:`window normalization <K01_signal_spectra/fun_K01_power_spectrum>`.

   .. raw:: html

      </details>


   .. rubric:: 4. Multiply the two channels to retain their relative phase

   The powers above do not tell us how the two signals relate. Following
   :k05:eq:`probe-cross-power`, multiply C3 by the conjugate of C1 **within the same
   segment**, then average. Use that complex average to compute coherence and phase:

   .. k05:equation:: experiment-coherence-phase
      :lang: en

      C_{13}^2(f)=\frac{|G(f)|^2}{P_X(f)P_Y(f)},\qquad G(f)=\langle Y_fX_f^*\rangle_R,\qquad \delta(f)=\arg G(f).


   :math:`G` has units V²; :math:`C_{13}^2` is dimensionless and :math:`\delta` is in
   radians. At our fixed bin, :math:`G=(6.68455-2.32260i)\times10^{-5}` V²,
   :math:`C_{13}^2=0.99427`, and :math:`\delta=-0.33441` rad.
   The high coherence describes a reproducible linear relationship at this frequency;
   it does not by itself establish propagation or growth. See also the
   :doc:`K01 coherence calculation <K01_signal_spectra/fun_K01_coherence>`.

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-cross.svg
      :width: 100%
      :alt: Figure 6. Coherence and relative phase computed from the same cross spectrum.

      Figure 6. Coherence and relative phase computed from the same cross spectrum.


   All four captures have median coherence about 0.986 in 0.5–5 MHz. In 25–50 MHz the
   medians are only 0.00032–0.00061 with these settings. The phase panels display only
   bins with coherence at least 0.5; blank areas were calculated but hidden. This is
   a display rule, not a significance threshold or a plasma cutoff frequency.
   A phase sign is not an energy-transfer sign, and a wrapped angle alone does not
   uniquely determine which probe saw a propagating wave first.

   .. raw:: html

      <details class="k05-note"><summary>Calculate G, coherence and the phase display</summary>

   .. code-block:: python

      G = np.mean(Y * X.conj(), axis=0)
      den = PX * PY
      coherence = np.divide(abs(G)**2, den,
                            out=np.full_like(den, np.nan), where=den > 0)
      phase = np.angle(G)
      phase_for_plot = np.where(coherence >= 0.5, phase, np.nan)

   X and Y must have the same segment rows. Zero power makes coherence undefined; NaN is not zero. A zero cross spectrum has no defined phase.

   .. raw:: html

      </details>


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
   signal relative to added noise. Thus neither the RMS difference in Supplement A
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
   propagation direction; the pure-delay example is not a fit to Figure 6.
   The :doc:`K01 angle-wrapping page <K01_signal_spectra/fun_K01_wrap_to_pi>`
   explains how angles are mapped to one period.

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
   cutoff or a confidence test; the last visible point is therefore
   not a measured plasma cutoff frequency.

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>When can the measured phase be interpreted as propagation?</summary>

   .. k05:equation:: experiment-measurement-phase
      :lang: en

      X_f=H_1(f)I_{1,f},\quad Y_f=H_3(f)I_{3,f},\qquad \delta_V=\delta_I+\arg H_3-\arg H_1\pmod{2\pi}.

   :math:`I` is the probe-current Fourier coefficient in A; :math:`H` is the complex current-to-voltage response in V/A. The measured phase :math:`\delta_V` includes the relative phase of the two responses as well as the current phase :math:`\delta_I`, modulo :math:`2\pi`. Channel delay, the propagation direction and a consistent spatial phase branch must therefore be checked before inferring a wavenumber. Neither spacing alone nor a small phase supplies group velocity.

   .. raw:: html

      </details>


   .. rubric:: 5. Keep the complex bispectrum before normalizing it

   We now compare three components of C1, using :k05:eq:`auto-bispectrum`.
   For each pair of bins :math:`k_1,k_2`, multiply
   :math:`X_{k_1}^{(r)}X_{k_2}^{(r)}(X_{k_1+k_2}^{(r)})^*` in each segment and average.
   The result :math:`B_X(f_1,f_2)` is complex, in V³. It has both a real and an imaginary
   part; keeping only its magnitude would discard information needed later.

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-bispectrum.svg
      :width: 100%
      :alt: Figure 7. Real and imaginary parts of the C1 complex bispectrum, capture 2.

      Figure 7. Real and imaginary parts of the C1 complex bispectrum, capture 2.


   Both panels use the same frequency coordinates and the same colour scale. The third
   frequency is always :math:`f_3=f_1+f_2`. We display :math:`0<f_1\le f_2` and
   :math:`f_1+f_2\le5` MHz; swapping the inputs gives the same product. Grey is outside
   the computed domain, whereas white inside it is near zero. The signed colour scale
   is linear for component magnitudes below :math:`10^{-9}` V³ and logarithmic farther away; this display choice is not a significance threshold. Read the colourbar values in V³.
   The red/blue signs are those of the complex moment's components, **not transfer directions**.

   Next use :k05:eq:`bicoherence` to normalize :math:`|B_X|^2` by the pair and target
   powers. This yields the dimensionless squared bicoherence :math:`b^2`:

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-bicoherence.svg
      :width: 100%
      :alt: Figure 8. C1 squared bicoherence across the four captures, with one logarithmic scale.

      Figure 8. C1 squared bicoherence across the four captures, with one logarithmic scale.


   A bright cell indicates a larger normalized relation between
   :math:`X(f_1)X(f_2)` and :math:`X(f_1+f_2)`. The combination of phases tends to survive
   averaging more strongly, with amplitudes also affecting the result. Brightness is
   neither wave energy nor the fraction of energy being transferred. A repeated
   non-sinusoidal waveform or measurement nonlinearity can also create this structure.

   The brighter strip near the bottom involves a small :math:`f_1` and two nearby
   higher frequencies, :math:`f_2` and :math:`f_2+f_1`. It is a family of related
   frequency triples, potentially consistent with modulation, not a determined
   direction of energy flow. Values use logarithmic colours from :math:`10^{-4}` to 1;
   the floor is a display choice, not a detection threshold. White is outside this
   map's computed domain. The first few bins are especially sensitive to windowing
   and frequency resolution.

   The two figures answer different questions: :math:`b^2` shows normalized association,
   while complex :math:`B_X` retains the magnitude and phase needed in
   :k05:eq:`spectral-power-balance`. The latter combines B with a coupling coefficient
   before taking a real part. Neither :math:`\operatorname{Re}B_X` alone nor a bright
   double-frequency band is already a transfer rate.

   .. raw:: html

      <details class="k05-note"><summary>The same products give B and squared bicoherence</summary>

   Here a and b are positive integer bin indices, not frequency values in MHz; a+b selects the target bin. The code operates on all rows, using the same X as the preceding calculations.

   .. code-block:: python

      pair = X[:, a] * X[:, b]
      target = X[:, a+b]
      B = np.mean(pair * target.conj())
      den = np.mean(abs(pair)**2) * np.mean(abs(target)**2)
      b2 = abs(B)**2 / den if den > 0 else np.nan

   The plotting loop repeats this calculation over the displayed pairs. It retains the complex B and the unmodified b² arrays; the colour floor affects only display.

   .. raw:: html

      </details>


   .. raw:: html

      <details class="k05-note"><summary>Check repeatability and frequency resolution without selecting a brighter result</summary>

   The four maps use the same colour limits. Their similarity is repeatability, not proof of an independent three-wave mechanism or statistical significance. The script also saves the C3 complex bispectra and bicoherence. For a resolution check, the preserved comparison below changes only segment length at C1.

   .. figure:: /_static/K_Diagnostics/k05-experiment-sensitivity.svg
      :width: 100%
      :alt: Supplement B. C1 bicoherence for 1024, 2048 and 4096 sample segments.

      Supplement B. Segment-length sensitivity; the middle panel uses the main setting.

   Shorter segments give more averages but wider frequency bins. Longer segments do the opposite. The low-frequency strip changes noticeably: it must not be treated as independent of resolution. Even nonoverlapping segments may be statistically dependent. These alternative settings do not replace the main calculation.

   .. raw:: html

      </details>


   .. rubric:: 6. What now goes into the coefficient calculation?

   The same :math:`X,Y` arrays provide the :math:`P,G,\mathbf b,\mathbf d,\mathbf F`
   in :k05:eq:`inference-matrix`. For a pair product :math:`Z_j` as defined on page 05,
   the required averages are :math:`b_j=\langle X_fZ_j^*\rangle`,
   :math:`d_j=\langle Y_fZ_j^*\rangle`, and :math:`F_{ij}=\langle Z_i^*Z_j\rangle`.
   For the auto-bispectrum just plotted, :math:`b_j=B_X(f_1,f_2)^*`.
   The conjugation matters. These averages use complex coefficients; a bicoherence
   image cannot replace them.

   The positive sum-frequency triangle is a readable display, not the complete
   quadratic input basis. The coefficient calculation also accounts for the retained
   difference-frequency pairs using negative-frequency conjugates. With the moments
   in hand, the next step is to solve for L and Q and test the resulting model, as in
   the :ref:`following page <k05-experiment-coefficients-en>`. Growth and signed transfer require
   those coefficients and the propagation/measurement inputs discussed on page 05.

   .. raw:: html

      <details class="k05-note"><summary>Reading the data and reproducing the complete calculation</summary>

   The binary reader removes the whole-record mean before applying the header voltage scale:

   .. k05:equation:: experiment-code-fluctuation
      :lang: en

      x_j[n]=g_j\bigl(c_j[n]-\overline{c_j}\bigr),\qquad g_j=\frac{2\ \mathrm{V/div}}{7680\ \mathrm{codes/div}}.

   c_j[n] is the stored integer, its bar is the record mean, and g_j is volts per code. The 16-bit storage format is distinct from the ADC resolution. The lab reader and manufacturer example use opposite DC-offset signs; that constant disappears after centring. Neither convention is used here to claim calibrated absolute current. The 1 kΩ scale is nominal, while relative gain, delay and frequency response still need calibration.

   Run from the repository root, choosing a new output directory:

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_spectral_walkthrough.py \
        --data /path/to/experiment-data \
        --output /path/to/new-walkthrough-results

   The reader finds the four synchronous pairs recursively. The script writes eight SVG/PNG figures, walkthrough_arrays.npz and walkthrough_summary.json. The arrays include all plotted moments and capture 2 complex X/Y coefficients through 5 MHz. The summary records settings, software, source and raw-file hashes, numerical checks and the fixed example. Raw input files and earlier analysis outputs remain separate; opening this page does not execute Python.

   The main PSD, coherence and bispectrum all use N=2048. Earlier N=16384 overview spectra remain reproducible with analyze_experiment.py; they must not be substituted for these moments without acknowledging the changed resolution. Later published comparison panels may use that finer overview spectrum; their own provenance determines the settings.

   Download :download:`the walkthrough script <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_spectral_walkthrough.py>`, :download:`shared spectral helpers <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py>`, :download:`the reader <../../../../K_Diagnostics/K05_bispectral_transfer/siglent_v4.py>` and :download:`metadata <../../../../K_Diagnostics/K05_bispectral_transfer/experiment_z5p5_a3p7.json>` into one directory. The :download:`figure provenance <../../_static/K_Diagnostics/k05-walkthrough-summary.json>` identifies the displayed run.

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

   .. rubric:: 用探针记录，实际算出第 03–05 页中的量

   现在用两支离子饱和电流探针（ion-saturation-current probes）的四组同步 C1/C3 记录，
   把前面的公式逐步变成结果：从两条电压波形得到 Fourier 系数，再对系数的乘积取平均，
   看每个平均量究竟保留了什么。功率谱首先连接 Brown 与 Jorns |brown-zh| 的图 2(b)，
   复数统计量则为 :ref:`第 05 页 <k05-inference-zh>` 的系数求解提供输入。

   固定第 2 组为贯穿本页的示例，第 3–5 组用于比较同一工况下的重复性。
   示例的第一个短段和最接近 2 MHz 的频点预先固定，不按结果是否清楚来挑选。
   主线谱统计统一使用 **同一套 2048 点分段和 Fourier 归一化**。

   .. rubric:: 1. 先看两支探针实际记录了什么

   .. _k05-experiment-geometry-zh:

   在实验正视图中，C1 是左侧固定探针，C3 是右侧移动探针；本批记录采集期间，C3 固定在同一位置。
   两者周向相距 3.7 mm，两支尖端都位于出口下游 5.5 mm；每支暴露尖端的直径为 0.5 mm、长度为 2.5 mm。
   这个位置关系本身不能确定波的传播方向。

   .. figure:: /_static/K_Diagnostics/k05-response-layout-zh.svg
      :alt: 探针几何示意图．根据实验布置重绘的 C1/C3 位置：轴向距出口 5.5 mm，局部周向间距 3.7 mm。示意图不按比例。
      :width: 100%

      探针几何示意图．根据实验布置重绘的 C1/C3 位置：轴向距出口 5.5 mm，局部周向间距 3.7 mm。示意图不按比例。


   正视图用于认清通道和局部周向间距，俯视图用于认清尖端相对出口平面的位置。
   示意图不按比例；“下游”箭头表示轴向参考方向，不表示波的周向传播方向。
   :ref:`测量电路 <k05-response-zh>` 另有说明。

   每路每组有 10,000,000 个点，采样率 :math:`f_s=100` MS/s：相邻点间隔 10 ns，
   记录总长 0.1 s，奈奎斯特频率（Nyquist frequency）为 :math:`f_s/2=50` MHz。
   :doc:`FFT 与奈奎斯特频率知识页 </knowledge/fft>` 给出了这个采样边界的图解。
   把相对整段均值的电压波动记为 :math:`x_1(t)` 和 :math:`x_3(t)`。
   减去均值只去掉一个常数，不会把快速起伏平滑掉。

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-records.svg
      :width: 100%
      :alt: 图 1．同一次同步采集在 C1、C3 两处的整段电压波动。

      图 1．同一次同步采集在 C1、C3 两处的整段电压波动。


   每条半透明带保留连续 10,000 点中的最小值和最大值，细线表示这些点的均值。
   这样可以压缩显示，同时保留短暂尖峰的范围。后面的计算使用全部采样点，不使用范围带代替原波形。

   纵轴是 **实测电压**，不能直接叫作等离子体电势。1 kΩ 电阻提供标称 0.001 A/V 换算，
   但这还不是整条测量链路在 MHz 频率下的标定。本页保持电压单位，避免在开始计算时就混淆测量量。

   .. raw:: html

      <details class="k05-note"><summary>四组记录的波动水平是否接近？</summary>

   用其他记录检查主例是否具有代表性。下方用 1 ms 小段观察慢变化；它只是波形检查，频谱计算仍使用 N=2048。对通道 j 的第 r 个检查区间，计算局部均值 μ 与波动均方根（RMS）σ：

   .. k05:equation:: experiment-block-statistics
      :lang: zh

      \mu_{j,r}=\frac{1}{M}\sum_{n=0}^{M-1}x_{j,r}[n],\qquad \sigma_{j,r}=\sqrt{\frac{1}{M}\sum_{n=0}^{M-1}\bigl(x_{j,r}[n]-\mu_{j,r}\bigr)^2}.

   这里 M=100,000 是检查区间长度，与频谱短段长度 N 不同。

   .. figure:: /_static/K_Diagnostics/k05-experiment-stability.svg
      :width: 100%
      :alt: 补充图 A．四组记录在 1 ms 区间上的局部均值与波动 RMS。

      补充图 A．四组记录在 1 ms 区间上的局部均值与波动 RMS。

   C1 的整组 RMS 为 0.626–0.629 V，C3 为 0.756–0.758 V。各通道在四次采集中较可重复，但 C3 的电压波动约大 20%。探针收集响应或通道增益不同，就可能改变 RMS，并不要求波真的增长；局部波动差异与噪声也可能参与。减均值不会消除这些幅度差。同一点的时间稳定性与 Kim 所用的两处共同模型功率，是两项不同的假设。

   .. raw:: html

      </details>


   .. rubric:: 2. 把一小段波形变成复系数

   两路从相同采样点开始切段。每段 :math:`N=2048` 点，长 20.48 μs；
   每组得到 :math:`R=4882` 对完整短段，末尾不足一段的 1664 点、即 16.64 μs，舍去。
   四组分别处理，不把不同次采集拼成一条连续波形。
   :math:`r=1,\ldots,R` 是短段编号，:math:`n=0,\ldots,N-1` 是段内采样点编号，都不是频率。通道编号为 :math:`j=1,3`，段内时刻为 :math:`t_n=n/f_s`。

   先减去每个短段自己的均值，再给两路乘上同一个周期 Hann 窗（periodic Hann window）：
   :math:`w_n=\tfrac12[1-\cos(2\pi n/N)]`。
   它把两端逐渐压低，减轻把有限短段作周期延拓时产生的谱泄漏（spectral leakage）。
   :ref:`“谱泄漏与窗函数”知识页 <knowledge-leakage-zh-record>` 用周期拼接图和频谱比较图解释了这一点。
   加窗也会改变幅度、展宽窄谱结构；后面算功率谱密度时，要考虑窗的均方归一化。

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-window.svg
      :width: 100%
      :alt: 图 2．第一对短段乘周期 Hann 窗前后的波形。

      图 2．第一对短段乘周期 Hann 窗前后的波形。


   虚线是无量纲的窗函数，读右轴；彩色曲线是乘窗前后的电压，读左轴。
   下图的曲线才是实际送入 Fourier 变换的信号。对它使用 :k05:eq:`time-fourier-series` 的约定，得到

   .. k05:equation:: experiment-windowed-coefficients
      :lang: zh

      X_k^{(r)}=\frac{1}{N}\sum_{n=0}^{N-1}w_n\bigl(x_{1,r}[n]-\overline{x_{1,r}}\bigr)e^{+i2\pi kn/N},\qquad f_k=\frac{k f_s}{N}.


   :math:`k` 是频点编号，对应 :math:`f_k=kf_s/N`，相邻频点间隔
   :math:`\Delta f=f_s/N=48.828125` kHz。
   :math:`X_k^{(r)}` 来自 C1；对 C3 作同样计算得到 :math:`Y_k^{(r)}`。
   两者都是单位为 V 的复数，相位以各自短段的起点为时间参考。

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-coefficients.svg
      :width: 100%
      :alt: 图 3．从波形得到复系数：固定短段看频率，或固定频率看不同短段。

      图 3．从波形得到复系数：固定短段看频率，或固定频率看不同短段。


   左图固定一个短段，覆盖 0–50 MHz，包含奈奎斯特频点。纵轴采用对数刻度，
   便于看清较小的高频系数；画的仍是系数的模，不是功率或 PSD。右图固定 :math:`f_\ast=2.001953125` MHz，
   把前 80 段的系数画在复平面上：点离原点的距离是模，方向角是相位。
   方块标出第一个短段，此时约为
   :math:`X^{(1)}=(-0.06217+4.03141i)` mV、:math:`Y^{(1)}=(1.41417+3.43763i)` mV。
   前面公式里的 X 和 Y，现在有了实际数值。
   这是加窗后的系数，其模不能直接当作一列等离子体波未经修正的峰值幅度。

   .. raw:: html

      <details class="k05-note"><summary>Fourier 公式对应的 Python 代码</summary>

   对实输入，NumPy 负指数变换的结果取共轭，就是这里的正指数约定；除以 N 设置归一化。数组每一行是一段，每一列是一个频点，C3 的 Y 按完全相同的方法得到。

   .. code-block:: python

      blocks = voltage[:R*N].reshape(R, N)
      centered = blocks - blocks.mean(axis=1, keepdims=True)
      w = scipy.signal.windows.hann(N, sym=False)
      X = np.fft.rfft(centered * w, axis=1).conj() / N
      f = np.fft.rfftfreq(N, d=1/fs)

   前 5 MHz 对应编号 0–102，完整数组一直到 50 MHz。没有补零或重采样。频点间隔不等于 Hann 窗展宽后谱峰的完整宽度。参见 :doc:`分段与窗函数 <K01_signal_spectra/fun_K01_segment_ffts>`。

   .. raw:: html

      </details>


   .. rubric:: 3. 每段先取模平方，再把许多段平均

   继续固定同一个 :math:`f_\ast`。每段先算一个非负的模平方，再平均；
   这就是把 :k05:eq:`record-powers` 用在真实记录上：

   .. k05:equation:: experiment-running-power
      :lang: zh

      p_{X,f}^{(r)}=|X_f^{(r)}|^2,\qquad
      P_X^{[m]}(f)=\frac{1}{m}\sum_{r=1}^{m}p_{X,f}^{(r)},\qquad
      P_X(f)=P_X^{[R]}(f).


   :math:`p_{X,f}^{(r)}` 是第 r 段的模平方；:math:`m` 表示目前已经纳入平均的段数。
   :math:`P_X^{[m]}` 的方括号上标是这个累计平均的标记，不是乘方。
   当 :math:`m=R` 时，就得到完整的 :math:`P_X`。把 X 换成 Y 可得 C3 的结果，单位都是 V²。

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-averaging.svg
      :width: 100%
      :alt: 图 4．同一个固定频点的逐段模平方，以及逐渐纳入更多短段的平均。

      图 4．同一个固定频点的逐段模平方，以及逐渐纳入更多短段的平均。


   左图显示单段的值会起伏；右图逐渐纳入更多短段，最后到达虚线所示的整组均值。
   曲线趋于稳定是一个直观检查，不等于已经证明平稳性，也不是误差条。
   在 :math:`f_\ast` 处，:math:`P_X=8.09277\times10^{-5}` V²、
   :math:`P_Y=6.22364\times10^{-5}` V²。对每个频点都重复这一步，就得到两路频点功率谱。

   要画单位为 V²/Hz 的 **单边功率谱密度（one-sided PSD）**，再作一次换算：

   .. k05:equation:: experiment-hann-psd
      :lang: zh

      w_n=\frac12\left(1-\cos\frac{2\pi n}{N}\right),\quad U=\frac1N\sum_n w_n^2=\frac38,\qquad S_{XX}^{+}(f_k)=\frac{s_k N}{f_s U}\left\langle|X_k|^2\right\rangle_R.


   :math:`U=3/8` 是窗函数的均方值。:math:`N/f_s=1/\Delta f` 把每个频点的功率换成每 Hz 的密度；
   实信号在正、负频率上有相等的功率，内部正频点取 :math:`s_k=2`，把两边合在一边。
   零频率和奈奎斯特频点不再加倍，取 :math:`s_k=1`。上标 + 表示单边。
   这套校正针对 PSD，与恢复单一正弦波的峰值幅度不同。

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-psd.svg
      :width: 100%
      :alt: 图 5．从频点功率换算得到单边 PSD，局部与全频段使用相同分段。

      图 5．从频点功率换算得到单边 PSD，局部与全频段使用相同分段。


   两幅图使用同一次计算：左边放大 0–5 MHz，右边保留 0–50 MHz 全频段。
   第 2 组用实色强调，另外三组用浅色比较重复性。
   这已对应 |brown-zh| 图 2(b) 所分析的频率分布，但这里明确使用本实验的电压单位，
   不是两次实验经过相同标定的等离子体能量对比。谱峰的位置本身也不能确认 EDI 模式。

   .. raw:: html

      <details class="k05-note"><summary>用代码计算功率，再换成 PSD</summary>

   .. code-block:: python

      PX = np.mean(np.abs(X)**2, axis=0)
      PY = np.mean(np.abs(Y)**2, axis=0)
      U = np.mean(w**2)
      s = np.full(X.shape[1], 2.0)
      s[[0, -1]] = 1.0  # N is even: DC and Nyquist are not doubled.
      SXX = s * N / (fs * U) * PX
      SYY = s * N / (fs * U) * PY

   PX、PY 是加窗后的频点功率；后面的因子把它们换成 PSD。脚本与同设置的 SciPy Welch |scipy-zh| 核对两路结果，并检查窗加权的 Parseval 求和。PSD 积分并不是逐点撤销加窗。参见 :doc:`窗函数归一化 <K01_signal_spectra/fun_K01_power_spectrum>`。

   .. raw:: html

      </details>


   .. rubric:: 4. 把两路系数相乘，保留相对相位

   上面的功率没有说明两路之间的关系。按照 :k05:eq:`probe-cross-power`，
   在 **同一个短段内** 把 C3 系数乘以 C1 系数的共轭，再平均。
   保留这个复数平均量，然后计算相干度和相位：

   .. k05:equation:: experiment-coherence-phase
      :lang: zh

      C_{13}^2(f)=\frac{|G(f)|^2}{P_X(f)P_Y(f)},\qquad G(f)=\langle Y_fX_f^*\rangle_R,\qquad \delta(f)=\arg G(f).


   :math:`G` 的单位是 V²，:math:`C_{13}^2` 无量纲，:math:`\delta` 的单位是 rad。
   在固定示例频点，:math:`G=(6.68455-2.32260i)\times10^{-5}` V²，
   :math:`C_{13}^2=0.99427`，:math:`\delta=-0.33441` rad。
   较大的相干度说明这个频率上的线性关系可重复，但它本身不能确认传播或增长。
   :doc:`K01 相干度计算 <K01_signal_spectra/fun_K01_coherence>` 也介绍了这一统计量。

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-cross.svg
      :width: 100%
      :alt: 图 6．从同一互谱得到相干度与两路相对相位。

      图 6．从同一互谱得到相干度与两路相对相位。


   在当前设置下，四组在 0.5–5 MHz 内的相干度中位数约为 0.986；
   在 25–50 MHz 内，中位数只有 0.00032–0.00061。
   相位图只显示相干度不低于 0.5 的频点，空白处已经计算，只是隐藏了散乱相位。
   0.5 是显示规则，不是显著性门槛，更不是等离子体截止频率。
   相位正负也不是能量转移正负；仅凭被包裹在一个周期内的角度，不能唯一确定传播波先到哪支探针。

   .. raw:: html

      <details class="k05-note"><summary>计算互谱、相干度和用于显示的相位</summary>

   .. code-block:: python

      G = np.mean(Y * X.conj(), axis=0)
      den = PX * PY
      coherence = np.divide(abs(G)**2, den,
                            out=np.full_like(den, np.nan), where=den > 0)
      phase = np.angle(G)
      phase_for_plot = np.where(coherence >= 0.5, phase, np.nan)

   X、Y 的行必须对应相同短段。功率为零时相干度未定义；NaN 不是零。如果互谱为零，相位也没有数学定义。

   .. raw:: html

      </details>


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
   所以，补充图 A 的 RMS 差异或接近奈奎斯特频率本身，都不能单独解释这个下降。
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
   解释传播方向前需要确定相位分支和通道响应；这个纯延迟例子并不是对图 6 的拟合。

   高频留白是另一个原因：绘图时隐藏了低相干点。
   下面代码中，``G`` 和 ``coherence`` 分别是 :k05:eq:`experiment-coherence-phase`
   定义的互谱与平方相干度数组：

   .. code-block:: python

      phase = np.angle(G)  # 每个频点都计算相位，单位为弧度。
      phase_for_plot = np.where(coherence >= 0.5, phase, np.nan)

   角度映射到一个周期的计算可参见 :doc:`K01 相位包裹 <K01_signal_spectra/fun_K01_wrap_to_pi>`。

   ``np.nan`` 让图中该处留白，不代表相位为零、功率为零或没有计算。
   当归一化后的互谱箭头很短时，小的统计变化就可能让它的方向明显改变。
   若互谱恰好为零，相位在数学上没有定义，不能把软件返回的数值当作物理相位。
   这里的 0.5 只是显示规则，不是物理截止或置信度检验；
   最后一个可见点也不能解释成测得了等离子体的截止频率。

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>什么时候可以把测得相位解释为传播？</summary>

   .. k05:equation:: experiment-measurement-phase
      :lang: zh

      X_f=H_1(f)I_{1,f},\quad Y_f=H_3(f)I_{3,f},\qquad \delta_V=\delta_I+\arg H_3-\arg H_1\pmod{2\pi}.

   :math:`I` 是单位为 A 的探针电流 Fourier 系数，:math:`H` 是单位为 V/A 的复数电流—电压响应。测得相位 :math:`\delta_V` 同时包含电流相位 :math:`\delta_I` 和两路响应的相位差，且只在模 :math:`2\pi` 意义下确定。因此需要检查通道延迟、传播方向和空间相位分支，才能进一步解释波数；间距本身或一个很小的相位，都不能提供群速度。

   .. raw:: html

      </details>


   .. rubric:: 5. 先保留复双谱，再看归一化的亮带

   现在用 :k05:eq:`auto-bispectrum` 比较 C1 中的三个频率成分。
   对每对频点 :math:`k_1,k_2`，在每段里计算
   :math:`X_{k_1}^{(r)}X_{k_2}^{(r)}(X_{k_1+k_2}^{(r)})^*`，然后平均。
   得到的 :math:`B_X(f_1,f_2)` 是复数，单位 V³；它有实部和虚部，
   如果只存模长，就会丢失后续计算需要的信息。

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-bispectrum.svg
      :width: 100%
      :alt: 图 7．第 2 组 C1 复双谱的实部与虚部。

      图 7．第 2 组 C1 复双谱的实部与虚部。


   两图的频率坐标和色标相同，第三个频率始终是 :math:`f_3=f_1+f_2`。
   这里展示 :math:`0<f_1\le f_2`、:math:`f_1+f_2\le5` MHz 的区域，交换两个输入频率不重复画。
   灰色是未计算域；计算域内接近白色表示接近零。
   色标保留正负，分量的绝对值小于 :math:`10^{-9}` V³ 时线性显示，超过时按对数压缩；这个显示选择不是显著性门槛，读数仍是 V³。
   红蓝表示复统计量分量的正负，**不表示能量转移方向**。

   接下来按 :k05:eq:`bicoherence`，用波对乘积和目标成分的功率归一化 :math:`|B_X|^2`，
   得到无量纲的平方双相干度（squared bicoherence） :math:`b^2`：

   .. figure:: /_static/K_Diagnostics/k05-walkthrough-bicoherence.svg
      :width: 100%
      :alt: 图 8．C1 四组平方双相干图，使用统一对数色标。

      图 8．C1 四组平方双相干图，使用统一对数色标。


   亮点表示 :math:`X(f_1)X(f_2)` 与 :math:`X(f_1+f_2)` 的归一化关系较大。
   相位组合在平均后更容易保留下来，幅度也参与加权；亮度既不是波能量，也不是能量转移的百分比。
   重复的非正弦波形或测量链路的非线性，同样可能产生这类结构。

   靠近底边的亮带涉及较小的 :math:`f_1`，以及两个相近的较高频率 :math:`f_2`、:math:`f_2+f_1`。
   它是一族相关的三频组合，可能与调制（modulation）有关，但还没有给出供能方向。
   图中使用 :math:`10^{-4}` 到 1 的统一对数色标；下限是显示选择，不是检测阈值。
   本图白色表示未计算域。最前几个频点尤其需要留意窗函数和频率分辨能力的影响。

   这两类图各有用途：:math:`b^2` 帮助看归一化关联，复 :math:`B_X` 则保留
   :k05:eq:`spectral-power-balance` 所需的模与相位。那个公式还要把 B 与耦合系数相乘，再取实部。
   所以仅有 :math:`\operatorname{Re}B_X`，或看到一条双相干亮带，都还没有得到转移率。

   .. raw:: html

      <details class="k05-note"><summary>同一组乘积怎样得到 B 和平方双相干</summary>

   这里 a、b 是正整数频点编号，不是以 MHz 表示的频率值；a+b 定位和频频点。代码使用前面同一套 X，在全部短段上相乘、平均。

   .. code-block:: python

      pair = X[:, a] * X[:, b]
      target = X[:, a+b]
      B = np.mean(pair * target.conj())
      den = np.mean(abs(pair)**2) * np.mean(abs(target)**2)
      b2 = abs(B)**2 / den if den > 0 else np.nan

   绘图程序对展示域里的每对频点重复这一步。保存的是完整复 B 和未经色标截断的 b²；显示下限只影响着色。

   .. raw:: html

      </details>


   .. raw:: html

      <details class="k05-note"><summary>比较重复性和分辨率，不按亮度挑选结果</summary>

   四组采用相同色标。相似说明图案可重复，不等于证明三个独立波模相互作用，也不是显著性检验。脚本同时保存 C3 的复双谱和双相干。下图保留已有的分段长度对照，检查同一 C1 记录对设置是否敏感。

   .. figure:: /_static/K_Diagnostics/k05-experiment-sensitivity.svg
      :width: 100%
      :alt: 补充图 B．C1 使用 1024、2048、4096 点分段时的双相干。

      补充图 B．分段长度敏感性；中间一幅使用本页主设置。

   短段提供更多平均，但频点更宽；长段相反。低频窄带的变化较明显，不能把它当成与分辨能力无关的结构。即使分段不重叠，各段也未必统计独立。这些对照不替换主线的计算设置。

   .. raw:: html

      </details>


   .. rubric:: 6. 这些结果怎样交给系数求解？

   现在同一套 X、Y 数组可以提供 :k05:eq:`inference-matrix` 中的
   :math:`P,G,\mathbf b,\mathbf d,\mathbf F`。
   沿用第 05 页的波对乘积 :math:`Z_j`，需要的平均分别是
   :math:`b_j=\langle X_fZ_j^*\rangle`、:math:`d_j=\langle Y_fZ_j^*\rangle`、
   :math:`F_{ij}=\langle Z_i^*Z_j\rangle`。
   对刚才画出的自双谱，有 :math:`b_j=B_X(f_1,f_2)^*`，这里的共轭不能漏掉。
   这些量都来自复系数，不能拿一张双相干强度图替代。

   正频率和频三角形只是便于读图的展示域，不是完整的二次模型输入。
   求系数时还要通过负频率的共轭关系，计入所保留频带内的差频波对。
   有了这些统计量，下一步就能求 L、Q 并检查模型，见 :ref:`后续页面 <k05-experiment-coefficients-zh>`。
   要进一步得到增长和有符号转移，还需这些系数，以及第 05 页已经说明的传播与测量信息。

   .. raw:: html

      <details class="k05-note"><summary>读取数据与复现完整计算</summary>

   读取器先去掉整段平均码值，再使用文件头中的电压比例：

   .. k05:equation:: experiment-code-fluctuation
      :lang: zh

      x_j[n]=g_j\bigl(c_j[n]-\overline{c_j}\bigr),\qquad g_j=\frac{2\ \mathrm{V/div}}{7680\ \mathrm{codes/div}}.

   c_j[n] 是存储整数，横线表示整段平均，g_j 是每码对应的电压。16 位存储格式与 ADC 的分辨率不是同一个概念。实验读取脚本和厂商示例对直流偏置使用相反符号；两者仅相差常数，去均值后消失。因此这里不选其中一个符号来声称得到了标定的直流电流。1 kΩ 仅提供标称比例，相对增益、延迟及频率响应仍需标定。

   在仓库根目录运行，输出选择一个新目录：

   .. code-block:: bash

      python K_Diagnostics/K05_bispectral_transfer/analyze_spectral_walkthrough.py \
        --data /path/to/experiment-data \
        --output /path/to/new-walkthrough-results

   读取器递归寻找四对同步文件。程序输出八张 SVG/PNG、walkthrough_arrays.npz 和 walkthrough_summary.json。数组包含绘图统计量，以及第 2 组到 5 MHz 的逐段复 X/Y。清单记录设置、软件、源码与原始文件哈希、数值检查及固定示例。原始输入和早期分析输出分开保存；打开网页不会执行 Python。

   本页主线 PSD、相干度和双谱均使用 N=2048。早期 N=16384 的频谱概览仍可用 analyze_experiment.py 重现；不能忽略分辨率差别，将其直接替换成本页的矩。后面的既有论文对照图可能使用该细网格概览，具体设置以各图来源为准。

   可将 :download:`本页计算脚本 <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_spectral_walkthrough.py>`、:download:`共享谱计算函数 <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py>`、:download:`读取器 <../../../../K_Diagnostics/K05_bispectral_transfer/siglent_v4.py>` 和 :download:`元数据 <../../../../K_Diagnostics/K05_bispectral_transfer/experiment_z5p5_a3p7.json>` 放在同一目录运行。:download:`绘图来源清单 <../../_static/K_Diagnostics/k05-walkthrough-summary.json>` 标识了本页展示的计算。

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

