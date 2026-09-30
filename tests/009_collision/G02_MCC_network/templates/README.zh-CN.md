# G02 CSV 模板

[中文](README.zh-CN.md) | [English](README.en.md)

推荐先复制[原始的一条弹性反应示例](../data/collision_box_elastic/)。这套数据来自最初的 G02 原型，已经能被当前程序读取。
[空白模板](blank/)保留所有表头，`manifest.csv` 预填格式版本和文件名；其他 CSV 需要自己填数据，不能直接用于计算。

## 从哪里开始？

1. 复制整个模型目录，不要只复制一张 CSV。
2. 填物种、内部态和元素组成，再填反应物、产物和反应参数。
3. 最后填写速率数据、数据集说明和文件清单，并运行检查。

逐表解释、单位、编号关联、可留空字段和下载入口见[CSV 填写教程](../../../../docs/source/tests/009_collision/G02_csv_templates.rst)。
已填写的二体和三体扩展示例分别在 [demo_binary](../data/demo_binary/) 和 [demo_three_body](../data/demo_three_body/)。

## 复制并检查

从仓库根目录在 Linux/WSL 中运行；`mktemp` 会创建新的工作目录：

```bash
model_dir=$(mktemp -d /tmp/g02_model.XXXXXX)
cp -R tests/009_collision/G02_MCC_network/data/collision_box_elastic/. "$model_dir/"
cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_csv_check -DG02_MCC_ENABLE_FORTRAN=OFF -DG02_MCC_BUILD_TESTS=ON
cmake --build /tmp/g02_csv_check --target g02_validate_model -j 4
/tmp/g02_csv_check/g02_validate_model "$model_dir"
```

从空白开始时，将复制命令的源目录换成 `tests/009_collision/G02_MCC_network/templates/blank/.`，填完再检查。
`PASS` 表示能加载并通过已有模型约束；错误或未填写模板返回非零状态。该工具还要求至少一个物种和一条启用的反应。
检查通过不代表物理数据可靠，也不代替碰撞运行测试。所有现有示例的数值都是合成值，不能用于科研结论。
