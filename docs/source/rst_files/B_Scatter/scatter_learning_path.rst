=====================
Scatter Learning Path
=====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这页解决什么问题

   本页面向第一次接触 ``B_Scatter`` 的读者。它不是 PIC 教材，而是帮你把
   粒子-网格沉积（scatter）的几何图像跟 AlgoPlasma 里的 Fortran routine 对上号。
   读完后，应该知道该先看哪一页、哪些公式对应哪些代码、以及测试为什么能
   说明实现是可信的。

   .. rubric:: 推荐学习顺序

   .. list-table::
      :header-rows: 1
      :widths: 18 44 38

      * - 步骤
        - 先理解什么
        - 建议阅读
      * - 1
        - 粒子→网格沉积的基本图像：三线性（CIC）权重和守恒性。
        - 本页"核心图景"
      * - 2
        - 一次完整的 3D Cartesian 密度沉积（``sub_B01_scatter_3Dxyz``）。
        - :doc:`B01_scatter_3Dxyz <B01_scatter_3Dxyz>` 和 ``sub_B01_scatter_3Dxyz`` 的 API 页。
      * - 3
        - ``_v`` （速度矩）和 ``_T`` （温度/方差）变体与基础密度沉积的差别。
        - :doc:`B01_scatter_3Dxyz <B01_scatter_3Dxyz>` 中三个子程序的 API 页。
      * - 4
        - 怎么调和怎么集成到 PIC 循环里。
        - :doc:`Scatter Usage Cookbook <scatter_usage_cookbook>`
      * - 5
        - 柱坐标 ``(r,\phi,z)`` 多出来的体积因子 ``r`` 和轴线 (``r=0``) 闭合。
        - :doc:`B02_deposit_3d_cyl <B02_deposit_3d_cyl>`
      * - 6
        - 怎样验证守恒、节点权重精度、OMP 一致性。
        - :doc:`Scatter Testing Guide <scatter_testing_guide>`
          和 :doc:`004_scatter tests </tests/004_scatter/index>`

   .. rubric:: 核心图景

   ``B_Scatter`` 里所有 routine 都做同一件事：把一堆粒子的某个属性
   （权重、速度分量、动能/方差）按几何权重分配到网格节点上。完整 PIC 循环里，
   调用方组织粒子数组、边界、ghost cell 和归约；scatter routine 本身只做一次
   累加。

   - **三线性（CIC）权重**。每个粒子落在网格的某个 cell 中，按粒子到 cell 八个
     节点的"反向距离"分配权重，权重之和恒为 1。这保证了 **逐粒子的局部守恒**：
     ``sum_{nodes} weight = 1``，因此 ``sum_{nodes} den = sum_p w_p``。
   - **节点定义在角上**。Cartesian 三线性把 ``den`` 放在整数索引节点
     ``(i,j,k)``；不像 staggered 网格那样区分边、面中心。``_v`` 也是节点量。
   - **温度/方差是最近格子**。``sub_..._T`` 不用 CIC，而是把每个粒子的速度
     直接归到它所在 cell 的"最近格子"，最后在节点上算
     :math:`\langle (v - \langle v\rangle)^2\rangle`。这是为了让方差表达式
     干净；用 CIC 的话方差不能逐节点闭式算。
   - **OMP 用 reduction**。当前 ``B01`` 的实现是
     ``!$omp parallel default(firstprivate) reduction(+:den)``——每个线程拿
     ``par`` 和 ``den`` 的本地副本，循环结束再做求和归约。在大 ``np``
     和高线程数下，``firstprivate(par)`` 的拷贝开销会主导。
   - **柱坐标多了体积因子** ``r``。在 ``(r,\phi,z)`` 网格里，cell 体积正比于
     ``r``，所以"均匀物理密度"和"均匀宏粒子密度"是两个不同的概念。
     ``B02`` 里有两组 test 分别覆盖这两种采样约定，确保实现一致。
   - **场不在 scatter 里**。scatter 输入是粒子位置 + 一个标量，输出是网格上
     的累加量。后续的 Poisson 求解（``D_Poisson``）或 Maxwell 推进
     （``E_Maxwell``）是别人的事。

   .. rubric:: 初学者最容易混的点

   - ``_v`` **不是另一种坐标**。``sub_B01_scatter_3Dxyz_v`` 的 ``_v`` 是
     "velocity moment"，把 ``par(d,:) * w`` 按 CIC 权重沉积；
     ``d=4,5,6`` 分别对应 ``v_x, v_y, v_z``。和 Cartesian / cylindrical
     的几何选择 **无关**。
   - ``_T`` **用最近格子法**。``sub_..._T`` 不是 CIC 也不是 ``_v`` 的二阶矩，
     而是基于最近格子的方差。混了这层会以为 ``_T`` 也守恒
     ``sum(den_T) = sum(w*v^2)``——并不。
   - ``par`` **维度跟接口要严格匹配**。如果上游声明
     ``real, dimension(1:3, 1:np) :: par`` 而调用方传
     ``real(1:6, 1:np_max)`` 的整段，Fortran 会按 stride 3 而不是 stride 6
     重解释，每隔一列读到的是速度槽（全零），位置直接错位。这就是
     :doc:`B01 测试 </tests/004_scatter/B01_scatter_3Dxyz>` case 04 抓到的
     "20 单位质量堆到 ``(0,0,0)``" bug。
   - **边界 / ghost cell 不在 scatter 里**。粒子落在 ``[il-1, iu+1]``
     范围外不会被处理；调用方要在 scatter 之前处理出界粒子，并预留
     guard cell 用于跨域累加。
   - **柱坐标的“密度”要除以** ``r``。``B02`` 沉积出来的 ``rho`` 是 charge per
     grid cell，要得到物理上的电荷密度还需要除以 cell 体积 ``r \Delta r \Delta\phi \Delta z``。

   .. rubric:: 建议练习

   1. 跑 :doc:`B01 测试 </tests/004_scatter/B01_scatter_3Dxyz>` case 1（单粒子在
      ``(2.5, 3.5, 4.5)``），手算 8 个节点的 CIC 权重，跟输出对照。
   2. 跑 case 04（hollow square + H + cross），看 ``result_many.png``，
      理解"几何图案沉积之后切片长什么样"。
   3. 跑 :doc:`B01 鲲鹏对比 </tests/kunpeng_compare/B01_scatter_3Dxyz_omp>`，
      看 efficiency 曲线在高 ``nthread`` 上的崩塌——理解 ``firstprivate par``
      和 reduction merge 在内存带宽和拷贝开销上的权衡。
   4. 跑 ``B02_deposit_3d_cyl/test1`` 和 ``test2``，对比"体积均匀采样" vs
      "``r`` 均匀采样 + 权重 ``2r/Rmax``"两种约定下的 ``rho``。两者应在
      cell-volume 归一化之后一致。

.. container:: ap-lang ap-lang-en

   .. rubric:: What This Page Is For

   This page is aimed at readers new to ``B_Scatter``. It is not a PIC
   textbook; it connects the geometric picture of particle-to-grid scatter
   to the Fortran routines in AlgoPlasma. After reading it, you should know which
   page to read first, which formula maps to which code, and why the tests
   give you confidence in the implementation.

   .. rubric:: Suggested Learning Order

   .. list-table::
      :header-rows: 1
      :widths: 18 44 38

      * - Step
        - What to understand first
        - Suggested reading
      * - 1
        - The basic picture of particle-to-grid deposition: trilinear (CIC) weights and conservation.
        - "Core Mental Model" below.
      * - 2
        - One full 3D Cartesian density scatter (``sub_B01_scatter_3Dxyz``).
        - :doc:`B01_scatter_3Dxyz <B01_scatter_3Dxyz>` and the API page of ``sub_B01_scatter_3Dxyz``.
      * - 3
        - How the ``_v`` (velocity moment) and ``_T`` (temperature / variance) variants differ from plain density scatter.
        - API pages of the three subroutines under :doc:`B01_scatter_3Dxyz <B01_scatter_3Dxyz>`.
      * - 4
        - How to call the scatter routines and integrate them into a PIC loop.
        - :doc:`Scatter Usage Cookbook <scatter_usage_cookbook>`
      * - 5
        - The extra cylindrical ``(r,\phi,z)`` factor of ``r`` and the closure at the axis (``r=0``).
        - :doc:`B02_deposit_3d_cyl <B02_deposit_3d_cyl>`
      * - 6
        - How to validate conservation, node-weight accuracy, and OMP consistency.
        - :doc:`Scatter Testing Guide <scatter_testing_guide>`
          and :doc:`004_scatter tests </tests/004_scatter/index>`.

   .. rubric:: Core Mental Model

   Every ``B_Scatter`` routine does the same thing: distribute a per-particle
   quantity (weight, velocity component, kinetic / variance moment) onto
   grid nodes by geometric weights. In a full PIC loop the caller owns
   particle arrays, boundaries, ghost cells, and any cross-domain reduction;
   the scatter routine itself just accumulates.

   - **Trilinear (CIC) weights.** Each particle sits inside one grid cell;
     it distributes its weight to the eight surrounding nodes by inverse
     distance, and the eight weights sum to 1. This gives **per-particle
     local conservation**: ``sum_{nodes} weight = 1``, hence
     ``sum_{nodes} den = sum_p w_p``.
   - **Nodes are at corners.** Cartesian trilinear places ``den`` at the
     integer-index nodes ``(i,j,k)``; this isn't a staggered grid with
     edges or face centres. ``_v`` is also a node quantity.
   - **Temperature / variance uses nearest-cell.** ``sub_..._T`` does
     **not** use CIC; it assigns each particle's velocity directly to the
     cell it lives in and then evaluates
     :math:`\langle (v - \langle v\rangle)^2\rangle` per cell. The
     CIC-weighted variance has no clean per-node closed form.
   - **OMP uses reduction.** The current ``B01`` implementation is
     ``!$omp parallel default(firstprivate) reduction(+:den)`` — each thread
     gets a private copy of both ``par`` and ``den`` and sums into the
     shared one. At large ``np`` and high thread counts the
     ``firstprivate(par)`` copy dominates the cost.
   - **Cylindrical adds a volume factor** ``r``. In a ``(r,\phi,z)`` grid,
     cell volume scales with ``r``, so "uniform physical density" and
     "uniform macro-particle density" are different concepts. ``B02`` has
     two subtests covering both sampling conventions to confirm the
     implementation matches both.
   - **Fields are not part of scatter.** The input is particle position +
     a scalar; the output is the accumulated grid quantity. The Poisson
     solve (``D_Poisson``) or Maxwell update (``E_Maxwell``) is somebody
     else's job.

   .. rubric:: Common Beginner Traps

   - ``_v`` **is not a coordinate variant.** The ``_v`` suffix in
     ``sub_B01_scatter_3Dxyz_v`` means "velocity moment": ``par(d,:) * w``
     is deposited with CIC weights, with ``d=4,5,6`` for ``v_x, v_y, v_z``.
     It has **nothing** to do with Cartesian vs cylindrical geometry.
   - ``_T`` **uses nearest-cell, not CIC.** ``sub_..._T`` is not the second
     moment of ``_v``; it's a nearest-cell variance. Conflating the two
     leads to wrongly expecting ``sum(den_T) = sum(w*v^2)``.
   - ``par`` **shape must match exactly.** If the upstream declares
     ``real, dimension(1:3, 1:np) :: par`` but the caller passes a
     ``real(1:6, 1:np_max)`` slab, Fortran reinterprets it with stride 3,
     reading every other column as garbage velocity slots. That's the
     "20 units of mass at ``(0,0,0)``" bug that
     :doc:`B01 tests </tests/004_scatter/B01_scatter_3Dxyz>` case 04
     caught.
   - **Boundaries / ghost cells aren't in scatter.** Particles outside
     ``[il-1, iu+1]`` are not handled; the caller must process
     out-of-domain particles before scatter and reserve guard cells for
     cross-domain accumulation.
   - **Cylindrical “density” must be divided by** ``r``. The ``rho``
     produced by ``B02`` is charge per grid cell; the physical charge
     density requires dividing by cell volume
     ``r \Delta r \Delta\phi \Delta z``.

   .. rubric:: Suggested Exercises

   1. Run :doc:`B01 tests </tests/004_scatter/B01_scatter_3Dxyz>` case 1
      (single particle at ``(2.5, 3.5, 4.5)``), compute the eight CIC
      weights by hand, and cross-check against the output.
   2. Run case 04 (hollow square + H + cross) and inspect
      ``result_many.png`` to internalise what "structured deposition"
      looks like in slices.
   3. Run the :doc:`B01 Kunpeng comparison </tests/kunpeng_compare/B01_scatter_3Dxyz_omp>`
      and watch the efficiency curves collapse at high ``nthread``; that
      teaches you the cost of ``firstprivate par`` and the reduction
      merge in memory bandwidth and copies.
   4. Run ``B02_deposit_3d_cyl/test1`` and ``test2`` and compare ``rho``
      under "uniform volume sampling" vs "uniform ``r`` sampling with
      weight ``2r/Rmax``"; the two should agree once normalised by cell
      volume.
