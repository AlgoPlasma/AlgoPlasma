# B04 minimal calling example

[简体中文](README.zh-CN.md)

[main.f90](main.f90) deposits one macroparticle representing eight real particles
on a nonuniform cylindrical annular sector with physical angular endpoints.
The sequence is **prepare volumes → clear density → scatter → sum represented
number → optionally form cell-volume averages**.

## Build and run

Use Bash (for example, on Linux or WSL) and GNU Fortran. From the repository root:

```bash
mkdir -p examples/B04_scatter_3d_raz_nonuniform/build
gfortran -cpp -std=f2008 -fdefault-real-8 -O0 -g -fcheck=all \
  -I B_Scatter/B04_scatter_3d_raz_nonuniform \
  -J examples/B04_scatter_3d_raz_nonuniform/build \
  B_Scatter/B04_scatter_3d_raz_nonuniform/mod_B04_scatter_3d_raz_nonuniform.f90 \
  examples/B04_scatter_3d_raz_nonuniform/main.f90 \
  -o examples/B04_scatter_3d_raz_nonuniform/build/b04_minimal
examples/B04_scatter_3d_raz_nonuniform/build/b04_minimal
```

The command enables preprocessing and compiles the module and caller with the
same double precision. Build artifacts stay in the ignored example `build/` directory.

## Expected output

```text
Represented number =     8.000000
Cell array shape = 2 2 2
```

The deposited nodal data represent eight real particles, matching the input
macroparticle weight. The cell-average array has two cells in each of the radial,
angular and axial directions.

## Further reading

- [Module and calling conventions](../../B_Scatter/B04_scatter_3d_raz_nonuniform/README.md)
- [Usage guide and adaptation to your program](../../docs/source/rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform/usage.rst) (bilingual Sphinx source)
- [Automated tests](../../tests/004_scatter/B04_scatter_3d_raz_nonuniform/README.md)

After building the documentation, open the repository-relative local file
`docs/build/html/rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform/usage.html`.

Author: Xin Luo.
