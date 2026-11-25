# 3D Cylindrical CPML Wave-Packet Reference Test

[简体中文](README.zh-CN.md)

This test follows the existing wave-packet reference method to check CPML absorption in the `z` direction in 3D cylindrical coordinates.

- Coordinates are 3D cylindrical `r-phi-z`.
- Mode `m=0 TM01`.
- Main field components `Er, Ez, Hphi`.
- Default active length of `136 cells` along the propagation direction.
- Default radial grid of `48 cells`.
- Default azimuthal grid of `4 cells`.
- Default CPML uses `npml = 12`.
- Propagation directions `z_plus` and `z_minus`.

This test covers the CPML on the two `z` ends. The initial packet is generated numerically in the longer reference domain using a `TM01` soft source. Once the packet leaves the source region, a compact window is cut out to give both domains the same initial field. The figures show `sqrt(r) Ez` to avoid overemphasizing axis cells with zero physical volume. Probes and error calculations use the original `Ez` values.

Run with defaults.

```bash
./run.sh
```

To specify an output directory, use the following command.

```bash
./run.sh 18 output_lambda18mm_npml12 12 3 0.02 3.5 0.012
```

Generate a GIF with one frame every 10 steps.

```bash
./run.sh 18 output_lambda18mm_npml12_gif 12 3 0.02 3.5 0.012 all 18 136 36 450 260 200 10
```

The current default results are stored in `output_lambda18mm_npml12/`.

| case | late reflection error | final interior energy |
|---|---:|---:|
| `z_plus` | -35.24 dB | -39.62 dB |
| `z_minus` | -36.38 dB | -36.04 dB |
