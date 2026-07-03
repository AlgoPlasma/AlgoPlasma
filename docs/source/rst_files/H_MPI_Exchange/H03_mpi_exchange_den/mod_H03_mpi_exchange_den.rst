mod_H03_mpi_exchange_den.f90
------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_H03_mpi_exchange_den`` 是该目录的模块包装器，
   通过 ``include`` 将密度交换主例程暴露为模块公开符号。

   .. rubric:: 公开入口与 include 关系

   下列文件在 ``mod_H03_mpi_exchange_den`` 的 ``contains`` 作用域内 include。
   调用方应 ``use mod_H03_mpi_exchange_den`` 后调用具体例程；不要把这些
   include 文件单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_H03_mpi_exchange_den.f90``
        - 交换 density 边界面数据，并把收到的邻居贡献累加回本地密度边界。
        - 粒子沉积后需要合并跨 MPI 子域边界的 charge/current density 贡献。

   .. rubric:: 局部假设

   与 H03 其他文件一致：使用 ``MPI_COMM_WORLD``，
   位置索引采用 cell units，密度数组含一层 ghost cell。

   .. rubric:: 调用注意

   本页只说明模块的包装关系；参数说明和实现细节见
   :doc:`sub_H03_mpi_exchange_den <sub_H03_mpi_exchange_den>`。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_H03_mpi_exchange_den`` is the module wrapper for this directory.
   It exposes the density exchange routine as a public module symbol via
   ``include``.

   .. rubric:: Public Entries And Includes

   The following file is included inside the ``contains`` scope of
   ``mod_H03_mpi_exchange_den``. Callers should ``use mod_H03_mpi_exchange_den``
   and call the concrete routine through the module; do not compile the include
   file separately.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_H03_mpi_exchange_den.f90``
        - Exchanges density boundary-plane data and accumulates received neighbor contributions back into local density boundaries.
        - Merge charge/current density contributions after particle deposition across MPI subdomain boundaries.

   .. rubric:: Local Assumptions

   Consistent with the rest of H03: uses ``MPI_COMM_WORLD``, cell-unit
   indices, and a density array with one ghost-cell layer.

   .. rubric:: Calling Notes

   This page documents the module wrapper relationship only; parameter
   details and implementation notes are in
   :doc:`sub_H03_mpi_exchange_den <sub_H03_mpi_exchange_den>`.

   .. rubric:: Generated API

   .. doxygenfile:: mod_H03_mpi_exchange_den.f90
