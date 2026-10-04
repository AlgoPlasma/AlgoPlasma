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
├── G_Collision       # 碰撞模型
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

## Contributors / 贡献者

<!-- CONTRIBUTORS:START -->
<p align="center"><sub>感谢每一位为 AlgoPlasma 贡献代码、测试、性能基准、文档、示例与缺陷修复的成员。</sub></p>

### 项目负责人

<table class="ap-work-list ap-work-list--lead">
  <thead>
    <tr>
      <th scope="col" align="left" width="160">成员</th>
      <th scope="col" align="left">个人简介</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><a href="https://github.com/Yin-YinjianZhao"><img src="docs/source/_static/contributors/zhaoyinjian.png" width="80" height="80" alt="赵隐剑"></a></span>
          <div class="ap-member-identity">
            <strong><a href="https://github.com/Yin-YinjianZhao">赵隐剑</a></strong><br>
            <sub class="ap-member-role">项目负责人</sub>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <p class="ap-member-biography">哈尔滨工业大学副教授、博士生导师，美国南加州大学航天工程博士，曾在美国劳伦斯伯克利国家实验室从事博士后研究，并参与美国能源部百亿亿次级计算项目WarpX开源程序的研发。长期从事等离子体物理与数值模拟研究，研究方向涵盖电推进、等离子体不稳定性、粒子模拟算法及高性能并行计算等。发表SCI论文40余篇，主持国家级青年人才、国家自然科学基金面上项目等多项科研项目。现任Plasma Science and Technology期刊青年编委，并担任Plasma Sources Science and Technology、Physics of Plasmas、Computer Physics Communications多本国内外等离子体物理与计算物理期刊审稿人。</p>
      </td>
    </tr>
  </tbody>
</table>

### 维护者

<table class="ap-work-list">
  <thead>
    <tr>
      <th scope="col" align="left" width="160">成员</th>
      <th scope="col" align="left">研究方向与参与工作</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><img src="docs/source/_static/contributors/xi-chen.svg" width="80" height="80" alt="陈曦"></span>
          <div class="ap-member-identity">
            <strong>陈曦</strong><br>
            <sub class="ap-member-role">维护者</sub>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <span class="ap-work-pending">待补充</span>
      </td>
    </tr>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><a href="https://gitee.com/jiaohuadetudouni"><img src="docs/source/_static/contributors/yingjie-chen.svg" width="80" height="80" alt="陈英杰"></a></span>
          <div class="ap-member-identity">
            <strong><a href="https://gitee.com/jiaohuadetudouni">陈英杰</a></strong><br>
            <sub class="ap-member-role">维护者</sub>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <span class="ap-work-pending">待补充</span>
      </td>
    </tr>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><img src="docs/source/_static/contributors/huchangzheng.jpg" width="80" height="80" alt="胡长征"></span>
          <div class="ap-member-identity">
            <strong>胡长征</strong><br>
            <sub class="ap-member-role">维护者</sub>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <span class="ap-work-pending">待补充</span>
      </td>
    </tr>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><a href="https://gitee.com/lzhe898"><img src="https://gitee.com/lzhe898.png" width="80" height="80" alt="刘哲"></a></span>
          <div class="ap-member-identity">
            <strong><a href="https://gitee.com/lzhe898">刘哲</a></strong><br>
            <sub class="ap-member-role">维护者</sub>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <ul class="ap-work-items">
          <li><a href="docs/source/rst_files/E_Maxwell/E01_Maxwell_2Drz.rst">轴对称二维柱坐标 Maxwell 方程的 FDTD 更新</a></li>
          <li><a href="docs/source/rst_files/E_Maxwell/E02_Maxwell_3Drtz.rst">三维柱坐标 Maxwell 方程的 FDTD 更新</a></li>
          <li><a href="docs/source/rst_files/E_Maxwell/E03_Maxwell_3Dxyz.rst">三维直角坐标 Maxwell 方程的 FDTD 更新</a></li>
          <li><a href="docs/source/rst_files/F_IO/F01_par_load.rst">并行粒子数据读取</a></li>
          <li><a href="docs/source/rst_files/F_IO/F02_par_output.rst">并行粒子数据输出</a></li>
          <li><a href="docs/source/rst_files/F_IO/F03_field_load.rst">并行场数据读取</a></li>
          <li><a href="docs/source/rst_files/F_IO/F04_field_output.rst">并行场数据输出</a></li>
          <li><a href="docs/source/rst_files/G_Collision/G02_MCC_network.rst">C++ 蒙特卡洛碰撞网络（CSV 反应模型）</a></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><a href="https://gitee.com/Luo-Xin-410"><img src="docs/source/_static/contributors/xin-luo.svg" width="80" height="80" alt="罗鑫"></a></span>
          <div class="ap-member-identity">
            <strong><a href="https://gitee.com/Luo-Xin-410">罗鑫</a></strong><br>
            <sub class="ap-member-role">维护者</sub>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <ul class="ap-work-items">
          <li><a href="docs/source/rst_files/C_Gather/C02_gather_3Dxyz_bspline.rst">三维直角坐标网格的 B 样条场插值</a></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><a href="https://gitee.com/peng-zilong123"><img src="docs/source/_static/contributors/pengzilong.jpg" width="80" height="80" alt="彭子龙"></a></span>
          <div class="ap-member-identity">
            <strong><a href="https://gitee.com/peng-zilong123">彭子龙</a></strong><br>
            <sub class="ap-member-role">维护者</sub>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <p class="ap-member-research"><strong>研究方向</strong><br>研究方向为电推进等离子体波动诊断与动力学机制，重点开展色散测量与高阶谱分析，后续拟结合实验与粒子模拟，探究多尺度波动耦合及其与电子输运的联系</p>
        <ul class="ap-work-items">
          <li><a href="docs/source/rst_files/A_Pusher/A03_Higuera_Cary_relativistic_3Dxyz.rst">三维直角坐标相对论 Higuera-Cary 粒子推进</a></li>
          <li><a href="docs/source/rst_files/B_Scatter/B01_scatter_3Dxyz.rst">三维直角坐标网格的粒子量沉积</a></li>
          <li><a href="docs/source/rst_files/D_Poisson/D05_phi1d_to_phi3d.rst">电势数组转三维网格与 MPI 边界交换</a></li>
          <li><a href="docs/source/rst_files/D_Poisson/D06_phi_to_E.rst">由电势计算三维电场</a></li>
          <li><a href="docs/source/rst_files/H_MPI_Exchange/H03_mpi_exchange_den.rst">粒子沉积后密度数组的 MPI 边界交换</a></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><a href="https://gitee.com/HermiteCat"><img src="docs/source/_static/contributors/wangbaisheng.jpg" width="80" height="80" alt="王佰胜"></a></span>
          <div class="ap-member-identity">
            <strong><a href="https://gitee.com/HermiteCat">王佰胜</a></strong><br>
            <sub class="ap-member-role">维护者</sub>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <p class="ap-member-research"><strong>研究方向</strong><br>空间电推进空心阴极数值模拟</p>
        <ul class="ap-work-items">
          <li><a href="docs/source/rst_files/D_Poisson/D01_hypre_3Dxyz.rst">三维直角坐标 Poisson 方程的 HYPRE 求解接口</a></li>
          <li><a href="docs/source/rst_files/D_Poisson/D02_hypre_3Dxyz_bc.rst">含边界条件的三维直角坐标 Poisson 求解</a></li>
          <li><a href="docs/source/rst_files/D_Poisson/D03_hypre_3Draz_uniform.rst">均匀柱坐标网格的三维 Poisson 求解</a></li>
          <li><a href="docs/source/rst_files/D_Poisson/D04_hypre_3Draz_nonuniform.rst">非均匀柱坐标网格的三维 Poisson 求解</a></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><a href="https://orcid.org/0009-0009-6248-9781"><img src="docs/source/_static/contributors/lihuan-xie.svg" width="80" height="80" alt="谢礼桓"></a></span>
          <div class="ap-member-identity">
            <strong><a href="https://orcid.org/0009-0009-6248-9781">谢礼桓</a></strong><br>
            <sub class="ap-member-role">维护者</sub>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <ul class="ap-work-items">
          <li><a href="docs/source/rst_files/G_Collision/G01_MCC.rst">基于空碰撞法的蒙特卡洛碰撞处理</a></li>
          <li><a href="docs/source/rst_files/G_Collision/G02_MCC_network.rst">C++ 蒙特卡洛碰撞网络（CSV 反应模型）</a></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><img src="docs/source/_static/contributors/wushun-zhang.svg" width="80" height="80" alt="张武顺"></span>
          <div class="ap-member-identity">
            <strong>张武顺</strong><br>
            <sub class="ap-member-role">维护者</sub>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <span class="ap-work-pending">待补充</span>
      </td>
    </tr>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><a href="https://github.com/GooseGH"><img src="docs/source/_static/contributors/zhongping-zhao.svg" width="80" height="80" alt="赵中平"></a></span>
          <div class="ap-member-identity">
            <strong><a href="https://github.com/GooseGH">赵中平</a></strong><br>
            <sub class="ap-member-role">维护者</sub>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <ul class="ap-work-items">
          <li><a href="docs/source/rst_files/A_Pusher/A01_Boris_3Dxyz.rst">三维直角坐标非相对论 Boris 粒子推进</a></li>
          <li><a href="docs/source/rst_files/A_Pusher/A02_Boris_3Drtz.rst">三维柱坐标非相对论 Boris 粒子推进</a></li>
          <li><a href="docs/source/rst_files/B_Scatter/B03_scatter_3Dxyz_bspline.rst">三维直角坐标网格的 B 样条粒子沉积</a></li>
          <li><a href="docs/source/rst_files/C_Gather/C01_gather_3Dxyz.rst">三维直角坐标网格的三线性场插值</a></li>
          <li><a href="docs/source/rst_files/C_Gather/C02_gather_3Dxyz_bspline.rst">三维直角坐标网格的 B 样条场插值</a></li>
          <li><a href="docs/source/rst_files/I_Initializer/I02_par_init_and_load.rst">离线生成并行加载初始粒子</a></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><img src="docs/source/_static/contributors/kunpeng-zhong.svg" width="80" height="80" alt="钟昆硼"></span>
          <div class="ap-member-identity">
            <strong>钟昆硼</strong><br>
            <sub class="ap-member-role">维护者</sub>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <span class="ap-work-pending">待补充</span>
      </td>
    </tr>
    <tr>
      <td class="ap-member" align="center" width="160" valign="top">
        <div class="ap-member-profile">
          <span class="ap-member-avatar"><a href="https://gitee.com/HIT-ZhouZhijun"><img src="docs/source/_static/contributors/zhijun-zhou.svg" width="80" height="80" alt="周志君"></a></span>
          <div class="ap-member-identity">
            <strong><a href="https://gitee.com/HIT-ZhouZhijun">周志君</a></strong><br>
            <sub class="ap-member-role">维护者</sub>
          </div>
        </div>
      </td>
      <td class="ap-work-cell" valign="top">
        <ul class="ap-work-items">
          <li><a href="docs/source/rst_files/B_Scatter/B02_deposit_3d_cyl.rst">三维柱坐标网格的电荷与电流密度沉积</a></li>
        </ul>
      </td>
    </tr>
  </tbody>
</table>

### 贡献者

<p align="center"><sub>贡献类型：💻 代码</sub></p>
<table>
  <tr>
    <td align="center" width="110" valign="top">
      <a href="https://github.com/bocong-zheng"><img src="https://github.com/bocong-zheng.png" width="80" height="80" alt="Bocong Zheng"></a><br>
      <sub><b>Bocong Zheng</b></sub><br>
      <sub><abbr title="代码">💻</abbr></sub>
    </td>
  </tr>
</table>

<p align="center"><sub>完整名单（含角色与链接）：<a href="https://algoplasma.readthedocs.io/en/latest/community/contributors.html">Read the Docs</a></sub></p>
<!-- CONTRIBUTORS:END -->

## 许可证

AlgoPlasma 采用 [Apache License 2.0](LICENSE) 开源许可证。版权和归属信息见 [NOTICE](NOTICE)。

## 发起人/联系人

- 赵隐剑 / Yinjian Zhao
- Email: contact@algoplasma.com
- Homepage: <https://homepage.hit.edu.cn/zhaoyinjian>
