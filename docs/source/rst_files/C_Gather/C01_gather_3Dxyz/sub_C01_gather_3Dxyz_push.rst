-----------------------------
sub_C01_gather_3Dxyz_push.f90
-----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   对一个粒子 gather 3D Cartesian 场后直接调用 Boris pusher。

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
      * - ``np``
        - ``in``
        - ``integer scalar``
        - 粒子数或粒子数组第二维
        - 整数下标或计数
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``par``
        - ``in/out``
        - ``real(1:6,1:np)``
        - 粒子相空间数组
        - 位置为网格指标单位，速度/其他分量按调用者约定
        - 使用 ``par(1:3,p)`` 作为位置；调用者保证粒子位于本地或 guard 可覆盖范围。
      * - ``il``
        - ``in``
        - ``integer(1:3)``
        - 本地网格有效下界
        - 整数下标或计数
        - 决定可访问的本地模板范围，必须与实际数组分配一致。
      * - ``iu``
        - ``in``
        - ``integer(1:3)``
        - 本地网格有效上界
        - 整数下标或计数
        - 决定可访问的本地模板范围，必须与实际数组分配一致。
      * - ``Ex``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - x 向电场网格。
        - 调用者归一化下的场值。
        - 数组覆盖本地区间外一层；三线性插值会访问八个相邻节点。
      * - ``Ey``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - y 向电场网格。
        - 调用者归一化下的场值。
        - 数组覆盖本地区间外一层；三线性插值会访问八个相邻节点。
      * - ``Ez``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - z 向电场网格。
        - 调用者归一化下的场值。
        - 数组覆盖本地区间外一层；三线性插值会访问八个相邻节点。
      * - ``Bx``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - x 向磁场网格。
        - 调用者归一化下的场值。
        - 数组覆盖本地区间外一层；三线性插值会访问八个相邻节点。
      * - ``By``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - y 向磁场网格。
        - 调用者归一化下的场值。
        - 数组覆盖本地区间外一层；三线性插值会访问八个相邻节点。
      * - ``Bz``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - z 向磁场网格。
        - 调用者归一化下的场值。
        - 数组覆盖本地区间外一层；三线性插值会访问八个相邻节点。
      * - ``q``
        - ``in``
        - ``real scalar``
        - 粒子电荷。
        - 调用者归一化下的电荷。
        - 标量；无 ghost cell。
      * - ``m``
        - ``in``
        - ``real scalar``
        - 粒子质量。
        - 调用者归一化下的质量。
        - 标量；无 ghost cell。
      * - ``dt``
        - ``in``
        - ``real scalar``
        - 时间步长
        - 调用者传入的网格或时间单位
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。

   .. rubric:: 局部假设 / 前置条件

   - 粒子位置使用网格指标单位；沉积/插值模板必须落在本地数组或 guard cell 覆盖范围内。
   - 本页只说明本 routine 的局部约定；不假设全局主程序的单位制、时间步或边界策略。

   .. rubric:: 实现逻辑

   - 先调用 C01 gather 得到粒子位置处的 ``E`` 和 ``B``。
   - 随后调用 A01 Boris pusher 更新粒子速度。

   .. rubric:: 调用注意

   - 粒子靠近本地边界时，guard cell 必须已经有效。


   .. rubric:: 子程序说明

   ``sub_C01_gather_3Dxyz_push`` 是 C01 的融合内核。它对 ``par`` 中的所有粒子循环执行：先三线性插值电磁场，再用非相对论 Boris 形式更新速度，最后用更新后的速度推进位置。

   .. rubric:: 接口

   .. code-block:: fortran

      call sub_C01_gather_3Dxyz_push(np, par, il, iu, Ex, Ey, Ez, &
                                     Bx, By, Bz, q, m, dt)

   .. list-table::
      :header-rows: 1
      :widths: 18 12 46

      * - 参数
        - 方向
        - 含义
      * - ``np``
        - in
        - 粒子数。
      * - ``par(1:6,1:np)``
        - in/out
        - 粒子相空间数组；位置和速度都会被更新。
      * - ``il(1:3)``, ``iu(1:3)``
        - in
        - 本地网格子域指标范围。
      * - ``Ex,Ey,Ez``, ``Bx,By,Bz``
        - in
        - 本地网格上的电场和磁场分量。
      * - ``q``, ``m``
        - in
        - 粒子电荷和质量。
      * - ``dt``
        - in, optional
        - 时间步长；省略时使用 ``1.0``。

   .. rubric:: 数值流程

   对每个粒子，例程使用与 ``sub_C01_gather_3Dxyz`` 相同的八点三线性插值。随后令

   .. math::

      k = \frac{q}{m}\frac{\Delta t}{2},

   按电场半步加速、磁场旋转、电场半步加速的 Boris 结构更新 ``par(4:6,p)``，再执行

   .. math::

      \mathbf{x}^{n+1}=\mathbf{x}^{n}+\mathbf{v}^{n+1}\Delta t.

   该实现把 gather 和 push 放在同一 OpenMP 循环中，可减少临时数组写回，并让局部插值结果直接保留给速度更新使用。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Gathers 3D Cartesian fields for one particle and then calls the Boris pusher.

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
      * - ``np``
        - ``in``
        - ``integer scalar``
        - particle count or second dimension of par
        - integer index or count
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``par``
        - ``in/out``
        - ``real(1:6,1:np)``
        - particle phase-space array
        - positions in grid-index units; other components follow caller convention
        - Uses ``par(1:3,p)`` as position; caller keeps particles inside the local or guard-covered range.
      * - ``il``
        - ``in``
        - ``integer(1:3)``
        - local active-grid lower bounds
        - integer index or count
        - Controls accessible local stencil bounds and must match the actual allocation.
      * - ``iu``
        - ``in``
        - ``integer(1:3)``
        - local active-grid upper bounds
        - integer index or count
        - Controls accessible local stencil bounds and must match the actual allocation.
      * - ``Ex``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - x electric-field grid.
        - field value in caller normalization
        - Array covers one layer around the local range; trilinear interpolation touches eight neighboring nodes.
      * - ``Ey``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - y electric-field grid.
        - field value in caller normalization
        - Array covers one layer around the local range; trilinear interpolation touches eight neighboring nodes.
      * - ``Ez``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - z electric-field grid.
        - field value in caller normalization
        - Array covers one layer around the local range; trilinear interpolation touches eight neighboring nodes.
      * - ``Bx``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - x magnetic-field grid.
        - field value in caller normalization
        - Array covers one layer around the local range; trilinear interpolation touches eight neighboring nodes.
      * - ``By``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - y magnetic-field grid.
        - field value in caller normalization
        - Array covers one layer around the local range; trilinear interpolation touches eight neighboring nodes.
      * - ``Bz``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - z magnetic-field grid.
        - field value in caller normalization
        - Array covers one layer around the local range; trilinear interpolation touches eight neighboring nodes.
      * - ``q``
        - ``in``
        - ``real scalar``
        - Particle charge.
        - charge in caller normalization
        - Scalar with no ghost-cell requirement.
      * - ``m``
        - ``in``
        - ``real scalar``
        - Particle mass.
        - mass in caller normalization
        - Scalar with no ghost-cell requirement.
      * - ``dt``
        - ``in``
        - ``real scalar``
        - time step
        - caller-provided mesh or time unit
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.

   .. rubric:: Local Assumptions / Preconditions

   - Particle positions are in grid-index units; the deposition/interpolation stencil must lie inside the local array or its guard cells.
   - This page states only the local routine conventions; it does not assume a global driver unit system, time step, or boundary policy.

   .. rubric:: Implementation Notes

   - Calls C01 gather to obtain ``E`` and ``B`` at the particle.
   - Then calls the A01 Boris pusher to update particle velocity.

   .. rubric:: Calling Notes

   - Guard cells must be valid when particles are close to local boundaries.


   .. rubric:: Generated API

   .. doxygenfile:: sub_C01_gather_3Dxyz_push.f90

   .. rubric:: Instruction

   ``sub_C01_gather_3Dxyz_push`` is the fused C01 kernel. It loops over all particles in ``par``, gathers electromagnetic fields with trilinear interpolation, advances velocity with a non-relativistic Boris-style update, and then advances position using the updated velocity.

   .. rubric:: Interface

   .. code-block:: fortran

      call sub_C01_gather_3Dxyz_push(np, par, il, iu, Ex, Ey, Ez, &
                                     Bx, By, Bz, q, m, dt)

   .. list-table::
      :header-rows: 1
      :widths: 18 12 46

      * - Argument
        - Direction
        - Meaning
      * - ``np``
        - in
        - Number of particles.
      * - ``par(1:6,1:np)``
        - in/out
        - Particle phase-space array; both positions and velocities are updated.
      * - ``il(1:3)``, ``iu(1:3)``
        - in
        - Local grid index range.
      * - ``Ex,Ey,Ez``, ``Bx,By,Bz``
        - in
        - Electric- and magnetic-field components on the local grid.
      * - ``q``, ``m``
        - in
        - Particle charge and mass.
      * - ``dt``
        - in, optional
        - Time-step size; defaults to ``1.0`` when omitted.

   .. rubric:: Numerical Flow

   For each particle, this routine uses the same eight-point trilinear interpolation as ``sub_C01_gather_3Dxyz``. It then sets

   .. math::

      k = \frac{q}{m}\frac{\Delta t}{2},

   advances ``par(4:6,p)`` with the Boris electric half-kick, magnetic rotation, and electric half-kick structure, and finally applies

   .. math::

      \mathbf{x}^{n+1}=\mathbf{x}^{n}+\mathbf{v}^{n+1}\Delta t.

   Keeping gather and push in the same OpenMP loop avoids writing temporary field arrays and lets the local interpolation results be consumed immediately by the velocity update.
