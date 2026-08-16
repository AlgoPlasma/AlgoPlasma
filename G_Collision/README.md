# G_Collision

[中文](README.zh-CN.md) | [English](README.en.md)

`G_Collision` contains collision models used by AlgoPlasma. The current implementation
is `G01_MCC`, a tabulated-cross-section Monte Carlo Collision (MCC) module.

## Subdirectories

- `G01_MCC`: null-collision MCC with cross-section loading, cross-section interpolation, electron-neutral collisions, ion-neutral collisions, and ionization product handling.

## Dependencies

- Collision routines use MPI and must be called from an MPI program.
- Sources are organized with Fortran `include`; builds need preprocessing and the proper include path.
- Cross-section tables, particle masses, charge constants, and the `eV` conversion factor must use consistent units.

## Documentation

Full formulas, workflow notes, and API pages live in the Sphinx `G_Collision` /
`G01_MCC` documentation.
