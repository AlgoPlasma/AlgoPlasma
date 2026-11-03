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

   .. raw:: html

      <details class="k05-note"><summary>Strong phase locking can make the coefficients inseparable</summary>

   For one pair, combine :k05:eq:`single-pair-estimator` with the squared
   bicoherence in :k05:eq:`bicoherence` (assuming :math:`P,F>0`):

   .. k05:equation:: inference-rank-bicoherence
      :lang: en

      \Delta=PF\left(1-b_X^2\right),\qquad
      b_X^2=\frac{|\langle ZX^*\rangle_R|^2}{PF}.

   If :math:`Z^{(r)}=cX^{(r)}` for every record, with the same complex constant
   :math:`c`, the model only observes :math:`(L+cQ)X`. Infinitely many choices of
   :math:`L,Q` give the same answer. Then :math:`b_X^2=1` and :math:`\Delta=0`.
   Values near this limit make estimates sensitive to small errors. A strong
   bispectral relationship can therefore coexist with poor coefficient identifiability.
   With several pairs, inspect the full predictor matrix, not only each pair separately.

   .. raw:: html

      </details>

   Measured probe data add a complication: noise can enter the first probe as
   well as the second. More averages do not remove that bias automatically.
   Brown and Jorns |ref-en| use a modification of the Ritz method developed by
   Kim and colleagues |kim-en|, together with approximate equality of power at
   the two locations. This is an extra physical/statistical assumption, beyond
   the joint least-squares algebra above.

   .. raw:: html

      <details class="k05-note" id="k05-kim-correction-en"><summary>What does the Kim stationarity correction add?</summary>

   The correction estimates **how much of the measured power belongs to the
   linear-quadratic model**, along with its coefficients. To see why that power
   is an extra unknown, start with the measured Fourier coefficient at each probe.
   The target frequency is still fixed, so its subscript is suppressed.

   **Separate the measured field from the part described by the model.** Write

   .. k05:equation:: kim-field-split
      :lang: en

      X=X_{\mathrm m}+X_{\mathrm n},\qquad Y=Y_{\mathrm m}+Y_{\mathrm n}.

   The subscript :math:`\mathrm m` means modelled: :math:`X_{\mathrm m}` and
   :math:`Y_{\mathrm m}` are the parts governed by the chosen linear-quadratic
   equation. The subscript :math:`\mathrm n` means nonideal: noise or fluctuations
   that this equation does not describe. All four quantities have units V.
   This is a statistical decomposition; the method does not first identify and
   subtract a known noise waveform. Real plasma fluctuations omitted by the model
   can also belong to the nonideal part.

   If the nonideal components have zero mean and are uncorrelated with the
   modelled component at each probe, their cross terms vanish in the power average. Thus

   .. k05:equation:: kim-power-split
      :lang: en

      \begin{aligned}
      P_X&=P_{\mathrm m,X}+P_{\mathrm n,X},\\
      P_Y&=P_{\mathrm m,Y}+P_{\mathrm n,Y}.
      \end{aligned}

   Here :math:`P_{\mathrm m,X}=\langle|X_{\mathrm m}|^2\rangle_R` and
   :math:`P_{\mathrm n,X}=\langle|X_{\mathrm n}|^2\rangle_R`; define the two
   :math:`Y` powers in the same way. All are in :math:`\mathrm{V^2}`.
   The measured :math:`P_X` can therefore be larger than the power participating
   in the model. Increasing the number of records does not remove the positive
   mean-square noise contribution.

   For a simple illustration, suppose the modelled wave has power
   :math:`1\,\mathrm{V^2}` and only changes phase, with true coefficient
   :math:`L=e^{i\delta}`. Add independent, zero-mean noise of power
   :math:`0.25\,\mathrm{V^2}` to the first probe. With no cross-correlated noise,
   :math:`P_X=1.25\,\mathrm{V^2}` but :math:`G=e^{i\delta}\,\mathrm{V^2}`.
   The linear-only ratio becomes :math:`G/P_X=0.8e^{i\delta}`. It appears to lose
   amplitude even though the modelled wave does not. This example isolates the
   noise effect; it has no quadratic coupling.

   **Why do cross moments help?** Expand the cross power:

   .. k05:equation:: kim-cross-power-split
      :lang: en

      \begin{aligned}
      G=\langle YX^*\rangle_R
      &=\langle Y_{\mathrm m}X_{\mathrm m}^*\rangle_R
      +\langle Y_{\mathrm m}X_{\mathrm n}^*\rangle_R\\
      &\quad+\langle Y_{\mathrm n}X_{\mathrm m}^*\rangle_R
      +\langle Y_{\mathrm n}X_{\mathrm n}^*\rangle_R.
      \end{aligned}

   If the last three averages vanish, :math:`G` keeps the modelled correlation
   without the added noise auto power. This explains the motivation for using
   cross moments. Applying the same reasoning to higher-order products needs
   stronger assumptions: ordinary pairwise uncorrelatedness alone does not remove
   every noise contribution to a third- or fourth-order moment.

   Ref. [2], Sec. III B, drops the specified nonideal terms except their auto
   powers, and uses the measured :math:`G,b,d,F` as inputs to the resulting moment
   system. In particular, :math:`F` is still the full measured fourth-order moment;
   it has not been made noise-free by definition. These are assumptions to assess
   for the data, not general identities for arbitrary contamination. The following
   equations use that model.

   **Start with one pair, before introducing matrices.** Under those moment
   assumptions, multiplying by :math:`X^*`, :math:`Y^*` and :math:`Z^*`, respectively,
   gives

   .. k05:equation:: kim-unclosed-scalar-moments
      :lang: en

      \begin{aligned}
      G&=LP_{\mathrm m,X}+Qb^*,\\
      P_{\mathrm m,Y}&=LG^*+Qd^*,\\
      d&=Lb+QF.
      \end{aligned}

   The first row is the earlier cross-power equation, but the power multiplying
   :math:`L` is now the unknown :math:`P_{\mathrm m,X}`. The second row is new:
   multiplication by the second-probe conjugate introduces its modelled power
   :math:`P_{\mathrm m,Y}`. Its right side uses
   :math:`\langle XY^*\rangle_R=G^*` and :math:`\langle ZY^*\rangle_R=d^*`.
   The third row is the cross-bispectrum equation already encountered.

   **Stationarity supplies the missing relation between those two powers.**
   Assume :math:`P_{\mathrm m,X}=P_{\mathrm m,Y}=P_\star`. The star is part of
   the name of this real power, not a complex-conjugate operation.
   In Kim's original time-evolution setting, this is a stationary model spectrum.
   For the two spatially separated probes it becomes approximate local homogeneity:
   the modelled mean-square fluctuation is the same at both locations.

   This does not require :math:`X=Y` record by record. Phases can change, and
   linear drive can balance nonlinear removal while the total modelled power
   stays constant. The measured powers can still contain different nonideal
   contributions. The constraint does not simply replace both measured powers by
   their arithmetic mean: :math:`P_\star,L,Q` must satisfy the moment equations
   together.

   .. raw:: html

      <details class="k05-note"><summary>Follow the elimination to P★, L and Q, then write the matrix form</summary>

   For one pair with :math:`F>0`, the last row of
   :k05:eq:`kim-unclosed-scalar-moments` gives :math:`Q=(d-Lb)/F`.
   Substitute it into the first two rows after setting both modelled powers to
   :math:`P_\star`:

   .. k05:equation:: kim-scalar-elimination
      :lang: en

      \begin{aligned}
      Q&=\frac{d-Lb}{F},\\
      G&=L\left(P_\star-\frac{|b|^2}{F}\right)+\frac{b^*d}{F},\\
      P_\star&=L\left(G^*-\frac{d^*b}{F}\right)+\frac{|d|^2}{F}.
      \end{aligned}

   For example, the first substitution uses
   :math:`Qb^*=(b^*d-L|b|^2)/F`. The second uses
   :math:`Qd^*=(|d|^2-Lbd^*)/F`. Thus each line is just multiplication and
   collection of the terms containing :math:`L`.

   Abbreviate :math:`\alpha=|b|^2/F`, :math:`\beta=|d|^2/F`, and
   :math:`\eta=G-b^*d/F`. Then the two lines become
   :math:`L(P_\star-\alpha)=\eta` and :math:`P_\star-\beta=L\eta^*`.
   The conjugate in the second expression follows from
   :math:`\eta^*=G^*-d^*b/F`, since :math:`F` is real.

   For several pairs, the same operation uses the vectors and matrix in
   :k05:eq:`inference-matrix`. Their entries are still
   :math:`b_i=\langle XZ_i^*\rangle_R`, :math:`d_i=\langle YZ_i^*\rangle_R`,
   and :math:`F_{ij}=\langle Z_i^*Z_j\rangle_R`.
   The three equations are Kim's Eqs. (11)–(14) in our notation:

   .. k05:equation:: kim-stationary-moments
      :lang: en

      \begin{aligned}
      G&=LP_\star+\mathbf b^\dagger\mathbf q,\\
      P_\star&=LG^*+\mathbf d^\dagger\mathbf q,\\
      \mathbf d&=L\mathbf b+\mathbf F\mathbf q.
      \end{aligned}

   Here :math:`\mathbf b^\dagger\mathbf q=\sum_j b_j^*Q_j` and
   :math:`\mathbf d^\dagger\mathbf q=\sum_j d_j^*Q_j`; the dagger is conjugate
   transpose. For invertible :math:`\mathbf F`, the last row gives
   :math:`\mathbf q=\mathbf F^{-1}(\mathbf d-L\mathbf b)`.
   Substitution produces precisely the scalar pattern above:

   .. k05:equation:: kim-elimination-quantities
      :lang: en

      \begin{aligned}
      \alpha&=\mathbf b^\dagger\mathbf F^{-1}\mathbf b,\qquad
      \beta=\mathbf d^\dagger\mathbf F^{-1}\mathbf d,\\
      \eta&=G-\mathbf b^\dagger\mathbf F^{-1}\mathbf d,\\
      L(P_\star-\alpha)&=\eta,\qquad P_\star-\beta=L\eta^*.
      \end{aligned}

   :math:`\alpha,\beta` are real, nonnegative powers, and :math:`\eta` is a
   complex cross moment; all have units :math:`\mathrm{V^2}`. They summarize
   the terms generated by eliminating the pair coefficients. They are neither
   additional measured fields nor extra fitting parameters.

   To remove :math:`L`, multiply :math:`P_\star-\beta=L\eta^*` by
   :math:`P_\star-\alpha`, then use :math:`L(P_\star-\alpha)=\eta`:

   .. k05:equation:: kim-power-quadratic
      :lang: en

      \begin{aligned}
      (P_\star-\alpha)(P_\star-\beta)
      &=(P_\star-\alpha)L\eta^*=\eta\eta^*=|\eta|^2,\\
      P_\star^2-(\alpha+\beta)P_\star+\alpha\beta-|\eta|^2&=0.
      \end{aligned}

   The second line is an ordinary quadratic in the real unknown :math:`P_\star`.
   Its discriminant simplifies to :math:`(\alpha-\beta)^2+4|\eta|^2`.
   Choosing the branch compatible with :math:`P_\star\ge\max(\alpha,\beta)`
   gives the power; then back-substitution gives the coefficients:

   .. k05:equation:: kim-stationary-solution
      :lang: en

      \begin{aligned}
      (P_\star-\alpha)(P_\star-\beta)&=|\eta|^2,\\
      P_\star&=\frac{\alpha+\beta+\sqrt{(\alpha-\beta)^2+4|\eta|^2}}{2},\\
      L&=\frac{\eta}{P_\star-\alpha},\qquad
      \mathbf q=\mathbf F^{-1}(\mathbf d-L\mathbf b).
      \end{aligned}

   The denominator :math:`P_\star-\alpha` must be nonzero. If it vanishes, the
   displayed division does not determine :math:`L`. Singular or nearly singular
   :math:`\mathbf F` also prevents a reliable separation of pair contributions.
   Numerical implementations should solve linear systems, rather than explicitly
   form an inverse.

   .. raw:: html

      </details>

   As a simple check, in the limit :math:`b=d=0` there is no pair correlation
   in these equations. Then :math:`\alpha=\beta=0` and :math:`P_\star=|G|`.
   For the phase-only noise example above this returns
   :math:`P_\star=1\,\mathrm{V^2}` and :math:`L=e^{i\delta}`: the excess
   measured auto power is not interpreted as damping. This limiting example
   illustrates the role of the stationarity assumption; it is not a general
   noise-removal guarantee.

   Finally, compare the inferred power with the measurements. The assumed
   additive power split requires :math:`0\le P_\star\le\min(P_X,P_Y)` within
   uncertainty. If that fails, inspect the assumptions and statistics rather than
   clipping the result. If :math:`P_\star` is only a small fraction of the measured
   power, the model explains little of the measured fluctuation. Ref. [2] uses
   this comparison to judge whether the inferred coefficients are meaningful.

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

   Insert :k05:eq:`phase-aware-difference` into
   :k05:eq:`frequency-equation-1d`. After multiplying by :math:`\Delta y/v_{g,f}`
   and rearranging, compare the coefficients of :math:`X_f` and each :math:`Z_j`:

   .. k05:equation:: discrete-continuous-coefficients
      :lang: en

      \begin{aligned}
      \widetilde L_f&\simeq1+\frac{\gamma_f^{(y)}\Delta y}{v_{g,f}}
      +i(k_{y,f}\Delta y-\delta_f),\\
      \widetilde Q_{fj}&\simeq\frac{\mathcal V_{fj}\Delta y}{v_{g,f}}.
      \end{aligned}

   :math:`k_{y,f}` is the real wavenumber along the probes, in rad/m;
   :math:`\mathcal V_{fj}` is the continuous quadratic coefficient after grouping
   identical pair products, in :math:`\mathrm{V^{-1}s^{-1}}`.
   :math:`\gamma_f^{(y)}` is the effective amplitude growth inferred along the
   probe direction. In the one-dimensional model it is :math:`\gamma_f`.
   For three-dimensional propagation, transverse variation can also affect it;
   two probes alone do not recover the full three-dimensional growth.

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

   .. raw:: html

      <details class="k05-note"><summary>A pure phase shift is a useful zero-growth check</summary>

   If :math:`Y=e^{i\delta}X` with no amplitude change and no quadratic contribution,
   the fit gives :math:`L=e^{i\delta}` and :math:`\widetilde L=1`. The converted
   growth is zero. Applying :math:`\operatorname{Re}L-1` to the raw coefficient
   would instead give :math:`\cos\delta-1`, a spurious damping term.

   Ref. [1], Eq. (4), includes :math:`e^{i\Delta\Theta_f}` in its transfer
   coefficients; its growth-rate sentence after Eq. (5) prints
   :math:`\operatorname{Re}L_f-1` without displaying that rotation. With the
   coefficients as defined in Eq. (4), taking the real part after dephasing gives
   :k05:eq:`inferred-growth-coupling`. Keeping raw and rotated symbols separate
   makes the convention explicit.

   .. raw:: html

      </details>

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

   Ref. [1], p. 115101-3, supplies the two-probe model and phase-dependent transfer functions. Ref. [2], Secs. II–III, supplies the finite-step power budget and modified stationary moment method. The scalar elimination, column-vector notation, explicit phase audit and expanded stationarity derivation here are explanatory derivations.

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

   .. raw:: html

      <details class="k05-note"><summary>相位关系很强，为什么反而可能分不开系数？</summary>

   对一个波对，将 :k05:eq:`single-pair-estimator` 与 :k05:eq:`bicoherence` 的平方双相干结合，
   在 :math:`P,F>0` 时有：

   .. k05:equation:: inference-rank-bicoherence
      :lang: zh

      \Delta=PF\left(1-b_X^2\right),\qquad
      b_X^2=\frac{|\langle ZX^*\rangle_R|^2}{PF}.

   若每段都满足 :math:`Z^{(r)}=cX^{(r)}`，且复常数 :math:`c` 不变，模型看到的就只有
   :math:`(L+cQ)X`。许多组不同的 :math:`L,Q` 都产生相同结果，无法分别识别。
   此时 :math:`b_X^2=1`、:math:`\Delta=0`。接近这种情况时，很小的误差也可能明显改变系数。
   所以很强的双谱关系，可以与很差的系数可辨识性（identifiability）同时存在。
   多个波对时，需要检查完整预测量矩阵，不能只逐对看双相干。

   .. raw:: html

      </details>

   实际探针数据还有一个问题：噪声不只进入第二支探针，也可能进入第一支。
   增加平均次数并不会自动消除这种偏差。Brown 与 Jorns |ref-zh| 采用 Kim 等人 |kim-zh|
   对 Ritz 方法的修正，并使用两位置功率近似相等的条件。这比上面的联合最小二乘代数，
   多了一层物理与统计假设。

   .. raw:: html

      <details class="k05-note" id="k05-kim-correction-zh"><summary>Kim 的平稳性修正，究竟额外做了什么？</summary>

   这项修正会同时估计两类未知量：系数，以及 **测得的功率中，有多少属于线性—二次模型能描述的部分**。
   为什么功率也成了未知量？先从每支探针测到的傅里叶系数说起。目标频率仍然固定，下面省略其下标。

   **先区分测得的量与模型描述的部分。** 写成：

   .. k05:equation:: kim-field-split
      :lang: zh

      X=X_{\mathrm m}+X_{\mathrm n},\qquad Y=Y_{\mathrm m}+Y_{\mathrm n}.

   下标 :math:`\mathrm m` 表示模型部分（modelled）：:math:`X_{\mathrm m},Y_{\mathrm m}`
   服从选定的线性—二次方程。下标 :math:`\mathrm n` 表示非理想部分（nonideal）：噪声，
   或该方程没有描述的波动。四个量的单位都是 V。
   这是统计上的分解；并不是已经知道噪声波形、先把它逐点减掉。
   模型遗漏的真实等离子体波动，也可能被归入非理想部分。

   若非理想部分均值为零，且在每个探针处都与模型部分不相关，功率平均中的交叉项消失，得到：

   .. k05:equation:: kim-power-split
      :lang: zh

      \begin{aligned}
      P_X&=P_{\mathrm m,X}+P_{\mathrm n,X},\\
      P_Y&=P_{\mathrm m,Y}+P_{\mathrm n,Y}.
      \end{aligned}

   这里 :math:`P_{\mathrm m,X}=\langle|X_{\mathrm m}|^2\rangle_R`、
   :math:`P_{\mathrm n,X}=\langle|X_{\mathrm n}|^2\rangle_R`；第二支探针的两个功率同样定义，
   单位都是 :math:`\mathrm{V^2}`。所以测得的 :math:`P_X`，可能大于真正参与模型关系的功率。
   多平均几次，并不会让噪声自身正的均方值消失。

   例如，模型波的功率为 :math:`1\,\mathrm{V^2}`，传播时只变相位，真实系数为 :math:`L=e^{i\delta}`。
   给第一支探针加入独立、零均值、功率为 :math:`0.25\,\mathrm{V^2}` 的噪声。
   若没有跨探针相关噪声，就有 :math:`P_X=1.25\,\mathrm{V^2}`，而 :math:`G=e^{i\delta}\,\mathrm{V^2}`。
   直接取比值会得到 :math:`G/P_X=0.8e^{i\delta}`，看起来幅值衰减了，实际模型波并没有衰减。
   这个小例子只用来说明噪声的影响，没有加入二次耦合。

   **互矩为什么能提供不同的信息？** 把互谱展开：

   .. k05:equation:: kim-cross-power-split
      :lang: zh

      \begin{aligned}
      G=\langle YX^*\rangle_R
      &=\langle Y_{\mathrm m}X_{\mathrm m}^*\rangle_R
      +\langle Y_{\mathrm m}X_{\mathrm n}^*\rangle_R\\
      &\quad+\langle Y_{\mathrm n}X_{\mathrm m}^*\rangle_R
      +\langle Y_{\mathrm n}X_{\mathrm n}^*\rangle_R.
      \end{aligned}

   若后三个平均量都为零，:math:`G` 就保留模型部分的相关性，而没有叠加噪声自功率。
   这解释了利用互矩的动机。但对更高阶乘积，还需要更强的假设：
   普通的“两两不相关”，并不保证三阶、四阶矩里的所有噪声贡献都消失。

   文献 [2] 第 III B 节舍去指定的非理想项、保留其自功率，并把测得的 :math:`G,b,d,F`
   代入由此得到的矩方程。尤其 :math:`F` 仍是完整的测量四阶矩，不是通过定义就变成了无噪声的量。
   这些是需要结合数据检查的模型假设，不是任意噪声都满足的恒等式。下面在这些假设下继续。

   **先看一个波对，不急着写矩阵。** 分别乘 :math:`X^*`、:math:`Y^*`、:math:`Z^*`
   再平均，得到：

   .. k05:equation:: kim-unclosed-scalar-moments
      :lang: zh

      \begin{aligned}
      G&=LP_{\mathrm m,X}+Qb^*,\\
      P_{\mathrm m,Y}&=LG^*+Qd^*,\\
      d&=Lb+QF.
      \end{aligned}

   第一行是前面的互谱方程，但乘在 :math:`L` 上的功率现在变成未知的 :math:`P_{\mathrm m,X}`。
   第二行是新增的关系：乘第二支探针的共轭后，引入它的模型功率 :math:`P_{\mathrm m,Y}`；
   右侧用到了 :math:`\langle XY^*\rangle_R=G^*`、:math:`\langle ZY^*\rangle_R=d^*`。
   第三行仍是已经见过的互双谱方程。

   **平稳性补上两个模型功率之间的关系。** 假定
   :math:`P_{\mathrm m,X}=P_{\mathrm m,Y}=P_\star`。
   这里星形是这个实数功率的名称标记，不是复共轭运算。
   在 Kim 原来的时间演化问题里，这是模型谱的统计平稳；换到两支空间探针，
   对应局部近似均匀，即两位置的模型均方波动相同。

   这个条件不要求每段记录都满足 :math:`X=Y`。相位仍然可以变化，线性驱动也可以与非线性移除相平衡，
   使总模型功率维持不变。两处测量还可能含有不同大小的非理想功率。
   因此这里不是简单把两个测得功率取算术平均，而是要求未知的 :math:`P_\star,L,Q` 一起满足矩方程。

   .. raw:: html

      <details class="k05-note"><summary>逐步求出 P★、L、Q，再写成多个波对的矩阵形式</summary>

   先保留一个波对，并设 :math:`F>0`。从 :k05:eq:`kim-unclosed-scalar-moments` 的第三行得到
   :math:`Q=(d-Lb)/F`。把两个模型功率都换成 :math:`P_\star`，再将 :math:`Q` 代入前两行：

   .. k05:equation:: kim-scalar-elimination
      :lang: zh

      \begin{aligned}
      Q&=\frac{d-Lb}{F},\\
      G&=L\left(P_\star-\frac{|b|^2}{F}\right)+\frac{b^*d}{F},\\
      P_\star&=L\left(G^*-\frac{d^*b}{F}\right)+\frac{|d|^2}{F}.
      \end{aligned}

   第一处代入用到 :math:`Qb^*=(b^*d-L|b|^2)/F`；第二处用到
   :math:`Qd^*=(|d|^2-Lbd^*)/F`。所以这几行只是展开乘法，再把含 :math:`L` 的项收在一起。

   为了缩短表达式，记 :math:`\alpha=|b|^2/F`、:math:`\beta=|d|^2/F`、
   :math:`\eta=G-b^*d/F`。于是最后两行变为
   :math:`L(P_\star-\alpha)=\eta`、:math:`P_\star-\beta=L\eta^*`。
   第二式的共轭来自 :math:`\eta^*=G^*-d^*b/F`，其中 :math:`F` 是实数。

   多个波对做的是同样的操作，只把数换成 :k05:eq:`inference-matrix` 中的向量和矩阵。
   其分量仍是 :math:`b_i=\langle XZ_i^*\rangle_R`、:math:`d_i=\langle YZ_i^*\rangle_R`、
   :math:`F_{ij}=\langle Z_i^*Z_j\rangle_R`。三组方程就是本页记法下的 Kim 公式 (11)–(14)：

   .. k05:equation:: kim-stationary-moments
      :lang: zh

      \begin{aligned}
      G&=LP_\star+\mathbf b^\dagger\mathbf q,\\
      P_\star&=LG^*+\mathbf d^\dagger\mathbf q,\\
      \mathbf d&=L\mathbf b+\mathbf F\mathbf q.
      \end{aligned}

   其中 :math:`\mathbf b^\dagger\mathbf q=\sum_jb_j^*Q_j`、
   :math:`\mathbf d^\dagger\mathbf q=\sum_jd_j^*Q_j`，:math:`\dagger` 表示共轭转置。
   当 :math:`\mathbf F` 可逆时，第三行给出
   :math:`\mathbf q=\mathbf F^{-1}(\mathbf d-L\mathbf b)`。
   代入后，又得到和单波对完全相同的结构：

   .. k05:equation:: kim-elimination-quantities
      :lang: zh

      \begin{aligned}
      \alpha&=\mathbf b^\dagger\mathbf F^{-1}\mathbf b,\qquad
      \beta=\mathbf d^\dagger\mathbf F^{-1}\mathbf d,\\
      \eta&=G-\mathbf b^\dagger\mathbf F^{-1}\mathbf d,\\
      L(P_\star-\alpha)&=\eta,\qquad P_\star-\beta=L\eta^*.
      \end{aligned}

   :math:`\alpha,\beta` 是非负实功率，:math:`\eta` 是复互矩，三者单位均为 :math:`\mathrm{V^2}`。
   它们是消去波对系数后出现的几组项的简写，不是额外测到的场，也不是新增拟合参数。

   接着消去 :math:`L`：把 :math:`P_\star-\beta=L\eta^*` 乘 :math:`P_\star-\alpha`，
   再利用 :math:`L(P_\star-\alpha)=\eta`，就有：

   .. k05:equation:: kim-power-quadratic
      :lang: zh

      \begin{aligned}
      (P_\star-\alpha)(P_\star-\beta)
      &=(P_\star-\alpha)L\eta^*=\eta\eta^*=|\eta|^2,\\
      P_\star^2-(\alpha+\beta)P_\star+\alpha\beta-|\eta|^2&=0.
      \end{aligned}

   第二行就是以实数 :math:`P_\star` 为未知量的普通一元二次方程。
   它的判别式可整理为 :math:`(\alpha-\beta)^2+4|\eta|^2`。
   选取符合 :math:`P_\star\ge\max(\alpha,\beta)` 的分支，先得到功率，再回代求系数：

   .. k05:equation:: kim-stationary-solution
      :lang: zh

      \begin{aligned}
      (P_\star-\alpha)(P_\star-\beta)&=|\eta|^2,\\
      P_\star&=\frac{\alpha+\beta+\sqrt{(\alpha-\beta)^2+4|\eta|^2}}{2},\\
      L&=\frac{\eta}{P_\star-\alpha},\qquad
      \mathbf q=\mathbf F^{-1}(\mathbf d-L\mathbf b).
      \end{aligned}

   分母 :math:`P_\star-\alpha` 必须非零；若为零，就不能用这个除法确定 :math:`L`。
   :math:`\mathbf F` 奇异或接近奇异时，也无法可靠地分开波对贡献。
   数值计算应求解线性方程，而不是显式生成逆矩阵。

   .. raw:: html

      </details>

   做一个简单检查：在 :math:`b=d=0`、方程中没有波对相关的极限下，
   :math:`\alpha=\beta=0`，所以 :math:`P_\star=|G|`。
   开头那个只变相位的含噪声例子，便得到 :math:`P_\star=1\,\mathrm{V^2}`、:math:`L=e^{i\delta}`，
   多出来的测量自功率没有被解释为阻尼。这个极限例子说明了平稳性约束的作用，不是一般性的去噪保证。

   最后要把求出的模型功率与测量比较。根据前面的加性功率分解，结果应在不确定度内满足
   :math:`0\le P_\star\le\min(P_X,P_Y)`。若不满足，应检查假设和统计量，不能直接截断数值。
   若 :math:`P_\star` 只占测得功率的一小部分，模型解释的波动就很少。
   文献 [2] 用这种比较判断推断出的系数是否有意义。

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

   .. k05:equation:: phase-aware-difference
      :lang: zh

      \left.\frac{\partial C_f}{\partial y}\right|_y
      \simeq\frac{e^{-i\delta_f}Y_f-X_f}{\Delta y}
      +i\frac{\delta_f}{\Delta y}X_f.

   这是局部有限差分近似，要求间距内幅值、系数变化足够小，且各段可用一个有代表性的共同相位增量。
   :math:`\arg G_f` 的主值只确定到模 :math:`2\pi`；若要解释波数，还需选择一致的相位分支。
   互谱接近零或相位估计不可靠时，不能得到可靠的旋转。

   把 :k05:eq:`phase-aware-difference` 代入 :k05:eq:`frequency-equation-1d`，
   乘 :math:`\Delta y/v_{g,f}` 并移项，再对照 :math:`X_f` 和各个 :math:`Z_j` 的系数：

   .. k05:equation:: discrete-continuous-coefficients
      :lang: zh

      \begin{aligned}
      \widetilde L_f&\simeq1+\frac{\gamma_f^{(y)}\Delta y}{v_{g,f}}
      +i(k_{y,f}\Delta y-\delta_f),\\
      \widetilde Q_{fj}&\simeq\frac{\mathcal V_{fj}\Delta y}{v_{g,f}}.
      \end{aligned}

   :math:`k_{y,f}` 是沿探针方向的实波数，单位 rad/m；:math:`\mathcal V_{fj}` 是合并相同波对乘积后
   连续方程的二次系数，单位 :math:`\mathrm{V^{-1}s^{-1}}`。
   :math:`\gamma_f^{(y)}` 是沿探针方向推断的有效幅值增长率。
   在一维模型中它等于 :math:`\gamma_f`；三维传播中，横向变化也可能影响它，
   仅凭两支探针不能恢复完整三维增长率。

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

   .. raw:: html

      <details class="k05-note"><summary>用“只变相位、不变幅值”的波检查零增长</summary>

   若 :math:`Y=e^{i\delta}X`，没有幅值变化也没有二次贡献，拟合给出 :math:`L=e^{i\delta}`，
   去相位后 :math:`\widetilde L=1`，换算的增长率为零。
   若直接对原始系数用 :math:`\operatorname{Re}L-1`，就会得到 :math:`\cos\delta-1`，产生虚假的阻尼。

   文献 [1] 公式 (4) 的系数中含 :math:`e^{i\Delta\Theta_f}`；其公式 (5) 后的增长率文字式写作
   :math:`\operatorname{Re}L_f-1`，没有显式显示这一步旋转。
   若严格采用公式 (4) 定义的系数，去相位后取实部就得到 :k05:eq:`inferred-growth-coupling`。
   分别记下原始系数与旋转系数，可以明确所用约定。

   .. raw:: html

      </details>

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
      的保留波对求和；本页 :math:`\mathcal T_{fj}` 是单个波对对**完整模平方变化率**的贡献。
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

   文献 [1] 纸面 115101-3 给出双探针模型及含相位的传递系数；文献 [2] 第 II–III 节给出有限步长功率收支与修正的平稳矩方法。本页的单波对消元、列向量记法、显式相位核对和平稳修正的展开属于补充推导。

