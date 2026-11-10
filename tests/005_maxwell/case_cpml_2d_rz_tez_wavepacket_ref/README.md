# 2D RZ TEz CPML Wave-Packet Reference Test

[简体中文](README.zh-CN.md)

This test measures how well the TEz CPML absorbs a finite-width electromagnetic wave packet in 2D cylindrical `r-z` coordinates.

Both the FDTD and CPML updates use the project's Fortran Maxwell routines.

- `../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tez.f90`
- `../../../E_Maxwell/E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tez.f90`

Python handles plotting and GIF generation.

## Current Setup

- Coordinates are 2D cylindrical `r-z`.
- TE mode.
- Field components are `Ephi, Hr, Hz`.
- Central active region of `136 x 136` cells.
- Total compact grid of `160 x 160` cells.
- Large reference grid of `568 x 576` cells.
- `dr = dz = 1 mm`
- `dt = 2.335067793 ps`
- Compact-domain CPML uses `npml = 12`.
- Reference-domain CPML uses `npml_ref = 20`.
- Central wavelength `lambda0 = 12 mm`.
- Packet envelope widths `sigma_long = 18 mm, sigma_trans = 22 mm`.
- The initial field is a finite-width electromagnetic wave packet with a Gaussian envelope. There is no continuous source.
- `450` time steps.
- late gate：`260`
- Static snapshots at `0, 150, 300, 450`.
- Full `Ephi` GIF animation with one frame every `10` steps.

CPML parameters

```text
kappa_max = 3
alpha_max = 0.02
m         = 3.5
R0        = 0.012
```

Four propagation directions

- `z_plus` propagates along `+z`.
- `z_minus` propagates along `-z`.
- `r_plus` propagates along `+r`.
- `r_minus` propagates along `-r`.

The probe sits behind the packet and records `Ephi`.

| case | probe index `(r,z)` |
|---|---:|
| `z_plus` | `(80, 36)` |
| `z_minus` | `(80, 124)` |
| `r_plus` | `(36, 80)` |
| `r_minus` | `(124, 80)` |

## Error Definition

Let `Ecompact` be the compact-domain result and `Eref` the large reference-domain result. The error is defined as follows.

```text
Error_dB(n) = 20 log10( abs(Ecompact(n) - Eref(n)) / max(abs(Eref)) )
```

The `late reflection error` is the maximum `Error_dB` from `n = 260` through `n = 450`. This interval excludes the main incident wave at the probe and captures the residual wave reflected by the CPML.

## Current Results

The current results are stored in this directory.

```text
output_lambda12mm_npml12_weak_ephi_gif/
```

Results by direction

| case | late reflection error | final interior energy |
|---|---:|---:|
| `z_plus` | -49.18886 dB | -24.06556 dB |
| `z_minus` | -49.30641 dB | -24.06455 dB |
| `r_plus` | -49.12683 dB | -24.09557 dB |
| `r_minus` | -50.39389 dB | -24.09364 dB |

Worst late reflection

```text
worst late reflection = -49.12683 dB
```

## Reference Solution Check

To check whether `Eref` affects the results, the size of the large reference domain was varied while holding the other settings fixed.

```text
ref_extra = 200, 350, 500
```

All three runs gave the same `worst late reflection`.

```text
-49.12683 dB
```

After the late gate, the difference in `Eref` between reference domains is around `-300 dB`. The current large reference domain with `ref_extra = 200` is therefore sufficient.

## Output Files

The current directory retains the following files.

- `metrics.dat`
- `case_info.dat`
- `*_probe.dat`
- `probe_compare.png`
- `probe_error_db.png`
- `ephi_snapshots_*.png`
- `hz_snapshots_*.png`
- `ephi_animation_*.gif`
- `ephi_snapshot_*.dat`
- `hz_snapshot_*.dat`
- `ephi_final_*.dat`
- `hz_final_*.dat`

The four `Ephi` GIFs

- `ephi_animation_z_plus.gif`
- `ephi_animation_z_minus.gif`
- `ephi_animation_r_plus.gif`
- `ephi_animation_r_minus.gif`

## Run Commands

To generate the results currently retained, run the following command.

```bash
./run.sh 12 output_lambda12mm_npml12_weak_ephi_gif 12 3 0.02 3.5 0.012 all 136 36 450 260 200 0
```

The final argument `0` writes static snapshots only at `0,150,300,450`.

To regenerate the full GIF with a frame every 10 steps, run the following command in a temporary output directory.

```bash
./run.sh 12 output_lambda12mm_npml12_weak_ephi_gif_fullframes 12 3 0.02 3.5 0.012 all 136 36 450 260 200 10
```

Retain only the `ephi_animation_*.gif` files from that run.
