# C01_gather_3Dxyz 测试

[English](README.md)

本测试独立于 PIC 循环的其他部分，验证 `C01_gather_3Dxyz`。

测试内容包括以下三项。

- 对合成三线性场的精确插值。
- 对平滑非三线性场的二阶收敛。
- `B=0` 时插值与粒子推进的融合路径。此时 Boris 更新退化为直接电场加速，可用作参考。

在本目录运行以下命令。

```bash
bash run.sh
```

Fortran 程序在 `output/` 下写出 CSV 文件。Python 后处理程序计算参考值、检查数值阈值、写出 `summary.json`，并将诊断图保存到 `output/figures/`。
