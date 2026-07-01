--------------------------------
sub_B03_bspline_stencil_1d.f90
--------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_B03_bspline_stencil_1d`` 为一个方向构造 B-spline scatter 模板。
   输入粒子坐标 ``xp`` 和阶数 ``order`` 后，它返回 ``order+1`` 个网格指标
   ``idx`` 以及对应权重 ``weight``。

   完整 scatter 推导见
   :doc:`sub_B03_scatter_3Dxyz_bspline <sub_B03_scatter_3Dxyz_bspline>`。

   .. rubric:: 接口

   .. code-block:: fortran

      call sub_B03_bspline_stencil_1d(order,xp,idx,weight)

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
        - B-spline 阶数，必须非负。
      * - ``xp``
        - ``in``
        - ``real scalar``
        - 该方向上的粒子坐标，单位为网格指标。
      * - ``idx``
        - ``out``
        - ``integer(0:order)``
        - 模板网格指标。
      * - ``weight``
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
      weight(a)=S_{order}(xp-idx(a)).

   其中 ``S_order`` 由
   :doc:`fun_B03_bspline_shape <fun_B03_bspline_shape>` 计算。

   最后源码计算

   .. math::

      sw=\sum_{a=0}^{order}weight(a),

   并在 ``sw>0`` 时令 ``weight=weight/sw``。这一步让一维权重和严格接近 1，
   减小递归求值和半开区间边界带来的舍入影响。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_B03_bspline_stencil_1d`` builds a B-spline scatter stencil in one
   direction. Given particle coordinate ``xp`` and degree ``order``, it returns
   ``order+1`` grid indices ``idx`` and their weights ``weight``.

   See :doc:`sub_B03_scatter_3Dxyz_bspline <sub_B03_scatter_3Dxyz_bspline>` for
   the full scatter derivation.

   .. rubric:: Interface

   .. code-block:: fortran

      call sub_B03_bspline_stencil_1d(order,xp,idx,weight)

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
        - B-spline degree, which must be non-negative.
      * - ``xp``
        - ``in``
        - ``real scalar``
        - Particle coordinate in this direction, in grid-index units.
      * - ``idx``
        - ``out``
        - ``integer(0:order)``
        - Stencil grid indices.
      * - ``weight``
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
      weight(a)=S_{order}(xp-idx(a)).

   Here ``S_order`` is evaluated by
   :doc:`fun_B03_bspline_shape <fun_B03_bspline_shape>`.

   The source then computes

   .. math::

      sw=\sum_{a=0}^{order}weight(a),

   and, when ``sw>0``, replaces ``weight`` by ``weight/sw``. This keeps the 1D
   weight sum close to 1 and reduces round-off effects from recursive
   evaluation and half-open boundary conventions.

   .. rubric:: Generated API

   .. doxygenfile:: sub_B03_bspline_stencil_1d.f90
