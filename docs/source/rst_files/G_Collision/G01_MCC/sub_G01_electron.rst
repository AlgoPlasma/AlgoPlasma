sub_G01_electron.f90
--------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_G01_electron`` 执行电子碰撞后的速度/粒子状态更新，包括激发和电离相关分支。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``v``
        - in/out
        - ``(1:3)``
        - 入射粒子速度向量。
      * - ``me``
        - in
        - scalar or caller-provided array
        - 电子质量。
      * - ``mn``
        - in
        - scalar or caller-provided array
        - 中性粒子质量。
      * - ``e``
        - in
        - scalar or caller-provided array
        - 基本电荷或电荷单位换算因子。
      * - ``energy_excitation``
        - in
        - scalar or caller-provided array
        - 激发能量阈值。
      * - ``energy_ionization``
        - in
        - scalar or caller-provided array
        - 电离能量阈值。
      * - ``x``
        - in
        - ``(1:3)``
        - 粒子位置或 HYPRE solution 句柄，具体取决于接口上下文。
      * - ``par_e``
        - out
        - ``(1:6)``
        - 电子粒子数组。
      * - ``par_i``
        - out
        - ``(1:6)``
        - 离子粒子数组。
      * - ``vti``
        - in
        - scalar or caller-provided array
        - 中性粒子热速度。
      * - ``vd``
        - in
        - ``(1:3)``
        - 漂移速度向量。
      * - ``eV``
        - in
        - scalar or caller-provided array
        - 电子伏特换算因子。

   .. rubric:: 局部假设

   碰撞例程假定粒子数组 ``par(1:6,...)`` 中 ``1:3`` 是位置、``4:6`` 是速度。随机数来自 Fortran ``random_number``；能量、截面、密度和时间步单位必须由调用方保持自洽。这里不替调用方设置随机种子。

   .. rubric:: 实现逻辑

   实现先计算或复用 ``nu_max``，再用 null-collision 概率抽取候选粒子；每个候选粒子按截面权重选择碰撞类型并更新速度或粒子数组。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_G01_electron`` electron collision and post-collision velocity update.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``v``
        - in/out
        - ``(1:3)``
        - real (1:3), electron velocity.
      * - ``me``
        - in
        - scalar or caller-provided array
        - real, electron mass.
      * - ``mn``
        - in
        - scalar or caller-provided array
        - real, neutral particle mass.
      * - ``e``
        - in
        - scalar or caller-provided array
        - real, unit charge.
      * - ``energy_excitation``
        - in
        - scalar or caller-provided array
        - real, excitation energy, if > 0 then excitation is applied.
      * - ``energy_ionization``
        - in
        - scalar or caller-provided array
        - real, ionization energy, if > 0 then ionization is applied.
      * - ``x``
        - in
        - ``(1:3)``
        - real (1:3), electron position.
      * - ``par_e``
        - out
        - ``(1:6)``
        - real (1:6), new electron particle array.
      * - ``par_i``
        - out
        - ``(1:6)``
        - real (1:6), new ion particle array.
      * - ``vti``
        - in
        - scalar or caller-provided array
        - real, thermal velocity of ion.
      * - ``vd``
        - in
        - ``(1:3)``
        - real (1:3), drifting velocity of ion.
      * - ``eV``
        - in
        - scalar or caller-provided array
        - real, electron volt conversion factor.

   .. rubric:: Local Assumptions

   Collision routines assume ``par(1:6,...)`` stores position in ``1:3`` and velocity in ``4:6``. Random numbers come from Fortran ``random_number``. Units of energy, cross section, density, and time step must be kept self-consistent by the caller. These routines do not seed the RNG.

   .. rubric:: Implementation Notes

   The implementation computes or reuses ``nu_max``, samples candidate particles with a null-collision probability, then selects collision type by cross-section weights and updates velocity or particle arrays.

   .. rubric:: Generated API

   .. doxygenfile:: sub_G01_electron.f90
