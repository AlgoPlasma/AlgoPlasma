<!-- K05 contribution history (Git author dates; edit times include timezone).
2026-10-28 16:37 +08:00 | Yinjian Zhao | git 288e21275be3
2026-10-29 13:23 +08:00 | Yinjian Zhao | git 5604a5bb51cc
2026-10-30 08:23 +08:00 | Yinjian Zhao | git 3f6fce651490
2026-10-30 11:25 +08:00 | Yinjian Zhao | git 303832d65c08
2026-11-02 13:56 +08:00 | Yinjian Zhao | git 1a1e390d6d38
2026-11-03 09:08 +08:00 | Yinjian Zhao | git 52f1bfb880ab
2026-11-03 13:13 +08:00 | Yinjian Zhao | git c78fafbf8e0b
2026-11-03 18:50 +08:00 | Yinjian Zhao | git 950991764e7f
2026-11-06 08:58 +08:00 | Yinjian Zhao | git 8ea987892b7b
2026-11-10 10:13 +08:00 | Yinjian Zhao | git b760bab91ff8
2026-11-10 11:18 +08:00 | Yinjian Zhao | git 2960c1dc97d1
2026-11-12 10:09 +08:00 | Yinjian Zhao | git ca62b318155e
2026-11-13 13:10 +08:00 | Yinjian Zhao | git dfd0f9af0503
2026-11-16 12:10 +08:00 | Yinjian Zhao | git 14e5fad1530d
2026-11-17 11:41 +08:00 | Yinjian Zhao | git f851bf1cd4a0
2026-11-17 13:54 +08:00 | Yinjian Zhao | git 9085032adbf6
2026-11-18 16:11 +08:00 | Yinjian Zhao | edit (Codex-assisted)
-->

# Reproduce the K05 probe example

Run from the repository root. The [script guide](../../docs/source/rst_files/K_Diagnostics/K05_scripts.rst)
connects programs to pages01–08 and documents the main array/function contracts.
Keep this module together, including its JSON configuration and reference-digitization files.

## Environment and inputs

```bash
python -m pip install -r K_Diagnostics/K05_bispectral_transfer/requirements.txt
python -m unittest discover -s K_Diagnostics/K05_bispectral_transfer -p 'test_*.py' -v
```

NumPy, SciPy and Matplotlib run the analyses; Sphinx and Doxygen are only needed
for the website. Use `--help` on an executable to inspect its arguments.
The fixed example expects eight external SIGLENT V4 files:
`SDS814X_HD_Binary_C1_2.bin` through `C1_5.bin` and the corresponding C3 files.
There must be exactly one match per channel/capture under `--data`.
The single-channel, unzoomed reader checks format, scales, payload length,
probe factor 1 and acquisition timing. Unsupported modes fail explicitly.

`experiment_z5p5_a3p7.json` records acquisition facts and unknown calibrations.
The four pairs are synchronous, at one condition, with 3.7 mm azimuthal separation.
The example uses 100 MS/s, 10,000,000 samples per channel. Raw captures and full
NPZ results are external inputs, not repository files. Metadata does not change
fixed capture IDs, segment sizes or frequency ranges in a producer.

Always choose a new analysis output folder outside the raw-data tree. Plotters
can overwrite existing figures; use a separate destination to preserve an older
rendering. Do not alter the input files or an earlier run's provenance.

## Dependency order for the current pages

Replace `/path/to/...` with real locations. The following produces statistics,
parent fits, the worked coefficient example, spectra and the page08 comparison.

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

The spectrum comparison parent supplies its 16384-point PSD to the last plotter;
its older 5 MHz coefficients and kinetic roots do not replace the expanded fit
or selected moving-ion scenario. The page07 and page08 coefficient bases differ;
do not splice their coefficients or statistical averages.

## Numerical conventions and saved arrays

All fast-record producers use voltage from `siglent_v4.py`. By default each
record mean is removed; an unverified DC offset sign is not inferred from spectra.
The main grid has N=2048, segment demeaning, periodic Hann and no overlap.
Forward Fourier coefficients use a positive exponent divided by N; negative
frequencies are conjugates. The cross moment is G = mean(Y conj(X)).
The coefficient is in V, its mean square in V², and B = mean(X1 X2 conj(X3))
in V³. PSD is one-sided and normalized by the Hann mean square, in V²/Hz.
The first-order transfer convention and its factor of two are explained on page08.

| Producer / output | Array meaning |
| --- | --- |
| `analyze_spectral_walkthrough.py`: `walkthrough_arrays.npz`, `walkthrough_summary.json` | `frequency_hz` contains all 1025 nonnegative bins. `g{2,3,4,5}_P_c{1,3}`, `..._psd_c{1,3}`, `..._G`, `..._coherence` are frequency arrays. `..._B_c{1,3}` / `..._b2_c{1,3}` use input-frequency rows and columns. `g2_X_band`, `g2_Y_band` have segment and frequency axes through 5 MHz. |
| `validate_experiment.py`: `validation_arrays.npz`, `validation_summary.json` | Each configuration stores target frequencies, signed pair lists, coefficients, scales, ranks, conditions and held-out metrics for four complete-record splits. Configuration labels distinguish N and input bandwidth. |
| `analyze_transfer_budget.py`: `transfer_arrays.npz`, `transfer_summary.json` | Kim coefficients/common power, identification and admissibility flags, moments and complete held-out power contributions on the main 5 MHz grid. |
| `analyze_coefficient_walkthrough.py`: `coefficient_walkthrough_arrays.npz`, `coefficient_walkthrough_summary.json` | Saved matrices, two-pair and full-pair calculations at the fixed worked frequency, and checks against the two parent runs. |
| `analyze_experiment.py`: `spectral_arrays.npz`, `analysis_summary.json` | Original 16384-point Welch PSD/coherence grid and selected bispectral statistics, retained as the page08 spectrum parent. |
| `analyze_paper_comparison.py`: `comparison_arrays.npz`, `comparison_summary.json` | Packages the older comparison including that PSD; configuration and derived scales remain explicit. |
| `analyze_extended_comparison.py`: `extended_arrays.npz`, `extended_summary.json` | Common 20 MHz-basis coefficients, padded pair arrays, powers, moments, errors, ranks, conditioning and Kim flags, with fold as the first axis and target as the second. |
| `analyze_physical_scenario.py`: `physical_arrays.npz`, `physical_summary.json` | Branch roots, partial group velocities, supported-target mask, Kim display mask, nominal-current conversion and conditional rates. |
| `plot_physical_comparison.py`: SVG/PNG and `plot_manifest.json` | Paired figure panels and detail views derived from saved arrays; hashes identify all numerical and digitized inputs. |

The page06 example is fixed before inspection: capture2, first segment, nearest
bin to 2 MHz (bin41, 2.001953125 MHz). At N=2048 each capture supplies 4882 full
segments; 1664 samples remain unused. Figure3 displays the first segment through
50 MHz. Stored B covers 0<f1<=f2 and f1+f2<=5 MHz; NaN marks the uncomputed
triangle. This is a display domain, not the full regression input basis.
The b-vector in the coefficient normal equations uses the conjugate of B.

The validation configurations are (N,input MHz) = (2048,5), (1024,5), (4096,5),
(2048,3), (2048,8). Targets remain 0.5–5 MHz. Input products include unique
nonzero signed pairs b<=c, b+c=target. Each fold excludes one entire capture
from training-column RMS scales and coefficients. The complex solve has no
intercept, uses SVD with rcond=1e-10, and flags deficient rank or condition>1e8.
Undefined metrics remain marked; a four-fold range is not a confidence interval.

Page07 trains on captures3/4/5 and tests capture2 in its worked example; its two
illustrative pairs are (10,31) and (-10,51), fixed before inspecting coefficient
magnitude. Full bin41 fits contain 81 unique pairs. The script checks parent
raw hashes, grids, saved training moments and an independent worked refit.

Page08 refits all 399 targets from 0.537 to 19.971 MHz with one common 20 MHz
input basis. QR compression of the augmented [D,y] matrix preserves the target
residual power as well as inner products; tests compare it with uncompressed
fits. All four folds must pass identification and Kim's necessary common-power
bound to display a target's Kim curve. Failed points are blank, not zero.
The full power identity retains quadratic squares and residual cross terms.

## Physical inputs and reference plots

`physical_scenario_config.json` separates reported temperature/field inputs from
assumptions: Te=9.1689 eV, n=2.2e16 m^-3, cold Xe+, ion energy100 eV, parallel
wavelength1 cm, effective acceleration length1 cm and a 15-degree tilt in the
plane perpendicular to the field. The mean axial electric field is an estimate.
Ion Doppler shift enters the response before root solving. The azimuthal group
velocity is a partial derivative holding other wavevector components fixed,
not the total slope along the oblique plotting path. Mapping to target frequency
never extrapolates outside the computed branch.

The solver also saves optional length/angle checks for local diagnosis. The
public page uses the selected single scenario. Relative channel response,
propagation direction and mode identification remain physical interpretation
conditions; a successful solve does not supply those measurements.

The nominal 1 kΩ conversion is used consistently for the displayed current,
coefficient and transfer units. It is not a calibrated MHz transimpedance.
Reference panels use attributed image-derived points under
`reference_digitization/`; retain its provenance and input files. They are not
the authors' original data. Unknown source normalization must not be invented
merely to make plotted heights comparable.

## Publishing reproducible figures

Keep full arrays, raw data, run logs and optional output figures outside Git.
Copy only assets used by the maintained Sphinx pages. The retained compact
summaries document the current page06, page07 and page08 figures; their names
and purposes are listed in [DATA_FILES.md](DATA_FILES.md). Do not overwrite an
old summary with new source hashes unless the corresponding analysis was rerun.

Page06 publishes `k05-walkthrough-*.svg` and its compact summary; page07 publishes
`k05-fit-*.svg` and its compact summary. Page08 uses selected `k05-compare-*.svg`
from the final plotter and compact extended/physical summaries. An unreferenced
optional figure does not need to be copied into the website's static directory.

## Optional producers and maintenance

`validate_high_frequency.py` retains a single-holdout dense 5–20 MHz check.
`analyze_rate_walkthrough.py` and `plot_transfer_budget.py` retain narrower-band
worked plots. These do not replace the current page08 four-fold calculation.
`plot_paper_comparison.py` and `plot_extended_comparison.py` render older parent
results. Their CLI help describes required result folders.

`analyze_probe_sweep.py`, `analyze_probe_response.py` and `yokogawa_wdf.py` handle
separate slow I–V measurements and response scenarios. Use their explicit JSON
configuration; these do not infer a slow-sweep temperature from fast spectra.
`plot_probe_sweep.py` is imported by the sweep producer rather than run directly.
`draw_probe_schematics.py` produces English-labelled geometry/circuit illustrations for both page languages.
`plot_reading_schematics.py` produces analytical teaching illustrations, not data.
Optional tools and their tests remain available even when no optional figures
are published in the current pages.

Use [EQUATIONS.md](EQUATIONS.md) to maintain bilingual semantic equation links.
The HTML source, analysis inputs and figure manifests are distinct deliverables;
rebuilding Sphinx does not rerun the experiment analysis.
