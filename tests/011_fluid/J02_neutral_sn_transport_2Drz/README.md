# J02 neutral SN transport tests

These deterministic tests exercise the first-stage, PIC-independent SN kernel:

- two-dimensional velocity-space quadrature and exact equivalence of the
  `midpoint` and `gauss-chebyshev` alias names;
- cylindrical r-z cell volumes, face areas, and weighted means;
- entries of the local P1-DG streaming operator;
- two-dimensional Maxwell and drifted-Maxwell reservoir shapes;
- MC crossing-bin conversion and prescribed-flux normalization;
- specific error messages and separate sweep failure indices;
- moment and internal-face-flux reconstruction.
- specular/diffuse wall reflection, partial-face inlet integration, and
  reflecting-boundary source iteration.

Run with:

```bash
bash tests/011_fluid/J02_neutral_sn_transport_2Drz/run.sh
```

Application-scale B0/ION validation is provided by the J03 application tests.
Positivity limiting under more strongly absorbing coupled cases remains future
coverage.
