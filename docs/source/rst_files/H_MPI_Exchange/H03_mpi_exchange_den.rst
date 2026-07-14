====================
H03_mpi_exchange_den
====================

.. toctree::
    :maxdepth: 1
    :hidden:

    H03_mpi_exchange_den/mod_H03_mpi_exchange_den
    H03_mpi_exchange_den/sub_H03_mpi_exchange_den

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``H03_mpi_exchange_den`` 用于粒子 scatter（沉积）之后的密度数组 MPI 边界交换。
   密度数组 ``den`` 含有一层 ghost cell，范围为 ``il(d)-1:iu(d)+1``。

   与场量交换（H01）的关键区别在于：场量交换接收后 **覆盖** ghost 层，
   而密度交换接收后 **累加** 到边界节点——因为相邻 rank 的粒子也会沉积到本 rank
   边界节点，两侧的贡献必须相加才等于物理密度。

   .. rubric:: 初学者先抓住什么

   H03 最容易理解的方式是：两个相邻 rank 各自 scatter 完以后，都只拿到了“自己那一半”的边界贡献。
   H03 的任务就是把这两半合成一份完整边界值。

   - 它不是 ghost 覆盖。
   - 它也不是重新做 scatter。
   - 它做的是 **sum / accumulate**。

   虽然 ``den`` 数组形式上也带一层 ghost，但 H03 真正通信和落点的是边界节点 ``il`` / ``iu``，不是 H01 那套 ``il-1`` / ``iu+1`` ghost 语义。

   .. rubric:: 文件角色

   .. list-table::
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 角色
      * - :doc:`mod_H03_mpi_exchange_den.f90 <H03_mpi_exchange_den/mod_H03_mpi_exchange_den>`
        - 模块包装器，include 密度交换主例程。
      * - :doc:`sub_H03_mpi_exchange_den.f90 <H03_mpi_exchange_den/sub_H03_mpi_exchange_den>`
        - 在未分裂方向做周期折叠，并依次执行 x/y/z 三方向的边界节点累加交换。
      * - ``inc_exchange_in_x/y/z.f90``
        - 针对单个方向打包边界面、调用 send/recv include，并把接收值 **累加** 到本地边界节点。
      * - ``inc_send_recv.f90`` / ``inc_recv_send.f90``
        - blocking ``MPI_Send`` / ``MPI_Recv`` 的两种调用顺序。

   .. rubric:: 与场量交换的对比

   .. list-table::
      :header-rows: 1
      :widths: 28 36 36

      * - 属性
        - 场量交换（H01）
        - 密度交换（H03）
      * - 接收操作
        - 覆盖 ghost 层
        - 累加到边界节点
      * - 物理含义
        - 拷贝邻居内部值
        - 求和各 rank 的偏沉积
      * - 缓冲区范围
        - ``il-1`` / ``iu+1`` ghost 层
        - ``il`` / ``iu`` 边界节点
      * - 缓冲区大小
        - 含 ghost 的完整面：``il-1:iu+1``
        - 仅内部面：``il:iu``

   .. rubric:: 程序语义

   当某个方向满足 ``domain_split(d)==1`` 且 ``l(d)>tiny(1.0)`` 时，
   也就是“未做 MPI 分裂且该方向是周期边界”，
   例程在本地先做折叠：

   .. code-block:: fortran

      den(il(d),:,:) = den(il(d),:,:) + den(iu(d),:,:)
      den(iu(d),:,:) = den(il(d),:,:)

   第二行把折叠后的结果镜像回上边界，保证两端物理等价。只有本地周期折叠完成后，
   才会对被 MPI 分裂的方向继续做邻居累加交换。

   .. rubric:: 通信顺序

   与 H01 相同，使用 blocking ``MPI_Send`` / ``MPI_Recv``，按当前方向逻辑坐标的奇偶选择顺序以避免死锁：

   - 奇数坐标：先 ``Send`` 后 ``Recv``。
   - 偶数坐标：先 ``Recv`` 后 ``Send``。

   在 x 方向，例程发送 ``den(iu(1),:,:)`` 或 ``den(il(1),:,:)``，
   接收后累加到本地相应边界节点。y、z 方向同理。

   .. rubric:: 调用注意

   - 在本地粒子 scatter 完之后再调用本例程；调用前 ``den`` 必须置零，确保边界累加只反映当前时间步的沉积结果。
   - 累加而非覆盖：用 ``=`` 代替 ``= ... + buf_recv`` 会丢弃一侧贡献，产生错误密度。
   - 缓冲区大小为 ``il:iu``，不包含 ghost 层。
   - include 文件使用 ``MPI_DOUBLE`` 发送 ``real`` 缓冲区；实际构建应保证默认 ``real`` 与 MPI datatype 一致。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/04/24) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``H03_mpi_exchange_den`` handles MPI boundary exchange of the density
   array ``den`` after particle scatter. The array includes one ghost layer
   and spans ``il(d)-1:iu(d)+1``.

   The critical difference from field exchange (H01) is that field exchange
   **overwrites** the ghost layer on receive, while density exchange
   **accumulates** (adds) into boundary nodes — because neighboring-rank
   particles also deposit onto this rank's boundary nodes, so both sides'
   contributions must be summed to recover the physical density.

   .. rubric:: Beginner Mental Model

   The easiest way to read H03 is: after two neighboring ranks scatter
   independently, each rank only owns "its half" of the shared boundary
   contribution. H03 combines those halves into the full boundary value.

   - It is not ghost overwrite.
   - It is not another scatter pass.
   - It is **sum / accumulate**.

   Even though ``den`` also carries one ghost layer for array compatibility,
   H03 communicates and updates the boundary nodes ``il`` / ``iu``, not the
   ``il-1`` / ``iu+1`` ghost contract used by H01.

   .. rubric:: File Roles

   .. list-table::
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`mod_H03_mpi_exchange_den.f90 <H03_mpi_exchange_den/mod_H03_mpi_exchange_den>`
        - Module wrapper including the density exchange routine.
      * - :doc:`sub_H03_mpi_exchange_den.f90 <H03_mpi_exchange_den/sub_H03_mpi_exchange_den>`
        - Applies periodic folding on non-split dimensions and performs boundary-node accumulation exchange in x, y, and z.
      * - ``inc_exchange_in_x/y/z.f90``
        - Pack one directional boundary face, call the send/recv include, and **accumulate** the received data into the local boundary node.
      * - ``inc_send_recv.f90`` / ``inc_recv_send.f90``
        - Two blocking ``MPI_Send`` / ``MPI_Recv`` call orders.

   .. rubric:: Contrast With Field Exchange

   .. list-table::
      :header-rows: 1
      :widths: 28 36 36

      * - Property
        - Field exchange (H01)
        - Density exchange (H03)
      * - Operation on receive
        - Overwrite ghost cell
        - Accumulate into boundary node
      * - Physical meaning
        - Copy neighbor's interior value
        - Sum partial scatter contributions
      * - Buffer region
        - ``il-1`` / ``iu+1`` (ghost cells)
        - ``il`` / ``iu`` (boundary nodes)
      * - Buffer size
        - Full face including ghost: ``il-1:iu+1``
        - Interior face only: ``il:iu``

   .. rubric:: Program Semantics

   When ``domain_split(d)==1`` (no MPI split) and ``l(d)>tiny(1.0)``
   (periodic BC) in a dimension, the routine first folds locally:

   .. code-block:: fortran

      den(il(d),:,:) = den(il(d),:,:) + den(iu(d),:,:)
      den(iu(d),:,:) = den(il(d),:,:)

   The second line mirrors the folded result back to the upper boundary so
   both ends hold the same total value, as required by periodicity. Only after
   this local periodic fold does the routine continue with MPI accumulation in
   directions that are actually split across ranks.

   .. rubric:: Communication Order

   Like H01, the routine uses blocking ``MPI_Send`` / ``MPI_Recv`` with
   odd-even ordering on the rank's logical coordinate to avoid deadlock:

   - Odd coordinate: ``Send`` then ``Recv``.
   - Even coordinate: ``Recv`` then ``Send``.

   In x, the routine sends ``den(iu(1),:,:)`` or ``den(il(1),:,:)`` and
   accumulates received data into the corresponding local boundary node.
   The y and z directions follow the same pattern.

   .. rubric:: Calling Notes

   - Complete local particle scatter before calling, and zero ``den`` before
     that scatter so boundary accumulation reflects only the current time-step's
     contributions.
   - Accumulate, never overwrite: using ``=`` instead of ``= ... + buf_recv``
     discards one side's contributions and produces incorrect density.
   - Buffer size is ``il:iu`` only — no ghost-cell range, unlike H01.
   - The include files send ``real`` buffers with ``MPI_DOUBLE``; builds
     should keep the default ``real`` kind consistent with that MPI datatype.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/04/24) · Harbin Institute of Technology</p>
      </div>
