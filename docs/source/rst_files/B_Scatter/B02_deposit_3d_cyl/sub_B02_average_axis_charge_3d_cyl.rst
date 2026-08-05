----------------------------------------
sub_B02_average_axis_charge_3d_cyl.f90
----------------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   对柱坐标轴线上的电荷密度做方位角平均。

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

   - 对每个 ``k``，沿所有 ``j`` 求轴线平均。
   - 把同一个物理轴线点的所有方位角副本替换成同一个平均值。

   .. rubric:: 调用注意

   - 调用前通常应清零输出沉积数组；多个粒子循环的累积顺序由调用者组织。


   .. rubric:: 子程序说明

   ``sub_B02_average_axis_charge_3d_cyl`` 对柱坐标轴线 ``r=0`` 上的电荷密度做方位向平均。由于 ``rho(0,j,k)`` 的所有 ``j`` 都表示同一个物理点，粒子循环结束后应把它们替换为同一平均值。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Azimuthally averages charge-density values on the cylindrical axis.

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

   - For each ``k``, averages over all ``j`` copies on the axis.
   - All azimuthal copies of the same physical axis point are replaced with that mean.

   .. rubric:: Calling Notes

   - Output deposition arrays are normally zeroed before the call; the caller organizes accumulation over multiple particles.


   .. rubric:: Subroutine Description

   ``sub_B02_average_axis_charge_3d_cyl`` averages charge density over the
   azimuthal direction on the cylindrical axis ``r=0``. Since all
   ``rho(0,j,k)`` entries represent the same physical point, they should be
   replaced by one shared mean value after the particle loop.

   .. rubric:: Generated API

   .. doxygenfile:: sub_B02_average_axis_charge_3d_cyl.f90
