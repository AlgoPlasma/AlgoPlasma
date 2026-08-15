sub_D05_phi1d_to_phi3d.f90
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_D05_phi1d_to_phi3d`` 将 HYPRE Poisson 求解器返回的 1D 解向量解包为包含
   ghost 格的 3D 势函数数组，并通过 MPI 点对点通信或周期环绕填充 ghost 层。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 20 10 28 42

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``il``
        - in
        - ``(1:3)``
        - 本地子域 cell-center 下界索引，对应 x、y、z 三个方向。
      * - ``iu``
        - in
        - ``(1:3)``
        - 本地子域 cell-center 上界索引；``nx=iu(1)-il(1)+1``，以此类推。
      * - ``phi1d``
        - in
        - ``(1:nx*ny*nz)``
        - HYPRE 返回的 1D 解向量，存储顺序为 i 最快、k 最慢。
      * - ``phi3d``
        - in/out
        - ``(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
        - 3D 势函数数组，每侧含一层 ghost 格；物理域格从 ``phi1d`` 写入，ghost 格由周期
          环绕或 MPI 通信填充。
      * - ``mpi_n``
        - in
        - scalar
        - MPI 总进程数。
      * - ``rank_to_ijk``
        - in
        - ``(1:3, 0:mpi_n-1)``
        - MPI rank → 三维逻辑索引 ``(i,j,k)`` 的映射表。
      * - ``domain_split``
        - in
        - ``(1:3)``
        - 各方向 MPI 子域数；等于 1 且域长度大于零时触发周期 ghost 填充。
      * - ``ijk_to_rank``
        - in
        - ``(0:domain_split(1)+1, 0:domain_split(2)+1, 0:domain_split(3)+1)``
        - 逻辑索引 → MPI rank 的映射表；``-1`` 表示该方向无邻居。
      * - ``l``
        - in
        - ``(1:3)``
        - 各方向物理域长度；``l(d)>0`` 且 ``domain_split(d)==1`` 时执行周期环绕填充。

   .. rubric:: 局部假设

   本页例程使用 cell-centered Cartesian ``(x,y,z)`` 布局；``phi3d`` 包含每侧一层 ghost 格。
   MPI halo 交换通过 ``rank_to_ijk`` 与 ``ijk_to_rank`` 定位邻居；奇偶逻辑索引的发收顺序
   交替以避免 Cartesian 进程网格上的死锁。

   .. rubric:: 实现逻辑

   子程序先将 ``phi3d`` 清零，再按 k-j-i 循环从 ``phi1d`` 顺序写入物理域格。
   随后对 ``domain_split(d)==1`` 且 ``l(d)>tiny`` 的方向做周期 ghost 填充。
   最后对每个 ``domain_split(d)>1`` 的方向 ``#include`` 对应的
   ``inc_exchange_in_x/y/z.f90`` 片段执行 MPI 通信。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_D05_phi1d_to_phi3d`` unpacks the 1D solution vector returned by the
   HYPRE Poisson solver into a 3D ghost-cell potential array, then fills ghost
   cells via MPI point-to-point communication or periodic wrap-around.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 20 10 28 42

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``il``
        - in
        - ``(1:3)``
        - integer(1:3), lower cell-center indices of the local subdomain in x, y, z.
      * - ``iu``
        - in
        - ``(1:3)``
        - integer(1:3), upper cell-center indices; ``nx=iu(1)-il(1)+1``, and so on.
      * - ``phi1d``
        - in
        - ``(1:nx*ny*nz)``
        - real(:), 1D solution from HYPRE with loop order i fastest, k slowest.
      * - ``phi3d``
        - in/out
        - ``(il(1)-1:iu(1)+1, il(2)-1:iu(2)+1, il(3)-1:iu(3)+1)``
        - real(:,:,:), 3D potential array with one ghost layer per side; physical
          cells are written from ``phi1d`` and ghost cells are filled by periodic
          wrap-around or MPI exchange.
      * - ``mpi_n``
        - in
        - scalar
        - integer, total number of MPI ranks.
      * - ``rank_to_ijk``
        - in
        - ``(1:3, 0:mpi_n-1)``
        - integer(1:3,0:mpi_n-1), mapping from MPI rank to 3D logical index ``(i,j,k)``.
      * - ``domain_split``
        - in
        - ``(1:3)``
        - integer(1:3), number of MPI subdomains per direction; direction ``d`` with
          value 1 and ``l(d)>0`` triggers periodic ghost fill instead of MPI exchange.
      * - ``ijk_to_rank``
        - in
        - ``(0:domain_split(1)+1, 0:domain_split(2)+1, 0:domain_split(3)+1)``
        - integer(:,:,:), mapping from logical indices to MPI rank; ``-1`` denotes a
          non-existing neighbour (physical boundary).
      * - ``l``
        - in
        - ``(1:3)``
        - real(1:3), physical domain length per direction; ``l(d)>0`` with
          ``domain_split(d)==1`` activates periodic ghost fill.

   .. rubric:: Local Assumptions

   These routines use a cell-centered Cartesian ``(x,y,z)`` layout; ``phi3d``
   carries one ghost layer per side. MPI halo exchange uses ``rank_to_ijk`` and
   ``ijk_to_rank`` to locate neighbours on the Cartesian process grid; alternating
   send/receive order (odd/even logical index) prevents deadlock.

   .. rubric:: Implementation Notes

   The subroutine first zeroes ``phi3d``, then writes the physical domain in a
   k-j-i loop from ``phi1d``. It then applies periodic ghost fill for directions
   where ``domain_split(d)==1`` and ``l(d)>tiny``. Finally, for each direction
   with ``domain_split(d)>1``, the corresponding ``inc_exchange_in_x/y/z.f90``
   fragment is included with ``#include`` to perform MPI communication.

   .. rubric:: Generated API

   .. doxygenfile:: sub_D05_phi1d_to_phi3d.f90
