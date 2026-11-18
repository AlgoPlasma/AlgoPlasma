# SN → J03 Application Tests

[简体中文](README.zh-CN.md)

This directory passes [J02 SN reference fields](../../../../J_Fluid/J02_neutral_sn_transport_2Drz/README.md)
to the [J03 continuity solver](../../../../J_Fluid/J03_neutral_continuity_faceflux_2Drz/README.md).
It checks complete applications for loss-free B0 and prescribed-volume-loss ION.
SN retains r-z space and two velocity components, with one in-plane angle in its
velocity quadrature. J03 advances scalar density. Cylindrical volumes and areas
supply the discrete conservation measures for this reduced model.

## Requirements and execution

Bash, GNU Fortran, Python 3, NumPy and Matplotlib are required. Plotting uses the
`Agg` backend. Run from the repository root:

```bash
OMP_NUM_THREADS=4 OMP_DYNAMIC=FALSE \
APPLICATION_OUTPUT="$HOME/algoplasma-results/sn-openmp-B0" \
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference/run_application_reference.sh B0
```

For ION, change the final argument to `ION` and select a different output directory.
J02 enables OpenMP by default, adding `-fopenmp` during compilation and linking;
set `OPENMP=0` for a serial build. Thread parallelism applies to J02 discrete-velocity
sweeps; J03 time stepping remains serial.

The second script argument can select another grid directory. The default is the
sibling [application_inputs](../application_inputs/README.md) directory.
Inputs must retain the prescribed 256×256 grid and active-region indices.
Grid validation precedes compilation; [application_case.f90](../application_case.f90)
generates the active region and ION loss.

## Checks and acceptance criteria

The runner executes J02 preprocessing, J03 continuity and the shared acceptance/plotting
program in sequence. On success, `summary.txt` contains `RESULT: PASS`; a failed
check returns a nonzero process status.

| Check | Acceptance criterion |
| --- | --- |
| SN preprocessing | Reflection source iteration converges |
| Preprocessing and J03 densities | Finite and nonnegative in active cells |
| J03 steady state | Solver reports convergence |
| Local residual | Normalized residual ≤ `1e-8` |
| Global balance | Relative particle-rate imbalance ≤ `1e-6` |

Density change relative to preprocessing is a diagnostic; the J03 equation and
face-flux closure determine its steady density. Formulas and historical runs are
documented on the [full-application test page](../../../../docs/source/tests/012_fluid/application_tests.rst).
Its SN B0/ION records dated 2026-10-06 used four OpenMP workers. See the
[J02 test guide](../../J02_neutral_sn_transport_2Drz/README.md) for the scope of spatial MPI verification.

## Outputs and cleanup

The default output directory is `build/application_reference/output_B0` or
`output_ION` within this directory. `APPLICATION_OUTPUT` overrides that location.
The destination must be empty; choose a new directory for each rerun.

| Output | Content |
| --- | --- |
| `j02/`, `j03/` | Stage-specific fields, balance records and `run.log` |
| `summary.txt` | Preprocessing status, continuity convergence, residual, balance and density change |
| `j02_chain_density.png` | Two panels on a common colour scale: SN reference density and J03 steady density |

The horizontal axis is z, the vertical axis is r, and colour represents neutral
density. Use `summary.txt` with the plot to assess acceptance. The J03 test
directory's `clean.sh` removes this application's entire `build/`, including
default results. Save needed output elsewhere first; results written to external
directories remain under the user's control.
