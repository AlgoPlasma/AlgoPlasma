----------------------------------
sub_B03_scatter_3Dxyz_bspline.f90
----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_B03_scatter_3Dxyz_bspline`` 把粒子数或统一权重源项沉积到三维
   Cartesian 网格。对每个粒子，源码根据 ``par(1:3,p)`` 分别生成 x、y、z
   三个方向的一维 B-spline stencil，然后把三维张量积权重累加到 ``den``。
   每个粒子的总沉积量为 ``w``。

   .. rubric:: 接口

   .. code-block:: fortran

      call sub_B03_scatter_3Dxyz_bspline(il,iu,den,np,par,w,order)

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
        - 接收沉积贡献的网格数组；调用前通常应由调用层清零。
      * - ``np``
        - ``in``
        - ``integer scalar``
        - 粒子数，也是 ``par`` 的第二维。
      * - ``par``
        - ``in``
        - ``real(1:6,1:np)``
        - 粒子相空间数组；使用 ``par(1:3,p)`` 作为网格指标单位的位置。
      * - ``w``
        - ``in``
        - ``real scalar``
        - 每个粒子的总沉积权重。
      * - ``order``
        - ``in``
        - ``integer scalar``
        - B-spline 阶数；``order=1`` 对应 B01 CIC/三线性沉积。

   .. rubric:: 数学公式

   粒子位置记为

   .. math::

      (x_p,y_p,z_p)=(par(1,p),par(2,p),par(3,p)).

   对阶数 :math:`m=order`，每个方向的 stencil 起点为

   .. math::

      i_0=\left\lfloor x_p-\frac{m-1}{2}\right\rfloor,\quad
      j_0=\left\lfloor y_p-\frac{m-1}{2}\right\rfloor,\quad
      k_0=\left\lfloor z_p-\frac{m-1}{2}\right\rfloor.

   权重为

   .. math::

      w_a^x=S_m(x_p-i_0-a),\quad
      w_b^y=S_m(y_p-j_0-b),\quad
      w_c^z=S_m(z_p-k_0-c).

   三维沉积公式是

   .. math::

      den_{i_0+a,j_0+b,k_0+c}
      \leftarrow
      den_{i_0+a,j_0+b,k_0+c}
      +w\,w_a^xw_b^yw_c^z,
      \qquad a,b,c=0,\ldots,m.

   这里的 :math:`S_m` 是中心化 B-spline 形函数，定义和递推见
   :doc:`fun_B03_bspline_shape <fun_B03_bspline_shape>`。

   .. rubric:: 源码实现步骤

   1. 检查 ``order`` 是否非负。
   2. 对每个粒子 ``p``，调用
      :doc:`sub_B03_bspline_stencil_1d <sub_B03_bspline_stencil_1d>` 三次，
      得到 ``ix,iy,iz`` 和 ``wx,wy,wz``。
   3. 按 ``c,b,a`` 三层循环访问三维 stencil。
   4. 对每个 stencil 点计算 ``wt=wx(a)*wy(b)*wz(c)``。
   5. 累加 ``den(ix(a),iy(b),iz(c)) += w*wt``。

   .. rubric:: 源码变量对应

   .. list-table::
      :header-rows: 1
      :widths: 28 44

      * - 数学符号
        - 源码变量
      * - :math:`m`
        - ``order``
      * - :math:`x_p,y_p,z_p`
        - ``par(1,p),par(2,p),par(3,p)``
      * - :math:`i_0+a,j_0+b,k_0+c`
        - ``ix(a),iy(b),iz(c)``
      * - :math:`w_a^x,w_b^y,w_c^z`
        - ``wx(a),wy(b),wz(c)``
      * - :math:`w_a^xw_b^yw_c^z`
        - ``wt``
      * - :math:`den_{i,j,k}`
        - ``den(ix(a),iy(b),iz(c))``

   .. rubric:: 守恒性质

   ``sub_B03_bspline_stencil_1d`` 会归一化一维权重，因此

   .. math::

      \sum_a w_a^x=\sum_b w_b^y=\sum_c w_c^z=1.

   所以单个粒子的三维总沉积量为

   .. math::

      \sum_{a,b,c} w\,w_a^xw_b^yw_c^z=w.

   当 ``order>=1`` 时，中心化 B-spline 还满足一阶矩条件，因此沉积的一阶矩应保持粒子位置：

   .. math::

      \sum_i i\,S_m(x_p-i)=x_p.

   测试中的 ``number_conservation`` 和 ``number_first_moment`` 就是在检查这两个性质。

   .. rubric:: 与 B01 的关系

   ``order=1`` 时，``S_1(r)=1-|r|``，每个方向只有两个 stencil 点，
   三维共有 8 个点，公式退化为 B01 的 CIC/三线性沉积。因此本例程在
   ``order=1`` 时应与 ``sub_B01_scatter_3Dxyz`` 逐点一致。

   .. rubric:: 调用注意

   - ``den`` 是累加目标，本例程不会在内部清零。
   - ``den`` 必须包含 ``ng=(order+2)/2`` 宽度的可访问 guard/halo。
   - 本例程不处理越界检查、周期折叠或 MPI guard-cell 累加。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_B03_scatter_3Dxyz_bspline`` deposits particle number or a uniform
   source weight to a 3D Cartesian grid. For each particle, the source builds
   one 1D B-spline stencil in each of x, y, and z from ``par(1:3,p)``, then
   accumulates the 3D tensor-product weights into ``den``. Each particle
   deposits total amount ``w``.

   .. rubric:: Interface

   .. code-block:: fortran

      call sub_B03_scatter_3Dxyz_bspline(il,iu,den,np,par,w,order)

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
        - Grid array receiving deposition contributions; normally zeroed by the caller before the call.
      * - ``np``
        - ``in``
        - ``integer scalar``
        - Particle count and the second dimension of ``par``.
      * - ``par``
        - ``in``
        - ``real(1:6,1:np)``
        - Particle phase-space array; ``par(1:3,p)`` are positions in grid-index units.
      * - ``w``
        - ``in``
        - ``real scalar``
        - Total deposited weight per particle.
      * - ``order``
        - ``in``
        - ``integer scalar``
        - B-spline degree; ``order=1`` corresponds to B01 CIC/trilinear deposition.

   .. rubric:: Mathematical Formula

   Denote the particle position by

   .. math::

      (x_p,y_p,z_p)=(par(1,p),par(2,p),par(3,p)).

   For degree :math:`m=order`, the first stencil indices are

   .. math::

      i_0=\left\lfloor x_p-\frac{m-1}{2}\right\rfloor,\quad
      j_0=\left\lfloor y_p-\frac{m-1}{2}\right\rfloor,\quad
      k_0=\left\lfloor z_p-\frac{m-1}{2}\right\rfloor.

   The weights are

   .. math::

      w_a^x=S_m(x_p-i_0-a),\quad
      w_b^y=S_m(y_p-j_0-b),\quad
      w_c^z=S_m(z_p-k_0-c).

   The 3D deposition formula is

   .. math::

      den_{i_0+a,j_0+b,k_0+c}
      \leftarrow
      den_{i_0+a,j_0+b,k_0+c}
      +w\,w_a^xw_b^yw_c^z,
      \qquad a,b,c=0,\ldots,m.

   Here :math:`S_m` is the centered B-spline shape function defined in
   :doc:`fun_B03_bspline_shape <fun_B03_bspline_shape>`.

   .. rubric:: Source Implementation Steps

   1. Check that ``order`` is non-negative.
   2. For each particle ``p``, call
      :doc:`sub_B03_bspline_stencil_1d <sub_B03_bspline_stencil_1d>` three
      times to obtain ``ix,iy,iz`` and ``wx,wy,wz``.
   3. Visit the 3D stencil with ``c,b,a`` loops.
   4. Compute ``wt=wx(a)*wy(b)*wz(c)`` for each stencil point.
   5. Accumulate ``den(ix(a),iy(b),iz(c)) += w*wt``.

   .. rubric:: Source Variable Mapping

   .. list-table::
      :header-rows: 1
      :widths: 28 44

      * - Mathematical symbol
        - Source variable
      * - :math:`m`
        - ``order``
      * - :math:`x_p,y_p,z_p`
        - ``par(1,p),par(2,p),par(3,p)``
      * - :math:`i_0+a,j_0+b,k_0+c`
        - ``ix(a),iy(b),iz(c)``
      * - :math:`w_a^x,w_b^y,w_c^z`
        - ``wx(a),wy(b),wz(c)``
      * - :math:`w_a^xw_b^yw_c^z`
        - ``wt``
      * - :math:`den_{i,j,k}`
        - ``den(ix(a),iy(b),iz(c))``

   .. rubric:: Conservation Properties

   ``sub_B03_bspline_stencil_1d`` normalizes each 1D stencil, so

   .. math::

      \sum_a w_a^x=\sum_b w_b^y=\sum_c w_c^z=1.

   Therefore one particle deposits

   .. math::

      \sum_{a,b,c} w\,w_a^xw_b^yw_c^z=w.

   For ``order>=1``, the centered B-spline also satisfies the first moment, so
   the deposited first moment should preserve the particle position:

   .. math::

      \sum_i i\,S_m(x_p-i)=x_p.

   The ``number_conservation`` and ``number_first_moment`` test cases check
   these two properties.

   .. rubric:: Relation to B01

   For ``order=1``, ``S_1(r)=1-|r|``. Each direction has two stencil points,
   so the 3D stencil has eight points and the formula reduces to B01
   CIC/trilinear deposition. This routine should therefore match
   ``sub_B01_scatter_3Dxyz`` pointwise for ``order=1``.

   .. rubric:: Calling Notes

   - ``den`` is an accumulation target; this routine does not zero it internally.
   - ``den`` must include an accessible guard/halo width ``ng=(order+2)/2``.
   - This routine does not perform bounds checks, periodic folding, or MPI guard-cell accumulation.

   .. rubric:: Generated API

   .. doxygenfile:: sub_B03_scatter_3Dxyz_bspline.f90
