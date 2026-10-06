# C++ 文档调用示例 / Documented C++ caller

`batch.cpp` 展示 `MccStepper::step` 的两个重载、粒子与背景初始化、工作区复用和异常处理。只演示 C++。模型目录从第一个命令行参数读取，要求含 A/B 的合成等质量弹性模型。

`batch.cpp` demonstrates both step overloads, particle/background initialization, workspace reuse and exception handling. Its first argument is a model directory containing the synthetic equal-mass A/B elastic model.

```bash
# From repository root / 从仓库根目录运行
cmake -S tests/009_collision/G02_MCC_network/examples/doc_snippets -B /tmp/g02_documented_callers
cmake --build /tmp/g02_documented_callers -j 4
ctest --test-dir /tmp/g02_documented_callers --output-on-failure
```

CTest 自动生成测试模型。手动执行时先运行生成器 / For manual execution, generate fixtures first:

```bash
/tmp/g02_documented_callers/g02_generate_test_data /tmp/g02_documented_callers/generated_models
/tmp/g02_documented_callers/doc_batch /tmp/g02_documented_callers/generated_models/collision_box_elastic
```

这些检查验证接口可调用，不代表真实气体物理精度。These smoke tests verify callable interfaces, not real-gas accuracy.
