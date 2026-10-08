.. rst-class:: ap-g02 ap-g02-reference

MPI
==================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   每个 MPI 进程持有本地粒子和背景。``DistributedMccStepper`` 先准备本地碰撞，协调错误状态和新产物 ID，再共同提交。所有相关进程都要参与调用；主程序保留全局唯一粒子 ID，负责 MPI 初始化、网格划分和粒子迁移。

   - :doc:`mpi.hpp <mpi>`：分布式批量接口。
   - :doc:`fun_G02_mcc_mpi.cpp <fun_G02_mcc_mpi>`：准备、协调与提交的实现。

   构建时启用 ``G02_MCC_ENABLE_MPI``，链接 ``AlgoPlasma::G02_MCC_MPI``。MPI 线程支持至少为 ``MPI_THREAD_FUNNELED``；在 ``MPI_Finalize()`` 前销毁步进器。

.. container:: ap-lang ap-lang-en

   Each rank owns local particles/backgrounds. ``DistributedMccStepper`` prepares local collisions, agrees on errors and child IDs, then commits together. Every participating rank must call it. The host preserves globally unique IDs and owns MPI initialization, partitioning and particle migration.

   - :doc:`mpi.hpp <mpi>`: distributed batch API.
   - :doc:`fun_G02_mcc_mpi.cpp <fun_G02_mcc_mpi>`: preparation, agreement and commit.

   Enable ``G02_MCC_ENABLE_MPI`` and link ``AlgoPlasma::G02_MCC_MPI``. Require at least ``MPI_THREAD_FUNNELED`` and destroy the stepper before ``MPI_Finalize()``.

.. toctree::
   :hidden:

   mpi.hpp <mpi>
   fun_G02_mcc_mpi.cpp <fun_G02_mcc_mpi>

:doc:`返回 G02 / Back to G02 <../G02_MCC_network>`
