mod_J01_continuity_freeflow.f90
-------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 用途

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
        - 已准备好密度、速度、扣减量与保护层后更新 ``n``。
      * - ``sub_J01_continuity_freeflow_2Drz.f90``
        - 二维柱坐标给定速度通量与单步密度更新。
        - 调用方已经有速度场，不需要在此跟踪粒子。

   .. rubric:: 使用条件

   仅三维接口使用 ``il``/``iu`` 与保护层，采用归一化 ``dx=dy=dz=dt=1``。二维接口使用单元中心数组、物理体积和面积，不沿用三维索引布局。

   .. rubric:: 计算过程

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用说明

   :doc:`J01 算法说明 <continuity>` 给出两个实现文件的参数、公式和用途；:doc:`J01 测试 </tests/011_fluid/J01_tests>` 列出各测试调用的接口。

.. container:: ap-lang ap-lang-en ap-fluid-doc

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
      * - ``sub_J01_continuity_freeflow_2Drz.f90``
        - Cylindrical prescribed-velocity fluxes and a continuity step.
        - Use when a velocity field is already available.

   .. rubric:: Local Assumptions

   The continuity routine updates only active cells defined by ``il``/``iu``. The current implementation uses normalized ``dx=dy=dz=dt=1``; boundary and ghost-cell values must be prepared by the caller before entry.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_J01_continuity_freeflow.f90
