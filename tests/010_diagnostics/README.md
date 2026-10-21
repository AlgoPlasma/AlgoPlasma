# 010_diagnostics

Basic numerical and broadband-chain tests for K01–K03 in `K_Diagnostics`.

These cases cover the [probe wave diagnostics topic](../../docs/source/rst_files/K_Diagnostics/probe_wave_diagnostics.rst).
Basic checks supply numerical inputs directly; the broadband case starts from
synthetic probe time series and tests spectra, phase statistics and wavevector
inversion. The numerical routines perform no file I/O; test drivers provide
inputs and orchestrate the computation.

- `case_basic_checks` — **basic_numerical tests / 基础数值测试**:
  three verification groups with references, measurements, errors, acceptance rules
  and status generated from the same run. Supporting figures are collapsible; the
  six-panel leakage explanation is on the knowledge page. The complete report
  retains the sixteen underlying regression checks.
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

K04 has a separate test case: [`011_K04_breathing_waveform`](../011_K04_breathing_waveform/).
See its [README](../011_K04_breathing_waveform/README.en.md) for tests, examples, plots and cleanup.
