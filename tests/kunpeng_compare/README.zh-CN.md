# 鲲鹏性能对比测试

[English](README.md)

本目录存放 AlgoPlasma 内核的跨平台性能对比算例。每个算例都保留原始基准程序、各被测机器的原始日志和 Python 后处理脚本。

现有算例：

- `A01_Boris_3Dxyz_omp`：Boris 粒子推进器的 OpenMP 性能对比。
- `B01_scatter_3Dxyz_omp`：直角坐标沉积的 OpenMP 性能对比。
- `D01_hypre_3Dxyz`：对比鲲鹏 GCC、鲲鹏毕昇和 AMD 上的 Poisson/HYPRE 性能。
- `E_Maxwell`：对比 AMD 和鲲鹏上的 Maxwell 更新内核。
