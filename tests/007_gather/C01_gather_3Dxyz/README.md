# C01_gather_3Dxyz test

This test validates `C01_gather_3Dxyz` independently from the rest of the PIC
loop.

It covers:

- trilinear exactness on a synthetic trilinear field;
- second-order convergence on a smooth non-trilinear field;
- the fused gather-push path with `B=0`, where the Boris update reduces to a
  direct electric acceleration reference.

Run from this directory:

```bash
bash run.sh
```

The Fortran program writes CSV files under `output/`. The Python postprocessor
computes reference values, checks numerical thresholds, writes `summary.json`,
and saves diagnostic figures under `output/figures/`.
