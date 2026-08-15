D05_phi1d_to_phi3d
==================

.. toctree::
    :maxdepth: 1
    :hidden:

    D05_phi1d_to_phi3d/mod_D05_phi1d_to_phi3d
    D05_phi1d_to_phi3d/sub_D05_phi1d_to_phi3d

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``D05_phi1d_to_phi3d`` 是 Poisson 求解与电场计算之间的衔接步骤。
   HYPRE 返回的 1D 解向量 ``phi1d`` 按照 i 最快、k 最慢的存储顺序逐元素写入
   3D ghost-cell 数组 ``phi3d``，随后通过 MPI 点对点通信填充相邻 rank 的 ghost 层；
   对单 rank 方向且域长度大于零的情形，则直接做周期环绕填充。
   调用完成后，物理边界上的非周期、非 MPI ghost 格保持为零，
   调用方需在此之后（且在调用 D06 之前）按实际边界条件另行赋值。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 角色
      * - :doc:`mod_D05_phi1d_to_phi3d.f90 <D05_phi1d_to_phi3d/mod_D05_phi1d_to_phi3d>`
        - 模块包装文件，集中 include D05 子程序。
      * - :doc:`sub_D05_phi1d_to_phi3d.f90 <D05_phi1d_to_phi3d/sub_D05_phi1d_to_phi3d>`
        - 主子程序：1D→3D 解包 + 周期 BC + MPI halo 交换。
      * - ``inc_exchange_in_x/y/z.f90``
        - 在主子程序内 include 的代码片段，分别实现三个 Cartesian 方向的 MPI ghost 交换；依赖
          ``inc_send_recv.f90`` 与 ``inc_recv_send.f90``。
      * - ``inc_send_recv.f90``
        - 先发后收的 MPI 点对点模式（奇逻辑索引 rank 使用）。
      * - ``inc_recv_send.f90``
        - 先收后发的 MPI 点对点模式（偶逻辑索引 rank 使用）。

   .. rubric:: ghost cell 约定

   D05 交换的是 **边界格本身**：每个 rank 把自身 ``iu(d)`` 方向末端格发给右邻 rank 的
   ghost 格，把 ``il(d)`` 方向首端格发给左邻 rank 的 ghost 格。
   这与 H01 电场交换（使用次边界格）的约定不同，调用方需注意区分。

   .. rubric:: 调用顺序建议

   1. 调用 D01–D04 中的 HYPRE 求解器，得到 ``phi1d``。
   2. 调用 ``sub_D05_phi1d_to_phi3d`` 解包并交换 ghost。
   3. 对物理边界的非周期 ghost 格按 Dirichlet/Neumann 等条件赋值。
   4. 调用 ``sub_D06_phi_to_E`` 计算电场。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">彭子龙 (2026/06/05) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``D05_phi1d_to_phi3d`` bridges the HYPRE Poisson solve and the electric-field
   computation. The 1D solution vector ``phi1d`` (loop order: i fastest, k slowest)
   is unpacked element by element into the physical domain of the 3D ghost-cell
   array ``phi3d``. Ghost cells are then filled either by periodic wrap-around
   (when the MPI split in that direction is 1 and the domain length is positive)
   or by point-to-point MPI communication with neighbouring ranks.
   After the call, non-periodic, non-MPI ghost cells at physical boundaries remain
   zero; the caller must set them according to the actual boundary conditions before
   calling D06.

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`mod_D05_phi1d_to_phi3d.f90 <D05_phi1d_to_phi3d/mod_D05_phi1d_to_phi3d>`
        - Module wrapper collecting the D05 subroutine.
      * - :doc:`sub_D05_phi1d_to_phi3d.f90 <D05_phi1d_to_phi3d/sub_D05_phi1d_to_phi3d>`
        - Main subroutine: 1D→3D unpack, periodic BC fill, and MPI halo exchange.
      * - ``inc_exchange_in_x/y/z.f90``
        - Code fragments included inside the main subroutine implementing MPI ghost
          exchange in each Cartesian direction; depend on ``inc_send_recv.f90`` and
          ``inc_recv_send.f90``.
      * - ``inc_send_recv.f90``
        - Send-then-receive MPI point-to-point pattern used by odd-index ranks.
      * - ``inc_recv_send.f90``
        - Receive-then-send MPI point-to-point pattern used by even-index ranks.

   .. rubric:: Ghost Cell Convention

   D05 exchanges **boundary cells**: each rank sends its ``iu(d)``-end cell to the
   right neighbour's ghost slot, and its ``il(d)``-end cell to the left neighbour's
   ghost slot. This differs from the H01 electric-field exchange, which uses the
   second-from-boundary cell; callers must not confuse the two conventions.

   .. rubric:: Recommended Call Order

   1. Run the HYPRE solver from D01–D04 to obtain ``phi1d``.
   2. Call ``sub_D05_phi1d_to_phi3d`` to unpack and exchange ghost cells.
   3. Set non-periodic physical-boundary ghost cells (Dirichlet, Neumann, etc.).
   4. Call ``sub_D06_phi_to_E`` to compute the electric field.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zilong PENG (2026/06/05) · Harbin Institute of Technology</p>
      </div>
