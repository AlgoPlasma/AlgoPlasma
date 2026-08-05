--------------------------------
sub_C02_bspline_stencil_1d.f90
--------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_C02_bspline_stencil_1d`` 为一个方向构造 B-spline gather 模板。
   输入粒子坐标 ``xp`` 和阶数 ``order`` 后，它返回 ``order+1`` 个网格指标
   ``idx`` 以及对应权重 ``w``。

   完整 gather 推导见
   :doc:`sub_C02_gather_3Dxyz_bspline <sub_C02_gather_3Dxyz_bspline>`。

   .. rubric:: 接口

   .. code-block:: fortran

      call sub_C02_bspline_stencil_1d(order,xp,idx,w)

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
      * - ``xp``
        - ``in``
        - ``real scalar``
        - 该方向上的粒子坐标，单位为网格指标。
      * - ``idx``
        - ``out``
        - ``integer(0:order)``
        - 模板网格指标。
      * - ``w``
        - ``out``
        - ``real(0:order)``
        - 与 ``idx`` 对应的一维权重。

   .. rubric:: 实现说明

   模板起点为

   .. math::

      i_0=\left\lfloor xp-\frac{order-1}{2}\right\rfloor.

   对 ``a=0..order``，源码设置

   .. math::

      idx(a)=i_0+a,\qquad
      w(a)=S_{order}(xp-idx(a)).

   最后对 ``w`` 做归一化，使权重和为 1。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_C02_bspline_stencil_1d`` builds a B-spline gather stencil in one
   direction. Given particle coordinate ``xp`` and degree ``order``, it returns
   ``order+1`` grid indices ``idx`` and their weights ``w``.

   See :doc:`sub_C02_gather_3Dxyz_bspline <sub_C02_gather_3Dxyz_bspline>` for
   the full gather derivation.

   .. rubric:: Interface

   .. code-block:: fortran

      call sub_C02_bspline_stencil_1d(order,xp,idx,w)

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
      * - ``xp``
        - ``in``
        - ``real scalar``
        - Particle coordinate in this direction, in grid-index units.
      * - ``idx``
        - ``out``
        - ``integer(0:order)``
        - Stencil grid indices.
      * - ``w``
        - ``out``
        - ``real(0:order)``
        - 1D weights associated with ``idx``.

   .. rubric:: Implementation Notes

   The first stencil index is

   .. math::

      i_0=\left\lfloor xp-\frac{order-1}{2}\right\rfloor.

   For ``a=0..order``, the source sets

   .. math::

      idx(a)=i_0+a,\qquad
      w(a)=S_{order}(xp-idx(a)).

   The routine then normalizes ``w`` so that the weights sum to 1.

   .. rubric:: Generated API

   .. doxygenfile:: sub_C02_bspline_stencil_1d.f90
