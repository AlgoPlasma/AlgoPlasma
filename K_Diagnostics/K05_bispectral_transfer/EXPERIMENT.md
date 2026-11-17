# Reproduce the experimental spectral walkthrough

## Current analysis workflow (2026-11-17)

The analysis sequence ends at page08; [page09](../../docs/source/rst_files/K_Diagnostics/K05_scripts.rst)
connects the scripts to those explanations, input/output contracts and tests.
The commands below close the data pipeline without requiring the removed supplement pages. Numerical scripts and
previous results are retained; the later sections document their settings.
Run from the repository root after installing this module's `requirements.txt`
(NumPy, SciPy and Matplotlib). Run `python -m unittest discover -s
K_Diagnostics/K05_bispectral_transfer -p "test_*.py" -v` for the private-data-free
numerical checks; see the README for a copyable single-line command.
Replace each `/path/to/...` with a real path; use a new output directory per run.

```bash
# Page06: the consistent N=2048 statistical walkthrough.
python K_Diagnostics/K05_bispectral_transfer/analyze_spectral_walkthrough.py \
  --data /path/to/raw-captures --output /path/to/walkthrough
# Page07 parents and worked coefficient example.
python K_Diagnostics/K05_bispectral_transfer/validate_experiment.py \
  --data /path/to/raw-captures --output /path/to/validation
python K_Diagnostics/K05_bispectral_transfer/analyze_transfer_budget.py \
  --data /path/to/raw-captures --output /path/to/budget
python K_Diagnostics/K05_bispectral_transfer/analyze_coefficient_walkthrough.py \
  --data /path/to/raw-captures --validation /path/to/validation \
  --budget /path/to/budget --output /path/to/coefficients
# Preserve the N=16384 PSD parent used in the page08 spectrum panel.
python K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py \
  --data /path/to/raw-captures --output /path/to/spectra
python K_Diagnostics/K05_bispectral_transfer/analyze_paper_comparison.py \
  --budget /path/to/budget/transfer_arrays.npz \
  --validation /path/to/validation/validation_arrays.npz \
  --spectra /path/to/spectra/spectral_arrays.npz \
  --config K_Diagnostics/K05_bispectral_transfer/paper_comparison_config.json \
  --output /path/to/comparison-parent
# Page08: expanded coefficients, selected physical scenario and paired plots.
OPENBLAS_NUM_THREADS=2 python K_Diagnostics/K05_bispectral_transfer/analyze_extended_comparison.py \
  --data /path/to/raw-captures --output /path/to/extended
python K_Diagnostics/K05_bispectral_transfer/analyze_physical_scenario.py \
  --extended /path/to/extended --output /path/to/physical
python K_Diagnostics/K05_bispectral_transfer/plot_physical_comparison.py \
  --extended /path/to/extended --comparison /path/to/comparison-parent \
  --physical /path/to/physical --output /path/to/figures
```

The comparison parent supplies PSD only to the final plotter; its older
5 MHz fits and kinetic roots do not replace the page08 20 MHz fit or moving-ion
scenario. Raw data are read-only. No numerical rerun is needed for a page-only
edit. Existing physical outputs also retain sensitivity checks for provenance;
the public page uses only the selected 1 cm acceleration length and 15 degree
perpendicular-plane tilt. Removed figures are not linked from the page.


The sixth peer page uses dataset `z5p5_a3p7`: four synchronous C1/C3 captures
from ion-saturation-current probes at one operating condition. Acquisition
facts and explicit unknowns are in `experiment_z5p5_a3p7.json`. Original binary
data are external inputs; no raw `.bin` files are included in the repository.

## Current page 06: a single N=2048 calculation path

```bash
python K_Diagnostics/K05_bispectral_transfer/analyze_spectral_walkthrough.py \
  --data /path/to/experiment-data \
  --output /path/to/new-walkthrough-results
```

This is the current page-06 producer. Choose an empty output directory; it refuses
to overwrite an earlier run. `--metadata` accepts the acquisition JSON. It reuses
`siglent_v4.py` and the Fourier, PSD and bispectral functions in
`analyze_experiment.py`, without changing earlier outputs or later fitted models.
Keep those three scripts together when downloading rather than cloning the repo.

All main statistics use 2048 samples, segment demeaning, periodic Hann, no overlap,
positive-exponent/N coefficients: 4882 segments and 1664 unused samples per capture.
The worked example is fixed at capture 2, its first segment and the bin nearest
2 MHz (k=41, f=2.001953125 MHz); it is not chosen for a large coupling result.
Four captures are calculated independently. Stored bicoherence and complex B
cover 0<f1<=f2 and f1+f2<=5 MHz. This displayed triangle is not a regression basis.

The eight `k05-walkthrough-*.svg`/`.png` plots follow records, windowing, complex
coefficients, power averaging, PSD, cross statistics, complex B, and bicoherence.
The complex-B panels share a signed symlog scale with a 1e-9 V³ linear threshold
and the largest absolute component as the common limit. It is only a display scale.
`walkthrough_arrays.npz` includes `frequency_hz` (all nonnegative bins),
`g{2,3,4,5}_P_c{1,3}`, `..._psd_c{1,3}`, `..._G`, `..._coherence`, `..._B_c{1,3}`,
`..._b2_c{1,3}`, and capture-2 segment arrays `g2_X_band`, `g2_Y_band` through 5 MHz.
Figure 3 uses all 1025 nonnegative bins through 50 MHz for the first segment,
with a logarithmic modulus axis. The producer reconstructs this full spectrum
from the saved demeaned first-segment samples and Hann window; it checks the
0–5 MHz slice against the stored coefficients. The fixed-frequency complex-plane
panel is unchanged. The R37 figure-only redraw has separate provenance in
the published summary's figure_revisions field; the original statistical-run
hashes are retained rather than relabelled as a new analysis.

Their first axis is segment and second axis is frequency bin; B matrices use
row=f1, column=f2. NaN in B marks the uncomputed domain. B is `<X1 X2 conj(X3)>`;
the b vector of page05 uses its conjugate. The products remain in voltage units.
The first segment, window and min/max display aggregates are also retained.

`walkthrough_summary.json` records settings, metadata, input/source hashes,
software, the fixed numerical example and checks against SciPy Welch plus the
window-weighted Parseval identity. Input hashes are checked again after plotting.
Copy the eight new SVGs and the summary as `k05-walkthrough-summary.json` into the
K05 static-assets folder. Full arrays and PNGs stay outside Git. The supplemental
1 ms RMS and segment-length sensitivity figures retain their original provenance.

The older N=16384 PSD/coherence overview below is retained for reproduction of
historical figures and existing paper-comparison panels. It is not the main grid
on the rewritten page06; do not mix its averages with N=2048 moments. The coefficient walkthrough reuses and audits the saved fits; it does not change
those parent results. Detailed validation settings remain below.


## Page 07: measured moments to coefficients (R38)

Run with NumPy, SciPy and Matplotlib, after generating the preserved validation
and transfer-budget outputs described below:

```bash
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
python K_Diagnostics/K05_bispectral_transfer/analyze_coefficient_walkthrough.py \
  --data /path/to/experiment-data \
  --validation /path/to/model-validation \
  --budget /path/to/transfer-budget \
  --output /path/to/new-coefficient-walkthrough
```

--metadata optionally replaces experiment_z5p5_a3p7.json. Output must be empty.
All eight raw hashes must match both parent manifests. The script checks common
grids and all saved LS coefficients, reconstructs N=2048 coefficients through
5 MHz, verifies the main split's training PX/PY/G across all targets, and
independently refits its fixed 2.001953125 MHz example. Parent arrays remain
unchanged; all-grid curves reuse the audited parent results. This is a new
explanation and targeted numerical audit, not a new all-grid inference run.

The main fit trains on captures3/4/5 (14646 rows), testing capture2 (4882 rows).
Page06's worked PX/PY/G were capture2 averages; distinguish these from training
moments. The teaching model uses fixed bin pairs (10,31) and (-10,51), never
selected by large Q. It explicitly evaluates the raw and RMS-scaled 3x3 moments.
The full example uses all81 signed pairs feeding bin41. Linear-only, joint LS
and Kim are separate fits; never fix the linear-only coefficient when adding Q.

Outputs: coefficient_walkthrough_arrays.npz (actual small design/moments/scales,
small fitted coefficients, full example b/d/F and LS/Kim coefficients, held-out
Y and three predictions); coefficient_walkthrough_summary.json (configuration,
parent/raw/source hashes, units, software and audits); seven SVG/PNG pairs.
Copy k05-fit-*.svg and the summary as k05-fit-summary.json to the K05 static
directory. PNGs and complete arrays stay outside Git.

Q maps display unique unordered pairs for the main split, in inverse volts,
with signed f1/f2 axes. Gray means uncomputed. The 0.01 V^-1 logarithmic color
floor is display-only, not a significance threshold. The white line selects
the fixed target. No symmetric duplication or rate conversion is applied.
Only8/92 main-split and35/368 four-split Kim solutions pass the common-power
bound; failed cases remain explicitly labelled algebraic results. All LS
designs are full rank, with scaled conditions4.888–10.765. A numerical rank
check is not a test of probe calibration or stationary independent noise.

The validation producer remains a numerical parent of the eight-page walkthrough.
Its former standalone explanatory page has been removed; page07 defines NMSE locally.

## Preserved first-analysis producer

Use Python with NumPy, SciPy and Matplotlib. The actual versions used for the
displayed results are recorded in the figure provenance JSON. From the repo root:

```bash
python K_Diagnostics/K05_bispectral_transfer/analyze_experiment.py \
  --data /path/to/experiment-data \
  --output /path/to/derived-results

python -m unittest discover -s K_Diagnostics/K05_bispectral_transfer -p 'test_experiment.py' -v
```

`--data` is searched recursively for `SDS814X_HD_Binary_C{1,3}_{2,3,4,5}.bin`.
Duplicate or missing names, unsupported binary layouts, and inconsistent header
timing are errors. `--metadata` can select another metadata JSON for this capture
layout. Do not mark unknown values as zero or copy another experiment's values.

The output contains 11 SVG/PNG figures, complex bispectra and other arrays in
`spectral_arrays.npz`, and the provenance/header audit in `analysis_summary.json`.
File hashes identify inputs without storing machine-specific paths. Outputs may
be regenerated in the same derived-results directory; inputs are read only.

## Voltage reference and supplementary evidence

SIGLENT EN03A V4.0 p. 46 adds the header vertical offset. The supplied lab reader
`tool02_readbin.py` subtracts it and cites a DC calibration whose underlying
records were not supplied. The default reader therefore returns **record-centred
voltage fluctuations**, without selecting an absolute DC convention. Both candidate
DC means are recorded in the manifest. The two centred waveforms agree with the
supplied reader to round-off. This removes only a constant, not a gain, polarity,
delay or frequency-response error.

The post-experiment scope photo agrees with header sampling and scale settings;
its displayed flat waveform is not assumed to be one of the eight stored captures.
The data owner maps this dataset to the 19:12 entry (sheet `1014`, row 9),
which records 200 V and 2.814 A. These are context, not local plasma parameters
or inputs needed for the frequency axis. Neither source supplies a verified current
conversion, interchannel calibration or group velocity.

## Numerical choices

- PSD and coherence: 16,384 samples, periodic Hann, segment mean removed, no
  overlap, 610 segments/capture, final 5760 samples omitted; positive-exponent
  normalized Fourier coefficients. One-sided PSD uses mean-square window gain.
- Bicoherence: 2048 samples, same processing, 4882 segments, final 1664 omitted;
  compute `0 < f1 <= f2`, `f1+f2 <= 5 MHz`. The stored complex bispectrum uses
  `<X1 X2 conj(X3)>`. This restricted view is not a full inference pair basis.
- Sensitivity: capture 2 C1 also uses 1024 and 4096 samples. Figures use shared
  color scales; changing the segment length changes both resolution and averaging.
- Figures 8–10 share logarithmic colors for squared bicoherence, from `1e-4`
  to `1`. Colorbar ticks are actual `b²` values, spaced by factors of ten.
  Values below `1e-4`, including zero, use the darkest color; white denotes
  the uncomputed domain. The lower colorbar extension marks the display floor,
  not a significance threshold. No per-panel rescaling or upper saturation is
  used for these data. Only display copies are floored; saved statistics remain
  unchanged. Both channel maps use `plot_bicoherence_maps`; the segment-length
  comparison uses `plot_bicoherence_sensitivity`, also callable on saved arrays.
- The illustrative triad is selected after inspecting capture 2, with `f1 >=
  0.1 MHz`. Its 63 circular target-sequence shifts use a fixed seed. This is an
  exploratory comparison, not a multiple-testing-corrected significance result.
- A fixed coherence mask of 0.5 controls phase display only. No trace is shifted
  to maximize correlation, no arbitrary normalizing gain is imposed, and no
  inferred group velocity is substituted for a missing calibration.
- Figure 7 shows the full 0–50 MHz band alongside a 0–5 MHz detail view,
  both from the same stored frequency arrays. Coherence retains all bins;
  the phase mask does not limit the frequency range of the calculation.

Generated documentation assets are the SVGs copied into
`docs/source/_static/K_Diagnostics/`, plus `k05-experiment-summary.json`.
After regenerating, copy those same SVG names and rename the run manifest to
that documentation filename, inspect the plots, then rebuild Sphinx. PNGs and
the full arrays stay in the external analysis output directory.

The sixth page reaches measured spectral relations. Physical growth and transfer
require the joint coefficient fit, signed-frequency pair accounting, conditioning,
held-out prediction, appropriate Kim assumptions and calibrated measurement/phase
response. Potential/energy and per-second rates additionally require the plasma
response and group velocity. Those quantities are not claimed by these scripts.

## Leave-one-capture-out model validation producer

```bash
OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 \
python K_Diagnostics/K05_bispectral_transfer/validate_experiment.py \
  --data /path/to/experiment-data \
  --output /path/to/model-validation

python -m unittest discover -s K_Diagnostics/K05_bispectral_transfer -p 'test_*.py' -v
```

Choose a separate derived-output folder to retain the first analysis. The reader
checks and hashes the same eight files; no calibrated current or propagation
parameters are required. `--metadata` accepts the same acquisition JSON as the
first analysis. Coefficients are recomputed from the raw records because the
averaged spectra do not retain the segment-level regression inputs.

The fixed main configuration is N=2048, target frequencies 0.5–5 MHz and
quadratic inputs with 0<|f|<=5 MHz. Signed pairs include sums and differences;
keep only b<=c, b+c=target, with neither input zero. Opposite-frequency
coefficients use complex conjugation; grouped products receive no extra factor
of two. Linear and quadratic models have no intercept. Full complex least
squares implicitly retains all fourth-order cross terms. The numerical solver
uses training-column RMS scaling and SVD (`rcond=1e-10`), then restores the
physical voltage units: L dimensionless, Q in inverse volts. Scaling does not
equalize channel gains. A rank deficit or scaled condition number >1e8 flags
coefficient identifiability; predictions remain available with that flag.

Each of captures 2–5 is held out in turn, with its full partner-channel record.
No test rows enter the training scales, coefficient fit, or feature selection.
Zero training columns are assigned zero coefficients and a rank-deficit flag.
Nonfinite training values are errors. Test target power zero gives undefined
NMSE; zero linear error gives undefined relative improvement. These are not
silently replaced by small positive denominators. Negative improvement remains
visible. Four-fold ranges describe variation across these records, not confidence
intervals. Prediction direction C1 to C3 is a modelling choice, not an inferred
physical propagation direction.

Five configurations are fixed before evaluation: (N, input MHz) = (2048,5),
(1024,5), (4096,5), (2048,3), (2048,8). Sensitivity plots compare their exact
common target bins (the 1024-point grid); there is no interpolation or selection
of the setting with the best test result. Cross-configuration figures report
dimensionless errors and normalized aggregate quadratic power, not raw Q-bin
comparisons. The illustrative trace is always held-out capture 2, the closest
bin to 2 MHz, and its first 150 segments.

Outputs are `validation_summary.json`, `validation_arrays.npz`, and nine
`k05-validation-*.svg`/`.png` figures. The NPZ names use a configuration prefix
such as `n2048_b5__`. Arrays contain four folds in capture order 2,3,4,5, followed
by target frequency. The last dimension of `coefficients` contains L then Q;
`pair_count` and `pair_bins` specify the non-padding pairs. Zero pair indices
and NaN coefficient entries beyond that count are padding. `scales`, `singular`,
`rank`, `condition`, and `reliable` preserve solver diagnostics.

`mse`, `nmse`, `prediction_power`, and residual metrics store linear then joint
models. `train_nmse` is kept separate from held-out `nmse`. `budget` stores
<|A|²>, 2Re<A*B>, <|B|²> in V², with A=LX and B=sum(QjZj);
`pair_cross` contains 2Re<A*QjZj>. Normalize by `target_power` for the figures.
The B-squared term includes cross terms between different pairs. These signed
cross contributions are finite-step prediction-power terms, not plasma energy
transfer rates. The example arrays retain complex measured/predicted coefficients
and segment midpoint times. Undefined JSON numbers are null; NPZ keeps NaN/Inf.

For documentation, copy the nine validation SVGs into the K05 static-assets
directory and copy the run summary as `k05-validation-summary.json`. Replotting
from the saved arrays uses `plot_results(results, fs, output)`, where `results`
maps each configuration ID to its NPZ fields with the prefix removed. The
summary records input and analysis-source hashes, versions, fold membership,
and all preset choices. Input hashes are checked again when the run finishes.

This is predictive least squares with noisy voltage predictors. It does not
apply Kim's stationary correction, identify a causal coupling, or turn measured
volts into a calibrated potential, growth rate, or energy transfer.

## Preserved dense high-frequency validation producer

```bash
OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 \
python K_Diagnostics/K05_bispectral_transfer/validate_high_frequency.py \
  --data /path/to/experiment-data \
  --output /path/to/high-frequency-validation
```

This fixed extension fits captures 3, 4, 5 and tests capture 2 only. It uses
N=2048, the same mean removal, periodic Hann window and positive-exponent/N
coefficients as the original validation. Every native target bin from 5 to
20 MHz is evaluated: 307 bins at 100 MS/s, with actual endpoints 5.029296875
and 19.970703125 MHz. All unique nonzero signed input pairs with both absolute
frequencies at most 20 MHz are retained; no circular/modulo-N matching is used.
Difference pairs involving frequencies above 20 MHz are outside this model.
The input limit and single held-out capture are fixed before scoring.

Only one two-panel figure is generated, `k05-validation-high-frequency-spectra`
in SVG/PNG. It uses the original Figure 2 PSD factor 2N/(fs U), U=3/8, for
measured, predicted and residual coefficient powers. Axis/legend symbols are
f, S_YY^+, S_(Yhat_m Yhat_m)^+ and S_(epsilon_m epsilon_m)^+, where epsilon_m
= Y-Yhat_m, m=0 (linear) or 1 (joint). The page links these to the
validation-model and PSD-normalization equations using semantic references,
so the displayed numbers follow the current registry. No other existing plots are redrawn.

`high_frequency_arrays.npz` uses the same fields as an individual original
configuration, without its configuration-name prefix. Its first axis has
one fold, explicitly identified by `heldout_captures=[2]`. It retains every
coefficient, scale, singular value, pair, error and model-power term; negative
improvements remain in the arrays and residual curves. The JSON summary records
the input hashes, exact frequency grid, fold, software and numerical source
hashes. Source snapshots are retained beside the outputs. Copy the SVG into
the K05 static-assets folder, and the summary as
`k05-validation-high-frequency-summary.json`.

This extension does not establish consistency across four held-out captures
at high frequency. Because the input basis also expands relative to Figure 2,
its result cannot isolate the effect of target frequency alone. Error reduction
is not the quadratic fraction of plasma energy; the two fits have different
linear coefficients and the complete prediction-power decomposition contains
a signed cross term.

## Preserved slow-sweep analysis and response checks

The data owner confirmed C1 is the left fixed probe and C3 the right probe,
3.7 mm apart azimuthally and 5.5 mm downstream. This identifies positions, not
propagation. The 1 kohm sampling resistor supplies a nominal 0.001 A/V scale,
not a MHz frequency-response calibration.

`yokogawa_wdf.py` reads the documented single-history DL350 Trace layout
(IM DL350-01EN Appendix 9). Unsupported histories, scales and illegal samples
are checked by the reader. CH3_2 is supply voltage Vs; CH4_2 is resistor voltage uR.
The slow bias is a 100 V **power supply**, while the fast bias is a 40.5 V battery.
Use Vp=Vs−100+uR and electron-positive net current I=−uR/1000.

The primary R24 analysis is `analyze_probe_sweep.py` with `probe_sweep_config.json`:

1. Select the first upward ramp from the first Vs>5 V to before the first Vs>349 V.
2. Group by imposed **Vs** in 1 V bins, retain bins with at least 8 samples,
   and take arithmetic means of both recorded channels. Convert these means
   to mean Vp and I. Do not remove samples solely for large current.
3. Find the single negative-to-positive mean-current crossing above −40 V.
   Fit signed ion background aVp+b over [−80,−50] V.
4. Interpolate the mean curve to a 0.5 V grid [−80,60) V. A cubic
   Savitzky–Golay derivative uses nominal spans 5,7,9,11,15,19,23 V.
   Each odd point-count window is round(span/0.5), incremented if even.
   Find the derivative maximum in (Vf+5,45) V; median peak position for spans
   at least 7 V is a **candidate**, not calibrated plasma potential.
5. Fit ln(Ie/1 mA) on unsmoothed mean bins in [Vf+2,Vpl_candidate−5] V,
   with equal weight per bin. Reject nonpositive Ie and nonpositive slope;
   report Te_eV=1/slope. No clipping or log-absolute-value workaround.
6. Retain all 72 sensitivity choices: lower margins 0,2,5 V × upper 3,5,8 V ×
   ion intervals [−90,−60], [−80,−50], [−70,−40], [−90,−40] V × linear/constant.
   Bin widths 0.5/1/2 V are compared at the same physical central fit bounds.

```bash
python K_Diagnostics/K05_bispectral_transfer/analyze_probe_sweep.py \
  --data /path/to/supplementary_scans \
  --output /path/to/separate_mean_output \
  --config K_Diagnostics/K05_bispectral_transfer/probe_sweep_config.json
python -m unittest discover -s K_Diagnostics/K05_bispectral_transfer -p test_probe_sweep.py -v
```

Record 0015 is the fixed worked example. It reproduces the independently
supplied `SingleProbe_AxialGroups_20261019` student's binned mean characteristic:
Vf=−24.145758 V, candidate=4.5 V, slope=0.1090643203 /V, Te=9.1689014105 eV,
26 selected bins and R²=0.992803. All 72 choices give 8.646744–10.151490 eV;
this is sensitivity, not a confidence interval or a calibrated bulk temperature.
015–018 yield 9.168901, 9.054662, 9.064749, 8.966188 eV (mean 9.063625 eV).
The earlier 008–011 set yields 8.766508, 8.962420, 8.639152, 8.673730 eV.
Keep the sets separate: the experimenter raised an unresolved quality concern
about the earlier set. Slow 50 kHz scans do not measure MHz temperature fluctuations.

The original `analyze_probe_response.py` and `probe_response_config.json` are
preserved as the **median comparison**, not the main temperature method:
instantaneous Vp bins of 2 V, medians, [−90,−70] V background,
central electron interval [Vf−5,Vf+10]. For 0015 this gives 6.726178 eV.
The mean curve with that relative fit rule gives 9.138003 eV; the old median
curve with the present absolute intervals gives 6.805970 eV. A source-bin
median with those same absolute intervals gives 7.056104 eV.
Current-unit conversion and the two WDF readers agree; curve reduction is the
dominant cause of this example's 6-to-9 difference.

New outputs are separate from all historical outputs: `probe_sweep_summary.json`,
`probe_sweep_arrays.npz` and seven SVG/PNG pairs generated by `plot_probe_sweep.py`.
The report records raw/config/source hashes, all fit bounds and sensitivity
cases. NPZ keys use r8_… through r18_…; `bins` columns are Vp[V], I[A], Vs[V],
uR[V], count. The fixed illustrative bin 75≤Vs<76 V retains its raw samples.
Display-only 2 ms blocks use means and 16–84% spreads, never confidence bands.
Preserve the output with its configuration. Original WDF, student archive and
historical median/fast-spectrum outputs remain read-only.

The fast load-line illustration now uses the **0015 mean** characteristic,
with assumed cathode/chamber offsets −20,0,+20 V. Corresponding Vp values
are −60.0745, −40.1388, −20.6795 V; fitted Ie/Ii ratios 0.0211,0.0655,1.5288.
The unchanged R–C illustration comes from the legacy response configuration,
using 20/100/200 pF. These are assumed scenarios, not measured calibration;
no inverse filter is applied to fast data. Physical growth/transfer inference
and Kim correction are not part of this temperature workflow.

### Probe geometry and circuit drawings

`draw_probe_schematics.py` generates the English/Chinese layout and circuit
SVG/PNG assets without reading or fitting the experimental records:

```bash
python K_Diagnostics/K05_bispectral_transfer/draw_probe_schematics.py \
  --output /path/to/probe_schematics
```

The Chinese drawings require Noto Sans CJK; SVG glyphs are embedded as paths.
Copy the four SVGs to `docs/source/_static/K_Diagnostics/`. Geometry follows the
data owner's layout sketch: C1 left/fixed, C3 right, azimuthal separation 3.7 mm,
both 5.5 mm downstream of the exit. The drawings are not to scale and do not
specify wave propagation. C1/C3 are fast channels; CH3_2/CH4_2 are slow channels.

The owner clarified on 2026-10-30 that the slow circuit's 100 V bias comes from
a power supply, whereas the fast circuit uses a 40.5 V rechargeable battery.
The preserved calculation input key `sweep_battery_v` is a historical name for
the 100 V **bias supply voltage**; its numerical value, equations and archived
calculation hashes remain unchanged. In the page, V_b means bias voltage.
The voltage-sense polarity is the explicit page assumption, not an independent
calibration. A measurement branch does not imply an isolated input; the fast
cathode-negative reference is not silently grounded to the chamber.

## Stationary moments and held-out power-budget producer

Run from the repository root (choose a new output directory):

```bash
python K_Diagnostics/K05_bispectral_transfer/analyze_transfer_budget.py --data /path/to/experimental_data --metadata K_Diagnostics/K05_bispectral_transfer/experiment_z5p5_a3p7.json --output /path/to/new_budget_output
python K_Diagnostics/K05_bispectral_transfer/plot_transfer_budget.py --output /path/to/new_budget_output
python -m unittest discover -s K_Diagnostics/K05_bispectral_transfer -p test_transfer_budget.py -v
```

The four whole-capture splits and 2048-point/5 MHz configuration match page07. Full measured fourth moments enter the stationary Kim estimator; RMS scaling and SVD use training rows only. No response correction, gain equalization, group velocity, or Kim-derived density calibration is imposed. A 1e-6 relative tolerance on Pstar <= min(PX,PY) is numerical, not statistical. Save all invalid-bound results instead of clipping or selecting favorable bins. NPZ includes physical-unit coefficients, product pairs, training moments/scales, diagnostic flags, test budgets and increments; JSON and plot provenance include input/source hashes. A failed bound is not repaired by choosing a group velocity.

Current example: 35/368 cases meet the necessary common-power bound; all product matrices are full rank. The complete measured-signal budget includes quadratic self power and the prediction/residual cross term. Kim's common model power is distinct from measured held-out power. Terms in volts squared are not calibrated plasma energy, and positive/negative terms do not alone establish a cascade.

Page08 R25 uses unchanged mean-sweep numerical arrays, with new full-range I–V and layout figures. Historical R24 numerical hashes describe the source at calculation time; plotting changes have a separate replot_provenance.json. Repeat scan labels1–4 map to10140015–10140018.WDF; earlier labels1–4 map to10140008–10140011.WDF. C3 is movable but stationary in these captures. The detailed illustrative R–C response is collapsed; capacitance is parasitic/input capacitance, not an added circuit component.


## Preserved narrow-band comparison producer

This producer is retained for reproducibility and the preserved PSD input.
Its former explanatory page is no longer in the public eight-page sequence.

Run the earlier spectra, validation and budget analyses first, or use their preserved
spectral_arrays.npz, validation_arrays.npz and transfer_arrays.npz outputs:

```bash
python K_Diagnostics/K05_bispectral_transfer/analyze_paper_comparison.py \
  --budget /path/to/budget/transfer_arrays.npz \
  --validation /path/to/validation/validation_arrays.npz \
  --spectra /path/to/spectra/spectral_arrays.npz \
  --config K_Diagnostics/K05_bispectral_transfer/paper_comparison_config.json \
  --output /path/to/new_comparison
python K_Diagnostics/K05_bispectral_transfer/plot_paper_comparison.py \
  --output /path/to/new_comparison
python -m unittest discover -s K_Diagnostics/K05_bispectral_transfer -p test_paper_comparison.py -v
```

NumPy, SciPy and Matplotlib are required. Use a new, empty output directory.
Copy the two k05-comparison-figure*.svg files to the K05 static directory and
comparison_summary.json as k05-comparison-summary.json when updating the example.
Changing parameters requires a fresh numerical output and matching documentation.

The script does not fit or normalize the raw captures again. It asserts matching
target grids and saved LS coefficients, obtains held-out PX from saved PY/(PY/PX),
and converts the exact quadratic cross contribution stored in the budget arrays.
For the half-power convention of Brown Eq6,
T_V_half = vg * PX * t_app / (2*dy); the full squared-amplitude cross contribution
is twice this value. It is in V^2/s, not calibrated plasma energy density.
The line/magnitude averages use all four splits; ranges are not confidence limits.
Q maps show mean magnitudes of symmetric ordered coefficients: Q_unique/2 off
diagonal, Q_unique on the diagonal. Negative targets are conjugate reconstructions.
Gray marks excluded targets/inputs, not zero coefficients. The 1e-3 V^-1 color
floor is display-only. No high-frequency single-fold coefficients are mixed in.

The explicitly provisional kinetic scenario uses Te=9.168901410487 eV from
page08, reported |Br|=39.48 G and |Baxial|=80.34 G, assumed n0=1e17 m^-3,
VD=+100 km/s, Xe+ mass131.293u, k_parallel*lambda_De=0.03, k_perp=ky and
zero ion Doppler shift. Parallel is aligned with the total local field.
Model +y is assumed to point C1 to C3; it is not a propagation measurement.
This is a magnetized Maxwellian-electron/cold-ion calculation based on the
Gordeev series, checked against Cavalier thesis Eqs2.7–2.9 and Brown Eq7.
It is not a fit of the background to the measured peaks. Te's kinetic meaning
is energy in joules after converting the eV input; do not reuse Kelvin directly.

Follow one positive-frequency root with continuation, require residual<=1e-9,
and save the full complex frequency. vgy = Re[-E_ky/E_omega] holds k_parallel
fixed. Fourier convention exp(+i omega t)/N is consistent with exp(-i omega t)
waves and positive Im(omega) temporal growth. The monotone branch maps to
measured frequencies without extrapolation; nonmonotone configurations fail
explicitly rather than choosing between multiple roots silently.

Outputs: comparison_arrays.npz (branch, derivative audits, 4 split Q maps,
apparent rates, absolute/normalized half-power contributions and spectra),
comparison_summary.json (configuration, hashes, units, assumptions, checks),
two SVG/PNG plots, and plot_provenance.json. Parent NPZ and all original
records remain unchanged. The fit band is0.537–4.980 MHz, inputs<=5 MHz,
while the Welch spectrum retains up to50 MHz. Rates and Q maps retain failed
Kim-bound cases; only35/368 pass. Open circles flag frequencies with at least
one failing split. No claim of identified EDI growth or inverse cascade is made.


### Figure 2 with reference axes (R29)

Replot only Figure 2 from the unchanged saved arrays into a separate directory:

```bash
python K_Diagnostics/K05_bispectral_transfer/plot_paper_comparison.py \
  --output /path/to/comparison --figure 2 --destination /path/to/new_figure2
```

The three panels follow Brown Figure2's axis limits and ticks: (a) ky=0–10000
m^-1 and f=0–5e7 Hz; (b) log f=1e5–1e8 Hz, approximate unlabelled vertical
endpoints0.2–4000; (c) f=0–3.5e7 Hz, left rate−5e4–3e5 s^-1, right
rate−5e5–3e6 s^-1. Preserve correct quantities: (a) explicitly labels
omega_k/(2*pi) for Hz, and (b) converts voltage PSD by1e12 to microvolt^2/Hz,
not to an unknown dimensionless-amplitude PSD. No peak matching or per-channel
normalization. Axes clip values outside their ranges; unsupported frequency
intervals remain blank. Figure3 and numerical arrays are not regenerated by
the figure2-only command. plot_provenance.json records these choices and hashes.


### R30 reading audit

Seven paired equation boxes, a kinetic-response derivation and the original-paper
synthesis extend the explanation without changing saved coefficients, spectra,
model parameters, source data or generated analysis plots. Page11 distinguishes
the source-paper findings from the conditional C1/C3 counterparts. Source figure
images come from Brown2023 PDF page2 image26 and page5 image124; attribution is
in the page. The reference omega_k/Hz plotting convention remains unresolved
from its label alone. Matching axes does not establish a measured speed ratio.


## Page 08: coefficients, measured changes and conditional rates (R40)

Run `analyze_rate_walkthrough.py --data RAW --budget BUDGET_DIR
--comparison COMPARISON_DIR --validation VALIDATION_DIR --output NEW_DIR`.
The three parent directories contain the previously audited transfer, kinetic
comparison and validation products. The output directory must be empty.

This script verifies all eight raw hashes, regenerates the same N=2048 Fourier
coefficients, and recomputes test-set pair moments and exact power balances for
four holdouts and 92 targets. Training-only coefficients and phases are reused,
not refitted. Pair products are unordered and include signed difference pairs.
The complete finite-step square and residual cross term are retained. Its
`rate_walkthrough_arrays.npz` stores all per-pair moments, signed increments,
powers, rates and group velocity. JSON records configuration, raw/parent/source
hashes, versions, fixed-example values and numerical identity errors.

Rates reuse the explicit estimated kinetic branch; they are in the measured
voltage convention, not calibrated plasma-energy transfer. The page gives
T^(1/2) matching the printed Eq.(6) expression and explicitly uses 2T^(1/2)
for a full first-order mean-square change. No new Kim validity is inferred.

`plot_reading_schematics.py --output NEW_SCHEMATIC_DIR` generates two independent
dimensionless teaching diagrams. Its analytic functions are reproduced in the
paper-reading page; it takes no paper image or data as input. These diagrams
must not be described as reproductions of measured reference curves.


## Page 08 expanded panel comparison (R43)

```bash
OPENBLAS_NUM_THREADS=2 python K_Diagnostics/K05_bispectral_transfer/analyze_extended_comparison.py \
  --data /path/to/raw-captures --output /path/to/new-extended-results
python K_Diagnostics/K05_bispectral_transfer/plot_extended_comparison.py \
  --extended /path/to/new-extended-results \
  --comparison /path/to/z5p5_a3p7_paper_comparison \
  --output /path/to/new-comparison-plots
```

The new output directory must be empty and outside raw inputs. The optional
`--metadata` argument defaults to `experiment_z5p5_a3p7.json`. The common basis
uses all 399 native target bins from 0.537109375 to 19.970703125 MHz, N=2048,
periodic Hann, segment demean, no overlap, positive-exponent Fourier/N,
and unique signed nonzero pairs with both absolute frequencies <=19.970703125
MHz. Each complete capture is held out in turn. Scaling, phase and fitting
use training rows only; signed moments and errors use held-out rows.

QR of the scaled augmented [D,y] matrix preserves the complete Gram matrix,
including the y residual. The existing SVD least-squares and Kim solvers operate
on the reduced rows; common moment normalization is restored. It is not a
normal-equation inversion. `test_extended_comparison.py` checks equivalence,
independent noise, rank degeneration, exact budgets and holdout isolation.
The 307 capture-2 high-frequency LS fits reproduce the earlier saved outputs.

`extended_arrays.npz` contains coefficient/pair grids, test moments, training
scales, phases, powers, normalized errors, rank/condition and Kim flags.
`extended_summary.json` records raw/source hashes, config, versions, all four
folds' band reductions and exact-identity checks. Checkpoints are intermediate
products, not completed results. The 5 MHz parent outputs and raw files are
unchanged. All 1596 joint fits are full rank, max scaled condition68.55;
199/399 targets pass Kim's necessary bound in every fold. High-frequency
quadratic error reduction is7.84–7.96%, not a physical transfer fraction.

The plotting script produces ten SVG/PNG figures and a hash manifest. Five
pair source-derived reference redraws with independent experimental results;
four offer local scales; one displays reliability. Source curves are approximate
published-image readings, and the Q heat map is image-derived, not raw author
data or an independent schematic. No original figure image is included.
See `reference_digitization/README.md` for attribution and the unresolved
public-reuse/license issue; this material is not represented as licensed under
the repository software license. Page12 independent schematics remain separate.

Broad-band rates assume +2150 m/s from C1 to C3 across3.7 mm throughout;
the saved kinetic branch only covers0.179–5.592 MHz and is never extrapolated.
The local t_f panels require no group velocity. All Kim outputs are retained,
with failed bounds explicitly flagged; no physical EDI/cascade conclusion is
asserted. Target/input limits above20 MHz remain excluded even for difference
pairs. The earlier5 MHz basis remains in saved parent results; its coefficients
and rates must not be spliced with page08 arrays.


## Page 08 moving-ion scenario (R44, 2026-11-16)

The 20 MHz coefficient fits and original captures are unchanged. Reuse them:

```bash
python K_Diagnostics/K05_bispectral_transfer/analyze_physical_scenario.py \
  --extended /path/to/z5p5_a3p7_extended_r43 --output /path/to/new-physical-results
python K_Diagnostics/K05_bispectral_transfer/plot_physical_comparison.py \
  --extended /path/to/z5p5_a3p7_extended_r43 \
  --comparison /path/to/z5p5_a3p7_paper_comparison \
  --physical /path/to/new-physical-results --output /path/to/new-figures
```

The comparison parent supplies only preserved PSD arrays; its old kinetic roots
are not used. Config `physical_scenario_config.json` fixes Te=9.1689 eV,
n=2.2e16 m^-3, cold Xe+, ion energy100 eV, parallel wavelength1 cm. An explicitly
estimated1 cm acceleration length gives E=10 kV/m and azimuthal ExB drift492.7
km/s using the full magnetic vector. Length0.5/2 cm and perpendicular-plane
wavevector tilt0/30 degrees are sensitivity cases around the unmeasured15 degree
closure. The same full dispersion includes the axial-ion Doppler denominator.

The selected positive ion-frame root covers1.349–26.607 MHz on ky10–100000 m^-1.
Its true azimuthal group velocity fixes the other wavevector components; it is
not the total derivative along ks=tan(theta)*ky. No frequency extrapolation;
382/399 targets support rates, while all399 retain across-gap coefficients. The
opposite ion-frame branch is retained in saved outputs and is never spliced in to fill gaps.
Root residuals, harmonic convergence, derivative checks, hashes and all scenario
configs are in physical_summary.json / physical_arrays.npz. Tests independently
resolve nearby roots, check energy/geometry, unit transforms and all-fold masking.

Kim appears only when all four fits are identifiable and pass the necessary
common-power bound. Remove entire target diagonals from its Q map, with conjugate
partners; never average only passing folds. Raw failed values remain in R43
arrays; only the common-power diagnostic shows why result intervals are missing.

Nominal1 kohm conversion applies equally to both probes: I=aV, L_I=L, Q_I=Q/a,
P_I=a^2P, T_I=a^2T; figures use mA units. No DC/RMS/peak normalization or MHz
response calibration is invented. Frequencies and growth-rate units are common
with the source; source Q/T absolute normalization remains unresolved.
