.. _distributedmccstepper-g02-mcc-mpi:

.. rst-class:: ap-g02 ap-g02-reference

MPI：分布式碰撞接口
==============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - workspace（工作区）是反复使用的临时内存；session（会话）是 C/Fortran 接口持有这类工作状态的对象。跨时间步复用可减少分配，但同一对象不能同时处理两个调用。
      - ABI（应用二进制接口）规定不同语言编译后怎样传参和返回结果。handle（句柄）是库对象的引用；保存并通过接口使用它，不直接读取其内部数据。

   .. tip:: Fortran 片段需要的声明

      ``iso_c_binding`` 是 Fortran 自带的 C 类型桥接模块，提供 ``c_double``、``c_int``、``c_int32_t``、``c_int64_t`` 等类型参数。G02 不会把这些名称转导出给主程序。
      在主程序声明区先写 ``use, intrinsic :: iso_c_binding``，再写 ``use mod_G02_MCC_network`` 和 ``implicit none``；``status`` 声明为 ``integer(c_int)``。
      本页简短调用式需要相应的 context、数组和步参数；:doc:`完整声明与初始化 <sub_G02_mcc_load>` 给出可构建示例。

   本模块在 ``contains`` 中 include :doc:`sub_G02_mcc_mpi_session` 和
   :doc:`sub_G02_mcc_mpi_step`，分别管理并行会话和每步碰撞。

   .. rubric:: 直接用途

   多个 MPI 进程分别持有自己的粒子和背景，G02 协调各进程完成碰撞与新粒子 ID 分配。
   它不负责把跨区域运动的粒子迁移到另一个进程。
   每个进程都必须按同样顺序参加这些集合调用，即使本地粒子数组为空。

   .. rubric:: C++ 与 C 入口

   C++ 使用 mpi.hpp 中的 DistributedMccStepper(engine, communicator, options)，
   随后 step(adapter, background, dt_s, global_step, seed) 返回本地 StepReport。
   它复制 communicator，保存跨步工作区和 ID 高水位。

   C 的 mpi_c_api.h 提供 ap_g02_mcc_mpi_session_create、create_f、step、destroy。
   create_f 接收 Fortran 通信器整数句柄；其余参数与普通会话类似。
   MPI 容量不足时各进程的输入都保留，各进程扩展必要容量后共同重试 step；
   这条路径重新确定性计算，没有普通会话的 resume 调用。

   .. rubric:: Fortran 子程序

   .. code-block:: fortran

      use mod_G02_MCC_network_mpi
      call sub_G02_mcc_mpi_session_init(context, communicator, session, status, &
                                    max_candidates, threads, backend, sampler)
      call sub_G02_mcc_mpi_step(context, session, particles, background, dt_s, &
                            global_step, seed, report, status)
      call sub_G02_mcc_mpi_session_close(session)

   .. list-table:: 参数
      :header-rows: 1
      :widths: 25 15 60

      * - 参数
        - 方向
        - 约定
      * - context
        - inout
        - 各进程成功加载相同模型。
      * - communicator
        - in
        - use mpi 的默认 integer 通信器；宽度须与 C int 匹配。
      * - session
        - inout
        - g02_mcc_mpi_session；初始化后跨步保留。
      * - particles / background
        - inout / in
        - 本进程已分配粒子数组与本地背景；字段约定见 :doc:`sub_G02_mcc_step`。
      * - dt_s / global_step / seed
        - in
        - 各进程为同一全局步骤提供一致的时间、步号与种子。
      * - report / status
        - out
        - 本地报告；0 成功，错误时原粒子保留。
      * - 初始化可选参数
        - in
        - 与 :doc:`sub_G02_mcc_session` 相同；MPI 步进中不重复设置。

   .. rubric:: 主程序的并行约定

   先调用 MPI_Init_thread，请求至少 MPI_THREAD_FUNNELED，并检查实际提供等级。
   碰撞集合调用应由允许执行 MPI 的线程进入。
   已存在粒子的 ID 在全局应唯一，迁移时保持 ID；新 ID 按父粒子、事件和产物序号协同分配。
   新产物从下一全局步参与。

   report 的计数、账本和背景增量是**本进程**结果；需要总碰撞数时，
   主程序再执行一次求和归约。G02 的全体一致性检查不会自动把所有报告变成全局报告。
   在 MPI_Finalize 前，所有相关进程应完成会话/步进器清理。

   .. rubric:: 构建与完整示例

   启用 G02_MCC_ENABLE_MPI；Fortran MPI 包装同时要求 G02_MCC_ENABLE_FORTRAN。
   C++/C 链接 AlgoPlasma::G02_MCC_MPI；
   Fortran 链接 AlgoPlasma::G02_MCC_Fortran_MPI。
   在 ``tests/009_collision/G02_MCC_network/`` 下，``examples/mpi_collision_box`` 展示 C++ 调用，
   ``fortran/test_fortran_mpi.f90`` 展示 Fortran 调用。
   MPI 与 OpenMP 可同时启用，OpenMP 负责每个进程内部的粒子分工。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - A workspace is reusable scratch memory. A session holds this state for C/Fortran callers. Reuse reduces allocation, but one instance must not serve concurrent calls.
      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.
      - Reservoir deltas track background gains/losses of particles, momentum and energy. A conservation ledger compares totals before and after reactions. Do not apply both as background source terms.

   .. tip:: Declarations required by Fortran fragments

      The intrinsic ``iso_c_binding`` module provides C-compatible kinds such as ``c_double``, ``c_int``, ``c_int32_t`` and ``c_int64_t``. G02 does not re-export them to the host.
      In the declaration section, write ``use, intrinsic :: iso_c_binding``, ``use mod_G02_MCC_network`` and ``implicit none``; declare status as ``integer(c_int)``.
      Short calls assume initialized context, arrays and step parameters; see :doc:`the complete caller <sub_G02_mcc_load>`.

   This module includes :doc:`sub_G02_mcc_mpi_session` and :doc:`sub_G02_mcc_mpi_step`
   after ``contains`` for MPI session management and collision steps.

   .. rubric:: Direct purpose

   Each MPI rank owns local particles and background. G02 coordinates collision preparation and child IDs.
   The host handles particle migration.
   Every rank participates in the same collective sequence, including ranks with no particles.

   .. rubric:: C++ and C

   DistributedMccStepper(engine,communicator,options) in mpi.hpp duplicates the communicator
   and keeps workspace plus an ID high-water mark.
   step(adapter,background,dt_s,global_step,seed) returns a local StepReport.

   mpi_c_api.h exposes ap_g02_mcc_mpi_session_create, create_f, step and destroy.
   create_f accepts the Fortran communicator integer.
   Capacity failure preserves all ranks' inputs; enlarge required buffers and collectively retry step.
   This path recomputes deterministically and has no ordinary-session resume entry.

   .. rubric:: Fortran

   .. code-block:: fortran

      use mod_G02_MCC_network_mpi
      call sub_G02_mcc_mpi_session_init(context, communicator, session, status, &
                                    max_candidates, threads, backend, sampler)
      call sub_G02_mcc_mpi_step(context, session, particles, background, dt_s, &
                            global_step, seed, report, status)
      call sub_G02_mcc_mpi_session_close(session)

   .. list-table:: Arguments
      :header-rows: 1
      :widths: 25 15 60

      * - Argument
        - Direction
        - Contract
      * - context
        - inout
        - Same successfully loaded model on all ranks.
      * - communicator
        - in
        - Default integer from use mpi; width must match C int.
      * - session
        - inout
        - g02_mcc_mpi_session retained across steps.
      * - particles / background
        - inout / in
        - Allocated local particles and local background; see :doc:`sub_G02_mcc_step`.
      * - dt_s / global_step / seed
        - in
        - Consistent global step inputs across ranks.
      * - report / status
        - out
        - Local report; 0 on success, original particles preserved on failure.
      * - Optional initialization settings
        - in
        - Same as :doc:`sub_G02_mcc_session`; set once at initialization.

   .. rubric:: Host contract

   Initialize MPI with at least MPI_THREAD_FUNNELED and check the provided level.
   Invoke collective steps from an MPI-permitted thread.
   Keep existing particle IDs globally unique and unchanged during migration.
   New IDs are coordinated by parent, event and product ordinal; children start next step.

   Report counts, ledger and exchange are local, not automatically reduced global diagnostics.
   The host sums them when global totals are needed.
   Destroy sessions/steppers collectively before MPI_Finalize.

   Enable G02_MCC_ENABLE_MPI and, for Fortran, G02_MCC_ENABLE_FORTRAN.
   Link AlgoPlasma::G02_MCC_MPI for C++/C or AlgoPlasma::G02_MCC_Fortran_MPI for Fortran.
   Under ``tests/009_collision/G02_MCC_network/``, ``examples/mpi_collision_box`` and
   ``fortran/test_fortran_mpi.f90`` provide complete callers.
   OpenMP may share work inside each rank.

.. rubric:: Module includes / 模块包含关系

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/mod_G02_MCC_network_mpi.f90
   :language: fortran
   :start-at: ! Public G02 routines
   :end-before: end module mod_G02_MCC_network_mpi

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fortran_interface/mod_G02_MCC_network_mpi.f90``

:doc:`MPI <group_mpi_interface>`
