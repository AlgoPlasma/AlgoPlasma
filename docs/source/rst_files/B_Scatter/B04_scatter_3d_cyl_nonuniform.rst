B04: Nonuniform Cylindrical Density Deposition
==============================================

.. toctree::
   :maxdepth: 1
   :hidden:
   :titlesonly:

   B04_scatter_3d_cyl_nonuniform/mod_B04_scatter_3d_cyl_nonuniform
   B04_scatter_3d_cyl_nonuniform/sub_B04_build_geometry
   B04_scatter_3d_cyl_nonuniform/sub_B04_scatter_3d_cyl_nonuniform
   B04_scatter_3d_cyl_nonuniform/sub_B04_average_axis
   B04_scatter_3d_cyl_nonuniform/sub_B04_project_density
   B04_scatter_3d_cyl_nonuniform/usage

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-b04-doc

   .. rubric:: 非均匀柱坐标网格上的粒子沉积

   **B04 将宏粒子代表的粒子数或电荷分配到周围节点，得到节点数密度或电荷密度。**
   它采用线性 CIC（cloud-in-cell）权重，适用于柱坐标 :math:`(r,\phi,z)` 下的结构化张量积网格：三个方向的间距均可独立变化，区域可以包含轴线，也可以是环域。

   .. rubric:: 按阅读目的进入

   - **理解算法：** 先看 :ref:`均匀到非均匀的变化 <b04-grid-difference-zh>`，再读 :ref:`基本思想 <b04-principle-zh>` 和 :ref:`网格约定 <b04-grid-zh>`；详细推导与代码分别由几何准备页和沉积页承接。
   - **在程序中调用：** 查看 :ref:`调用流程 <b04-workflow-zh>`，再用 :doc:`完整调用示例 <B04_scatter_3d_cyl_nonuniform/usage>` 组织自己的代码。
   - **查接口与公共量：** 进入 :doc:`模块入口 <B04_scatter_3d_cyl_nonuniform/mod_B04_scatter_3d_cyl_nonuniform>`；参数细节在各子程序页，:ref:`状态码 <b04-status-zh>` 集中在模块页。
   - **查看验证依据：** :doc:`测试与结果 </tests/004_scatter/B04_scatter_3d_cyl_nonuniform>` 给出已有算例的输入、参考量、判据和结果。

   .. _b04-grid-difference-zh:

   .. rubric:: 从均匀到非均匀：哪些变化决定算法构造？

   这里比较的是 **同一柱坐标系下的均匀网格与非均匀网格**。两者的物理体积元都是
   :math:`dV=r\,dr\,d\phi\,dz`，都要计入半径对体积的影响。非均匀网格进一步允许节点两侧的单元宽度不同。

   .. list-table:: 网格变化及对应处理
      :header-rows: 1
      :widths: 23 35 42

      * - 计算环节
        - 均匀柱坐标网格
        - B04 的一般构造
      * - 单元内的位置比例
        - 每个方向使用固定步长
        - 用所在单元的实际宽度计算比例；三个方向的线性权重仍相乘，分配给八个顶点
      * - 有效节点体积
        - 相邻等宽单元使积分公式简化；体积仍随半径和端点位置变化
        - 汇集节点相邻单元的形函数积分，计入各自宽度及径向因子
      * - 全周轴线上的密度合并
        - 均匀角网格具有相同的角向积分权重，可作算术平均
        - 使用角向积分权重平均；权重相同时自然得到算术平均

   .. admonition:: 构造依据：分配权重与有效体积配套

      **先由实际节点坐标确定线性分配权重，再对同一节点形函数按柱坐标体积元积分，得到归一化体积。**
      均匀物理密度应在非均匀网格上仍表示为相同的密度值；这一要求解释了为何采用配套积分。
      推导和径向示意图见 :ref:`几何准备页 <b04-matching-volume-zh>`。

   张量积网格与形函数使三维积分分解为径向、角向和轴向三个一维积分。
   **几何量只依赖网格，粒子分配权重随粒子位置变化**，因此程序可先准备几何量，再供逐粒子沉积复用。
   这两个性质在均匀网格中同样成立；具体分解见 :ref:`从一维积分到实现 <b04-geometry-assembly-zh>`。

   .. _b04-principle-zh:

   .. rubric:: 从粒子贡献量到节点密度

   理解沉积时，可以先沿着 **分配贡献量 → 确定配套体积 → 得到密度** 阅读：

   1. **分配到节点。** 粒子位于一个坐标单元内；各方向的左右线性权重相乘，得到八个顶点的权重 :math:`S_{ijk}^{(p)}`。权重之和为一，因此完整分配粒子贡献量 :math:`c_p`。具体计算见 :doc:`沉积例程 <B04_scatter_3d_cyl_nonuniform/sub_B04_scatter_3d_cyl_nonuniform>`。
   2. **确定有效节点体积。** 节点密度对应的体积由同一节点形函数在物理域内积分得到。柱坐标体积元包含径向因子 :math:`r`，因此体积随半径、相邻单元宽度和端点位置变化。积分过程见 :doc:`几何准备 <B04_scatter_3d_cyl_nonuniform/sub_B04_build_geometry>`。
   3. **累加密度。** 将分配量除以对应有效体积，累加到节点密度。

   .. math::

      V_{ijk}=\int_\Omega S_{ijk}(r,\phi,z)\,r\,dr\,d\phi\,dz,\qquad
      D_{ijk}\mathrel{+}=\frac{c_p S_{ijk}^{(p)}}{V_{ijk}}.

   :math:`S_{ijk}` 是节点基函数，:math:`S_{ijk}^{(p)}` 是它在粒子位置的值，:math:`\Omega` 是物理沉积域。
   代码中，:math:`D_{ijk}` 对应 ``density(i,j,k)``，:math:`c_p` 对应 ``amount``，
   :math:`1/V_{ijk}` 对应 ``inv_volume(i,j,k)``。

   **沉积输出已经是密度。** 从零开始累加并对独立节点各计一次时，:math:`\sum_{ijk}V_{ijk}D_{ijk}=\sum_p c_p`。

   ``amount=wp`` 表示宏粒子代表的真实粒子数，输出数密度；``amount=qp*wp`` 表示带符号电荷量，输出电荷密度。
   长度使用 m、电荷使用 C 时，单位分别为 :math:`\mathrm{m}^{-3}` 和 :math:`\mathrm{C\,m}^{-3}`。

   .. _b04-grid-zh:


   .. rubric:: 网格、物理位置和储存位置

   三维节点映射到物理空间为

   .. math::

      x_{ijk}=r_i\cos\phi_j,\qquad y_{ijk}=r_i\sin\phi_j,\qquad z_{ijk}=z_k.

   ``r(0:nr)`` 、``phi(0:nphi)`` 、``z(0:nz)`` 是节点坐标，``nr/nphi/nz`` 是各方向单元数。
   半径保留相对于圆柱轴线的真实距离；``r(0)>0`` 表示环域，不能为了从零开始索引而把半径整体减去内半径。
   角度使用弧度，径向和轴向使用同一长度单位。

   .. list-table:: 数组布局（采用零下界书写）
      :header-rows: 1
      :widths: 25 37 38

      * - 数组
        - 角向周期
        - 角向为两个物理端面
      * - ``density`` 、``inv_volume``
        - ``(0:nr,0:nphi-1,0:nz)``
        - ``(0:nr,0:nphi,0:nz)``
      * - ``phi_measure``
        - ``(0:nphi-1)``
        - ``(0:nphi)``
      * - ``cell_density``
        - ``(0:nr-1,0:nphi-1,0:nz-1)``
        - 同左

   **角向坐标始终保留区间的两个端点；周期密度只储存独立节点。** 周期长度为 ``phi(nphi)-phi(0)`` ，全周为 :math:`2\pi`。
   实参数组允许其他下界，其第一个元素在例程内映射为索引零；``cell`` 必须使用相同的相对编号。
   本接口使用上述物理节点范围；额外的通信缓冲层由调用方另行组织。

   .. _b04-workflow-zh:

   .. rubric:: 哪些工作准备一次，哪些工作每轮执行？

   **几何准备在网格建立或改变时执行；核心沉积在每轮的粒子循环内执行。**
   调用方在本轮开始时清零 ``density``，按应用边界规则处理粒子，并确定所在单元。
   下面按实际数据依赖列出四个环节，轴点和单元平均的调用条件分别标明。

   .. list-table:: 调用时机、输入与直接产物
      :header-rows: 1
      :widths: 30 30 40

      * - 环节与调用时机
        - 上游提供
        - 直接产物与去向
      * - :doc:`几何准备 <B04_scatter_3d_cyl_nonuniform/sub_B04_build_geometry>`：网格或周期设置改变时
        - 坐标数组、角向周期设置
        - ``inv_volume`` 供沉积使用；``phi_measure`` 供轴点平均使用。固定网格可复用
      * - :doc:`粒子沉积 <B04_scatter_3d_cyl_nonuniform/sub_B04_scatter_3d_cyl_nonuniform>`：每轮逐粒子调用
        - 位置、单元号、贡献量和逆体积
        - 累加 ``density``；供共享节点求和或后续节点运算使用
      * - :doc:`轴点平均 <B04_scatter_3d_cyl_nonuniform/sub_B04_average_axis>`：含轴全周区域，贡献汇集后
        - 完整轴线密度、角向积分权重
        - 更新 ``density`` 的轴线部分，使同一物理位置密度一致；环域直接使用内径节点
      * - :doc:`单元平均 <B04_scatter_3d_cyl_nonuniform/sub_B04_project_density>`：下游需要单元平均源项时
        - 完整节点密度、径向坐标、周期设置
        - 写出另一个数组 ``cell_density``；供单元平均源项组装使用

   .. admonition:: 本轮沉积结束后交给下游什么？

      **使用节点量的计算接收节点密度** ``density``。需要单元体积平均量时，使用 ``cell_density``。
      单元平均的物理含义见 :doc:`project_density <B04_scatter_3d_cyl_nonuniform/sub_B04_project_density>`；下游按自身离散方程的符号、单位和物理系数组装源项。

   .. rubric:: 分区计算时的衔接

   MPI 共享节点使用包含接口两侧基函数支撑的完整有效体积；调用方可先从全局几何准备，再按本地索引分发。
   各进程贡献使用相同体积，沉积后先求和，再对完整全周轴线平均。
   ``build_geometry`` 将输入坐标端点作为物理端点；分区接口的几何准备见其例程页。并发写入密度时，由调用方组织独立缓冲或同步。

   .. rubric:: 相关算法与文献

   :doc:`B02 <B02_deposit_3d_cyl>` 提供均匀柱坐标电荷与电流沉积；B04 使用显式非均匀节点坐标和调用方提供的单元号。
   两个模块的角向索引计数约定分别见各自接口；B04 测试直接调用 B02 的公开电荷沉积例程进行均匀网格对照。

   Liu, Z., Zhou, Z., Zhao, Y. (2026), *Conservative Charge and Current Deposition on Nonuniform 3D Cylindrical PIC Meshes with Residual Self-Field Diagnostics*.
   `预印本 v1 <https://arxiv.org/abs/2606.09168v1>`_，II.A–B（几何与密度沉积）、II.E（单元体积平均）。

   作者：Xin Luo。

   返回 :doc:`沉积学习入口 <scatter_learning_path>` · :doc:`使用指南 <scatter_usage_cookbook>`。

.. container:: ap-lang ap-lang-en ap-b04-doc

   .. rubric:: Particle deposition on nonuniform cylindrical grids

   **B04 distributes the number or charge represented by macroparticles to neighboring nodes and produces nodal number or charge density.**
   It uses linear CIC (cloud-in-cell) weights on a structured tensor-product grid in :math:`(r,\phi,z)`. Spacing can vary independently in all three directions, for either an axis-containing region or an annulus.

   .. rubric:: Choose a reading route

   - **Understand the method:** start with :ref:`what changes on a nonuniform mesh <b04-grid-difference-en>`, then the :ref:`principle <b04-principle-en>` and :ref:`grid conventions <b04-grid-en>`. The geometry and scatter pages develop the derivations and code.
   - **Call it from a program:** follow the :ref:`workflow <b04-workflow-en>` and adapt the :doc:`complete calling example <B04_scatter_3d_cyl_nonuniform/usage>`.
   - **Look up interfaces and shared definitions:** use the :doc:`module entry <B04_scatter_3d_cyl_nonuniform/mod_B04_scatter_3d_cyl_nonuniform>` and individual parameter pages. :ref:`Status codes <b04-status-en>` are collected on the module page.
   - **Inspect verification evidence:** :doc:`tests and results </tests/004_scatter/B04_scatter_3d_cyl_nonuniform>` describe inputs, references, criteria and saved results.

   .. _b04-grid-difference-en:

   .. rubric:: From uniform to nonuniform: what determines the construction?

   The comparison uses **uniform and nonuniform meshes in the same cylindrical coordinates**.
   Both use :math:`dV=r\,dr\,d\phi\,dz` and account for the radial variation of physical volume.
   A nonuniform mesh also allows different cell widths on the two sides of a node.

   .. list-table:: Mesh changes and their treatment
      :header-rows: 1
      :widths: 23 35 42

      * - Operation
        - Uniform cylindrical mesh
        - General construction in B04
      * - Position within a cell
        - A fixed spacing in each direction
        - Use the containing cell's actual widths; multiply three linear weights to assign the amount to eight vertices
      * - Effective nodal volume
        - Equal adjacent widths simplify the integrals; radius and endpoints still affect volume
        - Sum basis integrals over neighboring cells, including their widths and the radial factor
      * - Full-circle axis average
        - Equal angular integral weights permit an arithmetic mean
        - Use angular integral weights; equal weights give the arithmetic mean

   .. admonition:: Construction principle: match assignment and volume

      **Construct linear assignment weights from the actual nodes, then integrate the same nodal basis with the cylindrical volume element to obtain its normalization volume.**
      A constant physical density should retain the same value on a nonuniform mesh. This requirement explains the matching integral.
      See :ref:`geometry preparation <b04-matching-volume-en>` for the derivation and radial diagram.

   The tensor-product mesh and basis separate the volume integral into three one-dimensional integrals.
   **Geometry depends on the mesh, while assignment weights depend on particle position**, so geometry can be prepared and reused by per-particle deposition.
   Both properties also hold on uniform meshes; see :ref:`integrals and implementation <b04-geometry-assembly-en>`.

   .. _b04-principle-en:

   .. rubric:: From particle amount to nodal density

   Read the method as **distribute the amount → identify matching volumes → obtain density**:

   1. **Distribute to nodes.** Multiply lower/upper linear weights in three directions to obtain eight vertex weights :math:`S_{ijk}^{(p)}`. Their sum is one, distributing the full particle amount :math:`c_p`. See the :doc:`scatter routine <B04_scatter_3d_cyl_nonuniform/sub_B04_scatter_3d_cyl_nonuniform>`.
   2. **Identify effective nodal volumes.** Integrate the same nodal basis over the physical domain. The cylindrical volume element contains :math:`r`, so volumes depend on radius, adjacent cell widths and endpoints. See :doc:`geometry preparation <B04_scatter_3d_cyl_nonuniform/sub_B04_build_geometry>`.
   3. **Accumulate density.** Divide each assigned amount by its matching volume and add it to the nodal density.

   .. math::

      V_{ijk}=\int_\Omega S_{ijk}(r,\phi,z)\,r\,dr\,d\phi\,dz,\qquad
      D_{ijk}\mathrel{+}=\frac{c_p S_{ijk}^{(p)}}{V_{ijk}}.

   :math:`S_{ijk}` is the nodal basis, :math:`S_{ijk}^{(p)}` its value at the particle, and :math:`\Omega` the physical deposition domain.
   In code, :math:`D_{ijk}` is ``density(i,j,k)``, :math:`c_p` is ``amount``,
   and :math:`1/V_{ijk}` is ``inv_volume(i,j,k)``.

   **The output is already density.** Starting from zero and counting each independent node once gives :math:`\sum_{ijk}V_{ijk}D_{ijk}=\sum_p c_p`.

   Use ``amount=wp`` for represented particle number and number density, or ``amount=qp*wp`` for signed charge and charge density.
   Metres and coulombs give :math:`\mathrm{m}^{-3}` and :math:`\mathrm{C\,m}^{-3}` respectively.

   .. _b04-grid-en:


   .. rubric:: Coordinates and storage

   Physical nodes are

   .. math::

      x_{ijk}=r_i\cos\phi_j,\qquad y_{ijk}=r_i\sin\phi_j,\qquad z_{ijk}=z_k.

   ``r(0:nr)``, ``phi(0:nphi)`` and ``z(0:nz)`` store node coordinates; ``nr/nphi/nz`` count cells.
   Retain the physical distance from the cylindrical axis: a positive inner radius describes an annulus and is not subtracted for indexing.
   Angles use radians; radial and axial coordinates share a length unit.

   .. list-table:: Layouts with zero-based notation
      :header-rows: 1
      :widths: 25 37 38

      * - Array
        - Periodic angle
        - Physical angular endpoints
      * - ``density``, ``inv_volume``
        - ``(0:nr,0:nphi-1,0:nz)``
        - ``(0:nr,0:nphi,0:nz)``
      * - ``phi_measure``
        - ``(0:nphi-1)``
        - ``(0:nphi)``
      * - ``cell_density``
        - ``(0:nr-1,0:nphi-1,0:nz-1)``
        - Same

   **The angular coordinate array always retains both endpoints; periodic density stores independent nodes only.**
   The period is ``phi(nphi)-phi(0)``; a full circle spans :math:`2\pi`.
   Actual arrays may have other lower bounds. Their first element maps to dummy index zero, and ``cell`` uses the same relative numbering.
   The interface uses these physical-node extents; the caller organizes any additional communication buffers.

   .. _b04-workflow-en:

   .. rubric:: What is prepared once, and what runs each stage?

   **Prepare geometry when the grid is created or changed; deposit inside the particle loop of each stage.**
   At the start of a stage the caller clears ``density``, applies particle boundary rules and locates containing cells.
   The four operations below follow data dependencies; axis and cell averaging have their own calling conditions.

   .. list-table:: Timing, inputs and immediate results
      :header-rows: 1
      :widths: 30 30 40

      * - Operation and timing
        - Upstream inputs
        - Immediate result and consumer
      * - :doc:`Geometry <B04_scatter_3d_cyl_nonuniform/sub_B04_build_geometry>`: on grid or periodic-configuration changes
        - Coordinates and angular periodicity
        - ``inv_volume`` for scatter; ``phi_measure`` for axis averaging. Reusable on a fixed grid
      * - :doc:`Scatter <B04_scatter_3d_cyl_nonuniform/sub_B04_scatter_3d_cyl_nonuniform>`: per particle in each stage
        - Position, cell, amount and inverse volumes
        - Accumulated ``density`` for shared-node summation or subsequent nodal operations
      * - :doc:`Axis average <B04_scatter_3d_cyl_nonuniform/sub_B04_average_axis>`: full-circle axis after summation
        - Complete axis density and angular integral weights
        - Updated axis portion of ``density``, single-valued at each physical point. Annuli use their inner nodes directly
      * - :doc:`Cell average <B04_scatter_3d_cyl_nonuniform/sub_B04_project_density>`: when a cell-average source is needed
        - Complete nodal density, radial coordinates and periodicity
        - Separate ``cell_density`` array for cell-average source assembly

   .. admonition:: What does the next calculation receive?

      **Nodal calculations receive the nodal density** ``density``. Consumers of cell-volume averages use ``cell_density``.
      See :doc:`project_density <B04_scatter_3d_cyl_nonuniform/sub_B04_project_density>` for the meaning of that average. Downstream assembly supplies the signs, units and physical coefficients of its equation.

   .. rubric:: Connecting partitioned calculations

   MPI shared nodes require complete effective volumes including basis support on both sides. The caller can prepare global geometry and distribute it using local indices.
   Contributions use matching volumes and are summed before averaging the complete full-circle axis.
   ``build_geometry`` treats supplied coordinate endpoints as physical endpoints; its page explains interface-volume preparation. Concurrent density writes require caller-managed buffers or synchronization.

   .. rubric:: Related algorithm and reference

   :doc:`B02 <B02_deposit_3d_cyl>` provides uniform cylindrical charge/current deposition.
   B04 uses explicit nonuniform coordinates and caller-supplied cells. Check each interface's angular index convention.
   B04 tests call the public B02 charge routine for a uniform-grid comparison.

   Liu, Z., Zhou, Z., Zhao, Y. (2026), *Conservative Charge and Current Deposition on Nonuniform 3D Cylindrical PIC Meshes with Residual Self-Field Diagnostics*.
   `Preprint v1 <https://arxiv.org/abs/2606.09168v1>`_, Sections II.A–B (geometry and density deposition), II.E (cell-volume averaging).

   Author: Xin Luo.

   Return to the :doc:`scatter learning path <scatter_learning_path>` · :doc:`usage guide <scatter_usage_cookbook>`.
