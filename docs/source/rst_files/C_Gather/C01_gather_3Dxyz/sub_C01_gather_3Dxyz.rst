------------------------
sub_C01_gather_3Dxyz.f90
------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   用三线性插值把 3D Cartesian 网格场 gather 到一个粒子位置。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 14 10 28 34 26 40

      * - 参数
        - 方向
        - shape / 范围
        - 含义
        - 单位 / 归一化
        - 索引 / ghost-cell 要求
      * - ``p``
        - ``in``
        - ``integer scalar``
        - 粒子编号
        - 整数下标或计数
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``np``
        - ``in``
        - ``integer scalar``
        - 粒子数或粒子数组第二维
        - 整数下标或计数
        - 无额外 ghost-cell 要求；按源码中的标量或数组范围使用。
      * - ``par``
        - ``in``
        - ``real(1:6,1:np)``
        - 粒子相空间数组
        - 位置为网格指标单位，速度/其他分量按调用者约定
        - 使用 ``par(1:3,p)`` 作为位置；调用者保证粒子位于本地或 guard 可覆盖范围。
      * - ``il``
        - ``in``
        - ``integer(1:3)``
        - 本地网格有效下界
        - 整数下标或计数
        - 决定可访问的本地模板范围，必须与实际数组分配一致。
      * - ``iu``
        - ``in``
        - ``integer(1:3)``
        - 本地网格有效上界
        - 整数下标或计数
        - 决定可访问的本地模板范围，必须与实际数组分配一致。
      * - ``Ex``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - x 向电场网格。
        - 调用者归一化下的场值。
        - 数组覆盖本地区间外一层；三线性插值会访问八个相邻节点。
      * - ``Ey``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - y 向电场网格。
        - 调用者归一化下的场值。
        - 数组覆盖本地区间外一层；三线性插值会访问八个相邻节点。
      * - ``Ez``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - z 向电场网格。
        - 调用者归一化下的场值。
        - 数组覆盖本地区间外一层；三线性插值会访问八个相邻节点。
      * - ``Bx``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - x 向磁场网格。
        - 调用者归一化下的场值。
        - 数组覆盖本地区间外一层；三线性插值会访问八个相邻节点。
      * - ``By``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - y 向磁场网格。
        - 调用者归一化下的场值。
        - 数组覆盖本地区间外一层；三线性插值会访问八个相邻节点。
      * - ``Bz``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - z 向磁场网格。
        - 调用者归一化下的场值。
        - 数组覆盖本地区间外一层；三线性插值会访问八个相邻节点。
      * - ``E``
        - ``in/out``
        - ``real(1:3)``
        - 粒子位置处的电场向量
        - 调用者归一化下的粒子/场单位
        - 单粒子向量，无 ghost cell；分量顺序由本页坐标系决定。
      * - ``B``
        - ``in/out``
        - ``real(1:3)``
        - 粒子位置处的磁场向量
        - 调用者归一化下的粒子/场单位
        - 单粒子向量，无 ghost cell；分量顺序由本页坐标系决定。

   .. rubric:: 局部假设 / 前置条件

   - 粒子位置使用网格指标单位；沉积/插值模板必须落在本地数组或 guard cell 覆盖范围内。
   - 本页只说明本 routine 的局部约定；不假设全局主程序的单位制、时间步或边界策略。

   .. rubric:: 实现逻辑

   - 将粒子位置整体加 ``0.5`` 映射到 cell-centered 指标空间。
   - 对六个场分量分别执行八点三线性插值。

   .. rubric:: 调用注意

   - 粒子靠近本地边界时，guard cell 必须已经有效。


   .. rubric:: 子程序说明

   ``sub_C01_gather_3Dxyz`` 将 cell-centered 的三维直角坐标电磁场插值到单个粒子位置。粒子坐标来自 ``par(1:3,p)``，例程内部先加 ``0.5`` 映射到 cell-centered 指标坐标，然后在包围粒子的八个网格点上做三线性加权。

   .. image:: ../../../images/C_Gather/C01_E_B_interpolation.png
      :alt: C01 field interpolation schematic
      :scale: 50
      :align: center

   .. rubric:: 接口

   .. code-block:: fortran

      call sub_C01_gather_3Dxyz(p, np, par, il, iu, Ex, Ey, Ez, &
                                Bx, By, Bz, E, B)

   .. list-table::
      :header-rows: 1
      :widths: 18 12 46

      * - 参数
        - 方向
        - 含义
      * - ``p``
        - in
        - 需要插值的粒子编号。
      * - ``np``
        - in
        - 粒子总数，用于定义 ``par`` 的第二维。
      * - ``par(1:6,1:np)``
        - in
        - 粒子相空间数组；本例程只使用 ``par(1:3,p)``。
      * - ``il(1:3)``, ``iu(1:3)``
        - in
        - 本地子域的下、上网格指标。
      * - ``Ex,Ey,Ez``
        - in
        - 电场三个分量，数组范围为 ``il-1:iu+1``。
      * - ``Bx,By,Bz``
        - in
        - 磁场三个分量，数组范围为 ``il-1:iu+1``。
      * - ``E(1:3)``, ``B(1:3)``
        - out
        - 粒子位置处插值得到的电场和磁场。

   .. rubric:: 三线性插值

   设

   .. math::

      x_g = x_p + 0.5,\qquad i=\lfloor x_g \rfloor,\qquad f_i=x_g-i,

   y、z 方向同理。任意场分量 :math:`F` 在粒子位置处的插值为

   .. math::

      F_p = \sum_{\alpha,\beta,\gamma\in\{0,1\}}
      F_{i+\alpha,j+\beta,k+\gamma}
      w_x(\alpha)w_y(\beta)w_z(\gamma),

   其中 :math:`w_x(0)=1-f_i`、:math:`w_x(1)=f_i`，其余方向类似。调用前应保证粒子及其八点插值模板位于本地数组与 guard cell 覆盖范围内。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Trilinearly gathers 3D Cartesian grid fields to one particle position.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 14 10 28 34 26 40

      * - Parameter
        - Direction
        - Shape / Range
        - Meaning
        - Units / Normalization
        - Index / ghost-cell requirement
      * - ``p``
        - ``in``
        - ``integer scalar``
        - particle index
        - integer index or count
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``np``
        - ``in``
        - ``integer scalar``
        - particle count or second dimension of par
        - integer index or count
        - No extra ghost-cell requirement beyond the source-declared scalar or array bounds.
      * - ``par``
        - ``in``
        - ``real(1:6,1:np)``
        - particle phase-space array
        - positions in grid-index units; other components follow caller convention
        - Uses ``par(1:3,p)`` as position; caller keeps particles inside the local or guard-covered range.
      * - ``il``
        - ``in``
        - ``integer(1:3)``
        - local active-grid lower bounds
        - integer index or count
        - Controls accessible local stencil bounds and must match the actual allocation.
      * - ``iu``
        - ``in``
        - ``integer(1:3)``
        - local active-grid upper bounds
        - integer index or count
        - Controls accessible local stencil bounds and must match the actual allocation.
      * - ``Ex``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - x electric-field grid.
        - field value in caller normalization
        - Array covers one layer around the local range; trilinear interpolation touches eight neighboring nodes.
      * - ``Ey``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - y electric-field grid.
        - field value in caller normalization
        - Array covers one layer around the local range; trilinear interpolation touches eight neighboring nodes.
      * - ``Ez``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - z electric-field grid.
        - field value in caller normalization
        - Array covers one layer around the local range; trilinear interpolation touches eight neighboring nodes.
      * - ``Bx``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - x magnetic-field grid.
        - field value in caller normalization
        - Array covers one layer around the local range; trilinear interpolation touches eight neighboring nodes.
      * - ``By``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - y magnetic-field grid.
        - field value in caller normalization
        - Array covers one layer around the local range; trilinear interpolation touches eight neighboring nodes.
      * - ``Bz``
        - ``in``
        - ``real(il(1)-1:iu(1)+1,il(2)-1:iu(2)+1,il(3)-1:iu(3)+1)``
        - z magnetic-field grid.
        - field value in caller normalization
        - Array covers one layer around the local range; trilinear interpolation touches eight neighboring nodes.
      * - ``E``
        - ``in/out``
        - ``real(1:3)``
        - electric field vector at the particle
        - particle/field units chosen by the caller
        - Single-particle vector with no ghost cells; component order follows the coordinate system on this page.
      * - ``B``
        - ``in/out``
        - ``real(1:3)``
        - magnetic field vector at the particle
        - particle/field units chosen by the caller
        - Single-particle vector with no ghost cells; component order follows the coordinate system on this page.

   .. rubric:: Local Assumptions / Preconditions

   - Particle positions are in grid-index units; the deposition/interpolation stencil must lie inside the local array or its guard cells.
   - This page states only the local routine conventions; it does not assume a global driver unit system, time step, or boundary policy.

   .. rubric:: Implementation Notes

   - Adds ``0.5`` to the particle position to map into cell-centered index space.
   - Performs eight-point trilinear interpolation for each of the six field components.

   .. rubric:: Calling Notes

   - Guard cells must be valid when particles are close to local boundaries.


   .. rubric:: Generated API

   .. doxygenfile:: sub_C01_gather_3Dxyz.f90

   .. rubric:: Instruction

   ``sub_C01_gather_3Dxyz`` interpolates cell-centered 3D Cartesian electromagnetic fields to one particle position. The position is read from ``par(1:3,p)``, shifted by ``+0.5`` to cell-centered index coordinates, and blended from the eight surrounding grid points with trilinear weights.

   .. image:: ../../../images/C_Gather/C01_E_B_interpolation.png
      :alt: C01 field interpolation schematic
      :scale: 50
      :align: center

   .. rubric:: Interface

   .. code-block:: fortran

      call sub_C01_gather_3Dxyz(p, np, par, il, iu, Ex, Ey, Ez, &
                                Bx, By, Bz, E, B)

   .. list-table::
      :header-rows: 1
      :widths: 18 12 46

      * - Argument
        - Direction
        - Meaning
      * - ``p``
        - in
        - Particle index to gather for.
      * - ``np``
        - in
        - Number of particles; second dimension of ``par``.
      * - ``par(1:6,1:np)``
        - in
        - Particle phase-space array; only ``par(1:3,p)`` is used here.
      * - ``il(1:3)``, ``iu(1:3)``
        - in
        - Lower and upper grid indices of the local subdomain.
      * - ``Ex,Ey,Ez``
        - in
        - Electric-field components with array bounds ``il-1:iu+1``.
      * - ``Bx,By,Bz``
        - in
        - Magnetic-field components with array bounds ``il-1:iu+1``.
      * - ``E(1:3)``, ``B(1:3)``
        - out
        - Interpolated electric and magnetic fields at the particle position.

   .. rubric:: Trilinear Interpolation

   Let

   .. math::

      x_g = x_p + 0.5,\qquad i=\lfloor x_g \rfloor,\qquad f_i=x_g-i,

   with analogous definitions in y and z. For any field component :math:`F`,

   .. math::

      F_p = \sum_{\alpha,\beta,\gamma\in\{0,1\}}
      F_{i+\alpha,j+\beta,k+\gamma}
      w_x(\alpha)w_y(\beta)w_z(\gamma),

   where :math:`w_x(0)=1-f_i` and :math:`w_x(1)=f_i`, with the same pattern in the other directions. The caller must ensure that the particle and its eight-point interpolation stencil are covered by the local array and guard cells.
