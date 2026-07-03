mod_H02_mpi_exchange_par.f90
----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_H02_mpi_exchange_par`` 汇总粒子跨 MPI 子域交换入口，并维护邻居、
   tag 和缓冲区缓存。

   .. rubric:: 公开入口与 include 关系

   下列源码在 ``mod_H02_mpi_exchange_par`` 的 ``contains`` 作用域内 include 或定义。
   调用方应 ``use mod_H02_mpi_exchange_par`` 后调用具体例程；不要把这些
   include 文件单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件/符号
        - 功能
        - 适用场景
      * - ``sub_H02_mpi_exchange_par_init.f90``
        - 初始化邻居列表、方向映射、MPI tags 和固定大小收发缓冲区。
        - 粒子交换前调用一次；当 ``npm`` 或分解信息变化时重新初始化。
      * - ``sub_H02_mpi_exchange_par.f90``
        - 打包离开本地子域的粒子，先交换计数再交换 payload，并追加接收粒子。
        - 每个时间步或粒子推进后执行跨子域迁移。
      * - ``DIR_ID``
        - 模块内部 helper
        - 将 ``(-1:1,-1:1,-1:1)`` 方向三元组映射为稳定整数编号，用于 tag 生成。

   .. rubric:: 局部假设

   MPI 交换例程使用 ``MPI_COMM_WORLD``，索引和粒子位置采用 cell units。场交换要求数组含 ghost cell；粒子交换要求先调用初始化例程建立邻居和缓冲区缓存。周期方向由 ``l(d)>0`` 和 ``domain_split`` 共同决定。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_H02_mpi_exchange_par`` module for fast MPI particle exchange with cached neighbor metadata.

   .. rubric:: Public Entries And Includes

   The following sources are included or defined inside the ``contains`` scope
   of ``mod_H02_mpi_exchange_par``. Callers should
   ``use mod_H02_mpi_exchange_par`` and call concrete routines through the
   module; do not compile the include files separately.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File/symbol
        - Function
        - Typical use
      * - ``sub_H02_mpi_exchange_par_init.f90``
        - Initializes neighbor lists, direction maps, MPI tags, and fixed send/receive buffers.
        - Call once before particle exchange, or again when ``npm`` or decomposition metadata changes.
      * - ``sub_H02_mpi_exchange_par.f90``
        - Packs particles leaving the local subdomain, exchanges counts then payloads, and appends received particles.
        - Run after pushing particles whenever particles may cross MPI subdomain boundaries.
      * - ``DIR_ID``
        - module-local helper
        - Maps ``(-1:1,-1:1,-1:1)`` direction triplets to stable integer ids for tag generation.

   .. rubric:: Local Assumptions

   MPI exchange routines use ``MPI_COMM_WORLD`` and cell-unit positions/indices. Field exchange expects ghost cells in the field array; particle exchange requires the init routine to cache neighbors and buffers first. Periodic directions are determined by ``l(d)>0`` together with ``domain_split``.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   Module-level cached variables are documented by the source file. The callable APIs are rendered on the dedicated ``sub_H02_mpi_exchange_par_init`` and ``sub_H02_mpi_exchange_par`` pages to avoid duplicate declarations and parser warnings on this module overview.
