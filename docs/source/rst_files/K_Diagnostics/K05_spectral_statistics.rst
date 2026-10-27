04 · From records to spectral statistics
========================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <script defer src="../../_static/K_Diagnostics/k05-phase-statistics.js"></script>
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. |ref-en| raw:: html

   <a class="k05-cite" href="#k05-statistics-reference-1-en" aria-label="Reference 1">[1]</a>

.. |kim-en| raw:: html

   <a class="k05-cite" href="#k05-statistics-reference-2-en" aria-label="Reference 2">[2]</a>

.. |ref-zh| raw:: html

   <a class="k05-cite" href="#k05-statistics-reference-1-zh" aria-label="参考文献 1">[1]</a>

.. |kim-zh| raw:: html

   <a class="k05-cite" href="#k05-statistics-reference-2-zh" aria-label="参考文献 2">[2]</a>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-statistics-en:

   .. rubric:: From repeated records to power spectra, cross spectra and bispectra

   The :ref:`previous page <k05-probe-signals-en>` turned a pair of synchronized
   probe records into complex coefficients :math:`X_f` and :math:`Y_f`.
   One record tells us what happened during one short interval. Repeating the
   measurement gives different coefficients. **How can we summarize those
   records without losing the relationships between waves?**

   We will build the averages used in the analysis of Brown and Jorns |ref-en|,
   then connect them to the quadratic term in the wave equation. The Fourier
   sign and normalization remain those of :k05:eq:`time-fourier-series`.

   .. rubric:: 1. Average a quantity over many records

   Split the two simultaneous signals into :math:`R` paired segments of equal
   duration. Segment :math:`r` gives :math:`X_f^{(r)}` at the first probe and
   :math:`Y_f^{(r)}` at the second, on the same frequency grid. Here
   :math:`r=1,\ldots,R` labels a segment; the parenthesized superscript is not
   a power. The coefficients still have units V.

   For any quantity :math:`Z^{(r)}` calculated from segment :math:`r`, define

   .. k05:equation:: record-average
      :lang: en

      \langle Z\rangle_R=\frac{1}{R}\sum_{r=1}^{R}Z^{(r)}.

   The brackets mean: calculate the quantity in each segment, add the results,
   then divide by the number of segments. They do **not** mean averaging over
   frequency. :math:`Z` may be one coefficient, its magnitude squared, or a product
   of several coefficients. Choosing that product determines what the average measures.

   .. raw:: html

      <details class="k05-note"><summary>When can segments stand in for repeated measurements?</summary>

   This is a finite-sample estimate of an **ensemble average**: an average over
   repeated realizations of comparable conditions. Segments of a long record can
   serve that purpose when the underlying statistics remain sufficiently steady
   and the record is representative. A change of operating condition should not
   silently be mixed into the same ensemble.

   Use the same segment boundaries, sampling interval and processing for the two
   probes. Each paired segment uses a common local time origin. Correlated or
   overlapping segments provide fewer independent realizations than their raw
   count suggests. Increasing :math:`R` reduces random scatter under suitable
   sampling conditions; it does not remove a systematic instrument error.
   See :doc:`segmentation and windowing <K01_signal_spectra/fun_K01_segment_ffts>`.

   .. raw:: html

      </details>

   .. rubric:: 2. Power keeps the size of a fluctuation

   To ask how strong a frequency component is, multiply its coefficient by its
   complex conjugate before averaging. Since :math:`XX^*=|X|^2`, define

   .. k05:equation:: record-powers
      :lang: en

      P_X(f)=\left\langle |X_f|^2\right\rangle_R,\qquad
      P_Y(f)=\left\langle |Y_f|^2\right\rangle_R.

   :math:`P_X` and :math:`P_Y` are the two **power spectra** in our discrete,
   two-sided convention. Each value is a mean-square voltage contribution at
   one frequency bin, in :math:`\mathrm{V^2}`. It is not yet a plasma energy in
   joules; that conversion requires the appropriate plasma response.

   The magnitude squared does not depend on the coefficient's phase. A frequency
   can therefore have a substantial power even when its complex coefficients
   point in different directions in different records.

   .. raw:: html

      <details class="k05-note"><summary>Why not average the coefficients first and then square?</summary>

   Take two coefficients with equal magnitude :math:`a>0`, in V, and opposite
   phases. Their average cancels, but their powers add:

   .. k05:equation:: cancellation-average
      :lang: en

      X_f^{(1)}=a,\quad X_f^{(2)}=-a,\qquad
      \left|\langle X_f\rangle_2\right|^2=0,\quad
      \left\langle |X_f|^2\right\rangle_2=a^2.

   Thus :math:`|\langle X_f\rangle_R|^2` and
   :math:`\langle |X_f|^2\rangle_R` answer different questions. The first retains
   only the part coherent with the chosen segment timing; the second measures
   the mean-square fluctuation at that frequency.

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>How does bin power relate to a power spectral density?</summary>

   For :math:`N` samples spaced by :math:`\Delta t_s` seconds, with the normalized
   coefficients of the previous page and a rectangular window,

   .. k05:equation:: bin-power-density
      :lang: en

      T=N\Delta t_s,\qquad \Delta f=\frac{1}{T},\qquad
      S_{XX}(f)=\frac{P_X(f)}{\Delta f}.

   :math:`T` is the segment duration, and :math:`\Delta f` is the frequency-bin
   spacing in Hz. :math:`S_{XX}` is a two-sided **power spectral density**, in
   :math:`\mathrm{V^2/Hz}`. Dividing by the bin width changes the units;
   it is not an additional measurement. A one-sided density doubles the interior
   positive-frequency bins, excluding zero and the Nyquist bin when present.
   Other windows require their own normalization; see
   :doc:`power-spectrum normalization <K01_signal_spectra/fun_K01_power_spectrum>`.

   .. raw:: html

      </details>

   .. rubric:: 3. Cross power compares the two probe positions

   Powers alone discard phase. To compare the same frequency at two positions,
   average the product of the second probe's coefficient and the conjugate of
   the first:

   .. k05:equation:: probe-cross-power
      :lang: en

      G_{YX}(f)=\left\langle Y_fX_f^*\right\rangle_R,\qquad
      \Delta\Theta_f=\arg G_{YX}(f)\quad\bigl(G_{YX}\ne0\bigr).

   :math:`G_{YX}` is a **cross-power spectrum**, in :math:`\mathrm{V^2}` with this
   normalization. The order :math:`YX` specifies which coefficient is conjugated.
   Its argument :math:`\arg` is the phase angle :math:`\Delta\Theta_f`, measured
   modulo :math:`2\pi`. Average the complex products first, then take their
   argument; do not average wrapped phase angles directly.

   .. raw:: html

      <details class="k05-note"><summary>A simple case: the second probe sees a fixed complex gain</summary>

   Suppose the same dimensionless complex gain :math:`H_f` relates the two
   coefficients in every segment. Then

   .. k05:equation:: cross-linear-gain
      :lang: en

      Y_f^{(r)}=H_fX_f^{(r)}\quad\Longrightarrow\quad
      G_{YX}(f)=H_fP_X(f).

   Since :math:`P_X` is real and positive when that frequency is present,
   :math:`\arg G_{YX}=\arg H_f`. For the simple propagation model
   :k05:eq:`probe-linear-propagation`, this is the spatial phase advance.
   Swapping the product to :math:`\langle X_fY_f^*\rangle_R` conjugates the
   cross spectrum and reverses the phase sign. A phase difference by itself
   does not determine a growth rate.

   .. raw:: html

      </details>

   .. rubric:: 4. The bispectrum keeps a three-frequency phase relationship

   The quadratic term on the previous page multiplies two components to feed a
   third frequency. Pick a pair :math:`f_1,f_2` and its sum :math:`f_3`.
   Compare their product with the coefficient already present at that sum:

   .. k05:equation:: auto-bispectrum
      :lang: en

      \begin{aligned}
      f_3&=f_1+f_2,\qquad
      Z^{(r)}=X_{f_1}^{(r)}X_{f_2}^{(r)}\bigl(X_{f_3}^{(r)}\bigr)^*,\\
      B_X(f_1,f_2)&=\langle Z\rangle_R
      =\left\langle X_{f_1}X_{f_2}X_{f_3}^*\right\rangle_R.
      \end{aligned}

   :math:`Z^{(r)}` is now a particular three-coefficient product from one record.
   :math:`B_X` is its average, called the **bispectrum**. The subscript :math:`X`
   says that all three coefficients come from the first probe. It has units
   :math:`\mathrm{V^3}` and is generally complex. There are two independent
   frequency arguments because the third is fixed by their sum.

   To see what survives averaging, write each coefficient as a magnitude times
   a phase factor:

   .. k05:equation:: triad-phase
      :lang: en

      \begin{aligned}
      X_{f_\ell}^{(r)}&=a_{\ell,r}e^{i\theta_{\ell,r}},\qquad \ell=1,2,3,\\
      Z^{(r)}&=a_{1,r}a_{2,r}a_{3,r}e^{i\psi_r},\qquad
      \psi_r=\theta_{1,r}+\theta_{2,r}-\theta_{3,r}.
      \end{aligned}

   Here :math:`\ell` labels the three frequencies, :math:`a_{\ell,r}\ge0` is a
   coefficient magnitude in V, and :math:`\theta_{\ell,r}` is its phase in radians.
   Conjugating the third coefficient subtracts its phase. The combination
   :math:`\psi_r` is the phase of the product, not the phase of a single wave.

   Think of each :math:`Z^{(r)}` as an arrow in the complex plane. Its horizontal
   and vertical coordinates are the real and imaginary parts of the product.
   When these
   arrows keep pointing in a similar direction, their average remains large.
   For fixed magnitudes and independent uniformly distributed phases, the
   population average is zero; a finite collection generally leaves a residual.
   The bispectrum can distinguish these cases even when their power spectra agree.

   .. raw:: html

      <div id="k05-statistics-figure-en" class="k05-statistics" data-k05-statistics="en">
        <img src="../../_static/K_Diagnostics/k05-phase-statistics-en.svg" alt="Products with a fixed phase relation align in the complex plane; their average remains large while all three powers stay fixed.">
      </div>

   Start with **Fixed phase relation**, then select **Independent phases**.
   The three powers stay at 1. The grey arrows are the individual products;
   the orange arrow is their mean. The right-hand curve shows the mean magnitude
   after each of the first :math:`n` records, up to the selected :math:`R`.
   Increasing :math:`R` does not force every successive random mean to decrease.

   Change :math:`\delta` to rotate the phase relationship. In the fixed case it
   rotates the mean without changing its magnitude. **New phases** draws another
   reproducible set. These are synthetic coefficients, not experimental data
   or a simulation of interacting plasma waves.

   With a fixed relation, redrawing the individual phases leaves their product
   unchanged because the same phase constraint is still imposed.

   .. raw:: html

      <details class="k05-note"><summary>The exact records and parameters behind the illustration</summary>

   The coefficients represent ideal one-second real records sampled at 128 Hz
   (:math:`N=128`, :math:`\Delta t_s=1/128` s). All three frequencies lie on bins
   below Nyquist. In arbitrary amplitude units, the records are

   .. k05:equation:: phase-ensemble
      :lang: en

      \begin{aligned}
      x_r(\tau)&=2\sum_{\ell=1}^{3}\cos(\theta_{\ell,r}-2\pi f_\ell\tau),
      \qquad(f_1,f_2,f_3)=(3,5,8)\ \mathrm{Hz},\\
      X_{f_\ell}^{(r)}&=e^{i\theta_{\ell,r}},\qquad
      P_X(f_1)=P_X(f_2)=P_X(f_3)=1,\\
      Z^{(r)}&=e^{i\psi_r},\qquad B_X=\frac1R\sum_{r=1}^{R}e^{i\psi_r}.
      \end{aligned}

   :math:`\tau` is local time within one record. :math:`x_r` is its real signal;
   the factor 2 gives unit positive-frequency coefficients with the previous
   page's convention. Negative-frequency coefficients are their conjugates.
   The plot evaluates the exact coefficients directly.

   In the fixed case, independent uniform phases :math:`\theta_{1,r}` and
   :math:`\theta_{2,r}` are drawn on :math:`[0,2\pi)`, then
   :math:`\theta_{3,r}=\theta_{1,r}+\theta_{2,r}-\delta`.
   Thus :math:`\psi_r=\delta` in every record and :math:`B_X=e^{i\delta}`.
   In the independent case, draw a third independent uniform phase
   :math:`\eta_r` and set :math:`\theta_{3,r}=\eta_r-\delta`.
   The arrows then have independent uniform directions.

   The initial seed is 7, :math:`R=32` and :math:`\delta=60^\circ=\pi/3`.
   The controls allow 1–128 records and :math:`-180^\circ\le\delta\le180^\circ`.
   Changing the count keeps the same initial records; only **New phases** changes
   the seed. Amplitude and power values use arbitrary units throughout the drawing.

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>A normalized measure: squared bicoherence</summary>

   A large bispectrum can partly reflect large amplitudes. One useful
   normalization is the **squared bicoherence**, defined here by

   .. k05:equation:: bicoherence
      :lang: en

      b_X^2(f_1,f_2)=
      \frac{|B_X(f_1,f_2)|^2}
      {\left\langle |X_{f_1}X_{f_2}|^2\right\rangle_R P_X(f_3)},
      \qquad 0\le b_X^2\le1.

   This expression requires a nonzero denominator; otherwise it is undefined.
   The bound follows from the Cauchy–Schwarz inequality applied to the two
   record-wise quantities :math:`X_{f_1}X_{f_2}` and :math:`X_{f_3}`.
   The powers of V cancel, so :math:`b_X^2` is dimensionless. With fluctuating
   amplitudes it is a weighted phase relation, not simply an unweighted average
   of unit arrows.

   In this illustration all magnitudes are 1, so :math:`b_X^2=|B_X|^2`.
   With only one record it is always 1, even for independent phases: a single
   record cannot establish a repeatable relationship. For independent uniform
   arrows, the expected finite-sample value is :math:`1/R`, not exactly zero.
   Assessing measured values therefore needs sampling uncertainty or a suitable
   random-phase reference, not just a nonzero result.

   The illustration prescribes phases without solving any dynamics. A nonzero
   bispectrum alone does not establish the physical coupling mechanism or the
   direction of energy transfer.

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>From the averages to NumPy code</summary>

   Let ``x`` and ``y`` be real arrays of shape ``(R, N)``: each row is one
   synchronized segment and each column one sample. Use matching preprocessing.
   Here ``m1`` and ``m2`` are positive bin indices with
   ``m3 = m1 + m2 < N / 2``. The coefficients use ``ifft`` exactly as explained
   on the previous page. ``axis=1`` transforms each row; ``axis=0`` averages
   over the records.

   .. code-block:: python

      import numpy as np

      def spectral_moments(x, y, m1, m2):
          X = np.fft.ifft(x, axis=1)
          Y = np.fft.ifft(y, axis=1)
          m3 = m1 + m2
          PX = np.mean(np.abs(X)**2, axis=0)
          PY = np.mean(np.abs(Y)**2, axis=0)
          GYX = np.mean(Y * X.conj(), axis=0)
          pair = X[:, m1] * X[:, m2]
          BX = np.mean(pair * X[:, m3].conj())
          denominator = np.mean(np.abs(pair)**2) * PX[m3]
          b2 = abs(BX)**2 / denominator if denominator > 0 else np.nan
          return PX, PY, GYX, BX, b2

   ``PX``, ``PY`` and ``GYX`` contain one value per frequency bin;
   ``BX`` and ``b2`` refer to the selected pair only. ``np.nan`` marks an
   undefined normalization. This code calculates moments without a one-sided
   factor or a PSD bin-width conversion.

   .. raw:: html

      </details>

   .. rubric:: 5. Why the quadratic wave equation needs the bispectrum

   Return to :k05:eq:`frequency-equation-1d`, where the coefficient
   :math:`C_f(y)` varies with position. At the first probe it is :math:`X_f`.
   Define :math:`P_f(y)=\langle|C_f(y)|^2\rangle_R` and
   :math:`B_C(f_1,f_2;y)=\langle C_{f_1}(y)C_{f_2}(y)C_f(y)^*\rangle_R`
   for :math:`f_1+f_2=f`.

   To obtain a power equation, multiply the wave equation by :math:`C_f^*`,
   add its complex conjugate, and average. Assume the real quantities
   :math:`v_{g,f}`, :math:`\gamma_f`, :math:`k_f` and the possibly complex
   :math:`V^Q_{1,2}` are the same across the records being averaged.

   .. raw:: html

      <details class="k05-note"><summary>Show the derivative and the cancellation of the phase term</summary>

   The product rule and :k05:eq:`frequency-equation-1d` give

   .. k05:equation:: variance-derivative
      :lang: en

      \begin{aligned}
      \partial_y|C_f|^2
      &=C_f^*\partial_y C_f+C_f\partial_y C_f^*
      =2\operatorname{Re}\!\left(C_f^*\partial_y C_f\right),\\
      v_{g,f}\partial_y|C_f|^2
      &=2\operatorname{Re}\!\left[
      (\gamma_f+ik_fv_{g,f})|C_f|^2
      +\sum_{f_1+f_2=f}V^Q_{1,2}C_{f_1}C_{f_2}C_f^*\right].
      \end{aligned}

   :math:`\operatorname{Re}` takes the real part. The term
   :math:`ik_fv_{g,f}|C_f|^2` is purely imaginary, so it contributes nothing
   to this real part. The term :math:`\gamma_f|C_f|^2` survives twice.
   For the quadratic term, multiplication by :math:`C_f^*` makes precisely
   the three-coefficient product whose average is :math:`B_C`.
   With the same averaging ensemble at nearby positions, averaging commutes
   with this derivative. The result is
   :k05:eq:`spectral-power-balance`.

   .. raw:: html

      </details>

   .. k05:equation:: spectral-power-balance
      :lang: en

      v_{g,f}\frac{\partial P_f}{\partial y}
      =2\gamma_fP_f
      +2\operatorname{Re}\!\left[\sum_{f_1+f_2=f}
      V^Q_{1,2}B_C(f_1,f_2;y)\right].

   Every term has units :math:`\mathrm{V^2/s}`. The linear term contains
   :math:`2\gamma_f` because power is proportional to amplitude squared.
   The last term combines the bispectrum with the complex coupling coefficient.
   Its sign depends on their combination; :math:`|B_C|` alone cannot give a
   transfer direction. This is a continuous mean-square-potential balance
   derived from the one-dimensional model. A physical energy balance also
   requires the plasma-response weighting; the article's discrete transfer
   formula additionally involves its two-probe discretization and coefficients.

   .. raw:: html

      <details class="k05-note"><summary>The two-probe version used in the coefficient inference</summary>

   Ref. |ref-en| also uses a **cross bispectrum**: the output-frequency
   coefficient comes from the second probe, while both input coefficients
   come from the first. With the conjugate ordering used in its Eq. (5),

   .. k05:equation:: cross-bispectrum
      :lang: en

      \begin{aligned}
      B_{Y|XX}(f_1,f_2)&=\left\langle Y_{f_3}X_{f_1}^*X_{f_2}^*\right\rangle_R,
      \qquad f_3=f_1+f_2,\\
      Y=X\quad&\Longrightarrow\quad B_{Y|XX}=B_X^*.
      \end{aligned}

   The notation :math:`Y|XX` records the probe assignments; the vertical bar
   does not denote a conditional probability. The units are again
   :math:`\mathrm{V^3}`. When the two probes are identical, this ordering gives
   the conjugate of our auto-bispectrum, not the same complex number in general.
   Both conventions are usable if the equations and code keep the conjugations
   consistent. The auto- and cross-moments provide the measurements used by
   the coefficient-estimation method |ref-en| |kim-en|.

   .. raw:: html

      </details>

   We can now compute what the records say about strength, spatial phase and
   three-frequency phase relations. The :ref:`next page <k05-inference-en>`
   uses these moments to estimate the linear and quadratic coefficients of the
   two-probe model, then connects them to growth and transfer rates.

   .. rubric:: References

   .. _k05-statistics-reference-1-en:

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   .. _k05-statistics-reference-2-en:

   [2] J. S. Kim, R. D. Durst, R. J. Fonck, E. Fernandez, A. Ware and P. W. Terry,
   “Technique for the experimental estimation of nonlinear energy transfer in
   fully developed turbulence,” *Physics of Plasmas* **3**, 3998–4009 (1996).
   `doi:10.1063/1.871572 <https://doi.org/10.1063/1.871572>`_.

   Ref. [1], p. 115101-3, introduces the two-probe moments and ensemble averaging;
   Ref. [2], Secs. II–III, develops the model and its moment-based estimation method.
   The explicit normalization, examples, illustration and continuous power-balance
   derivation here are explanatory additions.


.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-statistics-zh:

   .. rubric:: 从重复记录到功率谱、互谱与双谱

   :ref:`上一页面 <k05-probe-signals-zh>` 已把一对同步探针记录变成复系数 :math:`X_f` 和 :math:`Y_f`。
   一段记录描述一个短时间区间；重复测量时，系数通常会变化。
   **怎样把这些记录合起来，又保留波与波之间的关系？**

   本页面逐步建立 Brown 与 Jorns |ref-zh| 分析中用到的平均量，再把它们接回波动方程的二次项。
   傅里叶符号与归一化继续采用 :k05:eq:`time-fourier-series`。

   .. rubric:: 1. 对许多段记录中的同一个量取平均

   把两路同步信号切成 :math:`R` 对等长片段。第 :math:`r` 段在第一支探针处给出
   :math:`X_f^{(r)}`，在第二支探针处给出 :math:`Y_f^{(r)}`，两者使用同一频率网格。
   :math:`r=1,\ldots,R` 是片段编号，带括号的上标不是乘方。系数的单位仍是 V。

   设 :math:`Z^{(r)}` 是由第 :math:`r` 段算出的某个量，定义

   .. k05:equation:: record-average
      :lang: zh

      \langle Z\rangle_R=\frac{1}{R}\sum_{r=1}^{R}Z^{(r)}.

   尖括号表示：每一段各算一次，把结果加起来，再除以段数。
   它 **不是对不同频率求平均**。:math:`Z` 可以是一个复系数、它的模平方，也可以是几个系数的乘积。
   选用什么乘积，就决定这个平均量记录什么信息。

   .. raw:: html

      <details class="k05-note"><summary>什么时候可以把分段当作重复测量？</summary>

   这是集合平均（ensemble average）的有限样本估计：对条件相近的多次实现取平均。
   当过程的统计性质足够稳定、整段记录又有代表性时，可以用一条长记录的多个片段来估计。
   不同运行工况下的数据不应悄悄混成同一个集合。

   两支探针采用相同的分段边界、采样间隔和处理方式；每对片段使用共同的局部时间起点。
   片段相互相关或重叠时，独立信息量通常小于名义段数。
   在合适的采样条件下，增加 :math:`R` 可以减小随机起伏，但不会自动消除仪器的系统误差。
   操作细节见 :doc:`分段与窗函数 <K01_signal_spectra/fun_K01_segment_ffts>`。

   .. raw:: html

      </details>

   .. rubric:: 2. 功率谱保留某个频率的强度

   要问某个频率成分有多强，先把系数乘以它的复共轭，再平均。
   因为 :math:`XX^*=|X|^2`，定义

   .. k05:equation:: record-powers
      :lang: zh

      P_X(f)=\left\langle |X_f|^2\right\rangle_R,\qquad
      P_Y(f)=\left\langle |Y_f|^2\right\rangle_R.

   :math:`P_X` 和 :math:`P_Y` 是本页离散双边约定下的功率谱（power spectrum）。
   每个频点的值是对应的平均电压平方贡献，单位为 :math:`\mathrm{V^2}`。
   它还不是以焦耳表示的等离子体波能量；要换算能量，还需要相应的等离子体响应关系。

   模平方不依赖复系数的相位。因此，即使同一频率的系数在不同记录里指向不同方向，
   这个频率的功率仍然可以很大。

   .. raw:: html

      <details class="k05-note"><summary>为什么不能先把复系数平均，再取模平方？</summary>

   取两个模相同、相位相反的系数。:math:`a>0` 是它们的模，单位为 V。
   平均复数时它们抵消，平均功率时却不会：

   .. k05:equation:: cancellation-average
      :lang: zh

      X_f^{(1)}=a,\quad X_f^{(2)}=-a,\qquad
      \left|\langle X_f\rangle_2\right|^2=0,\quad
      \left\langle |X_f|^2\right\rangle_2=a^2.

   所以 :math:`|\langle X_f\rangle_R|^2` 与 :math:`\langle|X_f|^2\rangle_R` 回答不同问题。
   前者只保留相对于分段时间起点相干的部分；后者衡量这个频率的平均平方起伏。

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>频点功率与功率谱密度是什么关系？</summary>

   每段含 :math:`N` 个样本，采样间隔为 :math:`\Delta t_s` 秒。
   沿用上一页归一化、且使用矩形窗时，

   .. k05:equation:: bin-power-density
      :lang: zh

      T=N\Delta t_s,\qquad \Delta f=\frac{1}{T},\qquad
      S_{XX}(f)=\frac{P_X(f)}{\Delta f}.

   :math:`T` 是每段时长，:math:`\Delta f` 是频率网格间隔，单位为 Hz。
   :math:`S_{XX}` 是双边功率谱密度（power spectral density），单位为 :math:`\mathrm{V^2/Hz}`。
   除以频点宽度改变的是归一化和单位，并没有新增一次测量。
   改成单边谱密度时，正频率内部频点乘二；零频和存在时的奈奎斯特频点不乘二。
   其他窗函数需要相应归一化，见 :doc:`功率谱归一化 <K01_signal_spectra/fun_K01_power_spectrum>`。

   .. raw:: html

      </details>

   .. rubric:: 3. 互谱比较两支探针处的关系

   功率谱本身丢掉了相位。要比较同一频率在两处的关系，可以把第二支探针的系数
   乘以第一支探针系数的复共轭，然后平均：

   .. k05:equation:: probe-cross-power
      :lang: zh

      G_{YX}(f)=\left\langle Y_fX_f^*\right\rangle_R,\qquad
      \Delta\Theta_f=\arg G_{YX}(f)\quad\bigl(G_{YX}\ne0\bigr).

   :math:`G_{YX}` 是互功率谱（cross-power spectrum），在这里的归一化下单位为 :math:`\mathrm{V^2}`。
   下标顺序 :math:`YX` 指明哪一个系数被取共轭。
   :math:`\arg` 表示取相位角；:math:`\Delta\Theta_f` 是模 :math:`2\pi` 意义下的相位差。
   应先平均复数乘积，再取相位，不能直接把折回一个周期的相位角作普通平均。

   .. raw:: html

      <details class="k05-note"><summary>一个简单情况：第二支探针只多了固定的复增益</summary>

   假设每一段里，两处系数都由同一个无量纲复增益 :math:`H_f` 联系起来，则

   .. k05:equation:: cross-linear-gain
      :lang: zh

      Y_f^{(r)}=H_fX_f^{(r)}\quad\Longrightarrow\quad
      G_{YX}(f)=H_fP_X(f).

   只要这个频率有信号，:math:`P_X` 就是正实数，所以 :math:`\arg G_{YX}=\arg H_f`。
   对于 :k05:eq:`probe-linear-propagation` 的简单传播模型，它就是空间相位推进。
   若把乘积换成 :math:`\langle X_fY_f^*\rangle_R`，互谱会变为复共轭，相位符号也会反过来。
   相位差本身不能确定增长率。

   .. raw:: html

      </details>

   .. rubric:: 4. 双谱保留三个频率之间的相位关系

   上一页的二次项把两个频率成分相乘，作用到第三个频率。
   选取一对 :math:`f_1,f_2`，令它们的和为 :math:`f_3`，再把前两项的乘积与和频处已有的系数比较：

   .. k05:equation:: auto-bispectrum
      :lang: zh

      \begin{aligned}
      f_3&=f_1+f_2,\qquad
      Z^{(r)}=X_{f_1}^{(r)}X_{f_2}^{(r)}\bigl(X_{f_3}^{(r)}\bigr)^*,\\
      B_X(f_1,f_2)&=\langle Z\rangle_R
      =\left\langle X_{f_1}X_{f_2}X_{f_3}^*\right\rangle_R.
      \end{aligned}

   这里的 :math:`Z^{(r)}` 是第 :math:`r` 段的一个具体三系数乘积。
   它的平均值 :math:`B_X` 就叫双谱（bispectrum）；下标 :math:`X` 表示三个系数都来自第一支探针。
   它的单位为 :math:`\mathrm{V^3}`，一般是复数。
   只有两个独立的频率参数，因为第三个频率已经由前两者之和确定。

   把每个复系数写成“模乘以相位因子”，就能看清平均时保留了什么：

   .. k05:equation:: triad-phase
      :lang: zh

      \begin{aligned}
      X_{f_\ell}^{(r)}&=a_{\ell,r}e^{i\theta_{\ell,r}},\qquad \ell=1,2,3,\\
      Z^{(r)}&=a_{1,r}a_{2,r}a_{3,r}e^{i\psi_r},\qquad
      \psi_r=\theta_{1,r}+\theta_{2,r}-\theta_{3,r}.
      \end{aligned}

   :math:`\ell` 标记三个频率，:math:`a_{\ell,r}\ge0` 是第 :math:`r` 段相应系数的模，单位 V；
   :math:`\theta_{\ell,r}` 是相位，单位 rad。第三项取共轭，所以它的相位被减去。
   :math:`\psi_r` 是乘积的相位组合，不是其中某一列波的相位。

   把每个 :math:`Z^{(r)}` 想成复平面上的一支箭头。
   横坐标是乘积的实部（Re），纵坐标是虚部（Im）。
   如果这些箭头总是大致朝同一个方向，平均后就能留下较大的结果。
   若模固定、各相位独立且均匀分布，理论总体平均为零，但有限段数通常还会留下残余。
   即使功率谱相同，双谱也能区分这两种相位组织方式。

   .. raw:: html

      <div id="k05-statistics-figure-zh" class="k05-statistics" data-k05-statistics="zh">
        <img src="../../_static/K_Diagnostics/k05-phase-statistics-zh.svg" alt="相位关系固定时，各段三频乘积的箭头指向相同方向，平均值保持较大，而三个频点的功率不变。">
      </div>

   先看 **相位关系固定**，再切换到 **相位彼此独立**。三个功率始终为 1。
   灰箭头代表各段的乘积，橙箭头代表平均值；右图表示从第 1 段开始，累计平均前
   :math:`n` 段后得到的模，直到所选的 :math:`R` 段。
   增加 :math:`R` 不意味着随机平均值每一步都会变小。

   改变 :math:`\delta`，就改变相位关系的偏移。在固定关系下，它只旋转平均箭头，并不改变模。
   点击 **换一组相位** 可以重抽一组可重复的样本。
   这是人工构造的系数，不是实验数据，也没有求解等离子体波相互作用的动力学。

   固定关系下重新抽取各个相位，三频乘积仍然不变，因为相同的相位约束一直保留着。

   .. raw:: html

      <details class="k05-note"><summary>这个图对应的记录、函数和参数</summary>

   这些系数对应时长 1 s、采样率 128 Hz 的理想实数记录，
   即 :math:`N=128`、:math:`\Delta t_s=1/128` s。
   三个频率都恰好落在频率网格上，并低于奈奎斯特频率。
   用任意幅度单位表示，记录是

   .. k05:equation:: phase-ensemble
      :lang: zh

      \begin{aligned}
      x_r(\tau)&=2\sum_{\ell=1}^{3}\cos(\theta_{\ell,r}-2\pi f_\ell\tau),
      \qquad(f_1,f_2,f_3)=(3,5,8)\ \mathrm{Hz},\\
      X_{f_\ell}^{(r)}&=e^{i\theta_{\ell,r}},\qquad
      P_X(f_1)=P_X(f_2)=P_X(f_3)=1,\\
      Z^{(r)}&=e^{i\psi_r},\qquad B_X=\frac1R\sum_{r=1}^{R}e^{i\psi_r}.
      \end{aligned}

   :math:`\tau` 是每段内部的局部时间，:math:`x_r` 是第 :math:`r` 段的实数信号。
   前面的 2 保证在上一页的约定下，每个正频率系数的模恰好为 1；负频率系数是对应的复共轭。
   图中直接使用这些精确系数计算。

   固定关系模式下，先独立地从 :math:`[0,2\pi)` 均匀抽取
   :math:`\theta_{1,r}` 和 :math:`\theta_{2,r}`，再设置
   :math:`\theta_{3,r}=\theta_{1,r}+\theta_{2,r}-\delta`。
   于是每段都满足 :math:`\psi_r=\delta`，平均值为 :math:`B_X=e^{i\delta}`。
   独立模式下，再独立均匀抽取第三个相位 :math:`\eta_r`，令
   :math:`\theta_{3,r}=\eta_r-\delta`；乘积箭头的方向就独立、均匀地分布。

   初始随机种子为 7，:math:`R=32`，:math:`\delta=60^\circ=\pi/3`。
   控件允许 1–128 段，:math:`-180^\circ\le\delta\le180^\circ`。
   改变段数时，前面的记录保持不变；只有“换一组相位”会改变种子。
   图中的幅值和功率数值均使用任意单位。

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>一种归一化：平方双相干</summary>

   双谱大，可能部分来自幅值本身很大。一种有用的归一化是平方双相干（squared bicoherence），
   本页采用下面的定义：

   .. k05:equation:: bicoherence
      :lang: zh

      b_X^2(f_1,f_2)=
      \frac{|B_X(f_1,f_2)|^2}
      {\left\langle |X_{f_1}X_{f_2}|^2\right\rangle_R P_X(f_3)},
      \qquad 0\le b_X^2\le1.

   这个式子要求分母非零，否则无定义。把每段的 :math:`X_{f_1}X_{f_2}` 与 :math:`X_{f_3}`
   当作两组数，应用柯西–施瓦茨不等式（Cauchy–Schwarz inequality），就得到 0 到 1 的界限。
   分子和分母的 V 次方抵消，故 :math:`b_X^2` 无量纲。
   幅值也变化时，它包含幅值权重，不能一概当作单位箭头的简单平均。

   本图中各系数的模均为 1，因此 :math:`b_X^2=|B_X|^2`。
   如果只有一段记录，即使相位独立，它也总是 1：单段记录不能证明关系在重复测量中保持稳定。
   对于独立均匀的箭头，有限样本结果的期望为 :math:`1/R`，而非严格为零。
   所以实际测量需要采样不确定度或合适的随机相位参照，不能只看结果是否非零。

   本图直接指定相位，没有求解动力学。
   仅凭非零双谱，不能确定背后的物理耦合机制，也不能确定能量转移方向。

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>把这些平均写成 NumPy 代码</summary>

   输入 ``x``、``y`` 是形状为 ``(R, N)`` 的实数数组：每行是一段同步记录，每列是一个采样点。
   两路采用一致的预处理。这里 ``m1``、``m2`` 是正频率的整数下标，
   并要求 ``m3 = m1 + m2 < N / 2``。系数仍用上一页说明的 ``ifft`` 计算。
   ``axis=1`` 表示逐行变换；``axis=0`` 表示沿记录方向平均。

   .. code-block:: python

      import numpy as np

      def spectral_moments(x, y, m1, m2):
          X = np.fft.ifft(x, axis=1)
          Y = np.fft.ifft(y, axis=1)
          m3 = m1 + m2
          PX = np.mean(np.abs(X)**2, axis=0)
          PY = np.mean(np.abs(Y)**2, axis=0)
          GYX = np.mean(Y * X.conj(), axis=0)
          pair = X[:, m1] * X[:, m2]
          BX = np.mean(pair * X[:, m3].conj())
          denominator = np.mean(np.abs(pair)**2) * PX[m3]
          b2 = abs(BX)**2 / denominator if denominator > 0 else np.nan
          return PX, PY, GYX, BX, b2

   ``PX``、``PY``、``GYX`` 为每个频点返回一个值；``BX`` 和 ``b2`` 只对应选中的频率对。
   ``np.nan`` 表示归一化无定义。这里没有乘单边谱的因子，也没有除以频点宽度转为谱密度。

   .. raw:: html

      </details>

   .. rubric:: 5. 为什么二次波动方程需要双谱？

   回到 :k05:eq:`frequency-equation-1d`：其中 :math:`C_f(y)` 随位置变化，在第一支探针处就是
   :math:`X_f`。定义 :math:`P_f(y)=\langle|C_f(y)|^2\rangle_R`，并对 :math:`f_1+f_2=f` 定义
   :math:`B_C(f_1,f_2;y)=\langle C_{f_1}(y)C_{f_2}(y)C_f(y)^*\rangle_R`。

   要得到功率方程，把波动方程乘以 :math:`C_f^*`，加上其复共轭，再平均。
   这里假定实数 :math:`v_{g,f}`、:math:`\gamma_f`、:math:`k_f`，以及可以是复数的
   :math:`V^Q_{1,2}`，在参与平均的各段记录中相同。

   .. raw:: html

      <details class="k05-note"><summary>展开求导，并说明相位项怎样消失</summary>

   利用乘积求导法则和 :k05:eq:`frequency-equation-1d`，有

   .. k05:equation:: variance-derivative
      :lang: zh

      \begin{aligned}
      \partial_y|C_f|^2
      &=C_f^*\partial_y C_f+C_f\partial_y C_f^*
      =2\operatorname{Re}\!\left(C_f^*\partial_y C_f\right),\\
      v_{g,f}\partial_y|C_f|^2
      &=2\operatorname{Re}\!\left[
      (\gamma_f+ik_fv_{g,f})|C_f|^2
      +\sum_{f_1+f_2=f}V^Q_{1,2}C_{f_1}C_{f_2}C_f^*\right].
      \end{aligned}

   :math:`\operatorname{Re}` 表示取实部。:math:`ik_fv_{g,f}|C_f|^2` 是纯虚数，所以对这个实部没有贡献。
   而 :math:`\gamma_f|C_f|^2` 会保留两次。
   二次项乘上 :math:`C_f^*` 后，正好变成前面定义的三系数乘积；它的平均就是 :math:`B_C`。
   在邻近位置使用同一个平均集合时，平均与这里的求导可以交换，得到
   :k05:eq:`spectral-power-balance`。

   .. raw:: html

      </details>

   .. k05:equation:: spectral-power-balance
      :lang: zh

      v_{g,f}\frac{\partial P_f}{\partial y}
      =2\gamma_fP_f
      +2\operatorname{Re}\!\left[\sum_{f_1+f_2=f}
      V^Q_{1,2}B_C(f_1,f_2;y)\right].

   各项单位都是 :math:`\mathrm{V^2/s}`。线性项中出现 :math:`2\gamma_f`，因为功率正比于幅值的平方。
   最后一项把双谱与复耦合系数相乘；正负取决于两者的组合，单看 :math:`|B_C|` 无法判断转移方向。
   这是本页从一维模型得到的连续电势平方收支式。转换为物理波能量收支还需要等离子体响应权重；
   文献中的离散转移率公式还涉及双探针离散化及其系数。

   .. raw:: html

      <details class="k05-note"><summary>两支探针一起使用时：互双谱</summary>

   文献 |ref-zh| 还使用互双谱（cross bispectrum）：和频处的系数来自第二支探针，
   两个输入频率的系数来自第一支探针。按其公式 (5) 的共轭顺序，

   .. k05:equation:: cross-bispectrum
      :lang: zh

      \begin{aligned}
      B_{Y|XX}(f_1,f_2)&=\left\langle Y_{f_3}X_{f_1}^*X_{f_2}^*\right\rangle_R,
      \qquad f_3=f_1+f_2,\\
      Y=X\quad&\Longrightarrow\quad B_{Y|XX}=B_X^*.
      \end{aligned}

   :math:`Y|XX` 只记录探针分配，竖线不是条件概率的符号。单位仍是 :math:`\mathrm{V^3}`。
   若两支探针完全相同，这个顺序给出的是本页自双谱的复共轭，一般不是同一个复数。
   两种约定都可以用，但方程与代码中的共轭位置必须保持一致。
   自谱和互谱的这些统计量，为后续的系数估计提供测量输入 |ref-zh| |kim-zh|。

   .. raw:: html

      </details>

   现在可以从记录中提取强度、空间相位与三频相位关联。
   :ref:`下一页面 <k05-inference-zh>` 利用这些统计量联合估计双探针模型的线性与二次系数，
   再把它们连接到增长率和波间转移率。

   .. rubric:: 参考文献

   .. _k05-statistics-reference-1-zh:

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   .. _k05-statistics-reference-2-zh:

   [2] J. S. Kim, R. D. Durst, R. J. Fonck, E. Fernandez, A. Ware and P. W. Terry,
   “Technique for the experimental estimation of nonlinear energy transfer in
   fully developed turbulence,” *Physics of Plasmas* **3**, 3998–4009 (1996).
   `doi:10.1063/1.871572 <https://doi.org/10.1063/1.871572>`_.

   文献 [1] 纸面第 115101-3 页给出双探针矩及集合平均的要求；文献 [2] 第 II–III 节给出模型及相关的矩估计方法。
   本页明确写出的归一化、示例、互动图和连续功率收支推导属于补充讲解。


