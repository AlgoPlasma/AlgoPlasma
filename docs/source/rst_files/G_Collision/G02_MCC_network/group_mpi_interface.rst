.. rst-class:: ap-g02 ap-g02-reference

MPI
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   这一组包含下面这些源码文件。头文件（.hpp / .h）约定可使用的类型和接口，实现文件（.cpp）完成计算；部分小工具直接实现在头文件中。

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - 程序文件
        - 用途
      * - :doc:`mpi.hpp <mpi>`
        - 分布式批量推进接口
      * - :doc:`fun_G02_mcc_mpi.cpp <fun_G02_mcc_mpi>`
        - 协调多进程推进与新粒子编号
      * - :doc:`mpi_c_api.h <mpi_c_api>`
        - MPI 的 C 与 Fortran 桥接接口
      * - :doc:`fun_G02_mcc_mpi_c_api.cpp <fun_G02_mcc_mpi_c_api>`
        - 将跨语言数组交给 MPI 步进器
      * - :doc:`mod_G02_MCC_network_mpi.f90 <mod_G02_MCC_network_mpi>`
        - MPI：分布式碰撞接口
      * - :doc:`sub_G02_mcc_mpi_session.f90 <sub_G02_mcc_mpi_session>`
        - MPI 会话：初始化与资源管理
      * - :doc:`sub_G02_mcc_mpi_step.f90 <sub_G02_mcc_mpi_step>`
        - MPI 步进：多进程协同碰撞

.. container:: ap-lang ap-lang-en

   This group contains the source files below. Headers define types and interfaces; .cpp files implement them. Small utilities may be implemented inline in headers.

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - Source file
        - Purpose
      * - :doc:`mpi.hpp <mpi>`
        - Distributed batch-stepping interface
      * - :doc:`fun_G02_mcc_mpi.cpp <fun_G02_mcc_mpi>`
        - Coordinate distributed steps and child IDs
      * - :doc:`mpi_c_api.h <mpi_c_api>`
        - MPI bridge for C and Fortran
      * - :doc:`fun_G02_mcc_mpi_c_api.cpp <fun_G02_mcc_mpi_c_api>`
        - Connect cross-language arrays to MPI stepping
      * - :doc:`mod_G02_MCC_network_mpi.f90 <mod_G02_MCC_network_mpi>`
        - MPI: distributed collision interface
      * - :doc:`sub_G02_mcc_mpi_session.f90 <sub_G02_mcc_mpi_session>`
        - MPI sessions: initialization and resources
      * - :doc:`sub_G02_mcc_mpi_step.f90 <sub_G02_mcc_mpi_step>`
        - MPI stepping: collisions across processes

.. toctree::
   :maxdepth: 1
   :hidden:

   mpi.hpp <mpi>
   fun_G02_mcc_mpi.cpp <fun_G02_mcc_mpi>
   mpi_c_api.h <mpi_c_api>
   fun_G02_mcc_mpi_c_api.cpp <fun_G02_mcc_mpi_c_api>
   mod_G02_MCC_network_mpi.f90 <mod_G02_MCC_network_mpi>
   sub_G02_mcc_mpi_session.f90 <sub_G02_mcc_mpi_session>
   sub_G02_mcc_mpi_step.f90 <sub_G02_mcc_mpi_step>

:doc:`返回 G02 / Back to G02 <../G02_MCC_network>`
