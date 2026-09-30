.. rst-class:: ap-g02 ap-g02-reference

mpi.hpp：分布式批量推进接口
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这个文件做什么

   每个 MPI 进程持有自己的粒子和背景，DistributedMccStepper 协调各进程完成同一时间步。主程序负责初始化 MPI，并在粒子迁移时保留 ID。所有相关进程都必须参加 step 调用。只在启用 MPI 时使用，不能只靠 mcc.hpp 获得此接口。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      DistributedMccStepper(MccEngine, MPI_Comm, StepOptions); step; communicator

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: What this file does

   Each rank owns local particles and backgrounds. The host initializes MPI and preserves IDs during migration. All participating ranks must call step. This optional API requires mpi.hpp explicitly.

   .. rubric:: Main types and entry points

   .. code-block:: text

      DistributedMccStepper(MccEngine, MPI_Comm, StepOptions); step; communicator

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`mpi.hpp <../../../../../G_Collision/G02_MCC_network/mpi.hpp>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/mpi.hpp
   :language: cpp
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/mpi.hpp``

:doc:`MPI <group_mpi_interface>`
