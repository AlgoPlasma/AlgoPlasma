# FDTD Pulse Long-Run Stability Tests

This directory tests stability with a short pulse followed by long no-source propagation.
It is separate from MMS accuracy tests.

## Covered Cases

- `test_pulse_2d_rz_tez.f90`
- `test_pulse_2d_rz_tmz.f90`
- `test_pulse_3d_cartesian.f90`
- `test_pulse_3d_cyl_m0.f90`
- `test_pulse_3d_cyl_m1.f90`

## Test Setup

- Periodic boundaries are used in periodic directions (`z` and `phi` by case).
- 3D Cartesian uses periodic boundaries in `x/y/z`.
- No PML/ABC.
- Source is enabled only for the first `Npulse` steps, then fully disabled.
- Pulse envelope is smooth in time (`sin^2`) and localized in space (Gaussian).
- Source location avoids axis-special points (`i>=2`).
- `m=1` case uses a `cos(phi)` pulse compatible with mode `m=1`.

## Build / Run / Clean

Run (default: `Ntotal=20000`, `monitor_every=100`, `Npulse=60`, `pulse_amp=1e-4`):

```bash
bash make.sh
bash run.sh
```

Run (custom):

```bash
bash run.sh 50000 200 80 5e-5
```

Argument order:

`Ntotal monitor_every Npulse pulse_amp`

Clean: `bash clean.sh`

## Outputs

- Per-case logs: `logs/*.log`
- Summary file: `pulse_longrun_summary.csv`

Summary columns:

`case_name, CFL, Npulse, Ntotal, final_energy_ratio, post_pulse_growth_rate, result`

Definitions:

- `final_energy_ratio = E_final / E_at_pulse_end`
- `post_pulse_growth_rate = log(E_final/E_at_pulse_end) / (t_final - t_pulse_end)`

## Log Format

Header:

```text
# step,time,pulse_on,max_abs_E,max_abs_H,total_energy,axis_band_max,first_ring_max,i0_active_max,i1_first_ring_max,axis_near_Ez_max,axis_near_Hz_max
```

Sample row:

```text
1200,2.316783E+01,0,5.270281E-05,1.242792E-04,7.502942E-09,3.808065E-05,3.724863E-05,3.808065E-05,3.724863E-05,3.612198E-06,1.022900E-05
```

## Result Criteria

- `stable`: bounded after pulse end, no persistent growth
- `marginal`: no blow-up but slow drift exists
- `unstable`: NaN/Inf or clear persistent growth

## 2D RZ TMz Sensitivity Note

- With `CFL=0.8, Ntotal=20000, Npulse=40, pulse_amp=1e-4`, `monitor_every=200`
  can occasionally classify as `marginal`.
- For the same evolution, `final_energy_ratio` and `post_pulse_growth_rate` stay small
  (about `1.0069` and `6.47e-05`), and `monitor_every=100/400` gives `stable`.
- This `marginal` result is mainly a sampling-window effect, not axis bias.
  Peaks at `i=0` and first ring `i=1` are nearly synchronized and close in amplitude.

## 3D Cylindrical Notes

- Focus on `axis_band` and `first_ring`.
- For `m=1`, axis inactive DOFs are not treated as divergence sources.
- For `m=1`, the outer `Ephi` ghost is filled consistently with the
  radial `r*Ephi` derivative used by the cylindrical `Hz` update.
- This test targets slow instability after many wrap-arounds, not pulse decay only.

## File List

Directory:

- `tests/005_maxwell/case_fdtd_pulse_longrun`

Added or updated files:

- `pulse_common.f90`
- `test_pulse_2d_rz_tez.f90`
- `test_pulse_2d_rz_tmz.f90`
- `test_pulse_3d_cartesian.f90`
- `test_pulse_3d_cyl_m0.f90`
- `test_pulse_3d_cyl_m1.f90`
- `make.sh`
- `run.sh`
- `clean.sh`
- `README.md`
