D_Poisson
=========

.. toctree::
    :maxdepth: 1

    D_Poisson/D01_hypre_3Dxyz
    D_Poisson/D02_hypre_3Dxyz_bc
    D_Poisson/D03_hypre_3Draz_uniform
    D_Poisson/D04_hypre_3Draz_nonuniform
    D_Poisson/D05_phi1d_to_phi3d
    D_Poisson/D06_phi_to_E

.. raw:: html

   <div class="pmsl-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="zh">中文</button>
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="en">English</button>
   </div>

.. container:: pmsl-lang pmsl-lang-zh

   .. rubric:: 概览

   ``D_Poisson`` 提供 PMSL 中的静电 Poisson 求解器文档入口。当前实现围绕
   HYPRE Struct 接口组织，覆盖 Cartesian ``(x,y,z)`` 网格、
   柱坐标均匀 ``(r,alpha,z)`` 网格，以及柱坐标非均匀 ``(r,alpha,z)`` 网格。
   这些求解器面向 PIC 中的电势 :math:`\phi` 求解，输入通常是已经沉积到网格上的电荷密度
   :math:`\rho` 和边界条件信息，输出是 cell-centered 势函数数组。

   .. list-table:: 模块关系
      :header-rows: 1
      :widths: 16 24 30 30

      * - 模块
        - 坐标/网格
        - 主要职责
        - 典型测试入口
      * - :doc:`D01_hypre_3Dxyz <D_Poisson/D01_hypre_3Dxyz>`
        - Cartesian ``(x,y,z)``
        - 早期 C/HYPRE 7 点 stencil 求解器和 Fortran-C 桥接。
        - ``tests/001_poisson/test00``
      * - :doc:`D02_hypre_3Dxyz_bc <D_Poisson/D02_hypre_3Dxyz_bc>`
        - Cartesian ``(x,y,z)``
        - Cartesian 矩阵/RHS 组装，支持 Dirichlet、Neumann、dielectric、outflow 等边界处理。
        - ``tests/001_poisson/test01``、``test02``
      * - :doc:`D03_hypre_3Draz_uniform <D_Poisson/D03_hypre_3Draz_uniform>`
        - 均匀柱坐标 ``(r,alpha,z)``
        - 均匀网格的单进程和 MPI-local 矩阵组装，以及轴线、周期和物理边界修正。
        - ``tests/001_poisson/test03``、``test04``，以及 ``test07`` 中的均匀网格 MMS 部分
      * - :doc:`D04_hypre_3Draz_nonuniform <D_Poisson/D04_hypre_3Draz_nonuniform>`
        - 非均匀柱坐标 ``(r,alpha,z)``
        - 非均匀网格的单进程和 MPI-local 矩阵组装，使用局部网格间距与 ghost 层信息。
        - ``tests/001_poisson/test05``、``test06``，以及 ``test07`` 中的非均匀网格 MMS 部分
      * - :doc:`D05_phi1d_to_phi3d <D_Poisson/D05_phi1d_to_phi3d>`
        - Cartesian ``(x,y,z)``
        - 将 HYPRE 1D 解向量解包为 3D ghost-cell 数组，并执行 phi 场的 MPI halo 交换。
        - Poisson 求解后、计算电场前的衔接步骤；无独立测试用例
      * - :doc:`D06_phi_to_E <D_Poisson/D06_phi_to_E>`
        - Cartesian ``(x,y,z)``
        - 用二阶中心差分由势函数 :math:`\phi` 计算电场三分量（:math:`\mathbf{E}=-\nabla\phi`，dx=dy=dz=1）。
        - 同上，配合 D05 使用

   .. rubric:: Poisson 方程与离散形式

   静电 PIC 中求解的基本方程为

   .. math::

      \nabla^2 \phi(\mathbf{r}) = -\frac{\rho(\mathbf{r})}{\varepsilon_0}.

   在 cell-centered 结构网格上，离散问题写成线性系统

   .. math::

      A\boldsymbol{\phi} = \boldsymbol{b},

   其中 ``A_values`` 存放每个 cell 的 stencil 系数，``rho1d`` 或 ``RHS`` 存放右端项和边界修正，
   ``phi1d`` 存放 HYPRE 返回的势函数。Cartesian 均匀网格的内部点通常是 7 点 stencil：
   中心点加六个坐标方向相邻点。D03/D04 在柱坐标中仍保持 7 点邻接拓扑，但系数包含半径、
   角向尺度、网格间距和轴线几何项。

   .. figure:: ../images/D_Poisson/D01_hypre_3Dxyz_7pt_stencil.png
      :align: center
      :width: 62%

      Cartesian 7 点 stencil 中心项与六个邻接方向。

   .. rubric:: HYPRE Struct 工作流

   D02-D04 的求解层遵循同一类 HYPRE Struct 流程：创建局部 grid box，定义 stencil，
   组装矩阵和向量，调用对应的 HYPRE setup/solve，然后将解复制回 Fortran 数组。边界条件不由求解器
   自动推断；各 ``*_A`` 组装例程会先把物理边界、MPI 邻接、周期方向、介质面电荷或 outflow
   修正折算进矩阵和 RHS。

   .. rubric:: 边界条件分工

   D02 的 Cartesian 组装例程处理六个物理面上的 Dirichlet、Neumann、dielectric 和 outflow 类型。
   D03/D04 在柱坐标中还需要额外处理 ``r=0`` 轴线几何、``alpha`` 周期方向和 MPI 子域邻接。
   其中 dielectric 修正通过面电荷项改变 RHS 和对应 stencil 项；outflow 修正通过 Robin 型关系消去
   ghost-cell 耦合。调用顺序应保持为：先组装基础矩阵/RHS，再叠加边界修正，最后进入 HYPRE solve。

   .. rubric:: 测试与图片

   Poisson 参考测试已整理在 :doc:`/tests/001_poisson/index`。该测试页包含 ``test00`` 到
   ``test07`` 的运行环境、误差表和参考图片。本节只描述 D_Poisson API 与算法结构，
   不重复保存测试结果；修改求解器或绘图脚本后，应重新运行测试页中对应用例并刷新图片。

.. container:: pmsl-lang pmsl-lang-en

   .. rubric:: Overview

   ``D_Poisson`` is the documentation entry point for the electrostatic Poisson
   solvers in PMSL. The current implementation is organized around the HYPRE
   Struct interface. It covers Cartesian ``(x,y,z)`` grids,
   uniform cylindrical ``(r,alpha,z)`` grids, and nonuniform cylindrical
   ``(r,alpha,z)`` grids. In PIC workflows these solvers take charge density and
   boundary-condition data on a cell-centered grid and return the electric
   potential :math:`\phi`.

   .. list-table:: Module Map
      :header-rows: 1
      :widths: 16 24 30 30

      * - Module
        - Coordinates / grid
        - Main responsibility
        - Typical test entry
      * - :doc:`D01_hypre_3Dxyz <D_Poisson/D01_hypre_3Dxyz>`
        - Cartesian ``(x,y,z)``
        - Early C/HYPRE 7-point-stencil solver with a Fortran-C bridge.
        - ``tests/001_poisson/test00``
      * - :doc:`D02_hypre_3Dxyz_bc <D_Poisson/D02_hypre_3Dxyz_bc>`
        - Cartesian ``(x,y,z)``
        - Cartesian matrix/RHS assembly with Dirichlet, Neumann, dielectric, and outflow boundary handling.
        - ``tests/001_poisson/test01`` and ``test02``
      * - :doc:`D03_hypre_3Draz_uniform <D_Poisson/D03_hypre_3Draz_uniform>`
        - Uniform cylindrical ``(r,alpha,z)``
        - Single-domain and MPI-local matrix assembly with axis, periodic, and physical boundary corrections.
        - ``tests/001_poisson/test03``, ``test04``, plus the uniform-grid MMS part of ``test07``
      * - :doc:`D04_hypre_3Draz_nonuniform <D_Poisson/D04_hypre_3Draz_nonuniform>`
        - Nonuniform cylindrical ``(r,alpha,z)``
        - Single-domain and MPI-local matrix assembly using local spacing and ghost-layer data.
        - ``tests/001_poisson/test05``, ``test06``, plus the nonuniform-grid MMS part of ``test07``
      * - :doc:`D05_phi1d_to_phi3d <D_Poisson/D05_phi1d_to_phi3d>`
        - Cartesian ``(x,y,z)``
        - Unpack the HYPRE 1D solution into a 3D ghost-cell array and perform MPI halo exchange for the phi field.
        - Post-solve / pre-E-field bridge step; no standalone test case
      * - :doc:`D06_phi_to_E <D_Poisson/D06_phi_to_E>`
        - Cartesian ``(x,y,z)``
        - Compute the three electric-field components from :math:`\phi` using second-order central differences (:math:`\mathbf{E}=-\nabla\phi`, dx=dy=dz=1).
        - Same; used together with D05

   .. rubric:: Poisson Equation and Discretization

   The electrostatic PIC equation solved here is

   .. math::

      \nabla^2 \phi(\mathbf{r}) = -\frac{\rho(\mathbf{r})}{\varepsilon_0}.

   On a cell-centered structured grid, the discretized problem is represented as

   .. math::

      A\boldsymbol{\phi} = \boldsymbol{b},

   where ``A_values`` stores stencil coefficients, ``rho1d`` or ``RHS`` stores
   the right-hand side plus boundary corrections, and ``phi1d`` stores the
   potential returned by HYPRE. On a uniform Cartesian mesh the interior operator
   is the standard 7-point stencil: one center coefficient and six neighbor
   coefficients. D03/D04 keep the same neighbor topology in cylindrical
   coordinates, but their coefficients include radius, angular scale, mesh
   spacing, and axis-geometry terms.

   .. figure:: ../images/D_Poisson/D01_hypre_3Dxyz_7pt_stencil.png
      :align: center
      :width: 62%

      Center and neighbor directions for the Cartesian 7-point stencil.

   .. rubric:: HYPRE Struct Workflow

   D02-D04 use the same HYPRE Struct pattern: create a local grid box, define a
   stencil, assemble the matrix and vectors, run the corresponding HYPRE
   setup/solve calls, and copy the solution back to Fortran arrays. Physical
   boundary conditions are not inferred by the solver. The ``*_A`` assembly routines fold physical boundaries, MPI-neighbor
   interfaces, periodic topology, dielectric surface charge, and outflow
   corrections into the matrix and right-hand side before the solve.

   .. rubric:: Boundary-Condition Responsibilities

   D02 Cartesian assembly handles Dirichlet, Neumann, dielectric, and outflow
   types on the six physical faces. D03/D04 also account for ``r=0`` axis
   geometry, ``alpha`` periodicity, and MPI subdomain adjacency in cylindrical
   coordinates. Dielectric corrections modify the RHS and relevant stencil
   entries through surface-charge terms; outflow corrections eliminate
   ghost-cell coupling through a Robin-type relation. The intended order is:
   assemble the base matrix/RHS, apply boundary corrections, then enter the
   HYPRE solve.

   .. rubric:: Tests and Figures

   The Poisson reference tests are documented in :doc:`/tests/001_poisson/index`.
   That page includes the runtime notes, error tables, and reference figures for
   ``test00`` through ``test07``. This section describes D_Poisson APIs and
   algorithm structure; it intentionally does not duplicate the test results. If a
   solver or plotting script changes, rerun the relevant test page cases and
   refresh those images.
