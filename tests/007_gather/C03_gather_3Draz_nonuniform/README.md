# C03 nonuniform cylindrical gather tests

Run from the repository root:

```bash
bash tests/007_gather/C03_gather_3Draz_nonuniform/run.sh
```

Requires GNU Fortran and Python 3 (standard library only). `FC` may select another
GNU-compatible compiler executable. The build enables double precision and array
bounds/runtime checks: `-cpp -O2 -fdefault-real-8 -Wall -Wextra -fcheck=all -fbacktrace`.

- `source_f90/main.f90`: fills component-specific staggered grids and samples the
  public point/wrapper interfaces; a command-line case selects an invalid input.
- `source_py/analyze.py`: evaluates analytic references independently, checks all
  6912 expected CSV rows, measures convergence, and checks 11 expected failures.
- `make.sh`: builds `build/main`.
- `run.sh`: builds, overwrites the CSV, and runs analysis. Any failed check returns
  a nonzero exit status; stale CSV output is never analyzed after a failed driver.
- `clean.sh`: removes this test's `build/`, `output/`, and Python cache.

Coverage: constants; uniform/nonuniform multilinear fields; wrapper and cached
cells; angular period shifts across a seam; offset local boxes and ghost values;
axis and single-cell grids; smooth-field convergence on 8/16/32 cells per axis.
Each grid samples 96 deterministic positions and all six components. Exact-field
cases include owned-box corners/edges/faces, internal faces, and cell centers.
Ghost widths differ from adjacent owned widths. No MPI communication is performed.

Results are written to `output/c03_gather.csv`, `output/summary.json`, and one
`output/<case>.log` per invalid-input case. Constant tolerance is `1e-12`, other
exact-field tolerances are `2e-11`; both smooth refinement orders must be in
`[1.7,2.3]`. Every invalid input must terminate unsuccessfully with its expected
C03 error message. Missing, duplicate, unexpected, or nonfinite samples fail.

[完整中文 / English 测试说明](../../../docs/source/tests/007_gather/C03_gather_3Draz_nonuniform.rst)
