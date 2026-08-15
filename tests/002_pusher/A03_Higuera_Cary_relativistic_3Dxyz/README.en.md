# A03_Higuera_Cary_relativistic_3Dxyz Test

[中文](README.zh-CN.md) | [English](README.en.md)

This directory provides an independent test for `A_Pusher/A03_Higuera_Cary_relativistic_3Dxyz`, the relativistic Higuera-Cary particle velocity pusher in 3D Cartesian coordinates. The test builds a small Fortran driver, runs relativistic gyro and high-Lorentz-factor `E x B` drift cases, and compares the numerical result against analytic references or a reference tolerance.

## Test Cases

The entry point is `source_f90/main.f90`, which runs three cases:

| Output file | Case | What it checks |
| --- | --- | --- |
| `build/case01_gyro.dat` | Relativistic gyromotion in a magnetic field | Uses an initial speed of `0.9c` and compares trajectory and velocity against the analytic solution with the relativistically corrected gyrofrequency. |
| `build/case02_exb_drift.dat` | Force-free `E x B` drift with `gamma = 20` | Sets `E = -v_y B_z` so the Lorentz force cancels, then checks that the particle keeps `x = 0` while drifting at constant velocity. |
| `build/case03_warpx_exb_drift.dat` | WarpX reference `E x B` drift test | Uses the positron charge-to-mass ratio and WarpX-style reference setup, then checks the final `|x| < 0.001` tolerance. |

When the executable runs, each case prints the maximum velocity error and maximum position error. The third case also prints `PASS` or `FAIL` for the WarpX reference tolerance.

## Requirements

Build and run requirements:

- POSIX shell or bash.
- GNU Fortran compiler `gfortran`.
- Python 3.
- Python packages `numpy` and `matplotlib`.

On Ubuntu/Debian, install the required tools with:

```bash
sudo apt update
sudo apt install -y gfortran python3 python3-pip
python3 -m pip install --user numpy matplotlib
```

To use a virtual environment instead:

```bash
python3 -m venv ~/.venv
source ~/.venv/bin/activate
pip install numpy matplotlib
```

## Build and Run

Run from this directory:

```bash
cd tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz
bash clean.sh
bash make.sh
bash run.sh
```

`make.sh` creates `build/` and builds `build/a.out`. `run.sh` enters `build/`, runs the executable, and generates:

- `build/case01_gyro.dat`
- `build/case02_exb_drift.dat`
- `build/case03_warpx_exb_drift.dat`

If `make.sh` reports that `build` already exists, run `bash clean.sh` first.

## Plot

Run:

```bash
bash plot.sh
```

The plotting script reads the first two case data files and saves figures to `figs_cases/`. It currently writes:

- `figs_cases/case01_gyro_traj_xy.png`
- `figs_cases/case01_gyro_v2_t.png`
- `figs_cases/case02_exb_drift_x_t.png`
- `figs_cases/case02_exb_drift_traj_xy.png`

`case03_warpx_exb_drift.dat` is currently used for terminal-side numerical checking and is not plotted by `plot.sh`.

## Clean

Run:

```bash
bash clean.sh
```

This removes:

- `build/`
- `figs_cases/`
