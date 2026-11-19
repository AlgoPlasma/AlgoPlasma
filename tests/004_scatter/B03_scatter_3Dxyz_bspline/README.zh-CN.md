# B03_scatter_3Dxyz_bspline 测试

[English](README.md)

本测试验证 `B_Scatter/B03_scatter_3Dxyz_bspline` 的以下性质。

- `order=1` 的粒子数沉积与 `B01_Scatter_3Dxyz` 逐点一致。
- `order=1` 的分量沉积与 `B01_Scatter_3Dxyz_v` 逐点一致。
- `order=0..4` 的沉积总量守恒。
- `order=1..4` 的一阶矩守恒。
- 分批累加的结果与一次完整调用一致。

Python 后处理程序还会生成 RST 测试文档所用的参考图。

运行命令如下。

```bash
bash run.sh
```
