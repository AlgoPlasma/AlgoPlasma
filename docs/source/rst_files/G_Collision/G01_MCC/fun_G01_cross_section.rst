fun_G01_cross_section.f90
-------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``fun_G01_cross_section`` 在截面表上按能量做线性插值，并对表外能量使用边界值。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``energy``
        - in
        - scalar or caller-provided array
        - 用于查询截面的粒子能量。
      * - ``Nmax``
        - in
        - scalar or caller-provided array
        - 截面表最大点数。
      * - ``cross_section``
        - in
        - ``(1:2,1:Nmax)``
        - 截面表；第一行通常为能量，第二行为截面值。

   .. rubric:: 返回值

   Interpolated or boundary-clamped cross-section value.

   .. rubric:: 局部假设

   碰撞例程假定粒子数组 ``par(1:6,...)`` 中 ``1:3`` 是位置、``4:6`` 是速度。随机数来自 Fortran ``random_number``；能量、截面、密度和时间步单位必须由调用方保持自洽。这里不替调用方设置随机种子。

   .. rubric:: 实现逻辑

   实现假定截面表能量点等间距，先由能量定位区间，再做线性插值；表外能量钳制到端点。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``fun_G01_cross_section`` interpolate a tabulated collision cross section.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``energy``
        - in
        - scalar or caller-provided array
        - Particle energy at which the cross section is evaluated.
      * - ``Nmax``
        - in
        - scalar or caller-provided array
        - Number of tabulated energy points.
      * - ``cross_section``
        - in
        - ``(1:2,1:Nmax)``
        - Tabulated data ``(1:2,1:Nmax)``. Row 1 stores energy values and row 2 stores
          cross-section values.

   .. rubric:: Return Value

   Interpolated or boundary-clamped cross-section value.

   .. rubric:: Local Assumptions

   Collision routines assume ``par(1:6,...)`` stores position in ``1:3`` and velocity in ``4:6``. Random numbers come from Fortran ``random_number``. Units of energy, cross section, density, and time step must be kept self-consistent by the caller. These routines do not seed the RNG.

   .. rubric:: Implementation Notes

   The implementation assumes uniformly spaced tabulated energies, locates the energy interval, then applies linear interpolation; out-of-range energies are clamped to endpoints.

   .. rubric:: Generated API

   The generated Doxygen record for this Fortran function is represented by the source-backed parameter and return tables above. Rendering this function signature directly through Breathe currently emits a parser warning, so the warning-free page keeps the manual API table as the canonical rendered form.
