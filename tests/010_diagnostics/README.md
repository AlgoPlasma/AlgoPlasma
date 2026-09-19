# 010_diagnostics

Diagnostic and signal-inversion tests for `K_Diagnostics`.

Unlike the other test categories, the algorithms under test take probe time
series rather than particles or fields, and the `K_Diagnostics` units are
subroutines only: they perform no file I/O and run no computation of their own.
All of the computation lives here.

- `case_broadband_dispersion`: drives K01, K02 and K03 as one chain on a single
  synthetic broadband dataset, and checks each against the generator that
  produced it.

The case is pure Python, so `make.sh` generates the synthetic records instead of
compiling, and `run.sh` reduces them through the three units.  Nothing is stored
in the repository: the records are rebuilt from the constants in
`source_py/config.py` on every run and removed by `clean.sh`.

The criteria compare the measurement with quantities fixed by the generator: a
spectral exponent, folded-wavenumber peaks and an ion sound speed.  The single-pair
K02 check does not claim to recover the fold order that aliasing removes.
