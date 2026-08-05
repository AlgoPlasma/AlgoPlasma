----------------------------------
mod_B03_scatter_3Dxyz_bspline.f90
----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_B03_scatter_3Dxyz_bspline`` 是 B03 的源码级 module 入口。它通过
   ``#include`` 汇入粒子数沉积、粒子分量沉积、一维 stencil 和中心化
   B-spline 形函数实现。

   .. rubric:: 组成文件

   .. list-table::
      :header-rows: 1
      :widths: 42 58

      * - include 文件
        - 作用
      * - ``sub_B03_scatter_3Dxyz_bspline.f90``
        - 顶层粒子数沉积接口。
      * - ``sub_B03_scatter_3Dxyz_bspline_v.f90``
        - 顶层粒子分量沉积接口。
      * - ``sub_B03_bspline_stencil_1d.f90``
        - 一个方向上的 B-spline stencil 生成。
      * - ``fun_B03_bspline_shape.f90``
        - 中心化 B-spline 形函数递归求值。

   .. rubric:: 编译约定

   由于 module 内部使用 ``#include``，编译时需要启用 Fortran 预处理，例如
   ``gfortran -cpp``。若主程序使用 ``-fdefault-real-8`` 或其他实数精度选项，
   应对本 module 使用相同选项，避免接口中的默认 ``real`` 精度不一致。

   .. rubric:: 使用示例

   .. code-block:: fortran

      use mod_B03_scatter_3Dxyz_bspline

      den = 0.0
      call sub_B03_scatter_3Dxyz_bspline(il,iu,den,np,par,w,order)

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_B03_scatter_3Dxyz_bspline`` is the source-level module entry for B03.
   It includes the particle-number deposition routine, the particle-component
   deposition routine, the 1D stencil builder, and the centered B-spline shape
   function implementation.

   .. rubric:: Included Files

   .. list-table::
      :header-rows: 1
      :widths: 42 58

      * - Included file
        - Role
      * - ``sub_B03_scatter_3Dxyz_bspline.f90``
        - Top-level particle-number deposition interface.
      * - ``sub_B03_scatter_3Dxyz_bspline_v.f90``
        - Top-level particle-component deposition interface.
      * - ``sub_B03_bspline_stencil_1d.f90``
        - B-spline stencil generation in one direction.
      * - ``fun_B03_bspline_shape.f90``
        - Recursive evaluation of the centered B-spline shape function.

   .. rubric:: Compilation Convention

   Because the module uses ``#include``, Fortran preprocessing is required,
   for example ``gfortran -cpp``. If the main program uses ``-fdefault-real-8``
   or another real-precision option, compile this module with the same option
   so that default ``real`` arguments have consistent precision.

   .. rubric:: Usage Example

   .. code-block:: fortran

      use mod_B03_scatter_3Dxyz_bspline

      den = 0.0
      call sub_B03_scatter_3Dxyz_bspline(il,iu,den,np,par,w,order)

   .. rubric:: Generated API

   .. doxygenfile:: mod_B03_scatter_3Dxyz_bspline.f90
