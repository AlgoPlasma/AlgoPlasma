-----------------------------------
fun_C02_gather_scalar_bspline.f90
-----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``fun_C02_gather_scalar_bspline`` 对一个标量场分量执行三维 B-spline gather。
   它不重新计算权重，只使用已经给定的 ``ix,iy,iz`` 和 ``wx,wy,wz`` 做三重求和。

   完整 gather 推导见
   :doc:`sub_C02_gather_3Dxyz_bspline <sub_C02_gather_3Dxyz_bspline>`。

   .. rubric:: 接口

   .. code-block:: fortran

      value = fun_C02_gather_scalar_bspline(order,ng,il,iu,field, &
          ix,iy,iz,wx,wy,wz)

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 12 30 45

      * - 参数
        - 方向
        - shape / 范围
        - 含义
      * - ``order``
        - ``in``
        - ``integer scalar``
        - B-spline 阶数。
      * - ``ng``
        - ``in``
        - ``integer scalar``
        - 场数组声明中使用的 guard-cell 宽度。
      * - ``il,iu``
        - ``in``
        - ``integer(1:3)``
        - 场数组的 cell-centered 指标范围。
      * - ``field``
        - ``in``
        - ``real 3D array``
        - 要 gather 的标量场分量。
      * - ``ix,iy,iz``
        - ``in``
        - ``integer(0:order)``
        - 三个方向的模板指标。
      * - ``wx,wy,wz``
        - ``in``
        - ``real(0:order)``
        - 三个方向的一维权重。
      * - return value
        - ``out``
        - ``real scalar``
        - 粒子位置处的标量场值。

   .. rubric:: 实现说明

   该函数计算

   .. math::

      F_p=\sum_{c=0}^{order}\sum_{b=0}^{order}\sum_{a=0}^{order}
      F_{ix(a),iy(b),iz(c)}w_x(a)w_y(b)w_z(c).

   源码按 ``c,b,a`` 三层循环访问 ``field(ii,jj,kk)``，并把
   ``wx(a)*wy(b)*wz(c)`` 作为该网格点的张量积权重。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``fun_C02_gather_scalar_bspline`` performs a 3D B-spline gather for one
   scalar field component. It does not recompute weights; it uses the supplied
   ``ix,iy,iz`` and ``wx,wy,wz`` arrays in a triple sum.

   See :doc:`sub_C02_gather_3Dxyz_bspline <sub_C02_gather_3Dxyz_bspline>` for
   the full gather derivation.

   .. rubric:: Interface

   .. code-block:: fortran

      value = fun_C02_gather_scalar_bspline(order,ng,il,iu,field, &
          ix,iy,iz,wx,wy,wz)

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 12 30 45

      * - Parameter
        - Direction
        - Shape / Range
        - Meaning
      * - ``order``
        - ``in``
        - ``integer scalar``
        - B-spline degree.
      * - ``ng``
        - ``in``
        - ``integer scalar``
        - Guard-cell width used in the field-array declaration.
      * - ``il,iu``
        - ``in``
        - ``integer(1:3)``
        - Cell-centered index range of the field array.
      * - ``field``
        - ``in``
        - ``real 3D array``
        - Scalar field component to gather.
      * - ``ix,iy,iz``
        - ``in``
        - ``integer(0:order)``
        - Stencil indices in the three directions.
      * - ``wx,wy,wz``
        - ``in``
        - ``real(0:order)``
        - 1D weights in the three directions.
      * - return value
        - ``out``
        - ``real scalar``
        - Scalar field value at the particle position.

   .. rubric:: Implementation Notes

   The function computes

   .. math::

      F_p=\sum_{c=0}^{order}\sum_{b=0}^{order}\sum_{a=0}^{order}
      F_{ix(a),iy(b),iz(c)}w_x(a)w_y(b)w_z(c).

   The source loops over ``c,b,a``, reads ``field(ii,jj,kk)``, and uses
   ``wx(a)*wy(b)*wz(c)`` as the tensor-product weight for that grid point.

   .. rubric:: Generated API

   .. doxygenfile:: fun_C02_gather_scalar_bspline.f90
