mod_G01_collision.f90
---------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_G01_collision`` 是该目录的模块包装器，集中 include 或暴露本组公开入口。

   .. rubric:: 公开入口与 include 关系

   下列源码文件由 ``mod_G01_collision`` 在 ``contains`` 中 include；调用方通常
   ``use mod_G01_collision`` 后调用具体例程，不应把这些 include 文件当作独立
   translation unit 编译。

   .. list-table::
      :header-rows: 1
      :widths: 32 36 32

      * - 文件
        - 功能
        - 何时使用
      * - ``sub_G01_load_cross_section.f90``
        - 读取两列能量-截面表，补齐到 ``Nmax``，并保持最后一个截面值。
        - 初始化碰撞截面数据时调用。
      * - ``sub_G01_collision1.f90``
        - 执行电子-中性粒子 MCC，覆盖弹性散射、激发和电离，并在电离时生成新电子/离子和源项。
        - 推进电子碰撞过程时调用。
      * - ``sub_G01_collision2.f90``
        - 执行离子-中性粒子 MCC，覆盖电荷交换和离子-中性粒子弹性散射。
        - 推进离子碰撞过程时调用。
      * - ``sub_G01_electron.f90``
        - 根据已选电子碰撞类型更新碰后速度，并在电离事件中抽样二次电子和离子。
        - 由电子碰撞例程内部调用，通常不是外层主循环的直接入口。
      * - ``fun_G01_cross_section.f90``
        - 对均匀能量网格上的截面表做线性插值，超出表范围时钳制到边界值。
        - 碰撞频率评估需要查询指定能量截面时调用。

   .. rubric:: 局部假设

   碰撞例程假定粒子数组 ``par(1:6,...)`` 中 ``1:3`` 是位置、``4:6`` 是速度。随机数来自 Fortran ``random_number``；能量、截面、密度和时间步单位必须由调用方保持自洽。这里不替调用方设置随机种子。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_G01_collision`` is documented by its generated API and local notes on this page.

   .. rubric:: Public Entries And Includes

   The following source files are included inside ``mod_G01_collision`` under
   ``contains``. Callers normally ``use mod_G01_collision`` and call the
   concrete routines; the include files are not standalone translation units.

   .. list-table::
      :header-rows: 1
      :widths: 32 36 32

      * - File
        - Function
        - Typical use
      * - ``sub_G01_load_cross_section.f90``
        - Reads a two-column energy/cross-section table, pads it to ``Nmax``, and holds the last cross-section value.
        - During collision table initialization.
      * - ``sub_G01_collision1.f90``
        - Runs electron-neutral MCC for elastic scattering, excitation, and ionization, including secondary particles and source deposition.
        - During electron collision advancement.
      * - ``sub_G01_collision2.f90``
        - Runs ion-neutral MCC for charge exchange and ion-neutral elastic scattering.
        - During ion collision advancement.
      * - ``sub_G01_electron.f90``
        - Updates the post-collision electron velocity and samples secondary electron/ion particles for ionization events.
        - Called internally by the electron collision routine; normally not the outer loop entry.
      * - ``fun_G01_cross_section.f90``
        - Linearly interpolates a uniformly spaced cross-section table and clamps out-of-range energies to boundary values.
        - When evaluating collision frequencies at a given particle energy.

   .. rubric:: Local Assumptions

   Collision routines assume ``par(1:6,...)`` stores position in ``1:3`` and velocity in ``4:6``. Random numbers come from Fortran ``random_number``. Units of energy, cross section, density, and time step must be kept self-consistent by the caller. These routines do not seed the RNG.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_G01_collision.f90
