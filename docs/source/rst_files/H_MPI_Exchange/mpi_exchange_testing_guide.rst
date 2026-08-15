MPI Exchange Testing Guide
==========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. raw:: html

   <div class="ap-mpi-guide">

.. container:: ap-lang ap-lang-zh

   .. rubric:: 1. 范围

   本指南专门说明 ``tests/008_mpi_exchange`` 的算例构造、手工期望值和诊断数据含义。
   如果只需要看“怎么跑、覆盖到哪里、如何判断通过”，先看
   :doc:`/tests/008_mpi_exchange/index`。

   当前 case 固定使用 4 个 MPI rank 和 ``2 x 2 x 1`` 拓扑：

   .. list-table::
      :header-rows: 1
      :widths: 18 24 58

      * - 项目
        - 固定设置
        - 说明
      * - rank 数
        - ``4``
        - 用最小代价覆盖真实 MPI 邻居交换。
      * - 拓扑
        - ``2 x 2 x 1``
        - x/y 方向有真实 MPI 邻居，z 方向不拆分。
      * - H01 覆盖
        - x/y halo + 本地 z 周期
        - 同时检查真实 halo 覆盖和 unsplit 方向的本地 ghost 填充。
      * - H02 覆盖
        - x/y face/edge/corner + 吸收边界 + 本地 z 回绕
        - 一次运行覆盖所有权迁移、删除和本地周期 wrap。
      * - H03 覆盖
        - x/y 边界累加 + 本地 z 周期折叠
        - 区分“覆盖 ghost”与“累加边界节点”两种语义。

   .. raw:: html

      <div class="ap-home-panel ap-topology-panel">
        <div class="ap-topology-label">拓扑 / 逻辑坐标</div>
        <div class="ap-topology-grid">
          <span class="ap-topology-node"><strong>rank 2</strong><code>(1,2,1)</code></span>
          <span class="ap-topology-node"><strong>rank 3</strong><code>(2,2,1)</code></span>
          <span class="ap-topology-node"><strong>rank 0</strong><code>(1,1,1)</code></span>
          <span class="ap-topology-node"><strong>rank 1</strong><code>(2,1,1)</code></span>
        </div>
      </div>

   这个 guide 关注“为什么这样构造、期望值怎么算”，而不是脚本入口细节。

   .. rubric:: 2. 逻辑拓扑

   ``init_topology`` 的逻辑坐标和真实邻居关系如下：

   .. list-table::
      :header-rows: 1
      :widths: 10 16 30 30 14

      * - rank
        - 逻辑坐标
        - x 邻居
        - y 邻居
        - z 邻居
      * - 0
        - ``(1,1,1)``
        - ``+x -> 1``，``-x -> 无``
        - ``+y -> 2``，``-y -> 无``
        - 无
      * - 1
        - ``(2,1,1)``
        - ``-x -> 0``，``+x -> 无``
        - ``+y -> 3``，``-y -> 无``
        - 无
      * - 2
        - ``(1,2,1)``
        - ``+x -> 3``，``-x -> 无``
        - ``-y -> 0``，``+y -> 无``
        - 无
      * - 3
        - ``(2,2,1)``
        - ``-x -> 2``，``+x -> 无``
        - ``-y -> 1``，``+y -> 无``
        - 无

   .. rubric:: 3. H01 场量 halo 测试

   .. list-table::
      :header-rows: 1
      :widths: 20 26 54

      * - 项目
        - 设置
        - 说明
      * - 有效区间
        - ``il=(/1,1,1/)``，``iu=(/4,4,3/)``
        - 每个 rank 的 active block 都相同。
      * - 本地数组范围
        - ``i=0:5, j=0:5, k=0:4``
        - active block 为 ``4 x 4 x 3``，外面包一层 ghost。
      * - 初始化
        - ``f(i,j,k)=1000*rank+100*i+10*j+k``
        - 数值可直接反推来源 rank 和格点。
      * - 发送层契约
        - ``iu-1`` / ``il+1``
        - H01 发的是有效内部一层，不是 ``iu`` / ``il`` 边界面。
      * - 接收层契约
        - ``iu+1`` / ``il-1``
        - 收到的数据写入 ghost 层。

   .. list-table::
      :header-rows: 1
      :widths: 10 16 24 22 28

      * - 轮次
        - ``l``
        - 目标
        - 断言粒度
        - 代表样本 / 期望
      * - 1
        - ``(/0,0,0/)``
        - 只测 x/y 的真实 MPI halo
        - 整张 x 面和 y 面逐点比较
        - ``f(5,2,2) <- rank 1`` 的 ``f(2,2,2)=1222``
      * - 2
        - ``(/0,0,3/)``
        - 只测 unsplit z 的本地周期 ghost
        - 抽查两个代表点
        - ``f(2,2,0)=f(2,2,2)``, ``f(2,2,4)=f(2,2,2)``

   本地 z 周期规则就是：
   ``f(:,:,il(3)-1)=f(:,:,iu(3)-1)``，
   ``f(:,:,iu(3)+1)=f(:,:,il(3)+1)``。

   .. rubric:: 4. H03 密度边界累加测试

   .. list-table::
      :header-rows: 1
      :widths: 20 26 54

      * - 项目
        - 设置
        - 说明
      * - 有效区间
        - ``il=(/1,1,1/)``，``iu=(/3,3,2/)``
        - 每个 rank 的 active block 都相同。
      * - 初始化
        - ``den(i,j,k)=2000*rank+100*i+10*j+k``
        - 数值可直接拆成本地值和邻居贡献。
      * - 接收语义
        - 边界节点累加
        - H03 不是 ghost 覆盖，而是把邻居贡献加到 ``il/iu`` 边界节点。
      * - 本地 z 周期
        - ``den(il)+=den(iu)``，再镜像回 ``iu``
        - 表示 unsplit 周期方向的本地折叠。

   .. list-table::
      :header-rows: 1
      :widths: 10 16 24 22 28

      * - 轮次
        - ``l``
        - 目标
        - 断言粒度
        - 代表样本 / 期望
      * - 1
        - ``(/0,0,0/)``
        - 只测 x/y 边界累加
        - x 面固定 ``j=2``，y 面固定 ``i=2``，沿 ``k`` 抽样
        - ``den(3,2,1)=321+2121=2442``
      * - 2
        - ``(/0,0,2/)``
        - 只测 z 周期折叠
        - 抽查一个代表点
        - ``den(2,2,1)=d(...,1)+d(...,2)``, ``den(2,2,2)=同值``

   ``build/h03_density_faces.dat`` 和 ``fig/h03_density_exchange.png`` 当前取自第二轮，
   也就是“已经做完 z 周期折叠”的样本状态，而不是第一轮非周期 x/y 边界断言的完整导出。
   因此 ``2442`` 仍然是解释 H03 累加语义的正确例子，但图和 ``.dat`` 会反映第二轮状态。

   .. rubric:: 5. H02 粒子迁移测试

   .. list-table::
      :header-rows: 1
      :widths: 20 26 54

      * - 项目
        - 设置
        - 说明
      * - 全局粒子盒子
        - ``il0=(/1,1,1/)``，``iu0=(/8,8,4/)``
        - 全局局域边界由这一对索引定义。
      * - 周期长度
        - ``l=(/0.0,0.0,4.0/)``
        - 只有 z 是周期方向，x/y 为非周期。
      * - 局部归属规则
        - ``[il(d)-1, iu(d))``
        - 半开区间避免边界粒子双重归属。
      * - 物种与 ID
        - ``ns=2``，测试 ID 写入 ``par(4)``
        - 方便检查迁移后所有权和删除行为。

   下面几张表建议按“拥有区间 -> 初始粒子构成 -> 刻意越界样本 -> 最终期望归属”的顺序阅读。
   先用 rank 的 x/y 拥有区间判断一个粒子理论上应该属于谁，再对照基础粒子和额外越界粒子的设计，
   最后核对迁移后的最终 ID 分布，这样更容易把“为什么会迁移到这个 rank”直接追溯回初值构造。

   .. list-table::
      :class: ap-table-compact
      :header-rows: 1
      :widths: 10 18 30

      * - rank
        - x 拥有区间
        - y 拥有区间
      * - 0
        - ``[0,4)``
        - ``[0,4)``
      * - 1
        - ``[4,8)``
        - ``[0,4)``
      * - 2
        - ``[0,4)``
        - ``[4,8)``
      * - 3
        - ``[4,8)``
        - ``[4,8)``

   由于本 case 只在 x/y 上做真实 MPI 拆分，z 方向不会改变 MPI 所有者；
   z 只负责触发“本地周期回绕”这条逻辑，因此后面看到 ``1300 + rank`` 时，
   应理解为“rank 不变，但粒子坐标会被本地修正”。

   .. list-table::
      :header-rows: 1
      :widths: 22 12 66

      * - 基础粒子 ID
        - species
        - 作用
      * - ``1000 + rank``
        - 1
        - 本地保留，给迁移前后提供稳定参照。
      * - ``1300 + rank``
        - 1
        - 初值设成 ``z=iu(3)+0.25``，用于测试本地 z 周期回绕。
      * - ``2000 + rank``
        - 2
        - 本地保留，验证第二物种不被错误迁移。

   .. list-table::
      :header-rows: 1
      :widths: 10 42 48

      * - rank
        - 额外放入的越界粒子
        - 主要覆盖
      * - 0
        - ``1201, 1202, 1203, 1900, 2201``
        - x/y 迁移、吸收边界、species 2
      * - 1
        - ``1211, 1212, 1213, 2211``
        - x/y 迁移、corner、species 2
      * - 2
        - ``1221, 1222, 1223, 2222``
        - x/y 迁移、corner、species 2
      * - 3
        - ``1231, 1232, 1233, 1903, 2231``
        - x/y 迁移、吸收边界、species 2

   ``1900`` 和 ``1903`` 设计为越过全局非周期边界，必须被吸收删除；
   ``1300 + rank`` 设计为越过 z 上边界，并在本地回绕到 ``z=0.25``。
   也就是说，这里同时故意混入了三类事件：跨 rank 迁移、本地 wrap、以及全局吸收删除，
   这样最终结果表不只是“列一个答案”，而是在同一套样本里同时验证三种边界行为。

   .. list-table::
      :header-rows: 1
      :widths: 10 48 42

      * - rank
        - species 1 最终应持有的 ID
        - species 2 最终应持有的 ID
      * - 0
        - ``1000, 1211, 1221, 1233, 1300``
        - ``2000, 2211``
      * - 1
        - ``1001, 1201, 1223, 1232, 1301``
        - ``2001, 2201``
      * - 2
        - ``1002, 1202, 1213, 1231, 1302``
        - ``2002, 2231``
      * - 3
        - ``1003, 1203, 1212, 1222, 1303``
        - ``2003, 2222``

   这张“最终应持有的 ID”表可以看成前面三张输入表的汇总结论：
   ``1000 + rank`` / ``2000 + rank`` 用来验证本地保留，
   ``12xx`` / ``22xx`` 用来验证跨 rank 迁移是否落到了正确拥有者，
   ``1300 + rank`` 用来验证 z 周期回绕后仍留在原 rank，
   而 ``1900`` / ``1903`` 则应该完全从全局结果里消失。

   .. list-table::
      :class: ap-table-compact
      :header-rows: 1
      :widths: 36 64

      * - 检查项
        - 通过条件
      * - 本地粒子数
        - 每个 rank、每个 species 的本地计数都与上表一致。
      * - 粒子所有权
        - 每个期望 ID 都出现在正确 rank，且不重复。
      * - z 周期回绕
        - ``1300 + rank`` 的 ``z`` 变成 ``0.25``。
      * - 吸收边界
        - ``1900`` 和 ``1903`` 的全局计数都为零。

   .. rubric:: 6. 诊断输出的用途

   这三份诊断输出并不是三套独立的测试，而是分别对应 H01、H02、H03 三类交换语义的可视化切片。
   它们的作用是把 Fortran 断言背后的“局部面值、边界累加状态、粒子所有权变化”具体展示出来，
   方便在断言失败时快速判断问题更像是 halo 覆盖错误、边界累加错误，还是粒子归属错误。

   .. list-table::
      :class: ap-table-compact
      :header-rows: 1
      :widths: 34 24 42

      * - Fortran 诊断表
        - Python 输出图
        - 主要用途
      * - ``build/h01_field_faces.dat``
        - ``fig/h01_field_exchange.png``
        - 展示 H01 代表面值，快速检查 halo 覆盖。
      * - ``build/h02_particle_exchange.dat``
        - ``fig/h02_particle_exchange.png``
        - 展示迁移前后粒子所有权和边界行为。
      * - ``build/h03_density_faces.dat``
        - ``fig/h03_density_exchange.png``
        - 展示 H03 边界累加和 z 周期折叠后的样本状态。

   这些文件适合文档配图、排障和汇报展示，但不是 pass/fail 的唯一依据；
   真正的通过条件仍然是 ``test_H_MPI_Exchange.f90`` 中的 Fortran 断言全部成功。
   一个实用的排查顺序是：先看断言失败落在 H01/H02/H03 的哪一段，再去对照对应 ``.dat`` 和图，
   这样能更快缩小到“发送层不对”“累加语义不对”或“粒子删除/迁移不对”这类具体错误。

.. container:: ap-lang ap-lang-en

   .. rubric:: 1. Scope

   This guide explains how ``tests/008_mpi_exchange`` is constructed, how the
   expected values are derived by hand, and how to read the diagnostic outputs.
   If you only need run commands, coverage, and pass/fail interpretation, start
   from :doc:`/tests/008_mpi_exchange/index`.

   The case always uses 4 MPI ranks on a fixed ``2 x 2 x 1`` topology:

   .. list-table::
      :header-rows: 1
      :widths: 18 24 58

      * - Item
        - Fixed setting
        - Meaning
      * - Rank count
        - ``4``
        - Covers the exchange logic with the smallest useful MPI run.
      * - Topology
        - ``2 x 2 x 1``
        - x/y have real MPI neighbors while z stays unsplit.
      * - H01 coverage
        - x/y halos + local z periodic fill
        - Exercises both true halo overwrite and unsplit-direction local ghost handling.
      * - H02 coverage
        - x/y face/edge/corner + absorbing boundaries + local z wrap
        - One run covers migration, deletion, and local periodic wrapping.
      * - H03 coverage
        - x/y accumulation + local z periodic fold
        - Separates "overwrite ghost" from "accumulate boundary node" semantics.

   .. raw:: html

      <div class="ap-home-panel ap-topology-panel">
        <div class="ap-topology-label">Topology / Logical Coordinates</div>
        <div class="ap-topology-grid">
          <span class="ap-topology-node"><strong>rank 2</strong><code>(1,2,1)</code></span>
          <span class="ap-topology-node"><strong>rank 3</strong><code>(2,2,1)</code></span>
          <span class="ap-topology-node"><strong>rank 0</strong><code>(1,1,1)</code></span>
          <span class="ap-topology-node"><strong>rank 1</strong><code>(2,1,1)</code></span>
        </div>
      </div>

   This guide is about "why this case is built this way" and "how the expected
   values are computed", not about shell-script entry points.

   .. rubric:: 2. Logical Topology

   ``init_topology`` gives the following logical coordinates and real
   neighbor relations:

   .. list-table::
      :header-rows: 1
      :widths: 10 16 30 30 14

      * - Rank
        - Logical index
        - x neighbors
        - y neighbors
        - z neighbors
      * - 0
        - ``(1,1,1)``
        - ``+x -> 1``, ``-x -> none``
        - ``+y -> 2``, ``-y -> none``
        - none
      * - 1
        - ``(2,1,1)``
        - ``-x -> 0``, ``+x -> none``
        - ``+y -> 3``, ``-y -> none``
        - none
      * - 2
        - ``(1,2,1)``
        - ``+x -> 3``, ``-x -> none``
        - ``-y -> 0``, ``+y -> none``
        - none
      * - 3
        - ``(2,2,1)``
        - ``-x -> 2``, ``+x -> none``
        - ``-y -> 1``, ``+y -> none``
        - none

   .. rubric:: 3. H01 Field Halo Test

   .. list-table::
      :header-rows: 1
      :widths: 20 26 54

      * - Item
        - Setting
        - Meaning
      * - Effective range
        - ``il=(/1,1,1/)``, ``iu=(/4,4,3/)``
        - The active block is identical on every rank.
      * - Local array range
        - ``i=0:5, j=0:5, k=0:4``
        - One ``4 x 4 x 3`` active block plus one ghost layer.
      * - Initialization
        - ``f(i,j,k)=1000*rank+100*i+10*j+k``
        - Every value directly reveals its source rank and indices.
      * - Send-layer contract
        - ``iu-1`` / ``il+1``
        - H01 sends the inner effective layer, not ``iu`` / ``il``.
      * - Receive-layer contract
        - ``iu+1`` / ``il-1``
        - Received values overwrite local ghosts.

   .. list-table::
      :header-rows: 1
      :widths: 10 16 24 22 28

      * - Pass
        - ``l``
        - Goal
        - Assertion granularity
        - Representative sample / expected result
      * - 1
        - ``(/0,0,0/)``
        - Test true x/y MPI halos only
        - Full x and y faces pointwise
        - ``f(5,2,2) <- rank 1`` value ``f(2,2,2)=1222``
      * - 2
        - ``(/0,0,3/)``
        - Test local z-periodic ghost fill
        - Two representative sample points
        - ``f(2,2,0)=f(2,2,2)``, ``f(2,2,4)=f(2,2,2)``

   The local z-periodic rule is:
   ``f(:,:,il(3)-1)=f(:,:,iu(3)-1)``,
   ``f(:,:,iu(3)+1)=f(:,:,il(3)+1)``.

   .. rubric:: 4. H03 Density Accumulation Test

   .. list-table::
      :header-rows: 1
      :widths: 20 26 54

      * - Item
        - Setting
        - Meaning
      * - Effective range
        - ``il=(/1,1,1/)``, ``iu=(/3,3,2/)``
        - The active block is identical on every rank.
      * - Initialization
        - ``den(i,j,k)=2000*rank+100*i+10*j+k``
        - Values can be decomposed into local and neighbor contributions by inspection.
      * - Receive semantics
        - Boundary-node accumulation
        - H03 does not overwrite ghosts; it adds neighbor values onto ``il/iu``.
      * - Local z periodic rule
        - ``den(il)+=den(iu)``, then mirror back to ``iu``
        - This is the local fold used in the unsplit periodic direction.

   .. list-table::
      :header-rows: 1
      :widths: 10 16 24 22 28

      * - Pass
        - ``l``
        - Goal
        - Assertion granularity
        - Representative sample / expected result
      * - 1
        - ``(/0,0,0/)``
        - Test x/y boundary accumulation only
        - Sample one center line on each boundary face
        - ``den(3,2,1)=321+2121=2442``
      * - 2
        - ``(/0,0,2/)``
        - Test local z-periodic folding
        - One representative point
        - ``den(2,2,1)=d(...,1)+d(...,2)``, ``den(2,2,2)=same``

   ``build/h03_density_faces.dat`` and ``fig/h03_density_exchange.png`` are
   currently generated from the second pass, i.e. after z-periodic folding.
   So values like ``2442`` remain the correct conceptual examples for H03
   accumulation semantics, while the dumped and plotted samples reflect the
   second-pass state.

   .. rubric:: 5. H02 Particle Migration Test

   .. list-table::
      :header-rows: 1
      :widths: 20 26 54

      * - Item
        - Setting
        - Meaning
      * - Global particle box
        - ``il0=(/1,1,1/)``, ``iu0=(/8,8,4/)``
        - Defines the global domain limits for ownership decisions.
      * - Periodic lengths
        - ``l=(/0.0,0.0,4.0/)``
        - Only z is periodic; x/y are nonperiodic.
      * - Local ownership rule
        - ``[il(d)-1, iu(d))``
        - Half-open intervals avoid double ownership on boundaries.
      * - Species and ID storage
        - ``ns=2``, test ID stored in ``par(4)``
        - Makes ownership checks explicit after migration.

   Read the next few tables in this order:
   ownership ranges -> initial particle groups -> intentionally out-of-domain
   samples -> expected final ownership.
   That order makes it easier to trace "why this particle ends up on this rank"
   directly back to how the test data was seeded.

   .. list-table::
      :class: ap-table-compact
      :header-rows: 1
      :widths: 10 18 30

      * - Rank
        - x ownership range
        - y ownership range
      * - 0
        - ``[0,4)``
        - ``[0,4)``
      * - 1
        - ``[4,8)``
        - ``[0,4)``
      * - 2
        - ``[0,4)``
        - ``[4,8)``
      * - 3
        - ``[4,8)``
        - ``[4,8)``

   Because this case is only MPI-decomposed in x/y, the z direction never
   changes the owning MPI rank. z only triggers the local periodic-wrap path,
   so ``1300 + rank`` should be read as "same rank, corrected local z".

   .. list-table::
      :header-rows: 1
      :widths: 22 12 66

      * - Base-particle ID
        - Species
        - Role
      * - ``1000 + rank``
        - 1
        - Stays local and provides a stable reference.
      * - ``1300 + rank``
        - 1
        - Starts at ``z=iu(3)+0.25`` to test local z wrapping.
      * - ``2000 + rank``
        - 2
        - Stays local and verifies the second species is not moved incorrectly.

   .. list-table::
      :header-rows: 1
      :widths: 10 42 48

      * - Rank
        - Extra out-of-domain particles inserted
        - Main cases covered
      * - 0
        - ``1201, 1202, 1203, 1900, 2201``
        - x/y migration, absorbing boundary, species 2
      * - 1
        - ``1211, 1212, 1213, 2211``
        - x/y migration, corner cases, species 2
      * - 2
        - ``1221, 1222, 1223, 2222``
        - x/y migration, corner cases, species 2
      * - 3
        - ``1231, 1232, 1233, 1903, 2231``
        - x/y migration, absorbing boundary, species 2

   ``1900`` and ``1903`` are designed to cross nonperiodic global boundaries
   and must be absorbed. ``1300 + rank`` crosses the z upper boundary and must
   wrap locally to ``z=0.25``.
   In other words, the same dataset deliberately mixes three event types:
   cross-rank migration, local wrapping, and global absorbing deletion.
   The final-ID table therefore validates three boundary behaviors at once,
   not just one migration pattern.

   .. list-table::
      :header-rows: 1
      :widths: 10 48 42

      * - Rank
        - Species 1 expected final IDs
        - Species 2 expected final IDs
      * - 0
        - ``1000, 1211, 1221, 1233, 1300``
        - ``2000, 2211``
      * - 1
        - ``1001, 1201, 1223, 1232, 1301``
        - ``2001, 2201``
      * - 2
        - ``1002, 1202, 1213, 1231, 1302``
        - ``2002, 2231``
      * - 3
        - ``1003, 1203, 1212, 1222, 1303``
        - ``2003, 2222``

   This final-ownership table is the combined conclusion of the previous input
   tables:
   ``1000 + rank`` / ``2000 + rank`` validate local retention,
   ``12xx`` / ``22xx`` validate cross-rank migration to the correct owner,
   ``1300 + rank`` validates z wrapping without ownership change,
   and ``1900`` / ``1903`` should disappear from the global result entirely.

   .. list-table::
      :class: ap-table-compact
      :header-rows: 1
      :widths: 36 64

      * - Check
        - Pass condition
      * - Local counts
        - Per-rank, per-species counts match the table above.
      * - Ownership
        - Every expected ID exists on the correct rank and is not duplicated.
      * - z wrapping
        - ``1300 + rank`` has ``z=0.25``.
      * - Absorbing boundaries
        - Global counts of ``1900`` and ``1903`` are zero.

   .. rubric:: 6. Purpose of the diagnostic outputs

   These three diagnostics are not three unrelated reports.
   They are the H01, H02, and H03 visual slices of the same testing strategy.
   Their role is to expose the local face values, boundary-accumulation state,
   and particle-ownership changes behind the Fortran assertions, so when an
   assertion fails you can quickly tell whether the bug looks like a halo
   overwrite issue, an accumulation issue, or an ownership issue.

   .. list-table::
      :class: ap-table-compact
      :header-rows: 1
      :widths: 34 24 42

      * - Fortran diagnostic table
        - Python figure
        - Main use
      * - ``build/h01_field_faces.dat``
        - ``fig/h01_field_exchange.png``
        - Shows representative H01 face values and halo overwrite behavior.
      * - ``build/h02_particle_exchange.dat``
        - ``fig/h02_particle_exchange.png``
        - Shows particle ownership before and after migration.
      * - ``build/h03_density_faces.dat``
        - ``fig/h03_density_exchange.png``
        - Shows H03 accumulation samples and the z-folded state.

   These files are useful for documentation figures, debugging, and regression
   summaries, but they are not the sole pass/fail criterion. The real decision
   still comes from the Fortran assertions in ``test_H_MPI_Exchange.f90``.
   A practical debugging order is: first identify whether the failing
   assertion belongs to H01, H02, or H03, then inspect the matching ``.dat``
   and figure to narrow it down to send-layer mistakes, accumulation-semantics
   mistakes, or particle migration/deletion mistakes.

.. raw:: html

   </div>
