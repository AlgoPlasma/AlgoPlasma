----------------------------------
mod_C02_gather_3Dxyz_bspline.f90
----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块职责

   ``mod_C02_gather_3Dxyz_bspline`` 是本目录的 Fortran module 入口。
   它不包含额外运行时逻辑，只通过 ``#include`` 把顶层 gather 子程序和辅助例程
   收集到同一个 module 中。

   .. rubric:: include 关系

   .. list-table::
      :header-rows: 1
      :widths: 42 58

      * - 文件 / 入口
        - 作用
      * - ``sub_C02_gather_3Dxyz_bspline``
        - 顶层单粒子 B-spline 电磁场 gather。
      * - ``sub_C02_bspline_stencil_1d``
        - 生成一个方向上的 B-spline 模板指标和权重。
      * - ``fun_C02_bspline_shape``
        - 计算中心化 B-spline 形函数值。
      * - ``fun_C02_gather_scalar_bspline``
        - 对一个标量场分量执行三维张量积加权求和。

   .. rubric:: 编译说明

   由于该 module 使用 ``#include`` 汇入源文件，编译时通常需要开启 C 预处理，
   例如使用 ``gfortran -cpp``。

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``mod_C02_gather_3Dxyz_bspline`` is the Fortran module entry for this
   directory. It has no additional runtime logic; it only collects the top-level
   gather routine and helper routines into one module through ``#include``.

   .. rubric:: Include Relation

   .. list-table::
      :header-rows: 1
      :widths: 42 58

      * - File / Entry
        - Role
      * - ``sub_C02_gather_3Dxyz_bspline``
        - Top-level single-particle B-spline electromagnetic-field gather.
      * - ``sub_C02_bspline_stencil_1d``
        - Builds B-spline stencil indices and weights in one direction.
      * - ``fun_C02_bspline_shape``
        - Evaluates the centered B-spline shape function.
      * - ``fun_C02_gather_scalar_bspline``
        - Applies the 3D tensor-product weighted sum to one scalar field component.

   .. rubric:: Compilation Note

   Because this module includes source files with ``#include``, builds normally
   need C preprocessing enabled, for example with ``gfortran -cpp``.

   .. rubric:: Generated API

   .. doxygenfile:: mod_C02_gather_3Dxyz_bspline.f90
