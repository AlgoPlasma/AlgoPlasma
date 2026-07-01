------------------------
mod_A01_Boris_3Dxyz.f90
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
      * - ``sub_A01_Boris_3Dxyz``
        - 公开子程序入口。
        - 由 ``#include`` 汇入 module。

   .. rubric:: 局部假设

   - 坐标系为 Cartesian，分量顺序为 ``(x,y,z)``。
   - 本页只说明本 routine 的局部约定；不假设全局主程序的单位制、时间步或边界策略。

   .. rubric:: 实现逻辑

   - module 的 ``contains`` 段汇入或定义表中公开入口；它本身不是运行时 dispatcher。
   - 公开入口：``sub_A01_Boris_3Dxyz``。

   .. rubric:: 调用注意

   - 上层代码应 ``use`` 该 module 后直接调用表中入口。
   - 若 module 通过 ``#include`` 汇入源文件，编译配置要保证 include 路径可见。


   .. rubric:: 模块说明

   ``mod_A01_Boris_3Dxyz`` 是 A01 直角坐标非相对论 Boris pusher 的
   Fortran module 入口。这个 module 本身只负责组织接口：它通过源码级
   ``include`` 收纳核心子程序，并把该子程序放在同一个 module 作用域中，
   方便调用端使用 ``use mod_A01_Boris_3Dxyz``。

   .. list-table::
      :header-rows: 1

      * - 收纳的子程序
        - 功能
      * - ``sub_A01_Boris_3Dxyz``
        - 对单个粒子的三维直角坐标速度 :math:`\mathbf{v}` 执行一次完整的
          non-relativistic Boris 更新。

   .. rubric:: 使用说明

   当前 A01 pusher 以源码级 module 方式组织。调用程序通常先 ``#include``
   module 入口文件，再在程序中 ``use`` 对应 module：

   .. code-block:: fortran

      #include "A_Pusher/A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz.f90"

      program demo_a01
          use mod_A01_Boris_3Dxyz
          implicit none

          real :: v(3), E(3), B(3), k

          v = (/1.0, 0.0, 0.0/)
          E = 0.0
          B = (/0.0, 0.0, 1.0/)
          k = 0.01

          call sub_A01_Boris_3Dxyz(v, E, B, k)
      end program demo_a01

   因为代码中使用的是默认 ``real``，单精度或双精度不是由源码中的 kind
   固定，而是在编译时决定。若希望默认 ``real`` 使用双精度，可按编译器选择相应选项，例如：

   .. code-block:: bash

      gfortran -cpp -O2 -fdefault-real-8 demo_a01.f90
      ifx -fpp -O2 -real-size 64 demo_a01.f90

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
      * - ``sub_A01_Boris_3Dxyz``
        - Public subroutine entry.
        - Included into the module by ``#include``.

   .. rubric:: Local Assumptions

   - The coordinate system is Cartesian with component order ``(x,y,z)``.
   - This page states only the local routine conventions; it does not assume a global driver unit system, time step, or boundary policy.

   .. rubric:: Implementation Notes

   - The module ``contains`` section includes or defines the listed public entries; it is not a runtime dispatcher.
   - Public entries: ``sub_A01_Boris_3Dxyz``.

   .. rubric:: Calling Notes

   - Caller code should ``use`` the module and call the listed entries directly.
   - If the module uses ``#include``, the build configuration must expose the included source paths.


   .. rubric:: Module Description

   ``mod_A01_Boris_3Dxyz`` is the Fortran module entry point for the A01
   non-relativistic Boris pusher in 3D Cartesian coordinates. The module is an
   interface wrapper rather than the algorithm implementation: it includes the
   core subroutine at source level and exposes it in the same module scope, so
   callers can use ``mod_A01_Boris_3Dxyz``.

   .. list-table::
      :header-rows: 1

      * - Contained subroutine
        - Purpose
      * - ``sub_A01_Boris_3Dxyz``
        - Advances a single particle velocity :math:`\mathbf{v}` with one full
          non-relativistic Boris update in 3D Cartesian coordinates.

   .. rubric:: Usage

   The A01 pusher is currently organized as a source-level Fortran module. A
   calling program usually includes the module entry file and then uses the
   corresponding module:

   .. code-block:: fortran

      #include "A_Pusher/A01_Boris_3Dxyz/mod_A01_Boris_3Dxyz.f90"

      program demo_a01
          use mod_A01_Boris_3Dxyz
          implicit none

          real :: v(3), E(3), B(3), k

          v = (/1.0, 0.0, 0.0/)
          E = 0.0
          B = (/0.0, 0.0, 1.0/)
          k = 0.01

          call sub_A01_Boris_3Dxyz(v, E, B, k)
      end program demo_a01

   The source uses default ``real`` declarations, so single versus double
   precision is selected at compile time rather than fixed by an explicit kind
   in the source. For double-precision default ``real``, choose the option
   supported by the compiler, for example:

   .. code-block:: bash

      gfortran -cpp -O2 -fdefault-real-8 demo_a01.f90
      ifx -fpp -O2 -real-size 64 demo_a01.f90

   Without such a default-real-size option, ``real`` keeps the compiler default
   precision. In a full application, compile the main program, module, and all
   related subroutines with consistent default ``real`` precision.

   .. rubric:: Generated API

   .. doxygenfile:: mod_A01_Boris_3Dxyz.f90
