----------------------------------
mod_B02_deposit_current_3d_cyl.f90
----------------------------------

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
      * - ``sub_B02_deposit_current_3d_cyl``
        - 公开子程序入口。
        - 由 ``#include`` 汇入 module。

   .. rubric:: 局部假设

   - 坐标系为柱坐标，分量/位置顺序按本页参数表；方位角按调用者的弧度约定。
   - 本页只说明本 routine 的局部约定；不假设全局主程序的单位制、时间步或边界策略。

   .. rubric:: 实现逻辑

   - module 的 ``contains`` 段汇入或定义表中公开入口；它本身不是运行时 dispatcher。
   - 公开入口：``sub_B02_deposit_current_3d_cyl``。

   .. rubric:: 调用注意

   - 上层代码应 ``use`` 该 module 后直接调用表中入口。
   - 若 module 通过 ``#include`` 汇入源文件，编译配置要保证 include 路径可见。


   .. rubric:: 模块说明

   ``mod_B02_deposit_current_3d_cyl`` 是 B02 柱坐标电流沉积的 module 入口。
   它导出 ``sub_B02_deposit_current_3d_cyl``，用于根据粒子在一个时间步内的旧位置和新位置沉积 ``Jr``、``Jphi`` 和 ``Jz``。

   该 module 内部还包含轨迹切分和单元内沉积 helper，调用者通常只需要使用公开的电流沉积子程序。

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
      * - ``sub_B02_deposit_current_3d_cyl``
        - Public subroutine entry.
        - Included into the module by ``#include``.

   .. rubric:: Local Assumptions

   - The coordinate system is cylindrical; component/order conventions follow this page, and azimuths use the caller radian convention.
   - This page states only the local routine conventions; it does not assume a global driver unit system, time step, or boundary policy.

   .. rubric:: Implementation Notes

   - The module ``contains`` section includes or defines the listed public entries; it is not a runtime dispatcher.
   - Public entries: ``sub_B02_deposit_current_3d_cyl``.

   .. rubric:: Calling Notes

   - Caller code should ``use`` the module and call the listed entries directly.
   - If the module uses ``#include``, the build configuration must expose the included source paths.


   .. rubric:: Module Description

   ``mod_B02_deposit_current_3d_cyl`` is the module entry point for B02
   cylindrical current deposition. It exports
   ``sub_B02_deposit_current_3d_cyl`` for depositing ``Jr``, ``Jphi``, and
   ``Jz`` from old and new particle positions over one time step.

   The module also contains internal helpers for trajectory splitting and
   single-cell deposition; callers usually need only the public current
   deposition subroutine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_B02_deposit_current_3d_cyl.f90
