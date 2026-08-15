# G01_MCC

[中文](README.zh-CN.md) | [English](README.en.md)

`G01_MCC` 是基于 null-collision 的 Monte Carlo Collision 模块。

## 文件

- `mod_G01_collision.f90`: 模块包装器，include 本目录的 G01 例程。
- `sub_G01_load_cross_section.f90`: 读取两列能量-截面表。
- `fun_G01_cross_section.f90`: 对等间隔能量表做线性插值。
- `sub_G01_collision1.f90`: 电子-中性粒子 MCC，支持弹性散射、激发和电离。
- `sub_G01_collision2.f90`: 离子-中性粒子 MCC，支持电荷交换和离子-中性粒子散射。
- `sub_G01_electron.f90`: 电子碰撞后的散射、能量损失和二次粒子速度抽样。

## 主要接口

- `sub_G01_load_cross_section(Nmax,cross_section,path)`
- `fun_G01_cross_section(energy,Nmax,cross_section)`
- `sub_G01_collision1(...)`
- `sub_G01_collision2(...)`
- `sub_G01_electron(...)`

## 注意

截面表的能量网格应等间隔。`sub_G01_collision1` 和 `sub_G01_collision2` 使用 MPI 归约全局最大碰撞频率，调用方需要保证粒子数组容量和密度网格范围有效。
