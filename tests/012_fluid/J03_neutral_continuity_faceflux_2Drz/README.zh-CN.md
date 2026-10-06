# J03 continuity tests

本目录先运行局部和配置测试，再运行真实前处理接续 J03 的小规模测试：

- `test_J03_continuity_units`：闭合系数、时间步、单步公式、残差及错误返回。
- `test_J03_equilibrium`：人工通量下的边界平衡、源损平衡和总量守恒。
- `test_J03_transient`：解析时间演化、时间步收敛、共享面、瞬态收支和稳态残差判据。
- `test_application_case`：应用有效区域与 ION 损失窗口。
- `test_J01_J03_channel`：真实 FM 轨迹与统计接入 J03；两单元解析时间演化；完整随机前处理的守恒。
- `test_J02_J03_analytic`：SN 解析分布的空间加密；实际面通量接入 J03，从空场推进至参考场。

J01 的独立粒子测试位于 `../J01_free_molecular`，J02 的局部和并行测试位于
`../J02_neutral_sn_transport_2Drz`。串联测试不读取完整应用输出。

在仓库根目录运行：

```bash
bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh
```

每个程序须无失败断言并以零状态退出，日志写入 `build/*.log`。
对应 HTML 在 Tests / 012_fluid 的 J03 module、J03 transient 和 Integration tests 页面，
给出解析参考、误差定义和通过标准。

完整算例位于 `application_reference_J01`（FM→J03）和
`application_reference`（SN→J03），它们与这些快速测试分开执行。
`clean.sh` 同时清理本目录和完整应用的生成物；需要保留应用结果时不要运行它。

应用输入与验收逻辑检查：

```bash
python3 tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/test_application_checks.py
```
