# I02_par_init_and_load

[中文](README.zh-CN.md) | [English](README.en.md)

`I02_par_init_and_load` 提供离线二进制粒子初值生成和 MPI 载入流程。

## 文件

- `init_particles_bin.py`: 在三维 T 形区域中生成电子/离子初始粒子，并输出二进制文件和诊断图。
- `mod_I02_load_init_particles_bin.f90`: Fortran 模块包装器。
- `sub_I02_load_init_particles_bin.f90`: 读取二进制粒子文件，并按当前 MPI 子域筛选本地粒子。

## 输入输出

- Python 输出目录：`output_init_particles_bin/`
- 电子文件：`par_ele_init.bin`
- 离子文件：`par_ion_init.bin`
- 每个粒子记录：`x,y,z,vx,vy,vz`，数据类型为 `float64`。

## 依赖

- Python 脚本依赖 NumPy、SciPy 和 Matplotlib。
- Fortran 载入例程依赖 MPI，并通过 `include` 组织源码。
- 默认粒子数很大，运行脚本前需要确认内存和磁盘空间。
