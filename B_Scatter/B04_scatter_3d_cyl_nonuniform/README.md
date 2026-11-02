# B04_scatter_3d_cyl_nonuniform

[中文说明与公式](README.zh-CN.md) | [English guide and formulas](README.en.md)

非均匀三维柱坐标 `(r, phi, z)` 网格上的一阶 CIC 数密度／电荷密度沉积。
包含节点体积准备、单粒子八节点累加、轴点体积加权平均和可选的单元体积平均。

First-order CIC number/charge density deposition on a nonuniform cylindrical
`(r, phi, z)` grid, with nodal geometry preparation, single-particle accumulation,
volume-weighted axis averaging and optional cell-volume averaging.

- 模块入口 / Module: [mod_B04_scatter_3d_cyl_nonuniform.f90](mod_B04_scatter_3d_cyl_nonuniform.f90)
- 测试说明 / Tests: [README](../../tests/004_scatter/B04_scatter_3d_cyl_nonuniform/README.md)
- 依赖 / Dependencies: Fortran 2008 compiler, preprocessing and intrinsic `ieee_arithmetic`.
