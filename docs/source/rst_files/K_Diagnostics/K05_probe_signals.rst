03 · From waves to probe records
=================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <script defer src="../../_static/K_Diagnostics/k05-probe-signals.js"></script>
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. |ref-en| raw:: html

   <a class="k05-cite" href="#k05-probe-reference-1-en" aria-label="Reference 1">[1]</a>

.. |ref-zh| raw:: html

   <a class="k05-cite" href="#k05-probe-reference-1-zh" aria-label="参考文献 1">[1]</a>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-probe-signals-en:

   .. rubric:: From a moving wave to probe records

   K05 connects wave evolution to measured signals. The :ref:`first page <k05-wave-overview-en>`
   explained how a wave moves, grows and interacts with other waves; the
   :ref:`second page <k05-coefficients-en>` explained the origin of its coefficients.
   Now place a detector at one fixed position. **How does a moving wave become a
   time record, and how can that record be connected to the wave equation?**
   We follow this connection to Eq. (2) of Brown and Jorns |ref-en|.

   .. rubric:: 1. Hold the probe still and let the wave pass

   Start with a single real potential wave:

   .. k05:equation:: travelling-potential
      :lang: en

      \Phi(y,t)=\Phi_0\cos(ky-2\pi f_0t),\qquad
      \lambda=\frac{2\pi}{k},\quad \omega_0=2\pi f_0.

   The capital :math:`\Phi` denotes the real potential fluctuation, in volts (V),
   and :math:`\Phi_0` is its peak amplitude. Position :math:`y` is in metres and
   time :math:`t` in seconds. The wavenumber :math:`k` is in rad/m; the frequency
   :math:`f_0` counts cycles per second (Hz). Wavelength :math:`\lambda` is in metres,
   and angular frequency :math:`\omega_0` is in rad/s. Choose :math:`k>0` and
   :math:`f_0>0`: the crests move towards increasing :math:`y`.

   An ideal potential detector at :math:`y=0` records only the value passing that
   point. A second detector, a distance :math:`\Delta y>0` away, records the same
   wave later:

   .. k05:equation:: fixed-probe-traces
      :lang: en

      s_1(t)=\Phi(0,t),\qquad s_2(t)=\Phi(\Delta y,t),\qquad
      \Delta t=\frac{k\Delta y}{2\pi f_0}.

   Here :math:`s_1` and :math:`s_2` are the two time traces, and :math:`\Delta t`
   is the travel delay of a chosen crest. In this example the amplitudes are equal.
   A phase difference between the records therefore does not by itself mean growth.

   .. raw:: html

      <div class="k05-probes" data-k05-probes="en">
        <img src="../../_static/K_Diagnostics/k05-probe-signals-en.svg" alt="A moving sinusoidal wave sampled at two fixed positions, with two time traces below.">
      </div>

   Move the time slider: the dots on the spatial wave are the values marked on the
   two time traces below. Change the spacing to change their delay. The complete
   ideal traces are drawn in advance; the vertical cursor selects the displayed
   instant. The illustration shows a potential signal, not experimental data or
   the full response of an ion saturation probe.

   .. raw:: html

      <details class="k05-note"><summary>The exact wave used in the illustration</summary>

   The graph uses :k05:eq:`travelling-potential` with :math:`\Phi_0=1`,
   :math:`k=\pi` and :math:`f_0=0.5`, in arbitrary units. Thus :math:`\lambda=2`,
   the period is 2, and the crest speed is 1. The probes remain at
   :math:`y_1=0` and :math:`y_2=\Delta y`; the spacing control changes the second
   position. There is no growth, damping or coupling in this drawing.
   At the default :math:`\Delta y=0.5`, the delay is 0.5 and the spatial phase
   advance is :math:`k\Delta y=\pi/2`.

   .. raw:: html

      </details>

   .. rubric:: 2. A frequency coefficient stores amplitude and phase

   A measured trace usually contains many frequencies. A **time Fourier
   decomposition** expresses it as a sum of simple oscillations. To keep the
   normalization explicit, first consider a record that repeats after a duration
   :math:`T`. Its frequencies are :math:`f_m=m/T`, where :math:`m` is an integer:

   .. k05:equation:: time-fourier-series
      :lang: en

      \begin{aligned}
      \Phi(y,t)&=\sum_{m=-\infty}^{\infty}C_{f_m}(y)e^{-i2\pi f_mt},\qquad f_m=\frac{m}{T},\\
      C_{f_m}(y)&=\frac{1}{T}\int_0^T\Phi(y,t)e^{+i2\pi f_mt}\,dt.
      \end{aligned}

   The complex coefficient :math:`C_{f_m}(y)` tells us how much of that frequency
   is present at position :math:`y`, and its phase. The second line extracts it
   by multiplying the trace by the opposite rotating exponential and averaging.
   Different integer frequencies cancel in this average. The symbol :math:`i`
   satisfies :math:`i^2=-1`. Both :math:`\Phi` and :math:`C_f` have units V because
   of the factor :math:`1/T`.

   **Only time has been decomposed.** The position :math:`y` remains an argument
   of :math:`C_f(y)`. A coefficient can therefore differ at two probe positions.
   From here onward, :math:`f` denotes one frequency on this grid.

   .. raw:: html

      <details class="k05-note"><summary>For one cosine, what is the complex coefficient?</summary>

   If :math:`f_0` lies on the grid, Euler's identity gives

   .. k05:equation:: cosine-time-coefficients
      :lang: en

      \begin{aligned}
      \Phi_0\cos(ky-2\pi f_0t)
      &=\frac{\Phi_0}{2}e^{iky}e^{-i2\pi f_0t}
      +\frac{\Phi_0}{2}e^{-iky}e^{+i2\pi f_0t},\\
      C_{f_0}(y)&=\frac{\Phi_0}{2}e^{iky},\qquad
      C_{-f_0}(y)=C_{f_0}(y)^*.
      \end{aligned}

   The positive-frequency coefficient has magnitude :math:`\Phi_0/2` and phase
   :math:`ky`. The other half belongs to the negative-frequency coefficient;
   the star :math:`*` denotes complex conjugation. Their sum is the real cosine.
   The half is required by this two-sided convention. A one-sided peak amplitude
   would be :math:`2|C_{f_0}|`, not :math:`|C_{f_0}|`.

   Negative frequencies are the partners needed to represent a real signal.
   They also allow frequency sums to represent differences. For example,
   :math:`f_1+(-f_2)=f_1-f_2`. They do not by themselves specify a second
   propagation direction.

   .. raw:: html

      </details>

   .. rubric:: 3. Rewrite the wave equation one frequency at a time

   For one frequency component, write

   .. k05:equation:: time-component-derivatives
      :lang: en

      \begin{aligned}
      \phi_f(y,t)&=C_f(y)e^{-i\omega_ft},\qquad \omega_f=2\pi f,\\
      \partial_t\phi_f&=-i\omega_fC_fe^{-i\omega_ft},\qquad
      \partial_y\phi_f=(\partial_yC_f)e^{-i\omega_ft}.
      \end{aligned}

   The lowercase :math:`\phi_f` is one complex term in the real signal's sum.
   Unlike that term, :math:`C_f` has no fast time oscillation left in it; the spatial
   phase is still present. The subscript :math:`f` labels frequency, not a derivative.
   At a fixed position the time derivative multiplies by :math:`-i\omega_f`.
   The spatial derivative acts on :math:`C_f(y)`.

   The product of two components has a time exponential at the sum of their
   frequencies. Its contribution to frequency :math:`f` is

   .. k05:equation:: time-product-convolution
      :lang: en

      \begin{aligned}
      \phi_{f_1}\phi_{f_2}
      &=C_{f_1}C_{f_2}e^{-i2\pi(f_1+f_2)t},\\
      N_f&=\sum_{f_1+f_2=f}V^Q_{1,2}C_{f_1}C_{f_2}.
      \end{aligned}

   :math:`N_f` denotes the total quadratic contribution at the target frequency,
   in V/s. :math:`V^Q_{1,2}` weights each pair, with units :math:`\mathrm{V^{-1}s^{-1}}`
   in this normalization; :math:`Q` means quadratic and 1, 2 label the input waves.
   The sum includes signed frequency pairs with :math:`f_1+f_2=f`. It is the
   frequency version of the wave-pair sum on the first page.

   Ref. |ref-en| also makes a physical approximation here: each contributing
   frequency pair identifies a unique wavevector pair satisfying the original
   wavevector condition. This permits frequency-only labels. A Fourier transform
   alone does not establish that correspondence. We use the same restriction below.

   Apply these substitutions to the one-dimensional wave equation
   :k05:eq:`full-wave-equation-1d`. After cancelling the common time factor,
   the terms :math:`-i\omega_fC_f` cancel between the two sides, giving

   .. k05:equation:: frequency-equation-1d
      :lang: en

      v_{g,f}\frac{\partial C_f}{\partial y}
      =\bigl(\gamma_f+i k_f v_{g,f}\bigr)C_f+N_f.

   :math:`v_{g,f}` is the group velocity in the :math:`y` direction (m/s),
   :math:`\gamma_f` is the amplitude growth rate (1/s), and :math:`k_f` is the
   wavenumber assigned to frequency :math:`f` (rad/m). They are the quantities
   already introduced on the previous pages, now labelled by frequency.
   Every term has units V/s.

   This equation describes **how a frequency component changes with position**.
   The :math:`ik_fv_{g,f}` term retains its spatial phase advance; the
   :math:`\gamma_f` term changes its magnitude, and :math:`N_f` accounts for other
   waves. The time oscillation has been factored out, not set to zero.

   .. raw:: html

      <details class="k05-note"><summary>Show the cancellation, then restore three dimensions</summary>

   Substitute :k05:eq:`time-component-derivatives` and
   :k05:eq:`time-product-convolution` into :k05:eq:`full-wave-equation-1d`.
   Divide by :math:`e^{-i\omega_ft}`. The complete intermediate line is

   .. k05:equation:: time-carrier-cancellation
      :lang: en

      \begin{aligned}
      -i\omega_f C_f+v_{g,f}\partial_y C_f
      &=\gamma_f C_f+i(k_fv_{g,f}-\omega_f)C_f+N_f,\\
      v_{g,f}\partial_y C_f
      &=\gamma_f C_f+ik_fv_{g,f}C_f+N_f.
      \end{aligned}

   The first line keeps the time term on both sides; adding :math:`i\omega_fC_f`
   to both sides gives the second. For three dimensions, replace
   :math:`v_{g,f}\partial_y` by :math:`\mathbf v_{g,f}\cdot\nabla` and
   :math:`k_fv_{g,f}` by :math:`\mathbf k_f\cdot\mathbf v_{g,f}`:

   .. _k05-source-2-en:

   .. container:: k05-paper-match

      .. rubric:: K05 and reference [1], Eq. (2)

      .. k05:equation:: frequency-equation-3d
         :lang: en

         \mathbf v_{g,f}\cdot\nabla C_f
         =\bigl(\gamma_f+i\mathbf k_f\cdot\mathbf v_{g,f}\bigr)C_f
         +\sum_{f_1+f_2=f}V^Q_{1,2}C_{f_1}C_{f_2}.

      **Original equation, original notation — [1], (2)**

      .. k05:equation:: paper-equation-2
         :lang: en

         \vec v_g\cdot\frac{\partial\hat\phi_f}{\partial\vec r}
         =(\gamma_f+i\vec k_r\cdot\vec v_g)\hat\phi_f
         +\sum_{f=f_1+f_2}V^Q_{1,2}\hat\phi_{f_1}\hat\phi_{f_2}.

      **Symbol map.** The article's :math:`\hat\phi_f(\vec r)` is our
      :math:`C_f(\mathbf r)`, the time-Fourier coefficient that still contains spatial
      phase. It is **not** the earlier slow envelope :math:`A_a`, despite the reused
      hat in the article. :math:`\vec k_r` means the real wavevector, our
      :math:`\mathbf k_f`; its subscript :math:`r` is not a coordinate index.
      :math:`f=\omega/(2\pi)` is ordinary frequency in Hz, while :math:`\omega`
      is angular frequency. The subscript :math:`f` labels components, not derivatives.

      The article keeps potential coefficients. K05 first derives the same equation
      for an ideal potential signal, then uses measured voltage coefficients in the
      experiment; this change of observable requires the response discussion on
      :ref:`measurement chain on page 06 <k05-experiment-observable-en>`. Replacing wavevector matching by frequency
      matching requires the single-branch correspondence stated above, not just an FFT.


   Here :math:`\mathbf r=(x,y,z)` is position, :math:`\nabla=(\partial_x,\partial_y,\partial_z)`
   is the spatial gradient, bold symbols are vectors and the dot is their scalar
   product. The subscript :math:`f` on the group velocity refers to the target wave.
   This is the form of Ref. |ref-en| Eq. (2). That reference calls the temporal
   coefficient :math:`\hat\phi_f` and writes the real wavevector as
   :math:`\mathbf k_r`. We use :math:`C_f` to distinguish it from the slow envelope
   :math:`A` on the first page: a time coefficient still contains spatial phase.
   The explicit Fourier normalization here is our teaching convention; any
   numerical use of the paper's coefficients must use a compatible normalization.

   The local modal model treats the coefficients as fixed over the time interval
   being decomposed. Strong time variation of those coefficients would require
   additional frequency convolutions.

   .. raw:: html

      </details>

   .. rubric:: 4. A second probe makes spatial comparison possible

   Using the notation of Ref. |ref-en|, name the two coefficients

   .. k05:equation:: probe-frequency-pair
      :lang: en

      X_f=C_f(y_1),\qquad Y_f=C_f(y_1+\Delta y).

   Both :math:`X_f` and :math:`Y_f` are complex voltage coefficients at the same
   frequency, obtained from synchronized records. Their magnitudes and phases
   provide different information. For the illustration, only phase changes.
   If growth is also present, their magnitudes can differ.

   A first view of the spatial derivative is the difference between the two
   coefficients divided by their separation:

   .. k05:equation:: probe-spatial-difference
      :lang: en

      \left.\frac{\partial C_f}{\partial y}\right|_{y_1}
      \approx\frac{Y_f-X_f}{\Delta y}.

   This approximation needs :math:`C_f` to vary little across the separation,
   including its phase. Even a constant envelope can have a rapidly rotating
   :math:`C_f`. Thus a small envelope change is not enough to justify this raw
   difference. Ref. |ref-en| uses a phase-aware discretization in Eqs. (3)–(4);
   the expression above only explains what spatial information two probes provide.

   .. rubric:: 5. The experimental signal is an ion-current signal

   So far the detectors were ideal potential detectors. Ref. |ref-en| uses
   **ion saturation probes** to estimate ion-density fluctuations, then uses a
   plasma-response approximation to relate density to potential. The chain is

   .. k05:equation:: probe-density-proxy
      :lang: en

      \frac{\delta I_{\mathrm{is}}}{I_{\mathrm{is},0}}
      \approx\frac{\delta n_i}{n_{i0}}
      \approx\frac{e\,\delta\Phi}{T_e}.

   :math:`I_{\mathrm{is}}` is the magnitude of the ion saturation current (A),
   :math:`n_i` is ion number density (:math:`\mathrm{m^{-3}}`), and subscript 0
   denotes a background value. The symbol :math:`\delta` denotes a small
   fluctuation; :math:`e>0` is the elementary charge (C), and :math:`T_e` is
   electron temperature expressed as an energy, here in joules. Each ratio is
   dimensionless. Equivalently, if temperature is quoted numerically in eV,
   the potential-to-temperature ratio can be written using volts and that eV value,
   as in the article.

   The first approximation needs the collecting geometry and other current-response
   factors to stay sufficiently stable. The second is the density–potential
   relation adopted for the EDI under the plasma conditions of Ref. |ref-en|;
   it is not a universal identity for every plasma fluctuation. Instrument gains
   and phase response must also be accounted for when comparing two records.

   We now have the connection: a moving field gives a time record; its Fourier
   coefficients retain spatial information; two records provide :math:`X_f` and
   :math:`Y_f` for the frequency-domain wave equation. The
   :ref:`next page <k05-statistics-en>` combines many records into power spectra,
   cross spectra and bispectra, and connects these averages to the wave equation.

   .. rubric:: References

   .. _k05-probe-reference-1-en:

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   The frequency equation and mode-mapping assumption are on printed p. 115101-2;
   the two-probe discretization is on p. 115101-3, and the density proxy on
   p. 115101-4. The explicit Fourier convention, intermediate algebra and
   interactive drawing are explanatory additions.


.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-probe-signals-zh:

   .. rubric:: 从移动的波到探针记录

   K05 要把波的演化与测量信号联系起来。:ref:`第一页面 <k05-wave-overview-zh>`
   说明波怎样移动、增长并相互作用，:ref:`第二页面 <k05-coefficients-zh>`
   解释这些系数从哪里来。现在把一个探测器固定在空间某处：
   **移动的波怎样变成一条时间记录，这条记录又怎样接到波动方程上？**
   本页面沿这条主线，走到 Brown 与 Jorns |ref-zh| 的公式 (2)。

   .. rubric:: 1. 固定探针，让波从它身边经过

   先看一列简单的实电势波：

   .. k05:equation:: travelling-potential
      :lang: zh

      \Phi(y,t)=\Phi_0\cos(ky-2\pi f_0t),\qquad
      \lambda=\frac{2\pi}{k},\quad \omega_0=2\pi f_0.

   大写 :math:`\Phi` 表示实数电势扰动，单位为伏特（V）；:math:`\Phi_0` 是峰值幅度。
   位置 :math:`y` 的单位是 m，时间 :math:`t` 的单位是 s。
   波数 :math:`k` 的单位是 rad/m；频率 :math:`f_0` 表示每秒振荡的周期数，单位为 Hz。
   波长 :math:`\lambda` 的单位是 m，角频率 :math:`\omega_0` 的单位是 rad/s。
   取 :math:`k>0`、:math:`f_0>0`，波峰就向 :math:`y` 增大的方向移动。

   放在 :math:`y=0` 的理想电势探测器，只记录经过这个点的数值。
   第二个探测器与它相隔 :math:`\Delta y>0`，会稍晚看到同一个波峰：

   .. k05:equation:: fixed-probe-traces
      :lang: zh

      s_1(t)=\Phi(0,t),\qquad s_2(t)=\Phi(\Delta y,t),\qquad
      \Delta t=\frac{k\Delta y}{2\pi f_0}.

   :math:`s_1` 和 :math:`s_2` 是两条时间曲线，:math:`\Delta t` 是选定波峰的传播延迟。
   这个例子中两处幅度相同。因此，两条记录之间有相位差，本身并不意味着波在增长。

   .. raw:: html

      <div class="k05-probes" data-k05-probes="zh">
        <img src="../../_static/K_Diagnostics/k05-probe-signals-zh.svg" alt="移动的正弦波经过两个固定位置，下方同步显示这两处的时间曲线。">
      </div>

   拖动时间滑块：上图波形上的两个点，就是下方两条时间曲线在当前时刻的数值。
   改变探针间距，两条曲线的延迟随之改变。完整的理想时间曲线已预先画出，竖线只标记当前时刻。
   这是电势信号示意，不是实验数据，也没有模拟离子饱和探针的完整响应。

   .. raw:: html

      <details class="k05-note"><summary>这张图实际使用什么波形？</summary>

   图使用 :k05:eq:`travelling-potential`，取 :math:`\Phi_0=1`、:math:`k=\pi`、
   :math:`f_0=0.5`，采用任意单位。因此波长 :math:`\lambda=2`，周期为 2，波峰速度为 1。
   两探针位于 :math:`y_1=0` 与 :math:`y_2=\Delta y`；间距滑块改变第二个位置。
   图中没有增长、阻尼或波间耦合。
   默认 :math:`\Delta y=0.5` 时，延迟为 0.5，空间相位推进为 :math:`k\Delta y=\pi/2`。

   .. raw:: html

      </details>

   .. rubric:: 2. 一个频率系数，同时保存幅值与相位

   真实时间曲线通常包含许多频率。**时间傅里叶分解（time Fourier decomposition）**
   把它写成简单振荡的叠加。为说清归一化，先考虑一条每隔时长 :math:`T` 重复的记录。
   它的频率为 :math:`f_m=m/T`，其中 :math:`m` 是整数：

   .. k05:equation:: time-fourier-series
      :lang: zh

      \begin{aligned}
      \Phi(y,t)&=\sum_{m=-\infty}^{\infty}C_{f_m}(y)e^{-i2\pi f_mt},\qquad f_m=\frac{m}{T},\\
      C_{f_m}(y)&=\frac{1}{T}\int_0^T\Phi(y,t)e^{+i2\pi f_mt}\,dt.
      \end{aligned}

   复系数 :math:`C_{f_m}(y)` 告诉我们：在位置 :math:`y`，这个频率成分有多大、相位是多少。
   第二行通过“乘以反向旋转的指数，再取平均”提取该系数；其他整数频率的贡献在平均中相消。
   :math:`i` 满足 :math:`i^2=-1`。因为有归一化因子 :math:`1/T`，
   :math:`\Phi` 与 :math:`C_f` 的单位都是 V。

   **这里只分解了时间，位置没有被消掉。** :math:`C_f(y)` 仍然是位置的函数，
   所以两支探针处的系数可以不同。以下用 :math:`f` 代表这个频率网格中的某一项。

   .. raw:: html

      <details class="k05-note"><summary>只有一个余弦时，这个复系数具体是什么？</summary>

   当 :math:`f_0` 落在频率网格上时，由欧拉公式得到

   .. k05:equation:: cosine-time-coefficients
      :lang: zh

      \begin{aligned}
      \Phi_0\cos(ky-2\pi f_0t)
      &=\frac{\Phi_0}{2}e^{iky}e^{-i2\pi f_0t}
      +\frac{\Phi_0}{2}e^{-iky}e^{+i2\pi f_0t},\\
      C_{f_0}(y)&=\frac{\Phi_0}{2}e^{iky},\qquad
      C_{-f_0}(y)=C_{f_0}(y)^*.
      \end{aligned}

   正频率系数的模是 :math:`\Phi_0/2`，相位是 :math:`ky`。
   另一半在负频率系数中；星号 :math:`*` 表示复共轭（complex conjugate）。
   两项加在一起才得到实数余弦。这个二分之一来自双边频率约定（two-sided convention）；
   若要报告单边峰值幅度，应取 :math:`2|C_{f_0}|`，不是 :math:`|C_{f_0}|`。

   负频率是表达实信号所需的配对项，也使“频率求和”可以包含差频，
   例如 :math:`f_1+(-f_2)=f_1-f_2`。负频率本身并不表示另一种传播方向。

   .. raw:: html

      </details>

   .. rubric:: 3. 按频率，把波动方程重新写一遍

   对其中一个频率成分，写成

   .. k05:equation:: time-component-derivatives
      :lang: zh

      \begin{aligned}
      \phi_f(y,t)&=C_f(y)e^{-i\omega_ft},\qquad \omega_f=2\pi f,\\
      \partial_t\phi_f&=-i\omega_fC_fe^{-i\omega_ft},\qquad
      \partial_y\phi_f=(\partial_yC_f)e^{-i\omega_ft}.
      \end{aligned}

   小写 :math:`\phi_f` 是实信号叠加中的一个复数项。与它不同，:math:`C_f` 中已不含快速时间振荡，
   但仍含空间相位。下标 :math:`f` 是频率标签，不表示求导。
   在固定位置，对时间求导就乘上 :math:`-i\omega_f`；对空间求导则作用于 :math:`C_f(y)`。

   两个分量相乘，时间指数里的频率相加。它们对目标频率 :math:`f` 的二次贡献为

   .. k05:equation:: time-product-convolution
      :lang: zh

      \begin{aligned}
      \phi_{f_1}\phi_{f_2}
      &=C_{f_1}C_{f_2}e^{-i2\pi(f_1+f_2)t},\\
      N_f&=\sum_{f_1+f_2=f}V^Q_{1,2}C_{f_1}C_{f_2}.
      \end{aligned}

   :math:`N_f` 表示目标频率上的全部二次贡献，单位 V/s。
   :math:`V^Q_{1,2}` 是每一对输入波的权重，在本页归一化下单位为 :math:`\mathrm{V^{-1}s^{-1}}`；
   :math:`Q` 表示二次（quadratic），1、2 是输入波的标签。
   求和包含满足 :math:`f_1+f_2=f` 的带正负号频率对。这就是第一页面波对求和的频率写法。

   文献 |ref-zh| 在这里还采用一个物理近似：每组参与作用的频率对，对应唯一一组满足原波矢条件的波矢对。
   这样才可以只用频率作标签。傅里叶变换本身不会保证这种对应关系；下面沿用这一限制。

   将上述表达代入一维波动方程 :k05:eq:`full-wave-equation-1d`。
   约去共同的时间因子后，两边的 :math:`-i\omega_fC_f` 相消，得到

   .. k05:equation:: frequency-equation-1d
      :lang: zh

      v_{g,f}\frac{\partial C_f}{\partial y}
      =\bigl(\gamma_f+i k_f v_{g,f}\bigr)C_f+N_f.

   :math:`v_{g,f}` 是沿 :math:`y` 方向的群速度（m/s），:math:`\gamma_f` 是幅值增长率（1/s），
   :math:`k_f` 是分配给频率 :math:`f` 的波数（rad/m）。它们就是前两页的物理量，
   现在改用频率标记。每一项的单位都是 V/s。

   这个方程描述的是 **某个频率成分随位置怎样变化**。
   :math:`ik_fv_{g,f}` 项保留空间相位推进，:math:`\gamma_f` 项改变幅值，
   :math:`N_f` 项描述其他波的作用。时间振荡被提出去了，并不是把时间变化设成了零。

   .. raw:: html

      <details class="k05-note"><summary>把相消过程写全，再推广到三维</summary>

   将 :k05:eq:`time-component-derivatives` 与 :k05:eq:`time-product-convolution`
   代入 :k05:eq:`full-wave-equation-1d`，再除以 :math:`e^{-i\omega_ft}`，完整中间步骤是

   .. k05:equation:: time-carrier-cancellation
      :lang: zh

      \begin{aligned}
      -i\omega_f C_f+v_{g,f}\partial_y C_f
      &=\gamma_f C_f+i(k_fv_{g,f}-\omega_f)C_f+N_f,\\
      v_{g,f}\partial_y C_f
      &=\gamma_f C_f+ik_fv_{g,f}C_f+N_f.
      \end{aligned}

   第一行保留两边的时间项；两边都加上 :math:`i\omega_fC_f`，就得到第二行。
   在三维中，把 :math:`v_{g,f}\partial_y` 换成 :math:`\mathbf v_{g,f}\cdot\nabla`，
   把 :math:`k_fv_{g,f}` 换成 :math:`\mathbf k_f\cdot\mathbf v_{g,f}`：

   .. _k05-source-2-zh:

   .. container:: k05-paper-match

      .. rubric:: K05 与文献 [1] 式 (2) 对照

      .. k05:equation:: frequency-equation-3d
         :lang: zh

         \mathbf v_{g,f}\cdot\nabla C_f
         =\bigl(\gamma_f+i\mathbf k_f\cdot\mathbf v_{g,f}\bigr)C_f
         +\sum_{f_1+f_2=f}V^Q_{1,2}C_{f_1}C_{f_2}.

      **文献原式与原符号 — [1], (2)**

      .. k05:equation:: paper-equation-2
         :lang: zh

         \vec v_g\cdot\frac{\partial\hat\phi_f}{\partial\vec r}
         =(\gamma_f+i\vec k_r\cdot\vec v_g)\hat\phi_f
         +\sum_{f=f_1+f_2}V^Q_{1,2}\hat\phi_{f_1}\hat\phi_{f_2}.

      **符号对照。** 文献的 :math:`\hat\phi_f(\vec r)` 对应这里的
      :math:`C_f(\mathbf r)`，是保留空间相位的时间 Fourier 系数。
      虽然文献再次使用帽子，它 **不是** 前面的慢包络 :math:`A_a`。
      :math:`\vec k_r` 是实波矢，对应 :math:`\mathbf k_f`；这里的下标
      :math:`r` 表示实部，不是某个坐标方向。
      :math:`f=\omega/(2\pi)` 是单位 Hz 的普通频率，:math:`\omega` 是角频率。
      下标 :math:`f` 标记频率分量，不表示求导。

      文献使用电势系数。K05 先对理想电势信号推导相同方程，实验计算再使用实测电压系数；
      更换观测量需要 :ref:`第06页测量链 <k05-experiment-observable-zh>` 的响应条件。
      把波矢匹配换成频率匹配，还需要前述单分支对应关系，不能只靠一次 FFT。


   :math:`\mathbf r=(x,y,z)` 是空间位置；:math:`\nabla=(\partial_x,\partial_y,\partial_z)`
   是空间梯度算符；粗体表示向量，点号表示点积。群速度的下标 :math:`f` 指目标波。
   这就是文献 |ref-zh| 公式 (2) 的形式。文献把时间傅里叶系数写成 :math:`\hat\phi_f`，
   把实波矢写成 :math:`\mathbf k_r`。本页暂用 :math:`C_f`，以免与第一页面的慢变包络
   :math:`A` 混淆：时间系数中仍然带着空间相位。
   本页明确给出的傅里叶归一化是一种讲解约定；数值使用文献系数时，必须采用兼容的归一化。

   这里的局部模式模型把各系数视为在被分解的时间区间内不随时间改变。
   若这些系数随时间显著变化，还会产生额外的频率卷积。

   .. raw:: html

      </details>

   .. rubric:: 4. 第二支探针带来了空间比较

   沿用文献 |ref-zh| 的记号，把两处系数命名为

   .. k05:equation:: probe-frequency-pair
      :lang: zh

      X_f=C_f(y_1),\qquad Y_f=C_f(y_1+\Delta y).

   :math:`X_f` 与 :math:`Y_f` 是同一频率、由同步记录得到的两个复电压系数。
   它们的模和相位提供不同信息。互动图中仅相位改变；如果同时有增长，幅值也可以不同。

   对空间导数的第一个直观近似，是“两个系数之差除以间距”：

   .. k05:equation:: probe-spatial-difference
      :lang: zh

      \left.\frac{\partial C_f}{\partial y}\right|_{y_1}
      \approx\frac{Y_f-X_f}{\Delta y}.

   这个近似要求 :math:`C_f` 在间距内变化足够小，**包括相位变化**。
   即使包络恒定，:math:`C_f` 也可能随空间快速转动，所以仅有包络变化小还不够。
   文献 |ref-zh| 公式 (3)–(4) 使用了考虑相位的离散化；
   上式仅用来说明两支探针提供什么空间信息。

   .. rubric:: 5. 实验中记录的是离子电流信号

   前面先用了理想电势探测器。文献 |ref-zh| 实际使用 **离子饱和探针（ion saturation probe）**
   估计离子密度扰动，再利用等离子体响应近似把密度与电势联系起来。这条联系可写为

   .. k05:equation:: probe-density-proxy
      :lang: zh

      \frac{\delta I_{\mathrm{is}}}{I_{\mathrm{is},0}}
      \approx\frac{\delta n_i}{n_{i0}}
      \approx\frac{e\,\delta\Phi}{T_e}.

   :math:`I_{\mathrm{is}}` 是离子饱和电流的大小（A），:math:`n_i` 是离子数密度
   （:math:`\mathrm{m^{-3}}`），下标 0 表示背景值。:math:`\delta` 表示小扰动，
   :math:`e>0` 是元电荷（C），:math:`T_e` 是用能量表示的电子温度，这里以焦耳计。
   每个比值都无量纲。若温度用 eV 的数值表达，也可以像文献那样，
   用伏特表示的电势数值除以该温度数值。

   第一个近似要求收集几何及其他电流响应因素足够稳定。
   第二个近似是文献 |ref-zh| 在相应等离子体条件下采用的 EDI 密度–电势关系，
   并非对任意等离子体扰动都成立的恒等式。比较两路记录时，还需考虑仪器的增益和相位响应。

   现在已经接通了这条关系：移动的场形成时间记录，傅里叶系数保留空间信息，
   两条记录提供频率域波动方程中的 :math:`X_f` 与 :math:`Y_f`。
   :ref:`下一页面 <k05-statistics-zh>` 把许多记录合成为功率谱（power spectrum）、互谱（cross spectrum）
   和双谱（bispectrum），再把这些平均量接回波动方程。

   .. rubric:: 参考文献

   .. _k05-probe-reference-1-zh:

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_。

   频率域方程及模式对应假设见纸面第 115101-2 页；双探针离散化见第 115101-3 页，
   密度代理关系见第 115101-4 页。本页明确的傅里叶约定、中间代数和互动图为补充讲解。
