# J02 中性粒子 SN 输运测试

本目录验证第一阶段中与 PIC 无关的 SN 数值核心，包括相空间求积、柱坐标几何、
局部 P1-DG 算子、二维 Maxwell/漂移 Maxwell 储库入口、MC 穿越样本转换、开放
边界通量归一化、镜面方向映射、漫反射通量守恒、部分面入口积分、反射源迭代、
带方向和单元坐标的错误诊断、以及单元矩和内部面通量重构。测试也
验证 `gauss-chebyshev` 是 `midpoint` 节点的精确别名。

运行命令：

```bash
bash tests/011_fluid/J02_neutral_sn_transport_2Drz/run.sh
```
