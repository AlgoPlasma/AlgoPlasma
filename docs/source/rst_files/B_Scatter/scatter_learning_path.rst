Scatter Learning Path
==============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-b04-doc

   .. rubric:: 从粒子量到网格量

   **粒子沉积（scatter）把粒子携带的数目、电荷或其他量分配到网格上。** 阅读时先确定三个问题：采用什么网格、分配什么物理量、输出是节点累加量还是已经归一化的密度。
   本页帮助你选择对应算法；公式和实际代码的联系放在各算法页面中。

   .. rubric:: 按网格和计算目标选择阅读入口

   各行是不同的学习入口，可直接选择与自己的计算相符的一行。

   .. list-table::
      :header-rows: 1
      :widths: 22 40 38

      * - 算法
        - 适合学习的内容
        - 接着阅读
      * - :doc:`B01 <B01_scatter_3Dxyz>`
        - 直角网格上的三线性 CIC 分配，以及粒子分量沉积和单元方差统计
        - B01 总览中的权重公式及各子程序
      * - :doc:`B02 <B02_deposit_3d_cyl>`
        - 均匀柱坐标网格中的电荷密度、轨迹电流沉积与轴线处理
        - B02 的网格、节点体积及电荷／电流说明
      * - :doc:`B03 <B03_scatter_3Dxyz_bspline>`
        - 直角网格上的 B-spline 权重，阶数与支撑范围的关系
        - B03 形函数及一维权重构造
      * - :doc:`B04 <B04_scatter_3d_raz_nonuniform>`
        - 各方向间距可变的三维柱坐标网格，以及配套有效体积下的节点密度
        - :ref:`B04 基本思想 <b04-principle-zh>` → 沉积与几何准备例程 → :doc:`调用示例 <B04_scatter_3d_raz_nonuniform/usage>`

   .. rubric:: 权重、贡献量与密度的关系

   线性 CIC（cloud-in-cell）在每个坐标方向按粒子在单元内的位置分配左右节点权重；三个方向相乘，得到八个顶点的权重。
   一维局部坐标为 :math:`\xi` 时，左右权重是 :math:`1-\xi` 和 :math:`\xi`。
   **权重之和为一，表示粒子的贡献量被完整分配。**

   读取输出时，还要区分“分配到节点的量”与“节点密度”：

   - **B01／B03：** 权重沉积到数组中，调用方给定缩放量 ``w``；输出单位由 ``w`` 和被沉积量共同确定。B01 基础例程在循环后整体缩放数组，B03 在每项增量中使用 ``w``。
   - **B02／B04 的密度沉积：** 在写入节点时已经除以配套的柱坐标有效节点体积。对密度乘该体积后求和，得到表示的总粒子数或总电荷。

   以 B04 为例，粒子贡献量为 :math:`c_p`、节点权重为 :math:`S_a^{(p)}`、有效体积为 :math:`V_a`，则

   .. math::

      D_a=\frac{\sum_p c_p S_a^{(p)}}{V_a},\qquad
      \sum_a V_aD_a=\sum_p c_p.

   这里假定密度从零开始累加，各独立节点只计一次。有效体积来自节点形函数与柱坐标体积元的积分，详见 :doc:`B04 几何准备 <B04_scatter_3d_raz_nonuniform/sub_B04_build_geometry>`。

   .. rubric:: 从理解原理到正确调用

   - **先看量的位置和单位。** B04 的 ``position`` 是实际柱坐标位置；B01／B03 使用网格指标坐标。节点密度与单元平均密度的区别见 :doc:`B04 单元平均 <B04_scatter_3d_raz_nonuniform/sub_B04_project_density>`。
   - **再看接口与调用频率。** B01／B03 在例程内遍历粒子；B04 的核心沉积每次处理一个粒子，几何量可在网格固定时复用。具体安排见 :doc:`使用指南 <scatter_usage_cookbook>`。
   - **最后结合已有测试。** 手算分配、总量检查、均匀密度恢复与电流连续性检查各自回答不同问题，见 :doc:`测试指南 <scatter_testing_guide>`。

   返回 :doc:`B_Scatter </rst_files/B_Scatter>`。

.. container:: ap-lang ap-lang-en ap-b04-doc

   .. rubric:: From particle quantities to grid quantities

   **Particle-to-grid deposition (scatter) distributes represented number, charge or another particle quantity onto a grid.** First identify the grid, the deposited physical quantity, and whether the output is an accumulated nodal amount or a normalized density.
   This page directs you to the appropriate algorithm; individual algorithm pages connect formulas to source code.

   .. rubric:: Choose a route by grid and calculation

   The rows are alternative entry points. Start with the one that matches your calculation.

   .. list-table::
      :header-rows: 1
      :widths: 22 40 38

      * - Algorithm
        - What to learn
        - Continue with
      * - :doc:`B01 <B01_scatter_3Dxyz>`
        - Cartesian trilinear CIC, particle-component deposition and cell variance
        - B01 weights and individual routines
      * - :doc:`B02 <B02_deposit_3d_cyl>`
        - Uniform cylindrical charge density, trajectory-current deposition and axis treatment
        - B02 grid, nodal volumes and charge/current descriptions
      * - :doc:`B03 <B03_scatter_3Dxyz_bspline>`
        - Cartesian B-spline weights and the relation between degree and support
        - B03 shape functions and one-dimensional weights
      * - :doc:`B04 <B04_scatter_3d_raz_nonuniform>`
        - Nonuniform three-dimensional cylindrical grids and nodal density with matching effective volumes
        - :ref:`B04 principle <b04-principle-en>` → scatter and geometry routines → :doc:`calling example <B04_scatter_3d_raz_nonuniform/usage>`

   .. rubric:: Weights, represented amounts and density

   Linear CIC (cloud-in-cell) assigns lower/upper weights in each coordinate direction according to the particle's local position. Multiplying the three factors gives eight vertex weights.
   For local coordinate :math:`\xi`, the one-dimensional weights are :math:`1-\xi` and :math:`\xi`.
   **Their partition of unity distributes the entire particle amount.**

   The output convention then determines how to recover that amount:

   - **B01/B03:** the caller supplies the scale ``w``; output units follow that scale and the deposited quantity. The basic B01 routine scales the whole array after the loop, while B03 applies ``w`` to each increment.
   - **B02/B04 density deposition:** each nodal increment already includes division by its effective cylindrical nodal volume. Multiply density by that volume and sum to recover represented number or charge.

   For B04, with particle amount :math:`c_p`, nodal weight :math:`S_a^{(p)}` and effective volume :math:`V_a`,

   .. math::

      D_a=\frac{\sum_p c_p S_a^{(p)}}{V_a},\qquad
      \sum_a V_aD_a=\sum_p c_p.

   This assumes zero initial density and counts each independent node once. Effective volumes integrate the nodal basis against the cylindrical volume element; see :doc:`B04 geometry preparation <B04_scatter_3d_raz_nonuniform/sub_B04_build_geometry>`.

   .. rubric:: From the method to a correct call

   - **Locate the quantities and their units.** B04 takes physical cylindrical positions; B01/B03 use grid-index coordinates. See :doc:`B04 cell averaging <B04_scatter_3d_raz_nonuniform/sub_B04_project_density>` for nodal versus cell-average density.
   - **Identify interfaces and call frequency.** B01/B03 loop over particles internally. B04 deposits one particle per call and reuses geometry on a fixed grid. See the :doc:`usage guide <scatter_usage_cookbook>`.
   - **Read the available checks.** Hand calculations, total-amount checks, uniform-density recovery and current-continuity checks address different properties; see the :doc:`testing guide <scatter_testing_guide>`.

   Return to :doc:`B_Scatter </rst_files/B_Scatter>`.
