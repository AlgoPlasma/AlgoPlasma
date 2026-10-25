# G_Collision

[中文](README.zh-CN.md) | [English](README.en.md)

`G_Collision` contains AlgoPlasma's collision models: `G01_MCC`,
`G02_MCC_network`, and the neutral elastic collision library `G03_DSMC`.

## New to collision simulation?

Start with the [G02 collision-box tutorial](../tests/009_collision/G02_MCC_network/examples/collision_box/README.en.md):
watch hot particles cool through collisions with a colder gas.
It explains zero-dimensional modeling, temperature versus drift, random collision counts and the three plots.
Speed, kinetic energy and averages are enough to begin.
See the [G02 module guide](G02_MCC_network/README.en.md) for interfaces.

For DSMC from first principles, open `G_Collision → G03_DSMC` in the Sphinx documentation. The chapters cover physics, algorithms and a source walkthrough. See the [documentation source](../docs/source/rst_files/G_Collision/G03_DSMC.rst) and [module directory note](G03_DSMC/README.en.md).

## Subdirectories

- `G01_MCC`: null-collision MCC with cross-section loading, cross-section interpolation, electron-neutral collisions, ion-neutral collisions, and ionization product handling.
- `G02_MCC_network`: data-driven, whole-step MCC network with a C++20 core, two- and three-body channels, and a zero-dimensional collision-box validation example. Its tests generate synthetic data at runtime, which must not support scientific conclusions.
- `G03_DSMC`: a C++20 DSMC collision library for one neutral atomic species and uniform particle weight. It accepts cylindrical particles and a nonuniform 3D grid, supports HS/VHS/VSS with rounded NTC or a continuous candidate clock, and includes theory, a source walkthrough and validation criteria.

## Dependencies

- `G01_MCC` uses MPI and Fortran `include`; callers need MPI, preprocessing and include paths, and consistent physical units.
- `G02_MCC_network` uses CMake and C++20. MPI and OpenMP are optional. Its test directory configures independently.
- `G03_DSMC` uses C++20 on a serial CPU. The calling project chooses its build setup and input formats. The [current tests](../tests/009_collision/G03_DSMC/README.en.md) cover models, cylindrical grids, both schedules and collision relaxation. Run `bash tests/009_collision/G03_DSMC/run.sh` from the repository root.

## Documentation

See each module's README and the Sphinx `G_Collision` pages for formulas,
interfaces and validation instructions.
