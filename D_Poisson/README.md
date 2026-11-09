# D_Poisson

[简体中文](README.zh-CN.md)

`D_Poisson` contains the electrostatic Poisson solvers and related post-processing utilities in AlgoPlasma. The solvers mainly use HYPRE Struct/PFMG to solve cell-centered structured-grid potential equations. Post-processing routines unpack the solver output and compute derived quantities such as the electric field.

## Subdirectories

- `D01_hypre_3Dxyz`: Earlier Cartesian C/HYPRE solver and Fortran-C bridge.
- `D02_hypre_3Dxyz_bc`: Cartesian 3D Poisson assembly with boundary conditions.
- `D03_hypre_3Draz_uniform`: Uniform cylindrical `(r,alpha,z)` Poisson solver.
- `D04_hypre_3Draz_nonuniform`: Nonuniform cylindrical `(r,alpha,z)` Poisson solver.
- `D05_phi1d_to_phi3d`: Unpacks the HYPRE 1D solution vector into a 3D ghost-cell array with MPI halo exchange.
- `D06_phi_to_E`: Computes electric field components from the potential via second-order central differences.
- `D07_phi_to_E_nonuniform`: Nonuniform cylindrical potential-to-field reconstruction (D04).

## Typical Call Order

A complete Poisson solve + field update step calls these modules in sequence:

```
D02  →  D05  →  (boundary BC fixup)  →  D06  →  H01 (MPI exchange of E)
```

For D04: solve → D05 unpack/exchange → physical boundary correction → D07 → field halo exchange. D07 returns cell-centered cylindrical fields.

## Dependencies

D01–D05 require MPI, HYPRE, a Fortran compiler, and a C compiler. D06 and D07 have no external dependencies.

## Documentation

Full formulas, boundary-condition notes, and reference test results live in the Sphinx `D_Poisson` page and the `tests/001_poisson` test page.
