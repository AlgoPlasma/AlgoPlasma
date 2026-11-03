02 · Envelope equation
========================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css?v=r31-review">
   <script defer src="../../_static/K_Diagnostics/k05-packet-band.js"></script>
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. |ref-en| raw:: html

   <a class="k05-cite" href="#k05-coefficients-reference-1-en" aria-label="Reference 1">[1]</a>

.. |ref-zh| raw:: html

   <a class="k05-cite" href="#k05-coefficients-reference-1-zh" aria-label="参考文献 1">[1]</a>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-coefficients-en:

   .. rubric:: Where the envelope equation comes from

   The :ref:`previous page <k05-wave-overview-en>` separated a wave into a fast
   oscillation and a slowly changing envelope. It used a group velocity, a growth
   rate and a coupling coefficient to describe that envelope. **What fixes these
   quantities?** The answer starts with how the electrons and ions respond to an
   electric potential.

   This page develops that missing step in the model used by Brown and Jorns
   |ref-en|. We first keep one spatial direction and one wave, then add the effect
   of other waves. The detailed calculations can be expanded as needed.

   .. rubric:: 1. A wave must agree with the charge motion it produces

   A potential variation produces an electric field. The field moves charged
   particles, changing the charge density. That charge must, in turn, produce the
   same potential through Poisson's equation. A freely evolving wave must satisfy
   this **self-consistency** requirement.

   .. container:: k05-r31-revised

      For a small sinusoidal wave in a locally uniform background, the linearized
      plasma equations package this requirement into a response function :math:`D(k,\omega)`. It is dimensionless
      in our convention and is called the **linear dielectric response**. Its form
      depends on the plasma: particle distributions, temperatures, drifts and magnetic
      field. It must be obtained from a physical model; the wave shape alone does not
      determine it.

   Recall that :math:`k` is the wavenumber along :math:`y`, in rad/m, and
   :math:`\omega` is angular frequency, in rad/s. We choose a real carrier frequency
   using the real part of the response:

   .. k05:equation:: response-carrier
      :lang: en

      D(k,\omega)=D_r(k,\omega)+iD_i(k,\omega),\qquad
      D_r(k,\omega)=0.

   Subscripts :math:`r` and :math:`i` mean real and imaginary parts;
   the separate :math:`i` multiplying :math:`D_i` satisfies :math:`i^2=-1`.
   The equation :math:`D_r=0` relates frequency to wavenumber: it is the real
   **dispersion relation** used here. The small imaginary response :math:`D_i`
   will account for slow growth or decay. Ref. |ref-en| writes these parts as
   :math:`\epsilon_r^{(1)}` and :math:`\epsilon_i^{(1)}`; superscript :math:`(1)`
   means first order in wave amplitude.

   .. raw:: html

      <details class="k05-note"><summary>How does Poisson's equation produce D?</summary>

   For a nonzero plane-wave wavenumber, write the first-order charge response as

   .. k05:equation:: poisson-response
      :lang: en

      \begin{aligned}
      \epsilon_0 k^2\phi&=\rho^{(1)},\qquad
      \rho^{(1)}=-\epsilon_0 k^2\sum_s\chi_s(k,\omega)\phi,\\
      D(k,\omega)\phi&=0,\qquad D=1+\sum_s\chi_s.
      \end{aligned}

   Here :math:`\phi` is the complex potential amplitude including its carrier,
   in volts (V); :math:`\rho^{(1)}` is the first-order charge-density fluctuation,
   in :math:`\mathrm{C/m^3}`; and :math:`\epsilon_0` is vacuum permittivity,
   in F/m. The dimensionless **susceptibility** :math:`\chi_s` measures the
   response of species :math:`s`, such as electrons or ions. The sum includes
   the species in the model. The first line defines the sign convention for
   :math:`\chi_s`; moving its right side to the left gives the second line.

   .. raw:: html

      <details class="k05-note k05-r31-added"><summary>Derive these lines: Poisson's equation and the response convention</summary>

   The electric field along :math:`y` is :math:`E_y`, in V/m. Gauss's law relates
   its spatial derivative to charge density. For a single Fourier component
   :math:`\phi\propto e^{i(ky-\omega t)}`, each :math:`y` derivative contributes
   :math:`ik`, so two derivatives give :math:`-k^2`:

   .. k05:equation:: poisson-response-steps
      :lang: en

      \begin{aligned}
      E_y&=-\partial_y\phi,\qquad \partial_yE_y=\rho^{(1)}/\epsilon_0,\\
      \partial_y^2\phi&=-\rho^{(1)}/\epsilon_0,\qquad
      \partial_y^2\phi=-k^2\phi,\\
      \epsilon_0k^2\phi&=-\epsilon_0k^2\left(\sum_s\chi_s\right)\phi,\\
      \left(1+\sum_s\chi_s\right)\phi&=0.
      \end{aligned}

   The second line therefore gives :math:`\epsilon_0 k^2\phi=\rho^{(1)}`.
   For each species, the linear response is written
   :math:`\rho_s^{(1)}=-\epsilon_0 k^2\chi_s\phi`.
   This **defines the normalization and sign of** :math:`\chi_s`; Poisson's
   equation alone does not calculate its value. Sum the species responses and
   substitute them to get the third line. Move everything to the left and divide
   by :math:`\epsilon_0k^2\ne0` to get the last line. The coefficient in parentheses
   is named :math:`D`. No division by :math:`D` is involved.

   .. raw:: html

      </details>

   For a nonzero wave, :math:`D\phi=0` requires :math:`D=0`. With a weak imaginary
   response, we use :math:`D_r=0` for the real carrier and keep :math:`D_i` in
   the envelope evolution. The full complex-frequency root is considered below.
   In a magnetized plasma, this :math:`D` is the electrostatic response for the
   chosen propagation direction; :math:`\chi_s` may depend on that direction.
   Computing it requires solving the linearized fluid or kinetic equations
   together with Poisson's equation. No particular susceptibility model is assumed
   in the algebra that follows.

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note k05-r31-added"><summary>A simple susceptibility: cold electrons with fixed ions</summary>

   Consider a uniform plasma with no magnetic field, collisions or equilibrium
   drift. Ignore electron pressure and let the ions supply a fixed neutralizing
   background. This illustrative cold-electron model gives [2]

   .. k05:equation:: cold-electron-susceptibility
      :lang: en

      \chi_e=-\frac{\omega_{pe}^2}{\omega^2},\qquad
      \omega_{pe}^2=\frac{n_0e^2}{\epsilon_0m_e},\qquad
      D=1+\chi_e=1-\frac{\omega_{pe}^2}{\omega^2}.

   Here :math:`n_0` is the equilibrium electron number density (m⁻³),
   :math:`e>0` is the elementary charge (C), :math:`m_e` is electron mass (kg),
   and :math:`\omega_{pe}` is the electron plasma angular frequency (rad/s).
   The electron charge is :math:`-e`; both :math:`\chi_e` and :math:`D` are dimensionless.

   To see where the expression comes from, let :math:`\delta u_e` be the electron
   velocity perturbation (m/s) and :math:`\delta n_e` its density perturbation (m⁻³).
   The symbol :math:`\delta` means a small departure from equilibrium. Newton's law
   and particle conservation, linearized about the stationary uniform state, give

   .. k05:equation:: cold-electron-fluid-response
      :lang: en

      \begin{aligned}
      m_e\partial_t\delta u_e&=-eE_y,\qquad
      \partial_t\delta n_e+n_0\partial_y\delta u_e=0,\\
      -i\omega m_e\delta u_e&=ie k\phi,\qquad
      -i\omega\delta n_e+ikn_0\delta u_e=0,\\
      \delta u_e&=-\frac{ek}{m_e\omega}\phi,\qquad
      \delta n_e=-\frac{n_0ek^2}{m_e\omega^2}\phi,\\
      \rho_e^{(1)}&=-e\delta n_e=
      \frac{n_0e^2k^2}{m_e\omega^2}\phi
      =-\epsilon_0k^2\chi_e\phi.
      \end{aligned}

   Insert :math:`E_y=-ik\phi`, :math:`\partial_t\to-i\omega` and
   :math:`\partial_y\to ik` to obtain the second line. Solve for velocity, then
   density. Comparing the last line with the response convention identifies
   :math:`\chi_e`. Thus susceptibility summarizes the chain
   **potential → particle motion → charge response**.

   For example, at :math:`\omega=2\omega_{pe}`, :math:`\chi_e=-1/4` and
   :math:`D=3/4`. This is a response evaluated at a trial frequency, not a free
   self-consistent wave. Imposing :math:`D=0` selects
   :math:`\omega^2=\omega_{pe}^2`. The negative susceptibility is not a negative
   density; it is the response coefficient in the stated convention.
   This example explains the notation; the magnetized, drifting model in [1]
   requires a different susceptibility.

   .. raw:: html

      </details>

   .. rubric:: 2. A slowly changing envelope contains nearby waves

   .. container:: k05-text

      An exactly uniform envelope gives one sinusoid. A broad, slowly varying packet
      is made from wavenumbers concentrated near a carrier. In the illustration below,
      the component frequencies also stay close because they lie on one smooth
      dispersion branch.

   .. container:: k05-text

      At the packet centre the input waves reinforce one another. Away from the centre,
      their slightly different wavelengths gradually put them out of step, and many
      contributions cancel. **Closer wavenumbers take a longer distance to lose phase
      alignment, so their sum has a wider envelope.**

      Drag the spectral-width slider first. The top panel shows the band of
      wavenumbers; the middle panel selects three representative waves from that band;
      the bottom panel shows the weighted sum over the whole band. The three middle
      curves are displayed with unit heights to make their phases easy to compare;
      the packet is not the sum of only those three curves.

      .. raw:: html

         <div class="k05-band" data-k05-band="en">
           <img src="../../_static/K_Diagnostics/k05-packet-band-en.svg" alt="A narrow Gaussian band of wavenumbers produces a broad wave packet; three representative input waves align near its centre.">
           <noscript>This is the default static view. Enable JavaScript to change the spectral width and time.</noscript>
         </div>

      All axes use arbitrary units. This is a superposition illustration with constant
      peak height, not experimental data. The width readouts refer to Gaussian
      amplitude profiles, not power spectra. Changing time moves the packet without
      changing its width in this deliberately linear dispersion model.

      .. raw:: html

         <details class="k05-note"><summary>The exact functions behind this illustration</summary>

      The carrier uses :math:`k_0=5`, :math:`\omega_0=8`, and :math:`v_g=0.7`;
      subscript :math:`0` marks the carrier values. Each input has a wavenumber
      :math:`k_0+q`, where :math:`q` is its offset from the carrier, in the same
      units as :math:`k_0`. Its weight and frequency are

      .. k05:equation:: packet-band-spectrum
         :lang: en

         W(q)=\frac{1}{\sqrt{2\pi}\sigma_k}
         \exp\!\left(-\frac{q^2}{2\sigma_k^2}\right),\qquad
         \omega(k_0+q)=\omega_0+v_gq.

      :math:`W` is a Gaussian amplitude-weight density, normalized so that
      :math:`\int W(q)\,dq=1`. The positive parameter :math:`\sigma_k` sets its
      wavenumber width, and the slider varies it from 0.15 to 0.60. The spectral panel
      plots the relative weight :math:`W(q)/W(0)`, against :math:`k_0+q`.
      The straight-line relation for :math:`\omega` means that a wavenumber offset
      :math:`q` has frequency offset :math:`\nu=v_gq`.

      Adding the real input waves gives an exactly known Gaussian packet:

      .. k05:equation:: packet-band-sum
         :lang: en

         \begin{aligned}
         u(y,t)&=h_0\int_{-\infty}^{\infty}W(q)
         \cos\!\left[(k_0+q)y-(\omega_0+v_gq)t\right]dq\\
         &=\underbrace{h_0\exp\!\left[-\frac{\sigma_k^2(y-v_gt)^2}{2}\right]}_{h(y,t)}
         \cos(k_0y-\omega_0t),\\
         \sigma_y&=\frac{1}{\sigma_k},\qquad \sigma_\omega=|v_g|\sigma_k.
         \end{aligned}

      The integral sign means add all inputs, with weights :math:`W(q)\,dq`.
      The peak voltage :math:`h_0` is set to 1. The envelope's spatial width is
      :math:`\sigma_y`, and the amplitude-weight frequency width is
      :math:`\sigma_\omega`; their units are length and inverse time. In physical
      units, :math:`\sigma_k` is in rad/m, :math:`\sigma_\omega` in rad/s, and
      :math:`W` has the reciprocal units of wavenumber. Doubling :math:`\sigma_k`
      halves :math:`\sigma_y` and doubles :math:`\sigma_\omega` in this model.
      The Gaussian has small tails rather than a sharp band edge.

      This is the same height-times-cosine structure as :k05:eq:`real-wave`.
      Unlike the earlier illustration, its centre starts at zero and there is no
      growth. The choice of a linear dispersion branch removes spreading and makes
      the relation between the two widths easy to see.

      .. raw:: html

         </details>

   .. container:: k05-text

      To examine one nearby component mathematically, write:

   .. k05:equation:: nearby-carrier
      :lang: en

      \begin{aligned}
      A(y,t)&=A_0 e^{i(qy-\nu t)},\\
      \phi(y,t)&=A(y,t)e^{i(ky-\omega t)}
      =A_0 e^{i[(k+q)y-(\omega+\nu)t]}.
      \end{aligned}

   :math:`A_0` is a constant complex voltage. The small offsets :math:`q` and
   :math:`\nu` have units rad/m and rad/s; they describe slow variation of the
   envelope :math:`A`. Multiplying by the carrier adds these offsets to
   :math:`k` and :math:`\omega`. This component is a tool for deriving the
   equation; a general envelope is a superposition of such components.

   Differentiation retrieves the offsets:

   .. k05:equation:: offset-derivatives
      :lang: en

      \begin{aligned}
      \partial_y A&=iqA, & qA&=-i\partial_y A,\\
      \partial_t A&=-i\nu A, & \nu A&=i\partial_t A.
      \end{aligned}

   Thus multiplying an envelope component by :math:`q` has the same effect as
   applying :math:`-i\partial_y`; multiplying by :math:`\nu` has the same effect
   as applying :math:`i\partial_t`. Here :math:`\partial_y` holds time fixed,
   and :math:`\partial_t` holds position fixed. These signs follow from the
   chosen carrier :math:`e^{i(ky-\omega t)}`.

   Now expand the response close to the carrier:

   .. k05:equation:: response-taylor
      :lang: en

      \begin{aligned}
      D(k+q,\omega+\nu)
      &\simeq D(k,\omega)+(\partial_k D)q+(\partial_\omega D)\nu\\
      &\simeq iD_i+(\partial_k D_r)q+(\partial_\omega D_r)\nu.
      \end{aligned}

   The sign :math:`\simeq` means “approximately equal.” The first line is a
   first-order Taylor expansion: it keeps the local slopes and omits terms
   quadratic and higher in the offsets. In the second line, :math:`D_r=0`
   leaves :math:`iD_i` as the constant term. We also neglect the small
   derivative contributions from :math:`D_i`.

   .. container:: k05-text

      .. raw:: html

         <details class="k05-note"><summary class="k05-r31-revised">Keep the second-order Taylor terms: what was omitted?</summary>

      .. raw:: html

         <span id="equation-k05-taylor-one-parameter-en"></span>

      .. k05:equation:: taylor-second-order
         :lang: en

         \begin{aligned}
         D(k+q,\omega+\nu)
         ={}&D+q\,\partial_kD+\nu\,\partial_\omega D\\
         &+\frac{1}{2}\left[q^2\partial_k^2D
         +2q\nu\,\partial_k\partial_\omega D
         +\nu^2\partial_\omega^2D\right]+\mathcal R_3.
         \end{aligned}

      .. container:: k05-r31-revised

         Every derivative on the right is evaluated at :math:`(k,\omega)`.
         :math:`\partial_k^2D` measures curvature in the wavenumber direction;
         :math:`\partial_\omega^2D` measures curvature in the frequency direction.
         The **mixed derivative** :math:`\partial_k\partial_\omega D` measures how
         one slope changes when the other input changes. For a smooth response,
         the mixed part inside the bracket is
         :math:`q\nu\,\partial_k\partial_\omega D+\nu q\,\partial_\omega\partial_kD`;
         the two mixed derivatives agree, giving the factor 2.
         The remainder :math:`\mathcal R_3` contains cubic and higher-order
         contributions in the offsets. Keeping that remainder makes this an equality;
         a finite Taylor polynomial alone is generally only an approximation.

      There are two distinct approximations in :k05:eq:`response-taylor`.
      The first line discards the second-order bracket and :math:`\mathcal R_3`.
      The second line also drops derivatives of the imaginary response. Before
      that second simplification, the first-order terms are

      .. k05:equation:: taylor-real-imaginary
         :lang: en

         \begin{aligned}
         D(k+q,\omega+\nu)
         ={}&\left[D_r+q\,\partial_kD_r+\nu\,\partial_\omega D_r\right]\\
         &+i\left[D_i+q\,\partial_kD_i+\nu\,\partial_\omega D_i\right]
         +\mathcal R_2.
         \end{aligned}

      Here :math:`\mathcal R_2` includes all the second-order and higher terms
      shown in :k05:eq:`taylor-second-order`. Set only :math:`D_r=0` at the
      carrier: the terms :math:`iq\partial_kD_i` and
      :math:`i\nu\partial_\omega D_i` are still present. They disappear from
      :k05:eq:`response-taylor` only under the additional weak-response ordering.
      A small value of :math:`D_i` at one point does not guarantee small slopes.

      .. raw:: html

         </details>

   Every response coefficient here is evaluated at the chosen real
   :math:`(k,\omega)`. The partial derivative :math:`\partial_k` holds
   :math:`\omega` fixed; :math:`\partial_\omega` holds :math:`k` fixed.
   Multiply this expansion by :math:`A`, set the linear response to zero,
   and use :k05:eq:`offset-derivatives`. The result is

   .. k05:equation:: linear-response-1d
      :lang: en

      iD_iA-i(\partial_k D_r)\partial_y A
      +i(\partial_\omega D_r)\partial_t A=0.

   .. container:: k05-text

      The numbers :math:`q` and :math:`\nu` have not literally turned into
      derivatives. We have rewritten their action on a component of the envelope.
      Before that replacement, multiply :k05:eq:`response-taylor` by :math:`A`:

      .. k05:equation:: offset-substitution-terms
         :lang: en

         \begin{aligned}
         0&\simeq iD_iA+(\partial_kD_r)qA+(\partial_\omega D_r)\nu A,\\
         (\partial_kD_r)qA&=(\partial_kD_r)(-i\partial_yA),\\
         (\partial_\omega D_r)\nu A&=(\partial_\omega D_r)(i\partial_tA).
         \end{aligned}

      Read the second line as “multiply this component by its wavenumber offset”
      or, equivalently, “differentiate it in space and multiply by :math:`-i`.”
      The third line does the same for the frequency offset and time derivative.
      The term :math:`iD_iA` stays unchanged. Substituting those two equalities
      in the first line gives exactly :k05:eq:`linear-response-1d`.

      An envelope can contain many components with different offsets. A single
      number :math:`q` cannot describe them all, but differentiation automatically
      multiplies each component by its own :math:`iq`; time differentiation does
      the corresponding operation with :math:`-i\nu`. Adding the components
      therefore gives one equation for the entire envelope :math:`A(y,t)`.

   .. rubric:: 3. Read the speed and growth rate from that equation

   Assume :math:`\partial_\omega D_r\ne0`, so division is possible.
   Divide :k05:eq:`linear-response-1d` by :math:`i\partial_\omega D_r`
   and move the term proportional to :math:`A` to the right:

   .. k05:equation:: linear-coefficients-1d
      :lang: en

      \boxed{\begin{aligned}
      \partial_t A+v_g\partial_y A&=\gamma A,\\
      v_g&=-\frac{\partial_k D_r}{\partial_\omega D_r},\qquad
      \gamma=-\frac{D_i}{\partial_\omega D_r}.
      \end{aligned}}

   This is the linear envelope equation :k05:eq:`linear-envelope` used on the
   previous page. The coefficient of :math:`\partial_y A` is the **group
   velocity** :math:`v_g`; the coefficient of :math:`A` is the **amplitude
   growth rate** :math:`\gamma`. They are now determined by the plasma response.

   The units check directly: :math:`\partial_kD_r` has units m,
   :math:`\partial_\omega D_r` has units s, so :math:`v_g` is in m/s and
   :math:`\gamma` in :math:`\mathrm{s}^{-1}`. Positive :math:`\gamma`
   increases the amplitude along the moving envelope. Its sign depends on both
   :math:`D_i` and :math:`\partial_\omega D_r`.

   .. raw:: html

      <details class="k05-note"><summary>Why is this speed the slope of the dispersion curve?</summary>

   Write the carrier frequency along one real dispersion branch as
   :math:`\omega=\Omega(k)`. The new symbol :math:`\Omega` names that function,
   so we can distinguish a total derivative along the curve from a partial
   derivative of :math:`D_r`:

   .. k05:equation:: group-velocity-chain
      :lang: en

      \begin{aligned}
      0=\frac{d}{dk}D_r(k,\Omega(k))
      &=(\partial_k D_r)_\omega+(\partial_\omega D_r)_k\frac{d\Omega}{dk},\\
      \frac{d\Omega}{dk}&=-\frac{\partial_k D_r}{\partial_\omega D_r}=v_g.
      \end{aligned}

   The first line is the chain rule applied to :math:`D_r(k,\Omega(k))=0`.
   The subscripts on parentheses state what is held fixed. After differentiation,
   evaluate both partial derivatives at :math:`\omega=\Omega(k)`.
   Solving for :math:`d\Omega/dk` gives precisely the coefficient in
   :k05:eq:`linear-coefficients-1d`. This is why the envelope speed equals
   the local slope of the dispersion curve.

   .. raw:: html

      </details>
      <details class="k05-note"><summary>Why does the imaginary response give growth or decay?</summary>

   A complex frequency :math:`\omega+i\gamma` adds exponential amplitude
   change to the time oscillation. Expanding the full dispersion equation about
   the real carrier, with the same weak-response ordering, gives

   .. raw:: html

      <span id="equation-k05-growth-retained-terms-en"></span>

   .. raw:: html

      <span id="equation-k05-growth-size-comparison-en"></span>

   .. raw:: html

      <span id="equation-k05-growth-complex-correction-en"></span>

   .. k05:equation:: weak-growth-root
      :lang: en

      \begin{aligned}
      D(k,\omega+i\gamma)&\simeq iD_i+i\gamma\partial_\omega D_r=0,\\
      \gamma&\simeq-\frac{D_i}{\partial_\omega D_r},\qquad
      e^{-i(\omega+i\gamma)t}=e^{-i\omega t}e^{\gamma t}.
      \end{aligned}

   The last equality shows the sign explicitly: positive :math:`\gamma`
   produces :math:`e^{\gamma t}`. Amplitude squared changes as
   :math:`e^{2\gamma t}`, so its growth rate is twice the amplitude growth rate.
   This is a leading-order approximation to the complex root. We have neglected,
   among other terms, :math:`-\gamma\partial_\omega D_i`; this requires a
   weak imaginary response and suitable derivative ordering, not merely a small
   ratio :math:`|\gamma/\omega|`. The chosen real carrier need not be exactly
   the real part of the full complex root.

   .. raw:: html

      </details>

   .. rubric:: 4. Other waves add a second-order charge response

   So far the charge response was linear in the potential. Keeping the next
   order adds products of two wave amplitudes. Physically, the fields of the
   waves perturb particle motion, and that perturbed motion changes how the
   plasma responds to the fields. A second-order calculation retains these
   products.

   Call their contribution to the envelope's field equation
   :math:`\mathcal N^{(2)}`. It is a normalized charge-response term, with
   units V; superscript :math:`(2)` means second order in wave amplitude.
   We define its sign by placing it on the left:

   .. k05:equation:: quadratic-response-1d
      :lang: en

      iD_iA-i(\partial_k D_r)\partial_y A
      +i(\partial_\omega D_r)\partial_t A+\mathcal N^{(2)}=0.

   **This is new physical input.** Taylor-expanding the linear function
   :math:`D` explains the derivative terms, but does not generate the quadratic
   response. That response must be calculated from the second-order plasma
   equations.

   For an output wave :math:`a`, collect the input pairs from
   :k05:eq:`matched-pairs`:

   .. k05:equation:: quadratic-source
      :lang: en

      \mathcal N^{(2)}_a
      =\sum_{(b,c)\in\mathcal S_a}K^{(2)}_{a;bc}A_bA_c.

   :math:`A_b` and :math:`A_c` are the input envelopes, each in V;
   :math:`\mathcal S_a` is the allowed set of pairs from the previous page.
   The response coefficient :math:`K^{(2)}_{a;bc}` has units
   :math:`\mathrm{V}^{-1}`. It may be complex. Its indices identify the output
   :math:`a` and inputs :math:`b,c`; the semicolon separates them. It uses
   the same ordered-pair convention as :k05:eq:`ordered-pair-sum`.

   Dividing :k05:eq:`quadratic-response-1d` by
   :math:`i(\partial_\omega D_r)_a` now gives

   .. k05:equation:: coupling-coefficient
      :lang: en

      \begin{aligned}
      (\partial_t+v_{g,a}\partial_y)A_a
      &=\gamma_a A_a+\sum_{(b,c)\in\mathcal S_a}V^Q_{a;bc}A_bA_c,\\
      V^Q_{a;bc}&=\frac{iK^{(2)}_{a;bc}}{(\partial_\omega D_r)_a}.
      \end{aligned}

   The subscript :math:`a` on the denominator means evaluate the derivative
   at :math:`(k_a,\omega_a)`. The plus sign in front of the new term follows
   from :math:`-1/i=i` when moving it to the right. Superscript :math:`Q`
   means quadratic. Its units are :math:`\mathrm{V}^{-1}\mathrm{s}^{-1}`,
   so each coupling term is in V/s. This recovers
   :k05:eq:`quadratic-envelope` with an explicit origin for every coefficient.

   .. raw:: html

      <details class="k05-note"><summary>How is the quadratic term related to charge density?</summary>

   Continue the Poisson convention of :k05:eq:`poisson-response`, retaining
   the quadratic charge source at output mode :math:`a`. This source contains
   products of the input waves; the charge response linear in the output
   potential is already included in :math:`D`:

   .. k05:equation:: quadratic-poisson
      :lang: en

      \begin{aligned}
      \epsilon_0 k_a^2\phi_a&=\rho^{(1)}_a+\rho^{(2)}_a,\\
      D_a\phi_a-\frac{\rho^{(2)}_a}{\epsilon_0 k_a^2}&=0,\qquad
      \rho^{(2)}_a=R^{(2)}_a e^{i\theta_a},\\
      \mathcal N^{(2)}_a&=-\frac{R^{(2)}_a}{\epsilon_0 k_a^2}.
      \end{aligned}

   :math:`D_a` is the response at that mode, and :math:`k_a\ne0` is its
   carrier wavenumber. The charge fluctuation :math:`\rho^{(2)}_a` and its slow
   complex envelope :math:`R^{(2)}_a` have units :math:`\mathrm{C/m^3}`;
   :math:`\theta_a=k_a y-\omega_a t` is the carrier phase. Remove the common
   factor :math:`e^{i\theta_a}` and expand the linear response as before.
   At the retained order, the last line gives the term used in
   :k05:eq:`quadratic-response-1d`; envelope corrections to its normalization
   are higher order.

   .. container:: k05-text

      To go from the first line of :k05:eq:`quadratic-poisson` to its second line,
      insert the linear charge response from :k05:eq:`poisson-response`.
      Write :math:`\chi_{s,a}=\chi_s(k_a,\omega_a)` for the susceptibility of
      species :math:`s` evaluated at the output carrier:

      .. k05:equation:: poisson-source-rearrangement
         :lang: en

         \begin{aligned}
         \rho_a^{(1)}&=-\epsilon_0k_a^2
         \left(\sum_s\chi_{s,a}\right)\phi_a,\\
         \epsilon_0k_a^2\phi_a
         &=-\epsilon_0k_a^2\left(\sum_s\chi_{s,a}\right)\phi_a+\rho_a^{(2)},\\
         \left(1+\sum_s\chi_{s,a}\right)\phi_a
         &=\frac{\rho_a^{(2)}}{\epsilon_0k_a^2},\\
         \underbrace{\left(1+\sum_s\chi_{s,a}\right)}_{D_a}\phi_a
         -\frac{\rho_a^{(2)}}{\epsilon_0k_a^2}&=0.
         \end{aligned}

      The second line is substitution. To obtain the third, move the negative
      linear-response term to the left, combine its coefficient with 1, and divide
      by the nonzero :math:`\epsilon_0k_a^2`. In the fourth line, recognize
      :math:`D_a=1+\sum_s\chi_{s,a}` and move the quadratic source to the left.
      The source has not been dropped: it is precisely the term with the minus sign.

   .. container:: k05-r31-added

      **Now obtain the last line: remove the carrier and identify the source.**
      Use :math:`\phi_a=A_a e^{i\theta_a}` and
      :math:`\rho_a^{(2)}=R_a^{(2)}e^{i\theta_a}`. For a packet, the compact linear
      response in :k05:eq:`quadratic-poisson` must also be expanded about the carrier,
      as in :k05:eq:`linear-response-1d`; it is not enough to replace it by a constant
      :math:`D_a A_a`. To keep the substitution readable, call that already-derived
      linear combination :math:`\mathcal L_a A_a`:

      .. k05:equation:: quadratic-envelope-source-steps
         :lang: en

         \begin{aligned}
         \mathcal L_a A_a&\equiv iD_{i,a}A_a
         -i(\partial_kD_r)_a\partial_yA_a
         +i(\partial_\omega D_r)_a\partial_tA_a,\\
         0&\simeq e^{i\theta_a}\left[\mathcal L_a A_a
         -\frac{R_a^{(2)}}{\epsilon_0k_a^2}\right],\\
         0&=\mathcal L_a A_a+\mathcal N_a^{(2)},\qquad
         \mathcal N_a^{(2)}=-\frac{R_a^{(2)}}{\epsilon_0k_a^2}.
         \end{aligned}

      The first line only abbreviates the three linear terms; subscript :math:`a`
      on their coefficients means evaluation at :math:`(k_a,\omega_a)`.
      The second line substitutes both carrier factors and the linear expansion into
      the rearranged Poisson equation. Since :math:`e^{i\theta_a}\ne0`, divide it out.
      Compare what remains with :k05:eq:`quadratic-response-1d`, whose convention is
      “linear terms + :math:`\mathcal N_a^{(2)}` = 0.” The leftover negative fraction
      is therefore :math:`\mathcal N_a^{(2)}`. Its units are volts, matching the linear
      terms; it becomes a rate term only after division by the frequency derivative.

   The minus sign belongs to this definition of :math:`\mathcal N^{(2)}`.
   Changing the normalization of :math:`D` requires changing the nonlinear
   term consistently. This fixes the algebra and units; it does not supply a
   numerical value for :math:`K^{(2)}` without a second-order response model.

   .. raw:: html

      </details>

   .. rubric:: 5. Allow motion in three dimensions

   Nothing in the argument requires only one spatial direction. Replace
   :math:`k` by the wavevector :math:`\mathbf k`, and :math:`y` by the
   position vector :math:`\mathbf r`. The first-order spatial expansion becomes
   a dot product:

   .. k05:equation:: dielectric-expansion
      :lang: en

      iD_iA+i(\partial_\omega D_r)\partial_t A
      -i(\nabla_{\mathbf k}D_r)\cdot\nabla A
      +\mathcal N^{(2)}=0.

   Here :math:`\nabla` differentiates with respect to position, while
   :math:`\nabla_{\mathbf k}` differentiates with respect to wavevector at
   fixed frequency. The dot combines the three directional contributions.
   Dividing as before yields

   .. k05:equation:: response-coefficients
      :lang: en

      \begin{aligned}
      (\partial_t+\mathbf v_g\cdot\nabla)A
      &=\gamma A+\frac{i\mathcal N^{(2)}}{\partial_\omega D_r},\\
      \gamma&=-\frac{D_i}{\partial_\omega D_r},\qquad
      \mathbf v_g=-\frac{\nabla_{\mathbf k}D_r}{\partial_\omega D_r}.
      \end{aligned}

   :math:`\mathbf v_g` is the group-velocity vector, in m/s. For each output
   mode, insert :k05:eq:`quadratic-source` with the vector matching conditions,
   then restore :math:`\phi_a=A_a e^{i\theta_a}` as on the previous page.
   This gives :k05:eq:`full-wave-equation`, the form of Eq. (1) in Ref. |ref-en|.
   The carrier-phase term comes from that last product rule; the coefficients
   derived here govern the envelope itself.

   The derivation has deliberately left the second-order kernel symbolic.
   Computing it from a chosen velocity distribution would be a separate kinetic
   prediction. The experiment in [1] instead **estimates its effective contribution
   from measured moments** through :ref:`the two-probe model <k05-inference-en>`.
   Thus the inference chain does not require an independently calculated value
   of every :math:`V^Q`; it still requires the weakly nonlinear model to be adequate.

   .. rubric:: From this equation to probe records

   .. container:: k05-text

      The :ref:`next page <k05-probe-signals-en>` starts with time records at
      fixed probe positions. Expressing the wave
      equation in time Fourier components, as in Eq. (2) of Ref. |ref-en|,
      connects the envelope description to those measured signals.

   .. rubric:: References

   .. _k05-coefficients-reference-1-en:

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   The coefficient definitions and their EDI qualification follow the discussion
   of Eq. (1), printed p. 115101-2. The intermediate response expansion and
   Poisson bookkeeping are explanatory derivations added here, not extra
   equations quoted from the article.


   .. container:: k05-r31-added

      .. _k05-coefficients-reference-2-en:

      [2] R. Fitzpatrick, *Plasma Physics*, “Cold-Plasma Dielectric Permittivity,”
      equations (5.30) and (5.33), University of Texas at Austin.
      `Lecture notes <https://farside.ph.utexas.edu/teaching/plasma/Plasma/node64.html>`_.


.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-coefficients-zh:

   .. rubric:: 包络方程和系数从哪里来

   :ref:`上一页面 <k05-wave-overview-zh>` 把一列波分成快速振荡和缓慢变化的包络，
   再用群速度、增长率和耦合系数描述包络的变化。**这些量究竟由什么决定？**
   需要从电子和离子怎样响应电势扰动说起。

   本页面补上 Brown 与 Jorns |ref-zh| 所用模型的这个环节。
   先只考虑一个方向、一列波，再加上其他波的作用。正文顺着推导走，详细计算可以按需展开。

   .. rubric:: 1. 波必须与它引起的电荷运动相互一致

   电势有起伏，就会产生电场；电场推动带电粒子，改变电荷密度。
   这些电荷又必须通过泊松方程（Poisson's equation）产生原来的电势。
   自由演化的波需要满足这种 **自洽性（self-consistency）**。

   .. container:: k05-r31-revised

      对于局部均匀背景中的小振幅正弦波，可以把线性化的等离子体方程整理成一个响应函数
      :math:`D(k,\omega)`。在这里的约定下，它无量纲，称为
      **线性介电响应（linear dielectric response）**。
      它的具体形式取决于粒子分布、温度、漂移和磁场等物理信息，必须从等离子体模型求出，
      不能只凭波形确定。

   回顾一下，:math:`k` 是沿 :math:`y` 方向的波数，单位 rad/m；
   :math:`\omega` 是角频率，单位 rad/s。这里用响应的实部选取一个实数载波频率：

   .. k05:equation:: response-carrier
      :lang: zh

      D(k,\omega)=D_r(k,\omega)+iD_i(k,\omega),\qquad
      D_r(k,\omega)=0.

   下标 :math:`r`、:math:`i` 分别表示实部（real part）和虚部（imaginary part）；
   乘在 :math:`D_i` 前面的 :math:`i` 是虚数单位，满足 :math:`i^2=-1`。
   :math:`D_r=0` 把频率与波数联系起来，称为这里采用的实
   **色散关系（dispersion relation）**。较小的虚响应 :math:`D_i` 将负责缓慢增长或衰减。
   文献 |ref-zh| 把这两部分写成 :math:`\epsilon_r^{(1)}`、:math:`\epsilon_i^{(1)}`；
   上标 :math:`(1)` 表示波幅的一阶响应。

   .. raw:: html

      <details class="k05-note"><summary>从泊松方程到 D，中间做了什么？</summary>

   对于波数非零的平面波，把一阶电荷响应写成

   .. k05:equation:: poisson-response
      :lang: zh

      \begin{aligned}
      \epsilon_0 k^2\phi&=\rho^{(1)},\qquad
      \rho^{(1)}=-\epsilon_0 k^2\sum_s\chi_s(k,\omega)\phi,\\
      D(k,\omega)\phi&=0,\qquad D=1+\sum_s\chi_s.
      \end{aligned}

   这里 :math:`\phi` 是包含载波的复电势，单位 V；:math:`\rho^{(1)}` 是一阶电荷密度扰动，
   单位 :math:`\mathrm{C/m^3}`；:math:`\epsilon_0` 是真空介电常数（vacuum permittivity），
   单位 F/m。无量纲的 **极化率（susceptibility）** :math:`\chi_s`
   描述粒子种类 :math:`s` 的响应，例如电子或离子；求和遍历模型中的粒子种类。
   第一行规定了 :math:`\chi_s` 的符号约定，把右边移到左边就得到第二行。

   .. raw:: html

      <details class="k05-note k05-r31-added"><summary>展开这几行：从泊松方程到响应函数</summary>

   :math:`E_y` 是沿 :math:`y` 方向的电场，单位 V/m。高斯定律（Gauss's law）
   把电场的空间变化与电荷密度联系起来。对单个 Fourier 分量
   :math:`\phi\propto e^{i(ky-\omega t)}`，每求一次 :math:`y` 导数就乘一个
   :math:`ik`，两次求导便得到 :math:`-k^2`：

   .. k05:equation:: poisson-response-steps
      :lang: zh

      \begin{aligned}
      E_y&=-\partial_y\phi,\qquad \partial_yE_y=\rho^{(1)}/\epsilon_0,\\
      \partial_y^2\phi&=-\rho^{(1)}/\epsilon_0,\qquad
      \partial_y^2\phi=-k^2\phi,\\
      \epsilon_0k^2\phi&=-\epsilon_0k^2\left(\sum_s\chi_s\right)\phi,\\
      \left(1+\sum_s\chi_s\right)\phi&=0.
      \end{aligned}

   第二行立刻给出 :math:`\epsilon_0k^2\phi=\rho^{(1)}`。
   对每种粒子，把线性电荷响应写成
   :math:`\rho_s^{(1)}=-\epsilon_0k^2\chi_s\phi`。
   这是对 :math:`\chi_s` 的 **归一化和正负号约定**，不能只靠泊松方程算出它的值。
   把各粒子的响应相加再代入，就得到第三行。全部移到左边，除以非零的
   :math:`\epsilon_0k^2`，便得到最后一行。括号内的系数命名为 :math:`D`；
   这里没有除以 :math:`D`。

   .. raw:: html

      </details>

   波不为零时，:math:`D\phi=0` 要求 :math:`D=0`。虚响应较弱时，
   我们用 :math:`D_r=0` 选择实载波，把 :math:`D_i` 留给包络演化；完整复频率根稍后说明。
   在磁化等离子体中，这里的 :math:`D` 是针对所选传播方向的静电响应，
   :math:`\chi_s` 可以依赖传播方向。实际计算它，需要把线性化的流体方程或动理学方程
   与泊松方程联立。下面的代数暂不指定某一个具体的极化率模型。

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note k05-r31-added"><summary>一个简单的极化率：冷电子与固定离子</summary>

   考虑均匀等离子体，不加磁场，没有碰撞和背景漂移。忽略电子压强，
   离子只提供固定的中和背景。这个冷电子模型（cold-electron model）给出 [2]

   .. k05:equation:: cold-electron-susceptibility
      :lang: zh

      \chi_e=-\frac{\omega_{pe}^2}{\omega^2},\qquad
      \omega_{pe}^2=\frac{n_0e^2}{\epsilon_0m_e},\qquad
      D=1+\chi_e=1-\frac{\omega_{pe}^2}{\omega^2}.

   其中 :math:`n_0` 是平衡电子数密度，单位 m⁻³；:math:`e>0` 是元电荷，单位 C；
   :math:`m_e` 是电子质量，单位 kg；:math:`\omega_{pe}` 是电子等离子体角频率
   （electron plasma angular frequency），单位 rad/s。电子电荷为 :math:`-e`，
   :math:`\chi_e` 与 :math:`D` 都无量纲。

   用 :math:`\delta u_e` 表示电子速度扰动，单位 m/s，用 :math:`\delta n_e`
   表示电子数密度扰动，单位 m⁻³；:math:`\delta` 表示偏离平衡的小变化。
   在静止、均匀的背景附近，把牛顿运动定律和粒子数守恒线性化：

   .. k05:equation:: cold-electron-fluid-response
      :lang: zh

      \begin{aligned}
      m_e\partial_t\delta u_e&=-eE_y,\qquad
      \partial_t\delta n_e+n_0\partial_y\delta u_e=0,\\
      -i\omega m_e\delta u_e&=ie k\phi,\qquad
      -i\omega\delta n_e+ikn_0\delta u_e=0,\\
      \delta u_e&=-\frac{ek}{m_e\omega}\phi,\qquad
      \delta n_e=-\frac{n_0ek^2}{m_e\omega^2}\phi,\\
      \rho_e^{(1)}&=-e\delta n_e=
      \frac{n_0e^2k^2}{m_e\omega^2}\phi
      =-\epsilon_0k^2\chi_e\phi.
      \end{aligned}

   代入 :math:`E_y=-ik\phi`、:math:`\partial_t\to-i\omega` 和
   :math:`\partial_y\to ik`，便得到第二行；随后先解出速度，再解出密度。
   把最后一行与前面的电荷响应约定比较，就读出了 :math:`\chi_e`。
   因此，极化率把 **电势 → 粒子运动 → 电荷响应** 这一串过程装进一个系数。

   例如，试取 :math:`\omega=2\omega_{pe}`，则 :math:`\chi_e=-1/4`、
   :math:`D=3/4`。这只是计算某个试探频率下的响应，并不是已经满足自洽条件的自由波；
   再要求 :math:`D=0`，才选出 :math:`\omega^2=\omega_{pe}^2`。
   负的极化率不表示负密度，而是当前约定下的响应系数。
   这个例子帮助认清符号；文献 [1] 的磁化、有漂移模型需要另一种极化率。

   .. raw:: html

      </details>

   .. rubric:: 2. 缓慢变化的包络，包含邻近的波

   .. container:: k05-text

      完全均匀的包络只给出一个正弦波。较宽、缓慢变化的波包，可以由集中在载波附近的波数叠加而成。
      下图选取同一条平滑色散分支，因此这些分量的频率也彼此接近。

   .. container:: k05-text

      在波包中心，各输入波同相叠加；离开中心后，略有不同的波长让相位逐渐错开，许多贡献相互抵消。
      **波数越接近，越需要走过较长距离才明显错开，所以叠加后的包络越宽。**

      先拖动“波数谱宽”滑块。上图显示波数分布，中图选出其中三列代表性的波，
      下图显示整个波数带的加权叠加。为了比较相位，中图三条曲线都画成单位高度；
      下图的波包并不只是这三条曲线相加。

      .. raw:: html

         <div class="k05-band" data-k05-band="zh">
           <img src="../../_static/K_Diagnostics/k05-packet-band-zh.svg" alt="集中的高斯波数分布对应较宽的波包；三列代表性的输入波在波包中心附近同相叠加。">
           <noscript>这是默认参数下的静态图；启用 JavaScript 后可以调节谱宽和时间。</noscript>
         </div>

      各坐标采用任意单位。这是峰值高度不变的叠加示意，不是实验数据。
      宽度读数针对高斯幅值分布，不是功率谱（power spectrum）。
      图中刻意使用直线形式的色散关系，所以拖动时间只使波包移动，不会改变其宽度。

      .. raw:: html

         <details class="k05-note"><summary>图中实际用了哪些函数？</summary>

      载波参数为 :math:`k_0=5`、:math:`\omega_0=8`，群速度 :math:`v_g=0.7`；
      下标 :math:`0` 表示载波取值。每个输入波的波数为 :math:`k_0+q`；
      :math:`q` 是相对于载波的波数偏移，单位与 :math:`k_0` 相同。其权重与频率取为

      .. k05:equation:: packet-band-spectrum
         :lang: zh

         W(q)=\frac{1}{\sqrt{2\pi}\sigma_k}
         \exp\!\left(-\frac{q^2}{2\sigma_k^2}\right),\qquad
         \omega(k_0+q)=\omega_0+v_gq.

      :math:`W` 是高斯形式的幅值权重密度（amplitude-weight density），
      归一化为 :math:`\int W(q)\,dq=1`。
      正参数 :math:`\sigma_k` 控制波数分布的宽度，滑块范围为 0.15–0.60；
      谱图纵轴画相对权重 :math:`W(q)/W(0)`，横轴画 :math:`k_0+q`。
      选定的直线色散关系意味着：波数偏移 :math:`q` 对应频率偏移 :math:`\nu=v_gq`。

      把这些实波形相加，就得到有解析表达式的高斯波包：

      .. k05:equation:: packet-band-sum
         :lang: zh

         \begin{aligned}
         u(y,t)&=h_0\int_{-\infty}^{\infty}W(q)
         \cos\!\left[(k_0+q)y-(\omega_0+v_gq)t\right]dq\\
         &=\underbrace{h_0\exp\!\left[-\frac{\sigma_k^2(y-v_gt)^2}{2}\right]}_{h(y,t)}
         \cos(k_0y-\omega_0t),\\
         \sigma_y&=\frac{1}{\sigma_k},\qquad \sigma_\omega=|v_g|\sigma_k.
         \end{aligned}

      积分号表示按权重 :math:`W(q)\,dq` 把所有输入加起来。
      峰值电压 :math:`h_0` 设为 1；:math:`\sigma_y` 是包络的空间宽度，
      :math:`\sigma_\omega` 是幅值权重的角频率宽度，单位分别是长度和时间的倒数。
      若恢复物理单位，:math:`\sigma_k` 为 rad/m，:math:`\sigma_\omega` 为 rad/s，
      :math:`W` 的单位与波数互为倒数。
      在这个模型里，:math:`\sigma_k` 加倍，:math:`\sigma_y` 就减半，
      :math:`\sigma_\omega` 则加倍。高斯分布有很小的尾部，并没有硬性的谱带边界。

      它仍是 :k05:eq:`real-wave` 中的“高度乘余弦”结构；这里中心从零出发，没有幅值增长。
      选用直线色散分支，是为了排除展宽过程，让两种宽度的关系更容易看清。

      .. raw:: html

         </details>

   .. container:: k05-text

      接下来，为了单独研究一个邻近分量，把它写成：

   .. k05:equation:: nearby-carrier
      :lang: zh

      \begin{aligned}
      A(y,t)&=A_0 e^{i(qy-\nu t)},\\
      \phi(y,t)&=A(y,t)e^{i(ky-\omega t)}
      =A_0 e^{i[(k+q)y-(\omega+\nu)t]}.
      \end{aligned}

   :math:`A_0` 是不随时空变化的复电压。小偏移 :math:`q`、:math:`\nu`
   的单位分别是 rad/m、rad/s，描述包络 :math:`A` 的缓慢变化。
   乘上载波后，这两个偏移分别加到 :math:`k`、:math:`\omega` 上。
   这个分量只是推导工具，一般包络可以由许多这样的分量叠加而成。

   对包络求导，就能取出这些偏移：

   .. k05:equation:: offset-derivatives
      :lang: zh

      \begin{aligned}
      \partial_y A&=iqA, & qA&=-i\partial_y A,\\
      \partial_t A&=-i\nu A, & \nu A&=i\partial_t A.
      \end{aligned}

   因此，给包络分量乘 :math:`q`，等价于对它作用 :math:`-i\partial_y`；
   乘 :math:`\nu`，等价于作用 :math:`i\partial_t`。
   :math:`\partial_y` 是固定时间对位置求偏导，:math:`\partial_t` 是固定位置对时间求偏导。
   这里的正负号来自我们选定的载波 :math:`e^{i(ky-\omega t)}`。

   接下来，把响应函数在载波附近展开：

   .. k05:equation:: response-taylor
      :lang: zh

      \begin{aligned}
      D(k+q,\omega+\nu)
      &\simeq D(k,\omega)+(\partial_k D)q+(\partial_\omega D)\nu\\
      &\simeq iD_i+(\partial_k D_r)q+(\partial_\omega D_r)\nu.
      \end{aligned}

   :math:`\simeq` 表示“近似相等”。第一行是一阶泰勒展开（Taylor expansion）：
   保留局部斜率，略去偏移的二次及更高次项。第二行用了 :math:`D_r=0`，
   所以常数项只剩 :math:`iD_i`；同时略去了 :math:`D_i` 的较小导数贡献。

   .. container:: k05-text

      .. raw:: html

         <details class="k05-note"><summary class="k05-r31-revised">保留二阶泰勒项：前面略去了什么？</summary>

      .. raw:: html

         <span id="equation-k05-taylor-one-parameter-zh"></span>

      .. k05:equation:: taylor-second-order
         :lang: zh

         \begin{aligned}
         D(k+q,\omega+\nu)
         ={}&D+q\,\partial_kD+\nu\,\partial_\omega D\\
         &+\frac{1}{2}\left[q^2\partial_k^2D
         +2q\nu\,\partial_k\partial_\omega D
         +\nu^2\partial_\omega^2D\right]+\mathcal R_3.
         \end{aligned}

      .. container:: k05-r31-revised

         右边所有导数都在 :math:`(k,\omega)` 处取值。
         :math:`\partial_k^2D` 描述沿波数方向的弯曲程度，
         :math:`\partial_\omega^2D` 描述沿频率方向的弯曲程度。
         **混合偏导（mixed derivative）** :math:`\partial_k\partial_\omega D`
         描述“改变一个自变量时，另一个方向的斜率怎样变化”。
         方括号内的混合项为 :math:`q\nu\,\partial_k\partial_\omega D`
         与 :math:`\nu q\,\partial_\omega\partial_kD`；响应足够光滑时，
         两种求导顺序结果相同，合并后就得到系数 2。
         余项（remainder） :math:`\mathcal R_3` 收纳偏移的三次及更高阶贡献。
         保留这个余项，才可以写等号；有限项的泰勒多项式通常只是近似。

      :k05:eq:`response-taylor` 实际做了 **两次不同的简化**。
      第一行略去了二阶方括号及 :math:`\mathcal R_3`；第二行又略去了虚响应的导数。
      在做第二次简化之前，一阶部分应写成

      .. k05:equation:: taylor-real-imaginary
         :lang: zh

         \begin{aligned}
         D(k+q,\omega+\nu)
         ={}&\left[D_r+q\,\partial_kD_r+\nu\,\partial_\omega D_r\right]\\
         &+i\left[D_i+q\,\partial_kD_i+\nu\,\partial_\omega D_i\right]
         +\mathcal R_2.
         \end{aligned}

      这里 :math:`\mathcal R_2` 包含 :k05:eq:`taylor-second-order` 中全部二阶及更高阶项。
      在载波处只令 :math:`D_r=0`，并不会让 :math:`iq\partial_kD_i`
      和 :math:`i\nu\partial_\omega D_i` 自动消失。
      它们从 :k05:eq:`response-taylor` 中消失，是因为又采用了虚响应较弱的近似。
      函数 :math:`D_i` 在某一点的值小，并不能保证它在该点附近的斜率也小。

      .. raw:: html

         </details>

   这里所有响应系数都在选定的实数 :math:`(k,\omega)` 处取值。
   :math:`\partial_k` 表示固定 :math:`\omega` 对波数求偏导；
   :math:`\partial_\omega` 表示固定 :math:`k` 对角频率求偏导。
   把展开式乘上 :math:`A`，令线性响应为零，再使用 :k05:eq:`offset-derivatives`，得到

   .. k05:equation:: linear-response-1d
      :lang: zh

      iD_iA-i(\partial_k D_r)\partial_y A
      +i(\partial_\omega D_r)\partial_t A=0.

   .. container:: k05-text

      :math:`q`、:math:`\nu` 这两个数并没有真的“变成”导数。
      我们只是把“它们乘在某个包络分量上的作用”换一种等价写法。
      先把 :k05:eq:`response-taylor` 乘上 :math:`A`，再逐项替换：

      .. k05:equation:: offset-substitution-terms
         :lang: zh

         \begin{aligned}
         0&\simeq iD_iA+(\partial_kD_r)qA+(\partial_\omega D_r)\nu A,\\
         (\partial_kD_r)qA&=(\partial_kD_r)(-i\partial_yA),\\
         (\partial_\omega D_r)\nu A&=(\partial_\omega D_r)(i\partial_tA).
         \end{aligned}

      第二行可以读成：“给这个分量乘上它的波数偏移”，等价于“对它求空间导数，再乘 :math:`-i`”。
      第三行对频率偏移做同样的处理，换成时间导数；:math:`iD_iA` 这一项保持不变。
      把这两个等式代回第一行，就恰好得到 :k05:eq:`linear-response-1d`。

      一个包络往往包含许多偏移不同的分量，不能用同一个数 :math:`q` 代表所有分量。
      但空间求导会自动给每个分量乘上它自己的 :math:`iq`，时间求导会乘上各自的 :math:`-i\nu`。
      因此，把分量相加之后，仍然可以用同一个微分方程描述整个包络 :math:`A(y,t)`。

   .. rubric:: 3. 从方程里读出移动速度和增长率

   要求 :math:`\partial_\omega D_r\ne0`，才能做下面的除法。
   把 :k05:eq:`linear-response-1d` 除以 :math:`i\partial_\omega D_r`，
   再把正比于 :math:`A` 的那一项移到右边：

   .. k05:equation:: linear-coefficients-1d
      :lang: zh

      \boxed{\begin{aligned}
      \partial_t A+v_g\partial_y A&=\gamma A,\\
      v_g&=-\frac{\partial_k D_r}{\partial_\omega D_r},\qquad
      \gamma=-\frac{D_i}{\partial_\omega D_r}.
      \end{aligned}}

   这正是上一页面使用的线性包络方程 :k05:eq:`linear-envelope`。
   :math:`\partial_y A` 前的系数就是 **群速度（group velocity）** :math:`v_g`，
   右边 :math:`A` 前的系数就是 **幅值增长率（amplitude growth rate）** :math:`\gamma`。
   现在，它们由等离子体响应决定了。

   单位也能直接检查：:math:`\partial_kD_r` 的单位是 m，
   :math:`\partial_\omega D_r` 的单位是 s，所以 :math:`v_g` 的单位是 m/s，
   :math:`\gamma` 的单位是 :math:`\mathrm{s}^{-1}`。
   沿包络移动时，正的 :math:`\gamma` 使幅值增加。
   增长还是衰减，要同时看 :math:`D_i` 和 :math:`\partial_\omega D_r` 的符号。

   .. raw:: html

      <details class="k05-note"><summary>为什么这个速度就是色散曲线的斜率？</summary>

   沿一条实色散分支，把载波频率写成 :math:`\omega=\Omega(k)`。
   新符号 :math:`\Omega` 只是给这个函数取名，方便区分“沿曲线求全导数”与“对响应函数求偏导”：

   .. k05:equation:: group-velocity-chain
      :lang: zh

      \begin{aligned}
      0=\frac{d}{dk}D_r(k,\Omega(k))
      &=(\partial_k D_r)_\omega+(\partial_\omega D_r)_k\frac{d\Omega}{dk},\\
      \frac{d\Omega}{dk}&=-\frac{\partial_k D_r}{\partial_\omega D_r}=v_g.
      \end{aligned}

   第一行是对 :math:`D_r(k,\Omega(k))=0` 使用链式法则（chain rule）。
   括号外的下标标明偏导时固定什么量；求完偏导，再在 :math:`\omega=\Omega(k)` 处取值。
   解出 :math:`d\Omega/dk`，恰好就是 :k05:eq:`linear-coefficients-1d` 中的系数。
   因此，包络速度等于色散曲线在载波处的斜率。

   .. raw:: html

      </details>
      <details class="k05-note"><summary>为什么虚响应对应增长或衰减？</summary>

   复频率 :math:`\omega+i\gamma` 会在时间振荡之外，增加指数形式的幅值变化。
   在实载波附近展开完整色散方程，采用同样的弱响应近似：

   .. raw:: html

      <span id="equation-k05-growth-retained-terms-zh"></span>

   .. raw:: html

      <span id="equation-k05-growth-size-comparison-zh"></span>

   .. raw:: html

      <span id="equation-k05-growth-complex-correction-zh"></span>

   .. k05:equation:: weak-growth-root
      :lang: zh

      \begin{aligned}
      D(k,\omega+i\gamma)&\simeq iD_i+i\gamma\partial_\omega D_r=0,\\
      \gamma&\simeq-\frac{D_i}{\partial_\omega D_r},\qquad
      e^{-i(\omega+i\gamma)t}=e^{-i\omega t}e^{\gamma t}.
      \end{aligned}

   最后一个等式明确了符号：正的 :math:`\gamma` 给出 :math:`e^{\gamma t}`。
   幅值平方则按 :math:`e^{2\gamma t}` 变化，因此它的增长率是幅值增长率的两倍。
   这只是复频率根的最低阶近似。其中略去了 :math:`-\gamma\partial_\omega D_i` 等项，
   需要虚响应及其导数满足适当的弱小排序，不能只检查 :math:`|\gamma/\omega|` 很小。
   所选实载波频率也不必严格等于完整复根的实部。

   .. raw:: html

      </details>

   .. rubric:: 4. 其他波带来二阶电荷响应

   到这里，电荷响应对电势都是线性的。再保留高一阶，就会出现两个波幅的乘积。
   从物理上说，波的电场先扰动粒子运动，而被扰动的运动又改变了等离子体对电场的响应。
   二阶计算把这些相乘的作用保留下来。

   用 :math:`\mathcal N^{(2)}` 表示它们在包络场方程中的贡献。
   这是归一化后的电荷响应项，单位 V；上标 :math:`(2)` 表示波幅的二阶。
   我们把它放在左边，以此明确它的符号约定：

   .. k05:equation:: quadratic-response-1d
      :lang: zh

      iD_iA-i(\partial_k D_r)\partial_y A
      +i(\partial_\omega D_r)\partial_t A+\mathcal N^{(2)}=0.

   **这里增加了新的物理输入。** 对线性函数 :math:`D` 作泰勒展开，可以得到前面的导数项，
   但不会凭空产生二次响应。二次响应必须从二阶等离子体方程另外求出。

   对于目标波 :math:`a`，把 :k05:eq:`matched-pairs` 中的输入波对收集起来：

   .. k05:equation:: quadratic-source
      :lang: zh

      \mathcal N^{(2)}_a
      =\sum_{(b,c)\in\mathcal S_a}K^{(2)}_{a;bc}A_bA_c.

   :math:`A_b`、:math:`A_c` 是两个输入包络，单位都是 V；
   :math:`\mathcal S_a` 是上一页面定义的允许波对集合。
   响应系数 :math:`K^{(2)}_{a;bc}` 的单位是 :math:`\mathrm{V}^{-1}`，可以为复数。
   下标区分输出 :math:`a` 与输入 :math:`b,c`，分号把两者隔开；
   波对采用与 :k05:eq:`ordered-pair-sum` 相同的有序计数约定。

   再把 :k05:eq:`quadratic-response-1d` 除以 :math:`i(\partial_\omega D_r)_a`，得到

   .. k05:equation:: coupling-coefficient
      :lang: zh

      \begin{aligned}
      (\partial_t+v_{g,a}\partial_y)A_a
      &=\gamma_a A_a+\sum_{(b,c)\in\mathcal S_a}V^Q_{a;bc}A_bA_c,\\
      V^Q_{a;bc}&=\frac{iK^{(2)}_{a;bc}}{(\partial_\omega D_r)_a}.
      \end{aligned}

   分母外的下标 :math:`a` 表示在 :math:`(k_a,\omega_a)` 处求该导数的值。
   新项前的正号来自移项时的 :math:`-1/i=i`。
   上标 :math:`Q` 表示二次（quadratic）；系数的单位是
   :math:`\mathrm{V}^{-1}\mathrm{s}^{-1}`，所以每个耦合项的单位都是 V/s。
   这就回到了 :k05:eq:`quadratic-envelope`，并说明了每个系数的来源。

   .. raw:: html

      <details class="k05-note"><summary>二次项与电荷密度究竟是什么关系？</summary>

   沿用 :k05:eq:`poisson-response` 的泊松方程约定，保留目标模式 :math:`a` 上的二次电荷源。
   这个源包含输入波的乘积；对输出电势的线性电荷响应已经计入 :math:`D`：

   .. k05:equation:: quadratic-poisson
      :lang: zh

      \begin{aligned}
      \epsilon_0 k_a^2\phi_a&=\rho^{(1)}_a+\rho^{(2)}_a,\\
      D_a\phi_a-\frac{\rho^{(2)}_a}{\epsilon_0 k_a^2}&=0,\qquad
      \rho^{(2)}_a=R^{(2)}_a e^{i\theta_a},\\
      \mathcal N^{(2)}_a&=-\frac{R^{(2)}_a}{\epsilon_0 k_a^2}.
      \end{aligned}

   :math:`D_a` 是该模式上的响应，:math:`k_a\ne0` 是其载波波数。
   电荷扰动 :math:`\rho^{(2)}_a` 与它的慢变复包络 :math:`R^{(2)}_a`
   都以 :math:`\mathrm{C/m^3}` 为单位；:math:`\theta_a=k_a y-\omega_a t` 是载波相位。
   去掉共同因子 :math:`e^{i\theta_a}`，再像前面一样展开线性响应，
   最后一行就给出了 :k05:eq:`quadratic-response-1d` 使用的项。
   在当前保留的阶次上，用载波波数归一化即可；其中的包络导数修正属于更高阶。

   .. container:: k05-text

      从 :k05:eq:`quadratic-poisson` 的第一行到第二行，需要代入
      :k05:eq:`poisson-response` 中的一阶电荷响应。
      记 :math:`\chi_{s,a}=\chi_s(k_a,\omega_a)`，表示粒子种类 :math:`s`
      在目标载波处的极化率：

      .. k05:equation:: poisson-source-rearrangement
         :lang: zh

         \begin{aligned}
         \rho_a^{(1)}&=-\epsilon_0k_a^2
         \left(\sum_s\chi_{s,a}\right)\phi_a,\\
         \epsilon_0k_a^2\phi_a
         &=-\epsilon_0k_a^2\left(\sum_s\chi_{s,a}\right)\phi_a+\rho_a^{(2)},\\
         \left(1+\sum_s\chi_{s,a}\right)\phi_a
         &=\frac{\rho_a^{(2)}}{\epsilon_0k_a^2},\\
         \underbrace{\left(1+\sum_s\chi_{s,a}\right)}_{D_a}\phi_a
         -\frac{\rho_a^{(2)}}{\epsilon_0k_a^2}&=0.
         \end{aligned}

      第二行只是代入。到第三行时，先把右边带负号的线性响应项移到左边，
      与原来的系数 1 合并，再除以非零的 :math:`\epsilon_0k_a^2`。
      最后一行用 :math:`D_a=1+\sum_s\chi_{s,a}` 简写，并把二次源移到左边。
      二次源没有被丢掉，它正是那个带负号的分式。

   .. container:: k05-r31-added

      **再得到最后一行：去掉载波，认出源项。**
      代入 :math:`\phi_a=A_a e^{i\theta_a}` 和
      :math:`\rho_a^{(2)}=R_a^{(2)}e^{i\theta_a}`。
      对波包，:k05:eq:`quadratic-poisson` 中简写的线性响应还要像
      :k05:eq:`linear-response-1d` 一样，在载波附近展开；不能只把它当成常数
      :math:`D_a A_a`。为了看清代入过程，把前面已经推得的三个线性项
      暂时合记为 :math:`\mathcal L_a A_a`：

      .. k05:equation:: quadratic-envelope-source-steps
         :lang: zh

         \begin{aligned}
         \mathcal L_a A_a&\equiv iD_{i,a}A_a
         -i(\partial_kD_r)_a\partial_yA_a
         +i(\partial_\omega D_r)_a\partial_tA_a,\\
         0&\simeq e^{i\theta_a}\left[\mathcal L_a A_a
         -\frac{R_a^{(2)}}{\epsilon_0k_a^2}\right],\\
         0&=\mathcal L_a A_a+\mathcal N_a^{(2)},\qquad
         \mathcal N_a^{(2)}=-\frac{R_a^{(2)}}{\epsilon_0k_a^2}.
         \end{aligned}

      第一行只是缩写；系数的下标 :math:`a` 表示在 :math:`(k_a,\omega_a)` 处求值。
      第二行把电势和二次电荷的载波因子，以及线性响应展开，代入整理后的泊松方程。
      由于 :math:`e^{i\theta_a}\ne0`，两边可除掉这个共同因子。
      再与 :k05:eq:`quadratic-response-1d` 的“线性项 + :math:`\mathcal N_a^{(2)}` = 0”
      比较，剩下的负分式正是 :math:`\mathcal N_a^{(2)}`。
      它的单位是 V，与这些线性项一致；再除以频率导数后，才成为演化方程中的变化率项。

   负号属于这里对 :math:`\mathcal N^{(2)}` 的定义。
   如果改变 :math:`D` 的归一化，也必须一致地改变非线性项。
   这个过程说明了代数和单位，但要得到 :math:`K^{(2)}` 的数值，仍需要具体的二阶响应模型。

   .. raw:: html

      </details>

   .. rubric:: 5. 推广到三个空间方向

   前面的思路并不依赖于只有一个空间方向。
   把波数 :math:`k` 换成波矢（wavevector） :math:`\mathbf k`，
   把位置 :math:`y` 换成位置矢量 :math:`\mathbf r`。
   一阶空间展开就变成一个点积：

   .. k05:equation:: dielectric-expansion
      :lang: zh

      iD_iA+i(\partial_\omega D_r)\partial_t A
      -i(\nabla_{\mathbf k}D_r)\cdot\nabla A
      +\mathcal N^{(2)}=0.

   :math:`\nabla` 对空间位置求梯度，:math:`\nabla_{\mathbf k}` 则在固定频率时对波矢求梯度。
   点积把三个方向的贡献加起来。再做与一维情况相同的除法，得到

   .. k05:equation:: response-coefficients
      :lang: zh

      \begin{aligned}
      (\partial_t+\mathbf v_g\cdot\nabla)A
      &=\gamma A+\frac{i\mathcal N^{(2)}}{\partial_\omega D_r},\\
      \gamma&=-\frac{D_i}{\partial_\omega D_r},\qquad
      \mathbf v_g=-\frac{\nabla_{\mathbf k}D_r}{\partial_\omega D_r}.
      \end{aligned}

   :math:`\mathbf v_g` 是群速度矢量，单位 m/s。
   对每个目标模式代入 :k05:eq:`quadratic-source`，其中匹配条件改用波矢，
   再按照上一页面恢复 :math:`\phi_a=A_a e^{i\theta_a}`，
   就得到 :k05:eq:`full-wave-equation`，也就是文献 |ref-zh| 公式 (1) 的形式。
   载波相位项来自最后这一步的乘积求导；本页面推导的系数负责包络本身的演化。

   这里将二阶响应核保留为符号，并不意味着后面的实验分析缺少一个必须先算出的数字。
   从指定速度分布计算它，是另一项动理学预测；文献 [1] 的方法则通过
   :ref:`双探针模型 <k05-inference-zh>`，**用实测统计矩估计它的有效贡献**。
   所以反演不要求事先独立知道每个 :math:`V^Q`，但仍要求弱非线性模型适合所测信号。

   .. rubric:: 从方程走向探针记录

   .. container:: k05-text

      :ref:`下一页面 <k05-probe-signals-zh>` 从固定探针的时间记录开始。像文献 |ref-zh| 公式 (2) 那样，
      用时间傅里叶分量（time Fourier components）重写波动方程，
      就可以把包络描述与这些测量信号联系起来。

   .. rubric:: 参考文献

   .. _k05-coefficients-reference-1-zh:

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_。

   系数定义及 EDI 适用条件依据文献纸面第 115101-2 页公式 (1) 附近的讨论。
   中间的响应展开与泊松方程整理是本页面补充的讲解推导，并非从原文逐条引用的公式。


   .. container:: k05-r31-added

      .. _k05-coefficients-reference-2-zh:

      [2] R. Fitzpatrick, *Plasma Physics*, “Cold-Plasma Dielectric Permittivity,”
      equations (5.30) and (5.33), University of Texas at Austin.
      `Lecture notes <https://farside.ph.utexas.edu/teaching/plasma/Plasma/node64.html>`_.

