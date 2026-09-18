# J01_free_molecular tests

Three standalone programs test the J01 production modules without archived external results:

- `test_J01_continuity_freeflow.f90`: 3D formula, subtractive source, guards, six shifts and periodic conservation.
- `test_J01_faceflux_2Drz_units.f90`: 2D flux signs, area/volume update, single-cell particle-rate balance and invalid density.
- `test_J01_fm_units.f90`: inlet sampling, reflection, lookup, residence/crossing statistics, normalization and error handling.

```bash
bash tests/011_fluid/J01_free_molecular/run.sh
```

All programs must report `n_failed=0` and `RESULT: PASS`. Logs are in `build/*.log`; failures return nonzero. FM scalar tolerance is `1e-11*max(1,abs(expected))`; other tolerances are documented in the test sources. Small tests do not establish distribution convergence or replace full applications.

Coupled FM→J03 and SN→J03 application tests remain under J03. Clean compiled files with:

```bash
bash tests/011_fluid/J01_free_molecular/clean.sh
```
