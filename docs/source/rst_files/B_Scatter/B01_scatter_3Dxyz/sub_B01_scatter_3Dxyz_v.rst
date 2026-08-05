sub_B01_scatter_3Dxyz_v.f90
---------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   把粒子数组的指定分量按三维 CIC 权重沉积到网格。

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
      * - ``den``
        - ``in/out``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - 沉积或交换的三维网格数组
        - 调用者定义的密度/电流/统计量归一化
        - 数组覆盖本地区间外一层；CIC/插值会访问八个相邻节点。
      * - ``np``
        - ``in``
        - ``integer scalar``
        - 粒子数或粒子数组第二维
        - 整数下标或计数
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``par``
        - ``in``
        - ``real(1:6,1:np)``
        - 粒子相空间数组
        - 位置为网格指标单位，速度/其他分量按调用者约定
        - 使用 ``par(1:3,p)`` 作为位置；调用者保证粒子位于本地或 guard 可覆盖范围。
      * - ``w``
        - ``in``
        - ``real scalar``
        - 整体缩放因子或一维权重数组
        - 粒子权重或归一化因子
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``d``
        - ``in``
        - ``integer scalar``
        - 选择粒子数组分量的索引
        - 整数下标或计数
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。

   .. rubric:: 局部假设 / 前置条件

   - 粒子位置使用网格指标单位；沉积/插值模板必须落在本地数组或 guard cell 覆盖范围内。
   - 本页只说明本 routine 的局部约定；不假设全局主程序的单位制、时间步或边界策略。

   .. rubric:: 实现逻辑

   - 对每个粒子取 ``floor`` 得到参考节点，并计算三个方向的线性权重。
   - 将贡献加到八个节点；最后对整个输出数组乘以权重/归一化因子。

   .. rubric:: 调用注意

   - 调用前通常应清零输出沉积数组；多个粒子循环的累积顺序由调用者组织。
   - 粒子靠近本地边界时，guard cell 必须已经有效。


   .. rubric:: 子程序说明

   ``sub_B01_scatter_3Dxyz_v`` 是带物理量选择的 CIC 沉积例程。它把每个粒子的
   ``par(d,p)`` 按三线性权重分配到八个相邻节点，最后把 ``den`` 乘以 ``w``。
   该接口可用于数密度以外的动量密度或其他粒子属性沉积。

   调用前应清零 ``den``，并保证 ``d`` 是 ``1:6`` 内的有效分量索引。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Deposits a selected particle-array component to the grid with 3D CIC weights.

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
      * - ``den``
        - ``in/out``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - 3D deposition/exchange array
        - caller-defined density/current/statistic normalization
        - Array covers one layer around the local range; CIC/interpolation touches the eight neighboring nodes.
      * - ``np``
        - ``in``
        - ``integer scalar``
        - particle count or second dimension of par
        - integer index or count
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``par``
        - ``in``
        - ``real(1:6,1:np)``
        - particle phase-space array
        - positions in grid-index units; other components follow caller convention
        - Uses ``par(1:3,p)`` as position; caller keeps particles inside the local or guard-covered range.
      * - ``w``
        - ``in``
        - ``real scalar``
        - global scaling factor or 1D weight array
        - particle weight or normalization factor
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``d``
        - ``in``
        - ``integer scalar``
        - selected component of the particle array
        - integer index or count
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.

   .. rubric:: Local Assumptions / Preconditions

   - Particle positions are in grid-index units; the deposition/interpolation stencil must lie inside the local array or its guard cells.
   - This page states only the local routine conventions; it does not assume a global driver unit system, time step, or boundary policy.

   .. rubric:: Implementation Notes

   - For each particle, ``floor`` gives the reference node and three linear weights.
   - Contributions are added to the eight nodes, then the whole output array is scaled.

   .. rubric:: Calling Notes

   - Output deposition arrays are normally zeroed before the call; the caller organizes accumulation over multiple particles.
   - Guard cells must be valid when particles are close to local boundaries.


   .. rubric:: Subroutine Description

   ``sub_B01_scatter_3Dxyz_v`` is the CIC deposition routine with a selectable
   particle component. It distributes ``par(d,p)`` from each particle to the
   eight neighboring nodes with trilinear weights, then scales ``den`` by
   ``w``. The interface can be used for momentum density or other particle
   attributes beyond number density.

   The caller should zero ``den`` before the call and keep ``d`` within the
   valid ``1:6`` component range.

   .. rubric:: Generated API

   .. doxygenfile:: sub_B01_scatter_3Dxyz_v.f90
