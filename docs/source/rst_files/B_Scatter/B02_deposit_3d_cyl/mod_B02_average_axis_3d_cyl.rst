mod_B02_average_axis_3d_cyl.f90
-------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块职责

   本 module 页说明 Fortran module 的职责、公开入口和 ``#include`` 关系；具体参数以各 routine 页为准。

   .. rubric:: 公开入口 / include 关系

   .. list-table::
      :header-rows: 1
      :widths: 30 35 35

      * - 入口 / 文件
        - 角色
        - 关系
      * - ``sub_B02_average_axis_charge_3d_cyl``
        - 公开子程序入口。
        - 由 ``#include`` 汇入 module。
      * - ``sub_B02_average_axis_jz_3d_cyl``
        - 公开子程序入口。
        - 由 ``#include`` 汇入 module。

   .. rubric:: 局部假设

   - 坐标系为柱坐标，分量/位置顺序按本页参数表；方位角按调用者的弧度约定。
   - 本页只说明本 routine 的局部约定；不假设全局主程序的单位制、时间步或边界策略。

   .. rubric:: 实现逻辑

   - module 的 ``contains`` 段汇入或定义表中公开入口；它本身不是运行时 dispatcher。
   - 公开入口：``sub_B02_average_axis_charge_3d_cyl``，``sub_B02_average_axis_jz_3d_cyl``。

   .. rubric:: 调用注意

   - 上层代码应 ``use`` 该 module 后直接调用表中入口。
   - 若 module 通过 ``#include`` 汇入源文件，编译配置要保证 include 路径可见。


   .. rubric:: 模块说明

   ``mod_B02_average_axis_3d_cyl`` 收纳 B02 的轴线平均工具例程。它导出电荷密度
   ``rho`` 和轴向电流 ``jz`` 的 ``r=0`` 方位向平均后处理，供粒子循环结束后统一调用。

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   This module page describes the Fortran module role, public entries, and ``#include`` relation; detailed arguments live on the routine pages.

   .. rubric:: Public Entries / Include Relation

   .. list-table::
      :header-rows: 1
      :widths: 30 35 35

      * - Entry / File
        - Role
        - Relation
      * - ``sub_B02_average_axis_charge_3d_cyl``
        - Public subroutine entry.
        - Included into the module by ``#include``.
      * - ``sub_B02_average_axis_jz_3d_cyl``
        - Public subroutine entry.
        - Included into the module by ``#include``.

   .. rubric:: Local Assumptions

   - The coordinate system is cylindrical; component/order conventions follow this page, and azimuths use the caller radian convention.
   - This page states only the local routine conventions; it does not assume a global driver unit system, time step, or boundary policy.

   .. rubric:: Implementation Notes

   - The module ``contains`` section includes or defines the listed public entries; it is not a runtime dispatcher.
   - Public entries: ``sub_B02_average_axis_charge_3d_cyl``, ``sub_B02_average_axis_jz_3d_cyl``.

   .. rubric:: Calling Notes

   - Caller code should ``use`` the module and call the listed entries directly.
   - If the module uses ``#include``, the build configuration must expose the included source paths.


   .. rubric:: Module Description

   ``mod_B02_average_axis_3d_cyl`` collects the B02 axis-averaging utilities.
   It exports post-processing routines for azimuthally averaging charge density
   ``rho`` and axial current ``jz`` on the ``r=0`` axis after the particle
   loop.

   .. rubric:: Generated API

   .. doxygenfile:: mod_B02_average_axis_3d_cyl.f90
