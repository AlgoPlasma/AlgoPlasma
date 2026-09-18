# J03 continuity tests

本目录运行五组小测试：

- `test_J02_transport_units`：检查 J02 的几何、面连接、吸收矩阵和边界通量符号。
- `test_J03_continuity_units`：检查面速度初始化、时间步、密度更新、残差与错误返回。
- `test_J03_neutral_continuity_faceflux_2Drz`：检查模块间传入的数据、稳态平衡与总量守恒。

- `test_J03_transient`：瞬态解析解、时间步收敛、时变损失、共享面检查及稳态残差判据。
- `test_application_case`：共同有效区域与 ION 窗口生成。

J01 自身的通量和粒子测试统一放在 `../J01_free_molecular`。

在仓库根目录运行：

```bash
bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh
```

每个程序须输出 `n_failed=0`、`RESULT: PASS` 并以零状态退出。测试日志写入 `build/*.log`。

完整算例分为 `application_reference_J01`（FM→J03）和 `application_reference`（SN→J03）。它们使用 application_inputs 内的网格，掩码与损失由 application_case.f90 生成，输出前处理场和对应的 J03 密度图。小测试不需要这些外部输入。

`clean.sh` 会清理本目录以及应用算例的生成结果；需要保留应用结果时不要运行该清理脚本。

应用验收逻辑和输入校验的小测试：

```bash
python3 tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/test_application_checks.py
```
