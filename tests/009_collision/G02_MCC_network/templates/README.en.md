# G02 CSV templates

[中文](README.zh-CN.md) | [English](README.en.md)

Start by copying the [original single-reaction elastic example](../data/collision_box_elastic/). It comes from the original G02 prototype and loads with the current library.
The [blank template](blank/) retains every header. `manifest.csv` supplies the format version and file paths; the other CSV files need data before use.

## Filling order

1. Copy the whole package, not just one CSV file.
2. Fill species, states and composition, then reactants, products and reaction parameters.
3. Fill rate tables, dataset metadata and the manifest, then run the checker.

See the [CSV guide](../../../../docs/source/tests/009_collision/G02_csv_templates.rst) for fields, units, cross-file references, optional values and downloads.
More complete two- and three-body examples are [demo_binary](../data/demo_binary/) and [demo_three_body](../data/demo_three_body/).

## Copy and check

Run from the repository root in Linux/WSL. `mktemp` creates a new working directory:

```bash
model_dir=$(mktemp -d /tmp/g02_model.XXXXXX)
cp -R tests/009_collision/G02_MCC_network/data/collision_box_elastic/. "$model_dir/"
cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_csv_check -DG02_MCC_ENABLE_FORTRAN=OFF -DG02_MCC_BUILD_TESTS=ON
cmake --build /tmp/g02_csv_check --target g02_validate_model -j 4
/tmp/g02_csv_check/g02_validate_model "$model_dir"
```

To start blank, copy `tests/009_collision/G02_MCC_network/templates/blank/.` instead and fill it before checking.
`PASS` means loading and existing model constraints succeeded. Errors and unfilled templates return nonzero.
The tool additionally requires at least one species and one enabled reaction.
This is not a scientific validation or a collision-run test. All supplied example values are synthetic and cannot support scientific conclusions.
