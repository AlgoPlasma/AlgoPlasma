# J01 continuity free-flow tests

This directory validates `J_Fluid/J01_continuity_freeflow` independently from
the rest of a fluid or PIC application.

The first test suite covers the current public contract of the routine:

- zero-velocity/zero-source identity;
- the current source convention, `n_new = n_old - s`;
- a deterministic three-dimensional single-step reference calculation;
- exact one-cell transport for positive and negative unit velocity in x, y,
  and z;
- preservation of the old state in `n0` and preservation of guard cells
  outside the documented update region;
- total-density conservation for a periodic domain with zero source.

The test deliberately uses unequal bounds in the three directions so that an
x/y/z indexing mix-up cannot be hidden by a cubic domain.

## Run

From the repository root:

```bash
bash tests/010_fluid/J01_continuity_freeflow/run.sh
```

A successful run ends with:

```text
RESULT: PASS
```

The build enables GNU Fortran bounds checking, uninitialized-real poisoning,
floating-point traps, and warnings. Build artifacts are kept under `build/`.

## Clean

```bash
bash tests/010_fluid/J01_continuity_freeflow/clean.sh
```

