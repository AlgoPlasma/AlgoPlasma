# J01_free_molecular tests

Five standalone programs test the production modules without archived external solutions.

| Test source | Implementation | Checks |
| --- | --- | --- |
| `test_J01_continuity_freeflow.f90` | 3D continuity | Update formula, subtractive source, guards, six shifts and periodic conservation |
| `test_J01_faceflux_2Drz_units.f90` | 2D flux utilities and FM driver | Flux signs, area/volume update, single-cell rate balance and invalid density |
| `test_J01_corner_crossings.f90` | Trajectory tracking | Exact and near corners, both arrival orders, all four velocity signs, stepped boundaries, crossing counts and residence |
| `test_J01_sampling_distribution.f90` | Inlet and wall sampling | Annular-area, truncated-normal inlet and four-face diffuse-reflection probabilities with three seeds |
| `test_J01_fm_units.f90` | Sampling, reflection, tracking, statistics and driver | Partial inlet, sampling range, lookup, normalization, truncation and invalid topology |

```bash
bash tests/012_fluid/J01_free_molecular/run.sh
```

Every program must report `RESULT: PASS`; failures return nonzero.
Logs are written to `build/*.log`. Deterministic FM scalar checks use
`1e-11*max(1,abs(expected))` unless the test specifies a different tolerance.
Sampling tests use 32768 draws per group and compare analytical probabilities
within seven binomial standard deviations. They do not replace full applications.

The J03 test directory contains the small FM-to-J03 tests: actual trajectory
tallies feed time stepping with a two-cell analytical solution, and a complete
sampled FM run checks rate balance. Full applications have separate runners.

```bash
bash tests/012_fluid/J01_free_molecular/clean.sh
```
