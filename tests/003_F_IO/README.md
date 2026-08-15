# 003_F_IO — F_IO I/O Regression Test (MPI + HDF5)

This directory provides a small but comprehensive regression test for the `F_IO`
I/O routines in AlgoPlasma. It validates:

- **Particle I/O**: `F02` (output) + `F01` (load)
- **Field I/O**: `F04` (output) + `F03` (load)
- Supported formats: **`dat` / `bin` / `h5`**
- Both **low-level format-specific routines** and **tag-based dispatchers**
- The **unknown-tag fallback** path in dispatchers

The test uses a **round-trip** strategy:

> write (per-rank) → `MPI_BARRIER` → read (per-rank) → element-wise compare  
Any mismatch triggers `MPI_ABORT` immediately.

---

## Contents

- `test_F_IO.f90`  
  MPI Fortran test program. Each rank writes/reads its own files and verifies
  correctness via round-trip comparisons.

- `makerun.sh`  
  Build-and-run script. Compiles required `F_IO` modules and `test_F_IO.f90`,
  then runs the test with MPI.

- `clean.sh`  
  Removes build artifacts and all test output folders.

---

## Requirements

- MPI (OpenMPI / MPICH, etc.)
- HDF5 with Fortran bindings (parallel HDF5 recommended)
- `h5pfc` available (MPI + HDF5 Fortran wrapper)

Quick checks:

```bash
which mpirun
which h5pfc
h5pfc -show
