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
orientations 0–90 deg, recorded for 256 segments each. The phase distribution is estimated from these repeated segments.

The **Beall pair** is a separate aligned 20 mm pair with 512 segments. Its first
alias boundary is `f_alias = c_s/(2d)`, but the full fold period is `c_s/d`.
Generated modes occupy ten fold orders (1 through 10); `f_max/f_alias` is not
the count of full folds. Longer separation exposes multiple folds without
expanding the inversion search domain.

## What is checked

- K01: spectral exponent, lower edge, ten-times-noise-floor threshold crossing, and coherence.
- K02: circular peak errors for strong modes, assessed in histogram bins.
- K03: sound speed, magnitude and direction statistics, plus **every selected wavevector** and boundary/tie flags.

Requirements are declared in `source_py/config.py: ACCEPTANCE`. They are engineering
acceptance limits for this fixed synthetic case, not universal confidence bounds.
The [bilingual test page](../../../docs/source/tests/010_diagnostics/case_broadband_dispersion.rst)
explains each limit and includes tables and four figures from the same run.

For total power `signal + noise > 10*noise`, the signal threshold is `9*noise`.
The threshold prediction uses this definition, not signal/noise equality.
For K03, each vector must satisfy `|K_est-K_true| <= 0.05*|K_true| + grid_step/sqrt(2)`.
The grid term is the nearest-grid-point distance budget; the 5% term is the declared
noisy-recovery requirement. No over-budget modes, boundary peaks or exact tied maxima
are accepted in this reference case. These flags do not by themselves establish the
validity or uniqueness of an estimate for general experimental data.

This case covers one propagation direction per frequency. Multiple simultaneous waves
at the same frequency and changes in noise/geometry need separate validation.

## Running

```bash
bash run.sh
# Also publish a consistent documentation snapshot after all checks pass:
bash run.sh --publish-docs
```

The driver runs four small acceptance counterexamples, regenerates the records, then
runs K01–K03. `source_py/test_acceptance.py` can be run separately without waveform files.
The basic analytic algorithm checks are in [basic_numerical tests](../case_basic_checks/).
The vectorized inversion uses up to 48 workers with bounded-memory row blocks.

Outputs:

- `output/summary.json`: requirements, measurements, per-mode errors/reasons and source hashes.
- `output/modes.csv`: one row per inverted frequency, including true/recovered components and search flags.
- `output/results_zh.rst`, `output/results_en.rst`: tables generated from that run.
- `output/figures/`: raw_waveform.png, power_spectrum.png, beall_skf.png, mle_dispersion.png.

`--publish-docs` updates the small numerical snapshot under
`docs/source/tests/010_diagnostics/_generated/case_broadband_dispersion/` and the four
figures under `docs/source/images/tests/010_diagnostics/case_broadband_dispersion/` together.
A failed run leaves its diagnostics in output and does not replace the published snapshot.
`clean.sh` removes runtime outputs and about 95 MB of generated records in build/.

## Related documentation

[K_Diagnostics](../../../K_Diagnostics/),
[K01_signal_spectra](../../../K_Diagnostics/K01_signal_spectra/),
[K02_beall](../../../K_Diagnostics/K02_beall/),
[K03_mle_k2d](../../../K_Diagnostics/K03_mle_k2d/).
