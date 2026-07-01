------------------------
mod_A02_Boris_3Drtz.f90
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
      * - ``sub_A02_Boris_3Drtz_push_v_x``
        - 公开子程序入口。
        - 由 ``#include`` 汇入 module。

   .. rubric:: 局部假设

   - 坐标系为柱坐标，分量/位置顺序按本页参数表；方位角按调用者的弧度约定。
   - 本页只说明本 routine 的局部约定；不假设全局主程序的单位制、时间步或边界策略。

   .. rubric:: 实现逻辑

   - module 的 ``contains`` 段汇入或定义表中公开入口；它本身不是运行时 dispatcher。
   - 公开入口：``sub_A02_Boris_3Drtz_push_v_x``。
   - 柱坐标 Boris 的速度旋转可理解为先在局部笛卡尔正交基中完成普通 Boris 更新，
     再在推动位置后，根据新的柱坐标局部基对 :math:`(v_r,v_\theta)` 做一次速度分量修正。

   .. rubric:: 调用注意

   - 上层代码应 ``use`` 该 module 后直接调用表中入口。
   - 若 module 通过 ``#include`` 汇入源文件，编译配置要保证 include 路径可见。


   .. rubric:: 模块说明

   ``mod_A02_Boris_3Drtz`` 是 A02 柱坐标非相对论 Boris pusher 的
   Fortran module 入口。这个 module 通过源码级 ``include`` 收纳核心子程序，
   并把该子程序放在同一个 module 作用域中，方便调用端使用
   ``use mod_A02_Boris_3Drtz``。

   .. list-table::
      :header-rows: 1

      * - 收纳的子程序
        - 功能
      * - ``sub_A02_Boris_3Drtz_push_v_x``
        - 在柱坐标 :math:`(r,\theta,z)` 中，对单个粒子的位置
          :math:`\mathbf{x}` 和速度 :math:`\mathbf{v}` 执行一次完整的
          non-relativistic Boris push。

   .. rubric:: 使用说明

   当前 A02 pusher 以源码级 module 方式组织。调用程序通常先 ``#include``
   module 入口文件，再在程序中 ``use`` 对应 module：

   .. code-block:: fortran

      #include "A_Pusher/A02_Boris_3Drtz/mod_A02_Boris_3Drtz.f90"

      program demo_a02
          use mod_A02_Boris_3Drtz
          implicit none

          real :: x(3), v(3), E(3), B(3), k, dt

          x = (/1.0, 0.0, 0.0/)
          v = (/0.0, 0.0, 0.0/)
          E = 0.0
          B = (/0.0, 0.0, 1.0/)
          dt = 0.01
          k = 0.01

          call sub_A02_Boris_3Drtz_push_v_x(x, v, E, B, k, dt)
      end program demo_a02

   其中 ``x = (r, theta, z)``，``v = (v_r, v_theta, v_z)``，``E`` 和
   ``B`` 应使用柱坐标分量；``k`` 通常表示 :math:`q\Delta t/(2m)`。

   因为代码中使用的是默认 ``real``，单精度或双精度不是由源码中的 kind
   固定，而是在编译时决定。若希望默认 ``real`` 使用双精度，可按编译器选择相应选项，例如：

   .. code-block:: bash

      gfortran -cpp -O2 -fdefault-real-8 demo_a02.f90
      ifx -fpp -O2 -real-size 64 demo_a02.f90

   如果不启用这类默认实数精度选项，则 ``real`` 使用编译器默认精度。实际项目中应保证主程序、module 和所有相关子程序采用一致的默认 ``real`` 精度。

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
      * - ``sub_A02_Boris_3Drtz_push_v_x``
        - Public subroutine entry.
        - Included into the module by ``#include``.

   .. rubric:: Local Assumptions

   - The coordinate system is cylindrical; component/order conventions follow this page, and azimuths use the caller radian convention.
   - This page states only the local routine conventions; it does not assume a global driver unit system, time step, or boundary policy.

   .. rubric:: Implementation Notes

   - The module ``contains`` section includes or defines the listed public entries; it is not a runtime dispatcher.
   - Public entries: ``sub_A02_Boris_3Drtz_push_v_x``.
   - The cylindrical Boris step can be understood as first performing the
     usual Boris velocity rotation in a local Cartesian orthonormal basis,
     then correcting the :math:`(v_r,v_\theta)` components after the position
     advance so they are expressed in the new local cylindrical basis.

   .. rubric:: Calling Notes

   - Caller code should ``use`` the module and call the listed entries directly.
   - If the module uses ``#include``, the build configuration must expose the included source paths.


   .. rubric:: Module Description

   ``mod_A02_Boris_3Drtz`` is the Fortran module entry point for the A02
   non-relativistic Boris pusher in cylindrical coordinates. The module
   includes the core subroutine at source level and exposes it in the same
   module scope, so callers can use ``mod_A02_Boris_3Drtz``.

   .. list-table::
      :header-rows: 1

      * - Contained subroutine
        - Purpose
      * - ``sub_A02_Boris_3Drtz_push_v_x``
        - Advances a single particle position :math:`\mathbf{x}` and velocity
          :math:`\mathbf{v}` with one full non-relativistic Boris push in
          cylindrical coordinates :math:`(r,\theta,z)`.

   .. rubric:: Usage

   The A02 pusher is currently organized as a source-level Fortran module. A
   calling program usually includes the module entry file and then uses the
   corresponding module:

   .. code-block:: fortran

      #include "A_Pusher/A02_Boris_3Drtz/mod_A02_Boris_3Drtz.f90"

      program demo_a02
          use mod_A02_Boris_3Drtz
          implicit none

          real :: x(3), v(3), E(3), B(3), k, dt

          x = (/1.0, 0.0, 0.0/)
          v = (/0.0, 0.0, 0.0/)
          E = 0.0
          B = (/0.0, 0.0, 1.0/)
          dt = 0.01
          k = 0.01

          call sub_A02_Boris_3Drtz_push_v_x(x, v, E, B, k, dt)
      end program demo_a02

   Here ``x = (r, theta, z)``, ``v = (v_r, v_theta, v_z)``, and ``E`` and
   ``B`` should be supplied in cylindrical components. The scalar ``k`` usually
   denotes :math:`q\Delta t/(2m)`.

   The source uses default ``real`` declarations, so single versus double
   precision is selected at compile time rather than fixed by an explicit kind
   in the source. For double-precision default ``real``, choose the option
   supported by the compiler, for example:

   .. code-block:: bash

      gfortran -cpp -O2 -fdefault-real-8 demo_a02.f90
      ifx -fpp -O2 -real-size 64 demo_a02.f90

   Without such a default-real-size option, ``real`` keeps the compiler default
   precision. In a full application, compile the main program, module, and all
   related subroutines with consistent default ``real`` precision.

   .. rubric:: Generated API

   .. doxygenfile:: mod_A02_Boris_3Drtz.f90
