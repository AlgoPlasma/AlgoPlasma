---------------------------------
sub_B02_deposit_charge_3d_cyl.f90
---------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   把一个粒子的电荷按 3D 柱坐标体积权重沉积到八个相邻节点。

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
      * - ``rp``
        - ``in``
        - ``real scalar``
        - 粒子半径
        - 网格物理坐标，角度按弧度约定
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``phip``
        - ``in``
        - ``real scalar``
        - 粒子方位角
        - 网格物理坐标，角度按弧度约定
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``zp``
        - ``in``
        - ``real scalar``
        - 粒子轴向位置
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
      * - ``rho``
        - ``in/out``
        - ``real(0:nr,0:nphi,0:nz)``
        - 节点电荷密度数组
        - 调用者定义的密度/电流/统计量归一化
        - 下标范围为 ``0:nr,0:nphi,0:nz``；``phi`` 方向按周期处理。

   .. rubric:: 局部假设 / 前置条件

   - 坐标系为柱坐标，分量/位置顺序按本页参数表；方位角按调用者的弧度约定。
   - 本页只说明本 routine 的局部约定；不假设全局主程序的单位制、时间步或边界策略。

   .. rubric:: 实现逻辑

   - 先把粒子坐标裁剪/规整到网格范围，并对 ``phi`` 做周期化。
   - 使用径向和轴向控制体积修正，把电荷分配到八个相邻节点。

   .. rubric:: 调用注意

   - 调用前通常应清零输出沉积数组；多个粒子循环的累积顺序由调用者组织。


   .. rubric:: 子程序说明

   ``sub_B02_deposit_charge_3d_cyl`` 把位于 ``(rp, phip, zp)`` 的单个粒子电荷 ``qp*wp`` 沉积到柱坐标八个相邻节点。权重在 ``r``、``phi`` 和 ``z``
   方向为一阶线性权重，归一化体积包含柱坐标径向因子、方位角长度和轴向边界半单元修正。

   ``phi`` 方向周期处理；粒子循环结束后，轴线上的 ``rho(0,:,k)`` 应由
   ``sub_B02_average_axis_charge_3d_cyl`` 平均。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Deposits one particle charge to eight neighboring nodes with 3D cylindrical volume weights.

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
      * - ``rp``
        - ``in``
        - ``real scalar``
        - particle radius
        - mesh coordinates; angles follow the radian convention
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``phip``
        - ``in``
        - ``real scalar``
        - particle azimuth
        - mesh coordinates; angles follow the radian convention
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``zp``
        - ``in``
        - ``real scalar``
        - particle axial position
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
      * - ``rho``
        - ``in/out``
        - ``real(0:nr,0:nphi,0:nz)``
        - nodal charge-density array
        - caller-defined density/current/statistic normalization
        - Bounds are ``0:nr,0:nphi,0:nz``; the ``phi`` direction is periodic.

   .. rubric:: Local Assumptions / Preconditions

   - The coordinate system is cylindrical; component/order conventions follow this page, and azimuths use the caller radian convention.
   - This page states only the local routine conventions; it does not assume a global driver unit system, time step, or boundary policy.

   .. rubric:: Implementation Notes

   - Clamps/wraps particle coordinates into the mesh and periodic ``phi`` range.
   - Uses radial and axial control-volume corrections to distribute charge to eight neighboring nodes.

   .. rubric:: Calling Notes

   - Output deposition arrays are normally zeroed before the call; the caller organizes accumulation over multiple particles.


   .. rubric:: Subroutine Description

   ``sub_B02_deposit_charge_3d_cyl`` deposits the charge ``qp*wp`` of one
   particle at ``(rp, phip, zp)`` to the eight neighboring cylindrical nodes.
   The weights are first-order in ``r``, ``phi``, and ``z``; normalization
   includes cylindrical radial factors, azimuthal length, and half-cell axial
   corrections at boundaries.

   The ``phi`` direction is periodic. After the particle loop, axis values
   ``rho(0,:,k)`` should be averaged with
   ``sub_B02_average_axis_charge_3d_cyl``.

   .. rubric:: Generated API

   .. doxygenfile:: sub_B02_deposit_charge_3d_cyl.f90
