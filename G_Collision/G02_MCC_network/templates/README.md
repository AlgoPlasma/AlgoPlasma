# G02 CSV 模板

`blank/` 是 Tests 中空白模板的完整拷贝，保留全部表头及预填的 manifest.csv。复制整个目录后填写，保留 tables/ 子目录；空白模板不能直接运行。

```bash
# 在仓库根目录执行
model_dir=$(mktemp -d /tmp/g02_model.XXXXXX)
cp -R G_Collision/G02_MCC_network/templates/blank/. "$model_dir/"
# 填完 CSV 后检查
cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_csv_check -DG02_MCC_ENABLE_FORTRAN=OFF -DG02_MCC_BUILD_TESTS=ON
cmake --build /tmp/g02_csv_check --target g02_validate_model -j 4
/tmp/g02_csv_check/g02_validate_model "$model_dir"
```

[填写教程](../../../docs/source/tests/009_collision/G02_csv_templates.rst)解释各表、单位和关联关系。[已填弹性算例](../../../tests/009_collision/G02_MCC_network/data/collision_box_elastic/)中的数值为合成值，不能用于科研结论。

修改模板格式时，请同步 Tests 中的 templates/blank/ 与本目录。
