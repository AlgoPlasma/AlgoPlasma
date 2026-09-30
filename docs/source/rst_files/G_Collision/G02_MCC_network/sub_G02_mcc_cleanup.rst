.. _g02-mcc-close-outcome-destroy-report-collect:

.. rst-class:: ap-g02 ap-g02-reference

结果整理与资源释放
==========================

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
      - reservoir（背景库）记录背景得到或失去的粒子、动量和能量；ledger（守恒账本）记录反应前后总量以核查守恒。两者用途不同，不能重复当作源项加入背景。

   .. tip:: Fortran 片段需要的声明

      ``iso_c_binding`` 是 Fortran 自带的 C 类型桥接模块，提供 ``c_double``、``c_int``、``c_int32_t``、``c_int64_t`` 等类型参数。G02 不会把这些名称转导出给主程序。
      在主程序声明区先写 ``use, intrinsic :: iso_c_binding``，再写 ``use mod_G02_MCC_network`` 和 ``implicit none``；``status`` 声明为 ``integer(c_int)``。
      本页简短调用式需要相应的 context、数组和步参数；:doc:`完整声明与初始化 <sub_G02_mcc_load>` 给出可构建示例。

   源码：``fortran_interface/sub_G02_mcc_cleanup.f90``，由 ``mod_G02_MCC_network`` 包含。

   .. rubric:: 直接用途与顺序

   把一次计算占用的资源释放干净。建议顺序：
   旧单粒子 outcome 用完立即释放 → 循环结束关闭 session → 关闭 context。
   原始粒子数组仍由主程序持有。

   .. list-table:: 清理入口
      :header-rows: 1
      :widths: 38 25 37

      * - 调用
        - 参数方向
        - 效果
      * - ``sub_G02_mcc_outcome_destroy(outcome)``
        - g02_mcc_outcome，inout
        - 释放 C 结果句柄与 created/reservoir/events 数组，并清零诊断字段。
      * - ``sub_G02_mcc_session_close(session)``
        - g02_mcc_session，inout
        - 释放会话工作区；详见 :doc:`sub_G02_mcc_session`。
      * - ``sub_G02_mcc_close(context)``
        - g02_mcc_context，inout
        - 先释放引擎，再释放模型；loaded 变假，status 和 error_message 重置。

   这些函数没有 status 输出，可重复清理默认初始化或已关闭的对象。
   复制带 C 指针的 context/session/outcome 不会复制底层资源；
   应明确由一个持有者负责释放，避免把同一个句柄当成两份独立资源。

   .. rubric:: 报告转换：sub_G02_mcc_report_collect

   .. code-block:: fortran

      call sub_G02_mcc_report_collect(handle, report, status)

   handle 为输入 type(c_ptr)，必须指向有效的 C 层批量报告；
   report 为输出 g02_mcc_step_report，status 为输出 integer(c_int)。
   它复制计数、账本、背景交换量与反应计数到 Fortran 数组，不改变粒子，也不释放输入 handle。
   底层调用者仍须执行 C 的 ap_g02_mcc_step_report_destroy。

   通常直接用 sub_G02_mcc_step 或 sub_G02_mcc_mpi_step：
   它们已经负责转换并释放 C 报告，主程序只使用 Fortran report。
   report 自身没有 C 句柄，其可分配成员由 Fortran 管理；不可拿它调用 outcome_destroy。

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

   Source: ``fortran_interface/sub_G02_mcc_cleanup.f90``, included by ``mod_G02_MCC_network``.

   .. rubric:: Purpose and order

   Release legacy outcomes after use, close sessions after the loop, then close the context.
   The host still owns its particle array.

   .. list-table:: Cleanup entries
      :header-rows: 1
      :widths: 38 25 37

      * - Call
        - Argument
        - Effect
      * - ``sub_G02_mcc_outcome_destroy(outcome)``
        - inout g02_mcc_outcome
        - Releases the C outcome and created/reservoir/events arrays; resets diagnostics.
      * - ``sub_G02_mcc_session_close(session)``
        - inout g02_mcc_session
        - Releases session workspace; see :doc:`sub_G02_mcc_session`.
      * - ``sub_G02_mcc_close(context)``
        - inout g02_mcc_context
        - Releases engine then model; resets loaded, status and error text.

   These calls have no status argument and can be repeated on default-initialized or closed objects.
   Copying a context/session/outcome with C pointers does not clone the underlying resource.
   Keep a single clear owner for cleanup.

   .. rubric:: Report conversion

   .. code-block:: fortran

      call sub_G02_mcc_report_collect(handle, report, status)

   handle is an input type(c_ptr) pointing to a valid C batch report.
   report is output g02_mcc_step_report and status is output integer(c_int).
   The routine copies statistics, ledger, exchange and reaction counts into Fortran storage.
   It neither changes particles nor destroys handle; a low-level caller must still invoke the C report destructor.

   Ordinary sub_G02_mcc_step and sub_G02_mcc_mpi_step already collect and destroy the C report.
   The resulting Fortran report has allocatable members and no C handle.
   It must not be passed to outcome_destroy.

.. rubric:: Declarations in source / 源码中的接口声明

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_cleanup.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_close(context)
   :end-before: integer(c_int) :: status

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_cleanup.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_outcome_destroy(outcome)
   :end-before: integer(c_int) :: status

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_cleanup.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_report_collect(handle, report, status)
   :end-before: integer(c_size_t) :: nitems, i

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_cleanup.f90``

:doc:`Fortran API <group_fortran_interface>`
