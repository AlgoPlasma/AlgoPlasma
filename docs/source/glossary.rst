Glossary
========

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 常用术语

   本页统一 AlgoPlasma 文档中反复出现的网格、粒子和并行术语。模块页和测试页优先使用这里的写法。

   .. list-table:: 术语表
      :header-rows: 1
      :widths: 24 76

      * - 术语
        - 约定含义
      * - active cell
        - 当前 rank 或当前数组切片中由数值内核实际更新的物理单元，通常由 ``il``/``iu`` 指定。
      * - guard/ghost cell
        - active cell 外侧的辅助单元，用于保存边界填充或相邻 rank 交换来的 halo 数据。文档中 ``guard cell`` 和 ``ghost cell`` 视为同义词。
      * - halo layer
        - MPI 子域边界附近需要与邻居交换的一层或多层数据；写入本地数组后通常表现为 ghost cell。
      * - cell-centered
        - 变量位于网格单元中心。密度、标量势和部分流体量通常采用此约定。
      * - node-centered
        - 变量位于网格节点或顶点。高阶 shape function 或某些边界量可能需要这种定位。
      * - CIC
        - Cloud-In-Cell，一阶形函数；粒子贡献按到相邻网格点或网格单元的线性权重分配。
      * - NGP
        - Nearest-Grid-Point，最近网格点形函数；粒子贡献全部落到最近目标位置。
      * - Yee grid
        - Maxwell/FDTD 中的交错网格，电场和磁场分量在空间位置上错开，并在时间上采用 leapfrog 交错。
      * - MPI rank
        - MPI 并行程序中的一个进程编号；每个 rank 通常负责一个或多个子域。
      * - domain decomposition
        - 把全局网格切分到多个 MPI rank 的并行策略。
      * - gather
        - 网格到粒子的插值过程，例如把场量插值到粒子位置。
      * - scatter / deposition
        - 粒子到网格的沉积过程，例如把电荷或电流贡献写入网格数组。
      * - pusher
        - 粒子推进器，按给定场量和时间步更新粒子速度、位置或二者。
      * - FDTD
        - Finite-Difference Time-Domain，用时间域有限差分离散 Maxwell 方程。
      * - CPML
        - Convolutional Perfectly Matched Layer，用于 FDTD 边界吸收的 split-field 或 memory-variable 技术。
      * - MMS
        - Method of Manufactured Solutions，用人为构造的精确解和源项检查离散格式收敛阶。

.. container:: ap-lang ap-lang-en

   .. rubric:: Common Terms

   This page standardizes grid, particle, and parallel terms used throughout the
   AlgoPlasma documentation. Module and test pages should prefer these spellings and
   meanings.

   .. list-table:: Glossary
      :header-rows: 1
      :widths: 24 76

      * - Term
        - Meaning
      * - active cell
        - A physical cell actually updated by a numerical kernel on the current rank or array slice, usually specified by ``il``/``iu``.
      * - guard/ghost cell
        - Auxiliary cells outside active cells, used for boundary fill or halo data received from neighboring ranks. In this documentation, ``guard cell`` and ``ghost cell`` are treated as synonyms.
      * - halo layer
        - One or more layers of data near an MPI subdomain boundary that must be exchanged with neighbors; after exchange they usually occupy local ghost cells.
      * - cell-centered
        - A variable located at cell centers. Density, scalar potential, and some fluid quantities commonly use this convention.
      * - node-centered
        - A variable located at grid nodes or vertices. Higher-order shape functions or some boundary quantities may use this location.
      * - CIC
        - Cloud-In-Cell, a first-order shape function; particle contributions are distributed by linear weights to neighboring targets.
      * - NGP
        - Nearest-Grid-Point, a nearest-target shape function; a particle contribution is assigned entirely to the closest target.
      * - Yee grid
        - The staggered grid used by Maxwell/FDTD, with electric and magnetic components offset in space and advanced with leapfrog time staggering.
      * - MPI rank
        - One process in an MPI program; each rank usually owns one or more subdomains.
      * - domain decomposition
        - A parallel strategy that partitions the global mesh across MPI ranks.
      * - gather
        - Grid-to-particle interpolation, such as evaluating fields at particle positions.
      * - scatter / deposition
        - Particle-to-grid deposition, such as writing charge or current contributions into mesh arrays.
      * - pusher
        - A particle update routine that advances velocity, position, or both under given fields and a time step.
      * - FDTD
        - Finite-Difference Time-Domain discretization for Maxwell equations.
      * - CPML
        - Convolutional Perfectly Matched Layer, a split-field or memory-variable absorbing-boundary technique for FDTD.
      * - MMS
        - Method of Manufactured Solutions, where a constructed exact solution and source terms are used to check convergence order.
