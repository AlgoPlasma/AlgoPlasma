12 · Supplement: validating the two-probe model
===========================================================================

.. raw:: html

   <link rel="stylesheet" href="../../_static/K_Diagnostics/k05-wave-packet.css">
   <div class="ap-language-switch" role="group" aria-label="Language switch" data-ap-default-lang="en">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-en k05-lesson

   .. _k05-validation-en:

   .. rubric:: A bright bispectral pattern suggests a question

   The :ref:`spectral-statistics page <k05-experiment-en>` found repeatable relations
   between frequencies. The :ref:`coefficient walkthrough <k05-experiment-coefficients-en>`
   used a fixed example to fit L/Q. This supplement expands its prediction checks. Can those relations help predict what the other probe records?
   Here we test the :ref:`two-probe model <k05-inference-en>` using measurements
   excluded from fitting. This checks a necessary predictive property of the
   approach discussed in [1]; prediction alone does not identify a physical interaction.

   .. rubric:: 1. Keep one complete capture out of the fit

   Call the C1 Fourier coefficient :math:`X_f^{(r)}` and the simultaneous C3
   coefficient :math:`Y_f^{(r)}`. Here :math:`f` is frequency in Hz and :math:`r`
   labels a segment within a capture; both coefficients have units V. C1 supplies
   the inputs and C3 the prediction target. This direction is a modelling choice,
   not a measurement of the direction of wave propagation.

   .. figure:: /_static/K_Diagnostics/k05-validation-folds.svg
      :alt: Figure 1. Each complete capture is tested once, with the other three used for fitting.
      :width: 500px

      Figure 1. Each complete capture is tested once, with the other three used for fitting.


   For example, fit on captures 3, 4 and 5, then use C1 from capture 2 to predict
   C3 from capture 2. Repeat with each capture held out. A held-out C3 record is
   used to score the prediction, never to fit its coefficients. Whole-capture
   separation avoids mixing neighbouring segments from one record between training
   and testing [2]. These four repetitions are called **folds**.

   The main calculation uses 2048 samples per segment, segment-mean removal, a
   periodic Hann window, no overlap and the positive-exponent coefficients in
   :k05:eq:`experiment-windowed-coefficients`. Each capture supplies 4882 segments
   of 20.48 microseconds; the last 1664 samples are omitted. There are 14646 training
   segments and 4882 test segments in each fold. Target bins lie between 0.5 and
   5 MHz, with 48.828125 kHz spacing; the actual endpoints are 0.537109375 and
   4.98046875 MHz.

   .. rubric:: 2. Compare two predictions of exactly the same quantity

   .. k05:equation:: validation-two-predictions
      :lang: en

      \begin{aligned}\widehat Y_{f,0}^{(r)}&=L_{f,0}X_f^{(r)},\\ \widehat Y_{f,1}^{(r)}&=L_{f,1}X_f^{(r)}+\sum_{j=1}^{J_f}Q_{fj}Z_j^{(r)}.\end{aligned}


   A hat means predicted. Subscript 0 denotes the **linear-only model**, and 1
   the **linear–quadratic model**. Each model fits its own complex linear coefficient
   :math:`L` (dimensionless); the joint model also fits :math:`Q_{fj}` (inverse V).
   :math:`Z_j=X_{f_{1j}}X_{f_{2j}}` is one product in V² with
   :math:`f_{1j}+f_{2j}=f`; :math:`j` indexes a pair and :math:`J_f` counts the pairs.
   This is the prediction form of :k05:eq:`two-probe-quadratic-model`.

   .. raw:: html

      <details class="k05-note"><summary>Which input pairs are included?</summary>

   Use all nonzero signed inputs with :math:`|f_1|,|f_2|\leq5\ \mathrm{MHz}`,
   :math:`f_1+f_2=f`, and :math:`f_1\leq f_2`. Negative-frequency coefficients
   are reconstructed as :math:`X_{-f}=X_f^*`. Thus difference interactions are
   included, unlike the positive-only display on the spectral-statistics page. Swapping
   the two inputs produces the same column: merge it once, with no extra factor
   of two. The main fits contain 51–96 quadratic columns plus one linear column.
   The finite band is a modelling restriction, not a statement that other
   frequencies have no physical role.

   .. raw:: html

      </details>


   Fit both models by minimizing complex squared errors on the same training
   segments, with no intercept. The joint fit retains correlations between every
   pair of predictor columns; it does not drop the off-diagonal fourth-order moments.

   .. figure:: /_static/K_Diagnostics/k05-validation-spectra.svg
      :alt: Figure 2. Measured and predicted spectra, then residual spectra, for held-out capture 2.
      :width: 100%

      Figure 2. Measured and predicted spectra, then residual spectra, for held-out capture 2.


   The two predicted spectra nearly overlap the measured spectrum, so the lower
   panel magnifies the useful difference: **the unexplained residual**. The
   coefficient powers use the same one-sided PSD conversion as
   :k05:eq:`experiment-hann-psd`, giving V²/Hz. On unseen data the residual need not
   be orthogonal to the prediction, so predicted PSD plus residual PSD is not
   generally equal to measured PSD.

   Similar predicted spectra do not, by themselves, measure the size of the
   quadratic part. The two fits have different :math:`L` coefficients, and the
   linear–quadratic cross term can add or subtract power; see
   :k05:eq:`validation-power-budget`. The residual tests whether the extra terms help.

   .. _k05-validation-high-frequency-en:

   .. rubric:: Figure 2 extended: what changes at 5–20 MHz?

   Keep capture 2 as the test record and fit on captures 3, 4 and 5. Keep the
   2048-sample segments and preprocessing, but now test every native frequency
   bin between 5 and 20 MHz. The quadratic inputs also expand to
   :math:`0<|f_1|,|f_2|\leq20\ \mathrm{MHz}`. Both predictions use exactly this
   same held-out record; the target grid is not thinned or interpolated.

   .. figure:: /_static/K_Diagnostics/k05-validation-high-frequency-spectra.svg
      :alt: Figure 2 (higher-frequency extension). The same held-out capture, with dense 5–20 MHz target bins: measured and predicted spectra above, residual spectra below.
      :width: 100%

      Figure 2 (higher-frequency extension). The same held-out capture, with dense 5–20 MHz target bins: measured and predicted spectra above, residual spectra below.

   The horizontal axis is :math:`f`. Above, :math:`S_{YY}^{+}` is the measured
   C3 power spectral density, and :math:`S_{\widehat Y_m\widehat Y_m}^{+}` is the
   PSD of prediction :math:`\widehat Y_{f,m}` in :k05:eq:`validation-two-predictions`.
   Below, :math:`S_{\varepsilon_m\varepsilon_m}^{+}` is the PSD of the residual
   :math:`\varepsilon_m=Y_f-\widehat Y_{f,m}`. Here :math:`m=0` is linear and
   :math:`m=1` includes quadratic terms; the superscript :math:`+` denotes a
   one-sided spectrum. All vertical values use the conversion in
   :k05:eq:`experiment-hann-psd` and units V²/Hz.

   The extra terms reduce the total squared prediction error over 5–20 MHz by
   **7.86%**. Summing errors within each sub-band gives reductions of **10.70%**
   at 5–10 MHz, **1.04%** at 10–15 MHz, and **1.64%** at 15–20 MHz.
   The lower panel therefore shows the main improvement below 10 MHz. Around
   17–19 MHz the predicted spectra separate visibly, yet the residuals remain
   close: more predicted power need not mean a proportionally better prediction.
   These percentages describe error reduction, not a fraction of plasma energy.

   .. _k05-validation-unexplained-en:

   .. raw:: html

      <details class="k05-note"><summary>Why does the linear–quadratic prediction still fall below the measured spectrum?</summary>

   At some higher frequencies, more of the C3 fluctuation remains beyond
   what the retained C1 inputs can predict consistently. Quadratic terms recover
   part of that information, but do not guarantee a complete prediction.

   The fit predicts each segment's **complex Fourier coefficient**, including
   both amplitude and phase. A component can have substantial amplitude while
   its phase relation to the predictors varies between segments. It still adds
   to the measured PSD, but is difficult to predict with fixed coefficients and
   largely remains in the residual. Matching average spectral power alone would
   not establish that the segment-by-segment prediction is correct.

   This connects to the reduced high-frequency **coherence** on the spectral-statistics
   page. Consider the optimal linear predictor for one unchanged statistical
   population. Define :math:`P_X=\langle|X_f|^2\rangle` and
   :math:`P_Y=\langle|Y_f|^2\rangle`, both in V² and both nonzero; the brackets
   average over that same population. The least-squares coefficient is
   :math:`L_{f,0}=\langle Y_fX_f^*\rangle/P_X`, where the star denotes conjugation.
   Combining this with :k05:eq:`experiment-coherence-phase` [4] gives

   .. k05:equation:: validation-linear-predictable-power
      :lang: en

      P_{\widehat Y_0}(f)=|L_{f,0}|^2P_X(f)=C_{13}^{2}(f)\,P_Y(f).


   :math:`P_{\widehat Y_0}=\langle|\widehat Y_{f,0}|^2\rangle` is the linear
   prediction power; :math:`C_{13}^{2}` is dimensionless magnitude-squared
   coherence. Thus coherence 0.1 gives a linear prediction power equal to 10%
   of the target power in this ideal calculation. The ratio is unchanged when
   both powers receive the same PSD normalization in :k05:eq:`experiment-hann-psd`.
   This is a statistical identity for the optimal linear predictor, not an exact
   constraint on a separately held-out record or on the quadratic model.

   Quadratic terms can use additional information in
   :math:`X_{f_1}X_{f_2}`. A remaining gap can have several origins:

   - **Measurement noise:** a C3 noise component unrelated to the retained C1
     inputs cannot be predicted from them. Its relative importance can increase
     when the physical signal is weaker; no independent noise floor was measured here.
   - **Spatial decorrelation:** the two positions can contain different physical
     components, or their propagation-phase relation can vary with time. Fixed
     coefficients may then fail to describe the full record.
   - **Model inadequacy:** inputs above 20 MHz, higher-order terms, other physical
     variables or time-varying coefficients are absent from this model. Relations
     learned from the training captures may also change in the test capture.

   The figure establishes a remaining prediction error. It does not distinguish
   these possible causes, or identify the spectral gap as a physical energy-transfer rate.


   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>Settings, limits and reproduction of this extension</summary>

   The 307 target bins run from 5.029296875 to 19.970703125 MHz, separated by
   48.828125 kHz. Each fit uses 14646 training segments and 4882 held-out segments.
   The actual largest input frequency is 19.970703125 MHz. Retaining every unique
   signed pair with :math:`f_1+f_2=f` gives 204–357 quadratic columns per target.
   Negative-frequency coefficients are conjugates; DC is excluded. Pairs with
   either input above 20 MHz are omitted, including high-frequency pairs whose
   difference lies in the target band.

   All 307 fits have full rank, with a maximum scaled condition number of 14.10.
   Error decreases in 225 bins and increases in the other 82; both outcomes remain
   in the curves. This is one fixed held-out capture, not four-fold evidence at
   high frequencies. The input basis is wider than in the original Figure 2,
   so the two figures do not isolate a change in target frequency alone.

   For each quoted sub-band percentage, sum residual powers across its native
   bins before taking :math:`1-\sum_f\langle|\varepsilon_1|^2\rangle/
   \sum_f\langle|\varepsilon_0|^2\rangle`. This is not an unweighted mean of
   per-frequency percentages. No test score was used to choose a winning bandwidth.

   .. code-block:: bash

      OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 \
      python K_Diagnostics/K05_bispectral_transfer/validate_high_frequency.py \
        --data /path/to/experiment-data \
        --output /path/to/high-frequency-validation

   Download the :download:`high-frequency script <../../../../K_Diagnostics/K05_bispectral_transfer/validate_high_frequency.py>`
   and :download:`run summary <../../_static/K_Diagnostics/k05-validation-high-frequency-summary.json>`.
   The script uses the same solver, preprocessing, reader and metadata linked below. It writes one SVG/PNG figure, the run summary and a full numerical archive in the chosen output folder.

   .. raw:: html

      </details>


   .. raw:: html

      <details class="k05-note"><summary>Inspect one frequency before averaging its power</summary>

   .. figure:: /_static/K_Diagnostics/k05-validation-example.svg
      :alt: Figure 3. The measured and predicted complex Fourier coefficient near 2 MHz, segment by segment.
      :width: 100%

      Figure 3. The measured and predicted complex Fourier coefficient near 2 MHz, segment by segment.

   The example was fixed before checking performance: held-out capture 2, the
   nearest bin to 2 MHz (2.001953125 MHz), and the first 150 segments. Each point
   is one complex Fourier coefficient, split into real and imaginary parts.
   The horizontal axis is segment midpoint time, not the rapid oscillation time
   within a segment. The predictions can look nearly identical while their small
   residuals differ. At this bin, the four held-out error reductions are 5.12–5.67%.

   .. raw:: html

      </details>


   .. rubric:: 3. Does the quadratic model reduce unseen error?

   For each target frequency, normalize the squared prediction error by the
   measured C3 coefficient power in the same held-out capture:

   .. k05:equation:: validation-nmse
      :lang: en

      E_m(f)=\frac{\sum_{r\in\mathcal T}|Y_f^{(r)}-\widehat Y_{f,m}^{(r)}|^2}{\sum_{r\in\mathcal T}|Y_f^{(r)}|^2},\qquad m\in\{0,1\}.


   :math:`\mathcal T` is the set of test segments. :math:`m` selects the model,
   and :math:`|\cdot|` is complex magnitude. The dimensionless **normalized mean
   square error (NMSE)** :math:`E_m` is zero for an exact prediction; predicting
   zero gives 1. It is not a fraction of plasma energy. Compare the models through

   .. k05:equation:: validation-improvement
      :lang: en

      I(f)=1-\frac{E_1(f)}{E_0(f)}.


   :math:`I>0` means less error with quadratic terms; :math:`I<0` means more error.
   Multiply by 100 for a percentage. Zero target power makes NMSE undefined; zero
   linear error makes relative improvement undefined. Neither is replaced by an
   arbitrary small denominator.

   .. figure:: /_static/K_Diagnostics/k05-validation-errors.svg
      :alt: Figure 4. Held-out normalized errors and the relative error reduction in all four folds.
      :width: 100%

      Figure 4. Held-out normalized errors and the relative error reduction in all four folds.


   The shaded region is the range of four held-out results, not a confidence
   interval. Negative improvements are retained. In the main configuration,
   87–90 of the 92 target bins improve in each fold, but not every bin does.
   The following summary first sums squared errors and target powers over the
   whole retained band, then takes the ratios. It therefore differs from an
   unweighted mean of the frequency-by-frequency percentage curve.

   .. list-table::
      :header-rows: 1
      :widths: 25 25 25 25

      * - Held-out capture
        - Linear NMSE
        - Joint NMSE
        - Error reduction
      * - #2
        - 0.04326
        - 0.04246
        - 1.83%
      * - #3
        - 0.04354
        - 0.04260
        - 2.16%
      * - #4
        - 0.04317
        - 0.04235
        - 1.91%
      * - #5
        - 0.04328
        - 0.04253
        - 1.73%


   The band-wide error reduction is **1.73%–2.16%**. The baseline already accounts
   for most measured coefficient power, and the extra benefit is modest. This is
   a repeated predictive improvement in these four captures; it does not by itself
   establish a causal plasma coupling or a formal significance level.

   .. rubric:: 4. Inspect what the prediction still misses

   .. figure:: /_static/K_Diagnostics/k05-validation-residuals.svg
      :alt: Figure 5. Residual associations with the linear predictor and with quadratic products, evaluated on held-out records.
      :width: 100%

      Figure 5. Residual associations with the linear predictor and with quadratic products, evaluated on held-out records.


   This figure asks whether the held-out residual still has an association with
   the target-frequency input :math:`X` or with a product :math:`Z_j`. Association
   left in a residual can indicate an incomplete or imperfectly transferable model.
   The lower panel takes the maximum over the included pairs; it is a diagnostic,
   not a multiple-comparison-corrected test. Small residual correlations do not
   prove that the residual is pure instrument noise.

   .. raw:: html

      <details class="k05-note"><summary>How the residual association is calculated</summary>

   .. k05:equation:: validation-residual-correlation
      :lang: en

      \varepsilon_m=Y-\widehat Y_m,\qquad \rho^2_{\varepsilon_m,V}=\frac{|\langle\varepsilon_m V^*\rangle_{\mathcal T}|^2}{\langle|\varepsilon_m|^2\rangle_{\mathcal T}\langle|V|^2\rangle_{\mathcal T}},\quad V\in\{X,Z_1,\ldots,Z_J\}.


   Suppress the fixed frequency and segment labels here. :math:`\varepsilon_m`
   is the residual of model :math:`m`; :math:`V` is one predictor column, not a
   voltage unit in this formula. The brackets average over test segments only,
   and the star denotes conjugation. The ratio is dimensionless. In training,
   least squares makes residuals orthogonal to the retained column space by
   construction; testing that same property on held-out records is more informative.
   Zero residual or predictor power makes the ratio undefined.

   .. raw:: html

      </details>


   .. figure:: /_static/K_Diagnostics/k05-validation-coefficients.svg
      :alt: Figure 6. Linear-coefficient magnitude and wrapped phase across four training selections.
      :width: 100%

      Figure 6. Linear-coefficient magnitude and wrapped phase across four training selections.


   Each line uses a different set of three training captures. Compare their
   magnitudes and wrapped phases, rather than taking an arithmetic average across
   a phase wrap. The joint-fit :math:`L` need not equal the linear-only result:
   the latter can absorb a contribution correlated with the quadratic predictors,
   as explained in :k05:eq:`linear-only-bias`. These are voltage transfer
   coefficients; their magnitude above or below 1 is not a calibrated growth rate.

   .. rubric:: 5. Can the fit distinguish its predictor columns?

   .. figure:: /_static/K_Diagnostics/k05-validation-conditioning.svg
      :alt: Figure 7. Condition number and rank of the scaled joint predictor matrix.
      :width: 100%

      Figure 7. Condition number and rank of the scaled joint predictor matrix.


   The **condition number** measures sensitivity to nearly indistinguishable
   combinations of columns. The **rank** counts numerically independent columns.
   All 368 main-configuration fits have full rank; their largest scaled
   condition number is 10.76. This is reassuring about numerical
   separability, but it does not remove bias from noisy input measurements or
   validate a physical interpretation of each coefficient.

   .. raw:: html

      <details class="k05-note"><summary>Training-only scaling and the SVD solve</summary>

   At one frequency, row :math:`r` of :math:`\mathbf D` contains
   :math:`(X_f^{(r)},Z_1^{(r)},\ldots,Z_J^{(r)})`; :math:`\mathbf y` contains
   training targets :math:`Y_f^{(r)}`. The unknown vector
   :math:`\boldsymbol\theta=(L,Q_1,\ldots,Q_J)^T` uses the original units.
   First scale each column by its training RMS:

   .. k05:equation:: validation-scaled-solve
      :lang: en

      \begin{aligned}s_j&=\sqrt{\langle|D_{rj}|^2\rangle_{\rm train}},\quad \widetilde D_{rj}=D_{rj}/s_j,\\ \widehat{\boldsymbol\beta}&=\underset{\boldsymbol\beta}{\operatorname{argmin}}\,\|\mathbf y-\widetilde{\mathbf D}\boldsymbol\beta\|_2^2,\quad \widehat\theta_j=\widehat\beta_j/s_j.\end{aligned}


   :math:`j` now indexes all matrix columns, including the linear one.
   :math:`s_j` has the units of that column; :math:`\widetilde D` is dimensionless,
   :math:`\beta_j` has units V, and division by :math:`s_j` restores the units of
   :math:`\theta_j`. The Euclidean norm :math:`\|\cdot\|_2` sums squared complex
   magnitudes. No column mean or fitted intercept is added, and neither channel
   is gain-normalized to the other.

   NumPy's SVD least-squares solver [3] uses ``rcond=1e-10``. Singular values
   smaller than that fraction of the largest are discarded. The condition number
   is largest/smallest singular value for a full-rank scaled matrix; a rank deficit
   is recorded as infinite. A rank deficit or condition number above :math:`10^8`
   flags unreliable coefficient separation. Predictions are retained with that
   flag, rather than silently erasing difficult cases. An exactly zero training
   column gets a zero coefficient and a rank-deficit flag. Test records never
   enter these scales or the fit.

   .. raw:: html

      </details>


   .. rubric:: 6. Change the settings without choosing a winner from the test data

   .. figure:: /_static/K_Diagnostics/k05-validation-sensitivity.svg
      :alt: Figure 8. All predefined segment lengths and input limits, compared on common target frequencies.
      :width: 100%

      Figure 8. All predefined segment lengths and input limits, compared on common target frequencies.


   The left column changes segment length to 1024, 2048 and 4096 at a fixed 5 MHz
   input limit. These provide 9765, 4882 and 2441 segments per capture, respectively.
   The right column fixes 2048 samples and changes the quadratic input limit to
   3, 5 and 8 MHz. The target band stays 0.5–5 MHz. Longer segments change both
   spectral resolution and averaging; wider input bands also add predictor columns.

   Only exact common frequency bins are used in this comparison, without
   interpolation. Lines are means across the four held-out captures. All five
   predefined configurations are shown; none is selected by its test score.
   The broad pattern of a small benefit persists, while its size and local sign
   depend on the settings. Near 4 MHz, including higher-frequency input pairs
   changes the predicted contribution appreciably. A single narrow peak should
   therefore not be treated as a setting-independent physical rate.

   The lower panels show the aggregate quadratic prediction power divided by
   measured target power: :math:`B=\sum_jQ_{fj}Z_j` and :math:`P_Y=\langle|Y_f|^2\rangle`.
   Different window durations change the statistics of
   individual bins, so this comparison uses normalized contributions rather than
   equating raw :math:`Q` values from different frequency grids.

   .. raw:: html

      <details class="k05-note"><summary>What the signed quadratic contributions mean</summary>

   Define the two parts of the joint prediction at a fixed target frequency:

   .. k05:equation:: validation-power-budget
      :lang: en

      \begin{aligned}A&=L_{f,1}X_f,\quad B=\sum_jQ_{fj}Z_j,\\ \langle|\widehat Y_{f,1}|^2\rangle_{\mathcal T}&=\langle|A|^2\rangle_{\mathcal T}+2\operatorname{Re}\langle A^*B\rangle_{\mathcal T}+\langle|B|^2\rangle_{\mathcal T}.\end{aligned}


   :math:`A` is the linear part and :math:`B` the sum of all quadratic parts,
   both in V. Here :math:`B` is not the bispectrum symbol used on earlier pages.
   :math:`\operatorname{Re}` takes the real part. All three power terms have units
   V² and use held-out averages. The :math:`|B|^2` term retains cross terms between
   different pairs, so it cannot be replaced by the sum of their separate powers.

   .. figure:: /_static/K_Diagnostics/k05-validation-budget.svg
      :alt: Figure 9. The complete joint-model power decomposition and individual signed cross contributions.
      :width: 100%

      Figure 9. The complete joint-model power decomposition and individual signed cross contributions.


   The left panel divides each term by measured target power. The right panel
   separates the signed cross term into pair contributions at the fixed example frequency:

   .. k05:equation:: validation-pair-cross
      :lang: en

      c_j=\frac{2\operatorname{Re}\langle A^*Q_{fj}Z_j\rangle_{\mathcal T}}{P_Y},\qquad P_Y=\langle|Y_f|^2\rangle_{\mathcal T},\quad \sum_jc_j=\frac{2\operatorname{Re}\langle A^*B\rangle_{\mathcal T}}{P_Y}.


   :math:`c_j` is dimensionless. A positive value adds to this prediction-power
   cross term; a negative value subtracts. Columns increase with signed
   :math:`f_1`, with representative frequencies labelled on the axis;
   :math:`f_2=f-f_1` and the exact pair list is saved with the results.
   This sign is not a measured direction of energy flow between plasma modes.
   The complete prediction power still includes both square terms in
   :k05:eq:`validation-power-budget`.

   .. raw:: html

      </details>


   .. rubric:: What the validation supports

   The joint model predicts these held-out voltage records slightly better overall
   than the linear-only model. Its numerical systems are well conditioned in the
   tested configurations. The frequency dependence and contribution sizes remain
   sensitive to analysis choices. Together, these results support investigating
   the model further; they do not yet determine EDI growth, an energy-transfer
   direction or an inverse cascade. Such interpretations require the additional
   measurement-response and propagation assumptions. The
   :ref:`probe-response page <k05-response-en>` uses swept-probe data to examine the
   collection regime and electrical-response scenarios.

   .. raw:: html

      <details class="k05-note"><summary>Reproduce the validation</summary>

   .. code-block:: bash

      OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 \
      python K_Diagnostics/K05_bispectral_transfer/validate_experiment.py \
        --data /path/to/experiment-data \
        --output /path/to/model-validation

   The output contains nine SVG/PNG figures, ``validation_summary.json`` and
   ``validation_arrays.npz``. The summary records input hashes, folds, all fixed
   settings and software versions. Arrays preserve coefficients, pair lists,
   training scales, singular values, test errors and model-power terms.
   Use a separate output folder to retain the first analysis.

   Download the :download:`validation script <../../../../K_Diagnostics/K05_bispectral_transfer/validate_experiment.py>`,
   :download:`shared preprocessing <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py>`,
   :download:`binary reader <../../../../K_Diagnostics/K05_bispectral_transfer/siglent_v4.py>`,
   :download:`metadata <../../../../K_Diagnostics/K05_bispectral_transfer/experiment_z5p5_a3p7.json>`
   and :download:`run summary <../../_static/K_Diagnostics/k05-validation-summary.json>`.
   Keep the Python files and metadata in one folder when running outside the repository.
   The original binary files are external inputs; loading this page does not rerun the analysis.

   .. raw:: html

      </details>

   .. rubric:: References

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**, 115101 (2023).
   `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   [2] scikit-learn, *Cross-validation: evaluating estimator performance*.
   `Grouped data and avoiding test-set leakage <https://scikit-learn.org/stable/modules/cross_validation.html>`_.

   [3] NumPy, ``numpy.linalg.lstsq``.
   `Least-squares solution and singular-value cutoff <https://numpy.org/doc/stable/reference/generated/numpy.linalg.lstsq.html>`_.

   [4] SciPy, ``scipy.signal.coherence``.
   `Magnitude-squared coherence definition <https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.coherence.html>`_.


.. container:: ap-lang ap-lang-zh k05-lesson

   .. _k05-validation-zh:

   .. rubric:: 从双谱中的结构，提出一个可检验的问题

   :ref:`谱统计量页面 <k05-experiment-zh>` 看到了频率之间可重复的关联；
   :ref:`系数计算页面 <k05-experiment-coefficients-zh>` 用固定例子求出 L/Q。
   本补充页展开其中的预测检验。
   这些关联能否帮助预测另一支探针的记录？本页面用未参与拟合的数据，检验
   :ref:`双探针模型 <k05-inference-zh>`。这是对文献 [1] 所用模型的一项预测能力检查；
   预测有效本身还不能识别具体的物理相互作用。

   .. rubric:: 1. 每次留出一整组记录

   把 C1 的 Fourier 系数记为 :math:`X_f^{(r)}`，同步 C3 系数记为
   :math:`Y_f^{(r)}`。:math:`f` 是频率，单位 Hz；:math:`r` 是一组记录内部的分段编号；
   两个系数的单位都是 V。用 C1 作输入、C3 作预测目标，是模型的设置，
   不代表已经确定波从 C1 向 C3 传播。

   .. figure:: /_static/K_Diagnostics/k05-validation-folds.svg
      :alt: 图 1．每组完整记录轮流作为测试集，其余三组用于拟合。
      :width: 500px

      图 1．每组完整记录轮流作为测试集，其余三组用于拟合。


   例如，用第 3、4、5 组拟合，再把第 2 组的 C1 交给模型，预测同组 C3。
   然后轮换留出的组。留出组的 C3 只用于评估，不参与该轮系数拟合。
   这样不会把同一记录内相邻的分段随机分散到训练集和测试集 [2]。
   这四次验证称为四折（four folds）。

   主分析每段取 2048 点，去段均值、乘周期 Hann 窗、不重叠，并采用
   :k05:eq:`experiment-windowed-coefficients` 的正指数 Fourier 约定。
   每组有 4882 段，每段 20.48 μs，末尾 1664 点舍去；每轮使用 14646 段拟合、4882 段测试。
   目标频带为 0.5–5 MHz，频点间隔 48.828125 kHz；实际首末频点为
   0.537109375 和 4.98046875 MHz。

   .. rubric:: 2. 用两种模型预测同一个量

   .. k05:equation:: validation-two-predictions
      :lang: zh

      \begin{aligned}\widehat Y_{f,0}^{(r)}&=L_{f,0}X_f^{(r)},\\ \widehat Y_{f,1}^{(r)}&=L_{f,1}X_f^{(r)}+\sum_{j=1}^{J_f}Q_{fj}Z_j^{(r)}.\end{aligned}


   帽子表示预测值；下标 0 表示 **仅线性模型（linear-only model）**，
   下标 1 表示 **线性—二次模型（linear–quadratic model）**。
   两者各自拟合复线性系数 :math:`L`，单位为 1；联合模型还拟合单位为
   :math:`\mathrm{V^{-1}}` 的 :math:`Q_{fj}`。
   :math:`Z_j=X_{f_{1j}}X_{f_{2j}}` 是单位为 V² 的乘积，满足
   :math:`f_{1j}+f_{2j}=f`；:math:`j` 是波对编号，:math:`J_f` 是波对数。
   它是 :k05:eq:`two-probe-quadratic-model` 的预测写法。

   .. raw:: html

      <details class="k05-note"><summary>输入究竟包含哪些波对？</summary>

   纳入满足 :math:`|f_1|,|f_2|\leq5\ \mathrm{MHz}`、
   :math:`f_1+f_2=f`、:math:`f_1\leq f_2` 的所有非零带符号频点。
   用 :math:`X_{-f}=X_f^*` 恢复负频率，因此包含差频作用，
   比谱统计量页仅用于展示的正频率三角域更完整。
   交换输入次序会得到相同预测列，只合并保留一次，不额外乘二。
   主配置每个目标有 51–96 个二次列，再加一个线性列。
   有限输入带是模型截断，不代表带外频率没有物理作用。

   .. raw:: html

      </details>


   两模型在相同训练分段上最小化复数平方误差，都不设截距。
   联合拟合保留所有预测列之间的相关性，没有省略四阶矩阵的非对角项。

   .. figure:: /_static/K_Diagnostics/k05-validation-spectra.svg
      :alt: 图 2．第 2 组留出记录：先比较实测与预测谱，再比较残差谱。
      :width: 100%

      图 2．第 2 组留出记录：先比较实测与预测谱，再比较残差谱。


   两个预测谱与实测谱接近，所以更值得看下面的 **残差（residual）**：
   它是测量值减去预测值，还剩下多少没有被解释。
   系数功率采用 :k05:eq:`experiment-hann-psd` 相同的单边 PSD 换算，单位为 V²/Hz。
   在未见过的数据上，残差与预测值不保证正交，所以预测谱与残差谱相加，
   一般不严格等于实测谱。

   预测谱接近，不能单独用来读出二次部分的大小。两种拟合的 :math:`L` 不同，
   线性与二次部分的交叉项还可能增加或抵消功率，见 :k05:eq:`validation-power-budget`。
   检验额外的项有没有帮助，要继续看残差是否降低。

   .. _k05-validation-high-frequency-zh:

   .. rubric:: 图 2 的高频补充：5–20 MHz 有什么不同？

   仍用第 3、4、5 组拟合，第 2 组检验；保持 2048 点分段和相同预处理，
   改为逐个检验 5–20 MHz 内的原生频点。
   二次输入同时扩展为 :math:`0<|f_1|,|f_2|\leq20\ \mathrm{MHz}`。
   两种模型预测同一份留出记录，没有抽稀目标频点，也没有插值。

   .. figure:: /_static/K_Diagnostics/k05-validation-high-frequency-spectra.svg
      :alt: 图 2（高频补充）．同一份第 2 组留出记录，密集覆盖 5–20 MHz：上图比较实测与预测谱，下图比较残差谱。
      :width: 100%

      图 2（高频补充）．同一份第 2 组留出记录，密集覆盖 5–20 MHz：上图比较实测与预测谱，下图比较残差谱。

   横轴是频率 :math:`f`。上图的 :math:`S_{YY}^{+}` 是实测 C3 的功率谱密度
   （power spectral density, PSD），:math:`S_{\widehat Y_m\widehat Y_m}^{+}` 是
   :k05:eq:`validation-two-predictions` 中预测量 :math:`\widehat Y_{f,m}` 的 PSD。
   下图的 :math:`S_{\varepsilon_m\varepsilon_m}^{+}` 是残差
   :math:`\varepsilon_m=Y_f-\widehat Y_{f,m}` 的 PSD。
   :math:`m=0` 表示仅线性，:math:`m=1` 表示加入二次项；上标 :math:`+` 表示单边谱。
   纵轴均按 :k05:eq:`experiment-hann-psd` 换算，单位为 V²/Hz。

   加入二次项后，5–20 MHz 内的总平方预测误差降低 **7.86%**。
   分频带汇总时，5–10 MHz 降低 **10.70%**，10–15 MHz 降低 **1.04%**，
   15–20 MHz 降低 **1.64%**；下图中主要的改善出现在 10 MHz 以下。
   约 17–19 MHz 处，两种预测谱明显分开，但残差仍很接近：
   预测功率增加，不一定意味着预测误差按相同比例降低。
   这些百分比描述误差降低，不是等离子体能量中二次项所占的比例。

   .. _k05-validation-unexplained-zh:

   .. raw:: html

      <details class="k05-note"><summary>为什么高频处加入二次项后，预测谱仍低于实测谱？</summary>

   在部分高频段，C3 波动中有更大一部分无法由当前保留的 C1 输入稳定预测。
   二次项能够补回一部分，但不能保证恢复全部测量信号。

   拟合预测的是每一段的 **复 Fourier 系数（complex Fourier coefficient）**，
   需要同时预测幅值和相位。某个成分即使幅值不小，如果它与预测输入的相位关系
   在各段之间不稳定，仍会贡献实测 PSD，却难以被固定系数预测，因而主要留在残差中。
   仅让平均功率谱接近，还不能说明逐段预测正确。

   这与第 06 页看到的高频 **相干度（coherence）** 降低相呼应。
   先考虑统计关系保持不变、针对同一统计总体得到的最优线性预测。
   记 :math:`P_X=\langle|X_f|^2\rangle`、:math:`P_Y=\langle|Y_f|^2\rangle`，
   两者单位均为 V²，且都非零；尖括号对这个相同的统计总体平均。
   最小二乘系数为 :math:`L_{f,0}=\langle Y_fX_f^*\rangle/P_X`，星号表示共轭。
   代入 :k05:eq:`experiment-coherence-phase` 的定义 [4]，得到

   .. k05:equation:: validation-linear-predictable-power
      :lang: zh

      P_{\widehat Y_0}(f)=|L_{f,0}|^2P_X(f)=C_{13}^{2}(f)\,P_Y(f).


   :math:`P_{\widehat Y_0}=\langle|\widehat Y_{f,0}|^2\rangle` 是线性预测功率，
   :math:`C_{13}^{2}` 是无量纲的幅值平方相干度（magnitude-squared coherence）。
   例如，在这个理想计算中，相干度为 0.1 时，线性预测功率只有目标功率的 10%。
   按 :k05:eq:`experiment-hann-psd` 给两边乘相同的 PSD 换算因子，比例不变。
   这是最优线性预测的统计恒等式，不是要求独立留出记录或二次模型严格满足的约束。

   加入二次项，可以利用 :math:`X_{f_1}X_{f_2}` 中额外的预测信息。
   剩余差异可能来自几类原因：

   - **测量噪声（measurement noise）：** C3 中与保留的 C1 输入无关的噪声无法被预测。
     物理信号较弱时，其相对影响可能更大；这里没有独立测得噪声底。
   - **空间失相关（spatial decorrelation）：** 两处可以包含不同的真实波动成分，
     或传播相位关系随时间变化，固定系数因而无法完整描述记录。
   - **模型不完整（model inadequacy）：** 当前模型未包含 20 MHz 以上的输入、
     更高阶项、其他物理变量或随时间变化的系数；训练组学到的关系也可能在测试组改变。

   这张图确认的是仍有预测误差，尚不能区分上述原因，
   也不能把实测谱与预测谱之间的差额直接解释成物理能量转移率。


   .. raw:: html

      </details>

   .. raw:: html

      <details class="k05-note"><summary>这张补充图的设置、边界与复现方法</summary>

   共有 307 个目标频点，实际端点为 5.029296875 和 19.970703125 MHz，
   间隔 48.828125 kHz。每次拟合使用 14646 个训练段、4882 个留出段。
   输入的实际最高频率也是 19.970703125 MHz；保留满足 :math:`f_1+f_2=f`
   的全部不重复带符号波对，每个目标含 204–357 个二次列。
   负频率由共轭恢复，零频率不参与。任一输入超过 20 MHz 的波对被截去，
   即使它们的差频落入目标范围，也不在这个模型中。

   307 次拟合均满秩，最大缩放条件数为 14.10。
   225 个频点的误差降低，另外 82 个频点增加，图中均保留。
   这里固定检验第 2 组，不能当作高频段的四轮一致性验证。
   与原图 2 相比，输入频带也变宽了，因此两图的差异不能只归因于目标频率升高。

   上面的分频带百分比先把该频带原生频点的残差功率求和，再计算
   :math:`1-\sum_f\langle|\varepsilon_1|^2\rangle/
   \sum_f\langle|\varepsilon_0|^2\rangle`，不是逐频点百分比的简单平均。
   没有根据测试分数挑选效果最好的频带设置。

   .. code-block:: bash

      OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 \
      python K_Diagnostics/K05_bispectral_transfer/validate_high_frequency.py \
        --data /path/to/experiment-data \
        --output /path/to/high-frequency-validation

   下载 :download:`high-frequency script <../../../../K_Diagnostics/K05_bispectral_transfer/validate_high_frequency.py>`
   及 :download:`run summary <../../_static/K_Diagnostics/k05-validation-high-frequency-summary.json>`.
   脚本依赖本页下方提供的同一求解器、预处理、读取器和元数据；在指定输出目录保存一张 SVG／PNG 图、运行摘要及完整数值数组。

   .. raw:: html

      </details>


   .. raw:: html

      <details class="k05-note"><summary>在平均功率之前，展开一个频率看看</summary>

   .. figure:: /_static/K_Diagnostics/k05-validation-example.svg
      :alt: 图 3．约 2 MHz 的复 Fourier 系数：逐段比较实测与预测。
      :width: 100%

      图 3．约 2 MHz 的复 Fourier 系数：逐段比较实测与预测。

   示例预先固定为第 2 组留出记录、最接近 2 MHz 的频点（2.001953125 MHz），以及最前面的 150 段。
   每一点是一个复 Fourier 系数，分成实部和虚部展示；横轴是分段的中点时间，
   不是段内快速振荡的时间。两种预测看起来很接近，但较小的残差仍可能不同。
   这个频点的四轮误差降低比例为 5.12%–5.67%。

   .. raw:: html

      </details>


   .. rubric:: 3. 二次项有没有降低未见过的误差？

   对每个目标频率，把测试组的预测误差平方和除以同组 C3 系数模平方和：

   .. k05:equation:: validation-nmse
      :lang: zh

      E_m(f)=\frac{\sum_{r\in\mathcal T}|Y_f^{(r)}-\widehat Y_{f,m}^{(r)}|^2}{\sum_{r\in\mathcal T}|Y_f^{(r)}|^2},\qquad m\in\{0,1\}.


   :math:`\mathcal T` 表示测试分段的集合；:math:`m` 选择模型；
   :math:`|\cdot|` 表示复数的模。无量纲的 :math:`E_m` 是
   **归一化均方误差（normalized mean square error, NMSE）**：
   预测完全正确时为 0，全部预测为零时为 1。它不是等离子体能量所占的比例。
   接着定义二次模型相对线性模型的改善：

   .. k05:equation:: validation-improvement
      :lang: zh

      I(f)=1-\frac{E_1(f)}{E_0(f)}.


   :math:`I>0` 表示二次项减小误差，:math:`I<0` 表示误差反而增加；乘 100 后写成百分数。
   目标功率为零时 NMSE 无定义；线性误差为零时相对改善无定义。
   计算中不会人为添加一个很小的分母来掩盖这些情况。

   .. figure:: /_static/K_Diagnostics/k05-validation-errors.svg
      :alt: 图 4．四轮验证的归一化误差，以及二次模型相对线性模型的误差降低比例。
      :width: 100%

      图 4．四轮验证的归一化误差，以及二次模型相对线性模型的误差降低比例。


   阴影是四组留出结果的范围，不是置信区间；负改善值也保留。
   主配置中，每轮 92 个目标频点里有 87–90 个改善，并非所有频点都更好。
   下表先在整个保留频带内累加误差平方与目标模平方，再取比值，
   因此不同于把逐频率的改善百分数直接作算术平均。

   .. list-table::
      :header-rows: 1
      :widths: 25 25 25 25

      * - 留出组
        - 线性 NMSE
        - 联合 NMSE
        - 误差降低
      * - #2
        - 0.04326
        - 0.04246
        - 1.83%
      * - #3
        - 0.04354
        - 0.04260
        - 2.16%
      * - #4
        - 0.04317
        - 0.04235
        - 1.91%
      * - #5
        - 0.04328
        - 0.04253
        - 1.73%


   全频段总平方误差降低 **1.73%–2.16%**。线性模型已经解释了大部分测得系数功率，
   二次项带来的是小幅附加改善。这是四组数据中重复出现的预测改善，
   还不等于证明了因果耦合，也不自动对应某个统计显著性水平。

   .. rubric:: 4. 继续检查模型还漏掉了什么

   .. figure:: /_static/K_Diagnostics/k05-validation-residuals.svg
      :alt: 图 5．在留出记录上，检查残差与线性输入、二次乘积之间的关联。
      :width: 100%

      图 5．在留出记录上，检查残差与线性输入、二次乘积之间的关联。


   这张图检查测试残差是否仍与目标频率的输入 :math:`X`，或某个二次乘积
   :math:`Z_j` 有关联。残留关联可能意味着模型不完整，或训练组拟合的关系不能完全用于另一组。
   下图取所有波对中的最大值，用来诊断，不是经过多重比较校正的显著性检验。
   残差关联小，也不能证明残差完全来自仪器噪声。

   .. raw:: html

      <details class="k05-note"><summary>残差关联具体怎样算？</summary>

   .. k05:equation:: validation-residual-correlation
      :lang: zh

      \varepsilon_m=Y-\widehat Y_m,\qquad \rho^2_{\varepsilon_m,V}=\frac{|\langle\varepsilon_m V^*\rangle_{\mathcal T}|^2}{\langle|\varepsilon_m|^2\rangle_{\mathcal T}\langle|V|^2\rangle_{\mathcal T}},\quad V\in\{X,Z_1,\ldots,Z_J\}.


   这里略去固定频率和分段下标。:math:`\varepsilon_m` 是模型 :math:`m` 的残差，
   :math:`V` 表示任意一个预测列，在这个公式中不是伏特单位。
   尖括号只对测试分段平均，星号表示共轭，最终比值无量纲。
   最小二乘会使训练残差与保留的预测列空间正交；
   因此到未参与拟合的记录上检查这件事，更能检验关系能否延续。
   残差功率或预测列功率为零时，比值无定义。

   .. raw:: html

      </details>


   .. figure:: /_static/K_Diagnostics/k05-validation-coefficients.svg
      :alt: 图 6．四种训练组选择得到的线性系数幅值和包裹相位。
      :width: 100%

      图 6．四种训练组选择得到的线性系数幅值和包裹相位。


   每条线使用不同的三组训练记录。比较幅值和包裹相位，不把跨越相位折返点的角度直接算术平均。
   联合模型的 :math:`L` 与仅线性模型不必相同：后者可能吸收了与二次预测列相关的贡献，
   见 :k05:eq:`linear-only-bias`。这些是电压模型的传递系数，
   其幅值大于或小于 1 都不能直接当成已标定的物理增长率。

   .. rubric:: 5. 各预测列能否被分辨？

   .. figure:: /_static/K_Diagnostics/k05-validation-conditioning.svg
      :alt: 图 7．缩放后联合预测矩阵的条件数与秩。
      :width: 100%

      图 7．缩放后联合预测矩阵的条件数与秩。


   **条件数（condition number）** 衡量近似不可区分的列组合会怎样放大数值误差，
   **秩（rank）** 表示数值上独立的列数。
   主配置的 368 次拟合全部满秩，缩放后的最大条件数为 10.76。
   这说明数值上的列区分较好，但不能消除输入测量噪声造成的偏差，
   也不能证明每个系数都有唯一的等离子体物理解释。

   .. raw:: html

      <details class="k05-note"><summary>只用训练数据缩放，再用 SVD 求解</summary>

   固定一个频率，矩阵 :math:`\mathbf D` 的第 :math:`r` 行为
   :math:`(X_f^{(r)},Z_1^{(r)},\ldots,Z_J^{(r)})`；
   :math:`\mathbf y` 存放训练目标 :math:`Y_f^{(r)}`。
   未知向量 :math:`\boldsymbol\theta=(L,Q_1,\ldots,Q_J)^T` 保留原有单位。
   先用每列在训练集上的 RMS 缩放：

   .. k05:equation:: validation-scaled-solve
      :lang: zh

      \begin{aligned}s_j&=\sqrt{\langle|D_{rj}|^2\rangle_{\rm train}},\quad \widetilde D_{rj}=D_{rj}/s_j,\\ \widehat{\boldsymbol\beta}&=\underset{\boldsymbol\beta}{\operatorname{argmin}}\,\|\mathbf y-\widetilde{\mathbf D}\boldsymbol\beta\|_2^2,\quad \widehat\theta_j=\widehat\beta_j/s_j.\end{aligned}


   这里 :math:`j` 编号所有矩阵列，包括线性列。:math:`s_j` 与对应列同单位，
   :math:`\widetilde D` 无量纲，:math:`\beta_j` 单位为 V；
   最后除以 :math:`s_j` 恢复 :math:`\theta_j` 的单位。
   :math:`\|\cdot\|_2` 是对复数模平方求和再开方的欧氏范数。
   这一步不再减列均值，不添加截距，也不把两通道幅度归一化成相同。

   NumPy 的奇异值分解（singular value decomposition, SVD）最小二乘求解器 [3]
   使用 ``rcond=1e-10``，舍弃小于最大奇异值这一比例的方向。
   满秩时条件数是最大与最小奇异值之比；秩不足记为无穷大。
   秩不足或条件数超过 :math:`10^8` 时标记系数不能可靠分离，
   保留预测及该标记，不悄悄删去困难结果。
   训练列恰好为零时给它零系数，并标记秩不足。测试组从不参与缩放或拟合。

   .. raw:: html

      </details>


   .. rubric:: 6. 改变设置，而不从测试结果中挑选赢家

   .. figure:: /_static/K_Diagnostics/k05-validation-sensitivity.svg
      :alt: 图 8．在共同目标频点上，比较全部预定分段长度和输入频带。
      :width: 100%

      图 8．在共同目标频点上，比较全部预定分段长度和输入频带。


   左列固定输入上限 5 MHz，把段长改为 1024、2048、4096 点，
   每组分别有 9765、4882、2441 段。右列固定段长 2048 点，把二次输入上限改为
   3、5、8 MHz。目标频带始终为 0.5–5 MHz。
   更长分段同时改变频率分辨能力与平均次数；更宽输入带也会增加预测列数。

   这里仅在各设置恰好共有的目标频点上比较，不插值；曲线是四轮测试结果的平均。
   五个预先确定的配置全部展示，不按测试得分选择最优者。
   小幅改善的总体趋势仍在，但幅度和局部正负号依赖设置。
   约 4 MHz 附近，纳入更高频的输入波对会明显改变预测贡献，
   因此某个窄峰不能立即当成不依赖分析设置的物理速率。

   下图把所有二次项合成后的预测功率除以目标实测功率，
   其中 :math:`B=\sum_jQ_{fj}Z_j`，:math:`P_Y=\langle|Y_f|^2\rangle`。
   不同窗长会改变单个频点的统计量，因此比较的是归一化贡献，
   没有把不同频率网格上的单个 :math:`Q` 强行对应。

   .. raw:: html

      <details class="k05-note"><summary>带正负号的二次贡献，究竟表示什么？</summary>

   固定一个目标频率，把联合预测拆成两部分：

   .. k05:equation:: validation-power-budget
      :lang: zh

      \begin{aligned}A&=L_{f,1}X_f,\quad B=\sum_jQ_{fj}Z_j,\\ \langle|\widehat Y_{f,1}|^2\rangle_{\mathcal T}&=\langle|A|^2\rangle_{\mathcal T}+2\operatorname{Re}\langle A^*B\rangle_{\mathcal T}+\langle|B|^2\rangle_{\mathcal T}.\end{aligned}


   :math:`A` 是线性部分，:math:`B` 是所有二次项的总和，单位都为 V。
   这里的 :math:`B` 不是前面页面表示双谱的符号。
   :math:`\operatorname{Re}` 取实部，三个功率项的单位都是 V²，平均均在留出组上进行。
   :math:`|B|^2` 包含不同波对之间的交叉项，不能替换成各波对功率的简单相加。

   .. figure:: /_static/K_Diagnostics/k05-validation-budget.svg
      :alt: 图 9．联合模型的完整功率分解，以及各波对的有符号交叉贡献。
      :width: 100%

      图 9．联合模型的完整功率分解，以及各波对的有符号交叉贡献。


   左图把三个项分别除以目标实测功率，右图在固定示例频率处进一步分解交叉项：

   .. k05:equation:: validation-pair-cross
      :lang: zh

      c_j=\frac{2\operatorname{Re}\langle A^*Q_{fj}Z_j\rangle_{\mathcal T}}{P_Y},\qquad P_Y=\langle|Y_f|^2\rangle_{\mathcal T},\quad \sum_jc_j=\frac{2\operatorname{Re}\langle A^*B\rangle_{\mathcal T}}{P_Y}.


   :math:`c_j` 无量纲；正值增加这个预测功率交叉项，负值减小它。
   波对按带符号的 :math:`f_1` 从小到大排列，横轴标出代表频率；
   :math:`f_2=f-f_1`，完整频点对表随结果保存。
   这个正负号不是已经测得的等离子体模式间能量流向。
   完整预测功率还必须保留 :k05:eq:`validation-power-budget` 中的两个模平方项。

   .. raw:: html

      </details>


   .. rubric:: 这次验证支持什么结论？

   联合模型对留出电压记录的总体预测略优于仅线性模型，
   所测配置的数值矩阵条件良好；频率依赖和贡献大小仍对分析设置敏感。
   这些结果支持进一步研究模型，但还没有确定 EDI 增长、能量转移方向或逆级联。
   后者还需要测量响应和传播条件。
   :ref:`探针响应页面 <k05-response-zh>` 用扫描探针数据检查收集状态和电路响应情景。

   .. raw:: html

      <details class="k05-note"><summary>复现计算与查看结果</summary>

   .. code-block:: bash

      OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 \
      python K_Diagnostics/K05_bispectral_transfer/validate_experiment.py \
        --data /path/to/experiment-data \
        --output /path/to/model-validation

   输出包含九张 SVG／PNG 图、``validation_summary.json`` 和 ``validation_arrays.npz``。
   摘要记录输入哈希、分组、所有预定设置和软件版本；数组保留系数、波对、训练缩放、
   奇异值、测试误差及模型功率项。使用单独输出目录保留谱统计量页的分析。

   下载 :download:`validation script <../../../../K_Diagnostics/K05_bispectral_transfer/validate_experiment.py>`,
   :download:`shared preprocessing <../../../../K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py>`,
   :download:`binary reader <../../../../K_Diagnostics/K05_bispectral_transfer/siglent_v4.py>`,
   :download:`metadata <../../../../K_Diagnostics/K05_bispectral_transfer/experiment_z5p5_a3p7.json>`
   以及 :download:`run summary <../../_static/K_Diagnostics/k05-validation-summary.json>`.
   在仓库外运行时，把 Python 文件和元数据放到同一目录。原始二进制文件作为外部输入，打开网页不会重新计算。

   .. raw:: html

      </details>

   .. rubric:: 参考文献

   [1] Z. A. Brown and B. A. Jorns, “Growth and Saturation of the Electron Drift
   Instability in a Crossed Field Plasma,” *Physical Review Letters* **130**, 115101 (2023).
   `doi:10.1103/PhysRevLett.130.115101 <https://doi.org/10.1103/PhysRevLett.130.115101>`_.

   [2] scikit-learn, *Cross-validation: evaluating estimator performance*.
   `Grouped data and avoiding test-set leakage <https://scikit-learn.org/stable/modules/cross_validation.html>`_.

   [3] NumPy, ``numpy.linalg.lstsq``.
   `Least-squares solution and singular-value cutoff <https://numpy.org/doc/stable/reference/generated/numpy.linalg.lstsq.html>`_.

   [4] SciPy, ``scipy.signal.coherence``.
   `Magnitude-squared coherence definition <https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.coherence.html>`_.
