# 3D Cartesian CPML Plane-Wave Packet Reference Test

[简体中文](README.zh-CN.md)

This test complements `case_cpml_2d_rz_tez_wavepacket_ref`. It uses 3D Cartesian coordinates and starts from a transversely uniform plane-wave packet to measure how well CPML absorbs plane waves.

Both the FDTD and CPML updates use the project's Fortran Maxwell routines.

- `../../../E_Maxwell/E03_Maxwell_3Dxyz/mod_E03_fdtd_3d_cartesian.f90`
- `../../../E_Maxwell/E03_Maxwell_3Dxyz/mod_E03_cpml_3d_cartesian.f90`

Test setup

- Coordinates are 3D Cartesian `x-y-z`.
- Field components are `Ex, Ey, Ez, Hx, Hy, Hz`.
- The default central active region spans `136 cells` in the propagation direction and `8 x 8 cells` transversely.
- The length along the propagation direction can be set at runtime. One run below extends it to `300 cells`.
- Default CPML uses `npml = 12`.
- The default total compact grid spans `160 cells` in the propagation direction and `8 x 8 cells` transversely.
- The default large reference domain is extended only in the propagation direction, giving `136 + 2*200 + 2*20 = 576` cells longitudinally and `8 x 8 cells` transversely.
- `dx = dy = dz = 1 mm`
- `dt = 0.99 / (c * sqrt(1/dx^2 + 1/dy^2 + 1/dz^2))`
- `450` time steps by default.
- Default central wavelength `lambda0 = 12 mm`.
- Packet envelope width `sigma_long = 18 mm`.
- The initial field is a transversely uniform plane-wave packet with a Gaussian envelope. There is no continuous point source.
- By default, the packet center is `36 mm` from the rear CPML's inner edge and `100 mm` from the absorbing end's inner CPML edge.
- Directions `x_plus`, `x_minus`, `y_plus`, `y_minus`, `z_plus`, and `z_minus`.
- Transverse boundaries use periodic copying.
- Boundaries along the propagation direction use CPML.

Comparison method

- The compact and large reference domains start from the same plane-wave packet.
- A probe behind the packet records the corresponding electric field component.
  - `x_*` records `Ey`.
  - `y_*` records `Ez`.
  - `z_*` records `Ex`.
- `Error_dB = 20 log10(abs(compact-reference)/max(abs(reference)))`
- The default `late reflection error` is the maximum error over `n = 260..450`. The longer-domain test uses `n = 800..1200`.
- The final interior energy is also recorded in dB relative to the initial interior energy.

Run with defaults.

```bash
./run.sh
```

To specify parameters, use the following command.

```bash
./run.sh 12 output_lambda12mm_npml12 12 3 0.02 3.5 0.012
```

Example with a longer domain in the propagation direction

```bash
./run.sh 12 output_lambda12mm_npml12_long300 12 3 0.02 3.5 0.012 all 18 300 36 1200 800 500
```

The interior spans `300 cells` in the propagation direction. The packet center stays `36 mm` from the rear CPML, which leaves about `264 mm` to the absorbing end's inner CPML edge. The run takes `1200` steps, measures late reflection starting at `n = 800`, and extends the reference domain by `500 cells`.

Output files

- `metrics.dat`
- `*_probe.dat`
- `probe_compare.png`
- `probe_error_db.png`
- `field_slices_*.png`
- `field_slice_*.dat`

Recorded results

Results for the default `lambda0 = 12 mm, npml = 12, kappa_max = 3, alpha_max = 0.02, m = 3.5, R0 = 0.012` are stored in `output_lambda12mm_npml12/`.

| case | late reflection error | final interior energy |
|---|---:|---:|
| `x_plus` | -43.45 dB | -49.41 dB |
| `x_minus` | -44.82 dB | -47.41 dB |
| `y_plus` | -43.45 dB | -49.41 dB |
| `y_minus` | -44.82 dB | -47.41 dB |
| `z_plus` | -43.45 dB | -49.41 dB |
| `z_minus` | -44.82 dB | -47.41 dB |

Results after increasing CPML thickness to `npml = 24` and keeping the other parameters fixed are stored in `output_lambda12mm_npml24/`.

| case | late reflection error | final interior energy |
|---|---:|---:|
| `x_plus` | -71.38 dB | -48.51 dB |
| `x_minus` | -76.83 dB | -49.53 dB |
| `y_plus` | -71.38 dB | -48.51 dB |
| `y_minus` | -76.83 dB | -49.53 dB |
| `z_plus` | -71.38 dB | -48.51 dB |
| `z_minus` | -76.83 dB | -49.53 dB |

Results for the longer domain with `lambda0 = 12 mm, npml = 12` are stored in `output_lambda12mm_npml12_long300/`.

| case | late reflection error | final interior energy |
|---|---:|---:|
| `x_plus` | -42.54 dB | -54.59 dB |
| `x_minus` | -46.19 dB | -62.26 dB |
| `y_plus` | -42.54 dB | -54.59 dB |
| `y_minus` | -46.19 dB | -62.26 dB |
| `z_plus` | -42.54 dB | -54.59 dB |
| `z_minus` | -46.19 dB | -62.26 dB |

Extending the original `136 cells` domain changed the worst late reflection from about `-43.45 dB` to about `-42.54 dB`, with essentially no improvement. This suggests that the main limitation at `npml = 12` is the discrete profile of the 12-layer CPML itself. Giving the initial packet more distance from the absorbing end did little to help. Increasing the thickness to `24` layers lowered the worst late reflection to about `-71 dB`.

Troubleshooting notes

- To speed up early runs, the interior along the propagation direction was shortened to `72 cells`. The packet center was only `24 mm` from the rear CPML. At `sigma_long = 18 mm` the packet tail still had about `17%` of its amplitude at the inner CPML edge, which strongly contaminated the reflection measurement.
- Extending the interior to `136 cells` improved the result at `npml = 12` from about `-20 dB` to about `-31 dB`.
- A parameter sweep showed that `R0 = 1e-6/1e-8` made the 12-layer discrete CPML too strong. The large `sigma` caused a discrete mismatch at the interface. With `R0 = 0.012, kappa_max = 3, alpha_max = 0.02, m = 3.5`, `npml = 12` reached about `-43 dB`.

The initial poor absorption was mainly due to the packet being too close to the CPML and the `sigma` profile being too strong.

Notes

- Python handles plotting only. The Fortran routines perform the FDTD and CPML updates.
- A transversely uniform plane-wave packet allows a narrow transverse grid. This isolates plane-wave absorption along the propagation direction and keeps the 3D reference solution practical to compute.
