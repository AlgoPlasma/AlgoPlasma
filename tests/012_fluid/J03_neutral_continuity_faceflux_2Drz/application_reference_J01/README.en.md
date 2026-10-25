# FM → J03 Application Test

[中文](README.zh-CN.md) | [English](README.en.md)

This directory passes the reference density and face fluxes from
[J01 free-molecular statistics](../../../../J_Fluid/J01_free_molecular/README.en.md)
to the [J03 continuity solver](../../../../J_Fluid/J03_neutral_continuity_faceflux_2Drz/README.en.md)
for the loss-free B0 application. FM tracks straight trajectories in the r-z plane
with radial and axial velocity components; cylindrical volumes and areas normalize
the statistics.

## Requirements and execution

Bash, GNU Fortran, Python 3, NumPy and Matplotlib are required. Plotting uses the
`Agg` backend. Run from the repository root:

```bash
APPLICATION_OUTPUT="$HOME/algoplasma-results/fm-B0" \
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference_J01/run.sh
```

The default inputs are in the sibling [application_inputs](../application_inputs/README.en.md)
directory, and [application_case.f90](../application_case.f90) generates the active
region. The first script argument can specify another grid directory, which must
retain the prescribed 256×256 grid and active-region indices. Input validation
precedes compilation.

By default, the preprocessor tracks 2400000 particle histories. Set the second
positional argument or `J01_FM_HISTORIES` environment variable to change this count;
the positional argument takes precedence. The count affects statistical error
and runtime.

## Checks and acceptance criteria

The runner executes J01 preprocessing, J03 continuity and the shared acceptance/plotting
program in sequence. On success, `summary.txt` contains `RESULT: PASS`; a failed
check returns a nonzero process status.

| Check | Acceptance criterion |
| --- | --- |
| FM preprocessing | All particle histories finish without truncation |
| Preprocessing and J03 densities | Finite and nonnegative in active cells |
| J03 steady state | Solver reports convergence |
| Local residual | Normalized residual ≤ `1e-8` |
| Global balance | Relative particle-rate imbalance ≤ `1e-6` |

Density change relative to preprocessing is a diagnostic. FM uses a sector of
`1/3` radian, whereas J03 integrates over a full turn. Density and flux per unit
area pass directly between them. Multiply the FM sector's total particle rates
by the azimuthal factor `6*pi` when comparing totals.

Formulas, figures and the historical run dated 2026-10-06 are documented on the
[full-application test page](../../../../docs/source/tests/012_fluid/application_tests.rst).
This application covers free-molecular motion with two velocity components in the
r-z plane.

## Outputs and cleanup

The default destination is `build/output_B0` within this directory.
`APPLICATION_OUTPUT` overrides that location. The destination must be empty;
choose a new directory for each rerun.

| Output | Content |
| --- | --- |
| `j01/`, `j03/` | Stage-specific fields, statistics or balance records and `run.log` |
| `summary.txt` | History completion, continuity convergence, residual, balance and density change |
| `j01_chain_density.png` | Two panels on a common colour scale: FM reference density and J03 steady density |

The horizontal axis is z, the vertical axis is r, and colour represents neutral
density. Use `summary.txt` with the plot to assess acceptance. The J03 test
directory's `clean.sh` removes this application's entire `build/`, including
default results. Save needed output elsewhere first; results written to external
directories remain under the user's control.
