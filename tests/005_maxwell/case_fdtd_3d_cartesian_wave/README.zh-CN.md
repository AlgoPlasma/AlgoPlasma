# 三维直角坐标波可视化算例

[English](README.md)

本算例完全使用 Python 进行可视化。`run.sh` 运行 `fdtd_3d_cartesian_wave.py` 并生成主图（三个切面）。目录中也保留了一张单切面参考图。

- `fdtd_3d_cartesian_ez_slices.png`
- `fdtd_3d_cartesian_wave_slice.png`

本算例不会编译或调用 `E_Maxwell` 的 Fortran 例程。内部六个分量的旋度更新与 E03 的 `sub_E03_fdtd_3d_cartesian_H/E` 一致。位于中心的 `Ez` 软源、均方根（RMS）累积图和海绵边界由 Python 可视化脚本设置。

运行命令

```bash
bash run.sh
```
