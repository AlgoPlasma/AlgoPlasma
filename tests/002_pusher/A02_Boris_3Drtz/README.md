# A02_Boris_3Drtz Test

[中文](README.zh-CN.md) | [English](README.md)

This directory provides an independent test for `A_Pusher/A02_Boris_3Drtz`, the non-relativistic Boris particle pusher in 3D cylindrical coordinates. The test builds a small Fortran driver, runs several single-particle analytic cases, and converts the cylindrical numerical position and velocity back to Cartesian coordinates for direct comparison with reference solutions.

## Test Cases

The entry point is `source_f90/main.f90`, which runs four cases:

| Output file | Case | What it checks |
| --- | --- | --- |
| `build/case01_gyro.dat` | Gyromotion in a magnetic field | Checks that the cylindrical pusher reproduces the Cartesian analytic gyro orbit and velocity, including conservation of velocity magnitude squared. |
| `build/case02_Eonly.dat` | Acceleration in an electric field | Checks that electric-field components transformed at the particle position produce the correct Cartesian position and velocity. |
| `build/case03_ExB.dat` | Perpendicular electric and magnetic fields | Checks gyromotion combined with `E x B` drift in the cylindrical update. |
| `build/case04_ExB_drift.dat` | Pure `E x B` drift | Checks drift velocity and trajectory without gyration. |

When the executable runs, each case prints the maximum velocity error and maximum position error. The data files store numerical position and velocity in Cartesian components, so they can be compared directly against the analytic reference columns.

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
cd tests/002_pusher/A02_Boris_3Drtz
bash clean.sh
bash make.sh
bash run.sh
```

`make.sh` creates `build/` and builds `build/a.out`. `run.sh` enters `build/`, runs the executable, and generates:

- `build/case01_gyro.dat`
- `build/case02_Eonly.dat`
- `build/case03_ExB.dat`
- `build/case04_ExB_drift.dat`

If `make.sh` reports that `build` already exists, run `bash clean.sh` first.

## Plot

Run:

```bash
bash plot.sh
```

The plotting script reads the data files under `build/` and saves figures to `figs_cases/`. It currently writes:

- `figs_cases/case01_gyro_traj_xy.png`
- `figs_cases/case01_gyro_v2_t.png`
- `figs_cases/case02_Eonly_x_t.png`
- `figs_cases/case03_ExB_traj_xy.png`
- `figs_cases/case04_drift_traj_xy.png`

## Clean

Run:

```bash
bash clean.sh
```

This removes:

- `build/`
- `figs_cases/`
