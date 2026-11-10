# B04：非均匀柱坐标节点密度沉积

[中文](README.zh-CN.md) | [English](README.en.md)

三维柱坐标结构化张量积网格上的线性 CIC：各方向允许非均匀间距；单次调用把一个宏粒子代表的粒子数或电荷累加为节点密度。

名称中的 `raz` 表示径向、角向和轴向；接口中的角向坐标使用 `phi`。

详细公式、参数与数据流见 [Sphinx 模块页](../../docs/source/rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform.rst)；本地编译后可打开 [模块网页](../../docs/build/html/rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform.html)。

| 文件 | 作用 |
|---|---|
| [mod_B04_scatter_3d_raz_nonuniform.f90](mod_B04_scatter_3d_raz_nonuniform.f90) | 模块入口、公共状态码 |
| [sub_B04_build_geometry.f90](sub_B04_build_geometry.f90) | 逆节点体积和角向积分权重 |
| [sub_B04_scatter_3d_raz_nonuniform.f90](sub_B04_scatter_3d_raz_nonuniform.f90) | 单粒子节点密度累加 |
| [sub_B04_average_axis.f90](sub_B04_average_axis.f90) | 全周轴线加权平均 |
| [sub_B04_project_density.f90](sub_B04_project_density.f90) | 可选单元体积平均 |

```fortran
use mod_B04_scatter_3d_raz_nonuniform
call sub_B04_build_geometry(r, phi, z, periodic_phi, inv_volume, phi_measure, ierr)
! Check ierr; initialize density once before accumulating particles.
call sub_B04_scatter_3d_raz_nonuniform(r, phi, z, periodic_phi, &
    cell, position, amount, inv_volume, density, ierr)
```

调用方分配数组、定位单元并处理粒子边界。`amount=wp` 得到数密度，`amount=qp*wp` 得到电荷密度。每次调用后检查 `ierr`。MPI 共享节点使用完整节点体积；全周轴点平均在贡献求和之后进行。

编译 module 入口时启用预处理并加入本目录的 include 路径，如 GNU Fortran 的 `-cpp -I ...`；module 与调用方使用相同精度，双精度可用 `-fdefault-real-8`。

- [Calling example / 完整调用示例](../../examples/B04_scatter_3d_raz_nonuniform/main.f90)
- [Usage page / 使用说明](../../docs/source/rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform/usage.rst)
- [Tests / 测试](../../tests/004_scatter/B04_scatter_3d_raz_nonuniform/README.md)

```bash
bash tests/004_scatter/B04_scatter_3d_raz_nonuniform/run.sh double debug
```

Liu, Zhou, Zhao (2026), [preprint v1](https://arxiv.org/abs/2606.09168v1), Sections II.A–B and II.E.

Author: Xin Luo.
