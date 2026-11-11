Scatter Testing Guide
==============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-b04-doc

   .. rubric:: 按算法查找验证依据

   **测试说明应同时给出比较对象、判据和对应实现。** 本页提供各算法的验证入口；算例设置、运行命令及已有结果保留在各测试页面中。

   .. list-table::
      :header-rows: 1
      :widths: 18 48 34

      * - 算法
        - 检查内容
        - 详细入口
      * - B01
        - 单／多粒子 CIC 分配、粒子分量、单元方差及 OpenMP 对照
        - :doc:`B01 综合测试 </tests/004_scatter/B01_scatter_3Dxyz>`
      * - B02
        - 柱坐标电荷／电流沉积，两种粒子采样与权重设置下的密度及连续性残差
        - :doc:`004_scatter 中的 B02 测试说明 </tests/004_scatter/index>`
      * - B03
        - 一阶对 B01、总量、一阶矩及分批累加
        - :doc:`B03 测试 </tests/004_scatter/B03_scatter_3Dxyz_bspline>`
      * - B04
        - 八节点分配、有效体积、均匀密度恢复、轴点加权平均、单元平均及 B02 对照
        - :doc:`B04 测试与结果 </tests/004_scatter/B04_scatter_3Draz_nonuniform>`

   .. rubric:: B04 的已有测试怎样对应算法？

   - **沉积分配与几何归一化：** 单粒子手算检查八项贡献；四组网格用确定性积分贡献检查有效体积与均匀物理密度恢复。
   - **后续处理：** 非均匀角网格检查轴点加权均值及总量；解析线性场检查单元体积平均。
   - **实现与接口：** 均匀网格直接调用 B02 公开电荷沉积例程作对照；参数及浮点范围检查核对返回状态和数组保留。

   当前测试在单、双精度各自的 debug 和 release 四种配置下各执行 102 项断言。
   输入、误差定义、阈值、运行结果摘要与插图集中在 :doc:`B04 测试页 </tests/004_scatter/B04_scatter_3Draz_nonuniform>`。

   .. rubric:: 怎样理解比较量？

   **首先确定数组的物理含义，再选择总量或误差公式。** 从零开始的 B01／B03 粒子数沉积，数组总和对应 ``np*w``；
   B02／B04 的密度需要乘配套有效体积后求和。粒子分量沉积检查相应分量总和，方差统计则与所在单元的方差参考值比较。

   各测试使用与比较量和精度相符的判据。B04 使用由机器精度定义的阈值，并分别记录节点误差、带符号总量误差及单元平均误差；具体定义见其测试页。
   密度分配的总量检查与电荷／电流的离散连续性检查各有对应的物理量和接口，应按所用算法阅读。

   .. rubric:: 使用示例与性能数据

   学习调用顺序可先阅读 :doc:`B04 调用示例 </rst_files/B_Scatter/B04_scatter_3Draz_nonuniform/usage>`；
   研究运行成本可查阅 :doc:`B01 平台比较 </tests/kunpeng_compare/B01_scatter_3Dxyz_omp>` 中对应配置的计时结果。

   返回 :doc:`学习入口 <scatter_learning_path>` · :doc:`使用指南 <scatter_usage_cookbook>` · :doc:`全部沉积测试 </tests/004_scatter/index>`。

.. container:: ap-lang ap-lang-en ap-b04-doc

   .. rubric:: Find verification evidence by algorithm

   **A test description identifies the reference, criterion and implementation under test.** This page links to the available checks. Individual test pages retain configurations, commands and saved results.

   .. list-table::
      :header-rows: 1
      :widths: 18 48 34

      * - Algorithm
        - Checks
        - Details
      * - B01
        - Single/multiple-particle CIC, particle components, cell variance and OpenMP comparisons
        - :doc:`B01 tests </tests/004_scatter/B01_scatter_3Dxyz>`
      * - B02
        - Cylindrical charge/current deposition, densities and continuity residuals with two sampling/weighting conventions
        - :doc:`B02 description in 004_scatter </tests/004_scatter/index>`
      * - B03
        - Degree-one comparison with B01, totals, first moments and batched accumulation
        - :doc:`B03 tests </tests/004_scatter/B03_scatter_3Dxyz_bspline>`
      * - B04
        - Eight-node distribution, effective volumes, uniform-density recovery, weighted axis averages, cell averages and B02 comparison
        - :doc:`B04 tests and results </tests/004_scatter/B04_scatter_3Draz_nonuniform>`

   .. rubric:: How B04 checks relate to the algorithm

   - **Deposition and geometric normalization:** a hand calculation checks eight contributions; deterministic quadrature contributions on four grids check effective volumes and uniform physical density.
   - **Subsequent operations:** nonuniform angular grids check weighted axis means and totals; an analytic linear field checks cell-volume averages.
   - **Implementation and interfaces:** a uniform-grid comparison calls the public B02 charge routine; invalid-input and floating-point-range checks inspect return status and preserved arrays.

   The current test executes 102 assertions in each of four configurations: single and double precision, each in debug and release mode.
   Inputs, error definitions, tolerances, result summaries and figures are collected on the :doc:`B04 test page </tests/004_scatter/B04_scatter_3Draz_nonuniform>`.

   .. rubric:: Interpret the compared quantity

   **Identify the array's physical meaning before selecting a total or error formula.** For zero-initialized B01/B03 number deposition, the array sum corresponds to ``np*w``.
   B02/B04 densities require multiplication by matching effective nodal volumes before summation. Component deposition checks the component total; variance is compared with a cell-variance reference.

   Each test uses criteria appropriate to its quantity and precision. B04 defines tolerances from machine precision and reports nodal, signed-total and cell-average errors separately; its test page supplies the definitions.
   Density-total checks and discrete charge/current continuity checks refer to their respective physical quantities and interfaces.

   .. rubric:: Usage examples and performance data

   Read the :doc:`B04 calling example </rst_files/B_Scatter/B04_scatter_3Draz_nonuniform/usage>` to learn the calling sequence.
   For runtime costs, consult the configurations and measurements in the :doc:`B01 platform comparison </tests/kunpeng_compare/B01_scatter_3Dxyz_omp>`.

   Return to the :doc:`learning path <scatter_learning_path>` · :doc:`usage guide <scatter_usage_cookbook>` · :doc:`scatter test index </tests/004_scatter/index>`.
