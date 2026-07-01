mod_H03_mpi_exchange_den.f90
------------------------------

.. raw:: html

   <div class="pmsl-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="zh">中文</button>
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="en">English</button>
   </div>

.. container:: pmsl-lang pmsl-lang-zh

   .. rubric:: 直接用途

   ``mod_H03_mpi_exchange_den`` 是该目录的模块包装器，
   通过 ``include`` 将密度交换主例程暴露为模块公开符号。

   .. rubric:: 公开入口与 include 关系

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - 文件/符号
        - 角色
        - 调用约定
      * - ``sub_H03_mpi_exchange_den.f90``
        - 被模块 include 的公开源码入口
        - 调用方通过 ``use mod_H03_mpi_exchange_den`` 后调用；
          不要把 include 文件当作独立 translation unit 编译。

   .. rubric:: 局部假设

   与 H03 其他文件一致：使用 ``MPI_COMM_WORLD``，
   位置索引采用 cell units，密度数组含一层 ghost cell。

   .. rubric:: 调用注意

   本页只说明模块的包装关系；参数说明和实现细节见
   :doc:`sub_H03_mpi_exchange_den <sub_H03_mpi_exchange_den>`。

.. container:: pmsl-lang pmsl-lang-en

   .. rubric:: Direct Purpose

   ``mod_H03_mpi_exchange_den`` is the module wrapper for this directory.
   It exposes the density exchange routine as a public module symbol via
   ``include``.

   .. rubric:: Public Entries And Includes

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - File/symbol
        - Role
        - Calling convention
      * - ``sub_H03_mpi_exchange_den.f90``
        - Included public source entry
        - Call after ``use mod_H03_mpi_exchange_den``; include files are not
          standalone translation units.

   .. rubric:: Local Assumptions

   Consistent with the rest of H03: uses ``MPI_COMM_WORLD``, cell-unit
   indices, and a density array with one ghost-cell layer.

   .. rubric:: Calling Notes

   This page documents the module wrapper relationship only; parameter
   details and implementation notes are in
   :doc:`sub_H03_mpi_exchange_den <sub_H03_mpi_exchange_den>`.

   .. rubric:: Generated API

   .. doxygenfile:: mod_H03_mpi_exchange_den.f90
