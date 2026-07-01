mod_D06_phi_to_E.f90
--------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_D06_phi_to_E`` 是该目录的模块包装器，通过 ``include`` 汇总
   ``sub_D06_phi_to_E.f90``，对外暴露 ``sub_D06_phi_to_E`` 子程序。

   .. rubric:: 公开入口与 include 关系

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - 文件/符号
        - 角色
        - 调用约定
      * - ``sub_D06_phi_to_E.f90``
        - 被模块 include 的公开源码入口
        - 调用方通过本模块 ``use`` 后访问；不要把 include 文件当作独立 translation unit 编译。

   .. rubric:: 局部假设

   本页例程使用 cell-centered Cartesian ``(x,y,z)`` 布局；``phi``、``Ex``、``Ey``、``Ez``
   均包含每侧一层 ghost 格。差分系数假设 dx=dy=dz=1，调用方负责换算为实际物理单位。
   无 MPI 或外部库依赖。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 汇总本目录公开入口；调用方 ``use`` 模块后调用
   ``sub_D06_phi_to_E``。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_D06_phi_to_E`` is the module wrapper for this directory. It groups
   ``sub_D06_phi_to_E.f90`` via ``include`` and exposes the ``sub_D06_phi_to_E``
   subroutine to callers.

   .. rubric:: Public Entries and Includes

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - File/symbol
        - Role
        - Calling convention
      * - ``sub_D06_phi_to_E.f90``
        - included public source entry
        - Call through this module after ``use``; include files are not
          standalone translation units.

   .. rubric:: Local Assumptions

   These routines use a cell-centered Cartesian ``(x,y,z)`` layout; ``phi``,
   ``Ex``, ``Ey``, and ``Ez`` all carry one ghost layer per side. The
   finite-difference coefficients assume dx=dy=dz=1; the caller converts to
   physical units. No MPI or external library dependencies.

   .. rubric:: Implementation Notes

   This module groups public entries via ``include``; callers ``use`` the module
   and call ``sub_D06_phi_to_E`` directly.

   .. rubric:: Generated API

   .. doxygenfile:: mod_D06_phi_to_E.f90
