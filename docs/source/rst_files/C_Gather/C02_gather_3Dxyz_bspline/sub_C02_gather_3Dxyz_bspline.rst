----------------------------------
sub_C02_gather_3Dxyz_bspline.f90
----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_C02_gather_3Dxyz_bspline`` 对一个粒子执行 B-spline 场 gather。
   它先根据粒子位置生成 x、y、z 三个方向的一维 B-spline 模板，再用三维张量积权重
   把 ``Ex,Ey,Ez,Bx,By,Bz`` 插值到粒子位置。

   .. rubric:: 接口

   .. code-block:: fortran

      call sub_C02_gather_3Dxyz_bspline(p,np,par,il,iu,Ex,Ey,Ez, &
          Bx,By,Bz,E,B,order)

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 15 10 31 44

      * - 参数
        - 方向
        - shape / 范围
        - 含义
      * - ``p``
        - ``in``
        - ``integer scalar``
        - 当前粒子编号。
      * - ``np``
        - ``in``
        - ``integer scalar``
        - 粒子总数，也是 ``par`` 的第二维。
      * - ``par``
        - ``in``
        - ``real(1:6,1:np)``
        - 粒子相空间数组；使用 ``par(1:3,p)`` 作为网格指标单位的位置。
      * - ``il,iu``
        - ``in``
        - ``integer(1:3)``
        - cell-centered 场数组的本地指标范围。
      * - ``Ex,Ey,Ez``
        - ``in``
        - ``real 3D arrays``
        - 电场三个分量。
      * - ``Bx,By,Bz``
        - ``in``
        - ``real 3D arrays``
        - 磁场三个分量。
      * - ``E,B``
        - ``out``
        - ``real(1:3)``
        - 粒子位置处 gather 得到的电场和磁场。
      * - ``order``
        - ``in``
        - ``integer scalar``
        - B-spline 阶数；``order=1`` 对应三线性插值。

   .. rubric:: 坐标约定

   粒子位置 ``par(1:3,p)`` 使用网格指标单位。本例程面向 cell-centered 场数组，
   因此源码先做

   .. code-block:: fortran

      x = par(1,p) + 0.5
      y = par(2,p) + 0.5
      z = par(3,p) + 0.5

   后文把这三个 gather 坐标记为
   :math:`\xi_x,\xi_y,\xi_z`。

   .. rubric:: B-spline 原始递推

   给定 knot 序列 :math:`u_i`，零阶 B-spline 为

   .. math::

      N_{i,0}(u)=
      \begin{cases}
      1, & u_i \le u < u_{i+1},\\
      0, & \mathrm{otherwise}.
      \end{cases}

   高阶 B-spline 由 Cox-de Boor 递推给出：

   .. math::

      N_{i,p}(u)=
      \frac{u-u_i}{u_{i+p}-u_i}N_{i,p-1}(u)
      +\frac{u_{i+p+1}-u}{u_{i+p+1}-u_{i+1}}N_{i+1,p-1}(u).

   在均匀 PIC 网格上取 :math:`u_i=i`，于是

   .. math::

      N_{i,p}(u)=
      \frac{u-i}{p}N_{i,p-1}(u)
      +\frac{i+p+1-u}{p}N_{i+1,p-1}(u).

   .. rubric:: 中心化 PIC 形函数

   PIC gather 更方便使用粒子到网格点的距离

   .. math::

      r=\xi-i.

   将 :math:`N_{0,p}` 平移到以 :math:`r=0` 为中心，定义

   .. math::

      S_p(r)=N_{0,p}\left(r+\frac{p+1}{2}\right).

   因此零阶形函数为

   .. math::

      S_0(r)=
      \begin{cases}
      1, & -\frac{1}{2}\le r < \frac{1}{2},\\
      0, & \mathrm{otherwise}.
      \end{cases}

   对 :math:`p>0`，把 :math:`u=r+(p+1)/2` 代入均匀网格递推，可得

   .. math::

      S_p(r)=
      \frac{r+\frac{p+1}{2}}{p}
      S_{p-1}\left(r+\frac{1}{2}\right)
      +\frac{\frac{p+1}{2}-r}{p}
      S_{p-1}\left(r-\frac{1}{2}\right).

   ``fun_C02_bspline_shape(order,r)`` 实现的就是这个递推，其中
   ``order`` 对应 :math:`p`。

   .. rubric:: 一维 gather

   对一维标量场 :math:`F_i`，粒子位置 :math:`\xi` 处的值为

   .. math::

      F_p=\sum_i F_i S_p(\xi-i).

   因为 :math:`S_p` 是紧支撑函数，实际只取 :math:`p+1` 个网格点。源码选择

   .. math::

      i_0=\left\lfloor \xi-\frac{p-1}{2}\right\rfloor,
      \qquad i=i_0,i_0+1,\ldots,i_0+p.

   对应权重为

   .. math::

      w_a=S_p\left(\xi-(i_0+a)\right),
      \qquad a=0,1,\ldots,p.

   所以一维 gather 变为

   .. math::

      F_p=\sum_{a=0}^{p}F_{i_0+a}w_a.

   ``sub_C02_bspline_stencil_1d`` 负责计算 ``idx(a)=i0+a`` 和 ``w(a)``。

   .. rubric:: 三维 gather

   三维形函数使用一维形函数的张量积。令三个方向的模板起点为
   :math:`i_0,j_0,k_0`，权重为

   .. math::

      w_a^x=S_p(\xi_x-i_0-a),\qquad
      w_b^y=S_p(\xi_y-j_0-b),\qquad
      w_c^z=S_p(\xi_z-k_0-c).

   对任意场分量 :math:`F`，gather 公式为

   .. math::

      F_p=\sum_{c=0}^{p}\sum_{b=0}^{p}\sum_{a=0}^{p}
      F_{i_0+a,j_0+b,k_0+c}w_a^xw_b^yw_c^z.

   ``fun_C02_gather_scalar_bspline`` 实现这个三重求和。顶层例程把它分别用于
   ``Ex,Ey,Ez,Bx,By,Bz``：

   .. math::

      E=(G(Ex),G(Ey),G(Ez)),\qquad
      B=(G(Bx),G(By),G(Bz)).

   这里 :math:`G(\cdot)` 表示上面的三维 B-spline gather。

   .. rubric:: 源码变量对应

   .. list-table::
      :header-rows: 1
      :widths: 25 43

      * - 数学符号
        - 源码变量
      * - :math:`p`
        - ``order``
      * - :math:`\xi_x,\xi_y,\xi_z`
        - ``x,y,z = par(1:3,p)+0.5``
      * - :math:`i_0+a,j_0+b,k_0+c`
        - ``ix(a),iy(b),iz(c)``
      * - :math:`w_a^x,w_b^y,w_c^z`
        - ``wx(a),wy(b),wz(c)``
      * - :math:`F_{i,j,k}`
        - ``field(ii,jj,kk)``

   .. rubric:: order=1 的退化

   ``order=1`` 时，

   .. math::

      S_1(r)=
      \begin{cases}
      1-|r|, & |r|<1,\\
      0, & \mathrm{otherwise}.
      \end{cases}

   每个方向只有两个权重，三维共有 :math:`2^3=8` 个点，公式正好退化为 C01
   的八点三线性插值。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_C02_gather_3Dxyz_bspline`` gathers fields for one particle with a
   B-spline shape function. It first builds 1D B-spline stencils in x, y, and
   z, then uses 3D tensor-product weights to interpolate
   ``Ex,Ey,Ez,Bx,By,Bz`` to the particle position.

   .. rubric:: Interface

   .. code-block:: fortran

      call sub_C02_gather_3Dxyz_bspline(p,np,par,il,iu,Ex,Ey,Ez, &
          Bx,By,Bz,E,B,order)

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 15 10 31 44

      * - Parameter
        - Direction
        - Shape / Range
        - Meaning
      * - ``p``
        - ``in``
        - ``integer scalar``
        - Current particle index.
      * - ``np``
        - ``in``
        - ``integer scalar``
        - Number of particles and second dimension of ``par``.
      * - ``par``
        - ``in``
        - ``real(1:6,1:np)``
        - Particle phase-space array; ``par(1:3,p)`` is the position in grid-index units.
      * - ``il,iu``
        - ``in``
        - ``integer(1:3)``
        - Local index range of the cell-centered field arrays.
      * - ``Ex,Ey,Ez``
        - ``in``
        - ``real 3D arrays``
        - Electric-field components.
      * - ``Bx,By,Bz``
        - ``in``
        - ``real 3D arrays``
        - Magnetic-field components.
      * - ``E,B``
        - ``out``
        - ``real(1:3)``
        - Electric and magnetic fields gathered at the particle position.
      * - ``order``
        - ``in``
        - ``integer scalar``
        - B-spline degree; ``order=1`` corresponds to trilinear interpolation.

   .. rubric:: Coordinate Convention

   Particle positions ``par(1:3,p)`` are in grid-index units. This routine
   targets cell-centered field arrays, so the source first computes

   .. code-block:: fortran

      x = par(1,p) + 0.5
      y = par(2,p) + 0.5
      z = par(3,p) + 0.5

   These gather coordinates are denoted by
   :math:`\xi_x,\xi_y,\xi_z` below.

   .. rubric:: Original B-spline Recurrence

   Given a knot sequence :math:`u_i`, the zero-degree B-spline is

   .. math::

      N_{i,0}(u)=
      \begin{cases}
      1, & u_i \le u < u_{i+1},\\
      0, & \mathrm{otherwise}.
      \end{cases}

   Higher-degree B-splines follow the Cox-de Boor recurrence:

   .. math::

      N_{i,p}(u)=
      \frac{u-u_i}{u_{i+p}-u_i}N_{i,p-1}(u)
      +\frac{u_{i+p+1}-u}{u_{i+p+1}-u_{i+1}}N_{i+1,p-1}(u).

   On a uniform PIC grid, take :math:`u_i=i`. Then

   .. math::

      N_{i,p}(u)=
      \frac{u-i}{p}N_{i,p-1}(u)
      +\frac{i+p+1-u}{p}N_{i+1,p-1}(u).

   .. rubric:: Centered PIC Shape Function

   PIC gather uses the distance from the particle to a grid index,

   .. math::

      r=\xi-i.

   Shift :math:`N_{0,p}` so that the shape is centered at :math:`r=0`:

   .. math::

      S_p(r)=N_{0,p}\left(r+\frac{p+1}{2}\right).

   The zero-degree shape is

   .. math::

      S_0(r)=
      \begin{cases}
      1, & -\frac{1}{2}\le r < \frac{1}{2},\\
      0, & \mathrm{otherwise}.
      \end{cases}

   For :math:`p>0`, substituting :math:`u=r+(p+1)/2` into the uniform-grid
   recurrence gives

   .. math::

      S_p(r)=
      \frac{r+\frac{p+1}{2}}{p}
      S_{p-1}\left(r+\frac{1}{2}\right)
      +\frac{\frac{p+1}{2}-r}{p}
      S_{p-1}\left(r-\frac{1}{2}\right).

   ``fun_C02_bspline_shape(order,r)`` implements this recurrence, with
   ``order`` corresponding to :math:`p`.

   .. rubric:: 1D Gather

   For a 1D scalar field :math:`F_i`, the gathered value at particle coordinate
   :math:`\xi` is

   .. math::

      F_p=\sum_i F_i S_p(\xi-i).

   Since :math:`S_p` has compact support, only :math:`p+1` grid points are
   used. The source chooses

   .. math::

      i_0=\left\lfloor \xi-\frac{p-1}{2}\right\rfloor,
      \qquad i=i_0,i_0+1,\ldots,i_0+p.

   The weights are

   .. math::

      w_a=S_p\left(\xi-(i_0+a)\right),
      \qquad a=0,1,\ldots,p.

   Thus the 1D gather becomes

   .. math::

      F_p=\sum_{a=0}^{p}F_{i_0+a}w_a.

   ``sub_C02_bspline_stencil_1d`` computes ``idx(a)=i0+a`` and ``w(a)``.

   .. rubric:: 3D Gather

   The 3D shape is the tensor product of the 1D shapes. Let the first stencil
   indices be :math:`i_0,j_0,k_0`, with weights

   .. math::

      w_a^x=S_p(\xi_x-i_0-a),\qquad
      w_b^y=S_p(\xi_y-j_0-b),\qquad
      w_c^z=S_p(\xi_z-k_0-c).

   For any field component :math:`F`, the gathered value is

   .. math::

      F_p=\sum_{c=0}^{p}\sum_{b=0}^{p}\sum_{a=0}^{p}
      F_{i_0+a,j_0+b,k_0+c}w_a^xw_b^yw_c^z.

   ``fun_C02_gather_scalar_bspline`` implements this triple sum. The top-level
   routine applies it to ``Ex,Ey,Ez,Bx,By,Bz``:

   .. math::

      E=(G(Ex),G(Ey),G(Ez)),\qquad
      B=(G(Bx),G(By),G(Bz)).

   Here :math:`G(\cdot)` denotes the 3D B-spline gather above.

   .. rubric:: Source Variable Mapping

   .. list-table::
      :header-rows: 1
      :widths: 25 43

      * - Mathematical symbol
        - Source variable
      * - :math:`p`
        - ``order``
      * - :math:`\xi_x,\xi_y,\xi_z`
        - ``x,y,z = par(1:3,p)+0.5``
      * - :math:`i_0+a,j_0+b,k_0+c`
        - ``ix(a),iy(b),iz(c)``
      * - :math:`w_a^x,w_b^y,w_c^z`
        - ``wx(a),wy(b),wz(c)``
      * - :math:`F_{i,j,k}`
        - ``field(ii,jj,kk)``

   .. rubric:: Order-1 Limit

   For ``order=1``,

   .. math::

      S_1(r)=
      \begin{cases}
      1-|r|, & |r|<1,\\
      0, & \mathrm{otherwise}.
      \end{cases}

   Each direction has two weights, so the 3D stencil has :math:`2^3=8` points.
   The formula therefore reduces exactly to the C01 eight-point trilinear
   interpolation.

   .. rubric:: Generated API

   .. doxygenfile:: sub_C02_gather_3Dxyz_bspline.f90
