sub_G01_collision2.f90
----------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_G01_collision2`` 执行离子-中性粒子 MCC 碰撞，包含 charge exchange 和 ion-neutral 分支。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``np``
        - in/out
        - scalar or caller-provided array
        - 粒子数；读写例程只处理 ``par(:,1:np)``，碰撞/交换例程可能更新它。
      * - ``npmax``
        - in
        - scalar or caller-provided array
        - 粒子数组第二维容量上限，调用前必须足以容纳本地粒子。
      * - ``par``
        - in/out
        - ``(1:6,1:npmax)``
        - 粒子数组；通常 ``1:3`` 为位置，``4:6`` 为速度，列或第二维为粒子编号。
      * - ``dt``
        - in
        - scalar or caller-provided array
        - 时间步长。
      * - ``e``
        - in
        - scalar or caller-provided array
        - 基本电荷或电荷单位换算因子。
      * - ``m``
        - in
        - scalar or caller-provided array
        - 粒子质量。
      * - ``Nmax``
        - in
        - scalar or caller-provided array
        - 截面表最大点数。
      * - ``Ntype``
        - in
        - scalar or caller-provided array
        - 碰撞类型数。
      * - ``cross_section``
        - in
        - ``(1:2,1:Nmax,1:Ntype)``
        - 截面表；第一行通常为能量，第二行为截面值。
      * - ``collision_type``
        - in
        - ``(1:Ntype)``
        - 碰撞类型编号数组。
      * - ``vti``
        - in
        - scalar or caller-provided array
        - 中性粒子热速度。
      * - ``vd``
        - in
        - ``(1:3)``
        - 漂移速度向量。
      * - ``il``
        - in
        - ``(1:3)``
        - 本地 active cell 下界索引。
      * - ``iu``
        - in
        - ``(1:3)``
        - 本地 active cell 上界索引。
      * - ``den``
        - in
        - scalar or caller-provided array
        - 背景密度或中性粒子密度场，按粒子位置插值得到局部密度。
      * - ``energy_min``
        - in
        - scalar or caller-provided array
        - 计算/查表能量下界。
      * - ``energy_max``
        - in
        - scalar or caller-provided array
        - 计算/查表能量上界。
      * - ``nu_max``
        - in/out
        - scalar or caller-provided array
        - null-collision 最大频率，可输入缓存值并由例程更新。

   .. rubric:: 局部假设

   碰撞例程假定粒子数组 ``par(1:6,...)`` 中 ``1:3`` 是位置、``4:6`` 是速度。随机数来自 Fortran ``random_number``；能量、截面、密度和时间步单位必须由调用方保持自洽。这里不替调用方设置随机种子。

   .. rubric:: 实现逻辑

   实现先计算或复用 ``nu_max``，再用 null-collision 概率抽取候选粒子；每个候选粒子按截面权重选择碰撞类型并更新速度或粒子数组。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_G01_collision2`` ion-neutral collision process based on Vahedi's MCC algorithm.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``np``
        - in/out
        - scalar or caller-provided array
        - integer, number of ions.
      * - ``npmax``
        - in
        - scalar or caller-provided array
        - integer, maximum number of ions.
      * - ``par``
        - in/out
        - ``(1:6,1:npmax)``
        - real (1:6,1:npmax), particle array containing position and velocity.
      * - ``dt``
        - in
        - scalar or caller-provided array
        - real, time step.
      * - ``e``
        - in
        - scalar or caller-provided array
        - real, elementary charge.
      * - ``m``
        - in
        - scalar or caller-provided array
        - real, particle mass.
      * - ``Nmax``
        - in
        - scalar or caller-provided array
        - integer, maximum number of cross section data points.
      * - ``Ntype``
        - in
        - scalar or caller-provided array
        - integer, number of collision types.
      * - ``cross_section``
        - in
        - ``(1:2,1:Nmax,1:Ntype)``
        - real (1:2,1:Nmax,1:Ntype), cross section tables.
      * - ``collision_type``
        - in
        - ``(1:Ntype)``
        - integer (1:Ntype), collision type identifiers.
      * - ``vti``
        - in
        - scalar or caller-provided array
        - real, thermal velocity.
      * - ``vd``
        - in
        - ``(1:3)``
        - real (1:3), drift velocity.
      * - ``il``
        - in
        - ``(1:3)``
        - integer (1:3), cell-center lower indices in x,y,z.
      * - ``iu``
        - in
        - ``(1:3)``
        - integer (1:3), cell-center upper indices in x,y,z.
      * - ``den``
        - in
        - scalar or caller-provided array
        - real (il(1)-1:iu(1),il(2)-1:iu(2),il(3)-1:iu(3)), neutral density.
      * - ``energy_min``
        - in
        - scalar or caller-provided array
        - real, minimum energy for collision frequency evaluation.
      * - ``energy_max``
        - in
        - scalar or caller-provided array
        - real, maximum energy for collision frequency evaluation.
      * - ``nu_max``
        - in/out
        - scalar or caller-provided array
        - real, maximum null-collision frequency ``nu_prime``.

   .. rubric:: Local Assumptions

   Collision routines assume ``par(1:6,...)`` stores position in ``1:3`` and velocity in ``4:6``. Random numbers come from Fortran ``random_number``. Units of energy, cross section, density, and time step must be kept self-consistent by the caller. These routines do not seed the RNG.

   .. rubric:: Implementation Notes

   The implementation computes or reuses ``nu_max``, samples candidate particles with a null-collision probability, then selects collision type by cross-section weights and updates velocity or particle arrays.

   .. rubric:: Generated API

   .. doxygenfile:: sub_G01_collision2.f90
