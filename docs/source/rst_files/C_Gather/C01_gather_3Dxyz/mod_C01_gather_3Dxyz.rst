------------------------
mod_C01_gather_3Dxyz.f90
------------------------

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
      * - ``sub_C01_gather_3Dxyz``
        - 公开子程序入口。
        - 由 ``#include`` 汇入 module。
      * - ``sub_C01_gather_3Dxyz_push``
        - 公开子程序入口。
        - 由 ``#include`` 汇入 module。

   .. rubric:: 局部假设

   - 粒子位置使用网格指标单位；沉积/插值模板必须落在本地数组或 guard cell 覆盖范围内。
   - 本页只说明本 routine 的局部约定；不假设全局主程序的单位制、时间步或边界策略。

   .. rubric:: 实现逻辑

   - module 的 ``contains`` 段汇入或定义表中公开入口；它本身不是运行时 dispatcher。
   - 公开入口：``sub_C01_gather_3Dxyz``，``sub_C01_gather_3Dxyz_push``。

   .. rubric:: 调用注意

   - 上层代码应 ``use`` 该 module 后直接调用表中入口。
   - 若 module 通过 ``#include`` 汇入源文件，编译配置要保证 include 路径可见。


   .. rubric:: 模块说明

   ``mod_C01_gather_3Dxyz`` 是 C01 的源码级入口文件。调用端通常包含该文件并使用 ``use mod_C01_gather_3Dxyz``，从而获得 ``sub_C01_gather_3Dxyz`` 与 ``sub_C01_gather_3Dxyz_push``。

   由于该入口文件使用 ``#include`` 收集子程序源文件，编译时通常需要开启 C 预处理，例如 ``gfortran -cpp``。

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
      * - ``sub_C01_gather_3Dxyz``
        - Public subroutine entry.
        - Included into the module by ``#include``.
      * - ``sub_C01_gather_3Dxyz_push``
        - Public subroutine entry.
        - Included into the module by ``#include``.

   .. rubric:: Local Assumptions

   - Particle positions are in grid-index units; the deposition/interpolation stencil must lie inside the local array or its guard cells.
   - This page states only the local routine conventions; it does not assume a global driver unit system, time step, or boundary policy.

   .. rubric:: Implementation Notes

   - The module ``contains`` section includes or defines the listed public entries; it is not a runtime dispatcher.
   - Public entries: ``sub_C01_gather_3Dxyz``, ``sub_C01_gather_3Dxyz_push``.

   .. rubric:: Calling Notes

   - Caller code should ``use`` the module and call the listed entries directly.
   - If the module uses ``#include``, the build configuration must expose the included source paths.


   .. rubric:: Module Description

   ``mod_C01_gather_3Dxyz`` is the C01 source-level entry file. A caller usually includes this file and then uses ``mod_C01_gather_3Dxyz`` to access ``sub_C01_gather_3Dxyz`` and ``sub_C01_gather_3Dxyz_push``.

   Because this entry file collects subroutine sources with ``#include``, compilation normally requires C preprocessing, for example ``gfortran -cpp``.

   .. rubric:: Generated API

   .. doxygenfile:: mod_C01_gather_3Dxyz.f90
