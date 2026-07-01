mod_H01_mpi_exchange_field.f90
------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_H01_mpi_exchange_field`` 是该目录的模块包装器，集中 include 或暴露本组公开入口。

   .. rubric:: 公开入口与 include 关系

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - 文件/符号
        - 角色
        - 调用约定
      * - ``sub_H01_mpi_exchange_field.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。

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

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - File/symbol
        - Role
        - Calling convention
      * - ``sub_H01_mpi_exchange_field.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.

   .. rubric:: Local Assumptions

   MPI exchange routines use ``MPI_COMM_WORLD`` and cell-unit positions/indices. Field exchange expects ghost cells in the field array; particle exchange requires the init routine to cache neighbors and buffers first. Periodic directions are determined by ``l(d)>0`` together with ``domain_split``.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_H01_mpi_exchange_field.f90
