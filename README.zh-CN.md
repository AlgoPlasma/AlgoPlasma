# AlgoPlasma: Open Algorithms for Plasma Modeling

[中文](README.zh-CN.md) | [English](README.en.md)

AlgoPlasma 曾用名为 PMSL，致力于把等离子体建模中分散、重复实现的核心算法，沉淀为开放、可复用、可测试、可解释的算法库；它既服务于科研中的可靠建模与结果验证，也服务于教学中的算法理解与实践训练。AlgoPlasma 希望汇众人之力构筑共同的算法基座，让后来者站在其上继续创新，而不是各自从零开始搭建。

## 仓库结构

```text
AlgoPlasma
├── A_Pusher          # 粒子推进
├── B_Scatter         # 粒子到网格沉积
├── C_Gather          # 网格到粒子插值
├── D_Poisson         # Poisson 求解及电场后处理
├── E_Maxwell         # Maxwell / FDTD
├── F_IO              # 数据输入输出
├── G_collision       # 碰撞模型
├── H_MPI_Exchange    # MPI 数据交换
├── I_Initializer     # 初始化
├── J_Fluid           # 流体算法
├── docs              # Sphinx + Doxygen 文档
└── tests             # 算法测试与验证案例
```

一个算法单元通常包含：

- 核心实现文件，例如 Fortran 子程序/函数文件、C/C++ 源文件、Python 脚本等。
- 模块入口或包装接口，例如 Fortran `mod_*.f90`。
- `README.md` 或 RST 文档，用于说明算法用途、公式和接口。
- 测试案例，用于验证数值正确性、稳定性、收敛性或物理行为。
- 可选的可视化脚本、参考结果和教学说明。

## 实现语言

AlgoPlasma 不限定实现语言。当前仓库以 Fortran 实现为主，同时包含少量 C 辅助代码和 Python 测试、初始化、绘图脚本。未来欢迎 C、C++、Python、CUDA、Julia 或其他适合特定算法的实现。

## 快速使用

AlgoPlasma 当前主要以源码级算法库形式组织。Fortran 模块通常通过 `mod_*.f90` 入口文件集成，该入口文件会使用 C 预处理 `#include` 纳入具体子程序。

示例：调用 3D Boris 粒子推进器。

```fortran
#include "A_Pusher/A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz.f90"

program demo_boris
    use mod_A01_Boris_3Dxyz
    implicit none

    real :: v(3), E(3), B(3), k

    v = (/1.0, 0.0, 0.0/)
    E = 0.0
    B = (/0.0, 0.0, 1.0/)
    k = 0.01

    call sub_A01_Boris_3Dxyz(v, E, B, k)
end program demo_boris
```

编译时通常需要开启 C 预处理：

```bash
gfortran -cpp -O2 -fdefault-real-8 demo_boris.f90
```

部分模块可能需要额外依赖，例如 MPI、OpenMP、HYPRE 或 HDF5。请参考对应算法目录和测试目录中的说明。

## 测试

测试位于 `tests/` 目录。许多测试目录包含：

- `make.sh`：编译测试程序。
- `run.sh`：运行测试。
- `clean.sh`：清理生成文件。
- `README.md`：说明测试目的、物理设置和验证标准。

例如运行 Maxwell FDTD 单步公式测试：

```bash
cd tests/005_maxwell/case_fdtd_single_step_formula
bash run.sh
```

修改某个算法后，建议优先运行与该算法直接相关的局部测试，再运行更长时间尺度或更完整的物理验证案例。

## 文档

项目文档基于 Sphinx、Doxygen 和 Breathe 构建：

- 源码中的 Doxygen 注释用于生成 API 文档。
- `docs/source/developer_onboarding.rst` 提供面向使用者和新开发者的快速入门路线。
- `docs/source/rst_files/` 中包含算法说明、公式推导、测试指南和示意图。
- `docs/source/creat_rst.py` 可辅助生成或更新部分 RST 页面。

构建文档的一般流程：

```bash
pip install -r docs/requirements.txt
cd docs
make html
```

系统中还需要安装 Doxygen。Read the Docs 配置见 `.readthedocs.yaml`。构建完成后，HTML 首页通常位于 `docs/build/html/index.html`，可以用浏览器打开该文件查看文档。

## 贡献建议

欢迎贡献任何服务于等离子体学科的算法实现、测试案例、文档说明和验证结果。

建议一个新的算法贡献至少包含：

- 清晰命名的算法目录。
- 核心实现和必要的包装接口。
- 参数、单位、数组布局和边界约定说明。
- 算法公式、适用范围和主要参考文献。
- 一个可以独立运行的测试或验证案例。
- 必要时提供 Python 可视化或数据分析脚本。

贡献时请尽量保持算法单元独立、接口清晰、依赖明确。对于已有算法的改进，请同时说明数值行为是否改变，并补充或更新相应测试。

## 许可证

AlgoPlasma 采用 [Apache License 2.0](LICENSE) 开源许可证。版权和归属信息见 [NOTICE](NOTICE)。

## 发起人/联系人

- 赵隐剑 / Yinjian Zhao
- Email: contact@algoplasma.com
- Homepage: <https://homepage.hit.edu.cn/zhaoyinjian>
