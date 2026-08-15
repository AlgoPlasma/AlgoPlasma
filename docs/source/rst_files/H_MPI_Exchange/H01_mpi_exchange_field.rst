H01_mpi_exchange_field
======================

.. toctree::
    :maxdepth: 1
    :hidden:

    H01_mpi_exchange_field/mod_H01_mpi_exchange_field
    H01_mpi_exchange_field/sub_H01_mpi_exchange_field

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``H01_mpi_exchange_field`` 负责标量场的一层 ghost/halo 交换。数组 ``f`` 含有一层 ghost cell，
   范围为 ``il(d)-1:iu(d)+1``。当某个方向被 MPI 分裂时，例程与该方向的相邻 rank 交换数据；
   当某个方向未分裂但 ``l(d)>0`` 时，它在本 rank 内直接填充周期 ghost。

   .. rubric:: 初学者先抓住什么

   可以把 H01 当成“给 stencil 准备邻居值”的小模块：

   - 它不更新 Maxwell 方程，也不决定物理边界条件。
   - 它只做一件事：把邻居 rank 里约定好的有效内部层，复制到我这一侧的 ghost 层。
   - 因此，H01 的核心语义是 **copy / overwrite**，不是求和，也不是粒子所有权迁移。

   .. rubric:: 文件角色

   .. list-table::
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 角色
      * - :doc:`mod_H01_mpi_exchange_field.f90 <H01_mpi_exchange_field/mod_H01_mpi_exchange_field>`
        - 模块包装器，include 场交换主例程。
      * - :doc:`sub_H01_mpi_exchange_field.f90 <H01_mpi_exchange_field/sub_H01_mpi_exchange_field>`
        - 执行 x/y/z 三方向的 ghost 层交换，并在未分裂方向处理周期边界。
      * - ``inc_exchange_in_x/y/z.f90``
        - 针对单个方向打包边界面、调用 send/recv include，并写回 ghost 层。
      * - ``inc_send_recv.f90`` / ``inc_recv_send.f90``
        - blocking ``MPI_Send`` / ``MPI_Recv`` 的两种调用顺序。

   .. rubric:: 内部 include 说明

   ``inc_exchange_in_x/y/z.f90``、``inc_send_recv.f90`` 和 ``inc_recv_send.f90``
   是被主例程 include 的内部 helper。它们不作为公开接口使用，也不单独建立 RST/API 页面；
   公开阅读入口保留在模块页和 ``sub_H01_mpi_exchange_field`` 页面。

   .. rubric:: 程序语义

   对一个方向而言：

   - ``il-1`` 和 ``iu+1`` 是接收后写入的 ghost 层。
   - ``il+1`` 和 ``iu-1`` 是当前程序约定下发送给邻居的有效内部层。
   - 也就是说，H01 发送的不是 ``il`` / ``iu``，而是更靠内一层的 ``il+1`` / ``iu-1``。

   这不是可随意替换的实现细节，而是当前 H01 与测试、调用端共享的索引契约。
   如果调用方把“该发哪一层、该收进哪一层”理解错，结果通常不是死锁，而是 ghost 值看起来有数据、但读到的是错层。

   .. figure:: ../../images/H_MPI_Exchange/mpi_exchange_field.jpg
      :align: center
      :width: 50%
      :name: H01_mpi_exchange_field_zh

      场量 ghost 层交换示意图。

   .. rubric:: 通信顺序

   H01 使用 blocking ``MPI_Send`` / ``MPI_Recv``。为避免相邻 rank 同时阻塞在发送上，代码按当前方向的逻辑坐标奇偶选择顺序：

   - 奇数坐标：先 ``Send`` 后 ``Recv``。
   - 偶数坐标：先 ``Recv`` 后 ``Send``。

   这个顺序只影响 MPI 调用顺序，不改变数据含义。x 方向发送 ``f(iu(1)-1,:,:)`` 或 ``f(il(1)+1,:,:)``，
   接收后写入 ``f(iu(1)+1,:,:)`` 或 ``f(il(1)-1,:,:)``；y、z 方向同理。

   .. rubric:: 调用注意

   - H01 只负责邻居拷贝；非周期物理边界怎样填充，仍由调用方决定。
   - 当某个方向 ``domain_split(d)==1`` 且 ``l(d)>0`` 时，例程直接在本 rank 内做周期 ghost 填充。
   - include 文件使用 ``MPI_DOUBLE`` 发送 ``real`` 缓冲区；实际构建应保证默认 ``real`` 与 MPI datatype 一致。
   - 如果你的上层算法要读的是邻居“边界节点”而不是 H01 约定的有效内部层，那么它需要的可能不是这个例程，而是不同的 exchange 语义。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵隐剑 (2025/12/04) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``H01_mpi_exchange_field`` handles one-layer ghost/halo exchange for a
   scalar field. The array ``f`` includes one ghost layer and spans
   ``il(d)-1:iu(d)+1``. If a direction is MPI-split, the routine exchanges
   data with neighbor ranks in that direction. If a direction is not split and
   ``l(d)>0``, it fills periodic ghosts locally on the same rank.

   .. rubric:: Beginner Mental Model

   Read H01 as a small "prepare neighbor values for a stencil" module:

   - It does not update Maxwell equations.
   - It does not decide physical boundary conditions.
   - It only copies the agreed effective interior layer from a neighbor into
     the local ghost layer.

   So the key semantic is **copy / overwrite**, not accumulation and not
   particle migration.

   .. rubric:: File Roles

   .. list-table::
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`mod_H01_mpi_exchange_field.f90 <H01_mpi_exchange_field/mod_H01_mpi_exchange_field>`
        - Module wrapper including the field exchange routine.
      * - :doc:`sub_H01_mpi_exchange_field.f90 <H01_mpi_exchange_field/sub_H01_mpi_exchange_field>`
        - Exchange ghost layers in x/y/z and handle periodic directions that are not MPI-split.
      * - ``inc_exchange_in_x/y/z.f90``
        - Pack one directional boundary plane, call the send/recv include, and write the ghost layer.
      * - ``inc_send_recv.f90`` / ``inc_recv_send.f90``
        - Two blocking ``MPI_Send`` / ``MPI_Recv`` call orders.

   .. rubric:: Internal Include Helpers

   ``inc_exchange_in_x/y/z.f90``, ``inc_send_recv.f90``, and
   ``inc_recv_send.f90`` are internal helpers included by the main routine.
   They are not public standalone interfaces and intentionally do not have
   separate RST/API pages; the public reading entry points remain the module
   page and the ``sub_H01_mpi_exchange_field`` page.

   .. rubric:: Program Semantics

   In one direction:

   - ``il-1`` and ``iu+1`` are the ghost layers written on receive.
   - ``il+1`` and ``iu-1`` are the effective interior layers sent to
     neighbors in the current program contract.
   - In other words, H01 does not send ``il`` / ``iu``. It sends the inner
     ``il+1`` / ``iu-1`` layers.

   This is not an interchangeable implementation detail. It is the indexing
   contract shared by H01, the tests, and current callers. If a caller assumes
   the wrong send/receive layers, ghost cells may still be populated but with
   the wrong data.

   .. figure:: ../../images/H_MPI_Exchange/mpi_exchange_field.jpg
      :align: center
      :width: 50%
      :name: H01_mpi_exchange_field_en

      Schematic diagram of scalar-field ghost exchange.

   .. rubric:: Communication Order

   H01 uses blocking ``MPI_Send`` / ``MPI_Recv``. To avoid neighboring ranks
   blocking on sends at the same time, the code chooses the order from the odd
   or even logical coordinate in the current direction:

   - Odd coordinate: ``Send`` then ``Recv``.
   - Even coordinate: ``Recv`` then ``Send``.

   This order changes only MPI progress, not the meaning of the data. In x, the
   routine sends ``f(iu(1)-1,:,:)`` or ``f(il(1)+1,:,:)`` and writes received
   data to ``f(iu(1)+1,:,:)`` or ``f(il(1)-1,:,:)``. The y and z directions
   follow the same pattern.

   .. rubric:: Calling Notes

   - H01 only performs neighbor copies; non-periodic physical boundary filling is still the caller's job.
   - If ``domain_split(d)==1`` and ``l(d)>0`` in a direction, the routine fills periodic ghosts locally on the same rank.
   - The include files send ``real`` buffers with ``MPI_DOUBLE``; builds should keep the default ``real`` kind consistent with that MPI datatype.
   - If your algorithm needs neighbor boundary-node accumulation instead of ghost overwrite, the intended routine is not H01 but H03 or a different exchange contract.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO (2025/12/04) · Harbin Institute of Technology</p>
      </div>
