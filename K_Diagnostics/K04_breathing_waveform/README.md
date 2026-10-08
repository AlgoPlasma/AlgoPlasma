# K04_breathing_waveform

[中文](README.zh-CN.md) | [English](README.en.md)

Extract the breathing-phase-repeatable mean waveform `C` from repeated single-point voltage records,
then return `R = X - C`. Learn the shape from all but one complete record and reconstruct it using
the held-out record's own phase. This directory contains only numerical routines and READMEs.
The routines require NumPy, perform no file I/O, and do not modify inputs.

See the [step-by-step explanation](../../docs/source/rst_files/K_Diagnostics/K04_breathing_waveform.rst).
Artificial data, tests, plotting and cleanup scripts live in
[`tests/011_K04_breathing_waveform`](../../tests/011_K04_breathing_waveform/README.en.md).
That README and the [documentation test page](../../docs/source/tests/011_K04_breathing_waveform/index.rst)
provide the running instructions.

## Python usage

Python 3.10+ with NumPy. Add the repository root to Python's import path, or run your own script from it:

```python
from K_Diagnostics.K04_breathing_waveform.mod_K04_breathing_waveform import (
    fun_K04_extract_waveform,
)

# Caller-supplied records: at least three 1-D voltage arrays from one point; fs in Hz.
result = fun_K04_extract_waveform(records, fs, held_out=0)
C, R = result["C"], result["R"]
```

Records must contain finite real voltages, share one sampling rate and represent comparable conditions.
Their lengths may differ. `C` and `R` are in V and align with `records[held_out]`.
Change `held_out` to obtain separate holdout results for each record. The full entry point is:

```python
fun_K04_extract_waveform(records, fs, held_out=0, bins=256, cutoff=3e6,
                        grid_size=4096, search=(35e3, 45e3), band=(25e3, 55e3))
```

Defaults match the documented artificial example. Reconsider the peak-search range `search`,
phase band `band`, bin count `bins`, nominal harmonic limit `cutoff` (Hz) and lookup count `grid_size`
for measured data. The returned dictionary also exposes original and selected frequency coefficients,
phases, bin sums and counts, mean shape `mu`, Fourier coefficients `a`, and cycle curve `w`.
Each function's docstring specifies all inputs, units, constraints and outputs.

## Files

`mod_K04_breathing_waveform.py` only re-exports routines. Each `fun_` file provides one function:

| File | Purpose |
| --- | --- |
| `fun_K04_find_frequency.py` | Full FFT and main-frequency search |
| `fun_K04_make_complex_signal.py` | Positive-band selection and complex IFFT |
| `fun_K04_mark_position.py` | Unwrapped phase and cycle position |
| `fun_K04_put_into_bins.py` | Accumulate original voltages and counts by phase position |
| `fun_K04_mean_other_records.py` | Pool the mean shape while excluding a complete record |
| `fun_K04_mean_to_coefficients.py` | Fourier coefficients with half-bin correction |
| `fun_K04_coefficients_to_grid.py` | Evaluate the cycle curve with a harmonic limit |
| `fun_K04_grid_to_time.py` | Periodic interpolation onto original sample phases |
| `fun_K04_extract_waveform.py` | Complete extraction workflow |
| `fun_K04_compact_phase.py` | Compact calculation of narrowband phase |

`C` includes the baseline and phase-repeatable components within the retained orders;
the harmonic limit is not an ordinary lowpass cutoff. Residual strength may still vary with breathing phase.
The compact method has a separate [knowledge note](../../docs/source/knowledge/compact_phase.rst).
