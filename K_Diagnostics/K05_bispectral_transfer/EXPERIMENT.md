# Reproduce the first experimental analysis

The sixth peer page uses dataset `z5p5_a3p7`: four synchronous C1/C3 captures
from ion-saturation-current probes at one operating condition. Acquisition
facts and explicit unknowns are in `experiment_z5p5_a3p7.json`. Original binary
data are external inputs; no raw `.bin` files are included in the repository.

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

## Leave-one-capture-out model validation (page 07)

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
