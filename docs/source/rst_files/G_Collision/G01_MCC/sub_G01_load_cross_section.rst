sub_G01_load_cross_section.f90
------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_G01_load_cross_section`` 从文本文件载入能量-碰撞截面表，供 MCC 碰撞例程查询。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``Nmax``
        - in
        - scalar or caller-provided array
        - 截面表最大点数。
      * - ``cross_section``
        - out
        - ``(1:2,1:Nmax)``
        - 截面表；第一行通常为能量，第二行为截面值。
      * - ``path``
        - in
        - scalar or caller-provided array
        - 截面数据文件路径。

   .. rubric:: 局部假设

   碰撞例程假定粒子数组 ``par(1:6,...)`` 中 ``1:3`` 是位置、``4:6`` 是速度。随机数来自 Fortran ``random_number``；能量、截面、密度和时间步单位必须由调用方保持自洽。这里不替调用方设置随机种子。

   .. rubric:: 实现逻辑

   实现先计算或复用 ``nu_max``，再用 null-collision 概率抽取候选粒子；每个候选粒子按截面权重选择碰撞类型并更新速度或粒子数组。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_G01_load_cross_section`` load tabulated electron collision cross-section data.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``Nmax``
        - in
        - scalar or caller-provided array
        - Maximum number of table rows to load.
      * - ``cross_section``
        - out
        - ``(1:2,1:Nmax)``
        - Table ``(1:2,1:Nmax)``. Row 1 stores energies and row 2 stores the corresponding
          cross sections.
      * - ``path``
        - in
        - scalar or caller-provided array
        - Path to the cross-section data file.

   .. rubric:: Local Assumptions

   Collision routines assume ``par(1:6,...)`` stores position in ``1:3`` and velocity in ``4:6``. Random numbers come from Fortran ``random_number``. Units of energy, cross section, density, and time step must be kept self-consistent by the caller. These routines do not seed the RNG.

   .. rubric:: Implementation Notes

   The implementation computes or reuses ``nu_max``, samples candidate particles with a null-collision probability, then selects collision type by cross-section weights and updates velocity or particle arrays.

   .. rubric:: Generated API

   .. doxygenfile:: sub_G01_load_cross_section.f90
