.. _g02-mcc-collide:

.. rst-class:: ap-g02 ap-g02-reference

mcc_collide：单粒子碰撞
==========================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - projectile / primary：projectile 是当前跟踪的入射粒子；primary 是一次事件后对这条原粒子记录的处理结果，可更新、移除或改变物种。background 是用密度、温度等描述的碰撞伙伴。
      - reservoir（背景库）记录背景得到或失去的粒子、动量和能量；ledger（守恒账本）记录反应前后总量以核查守恒。两者用途不同，不能重复当作源项加入背景。

   .. tip:: Fortran 片段需要的声明

      ``iso_c_binding`` 是 Fortran 自带的 C 类型桥接模块，提供 ``c_double``、``c_int``、``c_int32_t``、``c_int64_t`` 等类型参数。G02 不会把这些名称转导出给主程序。
      在主程序声明区先写 ``use, intrinsic :: iso_c_binding``，再写 ``use mod_G02_MCC_network`` 和 ``implicit none``；``status`` 声明为 ``integer(c_int)``。
      本页简短调用式需要相应的 context、数组和步参数；:doc:`完整声明与初始化 <sub_G02_mcc_load>` 给出可构建示例。

   源码：``fortran_interface/sub_G02_mcc_collide.f90``，由 ``mod_G02_MCC_network`` 包含。

   .. rubric:: 直接用途

   对一个输入粒子抽样碰撞，返回“应该怎样改”的结果，不直接改动原粒子。
   这是兼容旧主程序的接口。整步批量处理推荐 :doc:`sub_G02_mcc_step`。

   .. code-block:: fortran

      call sub_G02_mcc_collide(context, projectile, background, dt_s, global_step, seed, &
                           outcome, status, max_events_per_step)

   .. list-table:: 参数与结果
      :header-rows: 1
      :widths: 28 12 60

      * - 参数
        - 方向
        - 含义与类型
      * - ``context``
        - inout
        - 已加载的 g02_mcc_context；接收诊断。
      * - ``projectile``
        - in
        - 一个 g02_mcc_particle；调用后原对象不变。
      * - ``background(:)``
        - in
        - g02_mcc_background 数组；旧结构按物种提供，未带 cell/state。
      * - ``dt_s``
        - in
        - real(c_double)，秒，有限非负。
      * - ``global_step`` / ``seed``
        - in
        - integer(c_int64_t)，步编号和随机种子。
      * - ``outcome``
        - out
        - g02_mcc_outcome，含主粒子动作、新产物、背景交换量和逐事件记录。
      * - ``status``
        - out
        - integer(c_int)，0 成功。
      * - ``max_events_per_step``
        - 可选 in
        - integer(c_int32_t)，候选上限，含空碰撞；0 使用默认 64。

   .. rubric:: 主粒子动作

   - ``G02_MCC_ACTION_NONE``：无真实事件，保留原粒子。
   - ``G02_MCC_ACTION_UPDATE``：用 outcome%primary 替换原粒子。
   - ``G02_MCC_ACTION_REMOVE``：删除原粒子。
   - ``G02_MCC_ACTION_MOVE_SPECIES``：按 primary_destination 移到目标物种，并使用 primary。

   主程序还要为 created 中的产物分配唯一 ID、插入数组，并处理 reservoir。
   先准备所有修改，确认成功后统一提交。用完调用
   :doc:`sub_G02_mcc_outcome_destroy <sub_G02_mcc_cleanup>`，再复用该 outcome。

   .. rubric:: 旧接口的停止条件

   物种改变或主粒子移除时会停止。达到候选上限时，
   outcome%event_limit_reached 为真，可能仍有未处理时间；**status=0 不代表 dt 一定全部完成**。
   需要完成整段 dt 的程序应选批量入口；C++ 底层还提供 :doc:`collide_full <fun_G02_mcc_engine>`。

   结果中位置保持输入位置；碰撞函数不推进轨迹。不要在这一步额外更新同一份粒子两次。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - A null collision is a rejected candidate: sampled waiting time is consumed but the particle state stays unchanged. It is a sampling device, not a physical reaction.
      - The projectile is the tracked incoming particle. The primary outcome tells what happens to that original particle record: update, removal or species change. Background partners are described by density and temperature.
      - Reservoir deltas track background gains/losses of particles, momentum and energy. A conservation ledger compares totals before and after reactions. Do not apply both as background source terms.

   .. tip:: Declarations required by Fortran fragments

      The intrinsic ``iso_c_binding`` module provides C-compatible kinds such as ``c_double``, ``c_int``, ``c_int32_t`` and ``c_int64_t``. G02 does not re-export them to the host.
      In the declaration section, write ``use, intrinsic :: iso_c_binding``, ``use mod_G02_MCC_network`` and ``implicit none``; declare status as ``integer(c_int)``.
      Short calls assume initialized context, arrays and step parameters; see :doc:`the complete caller <sub_G02_mcc_load>`.

   Source: ``fortran_interface/sub_G02_mcc_collide.f90``, included by ``mod_G02_MCC_network``.

   .. rubric:: Direct purpose

   Sample collisions for one input particle and return a proposed outcome without modifying the input.
   This is the legacy path; use :doc:`sub_G02_mcc_step` for new batch callers.

   .. code-block:: fortran

      call sub_G02_mcc_collide(context, projectile, background, dt_s, global_step, seed, &
                           outcome, status, max_events_per_step)

   .. list-table:: Parameters
      :header-rows: 1
      :widths: 28 12 60

      * - Parameter
        - Direction
        - Meaning and type
      * - ``context``
        - inout
        - Loaded g02_mcc_context, updated diagnostics.
      * - ``projectile``
        - in
        - One g02_mcc_particle, unchanged by the call.
      * - ``background(:)``
        - in
        - Legacy g02_mcc_background array, without cell/state fields.
      * - ``dt_s``
        - in
        - Finite nonnegative seconds, real(c_double).
      * - ``global_step`` / ``seed``
        - in
        - Step and seed, integer(c_int64_t).
      * - ``outcome``
        - out
        - g02_mcc_outcome with action, products, exchange and events.
      * - ``status``
        - out
        - integer(c_int), 0 on success.
      * - ``max_events_per_step``
        - optional in
        - integer(c_int32_t), real+null candidate cap; 0 selects 64.

   .. rubric:: Host commit

   NONE keeps the input; UPDATE replaces it with primary; REMOVE deletes it;
   MOVE_SPECIES moves primary to primary_destination.
   The host also allocates unique IDs for created products and applies reservoir exchange.
   Prepare all changes before committing. Call
   :doc:`sub_G02_mcc_outcome_destroy <sub_G02_mcc_cleanup>` before reusing an outcome.

   .. rubric:: Legacy stopping behavior

   A species move or removal stops sampling. Hitting the candidate cap sets event_limit_reached
   and may leave time unprocessed. A successful status alone does not guarantee all dt was covered.
   Use the batch entry, or C++ :doc:`collide_full <fun_G02_mcc_engine>`, when full-time processing is required.
   Collision calls preserve position; they do not advance trajectories.

.. rubric:: Declarations in source / 源码中的接口声明

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_collide.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_collide(context, projectile, background, dt_s, global_step, seed, &
   :end-before: character(kind=c_char) :: errbuf(g02_mcc_error_length)

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_collide.f90``

:doc:`Fortran API <group_fortran_interface>`
