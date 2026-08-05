====================
Pusher Testing Guide
====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 1. 范围

   本指南概述 AlgoPlasma 中 ``A_Pusher`` 模块的验证方式、测试算例位置、推荐运行顺序
   和结果解读。如果只想看目录式测试入口，可先看
   :doc:`/tests/002_pusher/index`。

   当前覆盖：

   - **A01** ``sub_A01_Boris_3Dxyz``：非相对论 3D Cartesian Boris 速度推进。
   - **A02** ``sub_A02_Boris_3Drtz_push_v_x``：非相对论柱坐标 ``(r,\theta,z)``
     Boris 推进（同时更新位置和速度）。
   - **A03** ``sub_A03_Higuera_Cary_relativistic_3Dxyz``：相对论 Higuera-Cary
     Cartesian 速度推进。

   除非各 case 的 README 明确说明，这些测试 **不** 覆盖：

   - 多粒子相互作用 / 自洽场
   - 边界条件、注入和吸收
   - 与场求解器 / scatter / gather 的联动

   每个测试都把粒子放在已知解析解的均匀场里，对单粒子做长时间推进、跟解析解
   逐时步比较位置和速度误差。

   .. rubric:: 2. 测试矩阵

   - ``tests/002_pusher/A01_Boris_3Dxyz``
     A01 的四个参考算例（case 01 gyro / 02 Eonly / 03 ExB / 04 ExB drift），
     输出 ``build/case*.dat`` 和 ``figs_cases/*.png``。
     详见 :doc:`A01 测试 </tests/002_pusher/A01_Boris_3Dxyz>`。

   - ``tests/002_pusher/A02_Boris_3Drtz``
     A02 的四个算例，与 A01 在物理参数上对齐，
     每步把 Cartesian 场分量按 ``\theta`` 转成柱坐标分量后再传给推进器，
     输出模拟的柱坐标状态转回 Cartesian 后跟 A01 同款解析解逐分量比较。
     详见 :doc:`A02 测试 </tests/002_pusher/A02_Boris_3Drtz>`。

   - ``tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz``
     A03 的三个相对论算例：相对论 gyro（``\gamma \approx 2.3``）、高 ``\gamma``
     ExB drift 在 ``\gamma = 20`` 下的"力为零"测试、以及 WarpX 参考工况下的
     ExB drift 对照。详见 :doc:`A03 测试 </tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz>`。

   .. rubric:: 3. 快速运行命令

   每个测试目录都用同一套 ``clean.sh / make.sh / run.sh / plot.sh`` 入口：

   .. code-block:: bash

      cd tests/002_pusher/A01_Boris_3Dxyz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

      cd ../A02_Boris_3Drtz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

      cd ../A03_Higuera_Cary_relativistic_3Dxyz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   ``run.sh`` 在终端打印每个 case 的 ``max|v - v_ana|`` 和 ``max|r - r_ana|``；
   ``plot.sh`` 把轨迹图保存到 ``figs_cases/``。

   .. rubric:: 4. 建议验证顺序

   首次接触建议按以下顺序排查：

   1. **A01 case 01 (gyro)**：跑完看 ``case01_gyro_v2_t.png``，
      ``v^2`` 应在浮点误差内守恒；``case01_gyro_traj_xy.png`` 数值圆和解析圆应重合。
   2. **A01 case 02 (Eonly)**：匀加速 1D 运动，对照解析的 ``x(t)``。
      ``max|v|`` 误差应到机器精度（实测 ~1e-13）。
   3. **A01 case 03/04 (ExB)**：摆线轨迹和纯 drift，确认 Boris 在
      正交 E、B 下的物理图像。case 04 的 ``max|r|`` 应到 ~1e-6
      （E + v×B 严格抵消时的舍入级别）。
   4. **A02 case 01-04**：和 A01 同款物理参数。跑完后逐 case 对比
      ``max|r - r_ana|``，应与 A01 完全一致——这是柱坐标 Boris 物理等价的最强信号。
   5. **A03 case 01 (相对论 gyro)**：gamma 约为 2.3，
      验证 HC 在相对论圆周运动下保持 u 的模长守恒。
   6. A03 case 02（高 gamma ExB drift）：gamma = 20，E + v×B = 0。
      HC 给出 x 约为 0（漂移为零）；同工况下 Boris 会偏出 ~2321。
      这是判断"必须切到 HC"的关键算例。
   7. **A03 case 03 (WarpX 对照)**：与 WarpX 内置 HC 单元测试对齐的工况，
      用于跨实现回归。

   .. rubric:: 5. 结果解读

   - **位置误差 vs 速度误差不对称**。Boris 在 gyro case 里
     ``max|v|`` 通常 ~1e-7、``max|r|`` 却到 ~1e5——并不是 bug。
     位置误差量级 ≈ 相对位置误差 × 轨道半径；A01/A02 case 1 的
     ``r_L = v_0/\omega = 2 \times 10^7``，所以 0.5% 的相对位置误差
     就是 ~1e5 绝对值。
   - **A02 跟 A01 应该完全一致**。位置误差 **逐 case 相等** 意味着柱坐标
     Boris 没有引入额外物理偏差；如果某个 case 误差比 A01 大一个数量级，
     先怀疑场分量没正确从 Cartesian 转成 cylindrical。
   - **case 1 速度误差差异（A02 略大于 A01）是正常的**。柱坐标 Boris 多了
     ``cos / sin / sqrt / atan2``，引入额外舍入。差异在 ~10 倍以内属正常。
   - A03 case 02 是"判别相对论必要性"的金标准。如果你的代码在
     ``\gamma = 20`` 的 ExB 工况下用 Boris 给出 ``x \sim 2000``，
     不是 bug 是物理上不对，必须切到 A03。
   - ``v^2`` / ``|u|^2`` 守恒：Boris 在纯 ``B`` 场下应严格守恒 ``v^2``；
     HC 在纯 ``B`` 场下应守恒 ``|u|^2 = (\gamma v)^2``。如果在你的代码里
     看到漂移，先看 E 场是不是真的为零。

   .. rubric:: 6. 说明

   - 三个测试目录的输出格式都一致：

     .. code-block:: text

        step, t, x, y, z, vx, vy, vz, v2, x_ana, y_ana, z_ana, vx_ana, vy_ana, vz_ana, err_v, err_r

     所以 A02 和 A01 共用同一份 ``plot_savefig.py``。A03 在 ``v2`` 列填
     ``\gamma`` 或 ``|u|^2`` （按 case 不同），其它列含义保持一致。
   - 静态参考图已经放在 ``docs/source/images/tests/002_pusher/``，
     在不重跑测试时也能看见。改完测试程序或 pusher 算法后记得重画并同步。
   - 这套测试 **只验证单粒子**。把多粒子、自洽场和长时间数值稳定性纳入回归，
     需要在 :doc:`002_pusher tests </tests/002_pusher/index>` 之外
     单独建测试套件——当前还没有。

.. container:: ap-lang ap-lang-en

   .. rubric:: 1. Scope

   This guide summarises how ``A_Pusher`` modules are validated in AlgoPlasma,
   where the test cases live, the recommended run order, and how to read
   the results. For the directory-oriented entry point, see
   :doc:`/tests/002_pusher/index`.

   Currently covered:

   - **A01** ``sub_A01_Boris_3Dxyz``: non-relativistic 3D Cartesian Boris
     velocity push.
   - **A02** ``sub_A02_Boris_3Drtz_push_v_x``: non-relativistic
     cylindrical ``(r,\theta,z)`` Boris push (advances both position and
     velocity).
   - **A03** ``sub_A03_Higuera_Cary_relativistic_3Dxyz``: relativistic
     Higuera-Cary Cartesian velocity push.

   Unless individual READMEs say otherwise, these suites do **not** cover:

   - Multi-particle interaction or self-consistent fields
   - Boundary conditions, injection, or absorption
   - Coupling to the field solver, scatter, or gather

   Each test places a single particle in a uniform field with a known
   analytic solution, advances it for many steps, and compares position and
   velocity against the analytic answer step by step.

   .. rubric:: 2. Test Matrix

   - ``tests/002_pusher/A01_Boris_3Dxyz``
     A01's four reference cases (case 01 gyro / 02 Eonly / 03 ExB / 04 ExB
     drift). Outputs ``build/case*.dat`` and ``figs_cases/*.png``. See
     :doc:`A01 tests </tests/002_pusher/A01_Boris_3Dxyz>`.

   - ``tests/002_pusher/A02_Boris_3Drtz``
     Four A02 cases, parameter-aligned with A01. Cartesian field components
     are **recomputed in cylindrical at every step** before being passed in;
     the simulated cylindrical state is converted back to Cartesian before
     comparison against the same analytic solutions as A01. See
     :doc:`A02 tests </tests/002_pusher/A02_Boris_3Drtz>`.

   - ``tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz``
     Three relativistic cases for A03: relativistic gyro
     (``\gamma \approx 2.3``), the "force-free" high-``\gamma`` ExB drift
     at ``\gamma = 20``, and a cross-implementation ExB drift matched to
     WarpX's HC unit test. See
     :doc:`A03 tests </tests/002_pusher/A03_Higuera_Cary_relativistic_3Dxyz>`.

   .. rubric:: 3. Quick Run Commands

   Every test directory uses the same ``clean.sh / make.sh / run.sh /
   plot.sh`` entry points:

   .. code-block:: bash

      cd tests/002_pusher/A01_Boris_3Dxyz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

      cd ../A02_Boris_3Drtz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

      cd ../A03_Higuera_Cary_relativistic_3Dxyz
      bash clean.sh && bash make.sh && bash run.sh && bash plot.sh

   ``run.sh`` prints ``max|v - v_ana|`` and ``max|r - r_ana|`` per case to
   the terminal; ``plot.sh`` saves trajectory figures into ``figs_cases/``.

   .. rubric:: 4. Suggested Validation Order

   On first contact, work through the cases in this order:

   1. **A01 case 01 (gyro)**: check ``case01_gyro_v2_t.png`` shows ``v^2``
      conserved to floating-point precision; ``case01_gyro_traj_xy.png``
      should overlay numeric and analytic circles.
   2. **A01 case 02 (Eonly)**: constant acceleration in 1D against the
      analytic ``x(t)``. ``max|v|`` error should reach machine precision
      (~1e-13 in practice).
   3. **A01 case 03/04 (ExB)**: cycloid and pure drift, confirming Boris's
      behaviour in orthogonal E, B. Case 04 ``max|r|`` should reach ~1e-6
      (the rounding floor when ``E + v×B`` cancels exactly).
   4. **A02 cases 01-04**: identical physical parameters to A01. After
      running, compare ``max|r - r_ana|`` **case by case** with A01 — they
      should match exactly; that is the strongest signal that the
      cylindrical Boris is physically equivalent to the Cartesian one.
   5. **A03 case 01 (relativistic gyro)**: ``\gamma \approx 2.3``, verifying
      that HC conserves ``|u|`` in relativistic circular motion.
   6. **A03 case 02 (high-γ ExB drift)**: ``\gamma = 20``, with
      ``E + v×B = 0``. HC gives ``x \approx 0`` (drift cancelled); Boris on
      the same setup drifts by ~2321. This is the key case for deciding
      "must switch to HC".
   7. **A03 case 03 (WarpX cross-check)**: parameters chosen to match
      WarpX's built-in HC unit test, providing a cross-implementation
      regression.

   .. rubric:: 5. Result Interpretation

   - **Position-error magnitude is not velocity-error magnitude.** Boris on
     the gyro case typically gives ``max|v| ~ 1e-7`` but ``max|r| ~ 1e5`` —
     that is not a bug. Absolute position error ≈ relative position error
     × orbit radius; in A01/A02 case 1 the gyroradius is
     ``r_L = v_0/\omega = 2 \times 10^7``, so a 0.5% relative error is
     ~1e5 absolute.
   - **A02 and A01 should match exactly.** Equal case-by-case position
     errors mean the cylindrical Boris introduces no extra physical bias.
     If a single case differs by an order of magnitude, suspect that the
     Cartesian field components weren't converted to cylindrical correctly.
   - **Slightly larger A02 velocity error in case 1 is normal.** The
     cylindrical Boris involves extra ``cos / sin / sqrt / atan2`` and
     therefore extra rounding. Differences within ~10× are normal.
   - **A03 case 02 is the gold standard for relativistic necessity.** If
     your code's Boris pusher drifts to ``x ~ 2000`` in the
     ``\gamma = 20`` ExB setup, that is not a bug — it is physically
     wrong, and you **must** switch to A03.
   - ``v^2`` / ``|u|^2`` **conservation.** Boris must conserve ``v^2``
     exactly in pure ``B``; HC must conserve ``|u|^2 = (\gamma v)^2`` in
     pure ``B``. If your code shows drift here, first check that the E
     field is really zero.

   .. rubric:: 6. Notes

   - The three test directories share the same output column layout:
     ``step, t, x, y, z, vx, vy, vz, v2, x_ana, y_ana, z_ana, vx_ana,
     vy_ana, vz_ana, err_v, err_r``. That's why A02 reuses A01's
     ``plot_savefig.py`` verbatim. A03 stores ``\gamma`` or ``|u|^2`` in
     the ``v2`` column depending on the case; everything else is consistent.
   - Static reference figures live under
     ``docs/source/images/tests/002_pusher/`` so they render even when the
     tests aren't re-run. Remember to refresh them after changing a test
     program or pusher algorithm.
   - These suites **validate only single-particle motion.** Bringing
     multi-particle dynamics, self-consistent fields, and long-time
     stability under regression coverage requires a separate test suite
     outside :doc:`002_pusher tests </tests/002_pusher/index>`, which does
     not exist yet.
