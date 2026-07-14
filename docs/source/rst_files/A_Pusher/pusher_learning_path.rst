====================
Pusher Learning Path
====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这页解决什么问题

   本页面向第一次接触 ``A_Pusher`` 的读者。它不是粒子动力学教材，而是帮你把
   非相对论 Boris、柱坐标 Boris、相对论 Higuera-Cary 这三套推进器跟 AlgoPlasma
   里的 Fortran routine 对上号。读完后，应该知道该先看哪一页、哪些公式对应哪些代码、
   以及测试为什么能说明实现是可信的。

   .. rubric:: 推荐学习顺序

   .. list-table::
      :header-rows: 1
      :widths: 18 44 38

      * - 步骤
        - 先理解什么
        - 建议阅读
      * - 1
        - 时间交错（leapfrog）和"速度 / 位置交替推进"的基本图景。
        - 本页"核心图景"
      * - 2
        - 一次完整的 Cartesian Boris 速度推进（``v_neg → v_prime → v_pos``）。
        - :doc:`A01_Boris_3Dxyz <A01_Boris_3Dxyz>` 和 ``sub_A01_Boris_3Dxyz`` 的 API 页。
      * - 3
        - 怎么调和怎么集成到自己代码里。
        - :doc:`Pusher Usage Cookbook <pusher_usage_cookbook>`
      * - 4
        - 柱坐标 ``(r,\theta,z)`` 跟 Cartesian 的本质差异：位置更新和场分量都依赖 ``\theta``。
        - :doc:`A02_Boris_3Drtz <A02_Boris_3Drtz>` 和测试页
          :doc:`A02 测试 </tests/002_pusher/A02_Boris_3Drtz>`。
      * - 5
        - 相对论 Higuera-Cary：何时必须放弃 Boris、HC 多出来的步骤、高 ``\gamma`` 收益。
        - :doc:`A03_Higuera_Cary_relativistic_3Dxyz <A03_Higuera_Cary_relativistic_3Dxyz>`
          和测试页 :doc:`A03 测试 </tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz>`。
      * - 6
        - 怎样验证推进器在四类典型问题（gyro、纯 E 加速、ExB、ExB drift）下都通过。
        - :doc:`Pusher Testing Guide <pusher_testing_guide>`
          和 :doc:`002_pusher tests </tests/002_pusher/index>`。

   .. rubric:: 核心图景

   ``A_Pusher`` 的所有 routine 都做同一件事：把单个粒子的状态从 :math:`t^n`
   推进到 :math:`t^{n+1}`。完整 PIC 循环里，调用方组织粒子数组、电磁场插值、
   电流沉积、边界和时间步循环；推进器本身只负责一次原位状态更新。

   - **leapfrog 时间错位**。Boris 类方法假设速度存在半整数时间步
     :math:`v^{n-1/2}`，位置存在整数时间步 :math:`x^n`。
     传入推进器的 ``v`` 在物理上是 ``v^{n-1/2}``，返回的是 ``v^{n+1/2}``。
   - **Boris 旋转三步走**。在磁场不为零时：先做半步 ``E`` 加速（``v_neg``），
     再做 ``B`` 引起的旋转（``v_prime → v_pos``），最后再做半步 ``E`` 加速。
     ``E`` 加速和 ``B`` 旋转是 **算子分裂**，二阶精度。
   - **k 是 Boris 参数**。所有 A_Pusher 接口都需要 ``k = q\Delta t / (2m)`` 而不是
     原始 ``q/m`` 或 ``q\Delta t / m``——是把"半步加速"和"半角旋转"打包好的常数。
   - **位置更新归属不同**。A01/A03 只更新 ``v``，调用方写 ``r = r + v*dt``；
     A02 把位置更新放在 routine 内部，因为柱坐标位置更新涉及 ``\theta`` 旋转、
     不是简单加法。
   - **场是在粒子位置取值**。推进器接收的 ``E``、``B`` 是 **当前粒子位置** 的取值，
     不是网格量。怎么从网格插值到粒子位置是 gather 算子（``C_Gather``）的事，
     不是推进器的事。
   - **数值稳定性由调用方负责**。``\omega_c \Delta t \ll 1`` 是 Boris 稳定且精确的条件
     （:math:`\omega_c = qB/m` 是回旋频率）。传入 ``dt`` 过大不会报错，
     只会引入旋转角度误差。

   .. rubric:: 初学者最容易混的点

   - **k ≠ qm/2 ≠ q*dt/m**。每次时间步如果 ``qm`` 或 ``dt`` 变了，``k`` 必须重算
     （``k = 0.5*qm*dt``）。常见错误是把 ``k`` 当作常数缓存。
   - **A01 vs A02 接口不同**。A01 调用 ``sub_A01_Boris_3Dxyz(v, E, B, k)`` 之后
     **要自己加** ``r = r + v*dt``；A02 调用 ``sub_A02_Boris_3Drtz_push_v_x(x, v, E, B, k, dt)``
     位置已经更新完，**不能再加**。
   - **柱坐标的场分量随 θ 变**。如果在物理上是均匀 Cartesian ``E_x``，
     在柱坐标里就是 ``E_r = E_x\cos\theta``、``E_\phi = -E_x\sin\theta``，**每步都要重算**。
     直接传 Cartesian 分量给 A02 会得到错误轨迹。
   - **A03 内部转换 proper velocity，接口仍使用 lab velocity**。A03 内部把
     ``v`` 转换为 proper velocity ``\gamma v`` 再做 HC 旋转，接口仍然传入和返回
     lab velocity ``v``。初值约定与 Boris 相同，无需手动转换。
   - **r=0 在柱坐标里是奇点**。A02 的 routine 自己用 ``tiny(1.0_4)`` 检查并 fallback，
     但调用方应避免让粒子真正穿过 ``r=0`` 附近——θ 在该处不连续。

   .. rubric:: 建议练习

   1. 在草稿纸上把 Boris 旋转的三步推一遍，确认每步只用上一步的输出，不使用回旋频率
      或 ``\sin\omega\Delta t`` 的解析展开。
   2. 跑 :doc:`A01 测试 </tests/002_pusher/A01_Boris_3Dxyz>` 的 case 1，
      画出 ``x-y`` 轨迹和 ``v^2(t)``，确认 ``v^2`` 守恒。
   3. 用 ``dt`` 翻倍后再跑一次，观察 ``v^2`` 是否仍守恒（应该仍守恒，但位置误差变大）；
      理解 Boris 的"速度模长守恒、角度有 ``\omega\Delta t`` 误差"。
   4. 跑 A02 的 case 1，对比 A01 的位置最大误差——应该完全一致，
      因为柱坐标 Boris 和 Cartesian Boris 物理上等价。
   5. 跑 A03 的 case 2（高 ``\gamma`` ExB drift）。
      非相对论 Boris 在这种工况下会有几千的偏差，HC 给出 ``x \approx 0``——
      理解何时必须切换到相对论 pusher。

.. container:: ap-lang ap-lang-en

   .. rubric:: What This Page Is For

   This page is aimed at readers new to ``A_Pusher``. It is not a textbook on
   particle dynamics; it helps you connect the non-relativistic Boris,
   cylindrical Boris, and relativistic Higuera-Cary schemes to the Fortran
   routines in AlgoPlasma. After reading it, you should know which page to read
   first, which formula maps to which code, and why the tests give you
   confidence in the implementation.

   .. rubric:: Suggested Learning Order

   .. list-table::
      :header-rows: 1
      :widths: 18 44 38

      * - Step
        - What to understand first
        - Suggested reading
      * - 1
        - Leapfrog time staggering and the "advance velocity, then position" picture.
        - "Core Mental Model" below.
      * - 2
        - One full Cartesian Boris velocity push (``v_neg → v_prime → v_pos``).
        - :doc:`A01_Boris_3Dxyz <A01_Boris_3Dxyz>` and the API page of ``sub_A01_Boris_3Dxyz``.
      * - 3
        - How to call the pushers and integrate them into your own code.
        - :doc:`Pusher Usage Cookbook <pusher_usage_cookbook>`
      * - 4
        - What is genuinely different in cylindrical ``(r,\theta,z)``: position update and field components both depend on ``\theta``.
        - :doc:`A02_Boris_3Drtz <A02_Boris_3Drtz>` and its test page
          :doc:`A02 tests </tests/002_pusher/A02_Boris_3Drtz>`.
      * - 5
        - Relativistic Higuera-Cary: when Boris must be dropped, the extra steps in HC, and the payoff at high ``\gamma``.
        - :doc:`A03_Higuera_Cary_relativistic_3Dxyz <A03_Higuera_Cary_relativistic_3Dxyz>`
          and its test page :doc:`A03 tests </tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz>`.
      * - 6
        - How the four canonical cases (gyro, pure E acceleration, ExB, ExB drift) provide validation coverage.
        - :doc:`Pusher Testing Guide <pusher_testing_guide>`
          and :doc:`002_pusher tests </tests/002_pusher/index>`.

   .. rubric:: Core Mental Model

   Every ``A_Pusher`` routine does the same thing: advance a single
   particle's state from :math:`t^n` to :math:`t^{n+1}`. In a full PIC loop
   the caller owns particle arrays, field interpolation, current deposition,
   boundary handling, and the time loop; the pusher itself does one in-place
   state update.

   - **Leapfrog staggering.** Boris-family methods place velocity at the
     half time step :math:`v^{n-1/2}` and position at the integer step
     :math:`x^n`. The ``v`` you pass in is physically ``v^{n-1/2}``; the
     returned value is ``v^{n+1/2}``.
   - **Boris rotation in three steps.** With nonzero ``B``: a half-step
     electric kick (``v_neg``), a magnetic rotation
     (``v_prime → v_pos``), then another half-step electric kick. The
     ``E`` kick and ``B`` rotation are **operator-split** to second order.
   - **k is the Boris parameter.** All A_Pusher interfaces want
     ``k = q\Delta t / (2m)``, not ``q/m`` and not ``q\Delta t / m``. It
     bundles "half kick" and "half rotation" into one number.
   - **Where the position update lives differs.** A01/A03 only update ``v``,
     so the caller writes ``r = r + v*dt``; A02 advances position inside the
     routine because the cylindrical position update involves a ``\theta``
     rotation, not just addition.
   - **Fields are evaluated at the particle position.** The ``E``, ``B``
     inputs are the **values at the current particle position**, not grid
     arrays. Interpolating from the grid to the particle position is the job
     of the gather operator (``C_Gather``), not the pusher.
   - **Stability is the caller's problem.** ``\omega_c \Delta t \ll 1`` is
     the Boris stability-and-accuracy condition (:math:`\omega_c = qB/m`).
     Passing a too-large ``dt`` produces no error; it just introduces
     rotation-angle errors.

   .. rubric:: Common Beginner Traps

   - **k ≠ qm/2 ≠ q*dt/m.** If ``qm`` or ``dt`` changes between steps,
     ``k`` must be recomputed (``k = 0.5*qm*dt``). A common mistake is
     caching ``k`` as a constant.
   - **A01 and A02 have different interfaces.** After
     ``sub_A01_Boris_3Dxyz(v, E, B, k)`` the caller **must** add
     ``r = r + v*dt``; after
     ``sub_A02_Boris_3Drtz_push_v_x(x, v, E, B, k, dt)`` the position is
     already updated and **must not** be added again.
   - **Cylindrical field components depend on θ.** A uniform Cartesian
     ``E_x`` becomes ``E_r = E_x\cos\theta``, ``E_\phi = -E_x\sin\theta``
     in cylindrical components, **recomputed every step**. Passing Cartesian
     components to A02 will produce a wrong trajectory.
   - **A03 converts proper velocity internally while keeping a lab-velocity interface.**
     It converts ``v`` to proper velocity ``\gamma v`` internally; the interface still
     accepts and returns lab velocity ``v``.
     The initial-value convention is the same as Boris — no manual conversion
     is needed.
   - **r = 0 is a coordinate singularity.** A02's routine uses a
     ``tiny(1.0_4)`` fallback, but callers should avoid pushing particles
     truly close to ``r = 0``; ``\theta`` is discontinuous there.

   .. rubric:: Suggested Exercises

   1. Work through the three Boris rotation steps on paper and verify each
      step uses only the previous step's output, **not** an analytic
      expansion of ``\sin\omega\Delta t``.
   2. Run :doc:`A01 tests </tests/002_pusher/A01_Boris_3Dxyz>` case 1, plot
      the ``x-y`` trajectory and ``v^2(t)``, and confirm ``v^2`` is conserved.
   3. Re-run with ``dt`` doubled and watch ``v^2`` stay conserved (it
      should) while the position error grows; that is Boris's "exact speed,
      slightly wrong angle" behavior.
   4. Run A02 case 1 and compare the maximum position error against A01 —
      they should match, because the cylindrical Boris is physically
      equivalent to the Cartesian Boris.
   5. Run A03 case 2 (high-``\gamma`` ExB drift). Non-relativistic Boris
      drifts by several thousand under the same setup; HC produces
      ``x \approx 0``. That is the canonical example of when you must
      switch to the relativistic pusher.
