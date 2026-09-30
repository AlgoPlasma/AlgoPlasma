.. _g02-mcc-session-init-close:

.. rst-class:: ap-g02 ap-g02-reference

碰撞会话：创建与关闭工作区
==================================

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

   源码：``fortran_interface/sub_G02_mcc_session.f90``，由 ``mod_G02_MCC_network`` 包含。

   .. rubric:: 直接用途

   会话把多步之间可复用的工作区保存下来，减少重复准备和分配。
   第一次使用可不加会话；长期时间循环可以创建一次、每步复用。

   .. code-block:: fortran

      call sub_G02_mcc_session_init(context, session, status, max_candidates, threads, backend, sampler)
      call sub_G02_mcc_step(context, particles, gas, dt, step, seed, report, status, session=session)
      call sub_G02_mcc_session_close(session)

   .. list-table:: 初始化参数
      :header-rows: 1
      :widths: 27 13 60

      * - 参数
        - 方向
        - 约定
      * - ``context``
        - inout
        - 已加载的 g02_mcc_context。
      * - ``session``
        - inout
        - g02_mcc_session；已有会话会先关闭。
      * - ``status``
        - out
        - integer(c_int)，0 成功。
      * - ``max_candidates``
        - 可选 in
        - integer(c_int32_t)，0 选默认一百万；真实事件与空碰撞都计数。
      * - ``threads``
        - 可选 in
        - integer(c_int)，0 由 OpenMP 运行时决定，非负。
      * - ``backend``
        - 可选 in
        - G02_MCC_BACKEND_AUTO / SERIAL / OPENMP；默认 AUTO。
      * - ``sampler``
        - 可选 in
        - G02_MCC_SAMPLER_PREFIX / ALIAS；默认 PREFIX。

   PREFIX 用累积权重区间选通道；ALIAS 使用预先建立的查表结构。
   二者用于抽取相同的通道概率，跨采样器不承诺逐粒子结果相同。

   .. rubric:: 生命周期与容量重试

   传入 session 时，sub_G02_mcc_step 不再接收 max_candidates、threads、backend；
   这些选项由会话固定。包装器遇到容量不足会调用 C 层 session_resume，
   沿用已抽样的碰撞结果，扩容后继续提交。其他失败会中止待提交结果。

   先关闭 session，再关闭 context。会话不适合被多个并发调用共用；
   需要同时处理独立模拟时，为各自创建会话。
   关闭函数不返回 status，可对默认初始化或已关闭的会话重复调用。

   .. rubric:: C 接口对应关系

   ``ap_g02_mcc_session_create/step/resume/abort/destroy`` 分别负责创建、采样、
   扩容后续接、丢弃待提交结果和释放。详见 :doc:`fun_G02_mcc_c_api`。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - A null collision is a rejected candidate: sampled waiting time is consumed but the particle state stays unchanged. It is a sampling device, not a physical reaction.
      - A workspace is reusable scratch memory. A session holds this state for C/Fortran callers. Reuse reduces allocation, but one instance must not serve concurrent calls.

   .. tip:: Declarations required by Fortran fragments

      The intrinsic ``iso_c_binding`` module provides C-compatible kinds such as ``c_double``, ``c_int``, ``c_int32_t`` and ``c_int64_t``. G02 does not re-export them to the host.
      In the declaration section, write ``use, intrinsic :: iso_c_binding``, ``use mod_G02_MCC_network`` and ``implicit none``; declare status as ``integer(c_int)``.
      Short calls assume initialized context, arrays and step parameters; see :doc:`the complete caller <sub_G02_mcc_load>`.

   Source: ``fortran_interface/sub_G02_mcc_session.f90``, included by ``mod_G02_MCC_network``.

   .. rubric:: Direct purpose

   A session retains reusable batch workspace between steps.
   It is optional for a first caller and useful for long time loops.

   .. code-block:: fortran

      call sub_G02_mcc_session_init(context, session, status, max_candidates, threads, backend, sampler)
      call sub_G02_mcc_step(context, particles, gas, dt, step, seed, report, status, session=session)
      call sub_G02_mcc_session_close(session)

   .. list-table:: Initialization
      :header-rows: 1
      :widths: 27 13 60

      * - Parameter
        - Direction
        - Convention
      * - ``context``
        - inout
        - Loaded g02_mcc_context.
      * - ``session``
        - inout
        - Existing session is closed before initialization.
      * - ``status``
        - out
        - integer(c_int), 0 on success.
      * - ``max_candidates``
        - optional in
        - integer(c_int32_t); 0 selects one million real+null candidates.
      * - ``threads``
        - optional in
        - Nonnegative integer(c_int); 0 lets OpenMP choose.
      * - ``backend``
        - optional in
        - G02_MCC_BACKEND_AUTO / SERIAL / OPENMP; AUTO by default.
      * - ``sampler``
        - optional in
        - G02_MCC_SAMPLER_PREFIX / ALIAS; PREFIX by default.

   PREFIX selects cumulative weight intervals; ALIAS uses a prepared lookup structure.
   Both sample the same probabilities; identical particle realizations across samplers are not promised.

   .. rubric:: Lifetime and retry

   When supplying session to sub_G02_mcc_step, omit max_candidates, threads and backend.
   A capacity retry uses C session_resume, preserving sampled outcomes rather than sampling again.
   Other failures abort pending work.

   Close the session before the context. Do not share one session between concurrent calls.
   The close routine has no status output and may be repeated on an initialized or closed session.
   C equivalents are create/step/resume/abort/destroy; see :doc:`fun_G02_mcc_c_api`.

.. rubric:: Declarations in source / 源码中的接口声明

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_session.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_session_init(context, session, status, max_candidates, threads, backend, sampler)
   :end-before: integer(c_int32_t) :: event_cap

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_session.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_session_close(session)
   :end-before: integer(c_int) :: ignored

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_session.f90``

:doc:`Fortran API <group_fortran_interface>`
