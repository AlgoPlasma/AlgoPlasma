Plasma Waves
============

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 等离子体波：从观察开始

   从等离子体本身出发，一步步认识扰动、粒子运动和波动。
   每个专题独立展开，用动画观察物理图像，再逐步建立概念与模型。

   .. rubric:: 第一部分 · 波的基础

   **第 1 页：波来了，电子去哪儿了？**

   这一页只关注一个问题：电子的运动，与疏密图样的移动，是同一件事吗？
   无需预先学习色散关系或波动方程。

   .. raw:: html

      <p><a class="reference external" href="../../_static/plasma_waves/01_what_moves.html?lang=zh"
      style="display:inline-block;padding:14px 24px;background:#214e3a;color:#fff;border-radius:5px;font-size:20px;text-decoration:none;">开始观察 →</a></p>

   页面从均匀点阵开始。点击画面或右下角按钮，依次观察电子运动、追踪单个电子、
   标出密集区域，最后比较两种运动。方向键左右可前进或返回，空格继续，
   ``F`` 切换全屏，``P`` 暂停或播放。最后一步可重新播放整页。
   幻灯片右上角可随时切换中文或英文，保留当前讲解步骤与动画状态。

   绿色点代表电子，蓝色加号代表固定离子背景。图中省略热运动，
   点阵不代表晶格；这是减速的集体位移示意，不是粒子模拟结果。
   本页展示密度图样的相位运动，尚不讨论波包或能量输运速度。

   .. rubric:: 不播放动画时，也可以这样理解

   固定追踪一个电子，它只在平衡位置附近往复运动。
   再观察电子较密集的区域，这个区域随时间向右移动。
   不同位置电子的有序位移，可以组成移动的密度图样。
   **粒子的局部运动与波的图样运动需要分别观察。**

   .. rubric:: 第 2 页 · 电子为什么会来回运动？

   接着用电子层相对离子背景整体位移的平板模型，依次观察电荷分离、电场方向、
   电子受力和释放后的往复运动。先预测方向，再点击揭示箭头；最后观察电子
   穿过平衡位置时为什么不会立刻停下。本页先建立物理图像，暂不展开频率推导。

   .. raw:: html

      <p><a class="reference external" href="../../_static/plasma_waves/02_why_oscillates.html?lang=zh"
      style="display:inline-block;padding:14px 24px;background:#214e3a;color:#fff;border-radius:5px;font-size:20px;text-decoration:none;">进入第二页 →</a></p>

   这是无磁、冷电子、固定离子的简化平板模型，不模拟整列波的空间传播。
   **电场力指向平衡位置；惯性使电子越过平衡位置。**
   电子越过原位后，电场和恢复力反向。未计碰撞等阻尼时，模型中的振荡持续存在。

   .. rubric:: 第 3 页 · 怎样测量一列波？

   用同一列电子密度波完成三次测量：固定位置读周期，冻结时刻读波长，
   追踪同一个密度峰读相速度。由此连接 ``f = 1/T`` 和 ``v_ph = λ/T = λf``。
   探针测局部电子密度，图样的相速度与单个电子的速度分开讨论。

   .. raw:: html

      <p><a class="reference external" href="../../_static/plasma_waves/03_measuring_a_wave.html?lang=zh"
      style="display:inline-block;padding:14px 24px;background:#214e3a;color:#fff;border-radius:5px;font-size:20px;text-decoration:none;">进入第三页 →</a></p>

   不播放动画时：周期描述“多久重复”，波长描述“多远重复”。
   同一密度峰在一个周期内前进一个波长，因此相速度为波长除以周期。
   这里给定正弦密度波来说明运动学关系，不求解等离子体色散关系。

   .. rubric:: 第 4 页 · 不同位置，为什么不同时起伏？

   移动第二个探针，比较两处电子密度的时间曲线：相隔半波长反相，
   相隔一波长重新同相。把空间相位差与时间相位变化分别连接到波数
   ``k = 2π/λ`` 和角频率 ``ω = 2π/T``，再组成密度扰动的表达式
   ``δn = A cos(kx − ωt + φ₀)``。同相位点向右以 ``ω/k`` 移动。

   .. raw:: html

      <p><a class="reference external" href="../../_static/plasma_waves/04_phase.html?lang=zh"
      style="display:inline-block;padding:14px 24px;background:#214e3a;color:#fff;border-radius:5px;font-size:20px;text-decoration:none;">进入第四页 →</a></p>

   .. rubric:: 第 5 页 · 两列波相遇，会发生什么？

   从 ``δn = δn₁ + δn₂`` 出发，调相位观察增强和相消，再比较近频波的拍，
   最后观察同频等幅相向波形成的驻波。只叠加密度扰动，背景密度不重复相加。
   两选预测题配有反馈：密度节点处始终为零的是密度扰动，电子仍可穿过节点。

   .. raw:: html

      <p><a class="reference external" href="../../_static/plasma_waves/05_superposition.html?lang=zh"
      style="display:inline-block;padding:14px 24px;background:#214e3a;color:#fff;border-radius:5px;font-size:20px;text-decoration:none;">进入第五页 →</a></p>

   不播放动画时：同频等幅波同相时增强，反相时相消；拍频为两频率之差的绝对值。
   等频等幅相向波可以形成 ``δn = 2A cos(kx) cos(ωt)``，密度节点的位置固定。
   这些是线性叠加的给定波形示意，不是非线性相互作用或等离子体模拟结果。

   .. rubric:: 第 6 页 · 波为什么要用复数表示？

   从固定探针的实数密度信号出发，把它和复平面箭头的实轴投影连接起来。
   依次学习欧拉公式、复振幅、同频同波数的复振幅相加，以及平面波的微分。
   用初相位滑块改变波形，用相位差滑块预测增强与相消。

   .. raw:: html

      <p><a class="reference external" href="../../_static/plasma_waves/06_complex_waves.html?lang=zh"
      style="display:inline-block;padding:14px 24px;background:#214e3a;color:#fff;border-radius:5px;font-size:20px;text-decoration:none;">进入第六页 →</a></p>

   不播放动画时：令 ``ñ = n̂ exp[i(kx−ωt)]``、``n̂ = A exp(iφ₀)``，
   取 ``δn = Re{ñ}`` 恢复密度扰动，总密度为 ``n₀ + δn``。
   复平面两轴、复振幅和密度扰动均用 m⁻³，不是空间方向。
   固定探针处相位随时间减小，因此箭头顺时针转动。
   同一 k、ω 的波可以先相加常复振幅；相消为零时合成相位未定义。
   对这个常复振幅平面波，``∂ₜñ = −iωñ``、``∂ₓñ = ikñ``。
   图中用导数除以 ω 或 k 后的量比较相位，因而三种箭头单位一致。

   .. rubric:: 符号与单位

   .. list-table:: 前六页采用的 SI 单位
      :header-rows: 1
      :widths: 45 30 25

      * - 物理量
        - 符号
        - 单位
      * - 时间、周期
        - t, T, T₁
        - s
      * - 频率、拍频
        - f, f₁, f₂, f_beat
        - Hz
      * - 位置、位移、波长
        - x, Δx, λ
        - m
      * - 相速度、电子速度
        - v_ph, v_e
        - m/s
      * - 相位、相位差、初相位
        - φ, Δφ, φ₀
        - rad
      * - 波数
        - k
        - rad/m
      * - 角频率
        - ω
        - rad/s
      * - 数密度、密度扰动、实/复幅值
        - nₑ, n₀, δn, A, n̂, ñ
        - m⁻³
      * - 密度扰动的时间导数、空间导数
        - ∂ₜñ, ∂ₓñ
        - m⁻³/s；m⁻⁴
      * - 虚数单位、复指数
        - i, exp[i(kx−ωt)]
        - 1（无量纲）
      * - 电场、电子受力
        - E, F
        - V/m；N

   rad 在 SI 中量纲为一；保留 rad 是为了明确相位意义，区别 Hz 与 rad/s。
   指数或三角函数中的相位必须无量纲，因此 kx、ωt 和 φ₀ 应一致。
   本模块的 A 是密度扰动幅值，单位随被描述的物理量而定，不能一律写成 m。
   图以 λ、T、n₀ 为参考尺度（双波例使用 λ₁、T₁），未指定绝对 SI 数值；
   播放所用的秒数不等于物理周期。0.25λ 表示相对距离，不是 0.25 m。

.. container:: ap-lang ap-lang-en

   .. rubric:: Plasma waves: start with observation

   Start with the plasma itself and build an understanding of perturbations,
   particle motion and waves. Each topic stands on its own: observe a physical
   picture first, then develop the concepts and models needed to explain it.

   .. rubric:: Part 1 · Wave basics

   **Page 1: A wave passes. Where do the electrons go?**

   This page asks one question: is electron motion the same as motion of a density
   pattern? No prior knowledge of dispersion relations or wave equations is required.

   .. raw:: html

      <p><a class="reference external" href="../../_static/plasma_waves/01_what_moves.html?lang=en"
      style="display:inline-block;padding:14px 24px;background:#214e3a;color:#fff;border-radius:5px;font-size:20px;text-decoration:none;">Start observing →</a></p>

   Begin with a uniform dot array. Click the picture or the lower-right button
   to set electrons moving, follow one electron, highlight a dense region and
   compare the two motions. Left/right arrows go back/forward, Space continues,
   ``F`` toggles fullscreen and ``P`` pauses/plays. The last step offers a replay.
   Use the Chinese/EN switch at the top right to change language without resetting
   the current explanation step or animation state.

   Green dots represent electrons; blue plus signs represent fixed ions.
   Thermal motion is omitted, and the array is not a crystal lattice.
   This is a slowed collective-displacement illustration, not a particle-simulation
   result. It shows phase motion of a density pattern, not wave-packet or energy
   transport speed.

   .. rubric:: Text alternative

   Follow a particular electron: it oscillates near its equilibrium position.
   Then follow a dense region: that region moves to the right.
   Ordered displacements of electrons at different locations can form a moving
   density pattern. **Observe local particle motion and pattern motion separately.**

   .. rubric:: Page 2 · Why do electrons keep oscillating?

   Displace an electron layer relative to a fixed ion background. Reveal charge
   separation, field direction and electron force, then release the layer.
   Predict each direction before revealing its arrow. Finally, observe why the
   electrons do not stop as they pass equilibrium. The frequency derivation is
   deferred; this page establishes the physical mechanism.

   .. raw:: html

      <p><a class="reference external" href="../../_static/plasma_waves/02_why_oscillates.html?lang=en"
      style="display:inline-block;padding:14px 24px;background:#214e3a;color:#fff;border-radius:5px;font-size:20px;text-decoration:none;">Open page 2 →</a></p>

   This unmagnetized cold-electron slab approximation fixes the ions and isolates
   coherent displacement, rather than simulating spatial wave propagation.
   **The electric force points toward equilibrium; inertia carries electrons past it.**
   Field and force reverse after crossing. Without collisions or other damping,
   the ideal oscillation continues.

   .. rubric:: Page 3 · How do we measure a wave?

   Measure the same density wave three ways: period at a fixed position,
   wavelength at a frozen instant, and phase speed by following the same crest.
   Connect ``f = 1/T`` with ``v_ph = λ/T = λf``. The probe measures local electron
   density, and pattern motion is distinguished from individual electron motion.

   .. raw:: html

      <p><a class="reference external" href="../../_static/plasma_waves/03_measuring_a_wave.html?lang=en"
      style="display:inline-block;padding:14px 24px;background:#214e3a;color:#fff;border-radius:5px;font-size:20px;text-decoration:none;">Open page 3 →</a></p>

   Text alternative: period describes repetition in time; wavelength describes
   repetition in space. The same crest advances one wavelength per period, giving
   phase speed wavelength/period. This prescribed sinusoidal density wave teaches
   kinematics; it does not solve a plasma dispersion relation.

   .. rubric:: Page 4 · Different positions, different phases

   Move a second probe and compare two local density traces. Half a wavelength
   gives opposite phase; a full wavelength gives the same phase again. Connect
   spatial and temporal phase changes to wavenumber ``k = 2π/λ`` and angular
   frequency ``ω = 2π/T``. Combine them as ``δn = A cos(kx − ωt + φ₀)``;
   equal-phase points move right at ``ω/k``.

   .. raw:: html

      <p><a class="reference external" href="../../_static/plasma_waves/04_phase.html?lang=en"
      style="display:inline-block;padding:14px 24px;background:#214e3a;color:#fff;border-radius:5px;font-size:20px;text-decoration:none;">Open page 4 →</a></p>

   .. rubric:: Page 5 · What happens when two waves meet?

   Start from ``δn = δn₁ + δn₂``. Adjust relative phase to explore reinforcement
   and cancellation, compare nearby frequencies to reveal beats, then reverse
   one equal-frequency, equal-amplitude wave to form a standing wave. Add density
   perturbations; do not add the background twice. An optional two-choice
   prediction distinguishes fixed density nodes from stationary electrons.

   .. raw:: html

      <p><a class="reference external" href="../../_static/plasma_waves/05_superposition.html?lang=en"
      style="display:inline-block;padding:14px 24px;background:#214e3a;color:#fff;border-radius:5px;font-size:20px;text-decoration:none;">Open page 5 →</a></p>

   Text alternative: equal-frequency, equal-amplitude waves reinforce in phase
   and cancel in opposite phase. Beat frequency is the absolute frequency
   difference. Equal counterpropagating waves can form
   ``δn = 2A cos(kx) cos(ωt)`` with stationary density nodes. Electrons can still
   cross those nodes. These are prescribed illustrations of linear superposition,
   not nonlinear interactions or plasma-simulation results.

   .. rubric:: Page 6 · Why write waves as complex numbers?

   Connect the real density signal at a fixed probe to the real-axis projection
   of a rotating complex arrow. Reveal Euler's identity, complex amplitude,
   same-mode amplitude addition, then differentiation of a plane wave. Adjust
   initial phase and predict reinforcement or cancellation with one phase slider.

   .. raw:: html

      <p><a class="reference external" href="../../_static/plasma_waves/06_complex_waves.html?lang=en"
      style="display:inline-block;padding:14px 24px;background:#214e3a;color:#fff;border-radius:5px;font-size:20px;text-decoration:none;">Open page 6 →</a></p>

   Text alternative: write ``ñ = n̂ exp[i(kx−ωt)]`` and ``n̂ = A exp(iφ₀)``;
   recover the physical density perturbation as ``δn = Re{ñ}``, with total
   density ``n₀ + δn``. Both complex axes, the complex amplitude and density
   perturbation use m⁻³; they are not spatial directions. At a fixed probe,
   phase decreases with time, so the arrow rotates clockwise. Constant amplitudes
   can be added for a common k and ω; zero resultant amplitude has undefined phase.
   For this constant-amplitude plane wave, ``∂ₜñ = −iωñ`` and ``∂ₓñ = ikñ``.
   The plot divides derivatives by ω or k to compare phase with consistent units.

   .. rubric:: Symbols and units

   .. list-table:: SI units in the first six pages
      :header-rows: 1
      :widths: 45 30 25

      * - Quantity
        - Symbol
        - Unit
      * - Time and period
        - t, T, T₁
        - s
      * - Frequency and beat frequency
        - f, f₁, f₂, f_beat
        - Hz
      * - Position, displacement and wavelength
        - x, Δx, λ
        - m
      * - Phase speed and electron velocity
        - v_ph, v_e
        - m/s
      * - Phase, phase difference and initial phase
        - φ, Δφ, φ₀
        - rad
      * - Wavenumber
        - k
        - rad/m
      * - Angular frequency
        - ω
        - rad/s
      * - Number density, perturbation, real/complex amplitude
        - nₑ, n₀, δn, A, n̂, ñ
        - m⁻³
      * - Temporal and spatial density derivatives
        - ∂ₜñ, ∂ₓñ
        - m⁻³/s; m⁻⁴
      * - Imaginary unit and complex exponential
        - i, exp[i(kx−ωt)]
        - 1 (dimensionless)
      * - Electric field and electron force
        - E, F
        - V/m; N

   The radian has dimension one in SI. We retain rad to make phase explicit and
   distinguish Hz from rad/s. An exponential or trigonometric argument must be
   dimensionless, so kx, ωt and φ₀ must be consistent. Here A is a density
   amplitude; amplitude inherits the units of the quantity being described.
   The plots use λ, T and n₀ as reference scales (λ₁ and T₁ in the two-wave
   examples), with no assigned absolute SI values. Playback seconds are not
   physical periods. A distance of 0.25λ does not mean 0.25 m.
