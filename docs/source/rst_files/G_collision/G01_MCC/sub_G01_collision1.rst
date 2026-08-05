sub_G01_collision1.f90
----------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_G01_collision1`` 执行电子-中性粒子 MCC 碰撞，并可能更新电子和离子粒子数。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``np1``
        - in/out
        - scalar or caller-provided array
        - integer, number of electron particles.
      * - ``np2``
        - in/out
        - scalar or caller-provided array
        - integer, number of ion particles.
      * - ``npmax1``
        - in
        - scalar or caller-provided array
        - integer, maximum number of electron particles.
      * - ``npmax2``
        - in
        - scalar or caller-provided array
        - integer, maximum number of ion particles.
      * - ``par1``
        - in/out
        - ``(1:6,1:npmax1)``
        - real (1:6,1:npmax1), electron particle array.
      * - ``par2``
        - in/out
        - ``(1:6,1:npmax2)``
        - real (1:6,1:npmax2), ion particle array.
      * - ``dt``
        - in
        - scalar or caller-provided array
        - 时间步长。
      * - ``e``
        - in
        - scalar or caller-provided array
        - 基本电荷或电荷单位换算因子。
      * - ``m1``
        - in
        - scalar or caller-provided array
        - 第一类粒子质量。
      * - ``m2``
        - in
        - scalar or caller-provided array
        - 第二类粒子质量。
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
      * - ``energy_excitation``
        - in
        - scalar or caller-provided array
        - 激发能量阈值。
      * - ``energy_ionization``
        - in
        - scalar or caller-provided array
        - 电离能量阈值。
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
      * - ``S``
        - in/out
        - scalar or caller-provided array
        - 源项数组。
      * - ``energy_min``
        - in
        - scalar or caller-provided array
        - 计算/查表能量下界。
      * - ``energy_max``
        - in
        - scalar or caller-provided array
        - 计算/查表能量上界。
      * - ``eV``
        - in
        - scalar or caller-provided array
        - 电子伏特换算因子。
      * - ``wei``
        - in
        - scalar or caller-provided array
        - 粒子权重。
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

   ``sub_G01_collision1`` electron-neutral collision process based on Vahedi's MCC algorithm.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``np1``
        - in/out
        - scalar or caller-provided array
        - integer, number of electron particles.
      * - ``np2``
        - in/out
        - scalar or caller-provided array
        - integer, number of ion particles.
      * - ``npmax1``
        - in
        - scalar or caller-provided array
        - integer, maximum number of electron particles.
      * - ``npmax2``
        - in
        - scalar or caller-provided array
        - integer, maximum number of ion particles.
      * - ``par1``
        - in/out
        - ``(1:6,1:npmax1)``
        - real (1:6,1:npmax1), electron particle array.
      * - ``par2``
        - in/out
        - ``(1:6,1:npmax2)``
        - real (1:6,1:npmax2), ion particle array.
      * - ``dt``
        - in
        - scalar or caller-provided array
        - real, simulation time step.
      * - ``e``
        - in
        - scalar or caller-provided array
        - real, unit charge.
      * - ``m1``
        - in
        - scalar or caller-provided array
        - real, electron mass.
      * - ``m2``
        - in
        - scalar or caller-provided array
        - real, neutral particle mass.
      * - ``Nmax``
        - in
        - scalar or caller-provided array
        - integer, maximum number of energy grid points.
      * - ``Ntype``
        - in
        - scalar or caller-provided array
        - integer, number of collision types.
      * - ``cross_section``
        - in
        - ``(1:2,1:Nmax,1:Ntype)``
        - real (1:2,1:Nmax,1:Ntype), cross-section tables.
      * - ``collision_type``
        - in
        - ``(1:Ntype)``
        - integer (1:Ntype), collision type identifiers.
      * - ``vti``
        - in
        - scalar or caller-provided array
        - real, thermal velocity of ions.
      * - ``vd``
        - in
        - ``(1:3)``
        - real (1:3), drifting velocity.
      * - ``energy_excitation``
        - in
        - scalar or caller-provided array
        - real, excitation energy threshold.
      * - ``energy_ionization``
        - in
        - scalar or caller-provided array
        - real, ionization energy threshold.
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
        - real, neutral density defined on grid points.
      * - ``S``
        - in/out
        - scalar or caller-provided array
        - real, ionization source term on grid points.
      * - ``energy_min``
        - in
        - scalar or caller-provided array
        - real, minimum energy (eV) for nu_prime evaluation.
      * - ``energy_max``
        - in
        - scalar or caller-provided array
        - real, maximum energy (eV) for nu_prime evaluation.
      * - ``eV``
        - in
        - scalar or caller-provided array
        - real, electron volt conversion factor.
      * - ``wei``
        - in
        - scalar or caller-provided array
        - real, particle weight.
      * - ``nu_max``
        - in/out
        - scalar or caller-provided array
        - real, maximum collision frequency ``nu_prime``.

   .. rubric:: Local Assumptions

   Collision routines assume ``par(1:6,...)`` stores position in ``1:3`` and velocity in ``4:6``. Random numbers come from Fortran ``random_number``. Units of energy, cross section, density, and time step must be kept self-consistent by the caller. These routines do not seed the RNG.

   .. rubric:: Implementation Notes

   The implementation computes or reuses ``nu_max``, samples candidate particles with a null-collision probability, then selects collision type by cross-section weights and updates velocity or particle arrays.

   .. rubric:: Generated API

   .. doxygenfile:: sub_G01_collision1.f90
