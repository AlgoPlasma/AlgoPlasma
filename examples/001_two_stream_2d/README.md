# Two-dimensional electrostatic two-stream instability

This compact 2D3V PIC example assembles AlgoPlasma components into an
application-specific time loop. It uses `I01` for particle loading, `B01`
for charge deposition, `D02`/`D05`/`D06` for the electrostatic field,
`C01` for field interpolation, `A01` for velocity advancement, and
`F02`/`F04` for particle and field output. The driver retains the position
update, periodic particle boundaries, and execution order.

The normalized domain is `64 x 64`, with a `64 x 64` grid and two electron
beams drifting at `+/- 3 v_te`. Here `v_te = sqrt(k_B T_e / m_e)` is the
one-dimensional standard deviation of each Maxwellian beam. Each beam
contains 64 particles per cell. Counter-streaming beam pairs provide a
symmetry-preserving quiet start.
The time step is `0.05 / omega_pe`, and the `(2,1)` density mode is seeded
with amplitude 0.005.

## Build and run

Requirements are GNU Fortran, CMake, MPI, HYPRE 3.1 or later, NumPy,
SciPy, and Matplotlib. Before the first build, change only `HYPRE_ROOT`
near the top of `CMakeLists.txt` to the local HYPRE installation prefix.
From WSL or Linux:

```bash
cd example/two_stream_2d
bash run.sh
```

The example currently runs on one MPI rank. In addition to the initial and
first steps, field snapshots are written every five steps and particle
snapshots every fifty steps under `output/`.
The application driver is `src/main.f90`; details specific to this case,
such as array allocation and periodic ghost cells, are kept in
`src/two_stream_case.f90` so that the PIC loop remains explicit and short.
At the end of the run, `plot.py` creates the two publication figures under
`figures/`:

- `fig1_phase_space_evolution.png`
- `fig2_field_growth_energy.png`

To remove the generated build, simulation output, and figure files and
return the example to its initial state, run:

```bash
bash clean.sh
```

