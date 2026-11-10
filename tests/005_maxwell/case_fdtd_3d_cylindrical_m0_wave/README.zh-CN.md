# 三维柱坐标波导模可视化算例

[English](README.md)

本算例完全使用 Python 进行可视化。`run.sh` 运行 `fdtd_3d_cylindrical_m0_wave.py` 并生成以下图像。

- `fdtd_3d_cylindrical_waveguide_mode.png`

本算例不会编译或调用 `E_Maxwell` 的 Fortran 例程。脚本推进标量 `Ez` 波动方程，包含柱坐标度量项、轴线闭合和理想电导体（PEC）外壁边界。E02 的 `sub_E02_fdtd_3d_cylindrical_H/E` 则逐点更新六个场分量。要严格检验 E02 与 `m=0` 更新的一致性，请使用 `case_fdtd_cyl_m0_equivalence`。

运行命令

```bash
bash run.sh
```
