# K05 · Bispectral transfer

[中文](README.zh-CN.md) | [English](README.en.md)

Learn how wave growth and coupling lead to the probe-data analysis in Brown &
Jorns, *Physical Review Letters* **130**, 115101 (2023),
[doi:10.1103/PhysRevLett.130.115101](https://doi.org/10.1103/PhysRevLett.130.115101).

## Reading guide

The [K05 overview](../../docs/source/rst_files/K_Diagnostics/K05_bispectral_transfer.rst)
introduces the purpose and lists eleven peer articles in reading order.

The [first page](../../docs/source/rst_files/K_Diagnostics/K05_wave_growth.rst)
derives the structure of Eq. (1) of Brown & Jorns (2023). It introduces a real wave, its complex
envelope, motion of that envelope, quadratic coupling, and restoration of the
fast phase. Optional derivations fold away. An interactive wave packet separates
crest motion, envelope motion, and amplitude growth. Its values are illustrative,
not measurements or a kinetic EDI calculation.

The [second page](../../docs/source/rst_files/K_Diagnostics/K05_envelope_coefficients.rst)
derives the envelope equation from the plasma response: self-consistency,
nearby-wave offsets, the group velocity and growth rate, then a separate
second-order charge response for quadratic coupling. It works in one dimension
before extending to three. Poisson details, chain-rule calculations and the
approximation limits are optional disclosures.

A second interactive illustration connects a Gaussian band of wavenumbers to
its wave packet. Spectral-width and time controls use a linear dispersion
branch; the exact functions are given in a disclosure. The Taylor explanation
connects one-variable calculus to the two-variable expansion, retains the
omitted terms, and compares the sizes of terms in the weak-growth approximation.
The Poisson substitution is also expanded step by step.

The [third page](../../docs/source/rst_files/K_Diagnostics/K05_probe_signals.rst)
connects a moving wave to fixed-probe records and derives the time-frequency
form of Eq. (2). It specifies signed, normalized Fourier coefficients and
shows how derivatives and quadratic products become frequency-domain terms.
Optional calculations explain the cosine coefficients and carrier cancellation.
A linked spatial
wave and two time traces illustrate the measurement; the ion-current proxy
is explained separately from the ideal potential detectors.

The [fourth page](../../docs/source/rst_files/K_Diagnostics/K05_spectral_statistics.rst)
introduces record averages, bin power, cross-power phase, the bispectrum
and an optional squared-bicoherence normalization. The three-coefficient
product explains how phase relationships survive averaging.
The page derives a continuous mean-square-potential balance, then introduces
the two-probe cross bispectrum and a short NumPy moment function.

The [fifth page](../../docs/source/rst_files/K_Diagnostics/K05_coefficient_inference.rst)
starts with one pair and two coefficients, then expands a two-pair, three-row
example before introducing the full moment matrix. A practical Kim calculation
recipe obtains the common model power and coefficients from measured moments,
with assumptions and admissibility checks stated explicitly. Intermediate phase
derivatives and substitutions connect the fit to amplitude growth and mean-square
transfer. The conclusion distinguishes statistical closure from the additional
propagation, calibration and plasma-response inputs needed for physical rates.

The English views use English only; the Chinese views include English terms.
All eleven articles use the shared K05 equation sequence and cross-page references.
See [equation authoring](EQUATIONS.md) before adding a page or equation.

## Workflow from data to figures

1. Specify synchronized probe voltages, sampling rate, probe order, separation,
   calibration, stationarity windows, and uncertainty inputs.
2. Connect to K01 spectra after explicitly reconciling the Fourier sign,
   amplitude normalization, and positive/negative frequency conventions.
3. Calculate third- and fourth-order statistics, and estimate the linear and
   quadratic coefficients with conditioning and synthetic-data checks.
4. Convert spatial coefficients into growth and transfer rates using the
   required propagation information. Distinguish amplitude from power growth.
5. Produce spectra, growth-rate curves and transfer maps with uncertainty and
   provenance. Matching the published figures requires appropriate experimental
   data and parameters; none are bundled here.

The comparison boxes document phase, normalization, pair counting and the
factor of two; the experimental example uses explicit conventions throughout.
K01 currently uses NumPy's forward `exp(-i omega t)` transform and the cross
spectrum `X1 * conj(X2)`; do not change that convention implicitly.

## Edit, build, and continue

- Pages: `docs/source/rst_files/K_Diagnostics/K05_bispectral_transfer.rst` and
  `K05_envelope_coefficients.rst` and `K05_probe_signals.rst` in the same directory; the first article is
  `K05_wave_growth.rst` and the entry page is a short overview.
- Teaching assets: `docs/source/_static/K_Diagnostics/k05-wave-packet.{js,css,svg}`.
- Packet-band assets in that directory: `k05-packet-band.js` and bilingual
  `k05-packet-band-{en,zh}.svg` fallbacks. To regenerate a fallback, load the
  JavaScript with Node's `require`, call `plotSvg(0.30, 0, lang, uniqueId)`,
  and save the returned SVG as UTF-8. The browser uses the same renderer.
- Probe illustration: `k05-probe-signals.js` and bilingual
  `k05-probe-signals-{en,zh}.svg` fallbacks. Regenerate using the exported
  `plotSvg(0.5, 0, lang, uniqueId)` renderer. Controls use arbitrary units.
- Numbering and link infrastructure: see [EQUATIONS.md](EQUATIONS.md).
- Fifth article: `docs/source/rst_files/K_Diagnostics/K05_coefficient_inference.rst`.
- Fourth article: `docs/source/rst_files/K_Diagnostics/K05_spectral_statistics.rst`.
- Navigation: the toctree in `K05_bispectral_transfer.rst` lists the eleven articles.
- Install the existing `docs/requirements.txt` in a suitable environment; the
  documentation configuration also invokes Doxygen. From the repository root:

```sh
python -m sphinx -b html -W --keep-going docs/source docs/build/html
python -m http.server 8055 --bind 127.0.0.1 --directory docs/build/html
```

Open `http://localhost:8055/rst_files/K_Diagnostics/K05_bispectral_transfer.html`.
Do not edit the generated HTML. Check both language views, equations, disclosures,
and the time/growth/play controls after edits.

Reading order: wave growth and coupling → the origin of the envelope equation
and its coefficients → fixed-probe records and the time Fourier form of Eq. (2)
→ power, cross and bispectral statistics. Keep the main narrative simple;
put technical qualifications in optional disclosures. Check equations against
the original paper, printed page 115101-2. The local literature study project's
shared `HANDOFF.md` records the wider reading history; this checkout and that
project require their own actual synchronization to be available on another PC.

## Experimental walkthrough

The [sixth page](../../docs/source/rst_files/K_Diagnostics/K05_experimental_signals.rst)
follows a fixed paired capture from samples to complex Fourier coefficients,
power/PSD, cross spectra and complex bispectra, with four captures for comparison.
The main path uses N=2048 throughout. Run `analyze_spectral_walkthrough.py`; see
[reproduction instructions](EXPERIMENT.md) for saved moments and numerical checks.
Raw captures remain external. Figures use record-centred voltage fluctuations;
DC calibration, channel response and physical rate conversion are distinguished.

The [seventh page](../../docs/source/rst_files/K_Diagnostics/K05_experimental_coefficients.rst)
works from measured complex moments to linear-only L, a real two-pair matrix,
full signed-pair joint L/Q and the Kim common-power check, ending with held-out
residuals. Reproduce its seven figures with analyze_coefficient_walkthrough.py.

The [validation supplement](../../docs/source/rst_files/K_Diagnostics/K05_model_validation.rst)
compares linear and quadratic predictions with four whole-capture holdouts.
It follows errors, residual relations, coefficient identifiability and all preset
sensitivity settings. Reproduce it with `validate_experiment.py` as described
in [EXPERIMENT.md](EXPERIMENT.md).

The [eighth page](../../docs/source/rst_files/K_Diagnostics/K05_probe_response.rst)
uses slow DL350 sweeps to reconstruct I–V curves, estimate local-slope temperatures
and inspect bias and electrical response with explicitly labelled provisional inputs.
Run `analyze_probe_sweep.py` with `probe_sweep_config.json` for the mean I–V workflow.
The page compares mean and median characteristics on the same 0015 record,
explaining the 6.73 versus 9.17 eV estimates. The old median pipeline is retained
for comparison; see [EXPERIMENT.md](EXPERIMENT.md).


Page09: [Experimental counterparts of Figures 2 and 3](../../docs/source/rst_files/K_Diagnostics/K05_paper_comparison.rst) shows the five panels first, then explains their calculation and explicit parameter estimates. Page10: [Supplement](../../docs/source/rst_files/K_Diagnostics/K05_power_budget.rst) explains the common-power and complete-budget checks. Reproduction: EXPERIMENT.md.


## Equation comparison and concluding synthesis

Pages01,03,05,09 put the corresponding K05 expression and original reference
Eqs.(1)–(7) in permanent comparison boxes with symbol/normalization notes.
The overview links directly to all seven. Their semantic IDs provide stable links;
display numbers follow K05 reading order, while box headings retain the article's
own equation numbers. After inserting or moving equations, run
`renumber_equations.py --write`, then `--check` and a full documentation rebuild.
See [EQUATIONS.md](EQUATIONS.md) for the numbering policy and R31 migration map.
The page09 disclosure derives the linear Vlasov response, cold-ion susceptibility,
Maxwellian gyro-orbit average and Poisson closure.
[Page11](../../docs/source/rst_files/K_Diagnostics/K05_paper_synthesis.rst)
reads the original figures, derives the transverse-growth connection and a
conditional stationary balance, and closes the reading with a
result map and symbol guide. Experimental output arrays are unchanged.
