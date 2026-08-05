H02_mpi_exchange_par
====================

.. toctree::
    :maxdepth: 1
    :hidden:

    H02_mpi_exchange_par/mod_H02_mpi_exchange_par
    H02_mpi_exchange_par/sub_H02_mpi_exchange_par_init
    H02_mpi_exchange_par/sub_H02_mpi_exchange_par

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``H02_mpi_exchange_par`` 是 3D Cartesian 区域分解下的多物种粒子交换模块。它把越出本 rank
   半开子域 ``[xlo,xhi)`` 的粒子迁移到相邻 rank，支持 26 个方向的 face/edge/corner 邻居。
   模块缓存邻居表、MPI tag 和工作缓冲区，以避免热路径重复分配。

   .. rubric:: 初学者先抓住什么

   H02 的关键不是“拷贝一块数组”，而是“恢复粒子所有权的一致性”：

   - push 之后，每个粒子都应该重新落回某一个本地半开盒子 ``[il(d)-1, iu(d))``。
   - 若该方向没做 MPI 分裂且是周期边界，就本地回绕；这一步不走 MPI。
   - 若该方向没做 MPI 分裂且不是周期边界，就本地删除；这表示吸收边界。
   - 只有粒子真的跨到别的 MPI 子域时，才会发给 face/edge/corner 邻居。

   因此，H02 的核心语义是 **move ownership**，而不是 ghost 覆盖或边界求和。

   .. rubric:: 最小调用顺序

   .. code-block:: fortran

      call sub_H02_mpi_exchange_par_init(...)
      ...
      call push_particles(...)
      call sub_H02_mpi_exchange_par(...)

   .. rubric:: 文件角色

   .. list-table::
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 角色
      * - :doc:`mod_H02_mpi_exchange_par.f90 <H02_mpi_exchange_par/mod_H02_mpi_exchange_par>`
        - 保存邻居元数据、tag、发送/接收缓冲区和 ``DIR_ID`` 工具函数。
      * - :doc:`sub_H02_mpi_exchange_par_init.f90 <H02_mpi_exchange_par/sub_H02_mpi_exchange_par_init>`
        - 初始化当前 rank 的邻居列表、方向映射、tag 范围和缓存缓冲区。
      * - :doc:`sub_H02_mpi_exchange_par.f90 <H02_mpi_exchange_par/sub_H02_mpi_exchange_par>`
        - 每个时间步执行粒子计数交换、打包迁出粒子、payload 交换和接收粒子追加。

   .. rubric:: 两阶段协议

   运行时交换分为两阶段：

   - Phase A：每个邻居交换 ``ns`` 个整数，表示各物种将要发送的粒子数。
   - Phase B：按邻居优先、物种拼接的布局交换打包后的 ``par(1:6,...)`` payload。

   Phase A 后会计算每个邻居最大 payload 大小，并用 ``MPI_Allreduce`` 得到全局 ``nsmax``。如果
   ``nsmax > H02_npm``，所有 rank 返回 ``istat=1``，调用方应增大 ``npm``、重新初始化并重试。

   .. rubric:: 程序语义

   ``par(1:3,:,:)`` 位置和周期长度 ``l(1:3)`` 使用 cell units，默认网格间距为 1。局部所有权用半开区间
   ``[il(d)-1, iu(d))`` 表示，避免边界粒子双重归属。若某个方向未做 MPI 分裂且 ``l(d)>0``，例程会在本地做周期 wrap；
   否则越界粒子会被送往相应邻居，或在无邻居/吸收边界情况下移出本 rank 粒子数组。

   ``sub_H02_mpi_exchange_par_init`` 把“哪些方向有邻居、该用什么 tag、缓存区有多大”预先固定下来，
   运行时 ``sub_H02_mpi_exchange_par`` 只做计数、打包、发送、接收和追加。这样的拆分与程序逻辑一致：
   拓扑和缓冲区容量很少变化，粒子迁移却是每一步都要发生的热路径。

   .. rubric:: 调用注意

   - 必须先调用 ``sub_H02_mpi_exchange_par_init``，并保证 ``ns`` 与初始化值一致。
   - 只要 ``npm`` 或 ``ns`` 改了，就要重新初始化；否则缓存区元数据和真实运行参数会脱节。
   - ``npm`` 应在所有 rank 上一致，且足够容纳单个邻居方向的最大迁移粒子数。
   - 模块使用全局缓存数组，不是线程安全的；应从单个 OpenMP 线程调用。
   - 当前实现直接使用 ``MPI_COMM_WORLD``，并要求 ``MPI_TAG_UB`` 支持 ``TAG_BASE_DATA + 26``。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵隐剑 (2025/12/17; 2025/12/18) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``H02_mpi_exchange_par`` exchanges multi-species particles in a 3D Cartesian
   domain decomposition. Particles that leave the local half-open subdomain
   ``[xlo,xhi)`` are migrated to neighbor ranks, with up to 26 face/edge/corner
   directions. The module caches neighbor metadata, MPI tags, and work buffers
   to avoid repeated allocation in the hot exchange path.

   .. rubric:: Beginner Mental Model

   The key idea in H02 is not "copy an array block" but "restore consistent
   particle ownership":

   - After the push, every particle should belong to exactly one local
     half-open box ``[il(d)-1, iu(d))``.
   - If a direction is not MPI-split and is periodic, H02 wraps locally with
     no MPI traffic in that direction.
   - If a direction is not MPI-split and is non-periodic, H02 removes the
     particle locally, which matches an absorbing boundary.
   - Only particles that really cross into another MPI subdomain are sent to a
     face, edge, or corner neighbor.

   So the core semantic is **move ownership**, not ghost overwrite and not
   boundary accumulation.

   .. rubric:: Minimal Call Order

   .. code-block:: fortran

      call sub_H02_mpi_exchange_par_init(...)
      ...
      call push_particles(...)
      call sub_H02_mpi_exchange_par(...)

   .. rubric:: File Roles

   .. list-table::
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`mod_H02_mpi_exchange_par.f90 <H02_mpi_exchange_par/mod_H02_mpi_exchange_par>`
        - Own neighbor metadata, tags, send/receive buffers, and the ``DIR_ID`` helper.
      * - :doc:`sub_H02_mpi_exchange_par_init.f90 <H02_mpi_exchange_par/sub_H02_mpi_exchange_par_init>`
        - Initialize this rank's neighbor list, direction map, tag range, and cached buffers.
      * - :doc:`sub_H02_mpi_exchange_par.f90 <H02_mpi_exchange_par/sub_H02_mpi_exchange_par>`
        - Exchange particle counts, pack outgoing particles, exchange payloads, and append incoming particles.

   .. rubric:: Two-Phase Protocol

   Runtime exchange uses two phases:

   - Phase A: exchange ``ns`` integers with each neighbor, one count per species.
   - Phase B: exchange packed ``par(1:6,...)`` payloads in a neighbor-major, species-concatenated layout.

   After Phase A, each rank computes the maximum per-neighbor payload size and
   uses ``MPI_Allreduce`` to obtain the global ``nsmax``. If
   ``nsmax > H02_npm``, all ranks return ``istat=1`` so the caller can increase
   ``npm``, reinitialize, and retry.

   .. rubric:: Program Semantics

   Positions ``par(1:3,:,:)`` and periodic lengths ``l(1:3)`` are in cell units,
   with an assumed grid spacing of 1. Local ownership uses half-open intervals
   ``[il(d)-1, iu(d))`` to avoid duplicate boundary ownership. If a direction is
   not MPI-split and ``l(d)>0``, local periodic wrapping is applied. Otherwise,
   outgoing particles are sent to a matching neighbor, or removed from the local
   array when no neighbor exists for an absorbing boundary.

   ``sub_H02_mpi_exchange_par_init`` fixes the neighbor set, tag mapping, and
   buffer capacity ahead of time. Runtime ``sub_H02_mpi_exchange_par`` then
   only counts, packs, communicates, and appends particles. This matches the
   intended program structure: topology changes rarely, but migration is part
   of the hot per-step path.

   .. rubric:: Calling Notes

   - Call ``sub_H02_mpi_exchange_par_init`` first, and keep runtime ``ns`` equal to the initialized value.
   - Re-run the init routine whenever ``npm`` or ``ns`` changes, otherwise the cached metadata no longer matches the runtime contract.
   - ``npm`` should be consistent on all ranks and large enough for the largest per-neighbor migration payload.
   - The module owns global cached arrays and is not thread-safe; call it from one OpenMP thread.
   - The implementation uses ``MPI_COMM_WORLD`` and requires ``MPI_TAG_UB`` to support ``TAG_BASE_DATA + 26``.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO (2025/12/17; 2025/12/18) · Harbin Institute of Technology</p>
      </div>
