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

One way to build HYPRE from source is to download it from
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

Here, `-j 8` requests up to eight concurrent compilation jobs. After the
installation is complete, enter the example directory and specify the
HYPRE installation prefix (replace the placeholder with its absolute path):

```bash
cd ../../algoplasma/examples/001_two_stream_2d
HYPRE_ROOT=/absolute/path/to/hypre/src/hypre bash run.sh
```

`HYPRE_ROOT` must contain `include/HYPRE.h` and `lib/libHYPRE.*`.
The current `run.sh` defaults to `/opt/hypre-3.1.0`; it does not
automatically select the sibling source-build installation.

For the reference WSL installation, run the following from the AlgoPlasma
repository root:

```bash
cd examples/001_two_stream_2d
HYPRE_ROOT=/opt/hypre-3.1.0 \
OMP_NUM_THREADS=8 OMP_PROC_BIND=close OMP_PLACES=cores \
bash run.sh
```

`run.sh` configures and builds the example with CMake, runs the simulation,
and calls `plot.py`. Its default OpenMP settings are eight threads,
`OMP_PROC_BIND=close`, and `OMP_PLACES=cores`; environment variables
can override these settings.

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

These correspond to the phase-space and field-growth/energy figures
(Figures 4 and 5) in the manuscript. To regenerate the figures from existing
simulation output, run `python3 plot.py` from this example directory.

## Reproducibility

This example accompanies the manuscript describing AlgoPlasma `v1.0.1`.

The reference run was checked on 4 October 2026 using the `develop`
working tree based on commit
`105fe3cc5740a852ccb96b74c339a152272b058a`, with the default HYPRE path
in `run.sh` adjusted to `/opt/hypre-3.1.0`. The source commit and
environment recorded here identify the provenance of the reference
results below.

### Reference Environment

| Item | Reference configuration |
| --- | --- |
| Operating system | Ubuntu 22.04.5 LTS under WSL2 |
| Linux kernel | 5.10.16.3-microsoft-standard-WSL2 |
| CPU reported by WSL | AMD EPYC 7502 32-Core Processor; 64 logical CPUs |
| WSL-visible memory | Approximately 62.7 GiB |
| GNU Fortran / GCC | 11.4.0 |
| CMake | 3.22.1 |
| MPI implementation | Open MPI 4.1.2 |
| HYPRE | 3.1.0; double-precision real arithmetic; MPI and OpenMP enabled |
| Python | 3.10.12 |
| NumPy / SciPy / Matplotlib | 2.2.6 / 1.15.3 / 3.10.6 |
| Execution configuration | One MPI rank; eight OpenMP threads; close binding to cores |

The GNU Fortran build uses `-cpp -DUSE_HDF5=0 -O3 -fdefault-real-8 -fopenmp`.
HDF5 output is disabled for this example, so HDF5 is not required to run it.
These are the versions tested in this run, not a claim of compatibility with
every other compiler or dependency version.

### Initialization and Reference Results

The seed base is `random_seed_base = 20260810` in
`src/case_parameters.f90`. The Fortran random-number generator is
initialized in `src/two_stream_case.f90` with
`seed_values(j) = 20260810 + 104729*j`, for `j = 1, ..., nseed`;
`nseed` is obtained from `random_seed(size=nseed)`.

The run completed all 800 steps, reaching `omega_pe*t = 40`.
Diagnostics in `plot.py` gave the following reference values:

| Quantity | Reference value |
| --- | --- |
| PIC growth rate, gamma_PIC / omega_pe | 0.2603342007 |
| Theoretical growth rate, gamma_theory / omega_pe | 0.2615993751 |
| Log-amplitude fit R-squared | 0.9835732215 |
| Maximum recorded absolute total-energy error, percent | 0.01825332345 |

The growth-rate fit uses `10 <= omega_pe*t <= 19`. The energy error is
`100*abs((W(t)-W(0))/W(0))`, evaluated at the stored diagnostics;
`W` is the sum of electrostatic field energy and time-centered particle
kinetic energy. Rounded to manuscript precision, these values are
`0.2603`, `0.2616`, `0.9836`, and `0.0183%`, respectively.

These are numerical reference values from one configuration, not
cross-platform pass/fail tolerances. Random-number implementations and
floating-point operation order can differ across toolchains or thread
configurations; byte-identical output files or PNGs are not guaranteed.

### Runtime and Memory

The complete configure/build/run/plot workflow took **39.57 seconds** in
the reference run, including the initial example build. This is a
machine-specific observation, not the simulation-only runtime.

| Simulation-only measurement | Reference value |
| --- | --- |
| Wall-clock time, including diagnostic output | 28.45 seconds |
| Peak resident memory (maximum RSS) | 64,928 KiB (approximately 63.41 MiB) |

The simulation-only measurement used one MPI rank and eight OpenMP threads
with the reference configuration above. It includes initialization and
diagnostic output, but excludes compilation and Python plotting.

To repeat the measurement after building the example, run GNU `time` from
this example directory:

```bash
cd output
OMP_NUM_THREADS=8 OMP_PROC_BIND=close OMP_PLACES=cores \
  /usr/bin/time -v -o resources.log ../build/two_stream_2d
```

This reruns the simulation and overwrites its existing diagnostic output.
The log, `output/resources.log`, records elapsed wall-clock time and maximum
resident set size (reported as `kbytes`, in KiB on Linux). These measurements
are observations from this machine, not performance guarantees.

## Cleanup

To remove the build files, simulation output, and generated figures and return
the example to its initial state, run:

```bash
./clean.sh
```
