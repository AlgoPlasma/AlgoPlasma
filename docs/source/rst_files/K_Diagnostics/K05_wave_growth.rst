.. K05 contribution history (Git author dates; edit times include timezone).
   2026-10-23 16:13 +08:00 | Yinjian Zhao | git 482110a190d6
   2026-10-27 16:16 +08:00 | Yinjian Zhao | git 1782aebfbe9c
   2026-11-03 09:08 +08:00 | Yinjian Zhao | git 52f1bfb880ab
   2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)

.. _k05-wave-growth-and-coupling:

01 · Wave growth and coupling
==============================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <script defer src="../../_static/K_Diagnostics/k05-wave-packet.js"></script>
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. |ref-en| raw:: html

   <a class="k05-cite" href="#k05-reference-1-en" aria-label="Reference 1">[1]</a>

.. |ref-zh| raw:: html

   <a class="k05-cite" href="#k05-reference-1-zh" aria-label="参考文献 1">[1]</a>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-wave-overview-en:

   .. rubric:: From a moving wave to Eq. (1)

   A wave can move, grow, and change through other waves. Equation (1) of
   Ref. |ref-en| puts these changes into one equation. We will build it
   in that order. Read straight through first; the expandable notes can wait.

   .. rubric:: 1. Separate the wave's height from its oscillation

   Start with a voltage wave along one direction:

   .. k05:equation:: real-wave
      :lang: en

      u(y,t)=h(y,t)\cos(ky-\omega t).

   Here :math:`u` is the real potential fluctuation, in volts (V);
   :math:`y` is position along the azimuthal direction, in metres (m);
   and :math:`t` is time, in seconds (s). The positive height :math:`h` is in V.
   The **wavenumber** :math:`k=2\pi/\lambda` tells us how closely crests
   are spaced; :math:`\lambda` is wavelength in m. The **angular frequency** :math:`\omega=2\pi f` tells us how fast the signal oscillates;
   :math:`f` is frequency in hertz (Hz). Thus :math:`k` is in rad/m and
   :math:`\omega` in rad/s; :math:`\pi` is the circle constant.

   The cosine makes the crests. The slowly changing height outlines the
   **envelope**. Moving crests and a moving envelope need not have the same speed.

   .. container:: k05-text

      The graph below draws exactly this product. The upper panel shows
      :math:`u(y,t)` in orange between the blue bounds :math:`+h(y,t)` and
      :math:`-h(y,t)`. The lower panel isolates :math:`\cos(ky-\omega t)`,
      whose values lie between :math:`-1` and :math:`+1`. At the same position
      and time, multiplying that cosine by the positive height :math:`h`
      gives the orange wave.

   .. raw:: html

      <div class="k05-wave" data-k05-wave="en">
        <img class="k05-wave-fallback" src="../../_static/K_Diagnostics/k05-wave-packet.svg" alt="An oscillating wave inside a broad dashed envelope.">
        <noscript>The static drawing remains available. Enable JavaScript to move the wave.</noscript>
      </div>

   *Illustrative wave packet, not experimental data.* Drag time first, then select
   growth or decay. The dashed envelope moves more slowly than the crests.
   All plot values use arbitrary units, so the display makes no claim about actual plasma-wave speeds.

   .. raw:: html

      <details class="k05-note"><summary>Height function used in the wave-packet drawing</summary>

   Here is the exact height function used to draw the graph:

   .. k05:equation:: gaussian-height
      :lang: en

      h(y,t)=\exp(\gamma t)\,
      \exp\!\left[-\frac{(y+2-0.7t)^2}{2(2.2)^2}\right],
      \qquad u(y,t)=h(y,t)\cos(5y-8t).

   The second exponential is a bell-shaped, **Gaussian envelope**: its centre
   moves from :math:`y=-2` to :math:`y=-2+0.7t`, and its width parameter is
   :math:`2.2`. The first factor changes its peak height, initially :math:`1`.
   Here :math:`\exp` is the exponential function, and :math:`\gamma` is the
   growth setting: :math:`0` for constant height, :math:`+0.12` for growth,
   and :math:`-0.12` for decay. The cosine uses :math:`k=5` and :math:`\omega=8`.
   These numbers use the plot's arbitrary length, time and voltage units.
   The physical meaning of the envelope speed and growth rate follows in step 3.


   .. raw:: html

      </details>

   .. rubric:: 2. Use one compact expression for height and phase

   It is easier to differentiate an exponential than a cosine. We write

   .. k05:equation:: complex-wave
      :lang: en

      \phi=Ae^{i\theta},\qquad \theta=ky-\omega t,\qquad u=\operatorname{Re}\phi.

   The **complex wave** :math:`\phi` contains the oscillation.
   Its **complex envelope** :math:`A` changes slowly; both have units V.
   :math:`\theta` is phase, in radians; :math:`i^2=-1`, :math:`e` is the
   exponential base, and :math:`\operatorname{Re}` means “take the real part.”
   For the simple cosine above, :math:`A=h`; allowing complex :math:`A` also
   allows a slowly changing phase. Its magnitude :math:`|A|` is the wave height.
   In Ref. |ref-en|, :math:`A` is written :math:`\hat\phi`. **Keep these distinct:**
   :math:`A` is the envelope; :math:`\phi` includes the fast oscillation.

   .. rubric:: 3. Follow the envelope as it moves

   Let :math:`v_g` be the **group velocity**, the envelope's speed in m/s;
   subscript :math:`g` means “group.” Following it gives the rate of change

   .. k05:equation:: linear-envelope
      :lang: en

      \underbrace{(\partial_t+v_g\partial_y)}_{\mathcal D_g}A=\gamma A.

   :math:`\partial_t` differentiates at fixed position; :math:`\partial_y`
   differentiates at fixed time. Their combination :math:`\mathcal D_g`
   follows the moving envelope. :math:`\gamma` is its **linear amplitude growth
   rate**, in :math:`\mathrm{s}^{-1}`: positive means growth,
   negative means decay. For constant :math:`\gamma`, the height along this
   motion varies as :math:`e^{\gamma t}`. Squared amplitude grows as
   :math:`e^{2\gamma t}`; amplitude and power growth rates differ by two.

   .. raw:: html

      <details class="k05-note"><summary>Why does following the envelope add a spatial derivative?</summary>

   For constant :math:`v_g`, follow the position :math:`y(t)=y_0+v_gt`, where
   :math:`y_0` is the starting position. The chain rule gives

   .. k05:equation:: chain-rule
      :lang: en

      \frac{d A(y(t),t)}{dt}
      =\frac{\partial A}{\partial t}
       +\frac{dy}{dt}\frac{\partial A}{\partial y}
      =\partial_t A+v_g\partial_y A.

   Here :math:`d/dt` is a total derivative along that path.
   Even a packet of constant height produces a changing signal at a fixed probe
   as it passes. That change alone is not evidence of growth.

   .. raw:: html

      </details>

   .. rubric:: 4. Allow other waves to change the envelope

   .. container:: k05-text

      Let :math:`a` label the wave whose change we want to calculate. Its envelope is
      :math:`A_a`, and its group velocity is :math:`v_{g,a}`.
      **The label** :math:`a` **selects a wave, not a differentiation variable.**
      To follow that particular wave, define

      .. k05:equation:: mode-derivative
         :lang: en

         \mathcal D_{g,a}\equiv\partial_t+v_{g,a}\partial_y,\qquad
         \frac{dA_a(y_a(t),t)}{dt}
         =\left.\mathcal D_{g,a}A_a\right|_{y=y_a(t)},\quad
         \frac{dy_a}{dt}=v_{g,a}.

      Here :math:`\equiv` means “is defined as”; :math:`y_a(t)` is the path we
      follow, and the vertical bar means evaluate at that position.
      This is a **total time derivative along a chosen path**.
      A fixed probe uses :math:`\partial_t`; following wave :math:`a` uses
      :math:`\mathcal D_{g,a}`. For wave :math:`b`, the corresponding operator is
      :math:`\mathcal D_{g,b}=\partial_t+v_{g,b}\partial_y`.
      Different group velocities mean different paths and therefore different
      derivatives. If the velocities are equal, these operators coincide.
      If the envelopes have no spatial dependence, they all reduce to
      :math:`\partial_t`.

   .. container:: k05-text

      Keep :math:`a` fixed. Let :math:`b,c` run over possible **input waves**.
      The leading nonlinear correction contains products of their envelopes:

      .. k05:equation:: quadratic-envelope
         :lang: en

         \mathcal D_{g,a}A_a=\gamma_a A_a+
         \sum_{b,c\;\mathrm{matched}}V^Q_{a;bc}A_bA_c
         =\gamma_a A_a+\sum_{(b,c)\in\mathcal S_a}V^Q_{a;bc}A_bA_c.

      :math:`\sum` means add terms; :math:`b,c` are **summation indices**,
      whereas :math:`a` stays fixed. “Matched” is a restriction on the allowed
      pairs, not another variable. :math:`\mathcal S_a` names that set of pairs;
      :math:`\in` means “belongs to.” :math:`\gamma_a` is the linear amplitude
      growth rate of wave :math:`a`.

      The complex **coupling coefficient** :math:`V^Q_{a;bc}` specifies how
      the pair :math:`b,c` affects :math:`a`; the semicolon separates output from
      inputs. Superscript :math:`Q` means *quadratic*, not charge or an exponent.
      Its units here are :math:`\mathrm{V}^{-1}\mathrm{s}^{-1}`, so
      :math:`V^Q_{a;bc}A_bA_c` has units V/s, just like the left side.
      Two input factors and one output give **three-wave coupling**; the two
      inputs may even be the same mode.

   Why select pairs? Their oscillations multiply as

   .. k05:equation:: phase-product
      :lang: en

      e^{i\theta_b}e^{i\theta_c}
      =e^{i[(k_b+k_c)y-(\omega_b+\omega_c)t]}.

   .. container:: k05-text

      To keep driving wave :math:`a` in step, the product must have its
      wavenumber and frequency. The ideal **resonance condition** is therefore

      .. k05:equation:: matched-pairs
         :lang: en

         \mathcal S_a=\{(b,c):\ k_b+k_c=k_a,\quad\omega_b+\omega_c=\omega_a\}.

      The braces mean “the set of pairs satisfying both conditions.”
      The labels themselves are normally just names; it is the wavenumbers
      and frequencies that add.

   .. raw:: html

      <details class="k05-note"><summary>Expand the sum: which input pairs are counted?</summary>

   Choose a finite illustration with
   wave labels :math:`j=1,2,3,4`, wavenumbers :math:`k_j=j k_0`, and
   angular frequencies :math:`\omega_j=j\omega_0`.
   Here :math:`j` is an integer label; :math:`k_0>0` and :math:`\omega_0>0`
   are a reference wavenumber and angular frequency, in rad/m and rad/s.
   For the fixed output :math:`a=4`, the allowed **ordered pairs** are
   :math:`(1,3),(2,2),(3,1)`. Thus

   .. k05:equation:: ordered-pair-sum
      :lang: en

      \begin{aligned}
      \sum_{(b,c)\in\mathcal S_4}V^Q_{4;bc}A_bA_c
      & =V^Q_{4;13}A_1A_3+V^Q_{4;22}A_2^2+V^Q_{4;31}A_3A_1\\
      & =(V^Q_{4;13}+V^Q_{4;31})A_1A_3+V^Q_{4;22}A_2^2.
      \end{aligned}

   The notation :math:`4;13` means output 4, inputs 1 and 3; “13” is not
   thirteen. A repeated input :math:`(2,2)` appears once. The two orders
   :math:`(1,3)` and :math:`(3,1)` appear separately in this convention.
   Because :math:`A_1A_3=A_3A_1`, we can combine their coefficients.
   If those coefficients are equal, their sum is twice either one.
   If we list each unordered pair only once, we must use the combined coefficient.
   There is no universal extra factor of two for every term.
   Here the shortcut :math:`b+c=4` works **only because we chose this harmonic
   family**; it is not a rule for arbitrary mode labels. This finite example
   omits all other modes.


   .. raw:: html

      </details>

   .. rubric:: 5. Put the fast oscillation back: this gives Eq. (1)

   Reference |ref-en| evolves :math:`\phi_a=A_ae^{i\theta_a}`, not just :math:`A_a`.
   Apply the product rule:

   .. k05:equation:: product-rule
      :lang: en

      \mathcal D_{g,a}\phi_a
      =e^{i\theta_a}\mathcal D_{g,a}A_a
       +i\underbrace{(k_av_{g,a}-\omega_a)}_{\mathcal D_{g,a}\theta_a}\phi_a.

   .. raw:: html

      <details class="k05-note"><summary>Differentiate the phase and its exponential</summary>

   Use :math:`\theta_a=k_a y-\omega_a t`. In this local carrier description,
   :math:`k_a` and :math:`\omega_a` are constants; the slow changes are in
   :math:`A_a`. At fixed position the phase changes at :math:`-\omega_a`;
   at fixed time its spatial slope is :math:`k_a`. The chain rule then gives

   .. k05:equation:: phase-derivatives
      :lang: en

      \begin{aligned}
      \partial_t\theta_a&=-\omega_a,\qquad \partial_y\theta_a=k_a,\\
      \mathcal D_{g,a}\theta_a&=\partial_t\theta_a+v_{g,a}\partial_y\theta_a
                             =-\omega_a+v_{g,a}k_a,\\
      \mathcal D_{g,a}e^{i\theta_a}&=i e^{i\theta_a}\mathcal D_{g,a}\theta_a
                            =i(k_av_{g,a}-\omega_a)e^{i\theta_a}.
      \end{aligned}

   For the last line, the rule is :math:`d(e^{i\theta})/d\theta=i e^{i\theta}`.
   The product rule for :math:`A_a e^{i\theta_a}` has two terms: differentiate
   :math:`A_a`, then differentiate its exponential. The second term is
   :math:`A_a i(k_av_{g,a}-\omega_a)e^{i\theta_a}`. Since
   :math:`A_a e^{i\theta_a}=\phi_a`, this is exactly the extra term in
   :k05:eq:`product-rule`.

   .. raw:: html

      </details>

   .. container:: k05-text

      Next use the matching conditions :k05:eq:`matched-pairs`. Each carrier
      phase is :math:`\theta_j=k_jy-\omega_jt`, where :math:`j` labels a wave.
      Adding the input phases adds their wavenumbers and frequencies.
      For a matched pair these sums equal those of the output wave:

   .. k05:equation:: matched-phase-product
      :lang: en

      \begin{aligned}
      \theta_b+\theta_c
        &=(k_b+k_c)y-(\omega_b+\omega_c)t\\
        &=k_a y-\omega_a t=\theta_a,\\[3pt]
      \phi_b\phi_c
        &=(A_be^{i\theta_b})(A_ce^{i\theta_c})\\
        &=A_bA_c e^{i(\theta_b+\theta_c)}
         =e^{i\theta_a}A_bA_c.
      \end{aligned}

   The first two lines use the two matching conditions. The last two use
   :math:`\phi_j=A_j e^{i\theta_j}` and the exponential rule
   :math:`e^x e^z=e^{x+z}`. Thus the product of the two full input waves is
   the product of their envelopes multiplied by the output carrier factor.

   The **envelope equation being substituted is** :k05:eq:`quadratic-envelope`:
   it gives :math:`\mathcal D_{g,a}A_a`. Insert it into the product rule
   :k05:eq:`product-rule`, and use :k05:eq:`matched-phase-product` on each
   matched pair. The resulting **one-dimensional equation for the full wave** is

   .. k05:equation:: full-wave-equation-1d
      :lang: en

      \boxed{\begin{aligned}
      \partial_t\phi_a+v_{g,a}\partial_y\phi_a
       ={}&\gamma_a\phi_a+i(k_av_{g,a}-\omega_a)\phi_a\\
          &+\sum_{(b,c)\in\mathcal S_a}V^Q_{a;bc}\phi_b\phi_c.
      \end{aligned}}

   .. raw:: html

      <details class="k05-note"><summary>Substitute the envelope equation, term by term</summary>

   Start with :k05:eq:`product-rule`. Replace only its
   :math:`\mathcal D_{g,a}A_a` with the right side of
   :k05:eq:`quadratic-envelope`; keep the phase-derivative term:

   .. k05:equation:: envelope-substitution
      :lang: en

      \begin{aligned}
      \mathcal D_{g,a}\phi_a
       & =e^{i\theta_a}\left[\gamma_a A_a
             +\sum_{(b,c)\in\mathcal S_a}V^Q_{a;bc}A_bA_c\right]\\
       &\quad+i(k_av_{g,a}-\omega_a)\phi_a\\
       & =\gamma_a\phi_a
             +\sum_{(b,c)\in\mathcal S_a}V^Q_{a;bc}\phi_b\phi_c\\
       &\quad+i(k_av_{g,a}-\omega_a)\phi_a.
      \end{aligned}

   In the last two lines, :math:`e^{i\theta_a}A_a=\phi_a` converts the linear
   term. The factor :math:`e^{i\theta_a}` multiplies every summand, and
   :k05:eq:`matched-phase-product` converts each
   :math:`e^{i\theta_a}A_bA_c` to :math:`\phi_b\phi_c`.
   The coefficients :math:`\gamma_a` and :math:`V^Q_{a;bc}` are multiplied,
   not differentiated, in this substitution.

   Finally write the left side as
   :math:`\mathcal D_{g,a}\phi_a=\partial_t\phi_a+v_{g,a}\partial_y\phi_a`.
   This gives :k05:eq:`full-wave-equation-1d`, with all three contributions
   still present: linear growth, carrier-phase change and coupling.

   .. raw:: html

      </details>

   Now allow motion in three dimensions. Replace the directional derivative
   :math:`v_{g,a}\partial_y` by :math:`\mathbf v_{g,a}\cdot\nabla`, and
   replace :math:`k_a v_{g,a}` by :math:`\mathbf k_a\cdot\mathbf v_{g,a}`.
   The matching rule now adds wavevectors. The same steps give

   .. _k05-source-1-en:

   .. container:: k05-paper-match

      .. rubric:: K05 and reference [1], Eq. (1)

      .. k05:equation:: full-wave-equation
         :lang: en

         \boxed{\begin{aligned}
         \partial_t\phi_a+\mathbf v_{g,a}\cdot\nabla\phi_a
         ={}&\gamma_a\phi_a
           +i(\mathbf k_a\cdot\mathbf v_{g,a}-\omega_a)\phi_a\\
         &+\sum_{\substack{\mathbf k_b+\mathbf k_c=\mathbf k_a\\
                            \omega_b+\omega_c=\omega_a}}
              V^Q_{a;bc}\phi_b\phi_c .
         \end{aligned}}

      **Original equation, original notation — [1], (1)**

      .. k05:equation:: paper-equation-1
         :lang: en

         \begin{aligned}
         \frac{\partial\phi(\vec k,\omega)}{\partial t}
         +\vec v_g\cdot\frac{\partial\phi(\vec k,\omega)}{\partial\vec r}
         &=\gamma_\omega\phi(\vec k,\omega)
         +i(\vec k\cdot\vec v_g-\omega)\phi(\vec k,\omega)\\
         &\quad+\sum_{\substack{\omega=\omega_1+\omega_2\\\vec k=\vec k_1+\vec k_2}}
         V^Q_{1,2}\phi(\vec k_1,\omega_1)\phi(\vec k_2,\omega_2).
         \end{aligned}

      **Symbol map.** The article's :math:`\phi(\vec k,\omega)` is our
      :math:`\phi_a`: one full complex wave component, still depending on position
      and time. Its slow amplitude :math:`\hat\phi(\vec k,\omega)` is our :math:`A_a`.
      The labels :math:`1,2` are our input-wave labels :math:`b,c`; the target label
      :math:`a` on :math:`V^Q_{a;bc}` is left implicit in the article.
      :math:`\gamma_\omega` is our :math:`\gamma_a`, an amplitude rate in s⁻¹.
      :math:`\vec r` and :math:`\mathbf r` denote the same position vector;
      :math:`\partial/\partial\vec r` means the spatial gradient :math:`\nabla`.
      The superscript :math:`Q` means quadratic, not a power of :math:`V`.

      **What this buys us.** The three right-hand terms distinguish growth,
      carrier-phase evolution and exchange between wave components. Recovering the
      carrier from the envelope explains the extra imaginary term; it is not extra
      amplitude growth. The response derivation continues on
      :ref:`page 02 <k05-coefficients-en>`.


   Bold :math:`\mathbf k` and :math:`\mathbf v_g` are the wavevector
   and group-velocity vector. :math:`\nabla` is the spatial gradient;
   :math:`\cdot` is a dot product. Thus
   :math:`\mathbf v_g\cdot\nabla` follows motion along the group velocity.
   The one-dimensional phase becomes :math:`\theta_a=\mathbf k_a\cdot\mathbf r-\omega_at`,
   with position vector :math:`\mathbf r`, in m. In Ref. |ref-en|,
   :math:`\phi(\mathbf k,\omega)` is our :math:`\phi_a`, and its
   :math:`V^Q_{1,2}` is our :math:`V^Q_{a;bc}`.

   Read the result from left to right: **change following the envelope = linear
   growth + fast-phase change + coupling to other waves**. Every term has units
   V/s. The phase term is purely imaginary and does not by itself change
   :math:`|\phi_a|^2`. Equation :k05:eq:`full-wave-equation` recovers Eq. (1) of Ref. |ref-en|; the plasma response
   supplies the coefficients, whose origin is derived on the next page.

   .. raw:: html

      <span id="equation-k05-dielectric-expansion-en"></span>
      <span id="equation-k05-response-coefficients-en"></span>

   .. rubric:: What comes next

   The next page, :ref:`Where the envelope equation comes from <k05-coefficients-en>`,
   starts with how a potential wave makes the plasma respond. It then derives
   the envelope's motion, the linear growth rate and the quadratic coupling
   coefficient, one step at a time. The three-dimensional results are
   :k05:eq:`dielectric-expansion` and :k05:eq:`response-coefficients`.

   .. container:: k05-text

      A time Fourier transform then connects this wave equation to records
      at fixed probe positions.

   .. container:: k05-text

      .. rubric:: References

      .. _k05-reference-1-en:

      [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
      Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
      115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

      This page follows Eq. (1) and its discussion on p. 115101-2 of Ref. |ref-en|.
      The intermediate steps and interactive drawing are teaching additions.

.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-wave-overview-zh:

   .. rubric:: 从一列移动的波，到公式 (1)

   一列波会移动，会增长，也会受到其他波的影响。文献 |ref-zh| 的公式 (1)
   把这些变化写在一起。我们按这个顺序建立它。先顺着正文读，展开的补充可以稍后看。

   .. rubric:: 1. 把波的高度和振荡分开

   先看沿一个方向传播的电压波：

   .. k05:equation:: real-wave
      :lang: zh

      u(y,t)=h(y,t)\cos(ky-\omega t).

   :math:`u` 是真实的电势扰动（potential fluctuation），单位伏特 V；
   :math:`y` 是方位方向（azimuthal direction）的位置，单位米 m；
   :math:`t` 是时间，单位秒 s。正数 :math:`h` 是波的高度，单位 V。
   **波数（wavenumber）** :math:`k=2\pi/\lambda` 描述波峰有多密，
   :math:`\lambda` 是波长，单位 m。
   **角频率（angular frequency）** :math:`\omega=2\pi f` 描述振荡有多快，
   :math:`f` 是频率，单位赫兹 Hz。因此 :math:`k` 的单位是 rad/m，
   :math:`\omega` 的单位是 rad/s；:math:`\pi` 是圆周率。

   余弦产生波峰；缓慢变化的高度画出 **包络（envelope）**。
   波峰和包络不一定以相同的速度移动。

   .. container:: k05-text

      下面的图画的正是这个乘积。上图的橙色曲线是 :math:`u(y,t)`，
      蓝色虚线分别是 :math:`+h(y,t)` 和 :math:`-h(y,t)`；
      下图单独画出 :math:`\cos(ky-\omega t)`，其值在 :math:`-1` 与 :math:`+1` 之间。
      在同一位置、同一时刻，把下图的余弦值乘以上图的正高度 :math:`h`，就得到橙色波形。

   .. raw:: html

      <div class="k05-wave" data-k05-wave="zh">
        <img class="k05-wave-fallback" src="../../_static/K_Diagnostics/k05-wave-packet.svg" alt="一列振荡波被宽阔的虚线包络包围。">
        <noscript>当前显示静态图；启用 JavaScript 后可移动波形。</noscript>
      </div>

   *这是波包（wave packet）示意，不是实验数据。* 先拖动时间，再选择增长或衰减。
   虚线包络移动得比波峰慢。所有图中数值使用任意单位，不代表实际等离子体波的传播速度。

   .. raw:: html

      <details class="k05-note"><summary>画图实际使用的高度函数是什么？</summary>

   画图实际使用的高度函数是

   .. k05:equation:: gaussian-height
      :lang: zh

      h(y,t)=\exp(\gamma t)\,
      \exp\!\left[-\frac{(y+2-0.7t)^2}{2(2.2)^2}\right],
      \qquad u(y,t)=h(y,t)\cos(5y-8t).

   第二个指数函数是钟形的 **高斯包络（Gaussian envelope）**：中心从 :math:`y=-2`
   移到 :math:`y=-2+0.7t`，宽度参数为 :math:`2.2`。
   第一个因子改变包络的峰值高度，初始峰值为 :math:`1`。
   :math:`\exp` 表示指数函数，:math:`\gamma` 对应增长选项：
   高度不变时为 :math:`0`，增长时为 :math:`+0.12`，衰减时为 :math:`-0.12`。
   余弦取 :math:`k=5`、:math:`\omega=8`。
   这些数值采用图中的任意长度、时间和电压单位；包络速度与增长率的物理意义在第 3 步继续讲。


   .. raw:: html

      </details>

   .. rubric:: 2. 用一个紧凑表达式描述高度和相位

   指数函数比余弦更方便求导，因此写成

   .. k05:equation:: complex-wave
      :lang: zh

      \phi=Ae^{i\theta},\qquad \theta=ky-\omega t,\qquad u=\operatorname{Re}\phi.

   **复波形（complex wave）** :math:`\phi` 含有快速振荡，
   **复包络（complex envelope）** :math:`A` 则缓慢变化；二者单位都是 V。
   :math:`\theta` 是相位（phase），单位弧度；:math:`i^2=-1`，:math:`e` 是指数函数的底，
   :math:`\operatorname{Re}` 表示取实部。对刚才的简单余弦，:math:`A=h`；
   允许 :math:`A` 为复数，还能描述缓慢变化的相位。模 :math:`|A|` 就是波的高度。
   文献 |ref-zh| 把 :math:`A` 写成 :math:`\hat\phi`。
   **请区分这两个量：** :math:`A` 是包络，:math:`\phi` 才包含快速振荡。

   .. rubric:: 3. 跟着包络一起移动

   用 **群速度（group velocity）** :math:`v_g` 表示包络的移动速度，单位 m/s；
   下标 :math:`g` 代表 group。跟着包络看，它的变化率满足

   .. k05:equation:: linear-envelope
      :lang: zh

      \underbrace{(\partial_t+v_g\partial_y)}_{\mathcal D_g}A=\gamma A.

   :math:`\partial_t` 是固定位置的时间偏导，:math:`\partial_y` 是固定时间的空间偏导。
   合起来的 :math:`\mathcal D_g` 表示沿移动包络的变化率。
   :math:`\gamma` 是 **线性幅值增长率（linear amplitude growth rate）**，单位
   :math:`\mathrm{s}^{-1}`：正值增长，负值衰减。若 :math:`\gamma` 为常数，
   沿这个运动路径，波的高度按 :math:`e^{\gamma t}` 变化，幅值平方则按
   :math:`e^{2\gamma t}` 变化；幅值增长率与功率增长率相差因子 2。

   .. raw:: html

      <details class="k05-note"><summary>为什么跟着包络走，会多出一个空间导数？</summary>

   对常数 :math:`v_g`，运动路径是 :math:`y(t)=y_0+v_gt`，:math:`y_0` 是初始位置。
   链式法则（chain rule）给出

   .. k05:equation:: chain-rule
      :lang: zh

      \frac{d A(y(t),t)}{dt}
      =\frac{\partial A}{\partial t}
       +\frac{dy}{dt}\frac{\partial A}{\partial y}
      =\partial_t A+v_g\partial_y A.

   :math:`d/dt` 是沿路径的全导数。即使一个波包的高度保持不变，它经过固定探针时，
   信号也会变化。因此，固定点的信号变化本身不能证明波正在增长。

   .. raw:: html

      </details>

   .. rubric:: 4. 加上其他波对包络的作用

   .. container:: k05-text

      用 :math:`a` 标记我们正在研究的目标波。它的包络是 :math:`A_a`，群速度是
      :math:`v_{g,a}`。**下标** :math:`a` **是在选择哪一列波，不是求导变量。**
      跟着这列波走，需要定义

      .. k05:equation:: mode-derivative
         :lang: zh

         \mathcal D_{g,a}\equiv\partial_t+v_{g,a}\partial_y,\qquad
         \frac{dA_a(y_a(t),t)}{dt}
         =\left.\mathcal D_{g,a}A_a\right|_{y=y_a(t)},\quad
         \frac{dy_a}{dt}=v_{g,a}.

      :math:`\equiv` 表示“定义为”；:math:`y_a(t)` 是跟随的路径，竖线表示在该位置取值。
      这是 **沿所选路径对时间求全导数（total time derivative along a path）**。
      固定探针用 :math:`\partial_t`；跟着波 :math:`a` 用 :math:`\mathcal D_{g,a}`。
      跟着波 :math:`b` 则用 :math:`\mathcal D_{g,b}=\partial_t+v_{g,b}\partial_y`。
      各波群速度可能不同，所走的路径不同，导数就需要区分。
      如果群速度相同，这些算符就相同；如果包络完全不依赖空间，它们都简化为
      :math:`\partial_t`。

   .. container:: k05-text

      接下来，**固定目标** :math:`a`，让 :math:`b,c` 遍历可能的输入波（input waves）。
      最低阶的非线性修正包含两个包络的乘积：

      .. k05:equation:: quadratic-envelope
         :lang: zh

         \mathcal D_{g,a}A_a=\gamma_a A_a+
         \sum_{b,c\;\mathrm{matched}}V^Q_{a;bc}A_bA_c
         =\gamma_a A_a+\sum_{(b,c)\in\mathcal S_a}V^Q_{a;bc}A_bA_c.

      :math:`\sum` 是“把各项加起来”；:math:`b,c` 是 **求和下标（summation indices）**，
      :math:`a` 在整个求和中保持不变。matched 是筛选条件，不是第三个求和变量。
      :math:`\mathcal S_a` 表示允许的波对集合，:math:`\in` 表示“属于”。
      :math:`\gamma_a` 是目标波 :math:`a` 的线性幅值增长率。

      复数 **耦合系数（coupling coefficient）** :math:`V^Q_{a;bc}` 描述输入波对
      :math:`b,c` 对目标 :math:`a` 的作用；分号把输出与输入分开。
      上标 :math:`Q` 表示 quadratic（二次），不是电荷或幂。
      这里单位是 :math:`\mathrm{V}^{-1}\mathrm{s}^{-1}`，所以
      :math:`V^Q_{a;bc}A_bA_c` 的单位是 V/s，与左边相同。
      两个输入因子作用于一个输出，称为 **三波耦合（three-wave coupling）**；
      两个输入也可以来自同一个模式。

   为什么筛选波对？因为它们的振荡相乘得到

   .. k05:equation:: phase-product
      :lang: zh

      e^{i\theta_b}e^{i\theta_c}
      =e^{i[(k_b+k_c)y-(\omega_b+\omega_c)t]}.

   .. container:: k05-text

      若要持续“跟上”目标波 :math:`a`，乘积就需要具有相同的波数和频率。
      因此理想的 **共振条件（resonance condition）** 是

      .. k05:equation:: matched-pairs
         :lang: zh

         \mathcal S_a=\{(b,c):\ k_b+k_c=k_a,\quad\omega_b+\omega_c=\omega_a\}.

      花括号表示“满足这两个条件的波对组成的集合”。一般情况下，标签只是名字；
      真正相加的是波数与频率。

   .. raw:: html

      <details class="k05-note"><summary>展开求和：哪些输入波对会被计入？</summary>

   选一个有限的示例，波标签为 :math:`j=1,2,3,4`，
   令 :math:`k_j=j k_0`、:math:`\omega_j=j\omega_0`。
   :math:`j` 是整数标签，:math:`k_0>0`、:math:`\omega_0>0` 是参考波数与参考角频率，
   单位分别为 rad/m、rad/s。固定目标 :math:`a=4` 后，允许的
   **有序波对（ordered pairs）** 是 :math:`(1,3),(2,2),(3,1)`。因此

   .. k05:equation:: ordered-pair-sum
      :lang: zh

      \begin{aligned}
      \sum_{(b,c)\in\mathcal S_4}V^Q_{4;bc}A_bA_c
      & =V^Q_{4;13}A_1A_3+V^Q_{4;22}A_2^2+V^Q_{4;31}A_3A_1\\
      & =(V^Q_{4;13}+V^Q_{4;31})A_1A_3+V^Q_{4;22}A_2^2.
      \end{aligned}

   记号 :math:`4;13` 表示输出 4、输入 1 和 3，其中“13”不是十三。
   相同输入 :math:`(2,2)` 只出现一次；:math:`(1,3)` 和 :math:`(3,1)` 在本约定下分别出现。
   因为 :math:`A_1A_3=A_3A_1`，可以把两项的系数合并。
   如果这两个系数相等，合并后就是其中一个的两倍；若只列一次无序波对
   （unordered pair），就必须使用合并后的系数。不能给每一项一概多乘一个 2。
   这里能直接检查 :math:`b+c=4`，**仅因为选定了这组谐波（harmonics）**，
   不代表任意波标签都可以相加。这个有限示例不包含其他模式。


   .. raw:: html

      </details>

   .. rubric:: 5. 放回快速振荡，就得到公式 (1)

   文献 |ref-zh| 研究的是 :math:`\phi_a=A_ae^{i\theta_a}`，不只是 :math:`A_a`。
   对乘积求导（product rule）：

   .. k05:equation:: product-rule
      :lang: zh

      \mathcal D_{g,a}\phi_a
      =e^{i\theta_a}\mathcal D_{g,a}A_a
       +i\underbrace{(k_av_{g,a}-\omega_a)}_{\mathcal D_{g,a}\theta_a}\phi_a.

   .. raw:: html

      <details class="k05-note"><summary>展开相位和指数因子的求导过程</summary>

   从 :math:`\theta_a=k_a y-\omega_a t` 开始。在这里的局部载波描述中，
   :math:`k_a`、:math:`\omega_a` 是常数，缓慢变化放在包络 :math:`A_a` 中。
   固定位置对时间求导，得到 :math:`-\omega_a`；固定时间对位置求导，得到 :math:`k_a`。
   再用链式法则（chain rule）：

   .. k05:equation:: phase-derivatives
      :lang: zh

      \begin{aligned}
      \partial_t\theta_a&=-\omega_a,\qquad \partial_y\theta_a=k_a,\\
      \mathcal D_{g,a}\theta_a&=\partial_t\theta_a+v_{g,a}\partial_y\theta_a
                             =-\omega_a+v_{g,a}k_a,\\
      \mathcal D_{g,a}e^{i\theta_a}&=i e^{i\theta_a}\mathcal D_{g,a}\theta_a
                            =i(k_av_{g,a}-\omega_a)e^{i\theta_a}.
      \end{aligned}

   最后一行用到 :math:`d(e^{i\theta})/d\theta=i e^{i\theta}`。
   对 :math:`A_a e^{i\theta_a}` 使用乘积法则（product rule），分成两项：
   一项对 :math:`A_a` 求导，另一项对指数因子求导。后一项是
   :math:`A_a i(k_av_{g,a}-\omega_a)e^{i\theta_a}`。
   用 :math:`A_a e^{i\theta_a}=\phi_a` 合并，就得到 :k05:eq:`product-rule` 中的相位项。

   .. raw:: html

      </details>

   .. container:: k05-text

      接下来使用匹配条件 :k05:eq:`matched-pairs`。
      每一列波的载波相位都是 :math:`\theta_j=k_jy-\omega_jt`，其中 :math:`j` 是波的标签。
      两个输入相位相加，就把各自的波数、频率分别相加。
      对匹配波对，这两个和恰好等于目标波的波数、频率：

   .. k05:equation:: matched-phase-product
      :lang: zh

      \begin{aligned}
      \theta_b+\theta_c
        &=(k_b+k_c)y-(\omega_b+\omega_c)t\\
        &=k_a y-\omega_a t=\theta_a,\\[3pt]
      \phi_b\phi_c
        &=(A_be^{i\theta_b})(A_ce^{i\theta_c})\\
        &=A_bA_c e^{i(\theta_b+\theta_c)}
         =e^{i\theta_a}A_bA_c.
      \end{aligned}

   前两行使用两个匹配条件；后两行使用 :math:`\phi_j=A_j e^{i\theta_j}`，
   以及指数的乘法规则 :math:`e^x e^z=e^{x+z}`。
   因此，两个完整输入波的乘积，等于两个输入包络的乘积再乘上目标波的载波因子。

   **这里代入的包络方程是** :k05:eq:`quadratic-envelope`，它给出
   :math:`\mathcal D_{g,a}A_a`。将它代入乘积求导式 :k05:eq:`product-rule`，
   并对每个匹配波对使用 :k05:eq:`matched-phase-product`，先得到
   **完整波形的一维演化方程（one-dimensional wave-evolution equation）**：

   .. k05:equation:: full-wave-equation-1d
      :lang: zh

      \boxed{\begin{aligned}
      \partial_t\phi_a+v_{g,a}\partial_y\phi_a
       ={}&\gamma_a\phi_a+i(k_av_{g,a}-\omega_a)\phi_a\\
          &+\sum_{(b,c)\in\mathcal S_a}V^Q_{a;bc}\phi_b\phi_c.
      \end{aligned}}

   .. raw:: html

      <details class="k05-note"><summary>逐项展开：怎样代入包络方程？</summary>

   从 :k05:eq:`product-rule` 出发，只把其中的 :math:`\mathcal D_{g,a}A_a`
   替换成 :k05:eq:`quadratic-envelope` 的右边，相位求导项先保持原样：

   .. k05:equation:: envelope-substitution
      :lang: zh

      \begin{aligned}
      \mathcal D_{g,a}\phi_a
       & =e^{i\theta_a}\left[\gamma_a A_a
             +\sum_{(b,c)\in\mathcal S_a}V^Q_{a;bc}A_bA_c\right]\\
       &\quad+i(k_av_{g,a}-\omega_a)\phi_a\\
       & =\gamma_a\phi_a
             +\sum_{(b,c)\in\mathcal S_a}V^Q_{a;bc}\phi_b\phi_c\\
       &\quad+i(k_av_{g,a}-\omega_a)\phi_a.
      \end{aligned}

   最后两行中，线性项用 :math:`e^{i\theta_a}A_a=\phi_a` 合并。
   因子 :math:`e^{i\theta_a}` 乘进求和的每一项，再用 :k05:eq:`matched-phase-product`
   把每个 :math:`e^{i\theta_a}A_bA_c` 换成 :math:`\phi_b\phi_c`。
   这一步只是代入并相乘，没有对系数 :math:`\gamma_a` 或 :math:`V^Q_{a;bc}` 求导。

   最后，把左边写开：
   :math:`\mathcal D_{g,a}\phi_a=\partial_t\phi_a+v_{g,a}\partial_y\phi_a`。
   这就得到 :k05:eq:`full-wave-equation-1d`；线性增长、载波相位变化、波间耦合三项都保留下来。

   .. raw:: html

      </details>

   现在允许波包在三维空间移动。把沿一个方向的导数 :math:`v_{g,a}\partial_y`
   换成 :math:`\mathbf v_{g,a}\cdot\nabla`，把 :math:`k_a v_{g,a}`
   换成 :math:`\mathbf k_a\cdot\mathbf v_{g,a}`；匹配条件中的波数相加换成波矢相加。
   相同的步骤就给出三维方程：

   .. _k05-source-1-zh:

   .. container:: k05-paper-match

      .. rubric:: K05 与文献 [1] 式 (1) 对照

      .. k05:equation:: full-wave-equation
         :lang: zh

         \boxed{\begin{aligned}
         \partial_t\phi_a+\mathbf v_{g,a}\cdot\nabla\phi_a
         ={}&\gamma_a\phi_a
           +i(\mathbf k_a\cdot\mathbf v_{g,a}-\omega_a)\phi_a\\
         &+\sum_{\substack{\mathbf k_b+\mathbf k_c=\mathbf k_a\\
                            \omega_b+\omega_c=\omega_a}}
              V^Q_{a;bc}\phi_b\phi_c .
         \end{aligned}}

      **文献原式与原符号 — [1], (1)**

      .. k05:equation:: paper-equation-1
         :lang: zh

         \begin{aligned}
         \frac{\partial\phi(\vec k,\omega)}{\partial t}
         +\vec v_g\cdot\frac{\partial\phi(\vec k,\omega)}{\partial\vec r}
         &=\gamma_\omega\phi(\vec k,\omega)
         +i(\vec k\cdot\vec v_g-\omega)\phi(\vec k,\omega)\\
         &\quad+\sum_{\substack{\omega=\omega_1+\omega_2\\\vec k=\vec k_1+\vec k_2}}
         V^Q_{1,2}\phi(\vec k_1,\omega_1)\phi(\vec k_2,\omega_2).
         \end{aligned}

      **符号对照。** 文献的 :math:`\phi(\vec k,\omega)` 对应这里的
      :math:`\phi_a`：一个完整的复波动分量，仍依赖位置和时间。
      它的慢变幅值 :math:`\hat\phi(\vec k,\omega)` 对应 :math:`A_a`。
      输入波标签 :math:`1,2` 对应 :math:`b,c`；文献把 :math:`V^Q_{a;bc}`
      中的目标波标签 :math:`a` 省略了。:math:`\gamma_\omega` 对应
      :math:`\gamma_a`，是单位 s⁻¹ 的幅值增长率。
      :math:`\vec r` 与 :math:`\mathbf r` 都是位置矢量，
      :math:`\partial/\partial\vec r` 就是空间梯度 :math:`\nabla`。
      :math:`Q` 表示二次（quadratic），不是 :math:`V` 的幂。

      **这一式连接了什么？** 右侧分别描述增长、载波相位变化和波分量之间的耦合。
      恢复载波产生额外的虚数项，它不是额外的幅值增长。
      系数的响应推导接在 :ref:`第 02 页 <k05-coefficients-zh>`。


   粗体 :math:`\mathbf k` 与 :math:`\mathbf v_g` 分别是波矢（wavevector）和群速度矢量。
   :math:`\nabla` 是空间梯度（spatial gradient），:math:`\cdot` 是点积（dot product），
   因而 :math:`\mathbf v_g\cdot\nabla` 表示沿群速度方向移动产生的变化率。
   三维相位为 :math:`\theta_a=\mathbf k_a\cdot\mathbf r-\omega_at`，
   :math:`\mathbf r` 是位置矢量，单位 m。文献 |ref-zh| 的 :math:`\phi(\mathbf k,\omega)` 对应这里的
   :math:`\phi_a`，:math:`V^Q_{1,2}` 对应 :math:`V^Q_{a;bc}`。

   从左向右读：**跟着包络看到的变化 = 线性增长 + 快相位变化 + 其他波的耦合。**
   每项单位都是 V/s。相位项是纯虚数系数，本身不会改变 :math:`|\phi_a|^2`。
   :k05:eq:`full-wave-equation` 就是文献 |ref-zh| 中公式 (1) 的形式；其中系数的物理来源将在下一页面推导。

   .. raw:: html

      <span id="equation-k05-dielectric-expansion-zh"></span>
      <span id="equation-k05-response-coefficients-zh"></span>

   .. rubric:: 下一步

   下一页面 :ref:`包络方程和系数从哪里来 <k05-coefficients-zh>`，
   从“电势波怎样引起等离子体响应”开始，逐步推导包络的运动、线性增长率和二次耦合系数。
   最后得到三维结果 :k05:eq:`dielectric-expansion` 与 :k05:eq:`response-coefficients`，
   补上本页面所用包络方程的物理起点。

   .. container:: k05-text

      有了这层基础，再通过时间傅里叶变换（time Fourier transform）连接固定探针的时间记录。

   .. container:: k05-text

      .. rubric:: 参考文献

      .. _k05-reference-1-zh:

      [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
      Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
      115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_。

      本页面依据文献 |ref-zh| 第 115101-2 页公式 (1) 及相关讨论；中间推导与互动示意为教学补充。

