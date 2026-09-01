# Two-dimensional Electrostatic Two-stream Instability

[Chinese](README.zh-CN.md) | [English](README.md)

This compact 2D3V particle-in-cell (PIC) example demonstrates how
AlgoPlasma components can be assembled into an application-specific
time-advancement program. The example uses `I01` to load particles, `B01`
to deposit charge, `D02`, `D05`, and `D06` to solve the electrostatic field,
`C01` to interpolate grid fields to particle positions, `A01` to advance
particle velocities, and `F02` and `F04` to output particle and field data.
The main program controls the particle-position update, periodic particle
boundary conditions, and the execution order of the computational stages.

The normalized periodic domain has dimensions `64 x 64` and is discretized
on a `64 x 64` grid. It contains two electron beams with mean drift
velocities of `+/- 3 v_te`, where `v_te = sqrt(k_B T_e / m_e)` is the standard
deviation of each beam's Maxwellian distribution in one velocity direction.
Each beam contains 64 macroparticles per grid cell. The second beam copies
the particle positions of the first beam and reverses all velocity components,
forming a symmetric quiet start. The time step is `0.05 / omega_pe`, and the
program advances 800 steps to `omega_pe t = 40`. A longitudinal particle
displacement with an amplitude of 0.005 seeds the `(2,1)` mode, corresponding
to a 0.5% density perturbation to first order.

## Build and Run

The example requires GNU Fortran, CMake, MPI, HYPRE 3.1 or later, NumPy,
SciPy, and Matplotlib.

One tested way to install HYPRE is to download it from
<https://github.com/hypre-space/hypre> and place the `hypre/` directory next
to the `algoplasma/` directory:

```text
parent/
|-- algoplasma/
`-- hypre/
```

Then build and install HYPRE:

```bash
cd hypre/src
./configure
make install -j 8
```

Here, `-j 8` uses eight CPU cores for parallel compilation. After the
installation is complete, enter the example directory and run:

```bash
cd ../../algoplasma/examples/001_two_stream_2d
./run.sh
```

With the directory layout shown above, `run.sh` automatically uses the HYPRE
installation under `hypre/src/hypre`. If HYPRE is installed elsewhere, its
installation prefix can be specified explicitly:

```bash
HYPRE_ROOT=/path/to/hypre/src/hypre ./run.sh
```

If you are already in the AlgoPlasma repository root, simply run:

```bash
cd examples/001_two_stream_2d
bash run.sh
```

The current example runs with a single MPI process. Except at the initial
state and the first time step, field data are written to `output/` every five
steps and particle data every 50 steps. The application-level main program is
located in `src/main.f90`; example-specific details, including array allocation
and periodic ghost cells, are contained in `src/two_stream_case.f90`, keeping
the PIC loop in the main program clear and compact.

After the calculation, `plot.py` generates two publication figures in the
`figures/` directory:

- `fig1_phase_space_evolution.png`
- `fig2_field_growth_energy.png`

To remove the build files, simulation output, and generated figures and return
the example to its initial state, run:

```bash
./clean.sh
```
