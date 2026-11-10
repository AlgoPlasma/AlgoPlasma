# 二维 TE 圆形波前可视化算例

[English](README.md)

本算例完全使用 Python 进行可视化。`run.sh` 运行 `fdtd_2d_te_cylindrical_wave.py` 并生成以下图像。

- `fdtd_2d_te_cylindrical_wave.png`

本算例不会编译或调用 `E_Maxwell` 的 Fortran 例程。内部 Yee 更新与 E03 直角坐标 FDTD 的二维 TEz 降维形式一致（`d/dz = 0`，`Ex`、`Ey`、`Hz` 非零）。中心源和一阶 Mur 边界由 Python 可视化脚本设置。E01 的 `r-z` 柱坐标 TEz 例程采用另一套更新。

运行命令

```bash
bash run.sh
```
