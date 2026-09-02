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

The criteria are quantities the generator was built from — a spectral exponent,
an aliasing fold order, an ion sound speed — recovered from the measurement and
compared back, rather than tolerances chosen to make the tests pass.
