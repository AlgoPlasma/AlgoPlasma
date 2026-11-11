# B04：非均匀柱坐标节点密度沉积

[English](README.md)

三维柱坐标结构化张量积网格上的线性 CIC 沉积，各坐标方向允许独立的非均匀间距。
沉积例程每次调用把一个宏粒子代表的粒子数或电荷累加为节点密度。
名称中的 `raz` 表示径向、角向和轴向；接口中的角向坐标使用 `phi`。

## 文件

| 文件 | 作用 |
| --- | --- |
| [mod_B04_scatter_3Draz_nonuniform.f90](mod_B04_scatter_3Draz_nonuniform.f90) | 模块入口和公共状态码 |
| [sub_B04_build_geometry.f90](sub_B04_build_geometry.f90) | 有效节点体积的倒数和角向积分权重 |
| [sub_B04_scatter_3Draz_nonuniform.f90](sub_B04_scatter_3Draz_nonuniform.f90) | 单粒子节点密度累加 |
| [sub_B04_average_axis.f90](sub_B04_average_axis.f90) | 全周网格的轴线加权平均 |
| [sub_B04_project_density.f90](sub_B04_project_density.f90) | 可选的单元体积平均 |

## 最小调用顺序

分配数组并准备好网格及粒子数据后：

```fortran
use mod_B04_scatter_3Draz_nonuniform
call sub_B04_build_geometry(r, phi, z, periodic_phi, inv_volume, phi_measure, ierr)
if (ierr /= B04_OK) error stop 'B04 geometry failed'
density = 0.0
call sub_B04_scatter_3Draz_nonuniform(r, phi, z, periodic_phi, &
    cell, position, amount, inv_volume, density, ierr)
if (ierr /= B04_OK) error stop 'B04 scatter failed'
```

- 调用方分配数组、处理粒子边界，并使用同一组坐标数组确定每个粒子所在的单元。
- `amount=wp` 得到数密度，`amount=qp*wp` 得到电荷密度；`wp` 为宏粒子代表的真实粒子数，
  `qp` 为一个真实粒子的带符号电荷。
- 首次调用及网格或周期设置变化时准备几何。每轮重新计算密度时，在粒子循环前清零一次；每次调用后检查 `ierr`。
- MPI 共享节点使用完整有效节点体积，由调用方汇总贡献。含 `r=0` 的全周网格在贡献汇总后进行轴点平均。

## 编译

需要支持 Fortran 2008 的编译器、预处理功能及内置的 `ieee_arithmetic` 模块。
编译模块入口时，将本目录加入 include 路径（GNU Fortran 使用 `-cpp -I ...`）；
入口文件通过 include 纳入四份实现文件。模块与调用方使用相同实数精度；
GNU Fortran 可使用 `-fdefault-real-8` 选择双精度。

## 示例、测试与详细文档

- [调用示例与编译命令](../../examples/B04_scatter_3Draz_nonuniform/README.zh-CN.md) · [完整示例源码](../../examples/B04_scatter_3Draz_nonuniform/main.f90)
- [测试范围与运行方式](../../tests/004_scatter/B04_scatter_3Draz_nonuniform/README.zh-CN.md)
- [B04 算法总览](../../docs/source/rst_files/B_Scatter/B04_scatter_3Draz_nonuniform.rst) · [使用指南](../../docs/source/rst_files/B_Scatter/B04_scatter_3Draz_nonuniform/usage.rst)（双语 Sphinx 源文件）

从仓库根目录，在 Bash 中执行回归测试：

```bash
bash tests/004_scatter/B04_scatter_3Draz_nonuniform/run.sh double debug
```

文档构建完成后，可打开相对于仓库根目录的本地文件
`docs/build/html/rst_files/B_Scatter/B04_scatter_3Draz_nonuniform.html`。

参考：Liu、Zhou、Zhao（2026），[预印本 v1](https://arxiv.org/abs/2606.09168v1)，第 II.A–B 和 II.E 节。

作者：Xin Luo。
