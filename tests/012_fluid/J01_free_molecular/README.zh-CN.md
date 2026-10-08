# J01_free_molecular tests

本目录集中运行 J01 的五个小测试程序，不读取外部历史结果。

| 测试源文件 | 被测实现 | 检查内容 |
| --- | --- | --- |
| `test_J01_continuity_freeflow.f90` | `sub_J01_continuity_freeflow.f90` | 三维更新公式、源项符号、保护层、六方向输运、周期守恒 |
| `test_J01_faceflux_2Drz_units.f90` | 二维通量工具及粒子主入口 | 内部和边界通量符号、面积体积权重、单格粒子率守恒、非法密度 |
| `test_J01_corner_crossings.f90` | `sub_J01_fm_trajectory.f90` | 精确及近角点、两种碰面次序、四种速度符号、阶梯边界、穿面计数与驻留时间 |
| `test_J01_sampling_distribution.f90` | sampling 与 reflection | 三个固定种子下的环形面积采样、截断正态入射及四面漫反射概率 |
| `test_J01_fm_units.f90` | sampling、trajectory、reflection、statistics 与主入口 | 部分入口、采样范围、反射、定位、驻留统计、归一化、截断与非法拓扑 |

```bash
bash tests/012_fluid/J01_free_molecular/run.sh
```

每个程序应输出 `RESULT: PASS`，有失败时脚本返回非零状态。逐项结果写到本目录 `build/*.log`。粒子模块的确定性标量容差为 `1e-11*max(1,abs(expected))`；其余容差见测试源码。分布测试每组抽样 32768 次，与解析累积概率核对，容差为七倍二项分布标准差；它不代替完整应用测试。

J01→J03 的小规模串联测试位于 J03 测试目录：实际轨迹统计接入连续性单步过程，以两单元时间解析解为参考；另检查完整随机主入口的守恒。大型应用由独立脚本运行。

清理编译产物：

```bash
bash tests/012_fluid/J01_free_molecular/clean.sh
```
