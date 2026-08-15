--------------------------
fun_B03_bspline_shape.f90
--------------------------


.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``fun_B03_bspline_shape`` 计算中心化 B-spline 形函数
   ``S_order(r)``。它只负责一个距离 ``r`` 上的权重值，完整 scatter 推导见
   :doc:`sub_B03_scatter_3Dxyz_bspline <sub_B03_scatter_3Dxyz_bspline>`。

   .. rubric:: 接口

   .. code-block:: fortran

      value = fun_B03_bspline_shape(order,r)

   .. rubric:: 参数与返回值

   .. list-table::
      :header-rows: 1
      :widths: 18 14 30 46

      * - 名称
        - 方向
        - shape / 范围
        - 含义
      * - ``order``
        - ``in``
        - ``integer scalar``
        - B-spline 阶数。
      * - ``r``
        - ``in``
        - ``real scalar``
        - 粒子坐标到网格指标的距离。
      * - return value
        - ``out``
        - ``real scalar``
        - ``S_order(r)``。

   .. rubric:: 实现说明

   ``order=0`` 时，函数返回 top-hat 形函数：

   .. math::

      S_0(r)=
      \begin{cases}
      1, & -\frac{1}{2}\le r < \frac{1}{2},\\
      0, & \mathrm{otherwise}.
      \end{cases}

   ``order>0`` 时，函数按中心化递推计算：

   .. math::

      S_p(r)=
      \frac{r+\frac{p+1}{2}}{p}
      S_{p-1}\left(r+\frac{1}{2}\right)
      +\frac{\frac{p+1}{2}-r}{p}
      S_{p-1}\left(r-\frac{1}{2}\right).

   如果 ``r`` 已经位于支撑区间外，源码直接返回 0。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``fun_B03_bspline_shape`` evaluates the centered B-spline shape function
   ``S_order(r)``. It only computes the weight value at one distance ``r``;
   see :doc:`sub_B03_scatter_3Dxyz_bspline <sub_B03_scatter_3Dxyz_bspline>` for
   the full scatter derivation.

   .. rubric:: Interface

   .. code-block:: fortran

      value = fun_B03_bspline_shape(order,r)

   .. rubric:: Arguments And Return Value

   .. list-table::
      :header-rows: 1
      :widths: 18 14 30 46

      * - Name
        - Direction
        - Shape / Range
        - Meaning
      * - ``order``
        - ``in``
        - ``integer scalar``
        - B-spline degree.
      * - ``r``
        - ``in``
        - ``real scalar``
        - Distance from the particle coordinate to the grid index.
      * - return value
        - ``out``
        - ``real scalar``
        - ``S_order(r)``.

   .. rubric:: Implementation Notes

   For ``order=0``, the function returns the top-hat shape:

   .. math::

      S_0(r)=
      \begin{cases}
      1, & -\frac{1}{2}\le r < \frac{1}{2},\\
      0, & \mathrm{otherwise}.
      \end{cases}

   For ``order>0``, the function uses the centered recurrence:

   .. math::

      S_p(r)=
      \frac{r+\frac{p+1}{2}}{p}
      S_{p-1}\left(r+\frac{1}{2}\right)
      +\frac{\frac{p+1}{2}-r}{p}
      S_{p-1}\left(r-\frac{1}{2}\right).

   If ``r`` lies outside the support interval, the source returns 0 directly.

   .. rubric:: Generated API

   .. doxygenfile:: fun_B03_bspline_shape.f90


