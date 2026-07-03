mod_H01_mpi_exchange_field.f90
------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_H01_mpi_exchange_field`` 汇总标量场 MPI halo/ghost-cell 交换入口。

   .. rubric:: 公开入口与 include 关系

   下列文件在 ``mod_H01_mpi_exchange_field`` 的 ``contains`` 作用域内 include。
   调用方应 ``use mod_H01_mpi_exchange_field`` 后调用具体例程；不要把这些
   include 文件单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_H01_mpi_exchange_field.f90``
        - 在 3D Cartesian 区域分解中交换标量场的一层 ghost-cell 值。
        - 电势、电场或其它 cell-centered 标量场需要同步邻居边界。

   .. rubric:: 局部假设

   MPI 交换例程使用 ``MPI_COMM_WORLD``，索引和粒子位置采用 cell units。场交换要求数组含 ghost cell；粒子交换要求先调用初始化例程建立邻居和缓冲区缓存。周期方向由 ``l(d)>0`` 和 ``domain_split`` 共同决定。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_H01_mpi_exchange_field`` module wrapper for scalar-field MPI halo exchange.

   .. rubric:: Public Entries And Includes

   The following file is included inside the ``contains`` scope of
   ``mod_H01_mpi_exchange_field``. Callers should
   ``use mod_H01_mpi_exchange_field`` and call the concrete routine through the
   module; do not compile the include file separately.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_H01_mpi_exchange_field.f90``
        - Exchanges one layer of scalar-field ghost cells in a 3D Cartesian domain decomposition.
        - Synchronize potential, electric field, or other cell-centered scalar boundaries.

   .. rubric:: Local Assumptions

   MPI exchange routines use ``MPI_COMM_WORLD`` and cell-unit positions/indices. Field exchange expects ghost cells in the field array; particle exchange requires the init routine to cache neighbors and buffers first. Periodic directions are determined by ``l(d)>0`` together with ``domain_split``.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_H01_mpi_exchange_field.f90
