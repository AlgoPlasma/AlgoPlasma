sub_B01_scatter_3Dxyz_T.f90
---------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   按最近网格 cell 统计粒子某个分量的方差，得到温度型网格量。

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
      * - ``T``
        - ``out``
        - ``real(il(1):iu(1),il(2):iu(2),il(3):iu(3))``
        - 按 cell 聚合的方差/温度型数组
        - 调用者定义的密度/电流/统计量归一化
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
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

   - 第一遍按最近 cell 累加分量和计数，得到 cell 平均值。
   - 第二遍累加平方偏差并除以计数，得到方差。

   .. rubric:: 调用注意

   - 输出数组 ``T`` 由子程序内部在第二遍开始前自行清零，调用方无需清零。
   - 粒子靠近本地边界时，guard cell 必须已经有效。


   .. rubric:: 子程序说明

   ``sub_B01_scatter_3Dxyz_T`` 在每个网格单元内计算 ``par(d,p)`` 的方差。
   粒子通过 NGP 规则分配到单一单元；第一遍计算平均值，第二遍累加平方偏差。
   输出 ``T`` 是方差本身，不包含质量、Boltzmann 常数或温度单位换算。

   空单元保持为零；调用者应保证粒子位置映射到 ``T(il:iu)`` 范围内。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Computes a temperature-like variance of one particle component per nearest grid cell.

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
      * - ``T``
        - ``out``
        - ``real(il(1):iu(1),il(2):iu(2),il(3):iu(3))``
        - cell-grouped variance / temperature-like array
        - caller-defined density/current/statistic normalization
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
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

   - The first pass accumulates component sums and counts per nearest cell.
   - The second pass accumulates squared deviations and divides by the count.

   .. rubric:: Calling Notes

   - The output array ``T`` is zeroed internally by the subroutine before the second pass; the caller does not need to zero it.
   - Guard cells must be valid when particles are close to local boundaries.


   .. rubric:: Subroutine Description

   ``sub_B01_scatter_3Dxyz_T`` computes the variance of ``par(d,p)`` in each
   grid cell. Particles are assigned to one cell with an NGP rule; the first
   pass computes the mean and the second pass accumulates squared deviations.
   The output ``T`` is variance only and does not include mass, Boltzmann
   factors, or temperature-unit conversion.

   Empty cells remain zero. The caller must keep particle positions mapped
   inside the ``T(il:iu)`` range.

   .. rubric:: Generated API

   .. doxygenfile:: sub_B01_scatter_3Dxyz_T.f90
