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

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   ``D_Poisson`` 提供 AlgoPlasma 中的静电 Poisson 求解器文档入口。当前实现围绕
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

   .. rubric:: 边界条件离散与实现

   边界条件在这里不是 HYPRE 的运行时选项，而是线性系统组装的一部分。对一个靠近物理边界的
   cell-centered 未知量 :math:`\phi_P`，边界外侧的 ghost-cell 值 :math:`\phi_g` 不作为新的未知量交给
   HYPRE；组装例程会用边界关系消去 :math:`\phi_g`，并把影响折算到当前 cell 的对角项和 RHS 中。
   因此 ``A_values`` 和 ``rho1d``/``RHS`` 必须在调用 HYPRE setup/solve 前已经包含所有边界修正。

   .. list-table:: 边界码和面顺序
      :header-rows: 1
      :widths: 22 24 24 30

      * - 求解器
        - 面顺序
        - 边界码
        - 主要装配入口
      * - :doc:`D02_hypre_3Dxyz_bc <D_Poisson/D02_hypre_3Dxyz_bc>`
        - ``(xmin,xmax,ymin,ymax,zmin,zmax)``
        - ``1`` Dirichlet, ``2`` Neumann, ``3`` dielectric, ``4`` outflow
        - :doc:`sub_D02_hypre_3Dxyz_bc_A <D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A>`,
          :doc:`dielectric <D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A_dielectric>`,
          :doc:`outflow <D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A_outflow>`
      * - :doc:`D03_hypre_3Draz_uniform <D_Poisson/D03_hypre_3Draz_uniform>` /
          :doc:`D04_hypre_3Draz_nonuniform <D_Poisson/D04_hypre_3Draz_nonuniform>`
        - ``(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)``
        - ``0`` none, ``1`` axis, ``2`` Dirichlet, ``3`` Neumann, ``4`` dielectric, ``5`` outflow
        - D03/D04 的 ``*_A`` 基础装配，以及对应 ``*_bc_A_dielectric``、``*_bc_A_outflow`` 后处理例程

   对 Dirichlet 边界，边界值 :math:`\phi_b` 位于 cell center 与 ghost center 之间的半格位置。均匀
   Cartesian 情况下有

   .. math::

      \phi_b = \frac{\phi_P+\phi_g}{2},
      \qquad
      \phi_g = 2\phi_b-\phi_P .

   将它代入 D02 归一化的 7 点格式
   :math:`6\phi_P-\sum_N\phi_N-\phi_g = h^2\rho/\varepsilon_0` 后，当前行等价于
   对角项增加 ``1``，对应 ghost 方向的 off-diagonal 置零，RHS 增加 :math:`2\phi_b`。这正是
   ``sub_D02_hypre_3Dxyz_bc_A`` 对 ``bc(face)==1`` 的处理。D03/D04 使用有限体积形式；若边界面
   面积为 :math:`S_f`、法向半格距离为 :math:`d_n/2`，则边界贡献写成

   .. math::

      c_b = \frac{2S_f}{d_n}, \qquad
      A_{PP} \leftarrow A_{PP}+c_b,\qquad
      b_P \leftarrow b_P+c_b\phi_b .

   其中 D03 使用均匀 ``dr``/``da``/``dz`` 计算 :math:`S_f` 和 :math:`d_n`，D04 使用局部非均匀网格间距。

   .. figure:: ../images/D_Poisson/D02_hypre_3Dxyz_bc_Dirichlet.png
      :align: center
      :width: 58%

      Dirichlet 边界通过半格边界值消去 ghost-cell 势函数。

   对 Neumann 边界，D02 的 ``phibc`` 使用归一化电场量：``phibc = h*E``，其中
   :math:`\mathbf{E}=-\nabla\phi`，并按代码的面方向约定进入 RHS。低端面
   ``xmin/ymin/zmin`` 给 RHS 加 ``phibc(face)``，高端面 ``xmax/ymax/zmax`` 从 RHS 减
   ``phibc(face)``；对应 ghost 方向的 off-diagonal 置零，对角项减少 ``1``。可理解为用一阶边界关系
   :math:`\phi_g=\phi_P\mp hE_n` 消去 ghost-cell。D03/D04 的约定不同：
   ``bc_value(face)`` 是该面的外法向导数 :math:`\partial\phi/\partial n`，面方向符号已经包含在这个外法向定义中，
   因此六个面统一使用

   .. math::

      b_P \leftarrow b_P - S_f \left.\frac{\partial\phi}{\partial n}\right|_f .

   零 Neumann，也就是绝缘/无通量电势边界的常见形式，对应 ``phibc=0`` 或
   ``bc_value=0``；它不会向 RHS 加源项，只会移除外侧 ghost coupling。

   .. figure:: ../images/D_Poisson/D02_hypre_3Dxyz_bc_Neumann.png
      :align: center
      :width: 58%

      Neumann 边界把法向导数折算为当前 cell 的 RHS 修正。

   柱坐标的 ``BC_AXIS`` 只允许用于 ``r_lo``。它表示 :math:`r=0` 轴线处的几何约束，而不是普通
   Cartesian 面边界。D03/D04 在轴线上不添加跨轴通量项；轴线处的对称性和 :math:`rS_f` 几何因子已经由
   柱坐标有限体积系数体现。径向周期性被显式禁止，``alpha`` 和 ``z`` 的周期性则通过 HYPRE Struct
   periodic metadata 和边界处的 fallback 系数组装共同处理。

   dielectric 边界用于把已知面电荷折算进 Poisson 方程。对应修正例程只处理标记为 dielectric 的面：
   先把该面的四个 nodal surface-charge 值算术平均到相邻 cell，再按面方向把它加入 RHS。当前实现约定
   低端面 ``r_lo/a_lo/z_lo`` 或 ``xmin/ymin/zmin`` 加入平均 surface term，高端面减去平均 surface term；
   surface 数组本身应已经包含所需的物理量纲和符号缩放。矩阵上，如果对应 off-diagonal slot 仍有跨面耦合，
   例程会将该 slot 清零，并把原有 face contribution 从对角项中移除或转换，避免 HYPRE 再连接边界外的 ghost-cell。

   outflow 边界是远场 Robin 型近似，常用于让电势在外边界向参考值 :math:`\phi_\infty` 衰减。以参考点
   :math:`\mathbf{r}_0` 为中心，边界面中心到参考点的向量为 :math:`\mathbf{d}`，外法向为
   :math:`\mathbf{n}`，则代码使用

   .. math::

      k_b = \frac{\mathbf{d}\cdot\mathbf{n}}{|\mathbf{d}|^2},
      \qquad
      \eta = k_b d_n,
      \qquad
      \gamma = \frac{2\eta}{\eta+2}.

   由此得到 ghost-cell 消元关系

   .. math::

      \phi_g = (1-\gamma)\phi_P+\gamma\phi_\infty .

   D02 是单位网格归一化的 Cartesian 实现，相当于直接使用 ``kb`` 形成
   ``(kb-2)/(kb+2)`` 的对角修正和 ``2*kb/(kb+2)*phi_infty`` 的 RHS 修正。D03/D04 在柱坐标中先用
   ``r0_cyl=(r0,alpha0,z0)`` 计算 cylindrical 距离、法向投影和局部法向间距 ``dn``，再通过上式的
   ``gamma`` 把对应 face coefficient 转换为对角项和 RHS 项。若参考点落在被处理的边界面中心，或
   ``eta+2`` 过小，D03/D04 的 outflow 例程会停止，以避免奇异 Robin 系数。

   这些边界路径的回归验证分散在测试页中：Cartesian D02 的解析边界组合见
   :doc:`/tests/001_poisson/D02_hypre_3Dxyz_bc`，均匀柱坐标 D03 的单 rank/MPI 边界见
   :doc:`/tests/001_poisson/D03_hypre_3Draz_uniform`，非均匀柱坐标 D04 的边界和 MMS 对比见
   :doc:`/tests/001_poisson/D04_hypre_3Draz_nonuniform`。

   .. rubric:: 测试与图片

   Poisson 参考测试已整理在 :doc:`/tests/001_poisson/index`。该测试页包含 ``test00`` 到
   ``test07`` 的运行环境、误差表和参考图片。本节只描述 D_Poisson API 与算法结构，
   不重复保存测试结果；修改求解器或绘图脚本后，应重新运行测试页中对应用例并刷新图片。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   ``D_Poisson`` is the documentation entry point for the electrostatic Poisson
   solvers in AlgoPlasma. The current implementation is organized around the HYPRE
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

   .. rubric:: Boundary-Condition Discretization And Implementation

   Boundary conditions are assembled into the linear system; they are not a
   runtime option inferred by HYPRE. For a cell-centered unknown :math:`\phi_P`
   adjacent to a physical boundary, the outside ghost-cell value
   :math:`\phi_g` is not passed to HYPRE as a new unknown. The assembly routines
   eliminate :math:`\phi_g` through the boundary relation and fold the effect
   into the current row diagonal and right-hand side. Therefore ``A_values`` and
   ``rho1d``/``RHS`` must already contain all boundary corrections before the
   HYPRE setup/solve stage.

   .. list-table:: Boundary codes and face order
      :header-rows: 1
      :widths: 22 24 24 30

      * - Solver
        - Face order
        - Boundary codes
        - Main assembly entry points
      * - :doc:`D02_hypre_3Dxyz_bc <D_Poisson/D02_hypre_3Dxyz_bc>`
        - ``(xmin,xmax,ymin,ymax,zmin,zmax)``
        - ``1`` Dirichlet, ``2`` Neumann, ``3`` dielectric, ``4`` outflow
        - :doc:`sub_D02_hypre_3Dxyz_bc_A <D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A>`,
          :doc:`dielectric <D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A_dielectric>`,
          :doc:`outflow <D_Poisson/D02_hypre_3Dxyz_bc/sub_D02_hypre_3Dxyz_bc_A_outflow>`
      * - :doc:`D03_hypre_3Draz_uniform <D_Poisson/D03_hypre_3Draz_uniform>` /
          :doc:`D04_hypre_3Draz_nonuniform <D_Poisson/D04_hypre_3Draz_nonuniform>`
        - ``(r_lo,r_hi,a_lo,a_hi,z_lo,z_hi)``
        - ``0`` none, ``1`` axis, ``2`` Dirichlet, ``3`` Neumann, ``4`` dielectric, ``5`` outflow
        - D03/D04 base ``*_A`` assembly plus the corresponding ``*_bc_A_dielectric`` and ``*_bc_A_outflow`` post-processors

   For a Dirichlet boundary, the prescribed value :math:`\phi_b` lies halfway
   between the cell center and the ghost center. On a uniform Cartesian grid,

   .. math::

      \phi_b = \frac{\phi_P+\phi_g}{2},
      \qquad
      \phi_g = 2\phi_b-\phi_P .

   Substituting this into the D02 normalized 7-point equation
   :math:`6\phi_P-\sum_N\phi_N-\phi_g = h^2\rho/\varepsilon_0` increases the
   current row diagonal by ``1``, zeros the off-diagonal slot in the ghost
   direction, and adds :math:`2\phi_b` to the RHS. This is the
   ``bc(face)==1`` path in ``sub_D02_hypre_3Dxyz_bc_A``. D03/D04 use a
   finite-volume form. If a boundary face has area :math:`S_f` and normal
   spacing :math:`d_n`, the Dirichlet contribution is

   .. math::

      c_b = \frac{2S_f}{d_n}, \qquad
      A_{PP} \leftarrow A_{PP}+c_b,\qquad
      b_P \leftarrow b_P+c_b\phi_b .

   D03 computes :math:`S_f` and :math:`d_n` from uniform ``dr``/``da``/``dz``;
   D04 computes them from local nonuniform mesh spacing.

   .. figure:: ../images/D_Poisson/D02_hypre_3Dxyz_bc_Dirichlet.png
      :align: center
      :width: 58%

      Dirichlet boundaries eliminate the ghost-cell potential through the
      half-cell boundary value.

   For a Neumann boundary, D02 uses the normalized electric-field value
   ``phibc = h*E`` with :math:`\mathbf{E}=-\nabla\phi`, following the face
   orientation used by the code. Low faces ``xmin/ymin/zmin`` add
   ``phibc(face)`` to the RHS, while high faces ``xmax/ymax/zmax`` subtract
   ``phibc(face)``. The ghost-direction off-diagonal slot is zeroed and the
   diagonal is reduced by ``1``. This is equivalent to eliminating the ghost
   cell with a first-order relation :math:`\phi_g=\phi_P\mp hE_n`. D03/D04 use a
   different public convention: ``bc_value(face)`` is the prescribed outward
   normal derivative :math:`\partial\phi/\partial n`. The face-orientation sign
   is already part of that outward-normal derivative, so all six faces use

   .. math::

      b_P \leftarrow b_P - S_f \left.\frac{\partial\phi}{\partial n}\right|_f .

   Zero Neumann, the common insulating/no-flux potential boundary, corresponds
   to ``phibc=0`` or ``bc_value=0``. It adds no source term to the RHS and only
   removes the outside ghost coupling.

   .. figure:: ../images/D_Poisson/D02_hypre_3Dxyz_bc_Neumann.png
      :align: center
      :width: 58%

      Neumann boundaries convert the prescribed normal derivative into an RHS
      correction on the adjacent cell.

   In cylindrical coordinates, ``BC_AXIS`` is valid only on ``r_lo``. It
   represents the geometric constraint at :math:`r=0`, not an ordinary Cartesian
   face boundary. D03/D04 add no cross-axis flux at the axis; the symmetry and
   the :math:`rS_f` geometric factor are already represented by the cylindrical
   finite-volume coefficients. Radial periodicity is explicitly rejected, while
   ``alpha`` and ``z`` periodicity are handled by HYPRE Struct periodic metadata
   together with boundary-face fallback coefficients.

   Dielectric boundaries fold known surface charge into the Poisson equation.
   The correction routines process only faces marked as dielectric: they
   average the four nodal surface-charge values on the face to the adjacent
   cell and then apply a signed RHS correction. The current implementation adds
   the averaged surface term on low faces, ``r_lo/a_lo/z_lo`` or
   ``xmin/ymin/zmin``, and subtracts it on high faces. The surface arrays are
   expected to already contain the required physical scaling and sign. In the
   matrix, if the relevant off-diagonal stencil slot still contains a coupling
   across the boundary face, the routine zeros that slot and removes or converts
   the existing face contribution in the diagonal so HYPRE does not connect the
   row to an outside ghost cell.

   Outflow boundaries are far-field Robin approximations, usually used to let
   the potential decay toward a reference value :math:`\phi_\infty`. With a
   reference point :math:`\mathbf{r}_0`, boundary-face center displacement
   :math:`\mathbf{d}`, outward normal :math:`\mathbf{n}`, and local normal
   spacing :math:`d_n`, the implementation uses

   .. math::

      k_b = \frac{\mathbf{d}\cdot\mathbf{n}}{|\mathbf{d}|^2},
      \qquad
      \eta = k_b d_n,
      \qquad
      \gamma = \frac{2\eta}{\eta+2}.

   This gives the ghost-cell elimination relation

   .. math::

      \phi_g = (1-\gamma)\phi_P+\gamma\phi_\infty .

   D02 is the unit-spaced Cartesian implementation, so it uses ``kb`` directly
   to form the diagonal correction ``(kb-2)/(kb+2)`` and the RHS correction
   ``2*kb/(kb+2)*phi_infty``. D03/D04 first compute cylindrical distance,
   normal projection, and local ``dn`` from ``r0_cyl=(r0,alpha0,z0)``, then use
   ``gamma`` above to convert the corresponding face coefficient into diagonal
   and RHS terms. If the reference point lies on a processed boundary-face
   center, or if ``eta+2`` is too small, the D03/D04 outflow routines stop to
   avoid a singular Robin coefficient.

   Regression coverage for these paths is documented in the Poisson test pages:
   Cartesian D02 analytic boundary combinations in
   :doc:`/tests/001_poisson/D02_hypre_3Dxyz_bc`, uniform cylindrical D03
   single-rank/MPI boundary tests in
   :doc:`/tests/001_poisson/D03_hypre_3Draz_uniform`, and nonuniform
   cylindrical D04 boundary plus MMS comparisons in
   :doc:`/tests/001_poisson/D04_hypre_3Draz_nonuniform`.

   .. rubric:: Tests and Figures

   The Poisson reference tests are documented in :doc:`/tests/001_poisson/index`.
   That page includes the runtime notes, error tables, and reference figures for
   ``test00`` through ``test07``. This section describes D_Poisson APIs and
   algorithm structure; it intentionally does not duplicate the test results. If a
   solver or plotting script changes, rerun the relevant test page cases and
   refresh those images.
