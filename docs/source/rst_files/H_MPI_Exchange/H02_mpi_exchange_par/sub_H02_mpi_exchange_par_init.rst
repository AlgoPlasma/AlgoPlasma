sub_H02_mpi_exchange_par_init.f90
---------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_H02_mpi_exchange_par_init`` 初始化 H02 粒子交换所需的邻居、方向、tag 和缓冲区缓存。
   这是一次性 setup 入口；真正逐时间步调用的热路径是 ``sub_H02_mpi_exchange_par``。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``ns``
        - in
        - scalar or caller-provided array
        - 粒子种类数。
      * - ``npm``
        - in
        - scalar or caller-provided array
        - 初始化时每个邻居/种类缓冲容量。
      * - ``mpi_n``
        - in
        - scalar or caller-provided array
        - ``MPI_COMM_WORLD`` 中的 rank 总数。
      * - ``rank_to_ijk``
        - in
        - ``(1:3,0:mpi_n-1)``
        - rank 到三维逻辑坐标的映射表。
      * - ``domain_split``
        - in
        - ``(1:3)``
        - x/y/z 三方向的 MPI 切分数量。
      * - ``ijk_to_rank``
        - in
        - ``(0:ds(1)+1,0:ds(2)+1,0:ds(3)+1)``
        - 三维逻辑坐标到 rank 的映射表；无邻居位置为 ``-1``。

   .. rubric:: 局部假设

   - 例程直接使用 ``MPI_COMM_WORLD``。
   - ``rank_to_ijk`` / ``ijk_to_rank`` 必须描述同一个逻辑拓扑。
   - ``npm`` 必须在所有 rank 上一致，因为缓存区容量是按这个值统一分配的。

   .. rubric:: 实现逻辑

   初始化例程只遍历当前 rank 真正存在的 face/edge/corner 邻居，建立方向映射、对向 tag 和固定容量缓冲区；
   这些缓存由后续每一步的粒子交换重复复用。

   .. rubric:: 调用注意

   只要 ``ns`` 或 ``npm`` 改变，就必须重新调用本例程。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_H02_mpi_exchange_par_init`` initializes the cached neighbor lists,
   direction maps, MPI tags, and buffers for particle exchange. This is the
   one-time setup entry; the per-step hot path is ``sub_H02_mpi_exchange_par``.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``ns``
        - in
        - scalar or caller-provided array
        - integer, number of species.
      * - ``npm``
        - in
        - scalar or caller-provided array
        - integer, maximum number of particles per neighbor buffer.
      * - ``mpi_n``
        - in
        - scalar or caller-provided array
        - integer, MPI size.
      * - ``rank_to_ijk``
        - in
        - ``(1:3,0:mpi_n-1)``
        - integer (1:3,0:mpi_n-1), map rank -> MPI indices.
      * - ``domain_split``
        - in
        - ``(1:3)``
        - integer (1:3), MPI splits in x,y,z.
      * - ``ijk_to_rank``
        - in
        - ``(0:ds(1)+1,0:ds(2)+1,0:ds(3)+1)``
        - integer (0:ds(1)+1,0:ds(2)+1,0:ds(3)+1), map MPI indices -> rank; -1 means no rank.

   .. rubric:: Local Assumptions

   - The routine uses ``MPI_COMM_WORLD`` directly.
   - ``rank_to_ijk`` / ``ijk_to_rank`` must describe one consistent logical topology.
   - ``npm`` must be identical on all ranks because buffer capacity is allocated from that shared contract.

   .. rubric:: Implementation Notes

   The init routine only records the face/edge/corner neighbors that actually
   exist for the current rank, then builds direction maps, opposite-direction
   tags, and fixed-capacity buffers reused by later exchange calls.

   .. rubric:: Generated API

   .. doxygenfile:: sub_H02_mpi_exchange_par_init.f90
