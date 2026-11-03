# K05 equation numbering

K05 uses one consecutive reading-order sequence, `(K05.1)`, `(K05.2)`, …,
across the peer articles listed in the overview. Equations inside disclosures
participate in that sequence. English and Chinese versions share a number but
have separate language-specific link targets. The cited paper's numbers are separate.

**Revision 31 policy (2026-11-03):** at the user's request, display numbers now
follow article order and then equation appearance. This supersedes the old
append-only policy. Semantic IDs, rather than display numbers, provide stable
links. Do not reuse a removed semantic ID for an unrelated equation.

After adding, removing or moving equations, run from the repository root:

```sh
python K_Diagnostics/K05_bispectral_transfer/renumber_equations.py --write
python K_Diagnostics/K05_bispectral_transfer/renumber_equations.py --check
```

The script checks matching bilingual order and unique IDs, then writes
`docs/source/_data/k05_equations.json`. Use semantic equation roles throughout
the pages, not literal display numbers. Rebuild every page so cross-references
receive the new numbers. Revision 31 has 149 active equations; the complete
old/new mapping, including removed IDs, is in
`equation_number_migration_20261103.json`. Removed growth-ordering and Taylor
helper equations retain legacy HTML anchors at related surviving explanations.

In an English container:

```rst
.. k05:equation:: real-wave
   :lang: en

   u(y,t)=h(y,t)\cos(ky-\omega t).

See :k05:eq:`real-wave`.
```

Use the same ID and identical LaTeX with `:lang: zh` in the Chinese container.
Define each ID only once per language; reuse it elsewhere through a reference.
The role selects the language from the containing `ap-lang-en` or `ap-lang-zh`
container. Outside a language container it defaults to English; an explicit
target such as ``:k05:eq:`real-wave@zh` `` selects Chinese. A custom link caption
uses the usual syntax: ``:k05:eq:`the real wave <real-wave>` ``.

The Sphinx domain in `docs/source/_ext/k05_equations.py` resolves links across
pages and catches unknown IDs, duplicate targets and inconsistent translations.
Its JavaScript opens a target's disclosure and language panel on navigation.
Use this directive for K05 display equations instead of manual `\tag` numbers.
The current renderer uses `math_numfig = False` (the Sphinx default); do not
enable global figure-based math numbering without adapting this domain.

With documentation dependencies installed, run from the repository root:

```sh
python -m unittest discover -s docs/tests -v
python -m sphinx -E -a -b html -W --keep-going docs/source docs/build/html
```

## Historical revision notes (before the numbering migration)

The numbers and append-only instructions below describe earlier editions only.
Use the current policy above and the registry for maintained references.

Revision 4 retires IDs `example-inputs`, `example-forcing`, and `example-solution`
(numbers 11–13) after removing the maintained-input example. Keep their registry
entries reserved; do not reuse them. New derivation steps have numbers 18–21.
The envelope equation remains K05.7, the one-dimensional result is K05.20,
and the three-dimensional result remains K05.15.

The response derivation now lives in `K05_envelope_coefficients.rst`.
Moved IDs `dielectric-expansion` and `response-coefficients` keep numbers 16
and 17; new intermediate steps use 22–34. Cross-page equation roles resolve
to their new document. Legacy fragments for 16 and 17 on the first page lead
to the next-page preview, which links to the relocated equations.
Revision 6 adds 35–44 for the packet spectrum, Taylor expansions, offset
substitution, growth-ordering checks and Poisson rearrangement. Add further
IDs after 115; do not renumber the sequence into reading order.

The overview and articles use neutral text without temporary revision colours.
Illustration colours continue to identify the plotted quantities.
Implementation-status reminders belong in the project handoff, not the reader pages.

The probe-record page `K05_probe_signals.rst` adds 45–59. Its time Fourier
series uses normalized two-sided voltage coefficients and a positive exponent
in the forward transform. The K01/NumPy forward FFT has the opposite sign;
the page gives the conversion explicitly. Do not merge these conventions silently.

Revision 8 keeps `K05_bispectral_transfer.rst` as a short overview. Its toctree
lists `K05_wave_growth`, `K05_envelope_coefficients`, and `K05_probe_signals`
as peer documents. The child documents must not contain one another in a toctree.
The first article retains its semantic labels; equation roles find its new URL.
`k05-legacy-links.js`, loaded only by the overview, routes observed old fragment
URLs to the moved article (and old 16/17 fragments to the response page).

Numbers 60–62 are the Nyquist definition, integration by parts and integrating
factor derivation. Existing IDs and numbers, including 54 and 56, stay unchanged.
The NumPy snippets use default FFT normalization and real one-dimensional inputs;
the positive-exponent coefficients agree with `ifft(s)` and `conj(fft(s))/N`.

Revision 10 adds the fourth peer article `K05_spectral_statistics.rst` and
numbers 63–75. Preserve the positive-exponent, normalized voltage coefficients.
Bin powers and cross powers have units V^2; the bispectra have units V^3.
The auto-bispectrum is <X1 X2 X3*>; the cross bispectrum is <Y3 X1* X2*>.
The latter reduces to the conjugate of the former when Y=X. State conventions
before connecting them to estimators. The continuous power balance keeps the
group velocity on the left and the factor 2 on both growth and nonlinear terms;
it is an explanatory derivation, not a redefinition of the paper's discrete rate.
The interactive illustration prescribes phases and uses exact coefficients;
it does not simulate coupling or infer causality. Finite random averages do
not generally vanish. The sample NumPy function is in a disclosure, not an API.

Revision 11 adds `K05_coefficient_inference.rst` as the fifth peer, with 76–93.
Use b_i=<X Z_i*> and d_i=<Y Z_i*> as column vectors; F_ij=<Z_i* Z_j>.
Keep all fourth-order entries. Merge duplicate ordered products before fitting;
the combined coefficient contains both orders when the inputs differ.
Joint least-squares estimation and Kim's stationary model-power inference are
different estimators and must not be presented as interchangeable.
Raw L,Q retain propagation phase; use exp(-i delta) before the continuous rate
conversion. Preserve the factor 2 in the continuous mean-square balance, and
distinguish it from the displayed reference Eq. (6) and the finite-step Q-squared
term. The overview credits Yinjian Zhao, Harbin Institute of Technology.

Revision 12 removes the fifth-page NumPy disclosure and its unused reference.
The Kim disclosure introduces modelled/nonideal Fourier components, their power
split, explicit cross-power terms, and the three scalar moment equations before
stationarity. New intermediate equations use 94–99. Equations 84–86 retain their
numbers and LaTeX inside a nested algebra disclosure; equation links reveal both
levels. The nonideal-moment approximation is an assumption, not a general noise
cancellation identity. Pages remain neutral; wait for reader feedback before
starting another page.

Revision 13 adds the sixth peer experimental page and numbers 100–105.
The voltage observable is an ion-current diagnostic output, not calibrated
plasma potential. Default record centring removes the disputed DC offset sign.
Windowed coefficients keep exp(+iwt)/N; one-sided PSD corrects Hann mean-square
gain, without changing bispectrum definitions. Statistical plots do not imply
physical growth, energy transfer, a unique wavenumber, or a group velocity.

Revision 16 appends 106–108 in experimental-page disclosures: cross-power
phasor averaging, a shared-signal/uncorrelated-noise coherence model, and the
positive-exponent Fourier phase of a pure delay. Noise powers in that example
are illustrative, not measured calibration. Wrapped phase signs alone do not
identify propagation direction; phase masking is not a physical frequency cutoff.

Revision 18 adds the seventh peer page `K05_model_validation.rst` and 109–115:
held-out linear/joint predictions, NMSE, relative error reduction, training-only
column scaling, residual association, and the complete finite-step prediction
power budget with normalized signed pair cross contributions. These are voltage
prediction statistics, not Kim-corrected coefficients, physical growth rates or
plasma energy transfer. Hold out entire captures, retain signed difference pairs,
and use the same predetermined settings in both languages. Invalid metrics remain
undefined; negative improvements and failed-identifiability flags are retained.

Revision 21 appends 116 (`validation-linear-predictable-power`) in the
high-frequency-result disclosure on page 07. For a no-intercept optimal linear
predictor evaluated in the same statistical population, predicted bin power
equals magnitude-squared coherence times target bin power. Assume nonzero input
and target powers. A separately held-out record and a quadratic predictor need
not satisfy this identity. Retain the distinction between a PSD mismatch,
prediction error and a physical energy-transfer rate.

Revision 22 adds peer page 08 `K05_probe_response.rst` and equations 117–124.
The nominal resistor current is positive toward its return; the swept-probe net
current is electron-positive and has the opposite sign. Probe voltage includes
the slow bias power supply and resistor drop. Te is a conditional logarithmic-slope estimate,
not a unique measured bulk temperature. The RC transfer uses exp(+iwt) forward
and thus R/(1-iwtau). Estimated capacitance, cathode/chamber offset, gain and delay
are explicit provisional scenarios. Existing measured spectra are not corrected.
The metadata now identifies C1 as the left fixed probe. R22 next equation was 125.


Revision 24 rewrites page 08 as a practical mean-I–V workflow, without new
physical derivations. Append 125 (response-mean-sweep-point); preserve 117–124
and all earlier equation IDs/numbers. At R24 the next equation was 126; R25 uses 126–132.
The mean reduction groups by imposed supply voltage and averages both channels;
the historical instantaneous-probe-voltage median is a controlled comparison.
0015 gives 9.1689 eV with the mean pipeline and 6.7262 eV with the old median
pipeline; this difference is mainly curve construction. Temperature means here
an effective logarithmic slope, not independently calibrated bulk Te.
The figure label Te,fit in eV is the numerical value of Theta_e in volts in
equation 120; Te in that equation itself is in kelvin. Bars in 125 denote bin
arithmetic means; they are omitted in later curve labels where explicitly stated.

## Page 10 supplement: measured-power budget

Append-only IDs 126–132: budget-common-power, budget-reference-phase, budget-signal-parts, budget-full-identity, budget-increment-identity, budget-increment-parts, budget-distance-conversion. Both languages share these numbers. R28 appends 133–138 below; next new number: 139. The local A is a linear predicted signal, r a residual, and D a predicted increment; these are explicitly distinguished from earlier symbols.


## Page 09: experimental counterparts of Figures 2 and 3

R28 moves the existing budget article to reading position10 without changing its
file path, labels or equations126–132. Page09 is K05_paper_comparison.rst.
Append133–138 in order: comparison-rate, comparison-dispersion,
comparison-gordeev, comparison-branch, comparison-transfer, comparison-symmetric-q.
Next139. The kinetic slab uses k_perp=ky, fixed k_parallel and zero ion Doppler
shift; explicit estimated inputs are not mode identification. Te in this kinetic
formula is an energy in joules, converted from the eV configuration. This differs
from the Kelvin convention of the swept-probe equation120.
Rates use full complex roots and Re[-E_ky/E_omega] for the illustrative branch.
The voltage transfer uses the half-power convention of Brown Eq6; the full
squared-amplitude contribution is twice that value. Symmetric maps split unique
off-diagonal coefficients in two and reconstruct negative targets by conjugation.
Do not confuse a missing map cell with a zero coupling estimate.


## R30: original-equation comparison and reading closure

Append139–145 as paper-equation-1 through paper-equation-7. Each is a literal
mathematical transcription of the source (line wrapping only), placed below
its K05 counterpart in k05-paper-match. Headers retain source [1] Eq.(n);
K05 numbers provide stable cross-page links. Do not silently repair original
phase/factor/index conventions: explain them after the printed expression.
Source(5) repeats the pair labels in its second line; the notes distinguish
fixed multiplying row i and summed pair j, without dropping off-diagonal moments.

Append146–150: kinetic-linear-vlasov, kinetic-cold-ion, kinetic-orbit-average,
kinetic-electron-response, kinetic-poisson-closure. Source(7) is the scaled
dielectric; derive the full cold-beam form before describing the saved zero-ion-
Doppler specialization. Append151–152: paper-transverse-growth and
paper-saturated-balance on new peer page11. Next unused number153.
All previously active formulas retain their numbers and mathematical text.
The phase-space distributions F, time lag s, Gordeev X/Y, Larmor rho and
charge density rho_1 must be distinguished from earlier statistical symbols.
The static source images k05-reference-figure2/3.png are extracted from the
supplied paper, not newly generated measurements. Caption them as source figures.
