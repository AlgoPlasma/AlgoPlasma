# G02_MCC_network tests and validation

[中文](README.zh-CN.md) | [English](README.en.md)

CSV preparation: [blank templates, original examples and checker](templates/README.en.md).

These tests ask whether inputs are read correctly and whether collisions follow the specified model.
For a first introduction, read the [collision-box tutorial](examples/collision_box/README.en.md):
it explains cooling, the three plots and what `PASS` means.

The test data are synthetic. Passing these software checks does not supply the physical model or measured data needed for a real gas study.

## Where are the sources and examples?

Functional sources are in [`G_Collision/G02_MCC_network`](../../../G_Collision/G02_MCC_network/README.en.md). This test directory contains:

- `examples/`: the collision box and complete C++, Fortran and MPI callers.
- `data/`: synthetic models and invalid-input fixtures; `cpp/` and `fortran/`: regression tests.
- `CMakeLists.txt`, `cmake/` and `run.sh`: build, installation and test entry points.
- `templates/blank/`: blank CSV templates; `tools/validate_model.cpp`: the model-package checker.

The `fortran/` directory here contains Fortran test programs. The library interface is in
`G_Collision/G02_MCC_network/fortran_interface/`; C++ implementations and headers are directly in the G02 root.

See the [module guide](../../../G_Collision/G02_MCC_network/README.en.md#build-and-test) for build commands.
The default builds the library and tests. Add `-DG02_MCC_BUILD_TESTS=OFF` to build only the library using the same entry point.

## Run the default tests

Use a Linux/WSL terminal from the AlgoPlasma root.
You need CMake 3.20 or newer, a C++20 compiler, and C and Fortran compilers, such as GCC/gfortran:

```bash
bash tests/009_collision/G02_MCC_network/run.sh
```

The script builds in a temporary directory and uses CTest, CMake's test runner, to execute each test.
Look for `100% tests passed` and `PASS: G02_MCC_network build and ctest suite`.
A failure returns a nonzero status; use the failed test name to find its diagnostics.
Old plots do not establish that a new run passed.

The defaults also enable AddressSanitizer for memory errors and UndefinedBehaviorSanitizer for undefined behavior,
helping detect errors such as out-of-bounds access. MPI and OpenMP are disabled by default.

## What is being checked?

| Group | Meaning |
|---|---|
| Model package and interpolation | Correct file references, units and reactions; correct values between known table points |
| C01 and samplers | Correct probability sampling of collision times and channels |
| C02–C08 algorithms | Products, velocities and energy accounting consistent with each model |
| Batch and C/Fortran interfaces | Correct transfer of results across particle batches and language boundaries, with data preserved on failure |
| Collision box | Agreement of mean motion, temperature and collision counts with a simple theoretical model |
| Optional parallel tests | Correct IDs, exchanges and results when threads or processes cooperate |

## Enable parallel tests

MPI coordinates multiple processes; OpenMP shares work among CPU threads within a process.
With C++/Fortran MPI support and an OpenMP compiler, run the full suite:

```bash
cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_mcc_tests \
  -DCMAKE_BUILD_TYPE=Debug -DG02_MCC_ENABLE_MPI=ON -DG02_MCC_ENABLE_OPENMP=ON
cmake --build /tmp/g02_mcc_tests -j 4
ctest --test-dir /tmp/g02_mcc_tests --output-on-failure
```

## Zero-dimensional collision box

`tests/009_collision/G02_MCC_network/examples/collision_box/` follows A particles colliding elastically with a fixed B background of equal-mass particles.
Each velocity has three components; zero-dimensional means no spatial variation.

| Control | Expected outcome |
|---|---|
| Hot A and cold B | Mean drift weakens, temperature approaches B, and counts follow the constant-rate Poisson prediction |
| Zero background density | No collisions; initial velocities preserved |
| Zero time step | No elapsed time; states unchanged |
| A starts at B temperature with no drift | Statistics remain near equilibrium, allowing sampling fluctuations |
| Different step sizes, same total time | Each run passes the same statistical reference; individual particle results need not match |
| Different channel samplers | Alternative sampling implementations follow the same statistics |
| Serial versus OpenMP | Identical particle results and collision counts for the same seed and settings |

Velocity moments are statistics such as mean velocity and mean squared speed.
Relaxation describes approaching equilibrium.
The program compares these statistics with theory and balances momentum and energy including the background.
It tests the final Maxwell distribution only near equilibrium; shorter runs skip unreached checkpoints.
Any executed check that fails returns a nonzero status.

Run it manually to generate CSV files and plots:

```bash
bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh
```

Results go to the example's ignored `results/` directory. Plotting requires Python 3 and Matplotlib; neither the C++ validation nor CTest depends on plotting. See the [example README](examples/collision_box/README.en.md) for parameters, formulas and output details.

## Benchmark

The benchmark measures computing speed; the tests above establish the physical checks.

The same test project builds `bench_batch`. Its arguments are particle count, channel count, measured repeats and OpenMP threads; for example, `/tmp/g02_mcc_tests/bench_batch 1000000 100 7 8`.
