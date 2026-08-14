# Two-dimensional electrostatic two-stream instability

[中文](README.zh-CN.md) | [English](README.md)

This compact 2D3V particle-in-cell (PIC) example assembles AlgoPlasma
components into an application-specific time loop. It uses `I01` for
particle loading, `B01` for charge deposition, `D02`/`D05`/`D06` for the
electrostatic field solution, `C01` for field interpolation, `A01` for
velocity advancement, and `F02`/`F04` for particle and field output. The
driver retains control of the position update, periodic particle boundaries,
and execution order.

The normalized periodic domain is `64 x 64`, with a `64 x 64` grid and two
electron beams drifting at `+/- 3 v_te`. Here,
`v_te = sqrt(k_B T_e / m_e)` is the one-dimensional standard deviation of
each Maxwellian beam. Each beam contains 64 particles per cell. The second
beam duplicates the particle positions of the first and reverses all velocity
components, providing a symmetry-preserving quiet start. The time step is
`0.05 / omega_pe`, and the simulation advances for 800 steps to
`omega_pe t = 40`. A longitudinal particle displacement with amplitude
0.005 seeds the `(2,1)` mode, corresponding to a first-order density
perturbation of 0.5%.

## Build and run

Requirements are GNU Fortran, CMake, MPI, HYPRE 3.1 or later, NumPy,
SciPy, and Matplotlib. Before the first build, change `HYPRE_ROOT` near the
top of `CMakeLists.txt` to the local HYPRE installation prefix. From WSL or
Linux, run:

```bash
cd examples/001_two_stream_2d
bash run.sh
```

The example currently runs on one MPI rank. In addition to the initial and
first steps, field snapshots are written every five steps and particle
snapshots every fifty steps under `output/`. The application driver is
`src/main.f90`; case-specific details, such as array allocation and periodic
ghost cells, are kept in `src/two_stream_case.f90` so that the PIC loop
remains explicit and short.

At the end of the run, `plot.py` creates two publication figures under
`figures/`:

- `fig1_phase_space_evolution.png`
- `fig2_field_growth_energy.png`

To remove the generated build, simulation output, and figure files and
return the example to its initial state, run:

```bash
bash clean.sh
```
