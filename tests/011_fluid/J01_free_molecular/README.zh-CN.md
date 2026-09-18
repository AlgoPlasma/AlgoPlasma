# J01_free_molecular tests

本目录集中运行 J01 的三组小测试，不读取外部历史结果。

| 测试源文件 | 被测实现 | 检查内容 |
| --- | --- | --- |
| `test_J01_continuity_freeflow.f90` | `sub_J01_continuity_freeflow.f90` | 三维更新公式、源项符号、保护层、六方向输运、周期守恒 |
| `test_J01_faceflux_2Drz_units.f90` | 二维通量工具及粒子主入口 | 内部和边界通量符号、面积体积权重、单格粒子率守恒、非法密度 |
| `test_J01_fm_units.f90` | sampling、trajectory、reflection、statistics 与主入口 | 部分入口、采样范围、反射、定位、驻留统计、归一化、截断与非法拓扑 |

```bash
bash tests/011_fluid/J01_free_molecular/run.sh
```

每组应输出 `n_failed=0` 和 `RESULT: PASS`，有失败时脚本返回非零状态。逐项结果写到本目录 `build/*.log`。粒子模块的确定性标量容差为 `1e-11*max(1,abs(expected))`；其余容差见测试源码。小样本检查不代替分布收敛性或完整应用测试。

FM→J03、SN→J03 的完整应用测试仍放在 J03 测试目录，因为它们检查两个模块的连接和连续性解。

清理编译产物：

```bash
bash tests/011_fluid/J01_free_molecular/clean.sh
```
