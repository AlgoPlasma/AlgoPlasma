B04_scatter_3d_raz_nonuniform Test
====================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-b04-doc

   .. rubric:: 这些测试检查什么？

   **测试直接编译、调用 B04 的四个公开例程，检查密度分配、几何归一化、轴点处理及单元平均。**
   均匀网格对照还直接调用 B02 的公开电荷沉积例程。参考量由手算、独立 Gauss 积分和解析体积平均给出。

   :doc:`返回 B04 总览 </rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform>` ·
   :doc:`先看调用示例 </rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform/usage>` ·
   :doc:`返回沉积测试目录 <index>`。

   .. rubric:: 算例设置与比较量

   下表对应测试主程序中的实际检查。每种编译配置执行 79 项断言，另在公开例程调用后检查返回状态。

   .. list-table::
      :header-rows: 1
      :widths: 22 40 38

      * - 算例
        - 输入或参考
        - 检查内容
      * - 单粒子手算
        - 非均匀环域，位置 ``[1.25,0.5,0.5]`` ，贡献量 8
        - 八项增量、节点体积、总量、正负抵消、零贡献、数组下界和内部面表示
      * - 物理角点
        - 单元两个对角顶点分别放置贡献量 2 和 3
        - 只写对应端点，总量为 5
      * - 线性场单元平均
        - ``D=2+3*r-0.7*phi+0.4*z`` 的解析体积平均
        - 逐单元比较输出，并报告最大相对误差
      * - 四组网格积分
        - 含轴全周、环域全周、环域角向物理端面、单个周期角单元
        - 总体积、均匀密度恢复、带符号总量、单元平均总量、周期接缝或端面体积
      * - .. _b04-test-axis-zh:

          非均匀轴点
        - 角宽 ``[0.2,0.9,1.9,2*pi-3]`` ；轴密度 ``[1,2,4,8]`` 及相反数
        - 加权参考值约 ``4.64323945``，正负总量保持；见 :ref:`轴点平均验证 <b04-axis-validation-zh>`
      * - 公开 B02 对照
        - 从轴开始的均匀全周网格，71 个确定性粒子，正负电荷和可变权重
        - 轴点平均前的两套节点密度数组一致性
      * - 参数错误
        - 非法坐标、形状、单元、位置、贡献量、密度、体积或轴点权重
        - 返回状态及目标数组保留
      * - 浮点范围（19 项）
        - 倒数阈值、正负加法范围、临界舍入、重复周期目标，以及单元平均的大幅值输入与零场
        - 非法累加在溢出前拒绝并保留整数组；合法累加、抵消和单元平均符合参考结果

   .. rubric:: 图 1：一个粒子怎样分配到八个节点？

   完整坐标为 ``r=[1,2,4]`` 、``phi=[0,1,3]`` 、``z=[0,2,3]`` ，粒子位于第一个单元。
   局部坐标为 ``(0.25,0.5,0.25)`` ，三个方向的左右权重为 ``(0.75,0.25)`` 、``(0.5,0.5)`` 、``(0.75,0.25)`` 。

   .. figure:: /images/tests/004_scatter/B04_scatter_3d_raz_nonuniform/hand_en.png
      :target: ../../_images/hand_en.png
      :alt: 单粒子在两个轴向平面的分配与八节点实际贡献量
      :width: 100%

      两个平面是同一坐标单元的展开表示；星号为粒子投影。比较量为节点贡献量 :math:`D_a V_a`。

   手算与实际八项贡献均为 ``[2.25,0.75,2.25,0.75,0.75,0.25,0.75,0.25]`` ，
   总量为 8，最大绝对差为 0。这里比较的是 **密度乘有效体积** ，与公式中的 :math:`c_p S_a` 对应。

   .. _b04-test-constant-density-zh:

   .. rubric:: 图 2：非均匀网格能否恢复均匀物理密度？

   含轴全周算例采用

   .. code-block:: text

      r   = [0, 0.1, 0.23, 0.7, 1]
      phi = [0, 0.2, 1.1, 3, 2*pi]
      z   = [-0.3, 0.05, 0.6, 1]
      D0  = 3.25

   共有 48 个单元、80 个独立节点。每单元取八个两点张量积 Gauss 积分点，总计 384 项贡献；每项为

   .. math::

      c_p=D_0 r_p\,\Delta r\,\Delta\phi\,\Delta z/8.

   这里的 :math:`r_p` 来自圆柱体积元。两点 Gauss 规则可准确积分单元内“线性基函数 × 径向因子”，
   用来检查基函数与有效体积归一化是否配套。

   .. figure:: /images/tests/004_scatter/B04_scatter_3d_raz_nonuniform/uniform_en.png
      :target: ../../_images/uniform_en.png
      :alt: 非均匀网格节点、恢复的密度与节点相对误差
      :width: 100%

      **几何准备与沉积的结果，取自轴点平均之前。** 图中显示真实节点，误差未在节点之间插值。全网格最大相对误差为 ``8.198570028001156e-16`` 。

   最小和最大节点密度为 ``3.2499999999999973`` 、``3.2500000000000027`` 。
   这组确定性积分贡献检查均匀密度的离散恢复；粒子随机采样噪声和应用时间演化由相应应用算例评价。

   .. _b04-axis-validation-zh:

   .. rubric:: 图 3：轴点平均后，密度是否统一、总量是否保持？

   本节直接调用 ``sub_B04_average_axis``，检查 **平均值符合加权参考值、同一物理轴点的密度一致、处理前后总量保持**。
   先用四个已知密度值检查平均运算，再用沉积后的轴线密度检查它与沉积过程的衔接。

   **输入与参考值怎样确定？**

   固定轴向索引 ``k=0``，轴线上四个角向存储值为 ``[1,2,4,8]``，采用同一密度尺度。
   四个角向单元宽度为 ``[0.2,0.9,1.9,2*pi-3]`` rad。
   每个角节点的权重 :math:`A_j` 由相邻两单元各贡献半个角宽：

   .. math::

      A_j=\frac{\Delta\phi_{j-1}+\Delta\phi_j}{2},
      \qquad
      D_{\mathrm{ref}}=\frac{\sum_j A_j D^{\mathrm{before}}_{0,j,0}}{\sum_j A_j}
      =4.5+\frac{0.9}{2\pi}\approx4.6432394487827064.

   周期首节点的前一单元取最后一个角单元。测试中 ``va(j)`` 保存 :math:`A_j`，``rho(j,k)`` 保存轴线密度：

   .. list-table::
      :header-rows: 1
      :widths: 20 40 40

      * - 角向存储索引 j
        - 角向积分权重 A_j（rad）
        - 调用前密度
      * - 0
        - :math:`\pi-1.4\approx1.74159265`
        - 1
      * - 1
        - 0.55
        - 2
      * - 2
        - 1.4
        - 4
      * - 3
        - :math:`\pi-0.55\approx2.59159265`
        - 8

   **参考值由给定输入和加权公式确定；图中的方形标记取自公开例程的实际输出。**
   四个角向索引对应同一个物理轴点。等权平均值为 3.75，可用来辨认加权方式对结果的影响。

   .. figure:: /images/tests/004_scatter/B04_scatter_3d_raz_nonuniform/axis_average_en.png
      :target: ../../_images/axis_average_en.png
      :alt: 同一物理轴点四个角向索引的密度从1、2、4、8变为相同值，实际输出与加权参考值4.64323945重合
      :width: 100%

      柱形表示调用前密度，方形标记表示 B04 调用后的密度，实线表示加权参考值。横轴为同一物理轴点的存储索引。

   **密度改变后，怎样检查总量？**

   手算例比较角向加权量 :math:`T_k=\sum_j A_jD_{0,j,k}`。
   固定轴向位置时，有效节点体积为 :math:`V_{0jk}=R_0A_jZ_k`，因此对应的粒子数或电荷量为 :math:`R_0Z_kT_k`。
   网格固定时，保持 :math:`T_k` 就保持这部分总量。正密度输入的 :math:`T_0` 在处理前后均约为 29.17433388230814，
   绝对差为 :math:`3.5527\times10^{-15}`。另一轴向位置使用相反数密度，其加权量约为 −29.17433388230814。

   沉积连用检查采用图 2 所列的含轴全周网格，在每个单元放入一个带正或负贡献量的粒子。
   沉积后调用轴点平均，比较 **各轴向位置的角向密度差** 和 **全域总量在平均前后的变化**：

   .. math::

      e_{\mathrm{axis}}=\max_{j,k}|D^{\mathrm{after}}_{0,j,k}-D^{\mathrm{after}}_{0,0,k}|,
      \qquad
      e_Q=\frac{|Q_{\mathrm{after}}-Q_{\mathrm{before}}|}{\sum_p|c_p|},
      \qquad Q=\sum_{i,j,k}V_{ijk}D_{ijk}.

   分母使用各粒子贡献量绝对值之和，使正负贡献相互抵消时仍有合适的比较尺度。
   下面列出 **2026-11-01，double debug** 实际导出的误差及对应判据：

   .. list-table::
      :header-rows: 1
      :widths: 58 21 21

      * - 检查项
        - 实际误差
        - 通过上限
      * - 手算例：平均值与参考值的绝对差
        - ``0``
        - ``2.1115e-12``
      * - 手算例：正密度角向加权量的绝对变化
        - ``3.5527e-15``
        - ``1.3267e-11``
      * - 手算例：负密度角向加权量的绝对变化
        - ``3.5527e-15``
        - ``1.3267e-11``
      * - 沉积连用：轴线各角向索引的最大密度差
        - ``0``
        - ``4.5475e-13``
      * - 沉积连用：全域总量变化的归一化误差
        - ``0``
        - ``4.5475e-13``

   各项均满足通过条件；表中 0 表示本次浮点计算中对应比较量相同。
   同日 double release 和 single debug 的原有 70 项断言也全部通过；单个周期角单元同样执行总量与角向一致性检查。
   图 3 和本表来自现有测试主程序对真实调用结果的导出。

   权重与有效体积的关系见 :doc:`轴点平均算法页 </rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform/sub_B04_average_axis>`；
   返回 :ref:`算例列表 <b04-test-axis-zh>`。

   .. rubric:: 误差判据

   主要数值比较采用 :math:`\tau=2048\epsilon`，其中 :math:`\epsilon` 是当前实数精度的机器间隔。
   双精度阈值为 ``4.547473508864641e-13`` ，单精度为 ``2.44140625e-4`` 。

   - 标量比较通常要求 :math:`|a-b|\le\tau\max(1,|b|)`；八节点数组比较按参考数组最大幅值缩放。
   - 均匀恢复使用 :math:`e_D=\max|D-D_0|/D_0`；线性场平均使用 :math:`e_{\rm avg}=\max|\overline D-D_{\rm ref}|/\max|D_{\rm ref}|`。
   - 带符号总量使用 :math:`e_Q=|\sum VD-\sum_p c_p|/\sum_p|c_p|`，避免正负抵消使分母接近零。
   - 单元平均总量比较使用 :math:`|\sum\Omega\overline D-\sum VD|/\sum_p|c_p|`。
   - B02 对照使用 :math:`\max|D_{B04}-D_{B02}|/\max(1,\max|D_{B02}|)`。
   - 大幅值单元平均以 ``huge(1.0)`` 归一化，与解析参考值的差不超过 :math:`16\epsilon`；状态码及失败时数组保留采用直接判断。全部判据在测试主程序中定义。

   .. rubric:: 已保存的运行结果

   **2026-11-01 最新回归：** 三种配置各 79 项通过，包含单元平均在浮点上限附近的计算及非有限输入处理。下列图表保留各自注明日期的运行记录。

   以下为 **2026-10-31，WSL Ubuntu 22.04 / GNU Fortran 11.4.0** 的运行记录。
   三种配置各 70 项通过；两幅图使用同日 double debug 测试副本额外导出的节点数据，算法调用和比较判据相同。

   .. list-table:: 代表性误差（debug；double release 的这些数值与 double debug 相同）
      :header-rows: 1
      :widths: 48 26 26

      * - 指标
        - double
        - single
      * - 线性场单元平均相对最大误差
        - ``2.1831e-16``
        - ``5.8602e-8``
      * - 含轴全周均匀密度相对最大误差
        - ``8.1986e-16``
        - ``2.9344e-7``
      * - 四组网格均匀恢复误差的最大值
        - ``9.5650e-16``
        - ``4.4016e-7``
      * - 四组网格带符号总量误差的最大值
        - ``5.5003e-18``
        - ``5.9605e-8``
      * - 四组网格单元平均总量误差的最大值
        - ``1.8334e-18``
        - ``5.9605e-8``
      * - B02 节点密度对照相对最大误差
        - ``2.3183e-16``
        - ``2.4893e-7``

   .. rubric:: 测试环境与运行依赖

   - **已记录的测试环境：** WSL Ubuntu 22.04，GNU Fortran 11.4.0；图 1、图 2 的记录日期为 2026-10-31，图 3 及轴点误差表的记录日期为 2026-11-01。
   - **运行依赖：** Bash、GNU Fortran，以及仓库内 B04 和用于均匀网格对照的 B02 电荷沉积源文件。构建采用 Fortran 2008 标准并启用预处理。
   - **编译配置：** double 使用 ``-fdefault-real-8``；debug 启用 ``-fcheck=all`` 和 ``-ffpe-trap=invalid,zero,overflow``；release 使用 ``-O2``。算法模块与测试主程序采用一致精度。
   - **可选绘图依赖：** 运行 double debug 测试后，``python tests/004_scatter/B04_scatter_3d_raz_nonuniform/plot_results.py`` 从本地 ``build/double-debug/`` 的节点数据生成三张英文图，输出到该测试目录的 ``build/figures/``，供中英文页面共用。绘图需要 Python、NumPy 和 Matplotlib。原始数据和运行日志由 Git 忽略，已选用的文档插图随说明文档保留。

.. container:: ap-lang ap-lang-en ap-b04-doc

   .. rubric:: What the tests check

   **The suite compiles and calls all four public B04 routines, checking assignment, geometric normalization, axis treatment and cell averaging.**
   The uniform-grid comparison also calls the public B02 charge routine. References use hand calculations, independent Gauss quadrature and analytic volume averages.

   :doc:`B04 overview </rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform>` ·
   :doc:`Calling example </rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform/usage>` · :doc:`Scatter tests <index>`.

   .. rubric:: Cases and compared quantities

   Each configuration executes 79 assertions, plus return-status checks after public calls.

   .. list-table::
      :header-rows: 1
      :widths: 22 40 38

      * - Case
        - Input or reference
        - Checks
      * - Hand calculation
        - Nonuniform annulus; position ``[1.25,0.5,0.5]``, amount 8
        - Eight increments, nodal volumes, total, cancellation, zero amount, actual bounds and shared faces
      * - Physical corners
        - Amounts 2 and 3 at two opposite cell vertices
        - Only the endpoint nodes receive contributions; total 5
      * - Linear-field average
        - Analytic cell averages of ``D=2+3*r-0.7*phi+0.4*z``
        - Per-cell agreement and relative maximum norm
      * - Four quadrature grids
        - Full-circle axis, full-circle annulus, annulus with angular faces, one periodic angular cell
        - Volume, constant density, signed total, cell-average total, seams or endpoint measures
      * - .. _b04-test-axis-en:

          Nonuniform axis
        - Angular widths ``[0.2,0.9,1.9,2*pi-3]``; density ``[1,2,4,8]`` and its negative
        - Weighted reference near ``4.64323945`` and signed totals; see :ref:`axis-averaging verification <b04-axis-validation-en>`
      * - Public B02 comparison
        - Uniform full-circle grid from axis; 71 deterministic particles, signed charges and varying weights
        - Nodal arrays before axis averaging
      * - Invalid inputs
        - Coordinates, shapes, cells, positions, amounts, densities, volumes or axis weights
        - Status codes and preserved target arrays
      * - Floating range (19 checks)
        - Reciprocal limit, signed addition, rounded bound, repeated periodic targets, and large or zero inputs for cell averaging
        - Invalid sums rejected before overflow with arrays retained; valid sums, cancellation and cell averages agree with references

   .. rubric:: Figure 1: eight-node assignment

   The grid is ``r=[1,2,4]``, ``phi=[0,1,3]``, ``z=[0,2,3]``. The particle lies in cell zero with local coordinates ``(0.25,0.5,0.25)``.
   Endpoint weights are ``(0.75,0.25)``, ``(0.5,0.5)`` and ``(0.75,0.25)``.

   .. figure:: /images/tests/004_scatter/B04_scatter_3d_raz_nonuniform/hand_en.png
      :target: ../../_images/hand_en.png
      :alt: Particle projections and measured amounts at the eight nodes
      :width: 100%

      The planes unfold the coordinate cell; stars show the same particle's projection. The compared quantity is nodal amount :math:`D_a V_a`.

   Both hand and computed amounts are ``[2.25,0.75,2.25,0.75,0.75,0.25,0.75,0.25]``;
   their sum is 8 and the maximum absolute difference is zero. **Density times effective volume** corresponds to :math:`c_p S_a`.

   .. _b04-test-constant-density-en:

   .. rubric:: Figure 2: constant physical density on a nonuniform grid

   The full-circle axis case uses

   .. code-block:: text

      r   = [0, 0.1, 0.23, 0.7, 1]
      phi = [0, 0.2, 1.1, 3, 2*pi]
      z   = [-0.3, 0.05, 0.6, 1]
      D0  = 3.25

   There are 48 cells and 80 independent nodes. Eight tensor-product Gauss points per cell give 384 contributions:

   .. math::

      c_p=D_0 r_p\,\Delta r\,\Delta\phi\,\Delta z/8.

   The radial factor comes from cylindrical volume. Two-point Gauss quadrature integrates the local basis times this factor exactly, checking the matching of bases and volume normalization.

   .. figure:: /images/tests/004_scatter/B04_scatter_3d_raz_nonuniform/uniform_en.png
      :target: ../../_images/uniform_en.png
      :alt: Nonuniform nodes, recovered density and nodal relative errors
      :width: 100%

      **Geometry preparation and scatter, before axis averaging.** Values are shown at actual nodes without interpolating the error field. The maximum relative error over all nodes is ``8.198570028001156e-16``.

   The minimum/maximum densities are ``3.2499999999999973`` and ``3.2500000000000027``.
   These deterministic quadrature contributions check discrete constant-density recovery; sampling noise and time evolution are evaluated in application cases.

   .. _b04-axis-validation-en:

   .. rubric:: Figure 3: does axis averaging unify density and preserve the total?

   This section calls ``sub_B04_average_axis`` to check **agreement with a weighted reference, a common density at each physical axis point, and preservation of the represented amount**.
   A four-value case checks the averaging operation; an axis-containing deposition case checks the subsequent update.

   **How are the inputs and reference defined?**

   At axial index ``k=0``, the four angular entries contain ``[1,2,4,8]`` in one common density scale.
   Angular cell widths are ``[0.2,0.9,1.9,2*pi-3]`` rad.
   Each node receives half the width of each adjacent angular cell:

   .. math::

      A_j=\frac{\Delta\phi_{j-1}+\Delta\phi_j}{2},
      \qquad
      D_{\mathrm{ref}}=\frac{\sum_j A_j D^{\mathrm{before}}_{0,j,0}}{\sum_j A_j}
      =4.5+\frac{0.9}{2\pi}\approx4.6432394487827064.

   The first node's preceding cell is the last periodic cell. In the test, ``va(j)`` holds :math:`A_j` and ``rho(j,k)`` holds axis density:

   .. list-table::
      :header-rows: 1
      :widths: 20 40 40

      * - Angular storage index j
        - Angular basis integral A_j (rad)
        - Density before the call
      * - 0
        - :math:`\pi-1.4\approx1.74159265`
        - 1
      * - 1
        - 0.55
        - 2
      * - 2
        - 1.4
        - 4
      * - 3
        - :math:`\pi-0.55\approx2.59159265`
        - 8

   **The reference follows from the specified inputs and weighted formula; square markers show the actual public-routine output.**
   All four entries represent one physical axis point. The equal-weight mean, 3.75, illustrates the effect of the weighting.

   .. figure:: /images/tests/004_scatter/B04_scatter_3d_raz_nonuniform/axis_average_en.png
      :target: ../../_images/axis_average_en.png
      :alt: Four angular entries at one physical axis point change from 1, 2, 4, 8 to the common weighted reference 4.64323945
      :width: 100%

      Bars show input density, squares show the B04 output, and the solid line gives the weighted reference. The horizontal axis identifies storage entries at one physical axis point.

   **How is the total checked after the density changes?**

   The hand case compares the angular weighted amount :math:`T_k=\sum_j A_jD_{0,j,k}`.
   At fixed axial position, :math:`V_{0jk}=R_0A_jZ_k`, so the corresponding particle number or charge is :math:`R_0Z_kT_k`.
   On a fixed mesh, preserving :math:`T_k` preserves this amount. For positive input, :math:`T_0` is approximately 29.17433388230814
   both before and after the call, with an absolute difference of :math:`3.5527\times10^{-15}`.
   The other axial position uses the negative input values and has a weighted amount near -29.17433388230814.

   The deposition check uses the full-circle grid listed in Figure 2, with one particle of positive or negative amount in each cell.
   It then averages the axis and compares **angular density differences at every axial node** and **the change in the domain total**:

   .. math::

      e_{\mathrm{axis}}=\max_{j,k}|D^{\mathrm{after}}_{0,j,k}-D^{\mathrm{after}}_{0,0,k}|,
      \qquad
      e_Q=\frac{|Q_{\mathrm{after}}-Q_{\mathrm{before}}|}{\sum_p|c_p|},
      \qquad Q=\sum_{i,j,k}V_{ijk}D_{ijk}.

   The sum of absolute particle amounts provides a comparison scale even when positive and negative contributions cancel.
   The following errors and pass limits were exported from the **2026-11-01 double-debug run**:

   .. list-table::
      :header-rows: 1
      :widths: 58 21 21

      * - Check
        - Measured error
        - Pass limit
      * - Hand case: absolute mean/reference difference
        - ``0``
        - ``2.1115e-12``
      * - Hand case: absolute change in positive weighted amount
        - ``3.5527e-15``
        - ``1.3267e-11``
      * - Hand case: absolute change in negative weighted amount
        - ``3.5527e-15``
        - ``1.3267e-11``
      * - After deposition: maximum angular density difference on the axis
        - ``0``
        - ``4.5475e-13``
      * - After deposition: normalized change in the domain total
        - ``0``
        - ``4.5475e-13``

   Every check meets its pass condition; zero means the compared quantities were equal in this floating-point run.
   Double release and single debug also passed all 70 existing assertions that day. The one-periodic-angular-cell case also checks total preservation and angular agreement.
   Figure 3 and this table use actual call results exported by the existing test driver.

   See the :doc:`axis-averaging algorithm </rst_files/B_Scatter/B04_scatter_3d_raz_nonuniform/sub_B04_average_axis>` for weights and effective volumes;
   return to the :ref:`case list <b04-test-axis-en>`.

   .. rubric:: Error criteria

   The rounding tolerance is :math:`\tau=2048\epsilon`: ``4.547473508864641e-13`` for double and ``2.44140625e-4`` for single precision.

   - Scalar comparisons generally use :math:`|a-b|\le\tau\max(1,|b|)`; the eight-node comparison scales by the maximum reference magnitude.
   - Constant-density recovery uses :math:`e_D=\max|D-D_0|/D_0`; linear averaging uses :math:`e_{\rm avg}=\max|\overline D-D_{\rm ref}|/\max|D_{\rm ref}|`.
   - Signed totals use :math:`e_Q=|\sum VD-\sum_p c_p|/\sum_p|c_p|` to accommodate cancellation.
   - Cell-average totals use :math:`|\sum\Omega\overline D-\sum VD|/\sum_p|c_p|`.
   - B02 comparison uses :math:`\max|D_{B04}-D_{B02}|/\max(1,\max|D_{B02}|)`.
   - Large-value cell averages are normalized by ``huge(1.0)`` and compared with analytic references within :math:`16\epsilon`. Status codes and retained arrays use direct checks. The test driver defines every criterion.

   .. rubric:: Recorded execution

   **Latest regression, 2026-11-01:** all three configurations passed 79 assertions, including cell averaging near the floating-point limit and handling of nonfinite input. The figures and tables below retain their dated run records.

   Results below were recorded on **2026-10-31, WSL Ubuntu 22.04 / GNU Fortran 11.4.0**.
   Each configuration passed 70 assertions. Figures 1 and 2 use node data exported from a same-day double-debug test copy with the same algorithm calls and pass criteria.

   .. list-table:: Selected errors (debug; these double-release values match double-debug values)
      :header-rows: 1
      :widths: 48 26 26

      * - Metric
        - double
        - single
      * - Linear-field cell-average relative maximum error
        - ``2.1831e-16``
        - ``5.8602e-8``
      * - Axis/full-circle constant-density relative maximum error
        - ``8.1986e-16``
        - ``2.9344e-7``
      * - Largest constant-density error across four grids
        - ``9.5650e-16``
        - ``4.4016e-7``
      * - Largest signed-total error across four grids
        - ``5.5003e-18``
        - ``5.9605e-8``
      * - Largest cell-average-total error across four grids
        - ``1.8334e-18``
        - ``5.9605e-8``
      * - B02 relative maximum nodal difference
        - ``2.3183e-16``
        - ``2.4893e-7``

   .. rubric:: Test environment and dependencies

   - **Recorded test environment:** WSL Ubuntu 22.04 with GNU Fortran 11.4.0; Figures 1 and 2 were recorded on 2026-10-31; Figure 3 and the axis-error table on 2026-11-01.
   - **Runtime requirements:** Bash, GNU Fortran, and the repository's B04 sources plus the B02 charge-deposition sources used for uniform-grid comparison. The build selects Fortran 2008 and enables preprocessing.
   - **Build configurations:** double uses ``-fdefault-real-8``; debug enables ``-fcheck=all`` and ``-ffpe-trap=invalid,zero,overflow``; release uses ``-O2``. Algorithm modules and the test driver use consistent precision.
   - **Optional plotting dependencies:** after the double-debug test, run ``python tests/004_scatter/B04_scatter_3d_raz_nonuniform/plot_results.py`` to render three English figures from local ``build/double-debug/`` data into the test directory's ``build/figures/``. Both language versions use these figures. Plotting requires Python, NumPy and Matplotlib. Git ignores raw data and run logs; selected documentation figures remain with the documentation.
