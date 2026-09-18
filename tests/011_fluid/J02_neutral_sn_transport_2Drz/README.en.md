# J02 neutral SN transport tests

These deterministic tests exercise the PIC-independent SN preprocessor:

- two-dimensional velocity-space quadrature and the `midpoint`/
  `gauss-chebyshev` alias;
- cylindrical geometry and P1-DG streaming terms;
- reservoir Maxwellian and MC crossing-sampled inlet definitions;
- prescribed-flux normalization and detailed error reporting;
- cell-moment and conservative face-flux reconstruction;
- specular/diffuse wall reflection, partial-face inlets, and source iteration.

Run from the repository root:

```bash
bash tests/011_fluid/J02_neutral_sn_transport_2Drz/run.sh
```

Generated objects, executables, and logs are intentionally visible under
`build/`. Remove them with:

```bash
bash tests/011_fluid/J02_neutral_sn_transport_2Drz/clean.sh
```
