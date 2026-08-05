# 2D TE Circular-Wavefront Visualization Case

This is a Python-only visualization case. `run.sh` runs
`fdtd_2d_te_cylindrical_wave.py` and generates:

- `fdtd_2d_te_cylindrical_wave.png`

It does not compile or call the `E_Maxwell` Fortran routines. The interior Yee
update matches the 2D TEz reduction of E03 Cartesian FDTD (`d/dz = 0`, non-zero
`Ex`, `Ey`, `Hz`). The centered source and first-order Mur boundary are
Python-side visualization settings, and this is not the E01 cylindrical
coordinate `r-z` TEz routine.

Run:

```bash
bash run.sh
```
