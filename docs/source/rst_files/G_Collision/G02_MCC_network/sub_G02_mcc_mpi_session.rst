.. rst-class:: ap-g02 ap-g02-reference

MPI 会话：初始化与资源管理
======================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - workspace（工作区）是反复使用的临时内存；session（会话）是 C/Fortran 接口持有这类工作状态的对象。跨时间步复用可减少分配，但同一对象不能同时处理两个调用。

   .. tip:: Fortran 片段需要的声明

      ``iso_c_binding`` 是 Fortran 自带的 C 类型桥接模块，提供 ``c_double``、``c_int``、``c_int32_t``、``c_int64_t`` 等类型参数。G02 不会把这些名称转导出给主程序。
      在主程序声明区先写 ``use, intrinsic :: iso_c_binding``，再写 ``use mod_G02_MCC_network`` 和 ``implicit none``；``status`` 声明为 ``integer(c_int)``。
      本页简短调用式需要相应的 context、数组和步参数；:doc:`完整声明与初始化 <sub_G02_mcc_load>` 给出可构建示例。

   .. rubric:: 直接用途

   为多进程碰撞创建或关闭可复用的会话。会话保存 MPI 通信器和临时工作区；
   ``mod_G02_MCC_network_mpi`` 包含本文件。所有参与进程按相同顺序调用。

   .. code-block:: fortran

      call sub_G02_mcc_mpi_session_init(context, communicator, session, status, &
                                      max_candidates, threads, backend, sampler)
      ! 在时间循环中调用 sub_G02_mcc_mpi_step。
      call sub_G02_mcc_mpi_session_close(session)

   .. list-table:: 初始化参数
      :header-rows: 1
      :widths: 28 12 60

      * - 参数
        - 方向
        - 含义
      * - context
        - inout
        - 各进程已加载同一模型的 ``g02_mcc_context``；接收错误消息。
      * - communicator
        - in
        - ``use mpi`` 提供的默认 integer 通信器；不能是 ``MPI_COMM_NULL``。
      * - session
        - inout
        - ``g02_mcc_mpi_session``；初始化成功后跨步复用，关闭后释放。
      * - status
        - out
        - ``integer(c_int)``；0 表示成功。
      * - max_candidates / threads / backend / sampler
        - in，可选
        - 候选次数上限、线程数、执行后端、通道抽样器；含义见 :doc:`sub_G02_mcc_session`。

   初始化会先关闭传入的旧会话。先检查 ``status``，成功后才调用 :doc:`sub_G02_mcc_mpi_step`。
   主程序须初始化 MPI 并确认至少支持 ``MPI_THREAD_FUNNELED``；所有会话在 ``MPI_Finalize`` 前关闭。
   并行错误处理和完整例子见 :doc:`mod_G02_MCC_network_mpi`。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - A workspace is reusable scratch memory. A session holds this state for C/Fortran callers. Reuse reduces allocation, but one instance must not serve concurrent calls.

   .. tip:: Declarations required by Fortran fragments

      The intrinsic ``iso_c_binding`` module provides C-compatible kinds such as ``c_double``, ``c_int``, ``c_int32_t`` and ``c_int64_t``. G02 does not re-export them to the host.
      In the declaration section, write ``use, intrinsic :: iso_c_binding``, ``use mod_G02_MCC_network`` and ``implicit none``; declare status as ``integer(c_int)``.
      Short calls assume initialized context, arrays and step parameters; see :doc:`the complete caller <sub_G02_mcc_load>`.

   .. rubric:: Direct purpose

   Create or close a reusable MPI collision session holding a communicator and temporary workspace.
   ``mod_G02_MCC_network_mpi`` includes this file. Participating ranks follow the same call sequence.

   .. code-block:: fortran

      call sub_G02_mcc_mpi_session_init(context, communicator, session, status, &
                                      max_candidates, threads, backend, sampler)
      ! Call sub_G02_mcc_mpi_step inside the time loop.
      call sub_G02_mcc_mpi_session_close(session)

   ``context`` is an inout loaded model context, identical in model content across ranks.
   Input ``communicator`` is the default integer from ``use mpi`` and must not be ``MPI_COMM_NULL``.
   ``session`` is an inout ``g02_mcc_mpi_session``; output ``status`` is ``integer(c_int)`` with 0 for success.
   Optional ``max_candidates``, ``threads``, ``backend`` and ``sampler`` have the meanings in :doc:`sub_G02_mcc_session`.

   Initialization closes the supplied old session first. Check status before :doc:`sub_G02_mcc_mpi_step`.
   Initialize MPI with at least ``MPI_THREAD_FUNNELED`` and close sessions before ``MPI_Finalize``.
   See :doc:`mod_G02_MCC_network_mpi` for the collective contract and complete examples.

.. rubric:: Declarations in source / 源码中的接口声明

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_mpi_session.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_mpi_session_init
   :end-before: integer(c_int32_t) :: event_cap

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_mpi_session.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_mpi_session_close
   :end-before: integer(c_int) :: ignored

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_mpi_session.f90``

:doc:`MPI <group_mpi_interface>`
