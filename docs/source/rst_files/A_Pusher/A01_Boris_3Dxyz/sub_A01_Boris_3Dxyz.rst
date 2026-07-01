-----------------------
sub_A01_Boris_3Dxyz.f90
-----------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   对单个 3D Cartesian 粒子速度执行一次 non-relativistic Boris 更新。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 14 10 28 34 26 40

      * - 参数
        - 方向
        - shape / 范围
        - 含义
        - 单位 / 归一化
        - 索引 / ghost-cell 要求
      * - ``v``
        - ``in/out``
        - ``real(1:3)``
        - 粒子速度向量
        - 调用者归一化下的粒子/场单位
        - 单粒子向量，无 ghost cell；分量顺序由本页坐标系决定。
      * - ``E``
        - ``in``
        - ``real(1:3)``
        - 粒子位置处的电场向量
        - 调用者归一化下的粒子/场单位
        - 单粒子向量，无 ghost cell；分量顺序由本页坐标系决定。
      * - ``B``
        - ``in``
        - ``real(1:3)``
        - 粒子位置处的磁场向量
        - 调用者归一化下的粒子/场单位
        - 单粒子向量，无 ghost cell；分量顺序由本页坐标系决定。
      * - ``k``
        - ``in``
        - ``real scalar``
        - Boris/Higuera-Cary 半步系数，通常为 q*dt/(2m)。
        - 调用者归一化下的电荷质量比与时间步组合。
        - 单粒子标量；无 ghost cell。
   .. rubric:: 局部假设 / 前置条件

   - 坐标系为 Cartesian，分量顺序为 ``(x,y,z)``。
   - 本页只说明本 routine 的局部约定；不假设全局主程序的单位制、时间步或边界策略。

   .. rubric:: 实现逻辑

   - 先做电场 half-kick，再按磁场大小构造旋转参数，最后做第二个 half-kick。
   - 当 ``|B|`` 小于 tiny 阈值时，源码退化为纯电场加速分支。

   .. rubric:: 调用注意

   - 该 routine 只处理单粒子局部更新，场插值、粒子循环和边界处理在上层完成。


   .. rubric:: 子程序说明

   ``sub_A01_Boris_3Dxyz`` 对单个粒子的三维直角坐标速度
   :math:`\mathbf{v} = (v_x,v_y,v_z)` 执行一次 non-relativistic Boris
   velocity update。它先进行电场半步加速，再执行磁场旋转，最后再进行一次电场半步加速，从而在一个完整时间步内推进粒子速度。

   .. list-table::
      :header-rows: 1

      * - 参数
        - 方向
        - 含义
      * - ``v(1:3)``
        - in/out
        - 粒子速度；入口为时间步开始时的速度，出口为一次完整 Boris 更新后的速度。
      * - ``E(1:3)``
        - in
        - 粒子位置处的电场 :math:`\mathbf{E} = (E_x,E_y,E_z)`。
      * - ``B(1:3)``
        - in
        - 粒子位置处的磁场 :math:`\mathbf{B} = (B_x,B_y,B_z)`。
      * - ``k``
        - in
        - Boris 参数，通常为 :math:`q\Delta t/(2m)`，控制电场 half-kick
          和磁场旋转强度。

   .. rubric:: 算法说明

   经典 Boris leapfrog 格式可写为

   .. math::
      \frac{\mathbf{v}^{n+1/2}-\mathbf{v}^{n-1/2}}{\Delta t}
      = \frac{q}{m}\left(\mathbf{E}^n+\mathbf{v}^n\times\mathbf{B}^n\right),
      \qquad
      \mathbf{v}^n \approx
      \frac{\mathbf{v}^{n+1/2}+\mathbf{v}^{n-1/2}}{2}

   .. math::

      \frac{\mathbf{x}^{n+1}-\mathbf{x}^{n}}{\Delta t}
      = \mathbf{v}^{n+1/2}

   在本实现中，将 :math:`n=1/2`，并把半步场量简记为
   :math:`\mathbf{E}` 和 :math:`\mathbf{B}`。速度更新可写成：

   .. math::
      \mathbf{v}^- = \mathbf{v}^0
      + \frac{q\mathbf{E}}{m}\frac{\Delta t}{2}

   .. math::
      \mathbf{t} =
      \tan\left(\frac{q\Delta t}{2m}\|\mathbf{B}\|\right)
      \frac{\mathbf{B}}{\|\mathbf{B}\|}
      \approx \frac{q\Delta t}{2m}\mathbf{B}

   .. math::
      \mathbf{v}^\prime = \mathbf{v}^- + \mathbf{v}^- \times \mathbf{t},
      \qquad
      \mathbf{s} = \frac{2\mathbf{t}}{1+\|\mathbf{t}\|^2}

   .. math::
      \mathbf{v}^+ = \mathbf{v}^- + \mathbf{v}^\prime \times \mathbf{s},
      \qquad
      \mathbf{v}^1 =
      \mathbf{v}^+ + \frac{q\mathbf{E}}{m}\frac{\Delta t}{2}

   若还需要推进位置，可配合

   .. math::
      \mathbf{x}^{1/2 + 1}
      = \mathbf{x}^{1/2} + \mathbf{v}^{1}\Delta t

   .. note::

      因子
      :math:`q\,\Delta t\,\|\mathbf{B}\|/(2m)`
      正好等于物理 Larmor 旋转角的一半：
      :math:`\theta/2 = \omega_{ce}\Delta t/2`，其中
      :math:`\omega_{ce}=q\|\mathbf{B}\|/m` 是回旋频率。通过选择
      :math:`\mathbf{t}` 使
      :math:`\|\mathbf{t}\|=\tan(q\,\Delta t\,\|\mathbf{B}\|/(2m))`，
      这个精确半角由 tangent 函数编码。该构造在速度空间中给出严格的刚性旋转，
      因而在均匀磁场中，Boris 旋转步能够再现精确的 Larmor 旋转角
      :math:`\omega_{ce}\Delta t`。
      相比之下，标准 Boris 格式取
      :math:`\mathbf{t}=q\Delta t\,\mathbf{B}/(2m)`，只执行近似旋转：
      它具有二阶精度，并且在足够小的时间步下非常准确，但在有限
      :math:`\Delta t` 下会引入回旋频率（相位）误差。当磁场趋近于零时，
      更新退化为纯电场加速
      :math:`\mathbf{v}^1 \leftarrow
      \mathbf{v}^0 + q\Delta t\,\mathbf{E}/m`。

   .. rubric:: 参考文献

   [1] J.P. Boris, Relativistic plasma simulation-optimization of a hybrid code,
   in: Proceedings of the Fourth Conference on Numerical Simulation of Plasmas,
   Naval Research Laboratory, Washington, D.C., 1970, pp.3-67.

   [2] G.L. Delzanno, E. Camporeale, On particle movers in cylindrical geometry
   for Particle-In-Cell simulations, Journal of Computational Physics,
   253 (2013) 259-277. DOI: `10.1016/j.jcp.2013.07.007 <https://doi.org/10.1016/j.jcp.2013.07.007>`_

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Performs one non-relativistic Boris velocity update for a single 3D Cartesian particle.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 14 10 28 34 26 40

      * - Parameter
        - Direction
        - Shape / Range
        - Meaning
        - Units / Normalization
        - Index / ghost-cell requirement
      * - ``v``
        - ``in/out``
        - ``real(1:3)``
        - particle velocity vector
        - particle/field units chosen by the caller
        - Single-particle vector with no ghost cells; component order follows the coordinate system on this page.
      * - ``E``
        - ``in``
        - ``real(1:3)``
        - electric field vector at the particle
        - particle/field units chosen by the caller
        - Single-particle vector with no ghost cells; component order follows the coordinate system on this page.
      * - ``B``
        - ``in``
        - ``real(1:3)``
        - magnetic field vector at the particle
        - particle/field units chosen by the caller
        - Single-particle vector with no ghost cells; component order follows the coordinate system on this page.
      * - ``k``
        - ``in``
        - ``real scalar``
        - Boris/Higuera-Cary half-step coefficient, usually q*dt/(2m).
        - charge-to-mass and time-step combination in caller normalization
        - Single-particle scalar with no ghost-cell requirement.

   .. rubric:: Local Assumptions / Preconditions

   - The coordinate system is Cartesian with component order ``(x,y,z)``.
   - This page states only the local routine conventions; it does not assume a global driver unit system, time step, or boundary policy.

   .. rubric:: Implementation Notes

   - Applies an electric half-kick, builds the magnetic rotation, and applies the second half-kick.
   - When ``|B|`` is below the tiny threshold, the source falls back to pure electric acceleration.

   .. rubric:: Calling Notes

   - The routine handles only a single-particle local update; field gather, particle loops, and boundary handling live above this layer.


   .. rubric:: Generated API

   .. doxygenfile:: sub_A01_Boris_3Dxyz.f90

   .. rubric:: Instruction

   The Classic Boris Leap-Frog Method:

   .. math::
      \frac{\mathbf{v}^{n+1/2}-\mathbf{v}^{n-1/2}}{\Delta t}
      = \frac{q}{m}\left(\mathbf{E}^n+\mathbf{v}^n\times\mathbf{B}^n\right)\qquad
      \mathbf{v}^n \approx \frac{\mathbf{v}^{n+1/2}+\mathbf{v}^{n-1/2}}{2}

   .. math::

      \frac{\mathbf{x}^{n+1}-\mathbf{x}^{n}}{\Delta t} = \mathbf{v}^{n+1/2}

   Taking :math:`n=1/2`, the Boris velocity update [1]_ used in the code can be written in the
   following compact form [2]_ (:math:`\mathbf{E}^{1/2}` is denoted
   simply by :math:`\mathbf{E}`; :math:`\mathbf{B}^{1/2}` is denoted simply by :math:`\mathbf{B}`):

   .. math::
      \mathbf{v}^- = \mathbf{v}^0
      + \frac{q\mathbf{E}}{m}\frac{\Delta t}{2}

   .. math::
      \mathbf{t}   = \tan\left(\frac{\theta}{2}\right) \hat{\mathbf{B}} =
      \tan\left( \frac{q\Delta t}{2 m} \|\mathbf{B}\| \right) \hat{\mathbf{B}}
      \approx \frac{q\Delta t}{2m}\mathbf{B}

   .. math::
      \mathbf{v}^\prime = \mathbf{v}^- + \mathbf{v}^- \times \mathbf{t}\qquad
      \mathbf{s}        = \frac{2\mathbf{t}}{1+\|\mathbf{t}\|^2}

   .. math::
      \mathbf{v}^+ = \mathbf{v}^- + \mathbf{v}^\prime \times \mathbf{s}\qquad
      \mathbf{v}^1 = \mathbf{v}^+ + \frac{q\mathbf{E}}{m}\frac{\Delta t}{2}

   Together with the position update

   .. math::
      \mathbf{x}^{1/2 + 1}
      =\mathbf{x}^{1/2} +  \mathbf{v}^{1} \Delta t

   .. note::
      The factor
      :math:`( \frac{q\,\Delta t}{2m}\,\|\mathbf{B}\| )`
      is exactly one half of the physical Larmor rotation angle
      :math:`\frac{\theta}{2} = \omega_{ce} \frac{\Delta t}{2}`, where :math:`\omega_{ce} = \frac{q \|\mathbf{B}\|}{m}`
      is the cyclotron frequency. By choosing :math:`\mathbf{t}` such that
      :math:`\|\mathbf{t}\| = \tan( \frac{q\,\Delta t}{2m}\,\|\mathbf{B}\| )`,
      the exact half-angle :math:`\frac{\theta}{2} = \omega_{ce} \frac{\Delta t}{2}` is encoded via the tangent
      function. This construction produces a strict rigid rotation in velocity
      space, so that the Boris rotation step reproduces the exact Larmor angle
      :math:`\omega_{ce} \Delta t` in a uniform magnetic field.
      By contrast, the standard Boris scheme with
      :math:`\mathbf{t} = \frac{q \Delta t}{2m}\mathbf{B}` performs only an
      approximate rotation: it is second-order accurate and very accurate for
      sufficiently small time steps, but it introduces a cyclotron-frequency
      (phase) error at finite :math:`\Delta t`.
      In the limit of vanishing magnetic field, the update reduces to a pure
      electric acceleration :math:`\mathbf{v}^1 \leftarrow \mathbf{v}^0 + \frac{q \Delta t}{m}\mathbf{E}`.

   .. [1] J.P. Boris, Relativistic plasma simulation-optimization of a hybrid code,
          in: Proceedings of the Fourth Conference on Numerical Simulation of Plasmas,
          Naval Research Laboratory, Washington, D.C., 1970, pp.3-67.
   .. [2] G.L. Delzanno, E. Camporeale, On particle movers in cylindrical geometry
          for Particle-In-Cell simulations, Journal of Computational Physics,
          253 (2013) 259-277. DOI: `10.1016/j.jcp.2013.07.007 <https://doi.org/10.1016/j.jcp.2013.07.007>`_

.. Reviewed by Yinjian ZHAO
