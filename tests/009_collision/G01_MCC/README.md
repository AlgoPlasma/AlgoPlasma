# G01 MCC cross-section loader test

This regression test verifies that `sub_G01_load_cross_section` can load a table containing exactly `Nmax` rows without accessing `cross_section(:, Nmax + 1)` while checking for end of file.

The three-row input table is synthetic and is used only to exercise array bounds and preserve the loaded values. The test does not contain physical cross-section data.

Run the test from the repository root with:

```bash
bash tests/009_collision/G01_MCC/run.sh
```

The test compiles with GNU Fortran bounds checking enabled and prints `PASS: exact-length cross-section table loaded` when successful.
