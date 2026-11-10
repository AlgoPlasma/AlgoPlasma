# B04 nonuniform cylindrical scatter tests

[简体中文](README.zh-CN.md)

The suite compiles and calls all four public B04 routines and the public B02
charge-deposition routine used for the uniform-grid comparison. References use
hand calculations, independent Gauss quadrature and analytic volume averages.

## Files and coverage

| File | Role |
| --- | --- |
| [source_f90/main.f90](source_f90/main.f90) | Numerical cases, reference values and pass criteria |
| [run.sh](run.sh) | Build B04, B02 and the test driver with consistent options; run tests and export data |
| [plot_results.py](plot_results.py) | Render English documentation figures from local double-precision data |

Each configuration executes **79 assertions**, plus return-status checks after public calls.

| Case | Checks |
| --- | --- |
| Eight-node hand calculation | Nodal volumes, increments, totals, signed cancellation, zero amounts, array lower bounds and internal-face representations |
| Physical corner particles | Contributions go to the corresponding endpoint; the total is preserved |
| Linear-field projection | Cell-volume averages agree with analytic integrals |
| Four grid configurations | Axis/full circle, annulus/full circle, annulus with angular faces, and one periodic angular cell: volumes, uniform density, signed totals, cell-average totals and seam/endpoint handling |
| Nonuniform axis | Weighted reference value, equal density at one physical axis point, and preserved totals for signed inputs and after deposition |
| Public B02 comparison | Nodal arrays agree before axis averaging on a uniform full-circle grid starting at the axis; 71 deterministic particles with signed charges and variable weights |
| Invalid inputs | Return codes and preservation of destination arrays |
| Floating-point range (19 assertions) | Reciprocal-volume and addition limits, cancellation, repeated periodic destinations, and large-value/zero-field cell averaging; rejected operations retain the full destination array |

Deterministic two-point tensor Gauss contributions check that assignment weights
and cylindrical volume normalization recover a constant physical density.
Detailed inputs, formulas and figures are in the [bilingual Sphinx test source](../../../docs/source/tests/004_scatter/B04_scatter_3d_raz_nonuniform.rst).

## Run and interpret

Requires Bash (for example, on Linux or WSL), GNU Fortran, and the repository's
B04 and B02 sources. From the repository root:

```bash
bash tests/004_scatter/B04_scatter_3d_raz_nonuniform/run.sh double debug
bash tests/004_scatter/B04_scatter_3d_raz_nonuniform/run.sh double release
bash tests/004_scatter/B04_scatter_3d_raz_nonuniform/run.sh single debug
```

- `FC` can specify the compiler path; the script flags target GNU Fortran.
- All configurations use preprocessing and Fortran 2008. `double` adds
  `-fdefault-real-8`; `single` uses default real precision. All sources use matching options.
- `debug` enables `-fcheck=all` and `-ffpe-trap=invalid,zero,overflow`;
  `release` uses `-O2`. The full flag list is in [run.sh](run.sh).
- Artifacts stay in the test directory's ignored `build/<precision>-<mode>/`.

Successful execution exits with zero and ends with:

```text
B04 PASS: checks=79, real_bits=64
```

Single precision reports `real_bits=32`. Failed assertions report `FAIL` and exit
with a nonzero status; unexpected return codes also cause a nonzero exit.
`METRIC` lines report numerical errors. Most comparisons use
`2048*epsilon(1.0)` with scaling appropriate to the quantity. Large-value cell
averages are normalized by `huge(1.0)` and checked within `16*epsilon(1.0)`.
Status codes and unchanged arrays use direct checks; the test page and
[source](source_f90/main.f90) give the complete criteria.

## Local data and figures

The runner exports CSV files to `build/<precision>-<mode>/`: `hand_nodes.csv` and
`uniform_nodes.csv` supply Figures 1 and 2; `axis_nodes.csv`, `axis_metrics.csv`
and `axis_totals.csv` supply axis densities, errors and totals. The executable's
optional first argument names an existing export directory; the runner supplies
it. Without that argument, the executable runs the checks without CSV export.

After the double-debug test, run from the repository root:

```bash
python tests/004_scatter/B04_scatter_3d_raz_nonuniform/plot_results.py
```

Plotting requires Python, NumPy and Matplotlib. The script generates three English
figures in the test directory's `build/figures/`, shared by both documentation
languages. Use `--axis-only` for the axis figure, `--data-dir` for another
double-precision CSV directory, and `--output-dir` for a different figure directory.
Raw data and run logs stay local and are ignored by Git; selected documentation
figures remain in the repository.

## Further reading

- [Module and calling conventions](../../../B_Scatter/B04_scatter_3d_raz_nonuniform/README.md)
- [Calling example](../../../examples/B04_scatter_3d_raz_nonuniform/README.md)
- [Detailed test documentation](../../../docs/source/tests/004_scatter/B04_scatter_3d_raz_nonuniform.rst) (bilingual Sphinx source)

After building the documentation, open the repository-relative local file
`docs/build/html/tests/004_scatter/B04_scatter_3d_raz_nonuniform.html`.
