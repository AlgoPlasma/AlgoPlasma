.. rst-class:: ap-g02 ap-g02-reference

MPI 步进：多进程协同碰撞
====================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip:: Fortran 片段需要的声明

      ``iso_c_binding`` 是 Fortran 自带的 C 类型桥接模块，提供 ``c_double``、``c_int``、``c_int32_t``、``c_int64_t`` 等类型参数。G02 不会把这些名称转导出给主程序。
      在主程序声明区先写 ``use, intrinsic :: iso_c_binding``，再写 ``use mod_G02_MCC_network`` 和 ``implicit none``；``status`` 声明为 ``integer(c_int)``。
      本页简短调用式需要相应的 context、数组和步参数；:doc:`完整声明与初始化 <sub_G02_mcc_load>` 给出可构建示例。

   .. rubric:: 直接用途

   协同推进所有 MPI 进程的本步碰撞。每个进程处理自己的粒子与背景，
   G02 统一检查准备是否成功，并分配全局唯一的新粒子 ID，再写回结果。
   ``mod_G02_MCC_network_mpi`` 包含本文件。

   .. code-block:: fortran

      call sub_G02_mcc_mpi_step(context, session, particles, background, dt_s, &
                               global_step, seed, report, status)

   .. list-table:: 参数
      :header-rows: 1
      :widths: 25 15 60

      * - 参数
        - 方向
        - 含义
      * - context / session
        - inout
        - 已加载的模型和成功初始化的 MPI 会话。
      * - particles
        - inout
        - 本进程已分配的 ``g02_mcc_particle`` 数组；成功后包含新粒子。
      * - background
        - in
        - 本进程的 ``g02_mcc_cell_background`` 数组。
      * - dt_s / global_step / seed
        - in
        - 时间步（秒）、全局步号、随机种子；各进程保持一致。
      * - report / status
        - out
        - ``g02_mcc_step_report`` 和状态码；0 表示成功。

   即使本进程没有粒子，也要用已分配的零长度数组参加调用。出错时保留原粒子数组。
   报告统计与背景收支属于本进程，需要全局总量时由主程序求和。
   MPI 粒子迁移由主程序完成；已有 ID 在迁移时保持不变，新粒子从下一全局步参与碰撞。
   初始化见 :doc:`sub_G02_mcc_mpi_session`，字段与单位见 :ref:`数据对象与单位 <g02-data-types-zh>`。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.

   .. tip:: Declarations required by Fortran fragments

      The intrinsic ``iso_c_binding`` module provides C-compatible kinds such as ``c_double``, ``c_int``, ``c_int32_t`` and ``c_int64_t``. G02 does not re-export them to the host.
      In the declaration section, write ``use, intrinsic :: iso_c_binding``, ``use mod_G02_MCC_network`` and ``implicit none``; declare status as ``integer(c_int)``.
      Short calls assume initialized context, arrays and step parameters; see :doc:`the complete caller <sub_G02_mcc_load>`.

   .. rubric:: Direct purpose

   Advance one collective collision step. Each rank supplies local particles and background;
   G02 coordinates preparation, globally unique child IDs and commit.
   ``mod_G02_MCC_network_mpi`` includes this file.

   .. code-block:: fortran

      call sub_G02_mcc_mpi_step(context, session, particles, background, dt_s, &
                               global_step, seed, report, status)

   Inout ``context`` and ``session`` must be loaded and initialized.
   Inout ``particles`` is an allocated local ``g02_mcc_particle`` array;
   input ``background`` is a local ``g02_mcc_cell_background`` array.
   Inputs ``dt_s`` (seconds), ``global_step`` and ``seed`` agree across ranks.
   Outputs are ``g02_mcc_step_report`` and ``integer(c_int)`` status (0 for success).

   Empty ranks still participate with allocated zero-length arrays. Errors preserve the original particles.
   Reports are local; the host reduces them when global totals are needed.
   The host handles MPI migration, retaining existing IDs. Children start collisions on the next global step.
   See :doc:`sub_G02_mcc_mpi_session` for initialization and :ref:`Data objects and units <g02-data-types-en>` for fields and units.

.. rubric:: Declaration in source / 源码中的接口声明

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_mpi_step.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_mpi_step
   :end-before: type(g02_mcc_particle), allocatable, target :: work(:), finished(:)

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_mpi_step.f90``

:doc:`MPI <group_mpi_interface>`
