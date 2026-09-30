.. _g02-mcc-step:

.. rst-class:: ap-g02 ap-g02-reference

mcc_step：批量碰撞步进
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
      - reservoir（背景库）记录背景得到或失去的粒子、动量和能量；ledger（守恒账本）记录反应前后总量以核查守恒。两者用途不同，不能重复当作源项加入背景。

   .. tip:: Fortran 片段需要的声明

      ``iso_c_binding`` 是 Fortran 自带的 C 类型桥接模块，提供 ``c_double``、``c_int``、``c_int32_t``、``c_int64_t`` 等类型参数。G02 不会把这些名称转导出给主程序。
      在主程序声明区先写 ``use, intrinsic :: iso_c_binding``，再写 ``use mod_G02_MCC_network`` 和 ``implicit none``；``status`` 声明为 ``integer(c_int)``。
      本页简短调用式需要相应的 context、数组和步参数；:doc:`完整声明与初始化 <sub_G02_mcc_load>` 给出可构建示例。

   .. tip:: cell 与 state 的特殊值

      ``cell`` 是网格编号，不是数组下标。背景的 ``UINT32_MAX``（Fortran 的 ``-1_c_int32_t``）表示全域备用背景；正常网格编号必须与粒子一致。
      ``invalid_state`` 是 C++ 的 65535 哨兵值，C 用 ``UINT16_MAX``，Fortran 用 ``-1_c_int16_t``。它只供旧版按物种合并的背景使用，不等于基态，也不代表自动分配各态密度。
      入门时用 ``state_id(species, "ground")`` 或 Fortran 的 ``sub_G02_mcc_state_id`` 查询真实态；名称须存在于模型。被跟踪粒子的态必须有效。

   源码：``fortran_interface/sub_G02_mcc_step.f90``，由 ``mod_G02_MCC_network`` 包含。

   .. rubric:: 直接用途

   一次调用处理本步全部合格粒子的碰撞，包括速度更新、删除、转成其他物种和生成新粒子。
   粒子数组成功后直接更新，失败时原数组保留。这是新主程序推荐的 Fortran 入口。

   .. code-block:: fortran

      call sub_G02_mcc_step(context, particles, background, dt_s, global_step, seed, &
                        report, status, max_candidates, threads, backend, session)

   最后四个参数可省略。使用 ``session=...`` 时，其余三个选项必须省略，
   并在 :doc:`sub_G02_mcc_session` 初始化时设置。

   .. list-table:: 参数
      :header-rows: 1
      :widths: 23 12 25 40

      * - 参数
        - 方向
        - 类型/范围
        - 含义
      * - ``context``
        - inout
        - ``g02_mcc_context``
        - 已成功加载的上下文。
      * - ``particles(:)``
        - inout
        - 可分配 ``g02_mcc_particle`` 数组
        - 必须已 allocate，允许长度为零；成功后长度可能改变。
      * - ``background(:)``
        - in
        - ``g02_mcc_cell_background`` 数组
        - 按 cell/species/state 提供背景。活动通道需要的条目必须存在。
      * - ``dt_s``
        - in
        - ``real(c_double)``，秒，非负有限值
        - 本次要处理的时间；可以包含多次碰撞。
      * - ``global_step``
        - in
        - ``integer(c_int64_t)``，非负
        - 全局步编号；只处理 birth_step 不大于此值的粒子。
      * - ``seed``
        - in
        - ``integer(c_int64_t)``
        - 随机种子，与步编号和粒子 ID 一起确定抽样。
      * - ``report``
        - out
        - ``g02_mcc_step_report``
        - 计数、背景收支、守恒账本和耗时；成功后读取。
      * - ``status``
        - out
        - ``integer(c_int)``
        - 0 成功；非零时先读取错误。
      * - ``max_candidates``
        - in，可选
        - ``integer(c_int32_t)``
        - 单粒子候选上限，含真实和空碰撞；0 使用默认 1,000,000。
      * - ``threads`` / ``backend``
        - in，可选
        - ``integer(c_int)``
        - threads=0 由运行时选择；backend 为 AUTO / SERIAL / OPENMP 常量。
      * - ``session``
        - inout，可选
        - ``g02_mcc_session``
        - 已初始化的持久工作区。

   .. rubric:: 结果与主程序的衔接

   成功后 particles 已更新。新粒子 birth_step 设为 global_step+1，本步不再碰撞。
   ``report%stats`` 保存计数与耗时，``report%reaction_id/count`` 按反应汇总，
   ``report%reservoir`` 是背景获得的粒子数、动量和能量增量。
   这些是一次步进的增量，**不是已经除以体积和时间的源项密度**；
   换成流体方程中的源项时，主程序按自己的网格体积与时间步换算。

   背景数组不会自动改变。``report%ledger`` 用于核对收支，不能再次当作源项累加。
   批量 Fortran 报告不提供逐事件数组；研究逐事件记录时使用 C++ 的 record_events 选项。

   .. rubric:: 内部逻辑和常见错误

   包装器先复制粒子到工作数组；容量不足时自动扩容、重试，再复制报告并一次性替换原数组。
   缺背景、查表越界、实际频率超过上界、守恒失败、候选超限都会返回错误。
   超限不会被当作成功的短时间步。

   粒子 ID 应唯一并跨步保留；不要每步重新从 1 编号。均匀背景 cell 写作
   ``-1_c_int32_t``；物种合并背景的 state 写作 ``-1_c_int16_t``，
   按态提供密度时填写模型中的实际 state ID。类型完整字段见 :ref:`数据对象与单位 <g02-data-types-zh>`。

   .. code-block:: fortran

      call sub_G02_mcc_step(context, particles, gas, 1.0e-7_c_double, &
                        step, 42_c_int64_t, report, status)
      if (status /= 0_c_int) then
          print *, trim(context%error_message)
          stop 1
      end if
      print *, report%stats%real_events

   完整可编译示例在 :doc:`mod_G02_MCC_network`。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - A null collision is a rejected candidate: sampled waiting time is consumed but the particle state stays unchanged. It is a sampling device, not a physical reaction.
      - A workspace is reusable scratch memory. A session holds this state for C/Fortran callers. Reuse reduces allocation, but one instance must not serve concurrent calls.
      - Reservoir deltas track background gains/losses of particles, momentum and energy. A conservation ledger compares totals before and after reactions. Do not apply both as background source terms.

   .. tip:: Declarations required by Fortran fragments

      The intrinsic ``iso_c_binding`` module provides C-compatible kinds such as ``c_double``, ``c_int``, ``c_int32_t`` and ``c_int64_t``. G02 does not re-export them to the host.
      In the declaration section, write ``use, intrinsic :: iso_c_binding``, ``use mod_G02_MCC_network`` and ``implicit none``; declare status as ``integer(c_int)``.
      Short calls assume initialized context, arrays and step parameters; see :doc:`the complete caller <sub_G02_mcc_load>`.

   .. tip:: Special cell and state values

      cell is a mesh ID, not an array index. Background ``UINT32_MAX`` (Fortran ``-1_c_int32_t``) selects uniform fallback; local IDs must match particles.
      C++ ``invalid_state`` is the 65535 sentinel (C ``UINT16_MAX``; Fortran ``-1_c_int16_t``), only for legacy species-aggregate backgrounds. It is not ground state and does not distribute density over states.
      Prefer a real state obtained with ``state_id`` or ``sub_G02_mcc_state_id`` using a label in the model. Tracked particles must have valid states.

   Source: ``fortran_interface/sub_G02_mcc_step.f90``, included by ``mod_G02_MCC_network``.

   .. rubric:: Direct purpose

   Process all eligible particles for one step, including updates, removals, species moves and births.
   Success updates the array; failure preserves it. This is the recommended Fortran entry for new callers.

   .. code-block:: fortran

      call sub_G02_mcc_step(context, particles, background, dt_s, global_step, seed, &
                        report, status, max_candidates, threads, backend, session)

   The last four arguments are optional. With ``session=...``, omit the other three options;
   set them at :doc:`session initialization <sub_G02_mcc_session>`.

   .. list-table:: Parameters
      :header-rows: 1
      :widths: 23 12 25 40

      * - Parameter
        - Direction
        - Type/range
        - Meaning
      * - ``context``
        - inout
        - ``g02_mcc_context``
        - Successfully loaded context.
      * - ``particles(:)``
        - inout
        - Allocatable ``g02_mcc_particle`` array
        - Must be allocated, possibly empty; size may change on success.
      * - ``background(:)``
        - in
        - ``g02_mcc_cell_background`` array
        - Background by cell/species/state. Active channels require their entries.
      * - ``dt_s``
        - in
        - ``real(c_double)``, finite nonnegative seconds
        - Time to process, possibly including multiple collisions.
      * - ``global_step``
        - in
        - Nonnegative ``integer(c_int64_t)``
        - Only particles with birth_step no greater than this value participate.
      * - ``seed``
        - in
        - ``integer(c_int64_t)``
        - Random seed combined with step and particle ID.
      * - ``report``
        - out
        - ``g02_mcc_step_report``
        - Counts, exchange, ledger and timing; read after success.
      * - ``status``
        - out
        - ``integer(c_int)``
        - 0 on success.
      * - ``max_candidates``
        - optional in
        - ``integer(c_int32_t)``
        - Per-particle real+null cap; 0 selects 1,000,000.
      * - ``threads`` / ``backend``
        - optional in
        - ``integer(c_int)``
        - 0 threads lets the runtime choose; backend uses AUTO / SERIAL / OPENMP constants.
      * - ``session``
        - optional inout
        - ``g02_mcc_session``
        - Initialized persistent workspace.

   .. rubric:: Outputs and host integration

   Children get birth_step=global_step+1 and start colliding next step.
   ``report%stats`` has counts/timing, ``report%reaction_id/count`` summarizes reactions,
   and ``report%reservoir`` holds background number, momentum and energy increments.
   These are increments per call, not source densities already divided by volume and time.
   The host applies its own conversion for a fluid solver.

   Background inputs are unchanged. The ledger is an accounting diagnostic, not another source to add.
   Fortran batch reports do not expose per-event arrays; C++ record_events enables those records.

   .. rubric:: Implementation and failure

   The wrapper copies particles, expands/retries on capacity shortage, collects the report and replaces
   the original array only after success. Missing backgrounds, table-domain errors, violated bounds,
   conservation failures and candidate limits fail the call. A candidate limit does not silently truncate dt.

   Keep unique, persistent particle IDs. Uniform cell fallback is ``-1_c_int32_t``;
   species-aggregated state is ``-1_c_int16_t``. Use real state IDs for resolved state densities.
   See :ref:`Data objects and units <g02-data-types-en>`.

   .. code-block:: fortran

      call sub_G02_mcc_step(context, particles, gas, 1.0e-7_c_double, &
                        step, 42_c_int64_t, report, status)
      if (status /= 0_c_int) then
          print *, trim(context%error_message)
          stop 1
      end if
      print *, report%stats%real_events

   See :doc:`mod_G02_MCC_network` for a complete caller.

.. rubric:: Declarations in source / 源码中的接口声明

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_step.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_step(context, particles, background, dt_s, global_step, seed, &
   :end-before: type(g02_mcc_particle), allocatable, target :: work(:), finished(:)

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_step.f90``

:doc:`Fortran API <group_fortran_interface>`
