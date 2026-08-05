=====================
Pusher Usage Cookbook
=====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这页解决什么问题

   本页面面向 **已经把 A_Pusher 模块编译进自己代码**、要在 PIC 循环里调用推进器的开发者。
   它说明怎么选模块、调用方需要负责什么、最小时间步循环长什么样、相对论场景何时
   切换到 HC，以及常见集成错误。它不重复 :doc:`Learning Path <pusher_learning_path>`
   里的理论，也不替代每个 routine 自己的 API 页。

   .. rubric:: 先选哪个模块

   .. list-table::
      :header-rows: 1
      :widths: 14 20 24 42

      * - 模块
        - 坐标
        - 物理范围
        - 何时选它
      * - :doc:`A01 <A01_Boris_3Dxyz>`
        - Cartesian ``(x,y,z)``
        - 非相对论
        - 默认选择。粒子速度 ``v \ll c``，几何天然 Cartesian（如 3D 直角网格）。
      * - :doc:`A02 <A02_Boris_3Drtz>`
        - 柱坐标 ``(r,\theta,z)``
        - 非相对论
        - 几何天然柱对称（如圆柱腔、聚焦束流、等离子柱）；粒子在 ``r=0``
          附近也走 ``r,\theta`` 网格而不是临时转 Cartesian。
      * - :doc:`A03 <A03_Higuera_Cary_relativistic_3Dxyz>`
        - Cartesian ``(x,y,z)``
        - 相对论
        - 任何工况下 ``\gamma`` 显著大于 1，或 ``v_\perp/c`` 接近 1。
          相对论 ExB drift、激光-等离子相互作用、加速器束流都要走这条。

   选型判据：

   - 先按 **几何** 确定 Cartesian 还是 cylindrical。
   - 在 Cartesian 里再按 **最大 γ** 决定 Boris (A01) 还是 HC (A03)：
     若 ``\gamma_\text{max} - 1 > 0.01`` 就该认真考虑 A03。
   - 当前没有"相对论柱坐标 pusher"。需要时，请走 A02 做几何外推 + 在调用方
     侧自己做 ``\gamma`` 缩放，或上报需求。

   .. rubric:: 调用方必须负责的事情

   推进器是无状态的；它 **只** 做一次状态更新。下面这些必须由调用方组织好：

   1. **初值时间约定**。把 ``v`` 时间约定调到 ``v^{n-1/2}`` 而不是 ``v^n``。
      初始化时常用半步回拉：用 ``E^0, B^0`` 反向做一次"半步推进"。
   2. **Boris 参数 k**。每个时间步都计算 ``k = 0.5*qm*dt``。``qm`` 和 ``dt``
      改了要重算；不要把 ``k`` 当常数缓存。
   3. **场在粒子位置的取值**。用 gather 算子从网格插值，得到 ``E``、``B``
      在当前粒子位置的值。对 A02，还要把 Cartesian 场分量按当前 ``\theta``
      转换成柱坐标分量。
   4. **位置更新归属**。

      - A01 / A03：调用方在 routine 后写 ``r = r + v*dt``。
      - A02：routine 内部已完成，不要再加一次。
   5. **边界处理**。出界粒子的反射、周期 wrap、吸收等都不在推进器里。
   6. **诊断和守恒检查**。``v^2`` 守恒（Boris）或 ``\gamma`` 守恒
      （HC 在纯磁场下）由调用方测试；推进器不自检。

   .. rubric:: 编译和精度

   - 默认编译命令（跟测试目录里一致）：

     .. code-block:: bash

        gfortran -cpp -O3 -fdefault-real-8 main.f90

   - ``-fdefault-real-8`` 把所有 ``real`` 提升到 8 字节。强烈建议在 PIC
     生产代码里也开这个，否则 case 04 这种"刚好抵消"的算例会被舍入误差吃掉。
   - 推进器源码使用 Fortran 默认 ``real``，跨编译器没有显式 KIND 假设；
     用 Intel ifort、NVIDIA nvfortran 都能直接编。
   - 没有外部依赖，不需要链接 BLAS / FFTW / MPI。

   .. rubric:: 最小时间步结构

   伪代码骨架，所有 A_Pusher routine 通用：

   .. code-block:: text

      ! 一次时间步推进，针对一个粒子 p
      compute_field_at_particle(x_p, E_p, B_p)        ! gather: 网格 → 粒子
      k = 0.5*qm*dt                                    ! Boris 参数

      ! ---- 速度推进 ----
      if    (rel.and.cartesian) call sub_A03_HC_relativistic_3Dxyz(v_p, E_p, B_p, k)
      else if (.not.rel.and.cyl)  call sub_A02_Boris_3Drtz_push_v_x(x_p, v_p, E_p, B_p, k, dt)
      else                        call sub_A01_Boris_3Dxyz(v_p, E_p, B_p, k)

      ! ---- 位置推进（仅 A01 / A03） ----
      if (.not.(.not.rel.and.cyl)) then
          x_p = x_p + v_p*dt
      end if

      ! ---- 边界 / 诊断 / 沉积 ----
      apply_boundary(x_p, v_p)
      deposit_current(x_p, v_p)

   一些注释：

   - 真实代码会按 ``np`` 数组遍历（不是按粒子写循环），并把 ``k`` 提到外层算一次。
   - ``compute_field_at_particle`` 通常是 ``C_Gather`` 模块；本页不展开。
   - ``deposit_current`` 是 ``B_Scatter`` （参考
     :doc:`/rst_files/B_Scatter/scatter_testing_guide` ）；当前 A01-A03 都假设
     场为外部输入、不与粒子自洽，所以仅做单粒子测试时可省略。

   .. rubric:: 相对论场景的额外考虑

   非相对论 Boris (A01/A02) 在 ``\gamma`` 显著大于 1 时不正确——
   不是数值精度问题，而是物理上不对：磁场旋转角度直接用 ``q\Delta t / m`` 计算，
   没有 ``1/\gamma`` 因子。常见症状：

   - 高 ``\gamma`` 的 ExB drift 工况：分析上 ``\mathbf{E} + \mathbf{v}\times\mathbf{B} = 0``
     时粒子应该走直线，但 A01 会偏移几千倍粒子半径。
   - 激光场里的 8 字形振荡幅度被低估。

   切换到 A03 后：

   - 输入和返回值仍为 **lab velocity** :math:`\mathbf{v}`；A03 内部自行完成
     :math:`\mathbf{v} \to \mathbf{u} = \gamma\mathbf{v}` 的转换，调用方无需处理。
   - 位置更新与 A01 相同：``r = r + v*dt``，``v`` 即 A03 返回的 lab velocity，
     无需额外换算。
   - 守恒判据从 ``v^2`` 改为 ``|u|^2`` （在纯 B 场下）。
   - HC 比 Boris 多出 ``\gamma`` 求平方根步，但跟磁场旋转运算相比开销可忽略。

   切回 A01 的代价：HC 在低 ``\gamma`` 退化为 Boris，结果几乎相同。
   所以 **统一用 A03 是安全的**，区别只是极低 ``\gamma`` 下的常数开销。

   .. rubric:: 常见集成错误

   - ``k`` **缓存了旧 dt**。把 ``k`` 当全局常数，``dt`` 在自适应步长里变了
     却没重算——推进结果会按 ``dt`` 比例失真。
   - **A01 后忘了位置更新** ``r = r + v*dt``。粒子位置永远停在初值，``v`` 在变。
     现象：速度变化合理，但轨迹完全不动。
   - **A02 后又做了一次位置更新** ``r = r + v*dt``。位置被推进了两次，
     量值上看不出"两倍"，因为 A02 内部用的是柱坐标几何而不是简单加法，
     但轨迹会明显偏离解析解。
   - **A02 直接传 Cartesian 场分量**。粒子离 ``\theta = 0`` 越远，
     轨迹越离谱。改成每步重算
     ``E_r = E_x\cos\theta + E_y\sin\theta``、
     ``E_\phi = -E_x\sin\theta + E_y\cos\theta``。
   - **A03 初始化时误传 proper velocity** ``u = γv``。high-``\gamma`` 工况下结果会偏
     ``\gamma`` 倍。正确做法是传入 lab velocity ``v``；
     :math:`\gamma\mathbf{v}` 的转换由 routine 内部完成。
   - ``-fdefault-real-8`` **没开**。case 04 那种"E + v×B 严格抵消"的算例
     会因为单精度舍入误差里出现寄生 drift。

.. container:: ap-lang ap-lang-en

   .. rubric:: What This Page Is For

   This page targets developers who have already built ``A_Pusher`` into
   their own code and need to call the pushers inside a PIC loop. It covers
   how to choose a module, what the caller owns, the minimal time-step
   shape, when to switch to HC for relativistic cases, and common
   integration mistakes. It does not repeat the theory from
   :doc:`Learning Path <pusher_learning_path>` and does not replace each
   routine's API page.

   .. rubric:: Choose the Module First

   .. list-table::
      :header-rows: 1
      :widths: 14 20 24 42

      * - Module
        - Coordinates
        - Physical range
        - When to pick it
      * - :doc:`A01 <A01_Boris_3Dxyz>`
        - Cartesian ``(x,y,z)``
        - Non-relativistic
        - Default. Particle speed ``v \ll c`` and geometry is naturally
          Cartesian (e.g. 3D rectilinear grid).
      * - :doc:`A02 <A02_Boris_3Drtz>`
        - Cylindrical ``(r,\theta,z)``
        - Non-relativistic
        - Geometry is naturally cylindrical (cavities, focused beams,
          plasma columns) and particles must remain on the ``r,\theta`` grid
          even near ``r = 0`` rather than being transiently Cartesian.
      * - :doc:`A03 <A03_Higuera_Cary_relativistic_3Dxyz>`
        - Cartesian ``(x,y,z)``
        - Relativistic
        - Any setup where ``\gamma`` is appreciably greater than 1 or
          ``v_\perp/c`` is near 1: relativistic ExB drifts,
          laser-plasma interaction, accelerator beams.

   Selection rules of thumb:

   - First choose Cartesian vs cylindrical by **geometry**.
   - Inside Cartesian, pick Boris (A01) vs HC (A03) by **maximum γ**: if
     ``\gamma_\text{max} - 1 > 0.01`` you should seriously consider A03.
   - There is no relativistic cylindrical pusher today. If you need one,
     use A02 with caller-side ``\gamma`` corrections or open an issue.

   .. rubric:: What the Caller Owns

   The pushers are stateless; they perform **exactly one** state update. The
   caller is responsible for everything else:

   1. **Initial time convention.** Make sure ``v`` is on the half step
      ``v^{n-1/2}``, not on ``v^n``. The usual trick at initialization is a
      backward half-step push using ``E^0`` and ``B^0``.
   2. **Boris parameter k.** Compute ``k = 0.5*qm*dt`` every step. If
      ``qm`` or ``dt`` changes, recompute it; don't cache.
   3. **Field at the particle position.** Use a gather operator to
      interpolate ``E`` and ``B`` from the grid to the current particle
      position. For A02 you must also convert Cartesian field components to
      cylindrical components at the current ``\theta``.
   4. **Position update ownership.**

      - A01 / A03: the caller writes ``r = r + v*dt`` after the call.
      - A02: the routine already updates ``r``; **do not** add another
        position step.
   5. **Boundary handling.** Reflection, periodic wrap, and absorption of
      out-of-domain particles are not inside the pusher.
   6. **Diagnostics and conservation checks.** ``v^2`` conservation (Boris)
      and ``\gamma`` conservation in pure magnetic fields (HC) are
      caller-side tests; the pushers do not self-check.

   .. rubric:: Compilation and Precision

   - Default command line (matches what the test directories use):

     .. code-block:: bash

        gfortran -cpp -O3 -fdefault-real-8 main.f90

   - ``-fdefault-real-8`` promotes every ``real`` to 8 bytes. **Strongly
     recommended** for production PIC code; without it, balanced cases like
     case 04 (``E + v×B = 0``) develop a spurious drift from single-precision
     rounding.
   - The pusher source uses Fortran default ``real`` with no implicit KIND
     assumptions; ifort, nvfortran etc. should compile out of the box.
   - No external dependencies — no BLAS, FFTW, or MPI required.

   .. rubric:: Minimal Time-Step Structure

   Pseudo-code skeleton, shared by all A_Pusher routines:

   .. code-block:: text

      ! One time step for particle p
      compute_field_at_particle(x_p, E_p, B_p)        ! gather: grid → particle
      k = 0.5*qm*dt                                    ! Boris parameter

      ! ---- Velocity push ----
      if    (rel.and.cartesian) call sub_A03_HC_relativistic_3Dxyz(v_p, E_p, B_p, k)
      else if (.not.rel.and.cyl)  call sub_A02_Boris_3Drtz_push_v_x(x_p, v_p, E_p, B_p, k, dt)
      else                        call sub_A01_Boris_3Dxyz(v_p, E_p, B_p, k)

      ! ---- Position push (A01 / A03 only) ----
      if (.not.(.not.rel.and.cyl)) then
          x_p = x_p + v_p*dt
      end if

      ! ---- Boundary / diagnostics / deposition ----
      apply_boundary(x_p, v_p)
      deposit_current(x_p, v_p)

   Notes:

   - Production code loops over ``np`` particles in arrays (not particle by
     particle) and hoists ``k`` out of the inner loop.
   - ``compute_field_at_particle`` is the ``C_Gather`` module's job and is
     not expanded here.
   - ``deposit_current`` is the ``B_Scatter`` module (see
     :doc:`/rst_files/B_Scatter/scatter_testing_guide`); A01-A03 assume the
     field is externally supplied and not self-consistent with the
     particles, so single-particle tests can skip the deposition step.

   .. rubric:: Relativistic Considerations

   Non-relativistic Boris (A01/A02) becomes **wrong** at non-trivial
   ``\gamma`` — not in numerical accuracy but in physics: the magnetic
   rotation angle uses ``q\Delta t / m`` directly without the ``1/\gamma``
   factor. Typical symptoms:

   - In high-``\gamma`` ExB drift, where
     ``\mathbf{E} + \mathbf{v}\times\mathbf{B} = 0`` should give a straight
     line, A01 drifts by thousands of gyroradii.
   - The figure-8 amplitude inside a laser field is under-estimated.

   Switching to A03:

   - The ``v`` input and return value remain **lab velocity**
     :math:`\mathbf{v}`; A03 handles the
     :math:`\mathbf{v} \to \mathbf{u} = \gamma\mathbf{v}` conversion
     internally, so the caller needs no extra step.
   - The position update is identical to A01: ``r = r + v*dt``, where ``v``
     is the lab velocity returned by A03.
   - The conservation diagnostic changes from ``v^2`` to ``|u|^2`` in pure
     magnetic fields.
   - HC adds one square-root step compared to Boris, but it's negligible
     against the rotation arithmetic.

   The cost of staying on A03 at low ``\gamma``: HC degenerates to Boris
   and the result is essentially identical. **Using A03 uniformly is
   safe**, the only penalty is a tiny constant overhead at very low
   ``\gamma``.

   .. rubric:: Common Integration Mistakes

   - **k cached with stale dt.** Treating ``k`` as a global constant while
     ``dt`` varies under an adaptive scheme — the push scales wrong by the
     ``dt`` ratio.
   - **Forgot the position update after A01:** ``r = r + v*dt``. Position never moves while
     ``v`` evolves. Symptom: velocities look fine, trajectory frozen.
   - **Added another position update after A02:** ``r = r + v*dt``. Position is advanced twice.
     The factor isn't a clean 2× because A02's internal step uses
     cylindrical geometry, but the trajectory clearly diverges from the
     analytic answer.
   - **Passing Cartesian field components to A02.** The further from
     ``\theta = 0``, the wronger the trajectory. Recompute
     ``E_r = E_x\cos\theta + E_y\sin\theta``,
     ``E_\phi = -E_x\sin\theta + E_y\cos\theta`` every step.
   - **Passing proper velocity to A03:** ``u = γv``. At high ``\gamma`` the
     result is off by a factor ``\gamma``. A03 accepts lab velocity ``v``
     and handles the conversion internally — initialise with ``v``, not
     ``u = γv``.
   - ``-fdefault-real-8`` **not enabled.** Single-precision rounding kills
     the cancellation in cases like case 04 (``E + v×B = 0``) and produces
     a spurious drift.
