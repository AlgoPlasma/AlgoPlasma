mod_D05_phi1d_to_phi3d.f90
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_D05_phi1d_to_phi3d`` 是该目录的模块包装器，通过 ``include`` 汇总
   ``sub_D05_phi1d_to_phi3d.f90``，对外暴露 ``sub_D05_phi1d_to_phi3d`` 子程序。

   .. rubric:: 公开入口与 include 关系

   下列文件在 ``mod_D05_phi1d_to_phi3d`` 的 ``contains`` 作用域内 include。
   调用方应 ``use mod_D05_phi1d_to_phi3d`` 后调用公开入口；不要把这些
   include 文件单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_D05_phi1d_to_phi3d.f90``
        - 将 HYPRE 返回的 1D ``phi1d`` 解向量展开到 3D ``phi3d``，并填充周期或 MPI ghost cell。
        - Poisson 求解后需要把线性解向量恢复成带一层 ghost 的 3D 势场。

   .. rubric:: include 结构说明

   ``sub_D05_phi1d_to_phi3d.f90`` 内部还通过 ``#include`` 嵌入三组代码片段：

   - ``inc_exchange_in_x/y/z.f90``：三个 Cartesian 方向的 MPI ghost 交换逻辑，各自再
     ``#include`` ``inc_send_recv.f90`` 或 ``inc_recv_send.f90``。
   - ``inc_send_recv.f90``：先 ``mpi_send`` 后 ``mpi_recv`` 的原语序列（奇逻辑索引 rank）。
   - ``inc_recv_send.f90``：先 ``mpi_recv`` 后 ``mpi_send`` 的原语序列（偶逻辑索引 rank）。

   这些 inc 文件不包含独立子程序签名，只能在 ``sub_D05_phi1d_to_phi3d`` 的作用域内使用。

   .. rubric:: 局部假设

   本页例程使用 cell-centered Cartesian ``(x,y,z)`` 布局；``phi3d`` 包含每侧一层 ghost 格。
   MPI halo 交换采用 Cartesian 进程网格上的逻辑索引（``rank_to_ijk`` 和 ``ijk_to_rank``）
   来定位邻居 rank；奇偶交替的发收顺序用于避免死锁。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 汇总本目录公开入口；调用方 ``use`` 模块后调用
   ``sub_D05_phi1d_to_phi3d``。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_D05_phi1d_to_phi3d`` is the module wrapper for this directory. It groups
   ``sub_D05_phi1d_to_phi3d.f90`` via ``include`` and exposes the
   ``sub_D05_phi1d_to_phi3d`` subroutine to callers.

   .. rubric:: Public Entries and Includes

   The following file is included inside the ``contains`` scope of
   ``mod_D05_phi1d_to_phi3d``. Callers should
   ``use mod_D05_phi1d_to_phi3d`` and call the public entry through the module;
   do not compile the include file separately.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_D05_phi1d_to_phi3d.f90``
        - Unpacks the HYPRE 1D ``phi1d`` vector into 3D ``phi3d`` and fills periodic or MPI ghost cells.
        - Restore a Poisson solution into a 3D potential array with one ghost layer.

   .. rubric:: Include Structure

   Inside ``sub_D05_phi1d_to_phi3d.f90``, three groups of code fragments are
   embedded via ``#include``:

   - ``inc_exchange_in_x/y/z.f90``: MPI ghost-exchange logic for each Cartesian
     direction; each of these in turn uses ``#include`` for ``inc_send_recv.f90`` or
     ``inc_recv_send.f90``.
   - ``inc_send_recv.f90``: ``mpi_send`` then ``mpi_recv`` sequence (odd-index ranks).
   - ``inc_recv_send.f90``: ``mpi_recv`` then ``mpi_send`` sequence (even-index ranks).

   These inc files contain no standalone subroutine signatures and can only be
   used within the scope of ``sub_D05_phi1d_to_phi3d``.

   .. rubric:: Local Assumptions

   These routines use a cell-centered Cartesian ``(x,y,z)`` layout; ``phi3d``
   carries one ghost layer per side. MPI halo exchange uses the logical-index maps
   ``rank_to_ijk`` and ``ijk_to_rank`` on a Cartesian process grid; alternating
   send/receive order prevents deadlock.

   .. rubric:: Implementation Notes

   This module groups public entries via ``include``; callers ``use`` the module
   and call ``sub_D05_phi1d_to_phi3d`` directly.

   .. rubric:: Generated API

   .. doxygenfile:: mod_D05_phi1d_to_phi3d.f90
