# 011_K04_breathing_waveform

[中文](README.zh-CN.md) | [English](README.en.md)

Verify the [K04 numerical routines](../../K_Diagnostics/K04_breathing_waveform/README.en.md) with artificial data
and reproduce the 12 figures in the [learning page](../../docs/source/rst_files/K_Diagnostics/K04_breathing_waveform.rst)
plus the 2 figures in the [compact-phase note](../../docs/source/knowledge/compact_phase.rst).
This directory contains generators, example drivers, plotting scripts, 17 local tests and cleanup.
See the [documentation test page](../../docs/source/tests/011_K04_breathing_waveform/index.rst) for details.

## Environment and commands

Python 3.10+. Calculations and tests require NumPy; plots also require Matplotlib.
The `Agg` backend needs neither a display nor LaTeX. AlgoPlasma needs no compilation or package installation.
Run these commands from the **repository root**; skip installation if dependencies are already available:

```bash
python -m pip install -r tests/011_K04_breathing_waveform/requirements.txt
bash tests/011_K04_breathing_waveform/run.sh
```

`run.sh` runs all tests, both numerical examples, and all 14 plots. To run only tests or clean generated files:

```bash
bash tests/011_K04_breathing_waveform/test.sh
bash tests/011_K04_breathing_waveform/clean.sh
```

These scripts require Bash on Linux, macOS or WSL. Inside this directory, `bash run.sh`, `bash test.sh`
and `bash clean.sh` also work. The runners use `python3` by default; for example,
`PYTHON=python bash tests/011_K04_breathing_waveform/run.sh` selects the current environment's `python`.
The runners disable bytecode writes to avoid creating caches in the numerical routine directory.

Alternatively, run each Python step from the repository root without Bash orchestration:

```bash
python -B -m unittest discover -s tests/011_K04_breathing_waveform -v
python -B tests/011_K04_breathing_waveform/source_py/run_example.py
python -B tests/011_K04_breathing_waveform/source_py/plot_figures.py
python -B tests/011_K04_breathing_waveform/source_py/run_compact_phase.py
python -B tests/011_K04_breathing_waveform/source_py/plot_compact_phase.py
```

## Files

| File | Purpose |
| --- | --- |
| `run.sh` / `test.sh` | Full reproduction / local tests only |
| `source_py/generate.py` | Main and compact-phase artificial-data generators |
| `source_py/run_example.py` | Run the main example; save arrays and metrics |
| `source_py/plot_figures.py` | Read saved results and redraw Figures 1–12 |
| `source_py/run_compact_phase.py` | Run the compact-phase example |
| `source_py/plot_compact_phase.py` | Redraw the frequency-shift and phase-error figures |
| `source_py/_paths.py` | Locate the repository and default output directory |
| `test_K04_breathing_waveform.py` | 14 numerical and documentation-agreement tests |
| `test_clean.py` | 3 cleanup-scope and symlink tests |
| `clean.sh` | Remove default outputs and this test case's Python caches |
| `requirements.txt` | NumPy and Matplotlib dependencies |
| `output/` | Generated results; ignored by Git |

## Outputs and expected results

Results default to this directory's `output/`. Reruns overwrite matching output names.

- `synthetic_result.npz`: artificial inputs, checking truth, and intermediate `F`, `F_hat`, phases,
  `mu`, `a`, `w`, `C`, `R`, and other arrays.
- `metrics.json`: seed `20261004`, ten 160000-point records sampled at 8 MHz, holding out record 0.
  Main frequency 39750 Hz, `H=75`, minimum training count 5566, and waveform RMSE
  against generator truth approximately **0.00493408 V**.
- `figures/r3_01_x.png` through `r3_12_residual.png`: Figures 1–12 with the documentation filenames.
- `compact_phase_result.npz`, `compact_phase_metrics.json`, `compact_figures/`: compact-phase results
  and two figures. With 4096 coarse points, phase RMSE versus the direct method is approximately **6.8351e-7 rad**.

`C_known` and `phi_known` are checking truth, never inputs to extraction. `R` is residual voltage;
`error` is estimation error. These reference values describe fixed artificial data, not measured-data accuracy.

Run scripts accept `--output-dir`; the main example also accepts `--seed`.
Plot scripts accept `--input` and `--output-dir`. Append `--help` for options.
After changing numerical output locations, point the plotter at the new result, for example from the repository root:

```bash
python -B tests/011_K04_breathing_waveform/source_py/run_example.py --output-dir /tmp/k04-demo
python -B tests/011_K04_breathing_waveform/source_py/plot_figures.py --input /tmp/k04-demo/synthetic_result.npz --output-dir /tmp/k04-demo/figures
```

## What do the tests check?

The 14 numerical tests check known phase and positive-frequency half amplitude, original-voltage bins,
sample weighting and holdout exclusion, half-bin correction, harmonic truncation, periodic lookup,
input constraints, synthetic recovery, compact normalization/shifts, interpolation accuracy, and endpoint winding.
They execute both languages of the actual documentation snippets and compare them with the numerical routines.
Success prints `OK`; failure exits nonzero. The fixed artificial example uses regression budgets of
waveform RMSE <10 mV and compact phase RMSE <1e-6 rad; these are not universal physical accuracy limits.

Three additional tests use temporary directories to check cleanup scope, repeat runs, symlinks and script location.
They are skipped outside POSIX/Bash environments; numerical tests still run.

## Update documentation figures

Default plotting writes only to `output/`. After inspecting the results, update the 12+2 documentation assets
from the repository root with:

```bash
python -B tests/011_K04_breathing_waveform/source_py/plot_figures.py --output-dir docs/source/images/K_Diagnostics/k04
python -B tests/011_K04_breathing_waveform/source_py/plot_compact_phase.py --output-dir docs/source/images/knowledge
```

Generate both numerical examples first. These commands overwrite the corresponding documentation images.
Then rebuild Sphinx following the [documentation guide](../../docs/DOCUMENTATION_GUIDE.md).

## Cleanup scope

`clean.sh` removes this test case's entire default `output/` directory, including data, metrics and images,
plus Python `__pycache__/` directories within this test case, including Git-ignored files.
Repeated cleaning succeeds and restores the absence of default generated artifacts expected in a fresh clone.
Source, READMEs, saved documentation figures and user edits remain. Results written elsewhere with
`--output-dir` require separate cleanup. The script does not reset Git or clean other modules or documentation builds.
