# broadband_dispersion test

This case drives all three `K_Diagnostics` units from one synthetic dataset and
checks each of them against the generator that produced it.  The `K_Diagnostics`
units are subroutines only; this is where the computation happens.

## The synthetic field

The signal model is taken from the broadband Beall validation in
`simulation/simulation_beall/02宽频/generate_signal.py`: a continuous spectrum of
ion acoustic modes on the linear branch `omega = k c_s`, superposed in the time
domain.

- xenon, `m_i = 131 u`, `T_e = 20 eV`, so `c_s = 3825 m/s`; no ion drift
- sampled at 10 MHz in segments of 1250, so the bin width is 8 kHz
- 238 modes from 104 kHz to 2 MHz, **one per frequency bin**, so the in-band
  spectrum is continuous
- amplitude law `A ~ 1/f`, giving a power spectrum falling as `1/f^2`
- all modes share the propagation direction 30 deg; `|K|` runs from 171 to
  3286 rad/m
- random mode phases drawn **once** and shared by every segment and every
  configuration, as in the reference: the field is one stationary realisation
  observed by all the probes
- independent white Gaussian noise per probe at a broadband SNR of 10

Each segment is `sum_n A_n cos(K_n . x_p - omega_n t + phi_n)` evaluated at the
two probe positions, so the phase difference between the probes is exactly
`K_n . chi`.  Time restarts at zero in every segment, which keeps each segment
periodic in its own length so every mode lands on an exact rFFT bin.

Nothing is stored in the repository: `make.sh` rebuilds the records into
`build/` from the constants in `source_py/config.py`, and `clean.sh` removes
them.

### Two probe sets

The **inversion array** is 35 configurations, spacings 3.0–5.0 mm at
orientations 0–90 deg, recorded for 16 segments each.

The **Beall pair** is a single, deliberately coarse 20 mm pair recorded for 512
segments.  Two reasons for treating it separately.  The number of aliasing folds
a Beall map shows is `f_max / f_alias` with `f_alias = c_s / (2 d)`, so a coarse
pair produces many folds over a modest band — the reference reaches the same
pattern with a 4 mm pair and a 10 MHz band, which would push the inversion's
search grid up by an order of magnitude.  And the Beall spectrum is a
statistical estimator that spreads each sample over a wavenumber histogram, so
it needs far more segments than the mean phase the inversion needs.

## What is checked

| Unit | Criterion | Measured |
| --- | --- | --- |
| K01 | The generator's spectral exponent is recovered from the measured spectrum | −2.015 against −2 |
| K01 | The lower band edge is recovered | 104 kHz, matching to within one bin |
| K01 | The spectrum meets the noise floor where the `1/f^2` law predicts | 816 kHz measured against 733 kHz predicted (11 %) |
| K01 | Coherence is high where modes stand clear of the floor, and at the `1/n_seg` floor above the band | 0.932 and 0.038 against a floor of 0.0625 (checked numerically; not plotted) |
| K02 | Every mode is assigned to the correct fold, its peak landing where K02's own closed form predicts | largest circular residual 34 rad/m, 11 % of one fold period; median 1.1 bins |
| K02 | The branch is genuinely folded, many times over | all 238 modes aliased, 10 distinct fold orders |
| K03 | Fitting `f` against `\|k_hat\|` through the origin returns the ion sound speed | 3829.6 against 3824.6 m/s, relative error **1.3e-3** |
| K03 | Per-mode accuracy | `\|k\|` error median 0.28 %, direction error median 0.26 deg |

Every criterion has the same shape: a quantity the generator was built from is
recovered from the measurement and compared with it.  None of them is a
tolerance chosen to make the test go green.

The wavenumbers span more than a decade, which one uniform search grid cannot
cover at useful resolution, so K03 is driven through `search_wavevector`: a
coarse grid over the whole range followed by a fine grid around the coarse peak.

## Running

```bash
bash run.sh
```

`make.sh` generates the records into `build/`, and `source_py/analyze.py`
reduces them through the three units, writing `output/summary.json` and four
figures under `output/figures/`.  The exit code is 0 when all three checks
pass.  A full run takes a few seconds and leaves about 11 MB in `build/`, which
`clean.sh` deletes.

## Figures

Under `output/figures/`:

| File | Content |
| --- | --- |
| `raw_waveform.png` | Two panels: the noiseless segment against the recorded one, so the signal-to-noise ratio is visible; and the two noiseless probes, where the probe-to-probe phase difference can be seen. On the recorded traces it is buried, which is why the later units estimate it in the frequency domain |
| `power_spectrum.png` | Both power spectra in log-log against the generator's `f^-2` law and the noise floor, showing the sharp band edge and where the spectrum sinks into the floor |
| `beall_skf.png` | The measured `S(k, f)` inside the strip the coarse pair can represent, folded into a repeating sawtooth, with the folded branch and K02's per-mode prediction overlaid |
| `mle_dispersion.png` | The same branch recovered straight by the joint inversion, against `f = c_s\|k\|/2 pi` |

The last two are the point of the case: **the branch K02 can only show folded is
the branch K03 recovers straight**, from identical data.

## Related documentation

[`K_Diagnostics`](../../../K_Diagnostics/),
[`K01_signal_spectra`](../../../K_Diagnostics/K01_signal_spectra/),
[`K02_beall`](../../../K_Diagnostics/K02_beall/),
[`K03_mle_k2d`](../../../K_Diagnostics/K03_mle_k2d/).
