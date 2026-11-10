# Documented C++ caller

[简体中文](README.zh-CN.md)

`batch.cpp` demonstrates both `MccStepper::step` overloads, particle and background initialization, workspace reuse, and exception handling. This example covers C++ only. Its first command-line argument is a model directory containing the synthetic equal-mass A/B elastic model.

```bash
# Run from the repository root
cmake -S tests/009_collision/G02_MCC_network/examples/doc_snippets -B /tmp/g02_documented_callers
cmake --build /tmp/g02_documented_callers -j 4
ctest --test-dir /tmp/g02_documented_callers --output-on-failure
```

CTest generates the test models automatically. For manual execution, generate them first.

```bash
/tmp/g02_documented_callers/g02_generate_test_data /tmp/g02_documented_callers/generated_models
/tmp/g02_documented_callers/doc_batch /tmp/g02_documented_callers/generated_models/collision_box_elastic
```

These smoke tests verify that the interfaces can be called. They do not establish accuracy for real gases.
