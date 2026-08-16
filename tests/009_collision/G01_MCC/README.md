# G01 MCC cross-section loader test

[中文](README.zh-CN.md) | [English](README.en.md)

This directory provides a focused regression test for
`G_Collision/G01_MCC/sub_G01_load_cross_section.f90`. It checks the array-bound
behavior of the two-column cross-section loader; it does not validate MCC
collision physics or use physical cross-section data.

## Test cases

- `cross_section_exact_nmax.dat` contains exactly `Nmax` rows. The test verifies
  that all values are loaded without probing `cross_section(:, Nmax + 1)`.
- `cross_section_too_many_rows.dat` contains `Nmax + 1` rows. The test verifies
  that the loader prints its size diagnostic and exits with a nonzero status
  without an AddressSanitizer error.

## Requirements

- Bash
- GNU Fortran with AddressSanitizer support

On Ubuntu/Debian, install GNU Fortran with:

```bash
sudo apt update
sudo apt install -y gfortran
```

## Run

From the repository root:

```bash
bash tests/009_collision/G01_MCC/clean.sh
bash tests/009_collision/G01_MCC/run.sh
```

A successful run prints:

```text
PASS: exact-length cross-section table loaded.
PASS: oversized cross-section table rejected without an out-of-bounds access.
```

The test executables are written under `build/`.

## Clean

```bash
bash tests/009_collision/G01_MCC/clean.sh
```

This removes the local `build/` directory.
