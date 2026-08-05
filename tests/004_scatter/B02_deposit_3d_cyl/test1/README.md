# Simplified 3D cylindrical deposition package

This version removes the fragmented helper utilities from the previous package.
The source structure is now:

- `src/mod_B00_cyl3d_base.f90` : only constants
- `src/mod_B01_deposit_charge_3d_cyl.f90`
- `src/sub_B01_deposit_charge_3d_cyl.f90`
- `src/mod_B02_deposit_current_3d_cyl.f90`
- `src/sub_B02_deposit_current_3d_cyl.f90`

The current deposition keeps only one necessary helper for trajectory splitting
and one necessary helper for single-cell deposition.

## Build

```bash
mkdir -p build

gfortran -cpp -O2 -Wall -Wextra -fimplicit-none -J build -I src \
    src/mod_B00_cyl3d_base.f90 \
    src/mod_B01_deposit_charge_3d_cyl.f90 \
    test/test_charge_paper.f90 \
    -o build/test_charge_paper

gfortran -cpp -O2 -Wall -Wextra -fimplicit-none -J build -I src \
    src/mod_B00_cyl3d_base.f90 \
    src/mod_B01_deposit_charge_3d_cyl.f90 \
    src/mod_B02_deposit_current_3d_cyl.f90 \
    test/test_current_paper.f90 \
    -o build/test_current_paper
```

## Run

Quick smoke test:

```bash
./build/test_charge_paper 200000
python plot/plot_charge_paper.py

./build/test_current_paper 200000
python plot/plot_current_paper.py
```
