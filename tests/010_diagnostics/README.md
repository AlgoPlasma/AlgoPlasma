# 010_diagnostics

Diagnostic and signal-inversion tests for `K_Diagnostics`.

Unlike the other test categories, the algorithms under test take probe time
series rather than particles or fields, and the `K_Diagnostics` units are
subroutines only: they perform no file I/O and run no computation of their own.
Test drivers provide inputs and call the numerical routines.

- `case_basic_checks`: twelve small deterministic checks, numerical reports and
  four explanatory figures for phase statistics, weights, grid sampling and leakage.
  Run `bash case_basic_checks/run.sh`; add `--publish-docs` to update the documentation snapshot.

- `case_broadband_dispersion`: drives K01, K02 and K03 as one chain on a single
  synthetic broadband dataset, and checks each against the generator that
  produced it.

The broadband case is pure Python, so `make.sh` generates the synthetic records instead of
compiling, and `run.sh` reduces them through the three units. The large waveform
records are rebuilt from the constants in
`source_py/config.py` on every run and removed by `clean.sh`. Each case cleans its
own runtime outputs. The small basic-check documentation snapshot is versioned
separately under `docs/source/tests/010_diagnostics/_generated/case_basic_checks`.

The criteria compare the measurement with quantities fixed by the generator: a
spectral exponent, folded-wavenumber peaks and an ion sound speed.  The single-pair
K02 check does not claim to recover the fold order that aliasing removes.
