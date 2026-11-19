# G03_DSMC tests

[简体中文](README.zh-CN.md)

Verify the [G03_DSMC library](../../../G_Collision/G03_DSMC/README.md) through
its cylindrical interface for single-species, equal-weight HS/VHS/VSS elastic
collisions. The suite contains eight core groups and six collision-relaxation regressions.

## Environment and commands

Requires Bash, GCC/Clang with C++20 support, Python 3 and Matplotlib 3.6 or newer.
The runner compiles the library's eight implementation files directly. Core groups
and build-only mode need no Python. Select the compiler with `CXX` and the plotting
Python environment with `PYTHON`.

Run from the repository root:

```bash
bash tests/009_collision/G03_DSMC/run.sh
```

Each successful group prints `PASS`; failure reports a reason and returns a nonzero
status. The default build directory is temporary and removed on exit. Results are
written to this directory's Git-ignored `results/`. Reruns overwrite the log and
result files belonging to the selected run.

## Test coverage

| Group | Source | Purpose |
| --- | --- | --- |
| `models` | `cpp/test_models.cpp` | Check collision kernels and viscosity calibration against model definitions to supply correct material properties for event rates |
| `scattering` | `cpp/test_models.cpp` | Check preservation of relative speed and outgoing-direction statistics against the selected scattering law |
| `random` | `cpp/test_geometry.cpp` | Check keyed replay, field/purpose separation, real-number endpoints and uniform integer indices |
| `geometry` | `cpp/test_geometry.cpp` | Check cell membership, physical volumes and a common velocity basis in collision calculations |
| `conservation` | `cpp/test_stepper.cpp` | Check momentum and energy conservation across multiple cells and steps |
| `schedules` | `cpp/test_stepper.cpp` | Check conversion of physical rates into event counts, waiting times and pair probabilities |
| `replay` | `cpp/test_stepper.cpp` | Check reproducibility under reordering and log truncation, with writeback confined to the supplied span |
| `errors` | `cpp/test_stepper.cpp` | Check explicit failure reporting and preservation of the original state for the entire failed step |
| `relaxation` | `examples/relaxation.cpp` | Check full-trajectory conservation and late-time relative equilibrium errors in second- and fourth-order statistics |

Run individual groups or enable memory checks:

```bash
bash tests/009_collision/G03_DSMC/run.sh schedules
bash tests/009_collision/G03_DSMC/run.sh relaxation
G03_DSMC_SANITIZERS=1 bash tests/009_collision/G03_DSMC/run.sh
```

Scattering-angle checks draw 60000 samples for each angular parameter. Candidate-count
and acceptance-frequency checks each use 20000 seeds. These basic sampling checks
compare with analytical results using a six-standard-error regression rule.

## Relaxation regression

Run each of three models with each of two schedules. Defaults are N=16384,
2000 steps and seed 42. The timestep is `dt=1e-7 s`, total duration 200 microseconds,
number density `n=1e21 m^-3`, and initial temperature 300 K. Positions remain fixed
inside one cylindrical cell; initial global velocities form equally populated
positive and negative x-directed beams. The particle count reduces statistical
fluctuations to support a 1% relative-error check.

`--check` applies two sets of criteria:

- **Equilibrium error:** average statistics over steps 1001–2000, the second-half
  interval `(100,200]` microseconds. Directional energy shares `Fa` target `1/3`;
  x-component kurtosis `kappa_x` targets 3. Require
  `max_a |3*mean(Fa)-1| <= 1e-2` and `|mean(kappa_x)/3-1| <= 1e-2`.
  Compute kurtosis at each step before taking its time average.
- **Full-trajectory conservation:** at every step, both the relative temperature
  change and the mean-velocity change divided by initial speed `v0` must be at most `1e-10`.

Any failed check returns a nonzero status. Custom step counts still use the second
half; fewer particles or a shorter evolution may not meet the same accuracy.
Collision counts are diagnostic outputs. Spatial transport and transport coefficients
require dedicated cases.

## Outputs and plot interpretation

```text
results/
  run.log                         # Run details, measured relative errors and pass/fail reasons
  relaxation-{HS,VHS,VSS}-{ntc,clock}.csv  # Six step-by-step trajectories
  summary.csv                     # Endpoints, late means, relative errors and maximum conservation errors
  relaxation.png                  # VSS + NTC directional-energy and kurtosis relaxation
```

Each trajectory contains one row per step, including the initial state: 2001 rows
by default. The upper plot shows energy shares relaxing from `(1,0,0)` toward `1/3`
each; the lower plot shows kurtosis relaxing from 1 toward 3. Shading marks the
late-time averaging interval. `Late mean` labels its averages while curves retain
instantaneous fluctuations. In `summary.csv`, `mean_*` columns hold these averages
and `*_relative_error` columns hold the two equilibrium errors defined above.

Redraw existing data with:

```bash
bash tests/009_collision/G03_DSMC/run.sh plots
```

Rebuild the documentation after running the tests to update its embedded figure.

## Custom parameters

Keep executables in the test directory, then choose particle count, step count and seed:

```bash
G03_DSMC_BUILD_DIR=tests/009_collision/G03_DSMC/build bash tests/009_collision/G03_DSMC/run.sh build
mkdir -p tests/009_collision/G03_DSMC/results
# MODEL SCHEDULE [particles steps [seed]] [--check]
tests/009_collision/G03_DSMC/build/relaxation VSS ntc 16384 2000 42 --check \
  > tests/009_collision/G03_DSMC/results/relaxation-VSS-ntc.csv
```

Explicitly selected build directories are retained. The runner cleans only temporary
build directories it creates itself.

See [G03_DSMC Validation](../../../docs/source/tests/009_collision/G03_DSMC.rst)
for test purposes, equations and plot interpretation, and the
[library README](../../../G_Collision/G03_DSMC/README.md) for models and interfaces.
