# 011_fluid tests

## Fast checks

```bash
bash tests/011_fluid/J01_free_molecular/run.sh
bash tests/011_fluid/J02_neutral_sn_transport_2Drz/run.sh
bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh
bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/application_reference/make.sh
python3 tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/test_application_checks.py
```

Fortran checks require gfortran. Application validation and plots use NumPy and Matplotlib; input-grid validation itself uses only the standard library. Full applications are separate and may take substantially longer.

The application build above compiles the drivers without running transport.
It enables the test that supplies negative, NaN, and infinite J02 reference
densities to the actual J03 driver and verifies rejection before time stepping.
Without that build, the driver test is explicitly skipped. Both preprocessing
and continuity densities must be finite and nonnegative in active cells.

## Before committing

Generated build files remain visible in git status by design. Do not use an unrestricted `git add .`. Preserve application outputs that are still needed; the J03 clean script removes those outputs too.

To stage test changes while excluding generated directories:

```bash
git add -A -- tests/010_fluid tests/011_fluid ':!**/build/**' ':!**/__pycache__/**'
bash tests/011_fluid/check_pr_files.sh
git diff --cached --stat
```

Stage the intended J_Fluid source and docs/source changes separately and review them. Do not stage docs/build or docs/source/_doxygen. The guard checks the actual Git index for generated files and whitespace errors; it does not stage or delete anything. The obsolete tests/010_fluid path in the command records the directory migration.

The application scripts refuse to overwrite a nonempty output directory. Set APPLICATION_OUTPUT to a new path for a rerun. No full-application pass should be inferred from fast-test results.
