# 2D RZ TMz CPML Wave-Packet Reference Test

[简体中文](README.zh-CN.md)

This test follows `case_cpml_2d_rz_tez_wavepacket_ref` and compares a compact CPML domain with a longer reference domain using a finite-width wave packet.

- Coordinates are 2D cylindrical `r-z`.
- TM mode.
- Field components are `Er, Ez, Ha`.
- Default active region of `136 x 136` cells.
- Default CPML uses `npml = 14`.
- Default central wavelength `lambda0 = 12 mm`.
- CFL：`0.8`
- `450` time steps by default.
- Propagation directions `z_plus`, `z_minus`, and `r_plus`.

The axis at `r=0` has no inner radial CPML, so the test omits `r_minus`. The `z_*` probes record `Er`, and the `r_plus` probe records `Ez`.

Run with defaults.

```bash
./run.sh
```

To specify an output directory, use the following command.

```bash
./run.sh 12 output_lambda12mm_npml14 14 3 0.02 3.5 0.012
```

The current default results are stored in `output_lambda12mm_npml14/`.

| case | late reflection error | final interior energy |
|---|---:|---:|
| `z_plus` | -47.78 dB | -23.17 dB |
| `z_minus` | -49.18 dB | -23.17 dB |
| `r_plus` | -48.61 dB | -24.03 dB |
