------------------------------------
sub_B03_scatter_3Dxyz_bspline_v.f90
------------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_B03_scatter_3Dxyz_bspline_v`` 把粒子数组的一个分量 ``par(d,p)``
   按任意阶 B-spline 权重沉积到三维 Cartesian 网格。它和
   :doc:`sub_B03_scatter_3Dxyz_bspline <sub_B03_scatter_3Dxyz_bspline>`
   使用同样的 stencil 和权重，只是每个粒子的源项从 ``w`` 变为
   ``w*par(d,p)``。

   .. rubric:: 接口

   .. code-block:: fortran

      call sub_B03_scatter_3Dxyz_bspline_v(il,iu,den,np,par,d,w,order)

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 15 10 31 44

      * - 参数
        - 方向
        - shape / 范围
        - 含义
      * - ``il,iu``
        - ``in``
        - ``integer(1:3)``
        - 有效网格指标范围。
      * - ``den``
        - ``in/out``
        - ``real 3D array``
        - 接收分量沉积贡献的网格数组；调用前通常应由调用层清零。
      * - ``np``
        - ``in``
        - ``integer scalar``
        - 粒子数，也是 ``par`` 的第二维。
      * - ``par``
        - ``in``
        - ``real(1:6,1:np)``
        - 粒子相空间数组；``par(1:3,p)`` 是位置，``par(d,p)`` 是被沉积分量。
      * - ``d``
        - ``in``
        - ``integer scalar, 1:6``
        - 选择沉积 ``par`` 的第几个分量。
      * - ``w``
        - ``in``
        - ``real scalar``
        - 每个粒子的全局权重因子。
      * - ``order``
        - ``in``
        - ``integer scalar``
        - B-spline 阶数；``order=1`` 对应 B01 ``_v`` 的 CIC/三线性沉积。

   .. rubric:: 沉积公式

   设

   .. math::

      q_p=w\,par(d,p).

   与粒子数沉积相同，三维权重为

   .. math::

      W_{abc}=w_a^xw_b^yw_c^z.

   本例程执行

   .. math::

      den_{i_0+a,j_0+b,k_0+c}
      \leftarrow
      den_{i_0+a,j_0+b,k_0+c}
      +q_p W_{abc},
      \qquad a,b,c=0,\ldots,order.

   源码中的 ``source`` 对应 :math:`q_p`，``wt`` 对应 :math:`W_{abc}`。

   .. rubric:: 守恒关系

   因为张量积权重归一化，本例程应满足

   .. math::

      \sum_{i,j,k} den_{i,j,k}
      =
      w\sum_p par(d,p).

   当 ``order>=1`` 时，一阶矩应满足

   .. math::

      \sum_{i,j,k} i\,den_{i,j,k}
      =
      w\sum_p par(d,p)x_p,

   ``y`` 和 ``z`` 方向同理。测试中的 ``component_conservation`` 和
   ``component_first_moment`` 就是检查这些关系。

   .. rubric:: 参数顺序

   ``d`` 放在 ``w`` 和 ``order`` 之前，接口为 ``(...,par,d,w,order)``。
   这样调用时先读到粒子数组和选中的分量，再读到权重和阶数。

   .. rubric:: 调用注意

   - ``d`` 必须位于 ``1:6``，源码会检查非法分量。
   - ``den`` 是累加目标，本例程不会在内部清零。
   - ``den`` 必须包含 ``ng=(order+2)/2`` 宽度的可访问 guard/halo。
   - 本例程不处理越界检查、周期折叠或 MPI guard-cell 累加。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_B03_scatter_3Dxyz_bspline_v`` deposits one particle-array component
   ``par(d,p)`` to a 3D Cartesian grid with arbitrary-order B-spline weights.
   It uses the same stencil and weights as
   :doc:`sub_B03_scatter_3Dxyz_bspline <sub_B03_scatter_3Dxyz_bspline>`, but
   changes the particle source from ``w`` to ``w*par(d,p)``.

   .. rubric:: Interface

   .. code-block:: fortran

      call sub_B03_scatter_3Dxyz_bspline_v(il,iu,den,np,par,d,w,order)

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 15 10 31 44

      * - Parameter
        - Direction
        - Shape / Range
        - Meaning
      * - ``il,iu``
        - ``in``
        - ``integer(1:3)``
        - Active grid-index range.
      * - ``den``
        - ``in/out``
        - ``real 3D array``
        - Grid array receiving component-deposition contributions; normally zeroed by the caller before the call.
      * - ``np``
        - ``in``
        - ``integer scalar``
        - Particle count and the second dimension of ``par``.
      * - ``par``
        - ``in``
        - ``real(1:6,1:np)``
        - Particle phase-space array; ``par(1:3,p)`` are positions and ``par(d,p)`` is the deposited component.
      * - ``d``
        - ``in``
        - ``integer scalar, 1:6``
        - Selected component of ``par`` to deposit.
      * - ``w``
        - ``in``
        - ``real scalar``
        - Global particle weight factor.
      * - ``order``
        - ``in``
        - ``integer scalar``
        - B-spline degree; ``order=1`` corresponds to B01 ``_v`` CIC/trilinear deposition.

   .. rubric:: Deposition Formula

   Let

   .. math::

      q_p=w\,par(d,p).

   As in particle-number deposition, the 3D weight is

   .. math::

      W_{abc}=w_a^xw_b^yw_c^z.

   This routine performs

   .. math::

      den_{i_0+a,j_0+b,k_0+c}
      \leftarrow
      den_{i_0+a,j_0+b,k_0+c}
      +q_p W_{abc},
      \qquad a,b,c=0,\ldots,order.

   In the source, ``source`` corresponds to :math:`q_p`, and ``wt``
   corresponds to :math:`W_{abc}`.

   .. rubric:: Conservation Relations

   Since the tensor-product weights are normalized, this routine should
   satisfy

   .. math::

      \sum_{i,j,k} den_{i,j,k}
      =
      w\sum_p par(d,p).

   For ``order>=1``, the first moment should satisfy

   .. math::

      \sum_{i,j,k} i\,den_{i,j,k}
      =
      w\sum_p par(d,p)x_p,

   with analogous relations in ``y`` and ``z``. The
   ``component_conservation`` and ``component_first_moment`` tests check these
   relations.

   .. rubric:: Parameter Order

   ``d`` appears before ``w`` and ``order``, so the interface is
   ``(...,par,d,w,order)``. This makes the call read as particle array,
   selected component, weight, then B-spline degree.

   .. rubric:: Calling Notes

   - ``d`` must lie in ``1:6``; the source checks invalid component indices.
   - ``den`` is an accumulation target; this routine does not zero it internally.
   - ``den`` must include an accessible guard/halo width ``ng=(order+2)/2``.
   - This routine does not perform bounds checks, periodic folding, or MPI guard-cell accumulation.

   .. rubric:: Generated API

   .. doxygenfile:: sub_B03_scatter_3Dxyz_bspline_v.f90
