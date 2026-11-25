# 007_gather

[English](README.md)

这里收录 `C_Gather` 的场插值回归测试。

测试按模块划分，各子目录可以独立构建和运行。

- `C01_gather_3Dxyz` 检查三线性场插值以及插值与粒子推进的融合路径。
- `C02_gather_3Dxyz_bspline` 检查直接 B 样条场插值。
- `C03_gather_3Draz_nonuniform` 检查非均匀柱坐标交错网格的场插值、收敛性和无效输入处理。

各子目录由 Fortran 程序写出确定性的 CSV 数据，再用 Python 对照参考值并统计误差。C01 和 C02 还会生成诊断图。C03 检查预期的错误退出，且只需要 Python 标准库。
