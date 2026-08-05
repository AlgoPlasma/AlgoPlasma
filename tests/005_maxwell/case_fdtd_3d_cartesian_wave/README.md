# 3D Cartesian Wave Visualization Case

This is a Python-only visualization case. `run.sh` runs
`fdtd_3d_cartesian_wave.py` and generates the main triple-slice figure, while
the directory also keeps a single-plane reference figure:

- `fdtd_3d_cartesian_ez_slices.png`
- `fdtd_3d_cartesian_wave_slice.png`

It does not compile or call the `E_Maxwell` Fortran routines. The interior
six-component curl update matches E03 `sub_E03_fdtd_3d_cartesian_H/E`; the
centered `Ez` soft source, RMS accumulation figure, and sponge boundary are
Python-side visualization settings.

Run:

```bash
bash run.sh
```
