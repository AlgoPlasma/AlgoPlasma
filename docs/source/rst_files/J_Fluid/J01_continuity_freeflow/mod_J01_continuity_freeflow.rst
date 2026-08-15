mod_J01_continuity_freeflow.f90
-------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_J01_continuity_freeflow`` 汇总自由流连续性方程更新入口。

   .. rubric:: 公开入口与 include 关系

   下列文件在 ``mod_J01_continuity_freeflow`` 的 ``contains`` 作用域内 include。
   调用方应 ``use mod_J01_continuity_freeflow`` 后调用具体例程；不要把这些
   include 文件单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_J01_continuity_freeflow.f90``
        - 用 3D Lax-Friedrichs 格式推进自由流连续性方程。
        - 已准备好 density、velocity、source 和 ghost/boundary 值后更新 ``n``。

   .. rubric:: 局部假设

   连续性方程例程只更新 ``il``/``iu`` 定义的 active cell。当前实现采用归一化 ``dx=dy=dz=dt=1``；边界和 ghost cell 需要调用方在进入本例程前准备好。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_J01_continuity_freeflow`` module wrapper for the free-flow continuity update routine.

   .. rubric:: Public Entries And Includes

   The following file is included inside the ``contains`` scope of
   ``mod_J01_continuity_freeflow``. Callers should
   ``use mod_J01_continuity_freeflow`` and call the concrete routine through the
   module; do not compile the include file separately.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_J01_continuity_freeflow.f90``
        - Advances the free-flow continuity equation with a 3D Lax-Friedrichs scheme.
        - Update ``n`` after density, velocity, source, and ghost/boundary values are prepared.

   .. rubric:: Local Assumptions

   The continuity routine updates only active cells defined by ``il``/``iu``. The current implementation uses normalized ``dx=dy=dz=dt=1``; boundary and ghost-cell values must be prepared by the caller before entry.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_J01_continuity_freeflow.f90
