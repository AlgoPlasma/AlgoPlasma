sub_H01_mpi_exchange_field.f90
------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_H01_mpi_exchange_field`` 对带一层 ghost cell 的标量场做 MPI halo 交换，
   其具体语义是：发送 ``il+1`` / ``iu-1`` 的有效内部层，接收后覆盖 ``il-1`` / ``iu+1`` ghost 层。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``il``
        - in
        - ``(1:3)``
        - 本地 active cell 下界索引。
      * - ``iu``
        - in
        - ``(1:3)``
        - 本地 active cell 上界索引。
      * - ``f``
        - in/out
        - field array on caller index range
        - 场数组，范围应为 ``il(1)-1:iu(1)+1``、``il(2)-1:iu(2)+1``、``il(3)-1:iu(3)+1``，并含一层 ghost。
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
        - ``(0:domain_split(1)+1,0:domain_split(2)+1,0:domain_split(3)+1)``
        - 三维逻辑坐标到 rank 的映射表；无邻居位置为 ``-1``。
      * - ``l``
        - in
        - ``(1:3)``
        - 周期长度；大于 0 表示该方向可周期包裹。

   .. rubric:: 局部假设

   - 例程直接使用 ``MPI_COMM_WORLD``。
   - 数组 ``f`` 必须已经按 H01 约定分配好一层 ghost。
   - ``rank_to_ijk`` / ``ijk_to_rank`` 必须在所有 rank 上自洽。
   - ``domain_split(d)==1 .and. l(d)>0`` 表示该方向采用本地周期 ghost 填充，而不是 MPI 交换。

   .. rubric:: 实现逻辑

   场交换按 x/y/z 方向依次进行。每个方向都先判断是否真的有 MPI 邻居；若有，则按逻辑坐标奇偶选择
   blocking send/recv 顺序，发送有效内部层并把收到的数据写入 ghost 层。

   .. rubric:: 调用注意

   本例程不负责非周期物理边界条件；调用方应在交换前后补齐自己的边界处理。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_H01_mpi_exchange_field`` exchanges ghost-cell values of a scalar
   field among MPI neighbor ranks. Concretely, it sends the effective interior
   layers ``il+1`` / ``iu-1`` and overwrites the ghost layers
   ``il-1`` / ``iu+1`` on receive.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``il``
        - in
        - ``(1:3)``
        - integer(1:3), lower cell-center indices in x,y,z of the local subdomain (excluding
          ghost cells).
      * - ``iu``
        - in
        - ``(1:3)``
        - integer(1:3), upper cell-center indices in x,y,z of the local subdomain (excluding
          ghost cells).
      * - ``f``
        - in/out
        - field array on caller index range
        - real,dimension(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1, il(3)-1:iu(3)+1), scalar field
          values on cell centers including one ghost layer in each direction.
      * - ``mpi_n``
        - in
        - scalar or caller-provided array
        - integer, total number of MPI ranks in ``MPI_COMM_WORLD``.
      * - ``rank_to_ijk``
        - in
        - ``(1:3,0:mpi_n-1)``
        - integer(1:3,0:mpi_n-1), mapping from MPI rank to 3D logical index triplet
          ``(i,j,k)``.
      * - ``domain_split``
        - in
        - ``(1:3)``
        - integer(1:3), number of MPI subdomains in each of the three directions.
      * - ``ijk_to_rank``
        - in
        - ``(0:domain_split(1)``
        - integer(0:domain_split(1)+1,0:domain_split(2)+1, 0:domain_split(3)+1), mapping from
          logical indices ``(i,j,k)`` to MPI rank, with ``-1`` for non-existing neighbors and
          halo layers.
      * - ``l``
        - in
        - ``(1:3)``
        - real(1:3), physical length of the domain in each direction; used to decide whether
          periodic boundary conditions should be enforced when ``domain_split(d)==1``.

   .. rubric:: Local Assumptions

   - The routine uses ``MPI_COMM_WORLD`` directly.
   - ``f`` must already be allocated with one ghost layer in the H01 layout.
   - ``rank_to_ijk`` / ``ijk_to_rank`` must be consistent on all ranks.
   - ``domain_split(d)==1 .and. l(d)>0`` means local periodic ghost filling in
     that direction, not MPI exchange.

   .. rubric:: Implementation Notes

   The routine advances through x, y, and z in order. In each direction, it
   first checks whether a real MPI neighbor exists. If so, it uses odd-even
   ordered blocking send/recv, sends the effective interior layer, and writes
   the received data into ghost cells.

   .. rubric:: Generated API

   .. doxygenfile:: sub_H01_mpi_exchange_field.f90
