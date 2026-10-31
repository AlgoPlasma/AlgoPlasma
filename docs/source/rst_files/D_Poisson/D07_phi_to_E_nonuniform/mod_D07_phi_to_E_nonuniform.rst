mod_D07_phi_to_E_nonuniform.f90
===============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_D07_phi_to_E_nonuniform`` 是该目录的模块包装器，通过 ``include`` 汇总
   ``sub_D07_phi_to_E_nonuniform.f90``，对外暴露同名子程序。

   .. rubric:: 公开入口与 include 关系

   ``sub_D07_phi_to_E_nonuniform.f90`` 在模块的 ``contains`` 作用域内 include。
   调用方应 ``use`` 模块；不要单独编译被 include 的子程序文件。

   .. rubric:: 局部假设

   使用 D04 的单元中心柱坐标布局，单元中心位于两侧单元面的中点。
   ``phi`` 和电场数组各方向均含一层 ghost 格；``dr/da/dz`` 也含一层 ghost 值且必须为正。
   ``rface_lo`` 是本地最低径向面的全局半径，中心半径由它和 ``dr`` 累积得到。
   无 MPI 或外部库依赖。

   .. rubric:: 实现逻辑

   ``use mod_D07_phi_to_E_nonuniform`` 后调用 ``sub_D07_phi_to_E_nonuniform``。
   编译模块入口需开启预处理，例如 ``gfortran -cpp``；双精度可统一使用 ``-fdefault-real-8``。


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_D07_phi_to_E_nonuniform`` includes ``sub_D07_phi_to_E_nonuniform.f90``
   and exposes the public subroutine through the module.

   .. rubric:: Public Entries and Includes

   ``sub_D07_phi_to_E_nonuniform.f90`` is included inside the module contains scope.
   Use the module; do not compile the included source separately.

   .. rubric:: Local Assumptions

   Use D04 cell-centered cylindrical geometry, with each center at the midpoint
   of its two faces. Potential and field arrays carry one ghost layer per side;
   positive width arrays also carry one ghost value per side. ``rface_lo`` is
   the global radius of the lower local radial face; center radii are accumulated
   from this face using ``dr``. No MPI or external library dependencies.

   .. rubric:: Implementation Notes

   ``use mod_D07_phi_to_E_nonuniform`` and call ``sub_D07_phi_to_E_nonuniform``.
   Enable preprocessing, e.g. ``gfortran -cpp``; use ``-fdefault-real-8`` consistently for double precision.

   .. rubric:: Generated API

   .. doxygenfile:: mod_D07_phi_to_E_nonuniform.f90
