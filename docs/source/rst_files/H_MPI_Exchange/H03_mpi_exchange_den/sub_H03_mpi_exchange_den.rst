sub_H03_mpi_exchange_den.f90
------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_H03_mpi_exchange_den`` 在粒子沉积之后对密度数组进行 MPI 边界交换。
   对未进行 MPI 分裂且启用周期边界的方向先做本地折叠，
   再通过 include 的方向性 exchange helper 把相邻 rank 的边界节点贡献 **累加** 到本地。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 28 44

      * - 参数
        - 方向
        - shape / 范围
        - 含义与局部约定
      * - ``il``
        - in
        - ``integer(1:3)``
        - 本地有效 cell 下界索引（不含 ghost 层）。
      * - ``iu``
        - in
        - ``integer(1:3)``
        - 本地有效 cell 上界索引（不含 ghost 层）。
      * - ``den``
        - in/out
        - ``real(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
        - 沉积密度数组，含一层 ghost cell；交换后边界节点持有两侧 rank 贡献之和。
      * - ``mpi_n``
        - in
        - ``integer scalar``
        - MPI rank 总数。
      * - ``rank_to_ijk``
        - in
        - ``integer(1:3, 0:mpi_n-1)``
        - rank 到三维子域逻辑坐标的映射。
      * - ``domain_split``
        - in
        - ``integer(1:3)``
        - x/y/z 三方向的 MPI 分裂数目。
      * - ``ijk_to_rank``
        - in
        - ``integer(0:domain_split(1)+1, 0:domain_split(2)+1, 0:domain_split(3)+1)``
        - 三维逻辑坐标到 rank 的映射，含 halo 条目。
      * - ``l``
        - in
        - ``real(1:3)``
        - 各方向全域长度；``l(d) > tiny(1.0)`` 表示该方向为周期边界。

   .. rubric:: 局部假设

   - 调用前必须对 ``den`` 置零，以确保累加结果只反映当前时间步的贡献。
   - **接收后采用累加方式**。计算为 ``den = den + buf_recv``，而非覆盖；这是与 H01 场交换的本质区别。
   - 内部使用 ``MPI_DOUBLE`` 通信，默认 ``real`` 应与之一致（构建时使用 ``-fdefault-real-8``）。

   .. rubric:: 实现逻辑

   - 第一步：对每个满足 ``domain_split(d)==1 .and. l(d)>tiny(1.0)`` 的方向，
     做本地周期折叠：``den(il,:,:) += den(iu,:,:)``，再镜像回上边界。
   - 第二步：依次 ``#include`` x/y/z 方向的 exchange helper，
     将本地边界节点发送给邻居，并把收到的贡献累加到本地。

   .. rubric:: 调用注意

   - 先完成本地粒子沉积，再调用本例程；例程返回后 ``den`` 才包含全部 rank 的贡献。
   - 缓冲区只覆盖内部面 ``il:iu``，不含 ghost 层（与 H01 不同）。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_H03_mpi_exchange_den`` exchanges the density array ``den`` between
   MPI neighbors after particle scatter. For directions that are not split
   across ranks and have periodic boundary conditions, it folds endpoint
   contributions locally. It then includes directional exchange helpers that
   **accumulate** neighboring-rank boundary-node contributions into the local
   array.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 28 44

      * - Parameter
        - Direction
        - Shape / range
        - Meaning and local convention
      * - ``il``
        - in
        - ``integer(1:3)``
        - Local active-cell lower bound indices (ghost cells excluded).
      * - ``iu``
        - in
        - ``integer(1:3)``
        - Local active-cell upper bound indices (ghost cells excluded).
      * - ``den``
        - in/out
        - ``real(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
        - Density array including one ghost layer; after exchange the boundary nodes hold the sum of contributions from both sides.
      * - ``mpi_n``
        - in
        - ``integer scalar``
        - Total number of MPI ranks.
      * - ``rank_to_ijk``
        - in
        - ``integer(1:3, 0:mpi_n-1)``
        - Mapping from MPI rank to 3D logical subdomain index.
      * - ``domain_split``
        - in
        - ``integer(1:3)``
        - Number of MPI partitions in each spatial direction.
      * - ``ijk_to_rank``
        - in
        - ``integer(0:domain_split(1)+1, 0:domain_split(2)+1, 0:domain_split(3)+1)``
        - Mapping from 3D logical index to MPI rank, including halo entries.
      * - ``l``
        - in
        - ``real(1:3)``
        - Domain length in each direction; ``l(d) > tiny(1.0)`` indicates periodic BC in dimension ``d``.

   .. rubric:: Local Assumptions

   - ``den`` must be zeroed before the call so that the accumulated result reflects only the current time step.
   - Received data is **accumulated** (``den = den + buf_recv``), not overwritten — the essential difference from H01 field exchange.
   - The include helpers use ``MPI_DOUBLE``; the build must keep the default ``real`` kind consistent (typically ``-fdefault-real-8``).

   .. rubric:: Implementation Notes

   - Step 1: for each direction where ``domain_split(d)==1 .and. l(d)>tiny(1.0)``,
     fold locally: ``den(il,:,:) += den(iu,:,:)``, then mirror back to the upper boundary.
   - Step 2: ``#include`` the x, y, and z exchange helpers in turn, which pack the
     local boundary face, communicate with neighbors, and accumulate received data.

   .. rubric:: Calling Notes

   - Complete local particle scatter before calling; ``den`` only contains full contributions after this routine returns.
   - Buffers cover the interior face ``il:iu`` only — no ghost-cell range, unlike H01.

   .. rubric:: Generated API

   .. doxygenfile:: sub_H03_mpi_exchange_den.f90
