# G02_MCC_network tests and validation

[中文](README.zh-CN.md) | [English](README.en.md)

Tests check input parsing and collision behavior under specified models. Begin with the [collision box](examples/collision_box/README.en.md), then the [module guide](../../../G_Collision/G02_MCC_network/README.en.md). User input is described in the [CSV format guide](../../../docs/source/rst_files/G_Collision/G02_MCC_network/csv_format.rst).

## Layout and data

- Functional sources are in `G_Collision/G02_MCC_network/`; `cpp/` contains C++ regression tests and `examples/` C++ callers and collision boxes.
- `CMakeLists.txt`, `cmake/` and `run.sh` provide build/install/test entry points; `tools/validate_model.cpp` checks user-created model directories.
- No CSV data files or blank tables are shipped. C++ fixture builders generate minimal synthetic CSV packages at runtime. Shared packages live under build `generated_models/{demo_binary,demo_three_body,collision_box_elastic}`.

Synthetic masses, cross sections and rates validate software, not real-gas research. Installation does not ship fixtures.

## Default suite

From the repository root in Linux/WSL, with CMake 3.20 and a C++20 compiler:

```bash
bash tests/009_collision/G02_MCC_network/run.sh
```

The script builds in a temporary directory and uses CTest, which schedules fixture generation automatically. Look for `100% tests passed` and `PASS: G02_MCC_network build and ctest suite`. Failures return nonzero; read the failed test's diagnostics. The default script enables AddressSanitizer/UndefinedBehaviorSanitizer. MPI/OpenMP are off by default.

| Check | Coverage |
|---|---|
| Packages and interpolation | CSV structure, references, units, reaction constraints and interpolated values |
| RNG and C01 | Stream separation across events/purposes, waiting/channel probabilities and multi-collision mean/variance |
| C02–C08 | Products, velocities, energy and charge ledgers |
| Batching | Workspace reuse, child IDs, state changes, commit and failure preservation |
| Collision box | Mean velocity, temperature, collision counts and final distribution against simple theory |
| Optional CPU parallelism | Serial/OpenMP agreement, MPI global IDs and error agreement |

Build manually with parallel paths:

```bash
cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_mcc_tests   -DCMAKE_BUILD_TYPE=Debug -DG02_MCC_ENABLE_MPI=ON -DG02_MCC_ENABLE_OPENMP=ON
cmake --build /tmp/g02_mcc_tests -j 4
ctest --test-dir /tmp/g02_mcc_tests --output-on-failure
```

Use `-DG02_MCC_BUILD_TESTS=OFF` for the library only. MPI requires C++ MPI support; OpenMP requires compiler support.

## Manual generation and validation

CTest generates shared packages automatically. Before manually running tests/callers or the MPI collision box that accept a package path:

```bash
/tmp/g02_mcc_tests/g02_generate_test_data /tmp/g02_mcc_tests/generated_models
/tmp/g02_mcc_tests/g02_validate_model /tmp/g02_mcc_tests/generated_models/collision_box_elastic
```

Pass your own directory to check user data. PASS covers parsing and implemented constraints, not physical validity.

## Collision box and benchmark

The box tracks A against a fixed equal-mass B gas. Velocities have three components; zero-dimensional means no spatial variation. Zero density/dt preserves state. Near equilibrium, check the Maxwell distribution. Different dt values compare statistics at equal total time. OpenMP runs can compare particles directly with serial results.

```bash
bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh
```

Without `--model`, the executable generates a process-private temporary synthetic package and cleans it on exit. With `--model DIR`, it loads that directory only and validates the box's required single-channel equal-mass model. Plots need Python 3/Matplotlib; C++ checks and CTest do not.

`bench_batch` arguments are particles, channels, measured repeats, OpenMP threads and sampler:

```bash
/tmp/g02_mcc_tests/bench_batch 1000000 100 7 8 prefix
```

Benchmarks measure elapsed time; tests check statistics and physical constraints. See [PERFORMANCE.md](PERFORMANCE.md) for parallel integration.

## Verification references

[Probability checks, binary kinematics and the box derivation](../../../docs/source/rst_files/G_Collision/G02_MCC_network/references.rst) are mapped to individual tests. C01 checks the exponential clock and Poisson thinning; the box uses analytic moments of its specified equal-mass, constant-rate model, not fits to paper data. [Parodi–Petronio (2025)](https://doi.org/10.1063/5.0241527) is a reference for separate-module verification against analytical results; this suite does not reproduce its seven cases. Synthetic inputs and tolerances are defined by these tests.
