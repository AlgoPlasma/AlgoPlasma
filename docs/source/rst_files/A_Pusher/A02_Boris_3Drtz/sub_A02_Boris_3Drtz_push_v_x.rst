--------------------------------
sub_A02_Boris_3Drtz_push_v_x.f90
--------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在 3D 柱坐标中对单个粒子执行 Boris 速度更新，并同步推进位置。

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
      * - ``x``
        - ``in/out``
        - ``real(1:3)``
        - 粒子位置向量
        - 调用者归一化下的粒子/场单位
        - 单粒子向量，无 ghost cell；分量顺序由本页坐标系决定。
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
      * - ``dt``
        - ``in``
        - ``real scalar``
        - 时间步长
        - 调用者传入的网格或时间单位
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。

   .. rubric:: 局部假设 / 前置条件

   - 坐标系为柱坐标，分量/位置顺序按本页参数表；方位角按调用者的弧度约定。
   - 本页只说明本 routine 的局部约定；不假设全局主程序的单位制、时间步或边界策略。

   .. rubric:: 实现逻辑

   - 先执行 Boris 速度更新，再用柱坐标几何关系推进 ``r,theta,z``。
   - 位置更新后用旋转矩阵把速度分量变换到新的局部柱坐标基。

   .. rubric:: 调用注意

   - 该 routine 只处理单粒子局部更新，场插值、粒子循环和边界处理在上层完成。


   .. rubric:: 子程序说明

   ``sub_A02_Boris_3Drtz_push_v_x`` 在柱坐标
   :math:`(r,\theta,z)` 中对单个粒子执行 non-relativistic Boris push。
   给定粒子位置处的电场和磁场后，它会在一个完整时间步内同时更新粒子位置
   :math:`\mathbf{x} = (r,\theta,z)` 和速度
   :math:`\mathbf{v} = (v_r,v_\theta,v_z)`。

   .. list-table::
      :header-rows: 1

      * - 参数
        - 方向
        - 含义
      * - ``x(1:3)``
        - in/out
        - 粒子柱坐标位置 :math:`\mathbf{x} = (r,\theta,z)`。
      * - ``v(1:3)``
        - in/out
        - 粒子柱坐标速度 :math:`\mathbf{v} = (v_r,v_\theta,v_z)`。
      * - ``E(1:3)``
        - in
        - 粒子位置处的电场柱坐标分量
          :math:`\mathbf{E} = (E_r,E_\theta,E_z)`。
      * - ``B(1:3)``
        - in
        - 粒子位置处的磁场柱坐标分量
          :math:`\mathbf{B} = (B_r,B_\theta,B_z)`。
      * - ``k``
        - in
        - Boris 参数，通常为 :math:`q\Delta t/(2m)`。
      * - ``dt``
        - in
        - 时间步长 :math:`\Delta t`，用于柱坐标几何中的位置推进。

   .. rubric:: 算法说明

   Boris leapfrog 格式也可以直接写在柱坐标
   :math:`(r,\theta,z)` 中。设

   .. math::
      \mathbf{x}^n = (r^n,\theta^n,z^n), \qquad
      \mathbf{v}^{n-1/2} =
      \left(v_r^{n-1/2},v_\theta^{n-1/2},v_z^{n-1/2}\right)

   电场 :math:`\mathbf{E}` 和磁场 :math:`\mathbf{B}` 在
   :math:`\mathbf{x}^n` 处取值。该更新将
   :math:`(\mathbf{x}^n,\mathbf{v}^{n-1/2})` 推进到
   :math:`(\mathbf{x}^{n+1},\mathbf{v}^{n+1/2})`，并遵循 Delzanno
   等人给出的 cylindrical Boris algorithm。

   1. 首先执行电场 half-step acceleration：

      .. math::
         \mathbf{v}^{-}
         = \mathbf{v}^{n-1/2}
         + \frac{q\mathbf{E}}{m}\frac{\Delta t}{2}

   2. 然后执行磁场导致的速度空间旋转：

      .. math::
         \mathbf{v}^\prime
         = \mathbf{v}^{-}
         + f^{n,\Delta t}\mathbf{v}^{-} \times \mathbf{B}

      .. math::
         \mathbf{v}^{+}
         = \mathbf{v}^{-}
         + \frac{2 f^{n,\Delta t}}{1 + (f^{n,\Delta t})^2
            \|\mathbf{B}\|^2}
           \mathbf{v}^\prime \times \mathbf{B}

      其中

      .. math::
         f^{n,\Delta t}
         =
         \frac{\tan\left(
             \dfrac{q\Delta t}{2m}\|\mathbf{B}\|
           \right)}
           {\|\mathbf{B}\|}

   3. 再执行第二次电场 half-step acceleration：

      .. math::
         \mathbf{v}^{n+1/2*}
         = \mathbf{v}^{+}
         + \frac{q\mathbf{E}}{m}\frac{\Delta t}{2}

   4. 位置从 :math:`\mathbf{x}^n` 推进到
      :math:`\mathbf{x}^{n+1}`。定义中间量

      .. math::
         \phi^{n+1}
         = r^n + v_r^{n+1/2*}\Delta t, \qquad
         \psi^{n+1}
         = v_\theta^{n+1/2*}\Delta t

      新的柱坐标为

      .. math::
         r^{n+1}
         = \sqrt{ \left(\phi^{n+1}\right)^2
         + \left(\psi^{n+1}\right)^2 }

      .. math::
         \theta^{n+1}
         = \theta^n + \alpha, \qquad
         \sin\alpha = \frac{\psi^{n+1}}{r^{n+1}}, \qquad
         \cos\alpha = \frac{\phi^{n+1}}{r^{n+1}}

      .. math::
         z^{n+1}
         = z^n + v_z^{n+1/2*}\Delta t

   5. 由于径向-方位平面旋转了角度 :math:`\alpha`，速度分量还需要表达在新的柱坐标局部基底中：

      .. math::
         v_r^{n+1/2}
         = \cos\alpha\,v_r^{n+1/2*}
         + \sin\alpha\,v_\theta^{n+1/2*}

      .. math::
         v_\theta^{n+1/2}
         = -\sin\alpha\,v_r^{n+1/2*}
         + \cos\alpha\,v_\theta^{n+1/2*}

      .. math::
         v_z^{n+1/2} = v_z^{n+1/2*}

   .. note::

      当 :math:`r^{n+1}=0` 时，角度 :math:`\alpha` 不再由
      :math:`\sin\alpha` 和 :math:`\cos\alpha` 唯一确定。代码中使用
      :math:`\sin\alpha=0`、:math:`\cos\alpha=1` 处理粒子正好落在轴线上的情形。

   .. rubric:: 参考文献

   [1] G.L. Delzanno, E. Camporeale, On particle movers in cylindrical geometry
   for Particle-In-Cell simulations, Journal of Computational Physics,
   253 (2013) 259-277. DOI: `10.1016/j.jcp.2013.07.007 <https://doi.org/10.1016/j.jcp.2013.07.007>`_

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Performs a cylindrical-coordinate Boris velocity update for one particle and advances its position.

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
      * - ``x``
        - ``in/out``
        - ``real(1:3)``
        - particle position vector
        - particle/field units chosen by the caller
        - Single-particle vector with no ghost cells; component order follows the coordinate system on this page.
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
      * - ``dt``
        - ``in``
        - ``real scalar``
        - time step
        - caller-provided mesh or time unit
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.

   .. rubric:: Local Assumptions / Preconditions

   - The coordinate system is cylindrical; component/order conventions follow this page, and azimuths use the caller radian convention.
   - This page states only the local routine conventions; it does not assume a global driver unit system, time step, or boundary policy.

   .. rubric:: Implementation Notes

   - Runs the Boris velocity update, then advances ``r,theta,z`` with cylindrical geometry.
   - After the position update, a rotation maps velocity components onto the new local cylindrical basis.

   .. rubric:: Calling Notes

   - The routine handles only a single-particle local update; field gather, particle loops, and boundary handling live above this layer.


   .. rubric:: Generated API

   .. doxygenfile:: sub_A02_Boris_3Drtz_push_v_x.f90

   .. rubric:: Instruction

   The Boris leap-frog scheme can also be formulated directly in cylindrical
   coordinates :math:`(r,\theta,z)` for an axisymmetric system. Let

   .. math::
      \mathbf{x}^n = (r^n, \theta^n, z^n) \qquad
      \mathbf{v}^{n-1/2} = \left(v_r^{n-1/2}, v_\theta^{n-1/2}, v_z^{n-1/2}\right),

   and let :math:`\mathbf{E}` and :math:`\mathbf{B}` be the
   electric and magnetic fields evaluated at :math:`\mathbf{x}^n`. The time step is
   denoted by :math:`\Delta t`, and we advance the solution from
   :math:`( \mathbf{x}^n, \mathbf{v}^{n-1/2})` to
   :math:`( \mathbf{x}^{n+1}, \mathbf{v}^{n+1/2})`,
   the update implemented in code follows
   the cylindrical Boris algorithm described in Delzanno et al. [1]_ and
   can be split into two main stages.

   1. First apply a half-step acceleration due
      to the electric field only:

      .. math::
         \mathbf{v}^{-}
         = \mathbf{v}^{n-1/2}
         + \frac{q\mathbf{E}}{m}\frac{\Delta t}{2}

      where :math:`\mathbf{v}^{-}` has components
      :math:`(v_r^{-}, v_\theta^{-}, v_z^{-})`.

   2. Next perform a full-step rotation in velocity
      space due to the magnetic field:

      .. math::
         \mathbf{v}^\prime
         = \mathbf{v}^{-}
         + f^{n,\Delta t}\mathbf{v}^{-} \times \mathbf{B}

      .. math::
         \mathbf{v}^{+}
         = \mathbf{v}^{-}
         + \frac{2 f^{n,\Delta t}}{1 + (f^{n,\Delta t})^2
            \|\mathbf{B}\|^2}
           \mathbf{v}^\prime \times \mathbf{B}

      with

      .. math::
         f^{n,\Delta t}
         = \frac{\tan\left(
             \dfrac{q \Delta t}{2m }
             \|\mathbf{B}\|
           \right)}
           {\|\mathbf{B}\|}

   3. Apply a second half-step
      acceleration due to the electric field:

      .. math::
         \mathbf{v}^{n+1/2*}
         = \mathbf{v}^{+}
         + \frac{q\mathbf{E}}{m}\frac{\Delta t}{2}

      where

      .. math::
         \mathbf{v}^{n+1/2*}
         = \left(
             v_r^{n+1/2*},
             v_\theta^{n+1/2*},
             v_z^{n+1/2*}
           \right)

   4. The position is advanced from
      :math:`\mathbf{x}^n` to :math:`\mathbf{x}^{n+1}` using a cylindrical version
      of the leap-frog scheme. Define the intermediate quantities

      .. math::
         \phi^{n+1}
         = r^n + v_r^{n+1/2*}\Delta t \qquad
         \psi^{n+1}
         = v_\theta^{n+1/2*}\Delta t

   The new cylindrical coordinates are then obtained as

   .. math::
      r^{n+1}
      = \sqrt{ \left(\phi^{n+1}\right)^2 + \left(\psi^{n+1}\right)^2 }

   .. math::
      \theta^{n+1}
      = \theta^n + \alpha
      \qquad
      \sin\alpha = \frac{\psi^{n+1}}{r^{n+1}}
      \quad
      \cos\alpha = \frac{\phi^{n+1}}{r^{n+1}}
      \quad
      \alpha = \arctan{\dfrac{\psi^{n+1}}{\phi^{n+1}}}

   .. math::
      z^{n+1}
      = z^n + v_z^{n+1/2*}\Delta t

   so that

   .. math::
      \mathbf{x}^{n+1}
      = \left(r^{n+1}, \theta^{n+1}, z^{n+1}\right)

   5. Because the radial-azimuthal plane has been rotated by an angle
      :math:`\alpha`, the velocity components must be expressed in the new
      cylindrical frame. This is accomplished by the 2D rotation

      .. math::
         v_r^{n+1/2}
         = \cos\alpha v_r^{n+1/2*}
           + \sin\alpha v_\theta^{n+1/2*}

      .. math::
         v_\theta^{n+1/2}
         = -\sin\alpha v_r^{n+1/2*}
           + \cos\alpha v_\theta^{n+1/2*}

      .. math::
         v_z^{n+1/2}
         = v_z^{n+1/2*}

   and therefore

   .. math::
      \mathbf{v}^{n+1/2}
      = \left(
          v_r^{n+1/2},
          v_\theta^{n+1/2},
          v_z^{n+1/2}
        \right)

   .. note::

      The angle :math:`\alpha` defined above is well posed only if
      :math:`r^{n+1} \neq 0`. The special case :math:`r^{n+1} = 0`
      corresponds to a particle that comes exactly on axis. In this
      situation, one can set :math:`\cos\alpha = 1` and :math:`\sin\alpha = 0`
      so that the particle momentum is purely radial in the new frame.

   .. [1] G.L. Delzanno, E. Camporeale, On particle movers in cylindrical geometry for Particle-In-Cell simulations, Journal of Computational Physics, 253 (2013) 259-277. DOI: `10.1016/j.jcp.2013.07.007 <https://doi.org/10.1016/j.jcp.2013.07.007>`_
