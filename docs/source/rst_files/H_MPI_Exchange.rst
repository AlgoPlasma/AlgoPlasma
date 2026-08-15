H_MPI_Exchange
==============

.. toctree::
    :maxdepth: 1

    H_MPI_Exchange/H01_mpi_exchange_field
    H_MPI_Exchange/H02_mpi_exchange_par
    H_MPI_Exchange/H03_mpi_exchange_den
    H_MPI_Exchange/mpi_exchange_testing_guide

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   ``H_MPI_Exchange`` 记录 AlgoPlasma 在 3D 区域分解并行中使用的底层 MPI 数据交换例程。
   它不是通用 MPI 通信工具箱，而是围绕 PIC/FDTD 主循环里的三类数据语义拆成三组接口：

   - H01：把邻居 rank 的有效内部场值复制到本 rank 的 ghost 层。
   - H02：把离开本地子域的粒子迁移到新的所有者 rank。
   - H03：把 scatter 后落在共享边界上的密度贡献与邻居 rank 做求和累加。

   这三组接口都依赖同一套拓扑映射 ``rank_to_ijk`` / ``ijk_to_rank``，但它们的接收语义故意不同：
   H01 是覆盖，H02 是迁移所有权，H03 是累加。

   .. rubric:: 从哪里开始

   阅读和使用路线

   .. list-table::
      :header-rows: 1
      :widths: 26 34 40

      * - 读者目标
        - 先看
        - 然后看
      * - 第一次理解 H 模块，或给场求解器 / stencil 代码补 ghost 交换
        - :doc:`H01_mpi_exchange_field <H_MPI_Exchange/H01_mpi_exchange_field>`
        - 整体理解时，再看 :doc:`H03_mpi_exchange_den <H_MPI_Exchange/H03_mpi_exchange_den>` 对比“覆盖/累加”，最后看 H02；实现 ghost 交换时，直接看 :doc:`MPI Exchange Testing Guide <H_MPI_Exchange/mpi_exchange_testing_guide>` 的手工期望值。
      * - 排查粒子丢失、重复或越界所有权
        - :doc:`H02_mpi_exchange_par <H_MPI_Exchange/H02_mpi_exchange_par>`
        - 再看 ``sub_H02_mpi_exchange_par_init`` 和 ``sub_H02_mpi_exchange_par`` 页面。
      * - 排查 scatter 后边界密度不守恒
        - :doc:`H03_mpi_exchange_den <H_MPI_Exchange/H03_mpi_exchange_den>`
        - 再看 testing guide 中 H03 的样例和对照表。
      * - 修改了 H 模块，想快速确认没破坏行为
        - :doc:`MPI Exchange Testing Guide <H_MPI_Exchange/mpi_exchange_testing_guide>`
        - 再看 :doc:`008_mpi_exchange 测试总览 </tests/008_mpi_exchange/index>`。

   模块关系

   .. list-table::
      :header-rows: 1
      :widths: 18 24 28 30

      * - 模块
        - 数据对象
        - 接收/返回语义
        - 在一次时间步中的位置
      * - :doc:`H01_mpi_exchange_field <H_MPI_Exchange/H01_mpi_exchange_field>`
        - 标量场 ``f(il-1:iu+1,...)``
        - 接收后覆盖本 rank 的 ghost 层。
        - 在场更新或任意 stencil 读取邻居值之前调用。
      * - :doc:`H02_mpi_exchange_par <H_MPI_Exchange/H02_mpi_exchange_par>`
        - 多物种粒子数组 ``par(1:6,1:npmax,1:ns)``
        - 迁出粒子从本 rank 删除，迁入粒子追加到目标 rank。
        - 在粒子 push 之后、下一轮本地粒子循环或 scatter 之前调用。
      * - :doc:`H03_mpi_exchange_den <H_MPI_Exchange/H03_mpi_exchange_den>`
        - 密度数组 ``den(il-1:iu+1,...)``
        - 接收后把邻居贡献累加到本 rank 的边界节点 ``il/iu``。
        - 在本地 scatter 之后、场求解器或诊断读取密度之前调用。

   .. rubric:: 一次典型主循环里的位置

   .. code-block:: fortran

      ! setup once
      call sub_H02_mpi_exchange_par_init(...)

      ! field / stencil stage
      call prepare_local_or_physical_boundaries(...)
      call sub_H01_mpi_exchange_field(...)
      call update_local_field_or_stencil(...)

      ! particle stage
      call push_particles(...)
      call sub_H02_mpi_exchange_par(...)

      ! scatter stage
      den = 0.0
      call scatter_particles(...)
      call sub_H03_mpi_exchange_den(...)

   .. rubric:: 共同约定

   - 调用方负责构造 ``rank_to_ijk`` 和 ``ijk_to_rank``，并保证所有 rank 对邻居关系的解释一致。
   - 当前例程直接使用 ``MPI_COMM_WORLD``，没有通过参数传入自定义 communicator。
   - H01 和 H03 共享同一类逻辑拓扑输入，并都使用 blocking ``MPI_Send``/``MPI_Recv`` 加奇偶顺序避免死锁；它们真正不同的是“接收后写到哪里、用什么操作”。
   - H02 使用同样的拓扑映射，但额外缓存 26 邻居、MPI tag 和工作缓冲区，因为粒子 payload 大小随时间步变化。
   - 周期、吸收和物理边界策略不由 H 模块决定；调用方通过 ``domain_split`` 和 ``l(d)`` 给出边界语义。

   .. rubric:: 程序逻辑

   ``H_MPI_Exchange`` 更像三块“数据重排积木”，而不是完整并行框架：

   - H01 只负责“把邻居需要给我的场值放进 ghost”，不负责物理边界条件或场更新公式。
   - H02 只负责“恢复粒子所有权的一致性”，不负责 push、碰撞或粒子生成。
   - H03 只负责“合并 rank 之间共享边界上的沉积结果”，不负责 scatter 本身。

   如果把三者混成一种“万能 exchange”，程序语义反而会变得不清楚：场需要复制，粒子需要迁移，密度需要求和，它们不是同一种操作。

   .. rubric:: 测试状态

   ``tests/008_mpi_exchange`` 提供独立的小核数 MPI 回归测试。该测试使用 4 个
   rank，覆盖 H01 场量 halo 交换、H02 粒子跨 rank 迁移和 H03 密度边界累加。
   测试入口见 :doc:`008_mpi_exchange 测试总览 </tests/008_mpi_exchange/index>`；
   算例构造和期望值见
   :doc:`MPI Exchange Testing Guide <H_MPI_Exchange/mpi_exchange_testing_guide>`。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   ``H_MPI_Exchange`` documents the low-level MPI data-motion routines used by
   AlgoPlasma in 3D domain-decomposed runs. It is not a general MPI utility layer.
   Instead, it splits the PIC/FDTD loop into three different data semantics:

   - H01 copies neighboring field values into local ghost layers.
   - H02 migrates particles to the rank that now owns them.
   - H03 adds neighboring scatter contributions onto shared density boundaries.

   All three use the same topology maps ``rank_to_ijk`` / ``ijk_to_rank``, but
   their receive semantics are intentionally different: H01 overwrites, H02
   transfers ownership, and H03 accumulates.

   .. rubric:: Where to Start

   Reading and Usage Paths

   .. list-table::
      :header-rows: 1
      :widths: 26 34 40

      * - Reader goal
        - Start with
        - Then read
      * - Understand the H modules for the first time, or add ghost exchange for a field solver or stencil kernel
        - :doc:`H01_mpi_exchange_field <H_MPI_Exchange/H01_mpi_exchange_field>`
        - For the overall semantics, then read :doc:`H03_mpi_exchange_den <H_MPI_Exchange/H03_mpi_exchange_den>` for overwrite vs accumulate, and finish with H02; for ghost-exchange implementation, go straight to the hand-derived expectations in the :doc:`MPI Exchange Testing Guide <H_MPI_Exchange/mpi_exchange_testing_guide>`.
      * - Debug particle loss, duplication, or ownership mistakes
        - :doc:`H02_mpi_exchange_par <H_MPI_Exchange/H02_mpi_exchange_par>`
        - Then open the ``sub_H02_mpi_exchange_par_init`` and ``sub_H02_mpi_exchange_par`` pages.
      * - Debug scatter-boundary density mismatches
        - :doc:`H03_mpi_exchange_den <H_MPI_Exchange/H03_mpi_exchange_den>`
        - Then read the H03 case breakdown in the testing guide.
      * - Validate edits to H modules
        - :doc:`MPI Exchange Testing Guide <H_MPI_Exchange/mpi_exchange_testing_guide>`
        - Then use :doc:`008_mpi_exchange Tests </tests/008_mpi_exchange/index>`.

   Module Map

   .. list-table::
      :header-rows: 1
      :widths: 18 24 28 30

      * - Module
        - Data object
        - Receive / return semantics
        - Position in one time step
      * - :doc:`H01_mpi_exchange_field <H_MPI_Exchange/H01_mpi_exchange_field>`
        - Scalar field ``f(il-1:iu+1,...)``
        - Received data overwrites local ghost cells.
        - Call before a field update or any stencil that reads neighboring ranks.
      * - :doc:`H02_mpi_exchange_par <H_MPI_Exchange/H02_mpi_exchange_par>`
        - Multi-species particle array ``par(1:6,1:npmax,1:ns)``
        - Outgoing particles are removed locally and incoming particles are appended on the owner rank.
        - Call after the particle push and before the next local particle loop or scatter.
      * - :doc:`H03_mpi_exchange_den <H_MPI_Exchange/H03_mpi_exchange_den>`
        - Density array ``den(il-1:iu+1,...)``
        - Received data is added into boundary nodes ``il/iu``.
        - Call after local scatter and before solvers or diagnostics consume density.

   .. rubric:: Position in a Typical Main Loop

   .. code-block:: fortran

      ! setup once
      call sub_H02_mpi_exchange_par_init(...)

      ! field / stencil stage
      call prepare_local_or_physical_boundaries(...)
      call sub_H01_mpi_exchange_field(...)
      call update_local_field_or_stencil(...)

      ! particle stage
      call push_particles(...)
      call sub_H02_mpi_exchange_par(...)

      ! scatter stage
      den = 0.0
      call scatter_particles(...)
      call sub_H03_mpi_exchange_den(...)

   .. rubric:: Shared Conventions

   - Callers build ``rank_to_ijk`` and ``ijk_to_rank`` and must keep the neighbor interpretation consistent on every rank.
   - The routines use ``MPI_COMM_WORLD`` directly; no custom communicator is passed in.
   - H01 and H03 share the same logical-topology inputs and both use blocking ``MPI_Send`` / ``MPI_Recv`` with odd-even ordering to avoid deadlock. What differs is where received data lands and which operation is applied there.
   - H02 uses the same topology mapping, but caches 26-neighbor metadata, MPI tags, and work buffers because particle payload sizes vary from step to step.
   - Periodic, absorbing, and physical-boundary policy is not decided inside H modules; callers express that policy through ``domain_split`` and ``l(d)``.

   .. rubric:: Program Logic

   ``H_MPI_Exchange`` is best read as three composable data-motion building
   blocks, not as a full parallel framework:

   - H01 means "place neighbor field data into my ghost region."
   - H02 means "restore consistent particle ownership."
   - H03 means "merge scatter contributions on shared boundaries."

   Collapsing these into one generic "exchange" routine would hide the most
   important program invariant: fields are copied, particles are moved, and
   densities are summed. Those are different operations and the code keeps them
   separate on purpose.

   .. rubric:: Test Status

   A dedicated small-rank MPI regression entry lives at
   :doc:`tests/008_mpi_exchange </tests/008_mpi_exchange/index>`.  It uses 4
   ranks to cover H01 field halos, H02 particle migration across ranks, and H03
   density boundary accumulation.  See
   :doc:`MPI Exchange Testing Guide <H_MPI_Exchange/mpi_exchange_testing_guide>`
   for the case construction and expected values.
