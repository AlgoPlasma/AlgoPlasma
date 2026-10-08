# G_Collision

[中文](README.zh-CN.md) | [English](README.en.md)

`G_Collision` contains AlgoPlasma's collision models: `G01_MCC` and
`G02_MCC_network`.

## New to collision simulation?

Start with the [G02 collision-box tutorial](../tests/009_collision/G02_MCC_network/examples/collision_box/README.en.md):
watch hot particles cool through collisions with a colder gas.
It explains zero-dimensional modeling, temperature versus drift, random collision counts and the three plots.
Speed, kinetic energy and averages are enough to begin.
See the [G02 module guide](G02_MCC_network/README.en.md) for interfaces.

## Subdirectories

- `G01_MCC`: null-collision MCC with cross-section loading, cross-section interpolation, electron-neutral collisions, ion-neutral collisions, and ionization product handling.
- `G02_MCC_network`: data-driven, whole-step MCC network with a C++20 core, two- and three-body channels, and a zero-dimensional collision-box validation example. Its tests generate synthetic data at runtime, which must not support scientific conclusions.

## Dependencies

- `G01_MCC` uses MPI and Fortran `include`; callers need MPI, preprocessing and include paths, and consistent physical units.
- `G02_MCC_network` uses CMake and C++20. MPI and OpenMP are optional. Its test directory configures independently.

## Documentation

See each module's README and the Sphinx `G_Collision` pages for formulas,
interfaces and validation instructions.
