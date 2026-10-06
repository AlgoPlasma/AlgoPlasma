# C03：非均匀三维 RAZ 场 Gather

[中文](README.zh-CN.md) | [English](README.en.md)

使用 D04 风格单元索引，在物理坐标 `(r [m],alpha [rad],z [m])` 处插值场，输出柱坐标 E/B 分量。

- `Er/Ea/Ez`: `(face,center,center)` / `(center,face,center)` / `(center,center,face)`.
- `Br/Ba/Bz`: `(face,face,face)`.

该布局用于静电交错 E 和给定节点 B，不直接适配 E02 Yee 场。调用方负责粒子归属、ghost 场及物理边界。

## 文件与接口

- `mod_C03_gather_3Draz_nonuniform.f90`: 模块入口.
- `sub_C03_gather_3Draz_nonuniform.f90`: 粒子数组包装接口.
- `sub_C03_gather_3Draz_nonuniform_point.f90`: 单点 gather.
- `sub_C03_gather_helpers.f90`: 公开 sub_C03_check_grid 与私有辅助函数.

## 调用片段

以下假定几何及场数组已分配并填充。

```fortran
use mod_C03_gather_3Draz_nonuniform
! After declarations and geometry/field initialization:
call sub_C03_check_grid(il(1),iu(1),r_face,dr)
call sub_C03_check_grid(il(2),iu(2),a_face,da)
call sub_C03_check_grid(il(3),iu(3),z_face,dz)
call sub_C03_gather_3Draz_nonuniform_point( &
    x,il,iu,r_face,a_face,z_face,dr,da,dz,Er,Ea,Ez,Br,Ba,Bz,E,B)
```

可选参数：`cell(3)` 为只读单元缓存；`a_period>0` 启用角向归约；`a_origin` 默认 0 且必须与周期同时使用。

只编译 module 入口，使用 `gfortran -cpp`。默认 `real`；双精度可加 `-fdefault-real-8`，调用方须采用一致精度。

[完整接口、公式与边界说明](../../docs/source/rst_files/C_Gather/C03_gather_3Draz_nonuniform.rst).
