# 3D Cylindrical Waveguide Mode Visualization Case

This is a Python-only visualization case. `run.sh` runs
`fdtd_3d_cylindrical_m0_wave.py` and generates:

- `fdtd_3d_cylindrical_waveguide_mode.png`

It does not compile or call the `E_Maxwell` Fortran routines. The script
advances a scalar `Ez` wave equation with cylindrical metric terms, axis
closure, and a PEC outer wall. It is not a pointwise six-component equivalent
of E02 `sub_E02_fdtd_3d_cylindrical_H/E`; use
`case_fdtd_cyl_m0_equivalence` for strict E02 versus `m=0` consistency.

Run:

```bash
bash run.sh
```
