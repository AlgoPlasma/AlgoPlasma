# J01_free_molecular

[中文](README.zh-CN.md) | [English](README.en.md)

本目录通过 Fortran 模块 `mod_J01_neutral_free_molecular_2Drz` 提供自由分子粒子前处理。

## 粒子前处理

`mod_J01_neutral_free_molecular_2Drz` 接收网格、入口与壁面条件，独立生成粒子历史，返回参考密度、平均速度、内部面通量与边界出射通量。主入口为 `sub_J01_free_molecular_mc_2Drz`。

| 实现文件 | 任务 |
| --- | --- |
| `sub_J01_fm_sampling.f90` | 计算有效入口面积、供给粒子率，采样入射位置和速度 |
| `sub_J01_fm_reflection.f90` | 镜面反射或按壁温采样漫反射速度 |
| `sub_J01_fm_trajectory.f90` | 推进至下一网格面，累计驻留时间与有符号穿面次数 |
| `sub_J01_fm_statistics.f90` | 将统计量换算为密度、平均速度与面通量 |
| `sub_J01_free_molecular_mc_2Drz.f90` | 检查输入，组织全部历史，汇总完成状态和输出 |

当前模型在 r-z 平面内沿直线飞行，不含周向运动、体内电离或分子间碰撞。入口速度是正向截断的漂移高斯入射粒子分布，不再额外按法向速度加权。密度来自驻留统计，通量来自穿面计数，不能用单元平均速度乘密度代替。

入口径向区间只限制注入位置；它不会把同一开放面的其余部分自动改成壁面。规定入射通量由应用按相同粒子率与面积补齐。历史因跟踪上限中断时，返回的统计场不能视为完整结果。

## 构建与文档

编译 `mod_J01_neutral_free_molecular_2Drz.f90`，启用预处理并添加本目录的 include 路径。该模块包含表中的五个实现文件，构建时只编译模块文件。调用程序须采用相同实数精度。

Sphinx 的 [J01](../../docs/source/rst_files/J_Fluid/J01_free_molecular.rst) 按“数据 → 入口 → 反射 → 跟踪 → 统计 → 完整计算”讲解。测试入口见 [J01 tests](../../tests/012_fluid/J01_free_molecular/README.md)。
