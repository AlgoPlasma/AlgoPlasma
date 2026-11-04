05 · From statistics to growth and coupling
===========================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. |ref-en| raw:: html

   <a class="k05-cite" href="#k05-inference-reference-1-en">[1]</a>

.. |kim-en| raw:: html

   <a class="k05-cite" href="#k05-inference-reference-2-en">[2]</a>

.. |ref-zh| raw:: html

   <a class="k05-cite" href="#k05-inference-reference-1-zh">[1]</a>

.. |kim-zh| raw:: html

   <a class="k05-cite" href="#k05-inference-reference-2-zh">[2]</a>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-inference-en:

   .. rubric:: From measured averages to growth and coupling

   The :ref:`previous page <k05-statistics-en>` gave us powers, cross powers and
   bispectra. Now ask a more specific question: **how much of the signal at the
   second probe can be explained by the same frequency at the first probe, and
   how much by products of other frequencies?**

   We first fit those two contributions together. Only then do we convert the
   fitted coefficients into rates. This follows the two-probe model of Brown and
   Jorns |ref-en|; the statistical assumptions of the Kim method |kim-en| are
   made explicit below. Keep the normalized Fourier coefficients of
   :k05:eq:`time-fourier-series` throughout.

   .. rubric:: 1. One output frequency, several possible contributions

   Choose a target frequency :math:`f`. For each record :math:`r`, the first probe
   gives :math:`X_f^{(r)}` and the second gives :math:`Y_f^{(r)}`. Choose :math:`J`
   distinct frequency pairs that add to :math:`f`, and call each pair product
   :math:`Z_j^{(r)}`. The label :math:`j` counts pairs, not records.
   The labels 1 and 2 select the two input frequencies of pair :math:`j`.

   .. _k05-source-3-en:

   .. container:: k05-paper-match

      .. rubric:: K05 and reference [1], Eq. (3)

      .. k05:equation:: two-probe-quadratic-model
         :lang: en

         \begin{aligned}
         Z_j^{(r)}&=X_{f_{1j}}^{(r)}X_{f_{2j}}^{(r)},\qquad f_{1j}+f_{2j}=f,\\
         Y_f^{(r)}&=L_fX_f^{(r)}+\sum_{j=1}^{J}Q_{fj}Z_j^{(r)}+\varepsilon_f^{(r)}.
         \end{aligned}

      **Original equation, original notation — [1], (3)**

      .. k05:equation:: paper-equation-3
         :lang: en

         Y_f=L_fX_f+\sum_{f=f_1+f_2}Q_f^{1,2}X_{f_1}X_{f_2}.

      **Symbol map.** :math:`X_f=\hat\phi_f(y)` and
      :math:`Y_f=\hat\phi_f(y+\Delta y)` are the two positions, not two wave species.
      Our superscript :math:`(r)` labels a record; the article suppresses it.
      Our :math:`Z_j=X_{f_{1j}}X_{f_{2j}}` abbreviates one product, and
      :math:`Q_{fj}` labels its coefficient. The article writes that pair as the
      superscript :math:`1,2` on :math:`Q_f^{1,2}`.

      K05 explicitly retains the residual :math:`\varepsilon_f^{(r)}`; the printed
      model has no residual term. Pair grouping also matters: a unique off-diagonal
      coefficient combines two ordered coefficients. Neither this :math:`\varepsilon`
      nor the record label :math:`r` is the dielectric or the real-part subscript.
      :ref:`Page 07 <k05-validation-en>` tests this model on excluded captures.


   Here :math:`L_f` is the **linear transfer coefficient**: it multiplies the
   component already at :math:`f`. Each :math:`Q_{fj}` is a **quadratic transfer
   coefficient**: it multiplies a pair of components. These are complex numbers,
   so both size and phase matter. The same coefficients describe all :math:`R`
   records in the chosen ensemble. :math:`\varepsilon_f^{(r)}` is the unexplained
   remainder, or **residual**. Setting it to zero gives the structure of Ref. [1], Eq. (3).

   :math:`X` and :math:`Y` have units V, :math:`Z` has units :math:`\mathrm{V^2}`,
   :math:`L` is dimensionless and :math:`Q` has units :math:`\mathrm{V^{-1}}`.
   Thus :math:`L` and :math:`Q` describe a change between locations; they are not
   yet rates per second.

   .. raw:: html

      <details class="k05-note"><summary>Which pairs are listed, and why not list both orders?</summary>

   For target :math:`f=6\Delta f`, the positive-frequency examples
   :math:`(\Delta f,5\Delta f)`, :math:`(2\Delta f,4\Delta f)` and
   :math:`(3\Delta f,3\Delta f)` give three distinct products; :math:`\Delta f`
   is the frequency-grid spacing. Signed frequencies also allow difference-frequency
   contributions, such as :math:`(-\Delta f,7\Delta f)`, within the retained band.
   These examples are not a complete pair list for an arbitrary measurement.

   Because :math:`X_aX_b=X_bX_a`, listing both orders makes identical predictor
   columns. The data cannot separate their two coefficients. For :math:`a\ne b`,
   our one coefficient is the sum of the two ordered coefficients in the original
   wave equation: :math:`Q_j=Q_f^{a,b}+Q_f^{b,a}`. For :math:`a=b`, keep the single
   coefficient. The continuous coefficient :math:`\mathcal V_{fj}` introduced
   below uses the same grouping. Do not add another factor of two after grouping.

   For a real signal, :math:`X_{-f}=X_f^*`; this is how negative-frequency inputs
   can be reconstructed from stored positive frequencies. Pair selection must also
   respect the measurement bandwidth and the mode assumptions on the previous page.

   .. raw:: html

      </details>

   .. rubric:: 2. Turn many records into equations for the unknowns

   Start with just one pair. Suppress the fixed target label :math:`f` and pair
   label :math:`j` to make the algebra readable. Every record has different
   :math:`X,Y,Z`, but the same unknown :math:`L,Q`:

   .. k05:equation:: single-pair-records
      :lang: en

      \begin{aligned}
      Y^{(1)}&=LX^{(1)}+QZ^{(1)}+\varepsilon^{(1)},\\
      Y^{(2)}&=LX^{(2)}+QZ^{(2)}+\varepsilon^{(2)},\\
      &\ \vdots
      \end{aligned}

   The useful operation is to multiply each record equation by :math:`X^*`,
   then average. Repeat with :math:`Z^*`. This retains the two relationships
   needed to distinguish the two contributions. Give the measured averages short names:

   .. k05:equation:: inference-moments
      :lang: en

      \begin{aligned}
      P&=\langle |X|^2\rangle_R,&G&=\langle YX^*\rangle_R,\\
      b&=\langle XZ^*\rangle_R,&d&=\langle YZ^*\rangle_R,\\
      F&=\langle |Z|^2\rangle_R.
      \end{aligned}

   :math:`P` is the first-probe power and :math:`G` is its cross power with the
   second probe. :math:`b` is the **conjugate** of the auto-bispectrum defined in
   :k05:eq:`auto-bispectrum`; :math:`d` is the cross bispectrum in
   :k05:eq:`cross-bispectrum`. They have units :math:`\mathrm{V^3}`.
   :math:`F=\langle|X_{f_1}X_{f_2}|^2\rangle_R` is a **fourth-order moment**, in
   :math:`\mathrm{V^4}`. It appears because :math:`Z` already contains two coefficients.

   If the residual averages :math:`\langle\varepsilon X^*\rangle_R` and
   :math:`\langle\varepsilon Z^*\rangle_R` vanish, the result is

   .. _k05-source-5-en:

   .. container:: k05-paper-match

      .. rubric:: K05 and reference [1], Eq. (5)

      .. k05:equation:: single-pair-moment-equations
         :lang: en

         \begin{aligned}
         G&=LP+Qb^*,\\
         d&=Lb+QF.
         \end{aligned}

      **Original equation, original notation — [1], (5)**

      .. k05:equation:: paper-equation-5
         :lang: en

         \begin{aligned}
         Y_fX_f^*&=L_fX_fX_f^*+\sum_{f=f_1+f_2}Q_f^{1,2}X_{f_1}X_{f_2}X_f^*,\\
         Y_fX_{f_1}^*X_{f_2}^*&=L_fX_fX_{f_1}^*X_{f_2}^*\\
         &\quad+\sum_{f=f_1+f_2}Q_f^{1,2}X_{f_1}X_{f_2}X_{f_1}^*X_{f_2}^*.
         \end{aligned}

      **Symbol map and averaging.** The printed products correspond to our
      ensemble moments after averaging records. The first row becomes
      :math:`G=LP+\sum_jQ_jb_j^*`; multiplying by a chosen pair :math:`Z_i^*`
      gives :math:`d_i=Lb_i+\sum_jF_{ij}Q_j`.
      Here :math:`b_i=\langle XZ_i^*\rangle` is the conjugate auto-bispectrum,
      :math:`d_i=\langle YZ_i^*\rangle` is a cross bispectrum, and
      :math:`F_{ij}=\langle Z_i^*Z_j\rangle` is a fourth-order moment.

      **Read the repeated indices carefully.** The original second line uses
      :math:`f_1,f_2` both for the multiplying pair and inside the sum; the display
      above preserves that notation. In a multi-pair calculation the selected row
      must stay fixed while the summed pair varies. K05 uses separate :math:`i,j`
      labels and retains the off-diagonal moments, as in :k05:eq:`inference-matrix`.
      The printed shorthand is not a justification for deleting them. Vanishing
      residual cross moments and Kim's additional stationary-power assumptions
      are separate conditions, explained below.


   Everything except :math:`L,Q` is measured. **The bispectra supply extra equations;
   they are not themselves the coupling coefficients.**

   .. raw:: html

      <details class="k05-note"><summary>Show both multiplications and solve the two equations</summary>

   Multiplication by :math:`X^*` gives
   :math:`YX^*=L|X|^2+QZX^*+\varepsilon X^*`.
   Its average is :math:`G=LP+Qb^*`, since
   :math:`\langle ZX^*\rangle_R=b^*`.
   Multiplication by :math:`Z^*` gives
   :math:`YZ^*=LXZ^*+Q|Z|^2+\varepsilon Z^*`, hence :math:`d=Lb+QF`.

   Multiply the first moment equation by :math:`F`, the second by :math:`b^*`,
   and subtract. The :math:`QFb^*` terms cancel:
   :math:`FG-b^*d=L(PF-|b|^2)`. To eliminate :math:`L`, instead form
   :math:`Pd-bG=Q(PF-|b|^2)`. Therefore, when :math:`\Delta>0`,

   .. k05:equation:: single-pair-estimator
      :lang: en

      \begin{aligned}
      \Delta&=PF-|b|^2,\\
      L&=\frac{FG-b^*d}{\Delta},\qquad
      Q=\frac{Pd-bG}{\Delta}.
      \end{aligned}

   :math:`\Delta` is a determinant, not the probe spacing. Its units are
   :math:`\mathrm{V^6}`. The fractions return dimensionless :math:`L` and
   :math:`\mathrm{V^{-1}}` for :math:`Q`, as required.

   .. raw:: html

      </details>

   .. rubric:: 3. Estimate the linear and quadratic parts together

   If the quadratic contribution is discarded, a linear-only calculation would
   return :math:`G/P`. But the first moment equation actually says

   .. k05:equation:: linear-only-bias
      :lang: en

      \frac{G}{P}=L+Q\frac{b^*}{P}.

   Whenever the pair and target are correlated, some quadratic contribution is
   absorbed into that linear-only result. This is why we estimate :math:`L` and
   :math:`Q` together, rather than first declaring all observed growth to be linear.

   .. raw:: html

      <details class="k05-note"><summary>Several pairs: the same equations in a matrix</summary>

   For a concrete example, retain just two pairs feeding 6 MHz: (1, 5) MHz and
   (2, 4) MHz. Write :math:`X=X_{6\,\mathrm{MHz}}`, :math:`Y=Y_{6\,\mathrm{MHz}}`,
   :math:`Z_1=X_{1\,\mathrm{MHz}}X_{5\,\mathrm{MHz}}` and
   :math:`Z_2=X_{2\,\mathrm{MHz}}X_{4\,\mathrm{MHz}}`.
   These are illustrative frequency choices. There are three unknowns:
   :math:`L,Q_1,Q_2`. Multiply :math:`Y=LX+Q_1Z_1+Q_2Z_2+\varepsilon`
   by :math:`X^*`, :math:`Z_1^*` and :math:`Z_2^*`, then average:

   .. k05:equation:: two-pair-rows
      :lang: en

      \begin{aligned}
      G&=PL+b_1^*Q_1+b_2^*Q_2,\\
      d_1&=b_1L+F_{11}Q_1+F_{12}Q_2,\\
      d_2&=b_2L+F_{21}Q_1+F_{22}Q_2.
      \end{aligned}

   Here :math:`b_i=\langle XZ_i^*\rangle_R`,
   :math:`d_i=\langle YZ_i^*\rangle_R` and :math:`F_{ij}=\langle Z_i^*Z_j\rangle_R`.
   For example, :math:`F_{12}=\langle Z_1^*Z_2\rangle_R` comes from multiplying
   the second pair's contribution by the first pair's conjugate.
   Also :math:`F_{21}=F_{12}^*`. As above, residual cross moments are assumed zero.
   Put each unknown in its own column, in the order :math:`L,Q_1,Q_2`:

   .. k05:equation:: two-pair-matrix
      :lang: en

      \begin{pmatrix}
      P&b_1^*&b_2^*\\
      b_1&F_{11}&F_{12}\\
      b_2&F_{21}&F_{22}
      \end{pmatrix}
      \begin{pmatrix}L\\Q_1\\Q_2\end{pmatrix}
      =\begin{pmatrix}G\\d_1\\d_2\end{pmatrix}.

   Multiplying the matrix's second row by the unknown column reproduces the
   second equation exactly. Every matrix entry and right-hand entry is a
   measured average; only the middle column is unknown. The first row has
   units V² and each lower row V³: rows need not share units, but terms within
   each row must. With more pairs, add one row and one column per pair.

   For :math:`J` pairs define column vectors :math:`\mathbf b,\mathbf d,\mathbf q`
   with one entry per pair, and a :math:`J\times J` matrix :math:`\mathbf F`:

   .. k05:equation:: inference-matrix
      :lang: en

      \begin{aligned}
      b_i&=\langle XZ_i^*\rangle_R,\quad
      d_i=\langle YZ_i^*\rangle_R,\quad
      F_{ij}=\langle Z_i^*Z_j\rangle_R,\\
      \begin{pmatrix}P&\mathbf b^\dagger\\\mathbf b&\mathbf F\end{pmatrix}
      \begin{pmatrix}L\\\mathbf q\end{pmatrix}
      &=\begin{pmatrix}G\\\mathbf d\end{pmatrix},\qquad
      \mathbf q=(Q_1,\ldots,Q_J)^T.
      \end{aligned}

   The superscript :math:`T` means transpose; :math:`\dagger` means conjugate
   transpose. The top row is the power/cross-power equation. Row :math:`i` below
   it comes from multiplying by :math:`Z_i^*`. It contains every pair :math:`j`,
   through :math:`F_{ij}`. Off-diagonal entries describe correlations between
   different pair products; they cannot simply be dropped without an additional
   closure assumption. We retain them here.

   This is the full moment system associated with the linear-quadratic model.
   For recorded data it is also the normal-equation form of **complex least squares**:
   choose coefficients that minimize the sum of :math:`|\varepsilon^{(r)}|^2`.
   The fitted residual is orthogonal to the predictors in that sample by construction.
   That algebra alone does not prove that measurement errors are uncorrelated or
   that the fitted coefficients equal physical ones.

   .. raw:: html

      </details>

   Measured probe data add a complication: noise can enter the first probe as
   well as the second. More averages do not remove that bias automatically.
   Brown and Jorns |ref-en| use a modification of the Ritz method developed by
   Kim and colleagues |kim-en|, together with approximate equality of power at
   the two locations. This is an extra physical/statistical assumption, beyond
   the joint least-squares algebra above.

   The additional assumption is equal **modelled** power at the two locations,
   denoted :math:`P_\star`. Measured powers may differ. The method also neglects
   the nonideal mixed-moment contributions specified in Ref. [2], Sec. III B;
   pairwise uncorrelatedness alone does not guarantee this at third and fourth
   order. Under these assumptions, the computation below jointly determines
   the common power and coefficients. It does not impose zero linear growth:
   linear drive and nonlinear removal can balance.


   .. raw:: html

      <details class="k05-note" id="k05-kim-correction-en"><summary>Kim correction: calculate the common power and coefficients</summary>

   The outputs are a real common model power :math:`P_\star`, a dimensionless
   linear coefficient :math:`L`, and pair coefficients :math:`\mathbf q=(Q_1,\ldots,Q_J)^T`
   in V⁻¹. :math:`P_\star` has units V²; its star is a label, not conjugation.
   It represents the power assigned to the model at either probe, not the
   arithmetic mean of the two measured powers. Use the following calculation
   separately at each target frequency |kim-en|.

   **1. Calculate the inputs from the same paired records.** Keep the measured
   powers :math:`P_X=\langle|X|^2\rangle_R` and :math:`P_Y=\langle|Y|^2\rangle_R`
   for the final check. Calculate :math:`G,\mathbf b,\mathbf d,\mathbf F` using
   :k05:eq:`inference-moments` and :k05:eq:`inference-matrix`.
   Keep all off-diagonal entries of :math:`\mathbf F`.

   **2. Solve two linear systems, then form three numbers.**

   .. k05:equation:: kim-computation-quantities
      :lang: en

      \begin{aligned}
      \mathbf F\mathbf u_b&=\mathbf b,\qquad \mathbf F\mathbf u_d=\mathbf d,\\
      \alpha&=\mathbf b^\dagger\mathbf u_b,\qquad
      \beta=\mathbf d^\dagger\mathbf u_d,\qquad
      \eta=G-\mathbf b^\dagger\mathbf u_d.
      \end{aligned}

   :math:`\mathbf u_b,\mathbf u_d` are auxiliary solution columns, in V⁻¹;
   they are not new measurements. The dagger means conjugate transpose, so
   :math:`\mathbf b^\dagger\mathbf u_d=\sum_i b_i^*(u_d)_i`.
   For a positive-definite :math:`\mathbf F`, :math:`\alpha,\beta` are real,
   nonnegative powers; :math:`\eta` may be complex. All three have units V².
   With only one pair, simply use :math:`u_b=b/F`, :math:`u_d=d/F`.

   **3. Calculate the common power, then the coefficients.** Use the positive
   square-root branch below. In practice the last expression is
   :math:`\mathbf q=\mathbf u_d-L\mathbf u_b`; no matrix inverse is needed.

   .. k05:equation:: kim-stationary-solution
      :lang: en

      \begin{aligned}
      (P_\star-\alpha)(P_\star-\beta)&=|\eta|^2,\\
      P_\star&=\frac{\alpha+\beta+\sqrt{(\alpha-\beta)^2+4|\eta|^2}}{2},\\
      L&=\frac{\eta}{P_\star-\alpha},\qquad
      \mathbf q=\mathbf F^{-1}(\mathbf d-L\mathbf b).
      \end{aligned}

   **4. Substitute the answers to check the calculation.** All three rows should
   hold within numerical precision. These are the stationary moment constraints
   of Ref. [2], Eqs. (11)–(14), in the notation used here:

   .. k05:equation:: kim-stationary-moments
      :lang: en

      \begin{aligned}
      G&=LP_\star+\mathbf b^\dagger\mathbf q,\\
      P_\star&=LG^*+\mathbf d^\dagger\mathbf q,\\
      \mathbf d&=L\mathbf b+\mathbf F\mathbf q.
      \end{aligned}

   Here :math:`\mathbf b^\dagger\mathbf q=\sum_j b_j^*Q_j`, and similarly for
   :math:`\mathbf d^\dagger\mathbf q`. Substitution checks the algebra, not the assumptions.

   **5. Check whether the result can be interpreted.** The additive power split
   requires :math:`0\le P_\star\le\min(P_X,P_Y)`. A larger value fails this
   necessary check; do not clip it to the bound. If :math:`\mathbf F` is singular
   or poorly conditioned, or :math:`P_\star-\alpha` is zero or too small relative
   to moment uncertainty, the coefficients are not reliably determined.

   The correction recomputes :math:`L` and all :math:`Q_j` together. It is not
   a fixed factor applied to the least-squares growth rate. This step needs
   measured moments, not a prescribed noise waveform or group velocity.
   The measured fourth moment is not automatically noise-free; the assumptions
   stated above are still required.

   .. raw:: html

      </details>

   .. rubric:: 4. Remove propagation phase before reading off growth

   Now :math:`L_f,Q_{fj}` have been estimated. A wave can change phase between
   probes while keeping exactly the same amplitude. Growth must distinguish that
   rotation from a change in size.

   Let :math:`\Delta y` be the signed probe separation in metres and
   :math:`v_{g,f}\ne0` the group velocity along it, in m/s. Choose the probe order
   consistently with propagation, so :math:`\Delta y/v_{g,f}>0`.
   For nonzero cross power :math:`G_f`, take a representative ensemble phase
   :math:`\delta_f` in radians and define rotated coefficients:

   .. k05:equation:: phase-aligned-transfer
      :lang: en

      \delta_f=\arg G_f,\qquad
      \widetilde L_f=e^{-i\delta_f}L_f,\qquad
      \widetilde Q_{fj}=e^{-i\delta_f}Q_{fj}.

   Multiplication by :math:`e^{-i\delta_f}` rotates the second-probe result back
   by its propagation phase. The tilde distinguishes these rotated coefficients
   from the raw fit. The same rotation applies to every quadratic coefficient
   feeding that output frequency.

   .. raw:: html

      <details class="k05-note"><summary>Derive the connection to the spatial wave equation</summary>

   Write a local component as :math:`C_f(y)=a_f(y)e^{i\theta_f(y)}`, with amplitude
   :math:`a_f\ge0` and phase :math:`\theta_f`. The derivative is
   :math:`\partial_y C_f=(\partial_y a_f+i a_f\partial_y\theta_f)e^{i\theta_f}`.
   Approximate the amplitude derivative by the phase-aligned difference and the
   phase derivative by :math:`\delta_f/\Delta y`:

   Let :math:`a_1=a_f(y)`, :math:`a_2=a_f(y+\Delta y)` and
   :math:`\theta_1=\theta_f(y)`. Use the representative phase increment
   :math:`\theta_f(y+\Delta y)-\theta_1\simeq\delta_f`. Then

   .. k05:equation:: phase-aligned-endpoints
      :lang: en

      \begin{aligned}
      X_f&=a_1e^{i\theta_1},\qquad Y_f\simeq a_2e^{i(\theta_1+\delta_f)},\\
      e^{-i\delta_f}Y_f-X_f&\simeq(a_2-a_1)e^{i\theta_1},\\
      (\partial_y a_f)e^{i\theta_1}&\simeq
      \frac{e^{-i\delta_f}Y_f-X_f}{\Delta y}.
      \end{aligned}

   This gives the amplitude part. The second part comes from differentiating
   the phase factor: :math:`\partial_y e^{i\theta_f}=i(\partial_y\theta_f)e^{i\theta_f}`.
   At the first probe,

   .. k05:equation:: phase-gradient-term
      :lang: en

      i a_1(\partial_y\theta_f)e^{i\theta_1}
      \simeq i\frac{\delta_f}{\Delta y}a_1e^{i\theta_1}
      =i\frac{\delta_f}{\Delta y}X_f.

   Add the amplitude and phase parts to recover the derivative of the full coefficient:

   .. k05:equation:: phase-aware-difference
      :lang: en

      \left.\frac{\partial C_f}{\partial y}\right|_y
      \simeq\frac{e^{-i\delta_f}Y_f-X_f}{\Delta y}
      +i\frac{\delta_f}{\Delta y}X_f.

   This is a local finite-difference approximation. It assumes sufficiently small
   amplitude/coefficient changes over the separation and a representative common
   phase increment across records. The principal value of :math:`\arg G_f` is
   only known modulo :math:`2\pi`; interpreting a wavenumber still requires a
   consistent phase branch. A vanishing or poorly determined cross power does
   not supply a reliable rotation.

   :math:`k_{y,f}` is the real wavenumber along the probes, in rad/m;
   :math:`\mathcal V_{fj}` is the continuous quadratic coefficient after grouping
   identical pair products, in :math:`\mathrm{V^{-1}s^{-1}}`.
   :math:`\gamma_f^{(y)}` is the effective amplitude growth inferred along the
   probe direction. In the one-dimensional model it is :math:`\gamma_f`.
   For three-dimensional propagation, transverse variation can also affect it;
   two probes alone do not recover the full three-dimensional growth.

   Insert :k05:eq:`phase-aware-difference` into
   :k05:eq:`frequency-equation-1d`. After multiplying by :math:`\Delta y/v_{g,f}`
   and rearranging, compare the coefficients of :math:`X_f` and each :math:`Z_j`:

   For clarity, write :math:`\widetilde Y_f=e^{-i\delta_f}Y_f`.
   With the pair products already grouped, the substitutions are

   .. k05:equation:: coefficient-substitution-steps
      :lang: en

      \begin{aligned}
      v_{g,f}\left[\frac{\widetilde Y_f-X_f}{\Delta y}
      +i\frac{\delta_f}{\Delta y}X_f\right]
      &\simeq(\gamma_f^{(y)}+ik_{y,f}v_{g,f})X_f+\sum_j\mathcal V_{fj}Z_j,\\
      \widetilde Y_f-X_f+i\delta_fX_f
      &\simeq\left(\frac{\gamma_f^{(y)}\Delta y}{v_{g,f}}+ik_{y,f}\Delta y\right)X_f
      +\sum_j\frac{\mathcal V_{fj}\Delta y}{v_{g,f}}Z_j,\\
      \widetilde Y_f
      &\simeq\left[1+\frac{\gamma_f^{(y)}\Delta y}{v_{g,f}}
      +i(k_{y,f}\Delta y-\delta_f)\right]X_f
      +\sum_j\frac{\mathcal V_{fj}\Delta y}{v_{g,f}}Z_j.
      \end{aligned}

   The second line multiplies by :math:`\Delta y/v_{g,f}`; the third moves
   :math:`-X_f+i\delta_fX_f` to the right. The rotated fitted model is
   :math:`\widetilde Y_f=\widetilde L_fX_f+\sum_j\widetilde Q_{fj}Z_j`
   for its modelled part. Thus the bracket is :math:`\widetilde L_f` and
   each multiplier of :math:`Z_j` is :math:`\widetilde Q_{fj}`:

   .. k05:equation:: discrete-continuous-coefficients
      :lang: en

      \begin{aligned}
      \widetilde L_f&\simeq1+\frac{\gamma_f^{(y)}\Delta y}{v_{g,f}}
      +i(k_{y,f}\Delta y-\delta_f),\\
      \widetilde Q_{fj}&\simeq\frac{\mathcal V_{fj}\Delta y}{v_{g,f}}.
      \end{aligned}

   The raw coefficients are obtained by multiplying these expressions by
   :math:`e^{i\delta_f}`, which gives the structure of Ref. [1], Eq. (4).

   .. raw:: html

      </details>

   Write :math:`\gamma_f^{(y)}` for the effective amplitude growth along the
   probe direction, in :math:`\mathrm{s^{-1}}`, and :math:`\mathcal V_{fj}`
   for the continuous coupling coefficient of the same grouped pair, in
   :math:`\mathrm{V^{-1}s^{-1}}`. The resulting conversion is

   .. _k05-source-4-en:

   .. container:: k05-paper-match

      .. rubric:: K05 and reference [1], Eq. (4)

      .. k05:equation:: inferred-growth-coupling
         :lang: en

         \gamma_f^{(y)}\simeq\frac{v_{g,f}}{\Delta y}
         \left[\operatorname{Re}(\widetilde L_f)-1\right],\qquad
         \mathcal V_{fj}\simeq\frac{v_{g,f}}{\Delta y}\widetilde Q_{fj}.

      **Original equation, original notation — [1], (4)**

      .. k05:equation:: paper-equation-4
         :lang: en

         \begin{aligned}
         L_f&=\left[\left(\frac{\gamma_{f(y)}}{v_{g(y)}}+ik_y\right)\Delta y
         +1-i\Delta\Theta_f\right]e^{i\Delta\Theta_f},\\
         Q_f^{1,2}&=e^{i\Delta\Theta_f}V^Q_{1,2}\Delta y/v_{g(y)}.
         \end{aligned}

      **Symbol map.** :math:`\Delta\Theta_f` is our :math:`\delta_f`,
      the cross-power phase in radians; :math:`v_{g(y)}` is our :math:`v_{g,f}`.
      :math:`\gamma_{f(y)}` is our :math:`\gamma_f^{(y)}`, the effective azimuthal
      amplitude rate. The article's :math:`V^Q_{1,2}` becomes :math:`\mathcal V_{fj}`
      after identical products have been grouped. :math:`\Delta y` is the probe separation.

      **Why the tilde matters.** The original :math:`L_f,Q_f^{1,2}` include
      :math:`e^{i\Delta\Theta_f}`. K05 writes :math:`\widetilde L=e^{-i\delta}L`
      and :math:`\widetilde Q=e^{-i\delta}Q`, then takes the real part.
      The article's sentence after Eq. (5) prints :math:`\operatorname{Re}L_f-1`
      without restating that rotation. We keep the distinction explicit, rather
      than claiming to know its unpublished implementation. Both least squares
      and Kim estimate coefficients in this same model; neither supplies :math:`v_g`
      from the moments alone.


   :math:`v_g/\Delta y` supplies the missing inverse seconds. Positive
   :math:`\gamma_f^{(y)}` means amplitude growth in this local model; negative
   means damping. The group velocity is separate information: the moments alone
   do not determine it. Ref. [1] estimates it from a theoretical dispersion relation.

   .. rubric:: 5. Combine a coupling coefficient with its bispectrum

   Return to the continuous mean-square balance :k05:eq:`spectral-power-balance`.
   For pair :math:`j`, its auto-bispectrum is :math:`b_j^*=\langle Z_jX_f^*\rangle_R`.
   Its contribution is

   .. _k05-source-6-en:

   .. container:: k05-paper-match

      .. rubric:: K05 and reference [1], Eq. (6)

      .. k05:equation:: inferred-pair-transfer
         :lang: en

         \begin{aligned}
         \mathcal T_{fj}&=2\operatorname{Re}(\mathcal V_{fj}b_j^*)
         \simeq\frac{2v_{g,f}}{\Delta y}\operatorname{Re}(\widetilde Q_{fj}b_j^*),\\
         v_{g,f}\partial_yP_f&=2\gamma_f^{(y)}P_f+\sum_j\mathcal T_{fj}.
         \end{aligned}

      **Original equation, original notation — [1], (6)**

      .. k05:equation:: paper-equation-6
         :lang: en

         T_f=(v_{g(y)}/\Delta y)\operatorname{Re}\!\left[
         \sum_{f=f_1+f_2}e^{-i\Delta\Theta_f}Q_f^{1,2}X_{f_1}X_{f_2}X_f^*\right].

      **Symbol map.** The article's :math:`T_f` sums all retained pairs
      feeding target :math:`f`. Our :math:`\mathcal T_{fj}` is one pair's contribution
      to the **full** mean-square rate. With the same amplitude normalization and
      pair counting, :math:`T_f^{[1]}=\tfrac12\sum_j\mathcal T_{fj}`.
      The data implementation averages :math:`X_{f_1}X_{f_2}X_f^*` over records;
      the printed expression does not show the brackets.

      This factor follows from :math:`d|C|^2/dt=2\operatorname{Re}(C^*\dot C)`.
      It is not a change of sign or a claim about the author's code. Page 09 labels
      the reference-form calculation :math:`T^{(1/2)}_{V,f}` and reports V²/s.
      The subscript V keeps the measured voltage observable visible; this is not
      automatically a calibrated plasma-energy density rate. A bright :math:`|Q|`
      map omits the triple-product phase and therefore cannot replace this signed sum.


   :math:`\mathcal T_{fj}` has units :math:`\mathrm{V^2/s}`. A positive value
   adds mean-square fluctuation to target :math:`f`; a negative value removes it.
   Its sign depends on the relative phase of the complex coefficient and bispectrum,
   not just their magnitudes. This target-mode contribution does not by itself
   allocate a separate energy loss to each of the two input modes.

   The factor 2 comes from differentiating amplitude squared. Thus near a spatially
   stationary state, linear drive and nonlinear removal can balance even though
   both rates are nonzero. A physical wave-energy budget additionally needs the
   plasma-response weighting, as explained on the previous page.

   .. raw:: html

      <details class="k05-note"><summary>Finite probe spacing: why the discrete power balance has another term</summary>

   For the exact fitted model with zero residual, expand
   :math:`|Y|^2=|LX+\sum_j Q_jZ_j|^2` and average. The linear square gives
   :math:`|L|^2P_X`, the two cross terms give
   :math:`2\operatorname{Re}(L^*\mathbf b^\dagger\mathbf q)`, and the quadratic
   square gives :math:`\mathbf q^\dagger\mathbf F\mathbf q`. Hence

   .. k05:equation:: finite-probe-power-budget
      :lang: en

      \begin{aligned}
      P_Y-P_X&=(|L|^2-1)P_X
      +2\operatorname{Re}(L^*\mathbf b^\dagger\mathbf q)
      +\mathbf q^\dagger\mathbf F\mathbf q,\\
      g_P^{\Delta}&=\frac{v_g}{\Delta y}(|L|^2-1),\\
      \mathcal T^{\Delta}&=\frac{v_g}{\Delta y}
      \left[2\operatorname{Re}(L^*\mathbf b^\dagger\mathbf q)
      +\mathbf q^\dagger\mathbf F\mathbf q\right].
      \end{aligned}

   Here :math:`g_P^{\Delta}` is a finite-separation **power** growth coefficient,
   not the amplitude rate :math:`\gamma`; :math:`\mathcal T^{\Delta}` is the
   corresponding finite-separation nonlinear contribution. The superscript
   :math:`\Delta` labels the finite step. Multiplying the first line by
   :math:`v_g/\Delta y` gives the total mean-square change per propagation time.
   These are the algebraic terms used in Kim's finite-step power balance
   (Ref. [2], Sec. II, pp. 3999–4000).

   For a sufficiently short step with the phase handled consistently,
   :math:`g_P^{\Delta}\to2\gamma` and :math:`\mathcal T^{\Delta}\to\sum_j\mathcal T_{fj}`.
   The :math:`Q^2` term becomes higher order because :math:`Q=O(\Delta y)`.
   It need not be negligible at finite spacing. For an ordinary least-squares fit,
   orthogonality removes cross terms with the residual, but the measured output
   power also contains :math:`\langle|\varepsilon|^2\rangle_R`. Kim's modelled-power
   system has its own nonideal-power assumptions; these two treatments must not be mixed.

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>How this transfer normalization compares with Ref. [1], Eq. (6)</summary>

   Writing its measured products as ensemble averages, the displayed expression
   in Ref. [1] is

   .. k05:equation:: reference-transfer-convention
      :lang: en

      T_f^{\mathrm{[1]}}=\frac{v_{g,f}}{\Delta y}
      \operatorname{Re}\!\left[\sum_{f_1+f_2=f}
      e^{-i\delta_f}Q_f^{1,2}\langle X_{f_1}X_{f_2}X_f^*\rangle_R\right].

   With identical coefficient normalization and identical pair counting, this is
   one half of the continuous nonlinear contribution in
   :k05:eq:`inferred-pair-transfer`. The latter follows directly from
   :math:`\partial_y|C|^2=2\operatorname{Re}(C^*\partial_yC)`.
   We therefore use distinct symbols for the displayed reference expression and
   the explicitly derived continuous contribution. Matching a published transfer
   curve requires matching its amplitude normalization, pair convention and
   definition of transfer; a factor of two cannot be discarded silently.
   This distinction also separates both expressions from the finite-step
   :math:`\mathcal T^{\Delta}` above.

   .. raw:: html

      </details>

   The calculation now has a complete chain: records give moments; moments
   constrain coefficients; phase, spacing and group velocity convert coefficients
   to rates.

   **What is closed, and what still needs physical input?** Once the retained pairs,
   Fourier convention and estimator assumptions are fixed, the moments close the
   algebraic coefficient problem, provided the matrices are identifiable. Kim's
   common power is another inferred quantity, not an externally supplied parameter.
   That closes a statistical model; it does not supply all inputs for a physical rate.

   - **For rates in inverse seconds:** supply the signed separation and probe order,
     a reliable propagation phase after correcting channel delay/response, and the
     group velocity along the probes. Phase velocity inferred from phase delay is
     not automatically group velocity. A theoretical group velocity needs a chosen
     dispersion branch and its plasma inputs, such as electron temperature, density,
     magnetic field, electric field/drift and ion species. These are inputs to that
     physical model, not additional moments determined by the fit.
   - **For physical wave energy:** additionally specify the conversion from recorded
     voltage to the fluctuation of interest, the probe response, and the plasma
     energy weighting. V²/s alone is a mean-square-voltage rate. Transverse transport
     must also be assessed before identifying a two-probe effective rate with full
     three-dimensional growth.

   The :ref:`probe-response page <k05-response-en>` and
   :ref:`interpretation supplement <k05-budget-en>` discuss these inputs and checks.


   .. rubric:: Continue the reading

   The next page starts from real synchronized waveforms and constructs the statistics used here.

   :ref:`Next page <k05-experiment-en>`.

   .. rubric:: References

   .. _k05-inference-reference-1-en:

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   .. _k05-inference-reference-2-en:

   [2] J. S. Kim, R. D. Durst, R. J. Fonck, E. Fernandez, A. Ware and P. W. Terry,
   “Technique for the experimental estimation of nonlinear energy transfer in
   fully developed turbulence,” *Physics of Plasmas* **3**, 3998–4009 (1996).
   `doi:10.1063/1.871572 <https://doi.org/10.1063/1.871572>`_.

   Ref. [1], p. 115101-3, supplies the two-probe model and phase-dependent transfer functions. Ref. [2], Secs. II–III, supplies the finite-step power budget and modified stationary moment method. The expanded matrix example, computation recipe and intermediate phase-derivative steps are explanatory additions.

.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-inference-zh:

   .. rubric:: 从测得的平均量，到增长与耦合

   :ref:`上一页面 <k05-statistics-zh>` 已经给出了功率、互谱和双谱。
   现在把问题问得更具体一些：**第二支探针在某个频率上的信号，有多少可以用第一支探针的同频分量解释，
   又有多少需要用其他频率的乘积解释？**

   先把这两部分放在一起求出，再把系数换成变化率。本页面沿用 Brown 与 Jorns |ref-zh| 的双探针模型，
   并在下面明确 Kim 方法 |kim-zh| 增加的统计假设。傅里叶系数始终采用
   :k05:eq:`time-fourier-series` 的符号与归一化。

   .. rubric:: 1. 固定一个输出频率，列出可能的贡献

   选定目标频率 :math:`f`。第 :math:`r` 段记录在第一支探针处给出 :math:`X_f^{(r)}`，
   在第二支探针处给出 :math:`Y_f^{(r)}`。选取 :math:`J` 个频率之和为 :math:`f` 的不同波对，
   把每个波对的乘积记作 :math:`Z_j^{(r)}`。这里 :math:`j` 数波对，:math:`r` 数记录，
   下标中的 1、2 分别标记第 :math:`j` 对的两个输入频率。

   .. _k05-source-3-zh:

   .. container:: k05-paper-match

      .. rubric:: K05 与文献 [1] 式 (3) 对照

      .. k05:equation:: two-probe-quadratic-model
         :lang: zh

         \begin{aligned}
         Z_j^{(r)}&=X_{f_{1j}}^{(r)}X_{f_{2j}}^{(r)},\qquad f_{1j}+f_{2j}=f,\\
         Y_f^{(r)}&=L_fX_f^{(r)}+\sum_{j=1}^{J}Q_{fj}Z_j^{(r)}+\varepsilon_f^{(r)}.
         \end{aligned}

      **文献原式与原符号 — [1], (3)**

      .. k05:equation:: paper-equation-3
         :lang: zh

         Y_f=L_fX_f+\sum_{f=f_1+f_2}Q_f^{1,2}X_{f_1}X_{f_2}.

      **符号对照。** :math:`X_f=\hat\phi_f(y)`、
      :math:`Y_f=\hat\phi_f(y+\Delta y)` 表示两个位置，不是两类波。
      本页的上标 :math:`(r)` 标记第几段记录，文献省略了这个标签。
      :math:`Z_j=X_{f_{1j}}X_{f_{2j}}` 把一个乘积写短，:math:`Q_{fj}` 是它的系数；
      文献把这一对输入写成 :math:`Q_f^{1,2}` 的上标 :math:`1,2`。

      K05 明确保留残差 :math:`\varepsilon_f^{(r)}`，文献印刷模型没有这一项。
      波对的计数也要一致：去重后的非对角系数合并了两个有序系数。
      这里的 :math:`\varepsilon` 不是介电函数，记录标签 :math:`r` 也不是实部下标。
      :ref:`第 07 页 <k05-validation-zh>` 用没有参与拟合的记录检验这个模型。


   :math:`L_f` 是 **线性传递系数（linear transfer coefficient）** ，乘在已经位于 :math:`f` 的分量上。
   :math:`Q_{fj}` 是 **二次传递系数（quadratic transfer coefficient）** ，乘在一对分量的乘积上。
   两者都是复数，既描述大小，也描述相位。在选定的 :math:`R` 段记录中，我们用同一组系数。
   :math:`\varepsilon_f^{(r)}` 是模型没能解释的剩余部分，称为 **残差（residual）** 。
   把它置零，就得到文献 [1] 公式 (3) 的结构。

   :math:`X,Y` 的单位为 V，:math:`Z` 为 :math:`\mathrm{V^2}`，:math:`L` 无量纲，
   :math:`Q` 为 :math:`\mathrm{V^{-1}}`。因此 :math:`L,Q` 首先描述两个位置之间的变化，
   还不是“每秒变化多少”的速率。

   .. raw:: html

      <details class="k05-note"><summary>究竟列哪些波对？为什么不把两个顺序都列出来？</summary>

   例如目标为 :math:`f=6\Delta f`，其中 :math:`\Delta f` 是频率网格间隔，
   正频率波对 :math:`(\Delta f,5\Delta f)`、:math:`(2\Delta f,4\Delta f)`、
   :math:`(3\Delta f,3\Delta f)` 给出三个不同乘积。若保留的频带允许，带符号频率还可以给出
   :math:`(-\Delta f,7\Delta f)` 这样的差频贡献。这只是例子，不是任意实验的完整波对清单。

   由于 :math:`X_aX_b=X_bX_a`，把两个顺序都列出，会产生完全相同的预测量列。
   数据无法分别识别它们的两个系数。对 :math:`a\ne b`，本页一个系数合并原有序求和的两项：
   :math:`Q_j=Q_f^{a,b}+Q_f^{b,a}`；对 :math:`a=b`，只保留原来的一项。
   后面连续方程的系数 :math:`\mathcal V_{fj}` 采用同样的合并方式，合并后不要再额外乘 2。

   实信号满足 :math:`X_{-f}=X_f^*`，因此可以从保存的正频率系数恢复负频率输入。
   选取波对还要符合测量带宽以及前面页面的模式假设。

   .. raw:: html

      </details>

   .. rubric:: 2. 把许多段记录，变成求未知系数的方程

   先只保留一个波对。为了看清代数，暂时省略固定的目标下标 :math:`f` 和波对下标 :math:`j`。
   每段记录的 :math:`X,Y,Z` 不同，但待求的 :math:`L,Q` 相同：

   .. k05:equation:: single-pair-records
      :lang: zh

      \begin{aligned}
      Y^{(1)}&=LX^{(1)}+QZ^{(1)}+\varepsilon^{(1)},\\
      Y^{(2)}&=LX^{(2)}+QZ^{(2)}+\varepsilon^{(2)},\\
      &\ \vdots
      \end{aligned}

   一个有用的操作是：每段方程先乘 :math:`X^*`，再平均；然后改为乘 :math:`Z^*`，再平均。
   这就留下了区分两个贡献所需的两种关系。把测得的平均量简记为：

   .. k05:equation:: inference-moments
      :lang: zh

      \begin{aligned}
      P&=\langle |X|^2\rangle_R,&G&=\langle YX^*\rangle_R,\\
      b&=\langle XZ^*\rangle_R,&d&=\langle YZ^*\rangle_R,\\
      F&=\langle |Z|^2\rangle_R.
      \end{aligned}

   :math:`P` 是第一支探针的功率，:math:`G` 是它与第二支探针之间的互谱。
   :math:`b` 是 :k05:eq:`auto-bispectrum` 所定义自双谱的 **共轭** ，
   :math:`d` 是 :k05:eq:`cross-bispectrum` 中的互双谱，单位均为 :math:`\mathrm{V^3}`。
   :math:`F=\langle|X_{f_1}X_{f_2}|^2\rangle_R` 是 **四阶矩（fourth-order moment）** ，
   单位 :math:`\mathrm{V^4}`。它出现是因为 :math:`Z` 本身已经包含两个傅里叶系数。

   若残差满足 :math:`\langle\varepsilon X^*\rangle_R=0`、
   :math:`\langle\varepsilon Z^*\rangle_R=0`，就得到：

   .. _k05-source-5-zh:

   .. container:: k05-paper-match

      .. rubric:: K05 与文献 [1] 式 (5) 对照

      .. k05:equation:: single-pair-moment-equations
         :lang: zh

         \begin{aligned}
         G&=LP+Qb^*,\\
         d&=Lb+QF.
         \end{aligned}

      **文献原式与原符号 — [1], (5)**

      .. k05:equation:: paper-equation-5
         :lang: zh

         \begin{aligned}
         Y_fX_f^*&=L_fX_fX_f^*+\sum_{f=f_1+f_2}Q_f^{1,2}X_{f_1}X_{f_2}X_f^*,\\
         Y_fX_{f_1}^*X_{f_2}^*&=L_fX_fX_{f_1}^*X_{f_2}^*\\
         &\quad+\sum_{f=f_1+f_2}Q_f^{1,2}X_{f_1}X_{f_2}X_{f_1}^*X_{f_2}^*.
         \end{aligned}

      **符号与平均。** 对原式中的乘积作分段平均，就得到本页的统计矩。
      第一行成为 :math:`G=LP+\sum_jQ_jb_j^*`；乘上选定波对的
      :math:`Z_i^*`，第二行成为 :math:`d_i=Lb_i+\sum_jF_{ij}Q_j`。
      这里 :math:`b_i=\langle XZ_i^*\rangle` 是自双谱的共轭，
      :math:`d_i=\langle YZ_i^*\rangle` 是交叉双谱，
      :math:`F_{ij}=\langle Z_i^*Z_j\rangle` 是四阶矩。

      **原式重复的标签需要怎样读？** 印刷第二行同时用 :math:`f_1,f_2`
      标记相乘的波对和求和中的波对，上方保留了这个写法。
      真正计算多个波对时，选定的方程行应固定，求和波对应变化；
      所以 K05 用不同的 :math:`i,j` 区分，并在 :k05:eq:`inference-matrix`
      保留非对角四阶矩。不能把原式的简写当成删除交叉项的依据。
      残差交叉矩消失与 Kim 额外施加的平稳功率假设，是不同条件，下文分别解释。


   除了 :math:`L,Q`，其余量都来自测量。 **双谱提供了求系数所需的额外方程，但双谱本身并不等于耦合系数。** 

   .. raw:: html

      <details class="k05-note"><summary>展开两次相乘，再一步步解出两个系数</summary>

   乘 :math:`X^*` 得到 :math:`YX^*=L|X|^2+QZX^*+\varepsilon X^*`。
   平均后，因为 :math:`\langle ZX^*\rangle_R=b^*`，第一式就是 :math:`G=LP+Qb^*`。
   乘 :math:`Z^*` 则得到 :math:`YZ^*=LXZ^*+Q|Z|^2+\varepsilon Z^*`，平均后为 :math:`d=Lb+QF`。

   第一式乘 :math:`F`，第二式乘 :math:`b^*`，再相减，含 :math:`QFb^*` 的项抵消：
   :math:`FG-b^*d=L(PF-|b|^2)`。
   要消去 :math:`L`，则计算 :math:`Pd-bG=Q(PF-|b|^2)`。
   所以当 :math:`\Delta>0` 时：

   .. k05:equation:: single-pair-estimator
      :lang: zh

      \begin{aligned}
      \Delta&=PF-|b|^2,\\
      L&=\frac{FG-b^*d}{\Delta},\qquad
      Q=\frac{Pd-bG}{\Delta}.
      \end{aligned}

   这里 :math:`\Delta` 是行列式，不是探针间距，单位为 :math:`\mathrm{V^6}`。
   两个分式分别得到无量纲的 :math:`L` 和单位为 :math:`\mathrm{V^{-1}}` 的 :math:`Q`。

   .. raw:: html

      </details>

   .. rubric:: 3. 线性和二次部分，要一起估计

   如果直接舍去二次贡献，只做线性计算，就会得到 :math:`G/P`。但第一条矩方程实际表示：

   .. k05:equation:: linear-only-bias
      :lang: zh

      \frac{G}{P}=L+Q\frac{b^*}{P}.

   只要波对乘积与目标分量相关，二次贡献就会有一部分混入这个“只拟合线性”的结果。
   因此需要联合估计 :math:`L,Q`，不能先把测到的全部变化认作线性增长。

   .. raw:: html

      <details class="k05-note"><summary>多个波对：把同样的方程排成矩阵</summary>

   先只保留两个馈入 6 MHz 的波对：(1, 5) MHz 和 (2, 4) MHz。
   记 :math:`X=X_{6\,\mathrm{MHz}}`、:math:`Y=Y_{6\,\mathrm{MHz}}`，
   :math:`Z_1=X_{1\,\mathrm{MHz}}X_{5\,\mathrm{MHz}}`、
   :math:`Z_2=X_{2\,\mathrm{MHz}}X_{4\,\mathrm{MHz}}`。
   这些频率仅用于说明矩阵怎样排列。现在有三个未知数：:math:`L,Q_1,Q_2`。
   把 :math:`Y=LX+Q_1Z_1+Q_2Z_2+\varepsilon` 分别乘上
   :math:`X^*`、:math:`Z_1^*` 和 :math:`Z_2^*`，再平均，就得到三行：

   .. k05:equation:: two-pair-rows
      :lang: zh

      \begin{aligned}
      G&=PL+b_1^*Q_1+b_2^*Q_2,\\
      d_1&=b_1L+F_{11}Q_1+F_{12}Q_2,\\
      d_2&=b_2L+F_{21}Q_1+F_{22}Q_2.
      \end{aligned}

   其中 :math:`b_i=\langle XZ_i^*\rangle_R`、:math:`d_i=\langle YZ_i^*\rangle_R`，
   :math:`F_{ij}=\langle Z_i^*Z_j\rangle_R`。
   例如，:math:`F_{12}=\langle Z_1^*Z_2\rangle_R` 来自“第二个波对的贡献乘上第一个波对的共轭”；
   :math:`F_{21}=F_{12}^*`。这里仍沿用前面残差互矩为零的条件。
   按 :math:`L,Q_1,Q_2` 的顺序把三个未知数排成一列，三行方程就变成：

   .. k05:equation:: two-pair-matrix
      :lang: zh

      \begin{pmatrix}
      P&b_1^*&b_2^*\\
      b_1&F_{11}&F_{12}\\
      b_2&F_{21}&F_{22}
      \end{pmatrix}
      \begin{pmatrix}L\\Q_1\\Q_2\end{pmatrix}
      =\begin{pmatrix}G\\d_1\\d_2\end{pmatrix}.

   用矩阵第二行乘未知数列，就原样得到上面的第二条方程。
   左边矩阵和右边向量里的数都由记录平均得到；只有中间那列是待求的系数。
   第一行各项单位为 V²，后两行各项单位为 V³；要求的是同一行内单位相同。
   每多保留一个波对，就多一个未知系数，也多一行和一列。

   有 :math:`J` 个波对时，用列向量 :math:`\mathbf b,\mathbf d,\mathbf q` 各保存每个波对的一项，
   用 :math:`J\times J` 矩阵 :math:`\mathbf F` 保存波对之间的四阶矩：

   .. k05:equation:: inference-matrix
      :lang: zh

      \begin{aligned}
      b_i&=\langle XZ_i^*\rangle_R,\quad
      d_i=\langle YZ_i^*\rangle_R,\quad
      F_{ij}=\langle Z_i^*Z_j\rangle_R,\\
      \begin{pmatrix}P&\mathbf b^\dagger\\\mathbf b&\mathbf F\end{pmatrix}
      \begin{pmatrix}L\\\mathbf q\end{pmatrix}
      &=\begin{pmatrix}G\\\mathbf d\end{pmatrix},\qquad
      \mathbf q=(Q_1,\ldots,Q_J)^T.
      \end{aligned}

   上标 :math:`T` 表示转置，:math:`\dagger` 表示共轭转置。矩阵第一行就是功率／互谱方程。
   下面第 :math:`i` 行来自乘 :math:`Z_i^*` 再平均；其中每个波对 :math:`j` 都通过 :math:`F_{ij}` 参与。
   非对角元表示不同波对乘积之间的相关性；除非另加闭合假设，否则不能直接删掉。本页保留这些项。

   这就是线性—二次模型的完整矩方程。对记录样本，它也是 **复数最小二乘（complex least squares）** 
   的正规方程：选择系数，使所有 :math:`|\varepsilon^{(r)}|^2` 的总和最小。
   拟合后的残差在该样本上与预测量正交，是这种计算本身保证的性质；
   它不能单独证明测量误差不相关，也不能证明拟合系数就是物理系数。

   .. raw:: html

      </details>

   实际探针数据还有一个问题：噪声不只进入第二支探针，也可能进入第一支。
   增加平均次数并不会自动消除这种偏差。Brown 与 Jorns |ref-zh| 采用 Kim 等人 |kim-zh|
   对 Ritz 方法的修正，并使用两位置功率近似相等的条件。这比上面的联合最小二乘代数，
   多了一层物理与统计假设。

   这里额外假定两处 **归属于模型的功率** 相同，记为 :math:`P_\star`；实测总功率仍可不同。
   同时按文献 [2] 第 III B 节忽略指定的非理想混合矩贡献；仅有两两不相关，
   并不能保证三阶、四阶矩都满足这个要求。在这些假设下，下面一起求出共同功率和系数。
   共同功率不变不等于线性增长为零：线性驱动仍可与非线性移出相平衡。

   .. raw:: html

      <details class="k05-note" id="k05-kim-correction-zh"><summary>Kim 修正：从统计量算出共同功率和系数</summary>

   要算出的结果是共同模型功率 :math:`P_\star`、线性系数 :math:`L`，以及
   波对系数列 :math:`\mathbf q=(Q_1,\ldots,Q_J)^T`。
   :math:`P_\star` 是实数，单位 V²；星号是名称的一部分，不表示共轭。
   它表示两探针处分别归属于模型的同一个功率，并不是把两个实测功率取算术平均。
   :math:`L` 无量纲，各 :math:`Q_j` 的单位为 V⁻¹。
   每个目标频率分别按下面的步骤计算 |kim-zh|。

   **1. 从同一批成对记录计算输入。** 保留实测功率
   :math:`P_X=\langle|X|^2\rangle_R`、:math:`P_Y=\langle|Y|^2\rangle_R`，用于最后检查。
   按 :k05:eq:`inference-moments` 和 :k05:eq:`inference-matrix` 计算
   :math:`G,\mathbf b,\mathbf d,\mathbf F`，保留 :math:`\mathbf F` 的非对角元。

   **2. 先解两个线性方程组，再计算三个数。**

   .. k05:equation:: kim-computation-quantities
      :lang: zh

      \begin{aligned}
      \mathbf F\mathbf u_b&=\mathbf b,\qquad \mathbf F\mathbf u_d=\mathbf d,\\
      \alpha&=\mathbf b^\dagger\mathbf u_b,\qquad
      \beta=\mathbf d^\dagger\mathbf u_d,\qquad
      \eta=G-\mathbf b^\dagger\mathbf u_d.
      \end{aligned}

   :math:`\mathbf u_b,\mathbf u_d` 是刚解出的辅助列向量，单位 V⁻¹，不是额外测量。
   :math:`\dagger` 表示共轭转置，例如
   :math:`\mathbf b^\dagger\mathbf u_d=\sum_i b_i^*(u_d)_i`。
   当 :math:`\mathbf F` 正定时，:math:`\alpha,\beta` 是非负实数，:math:`\eta` 可以为复数；
   三者单位均为 V²。只有一个波对时，直接用 :math:`u_b=b/F`、:math:`u_d=d/F` 即可。

   **3. 先算共同功率，再算系数。** 取下面带正平方根的分支。
   实际计算最后一项时，用 :math:`\mathbf q=\mathbf u_d-L\mathbf u_b`，不必显式求逆矩阵。

   .. k05:equation:: kim-stationary-solution
      :lang: zh

      \begin{aligned}
      (P_\star-\alpha)(P_\star-\beta)&=|\eta|^2,\\
      P_\star&=\frac{\alpha+\beta+\sqrt{(\alpha-\beta)^2+4|\eta|^2}}{2},\\
      L&=\frac{\eta}{P_\star-\alpha},\qquad
      \mathbf q=\mathbf F^{-1}(\mathbf d-L\mathbf b).
      \end{aligned}

   **4. 把结果代回，检查是否算对。** 下面三行应在数值精度内同时成立。
   它们是文献 [2] 公式 (11)–(14) 在本页记号下的平稳矩约束：

   .. k05:equation:: kim-stationary-moments
      :lang: zh

      \begin{aligned}
      G&=LP_\star+\mathbf b^\dagger\mathbf q,\\
      P_\star&=LG^*+\mathbf d^\dagger\mathbf q,\\
      \mathbf d&=L\mathbf b+\mathbf F\mathbf q.
      \end{aligned}

   这里 :math:`\mathbf b^\dagger\mathbf q=\sum_j b_j^*Q_j`，
   :math:`\mathbf d^\dagger\mathbf q` 同理。代回成立只证明代数自洽，并不证明物理假设成立。

   **5. 再检查结果是否允许作相应解释。** 模型功率加上非负非理想功率的假设要求
   :math:`0\le P_\star\le\min(P_X,P_Y)`。若超过上界，就未通过这项必要检查，不能把结果截到上界。
   若 :math:`\mathbf F` 奇异或病态，或者 :math:`P_\star-\alpha` 为零、
   或相对于统计矩的不确定度过小，就不能可靠地区分系数，应记录失败原因。

   修正会一起重新求出 :math:`L` 和所有 :math:`Q_j`，不是给最小二乘增长率乘固定因子。
   此步输入都是实测统计矩，不需要预先指定噪声波形或群速度。
   但实测四阶矩不会自动变成无噪声量，仍须满足上面说明的模型条件。

   .. raw:: html

      </details>

   .. rubric:: 4. 先去掉传播相位，再读出增长

   现在已经估计出 :math:`L_f,Q_{fj}`。但波可以在两探针之间只转过一个相位，幅值完全不变。
   求增长率时，必须把这种旋转与大小变化分开。

   设 :math:`\Delta y` 为带符号探针间距，单位 m；:math:`v_{g,f}\ne0` 为沿该方向的群速度，单位 m/s。
   探针顺序与传播方向采用一致约定，使 :math:`\Delta y/v_{g,f}>0`。
   当互谱 :math:`G_f` 非零时，以它的相位作为这组记录的代表性相位增量 :math:`\delta_f`，单位 rad，定义：

   .. k05:equation:: phase-aligned-transfer
      :lang: zh

      \delta_f=\arg G_f,\qquad
      \widetilde L_f=e^{-i\delta_f}L_f,\qquad
      \widetilde Q_{fj}=e^{-i\delta_f}Q_{fj}.

   乘 :math:`e^{-i\delta_f}` 相当于把第二支探针结果的传播相位转回来。
   波浪号区分旋转后的系数与原始拟合系数；所有馈入同一个输出频率的二次系数，都要做相同旋转。

   .. raw:: html

      <details class="k05-note"><summary>展开它与空间波动方程的对应关系</summary>

   把局部分量写为 :math:`C_f(y)=a_f(y)e^{i\theta_f(y)}`，其中 :math:`a_f\ge0` 是幅值，
   :math:`\theta_f` 是相位。求导得到
   :math:`\partial_y C_f=(\partial_y a_f+i a_f\partial_y\theta_f)e^{i\theta_f}`。
   幅值导数用相位对齐后的差分近似，相位导数用 :math:`\delta_f/\Delta y` 近似：

   具体地，令 :math:`a_1=a_f(y)`、:math:`a_2=a_f(y+\Delta y)`，
   :math:`\theta_1=\theta_f(y)`。用共同的代表性相位增量近似每段记录的相位差：
   :math:`\theta_f(y+\Delta y)-\theta_1\simeq\delta_f`，于是

   .. k05:equation:: phase-aligned-endpoints
      :lang: zh

      \begin{aligned}
      X_f&=a_1e^{i\theta_1},\qquad Y_f\simeq a_2e^{i(\theta_1+\delta_f)},\\
      e^{-i\delta_f}Y_f-X_f&\simeq(a_2-a_1)e^{i\theta_1},\\
      (\partial_y a_f)e^{i\theta_1}&\simeq
      \frac{e^{-i\delta_f}Y_f-X_f}{\Delta y}.
      \end{aligned}

   这样得到了幅值变化的部分。另一部分来自对相位因子求导：
   :math:`\partial_y e^{i\theta_f}=i(\partial_y\theta_f)e^{i\theta_f}`。
   在第一支探针处，它给出

   .. k05:equation:: phase-gradient-term
      :lang: zh

      i a_1(\partial_y\theta_f)e^{i\theta_1}
      \simeq i\frac{\delta_f}{\Delta y}a_1e^{i\theta_1}
      =i\frac{\delta_f}{\Delta y}X_f.

   把幅值部分和相位部分加起来，才得到原来整个复系数的空间导数：

   .. k05:equation:: phase-aware-difference
      :lang: zh

      \left.\frac{\partial C_f}{\partial y}\right|_y
      \simeq\frac{e^{-i\delta_f}Y_f-X_f}{\Delta y}
      +i\frac{\delta_f}{\Delta y}X_f.

   这是局部有限差分近似，要求间距内幅值、系数变化足够小，且各段可用一个有代表性的共同相位增量。
   :math:`\arg G_f` 的主值只确定到模 :math:`2\pi`；若要解释波数，还需选择一致的相位分支。
   互谱接近零或相位估计不可靠时，不能得到可靠的旋转。

   :math:`k_{y,f}` 是沿探针方向的实波数，单位 rad/m；:math:`\mathcal V_{fj}` 是合并相同波对乘积后
   连续方程的二次系数，单位 :math:`\mathrm{V^{-1}s^{-1}}`。
   :math:`\gamma_f^{(y)}` 是沿探针方向推断的有效幅值增长率。
   在一维模型中它等于 :math:`\gamma_f`；三维传播中，横向变化也可能影响它，
   仅凭两支探针不能恢复完整三维增长率。

   把 :k05:eq:`phase-aware-difference` 代入 :k05:eq:`frequency-equation-1d`，
   乘 :math:`\Delta y/v_{g,f}` 并移项，再对照 :math:`X_f` 和各个 :math:`Z_j` 的系数：

   为看清每一步，暂记 :math:`\widetilde Y_f=e^{-i\delta_f}Y_f`。
   沿探针方向写方程，并把相同波对乘积合并后，代入与移项的过程是

   .. k05:equation:: coefficient-substitution-steps
      :lang: zh

      \begin{aligned}
      v_{g,f}\left[\frac{\widetilde Y_f-X_f}{\Delta y}
      +i\frac{\delta_f}{\Delta y}X_f\right]
      &\simeq(\gamma_f^{(y)}+ik_{y,f}v_{g,f})X_f+\sum_j\mathcal V_{fj}Z_j,\\
      \widetilde Y_f-X_f+i\delta_fX_f
      &\simeq\left(\frac{\gamma_f^{(y)}\Delta y}{v_{g,f}}+ik_{y,f}\Delta y\right)X_f
      +\sum_j\frac{\mathcal V_{fj}\Delta y}{v_{g,f}}Z_j,\\
      \widetilde Y_f
      &\simeq\left[1+\frac{\gamma_f^{(y)}\Delta y}{v_{g,f}}
      +i(k_{y,f}\Delta y-\delta_f)\right]X_f
      +\sum_j\frac{\mathcal V_{fj}\Delta y}{v_{g,f}}Z_j.
      \end{aligned}

   第二行是两边乘 :math:`\Delta y/v_{g,f}`；第三行把左边的
   :math:`-X_f+i\delta_fX_f` 移到右边。
   旋转后的拟合模型，其模型部分写成
   :math:`\widetilde Y_f=\widetilde L_fX_f+\sum_j\widetilde Q_{fj}Z_j`。
   因此，方括号就是 :math:`\widetilde L_f`，各个 :math:`Z_j` 前的乘数就是
   :math:`\widetilde Q_{fj}`，得到

   .. k05:equation:: discrete-continuous-coefficients
      :lang: zh

      \begin{aligned}
      \widetilde L_f&\simeq1+\frac{\gamma_f^{(y)}\Delta y}{v_{g,f}}
      +i(k_{y,f}\Delta y-\delta_f),\\
      \widetilde Q_{fj}&\simeq\frac{\mathcal V_{fj}\Delta y}{v_{g,f}}.
      \end{aligned}

   将这些表达式乘回 :math:`e^{i\delta_f}`，就得到文献 [1] 公式 (4) 的原始系数结构。

   .. raw:: html

      </details>

   用 :math:`\gamma_f^{(y)}` 表示沿探针方向的有效幅值增长率，单位 :math:`\mathrm{s^{-1}}`；
   用 :math:`\mathcal V_{fj}` 表示同一个合并波对在连续方程中的耦合系数，单位
   :math:`\mathrm{V^{-1}s^{-1}}`。最后的换算为：

   .. _k05-source-4-zh:

   .. container:: k05-paper-match

      .. rubric:: K05 与文献 [1] 式 (4) 对照

      .. k05:equation:: inferred-growth-coupling
         :lang: zh

         \gamma_f^{(y)}\simeq\frac{v_{g,f}}{\Delta y}
         \left[\operatorname{Re}(\widetilde L_f)-1\right],\qquad
         \mathcal V_{fj}\simeq\frac{v_{g,f}}{\Delta y}\widetilde Q_{fj}.

      **文献原式与原符号 — [1], (4)**

      .. k05:equation:: paper-equation-4
         :lang: zh

         \begin{aligned}
         L_f&=\left[\left(\frac{\gamma_{f(y)}}{v_{g(y)}}+ik_y\right)\Delta y
         +1-i\Delta\Theta_f\right]e^{i\Delta\Theta_f},\\
         Q_f^{1,2}&=e^{i\Delta\Theta_f}V^Q_{1,2}\Delta y/v_{g(y)}.
         \end{aligned}

      **符号对照。** :math:`\Delta\Theta_f` 对应 :math:`\delta_f`，
      是以弧度计的互谱相位；:math:`v_{g(y)}` 对应 :math:`v_{g,f}`。
      :math:`\gamma_{f(y)}` 对应 :math:`\gamma_f^{(y)}`，表示有效周向幅值增长率。
      文献的 :math:`V^Q_{1,2}` 合并相同乘积后成为 :math:`\mathcal V_{fj}`。
      :math:`\Delta y` 是探针间距。

      **为什么多了波浪号？** 原式的 :math:`L_f,Q_f^{1,2}` 含有
      :math:`e^{i\Delta\Theta_f}`。K05 先写
      :math:`\widetilde L=e^{-i\delta}L`、:math:`\widetilde Q=e^{-i\delta}Q`，
      再取实部。文献式 (5) 后的文字写成 :math:`\operatorname{Re}L_f-1`，
      没有再次显示移相。这里保留两种符号的区别，不据此猜测作者未公开的实现。
      Least squares 和 Kim 都在这个模型中估计系数，统计矩本身都不能独立给出 :math:`v_g`。


   :math:`v_g/\Delta y` 提供了缺少的“每秒”单位。局部模型中，:math:`\gamma_f^{(y)}>0` 表示幅值增长，
   小于零表示阻尼。群速度是额外信息，不能仅由这些矩直接确定；文献 [1] 通过理论色散关系估计它。

   .. rubric:: 5. 耦合系数乘上双谱，才得到转移贡献

   回到连续均方收支 :k05:eq:`spectral-power-balance`。
   第 :math:`j` 个波对的自双谱为 :math:`b_j^*=\langle Z_jX_f^*\rangle_R`，其贡献是：

   .. _k05-source-6-zh:

   .. container:: k05-paper-match

      .. rubric:: K05 与文献 [1] 式 (6) 对照

      .. k05:equation:: inferred-pair-transfer
         :lang: zh

         \begin{aligned}
         \mathcal T_{fj}&=2\operatorname{Re}(\mathcal V_{fj}b_j^*)
         \simeq\frac{2v_{g,f}}{\Delta y}\operatorname{Re}(\widetilde Q_{fj}b_j^*),\\
         v_{g,f}\partial_yP_f&=2\gamma_f^{(y)}P_f+\sum_j\mathcal T_{fj}.
         \end{aligned}

      **文献原式与原符号 — [1], (6)**

      .. k05:equation:: paper-equation-6
         :lang: zh

         T_f=(v_{g(y)}/\Delta y)\operatorname{Re}\!\left[
         \sum_{f=f_1+f_2}e^{-i\Delta\Theta_f}Q_f^{1,2}X_{f_1}X_{f_2}X_f^*\right].

      **符号对照。** 文献的 :math:`T_f` 对所有进入目标频率 :math:`f`
      的保留波对求和；本页 :math:`\mathcal T_{fj}` 是单个波对对 **完整模平方变化率** 的贡献。
      若幅值归一化和波对计数一致，有 :math:`T_f^{[1]}=\tfrac12\sum_j\mathcal T_{fj}`。
      实际数据计算对 :math:`X_{f_1}X_{f_2}X_f^*` 作分段平均，原式未显示平均括号。

      因子 2 来自 :math:`d|C|^2/dt=2\operatorname{Re}(C^*\dot C)`，
      不是符号改变，也不是对作者代码的判断。第 09 页将原式约定下的计算标为
      :math:`T^{(1/2)}_{V,f}`，报告 V²/s；下标 V 强调观测量仍是电压，
      不能自动视作标定后的等离子体能量密度变化率。
      明亮的 :math:`|Q|` 图没有三阶乘积的相位，不能替代这里的有符号求和。


   :math:`\mathcal T_{fj}` 的单位为 :math:`\mathrm{V^2/s}`。
   正值表示向目标频率 :math:`f` 增加均方波动，负值表示从该目标移除均方波动。
   符号取决于复系数与双谱的相对相位，不能只看它们的模。
   这是对目标模式的贡献，本式本身并未把能量损失分别分配给两个输入模式。

   因子 2 来自幅值平方的求导。因此，空间近似平稳时，线性驱动与非线性移除可以相互平衡，
   即使它们各自的速率都不为零。若要解释为物理波能收支，还需上一页面所说的等离子体响应权重。

   .. raw:: html

      <details class="k05-note"><summary>探针间距有限时，离散功率收支为什么还多出一项？</summary>

   对残差为零的精确拟合模型，展开 :math:`|Y|^2=|LX+\sum_j Q_jZ_j|^2` 再平均。
   线性平方给出 :math:`|L|^2P_X`，两个交叉项给出
   :math:`2\operatorname{Re}(L^*\mathbf b^\dagger\mathbf q)`，
   二次部分自身的平方给出 :math:`\mathbf q^\dagger\mathbf F\mathbf q`，因此：

   .. k05:equation:: finite-probe-power-budget
      :lang: zh

      \begin{aligned}
      P_Y-P_X&=(|L|^2-1)P_X
      +2\operatorname{Re}(L^*\mathbf b^\dagger\mathbf q)
      +\mathbf q^\dagger\mathbf F\mathbf q,\\
      g_P^{\Delta}&=\frac{v_g}{\Delta y}(|L|^2-1),\\
      \mathcal T^{\Delta}&=\frac{v_g}{\Delta y}
      \left[2\operatorname{Re}(L^*\mathbf b^\dagger\mathbf q)
      +\mathbf q^\dagger\mathbf F\mathbf q\right].
      \end{aligned}

   :math:`g_P^{\Delta}` 是有限间距的 **功率** 增长系数，不是幅值增长率 :math:`\gamma`；
   :math:`\mathcal T^{\Delta}` 是相应的有限间距非线性贡献。上标 :math:`\Delta` 表示有限步长。
   第一式乘 :math:`v_g/\Delta y`，得到每单位传播时间的总均方变化。
   这些就是 Kim 有限步长功率收支中的代数项（文献 [2] 第 II 节，3999–4000 页）。

   步长足够小且相位处理一致时，:math:`g_P^{\Delta}\to2\gamma`，
   :math:`\mathcal T^{\Delta}\to\sum_j\mathcal T_{fj}`。
   因为 :math:`Q=O(\Delta y)`，:math:`Q^2` 项成为高阶小量；但有限间距时，它不一定能忽略。
   普通最小二乘中，正交性使残差的交叉项消失，但测得的输出功率还含
   :math:`\langle|\varepsilon|^2\rangle_R`。
   Kim 的模型功率体系有其自己的非理想功率假设，不能把这两种处理直接混在一起。

   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>与文献 [1] 公式 (6) 的转移归一化怎样对应？</summary>

   将文献中的测量乘积显式写成集合平均，其展示式为：

   .. k05:equation:: reference-transfer-convention
      :lang: zh

      T_f^{\mathrm{[1]}}=\frac{v_{g,f}}{\Delta y}
      \operatorname{Re}\!\left[\sum_{f_1+f_2=f}
      e^{-i\delta_f}Q_f^{1,2}\langle X_{f_1}X_{f_2}X_f^*\rangle_R\right].

   若系数归一化和波对计数完全相同，它是 :k05:eq:`inferred-pair-transfer` 中连续非线性贡献的一半。
   后者直接来自 :math:`\partial_y|C|^2=2\operatorname{Re}(C^*\partial_yC)`。
   因此，这里用不同符号区分文献展示式与明确推导的连续贡献。
   对照文献的转移曲线时，需要一致的幅值归一化、波对约定和转移定义，不能静默丢掉因子 2。
   这也把它们与上面的有限步长 :math:`\mathcal T^{\Delta}` 区分开来。

   .. raw:: html

      </details>

   现在计算链条已经接起来：记录给出统计量，统计量约束系数，相位、间距和群速度再把系数换成速率。

   **哪里已经闭合，还缺哪些物理输入？** 选定波对、Fourier 约定和估计方法的假设后，
   只要矩阵能可靠地区分系数，统计矩就足以封闭这套代数求解；Kim 的共同功率也是待求结果，
   不需要从外部另给一个数。但这只说明统计模型闭合，物理速率的输入还需要补齐。

   - **要得到每秒的增长／转移率：** 还需要带符号的探针间距和顺序、
     校正通道延迟／频率响应后可信的传播相位，以及沿探针方向的群速度（group velocity）。
     由相位延迟推得的相速度不自动等于群速度。若从理论色散关系求群速度，
     还要选定色散分支，并提供该模型所需的电子温度、密度、磁场、电场／漂移和离子种类等参数。
     这些属于物理模型输入，不是拟合又能额外求出的统计矩。
   - **要把结果解释成物理波能量：** 还需要记录电压到目标扰动物理量的换算、探针响应和等离子体能量权重。
     单位 V²/s 本身只是电压模平方的变化率。
     若要将双探针的有效增长率等同于完整三维增长率，还要评估横向输运的贡献。

   :ref:`探针响应页面 <k05-response-zh>` 和 :ref:`物理解释补充页 <k05-budget-zh>`
   继续讨论这些输入及适用性检查。



   .. rubric:: 继续阅读

   下一页面从真实同步波形出发，逐步构造本页使用的统计量。

   :ref:`下一页面 <k05-experiment-zh>`.

   .. rubric:: 参考文献

   .. _k05-inference-reference-1-zh:

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters*  **130** ,
   115101 (2023). `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   .. _k05-inference-reference-2-zh:

   [2] J. S. Kim, R. D. Durst, R. J. Fonck, E. Fernandez, A. Ware and P. W. Terry,
   “Technique for the experimental estimation of nonlinear energy transfer in
   fully developed turbulence,” *Physics of Plasmas*  **3** , 3998–4009 (1996).
   `doi:10.1063/1.871572 <https://doi.org/10.1063/1.871572>`_.

   文献 [1] 纸面 115101-3 给出双探针模型及含相位的传递系数；文献 [2] 第 II–III 节给出有限步长功率收支与修正的平稳矩方法。本页展开的矩阵例子、计算流程和相位求导中间步骤属于补充讲解。

