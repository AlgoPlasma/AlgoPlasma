.. K05 contribution history (Git author dates; edit times include timezone).
   2026-10-27 16:16 +08:00 | Yinjian Zhao | git 1782aebfbe9c
   2026-11-03 18:50 +08:00 | Yinjian Zhao | git 950991764e7f
   2026-11-04 08:15 +08:00 | Yinjian Zhao | git 6e01f53a6565
   2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

04 · From records to spectral statistics
========================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
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
   :math:`\arg G_{YX}=\arg H_f`. For the single travelling cosine in
   :k05:eq:`cosine-time-coefficients`, :math:`H_f=e^{ik\Delta y}`, so this
   angle is the spatial phase advance :math:`k\Delta y` modulo :math:`2\pi`.
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

   With only one record and a nonzero denominator, it is always 1, even for
   independent phases: a single record cannot establish a repeatable relationship.
   For fixed magnitudes and independent, uniformly distributed phase combinations
   :math:`\psi_r`, the expected finite-sample value is :math:`1/R`, not exactly zero.
   Assessing measured values therefore needs sampling uncertainty or a suitable
   random-phase reference, not just a nonzero result.

   A nonzero bispectrum alone does not establish the physical coupling mechanism or the
   direction of energy transfer.

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>From the averages to NumPy code</summary>

   Let ``x`` and ``y`` be real arrays of shape ``(R, N)``: each row is one
   synchronized segment and each column one sample. Use matching preprocessing.
   Here ``m1`` and ``m2`` are positive bin indices with
   ``m3 = m1 + m2 < N / 2``. Here ``ifft`` uses the positive exponent and
   division by :math:`N`, matching :k05:eq:`time-fourier-series`.
   ``axis=1`` transforms each row; ``axis=0`` averages
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
   undefined normalization. This code uses normalized, two-sided coefficients.

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
   The explicit normalization, examples and continuous power-balance
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
   对于 :k05:eq:`cosine-time-coefficients` 中单个传播的余弦波，
   :math:`H_f=e^{ik\Delta y}`，所以这个角度就是模 :math:`2\pi` 意义下的空间相位推进
   :math:`k\Delta y`。
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

   如果只有一段记录且分母非零，即使相位独立，它也总是 1：
   单段记录不能证明关系在重复测量中保持稳定。
   当模固定、相位组合 :math:`\psi_r` 彼此独立且均匀分布时，
   有限样本结果的期望为 :math:`1/R`，而非严格为零。
   所以实际测量需要采样不确定度或合适的随机相位参照，不能只看结果是否非零。

   仅凭非零双谱，不能确定背后的物理耦合机制，也不能确定能量转移方向。

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>把这些平均写成 NumPy 代码</summary>

   输入 ``x``、``y`` 是形状为 ``(R, N)`` 的实数数组：每行是一段同步记录，每列是一个采样点。
   两路采用一致的预处理。这里 ``m1``、``m2`` 是正频率的整数下标，
   并要求 ``m3 = m1 + m2 < N / 2``。这里 ``ifft`` 采用正指数并除以 :math:`N`，
   与 :k05:eq:`time-fourier-series` 的约定一致。
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
   ``np.nan`` 表示归一化无定义。这里使用归一化的双边系数。

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
   本页明确写出的归一化、示例和连续功率收支推导属于补充讲解。


