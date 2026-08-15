----------------------------------
sub_B02_deposit_current_3d_cyl.f90
----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   把一个粒子从起点到终点的运动轨迹分段后，沉积 3D 柱坐标电流密度。

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
      * - ``r0``
        - ``in``
        - ``real scalar``
        - 粒子轨迹起点半径
        - 网格物理坐标，角度按弧度约定
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``phi0``
        - ``in``
        - ``real scalar``
        - 粒子轨迹起点方位角
        - 网格物理坐标，角度按弧度约定
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``z0``
        - ``in``
        - ``real scalar``
        - 粒子轨迹起点轴向位置
        - 网格物理坐标，角度按弧度约定
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``r1``
        - ``in``
        - ``real scalar``
        - 粒子轨迹终点半径
        - 网格物理坐标，角度按弧度约定
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``phi1``
        - ``in``
        - ``real scalar``
        - 粒子轨迹终点方位角
        - 网格物理坐标，角度按弧度约定
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``z1``
        - ``in``
        - ``real scalar``
        - 粒子轨迹终点轴向位置
        - 网格物理坐标，角度按弧度约定
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``qp``
        - ``in``
        - ``real scalar``
        - 粒子电荷
        - 粒子权重或归一化因子
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``wp``
        - ``in``
        - ``real scalar``
        - 宏粒子权重
        - 粒子权重或归一化因子
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``dr``
        - ``in``
        - ``real scalar``
        - 径向网格间距
        - 调用者传入的网格或时间单位
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``dphi``
        - ``in``
        - ``real scalar``
        - 方位角网格间距
        - 调用者传入的网格或时间单位
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``dz``
        - ``in``
        - ``real scalar``
        - 轴向网格间距
        - 调用者传入的网格或时间单位
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``nr``
        - ``in``
        - ``integer scalar``
        - 径向 cell 数
        - 整数下标或计数
        - 决定可访问的本地模板范围，必须与实际数组分配一致。
      * - ``nphi``
        - ``in``
        - ``integer scalar``
        - 最大方位角节点索引
        - 整数下标或计数
        - 决定可访问的本地模板范围，必须与实际数组分配一致。
      * - ``nz``
        - ``in``
        - ``integer scalar``
        - 轴向 cell 数
        - 整数下标或计数
        - 决定可访问的本地模板范围，必须与实际数组分配一致。
      * - ``dt``
        - ``in``
        - ``real scalar``
        - 时间步长
        - 调用者传入的网格或时间单位
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``jr``
        - ``in/out``
        - ``real(0:nr,0:nphi,0:nz)``
        - 径向电流密度数组
        - 调用者定义的密度/电流/统计量归一化
        - 下标范围为 ``0:nr,0:nphi,0:nz``；``phi`` 方向按周期处理。
      * - ``jphi``
        - ``in/out``
        - ``real(0:nr,0:nphi,0:nz)``
        - 方位角电流密度数组
        - 调用者定义的密度/电流/统计量归一化
        - 下标范围为 ``0:nr,0:nphi,0:nz``；``phi`` 方向按周期处理。
      * - ``jz``
        - ``in/out``
        - ``real(0:nr,0:nphi,0:nz)``
        - 轴向电流密度数组
        - 调用者定义的密度/电流/统计量归一化
        - 下标范围为 ``0:nr,0:nphi,0:nz``；``phi`` 方向按周期处理。

   .. rubric:: 局部假设 / 前置条件

   - 坐标系为柱坐标，分量/位置顺序按本页参数表；方位角按调用者的弧度约定。
   - 本页只说明本 routine 的局部约定；不假设全局主程序的单位制、时间步或边界策略。

   .. rubric:: 实现逻辑

   - 先把起点/终点规整到网格范围，并选择跨周期的最短 ``phi`` 位移。
   - 递归把轨迹切到单 cell 段，再用单 cell 公式累加 ``jr/jphi/jz``。

   .. rubric:: 调用注意

   - 调用前通常应清零输出沉积数组；多个粒子循环的累积顺序由调用者组织。


   .. rubric:: 子程序说明

   ``sub_B02_deposit_current_3d_cyl`` 接收粒子从 ``(r0,phi0,z0)`` 到
   ``(r1,phi1,z1)`` 的位移，并把它在时间步 ``dt`` 内贡献的电流沉积到
   ``jr``、``jphi`` 和 ``jz``。若轨迹穿越网格面，内部递归 helper 会把轨迹切分为单元内片段，分别按扫掠体积沉积。

   输入 ``phi`` 会按最短周期位移处理，``r`` 和 ``z`` 会限制在有效计算域内。
   粒子循环完成后，轴线上的 ``jz(0,:,k)`` 应进行方位向平均。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Splits one particle trajectory and deposits 3D cylindrical current density.

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
      * - ``r0``
        - ``in``
        - ``real scalar``
        - trajectory start radius
        - mesh coordinates; angles follow the radian convention
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``phi0``
        - ``in``
        - ``real scalar``
        - trajectory start azimuth
        - mesh coordinates; angles follow the radian convention
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``z0``
        - ``in``
        - ``real scalar``
        - trajectory start axial position
        - mesh coordinates; angles follow the radian convention
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``r1``
        - ``in``
        - ``real scalar``
        - trajectory end radius
        - mesh coordinates; angles follow the radian convention
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``phi1``
        - ``in``
        - ``real scalar``
        - trajectory end azimuth
        - mesh coordinates; angles follow the radian convention
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``z1``
        - ``in``
        - ``real scalar``
        - trajectory end axial position
        - mesh coordinates; angles follow the radian convention
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``qp``
        - ``in``
        - ``real scalar``
        - particle charge
        - particle weight or normalization factor
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``wp``
        - ``in``
        - ``real scalar``
        - macro-particle weight
        - particle weight or normalization factor
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``dr``
        - ``in``
        - ``real scalar``
        - radial spacing
        - caller-provided mesh or time unit
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``dphi``
        - ``in``
        - ``real scalar``
        - azimuthal spacing
        - caller-provided mesh or time unit
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``dz``
        - ``in``
        - ``real scalar``
        - axial spacing
        - caller-provided mesh or time unit
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``nr``
        - ``in``
        - ``integer scalar``
        - number of radial cells
        - integer index or count
        - Controls accessible local stencil bounds and must match the actual allocation.
      * - ``nphi``
        - ``in``
        - ``integer scalar``
        - maximum phi-node index
        - integer index or count
        - Controls accessible local stencil bounds and must match the actual allocation.
      * - ``nz``
        - ``in``
        - ``integer scalar``
        - number of axial cells
        - integer index or count
        - Controls accessible local stencil bounds and must match the actual allocation.
      * - ``dt``
        - ``in``
        - ``real scalar``
        - time step
        - caller-provided mesh or time unit
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``jr``
        - ``in/out``
        - ``real(0:nr,0:nphi,0:nz)``
        - radial current-density array
        - caller-defined density/current/statistic normalization
        - Bounds are ``0:nr,0:nphi,0:nz``; the ``phi`` direction is periodic.
      * - ``jphi``
        - ``in/out``
        - ``real(0:nr,0:nphi,0:nz)``
        - azimuthal current-density array
        - caller-defined density/current/statistic normalization
        - Bounds are ``0:nr,0:nphi,0:nz``; the ``phi`` direction is periodic.
      * - ``jz``
        - ``in/out``
        - ``real(0:nr,0:nphi,0:nz)``
        - axial current-density array
        - caller-defined density/current/statistic normalization
        - Bounds are ``0:nr,0:nphi,0:nz``; the ``phi`` direction is periodic.

   .. rubric:: Local Assumptions / Preconditions

   - The coordinate system is cylindrical; component/order conventions follow this page, and azimuths use the caller radian convention.
   - This page states only the local routine conventions; it does not assume a global driver unit system, time step, or boundary policy.

   .. rubric:: Implementation Notes

   - Normalizes start/end points and chooses the shortest periodic ``phi`` displacement.
   - Recursively splits the trajectory into single-cell segments and accumulates ``jr/jphi/jz``.

   .. rubric:: Calling Notes

   - Output deposition arrays are normally zeroed before the call; the caller organizes accumulation over multiple particles.


   .. rubric:: Subroutine Description

   ``sub_B02_deposit_current_3d_cyl`` receives a particle displacement from
   ``(r0,phi0,z0)`` to ``(r1,phi1,z1)`` and deposits its current contribution
   over time step ``dt`` to ``jr``, ``jphi``, and ``jz``. If the trajectory
   crosses grid faces, an internal recursive helper splits it into single-cell
   segments and deposits each segment with swept-volume formulas.

   Input ``phi`` is handled as the shortest periodic displacement, while ``r``
   and ``z`` are clamped to the valid domain. After the particle loop,
   ``jz(0,:,k)`` on the axis should be azimuthally averaged.

   .. rubric:: Generated API

   .. doxygenfile:: sub_B02_deposit_current_3d_cyl.f90
