# 文档调用示例 / Documented callers

三个示例使用同一套合成 A/B 弹性数据，分别展示 C++ 的两个 step 重载、C 的 request 与具名选项、Fortran 的类型声明与状态检查。每个程序从第一个命令行参数读取模型目录。

The three callers use the same synthetic A/B elastic model. They demonstrate C++ step overloads, a fully initialized C request with named options, and Fortran kind imports and status checks. Each takes the model directory as its first argument.

```bash
# From repository root / 从仓库根目录运行
cmake -S tests/009_collision/G02_MCC_network/examples/doc_snippets -B /tmp/g02_documented_callers
cmake --build /tmp/g02_documented_callers -j 4
ctest --test-dir /tmp/g02_documented_callers --output-on-failure
```

These smoke tests check callable interfaces, not physical accuracy. / 这些调用检查用于验证接口能运行，不代表物理模型已验证。
