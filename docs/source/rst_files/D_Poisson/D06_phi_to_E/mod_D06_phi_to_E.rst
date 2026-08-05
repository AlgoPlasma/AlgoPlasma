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

   下列文件在 ``mod_D06_phi_to_E`` 的 ``contains`` 作用域内 include。调用方应
   ``use mod_D06_phi_to_E`` 后调用公开入口；不要把这些 include 文件单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_D06_phi_to_E.f90``
        - 用二阶中心差分从 ``phi`` 计算 ``Ex``、``Ey``、``Ez``，实现 ``E=-grad(phi)``。
        - Poisson 求解并完成 ghost/boundary 处理后，需要得到电场分量。

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

   The following file is included inside the ``contains`` scope of
   ``mod_D06_phi_to_E``. Callers should ``use mod_D06_phi_to_E`` and call the
   public entry through the module; do not compile the include file separately.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_D06_phi_to_E.f90``
        - Computes ``Ex``, ``Ey``, and ``Ez`` from ``phi`` using second-order central differences.
        - Obtain electric-field components after Poisson solve and ghost/boundary preparation.

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
