# C++ 文档调用示例

[English](README.md)

`batch.cpp` 展示 `MccStepper::step` 的两个重载、粒子与背景初始化、工作区复用和异常处理。本示例只演示 C++。程序从第一个命令行参数读取模型目录，该目录须包含 A/B 的合成等质量弹性碰撞模型。

```bash
# 从仓库根目录运行
cmake -S tests/009_collision/G02_MCC_network/examples/doc_snippets -B /tmp/g02_documented_callers
cmake --build /tmp/g02_documented_callers -j 4
ctest --test-dir /tmp/g02_documented_callers --output-on-failure
```

CTest 自动生成测试模型。手动执行时先运行生成器。

```bash
/tmp/g02_documented_callers/g02_generate_test_data /tmp/g02_documented_callers/generated_models
/tmp/g02_documented_callers/doc_batch /tmp/g02_documented_callers/generated_models/collision_box_elastic
```

这些检查验证接口可调用，真实气体的物理精度需要另外验证。
