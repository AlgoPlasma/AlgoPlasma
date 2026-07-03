===========================
B03_scatter_3Dxyz_bspline
===========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块说明

   ``B03_scatter_3Dxyz_bspline`` 在三维 Cartesian 网格上执行任意阶
   centered B-spline 粒子沉积。它与
   :doc:`C02_gather_3Dxyz_bspline </rst_files/C_Gather/C02_gather_3Dxyz_bspline>`
   使用同一类中心化 B-spline 形函数。C02 做的是从网格到粒子的 gather，
   B03 做的是从粒子到网格的 scatter。

   在 PIC 计算中，scatter 的核心是把每个粒子的源项按形函数分配给附近网格。
   本模块提供两类源项：

   - 粒子数或统一权重源项：每个粒子总贡献为 ``w``。
   - 粒子分量源项：每个粒子总贡献为 ``w*par(d,p)``。

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 40 60

      * - 文件
        - 作用
      * - :doc:`mod_B03_scatter_3Dxyz_bspline.f90 <B03_scatter_3Dxyz_bspline/mod_B03_scatter_3Dxyz_bspline>`
        - 源码级 module 入口，汇入两个顶层沉积子程序和两个 B-spline 辅助例程。
      * - :doc:`sub_B03_scatter_3Dxyz_bspline.f90 <B03_scatter_3Dxyz_bspline/sub_B03_scatter_3Dxyz_bspline>`
        - 粒子数沉积；对每个粒子沉积总量 ``w``。
      * - :doc:`sub_B03_scatter_3Dxyz_bspline_v.f90 <B03_scatter_3Dxyz_bspline/sub_B03_scatter_3Dxyz_bspline_v>`
        - 粒子分量沉积；对每个粒子沉积总量 ``w*par(d,p)``。
      * - :doc:`sub_B03_bspline_stencil_1d.f90 <B03_scatter_3Dxyz_bspline/sub_B03_bspline_stencil_1d>`
        - 在一个方向上生成 ``order+1`` 个网格指标和对应权重。
      * - :doc:`fun_B03_bspline_shape.f90 <B03_scatter_3Dxyz_bspline/fun_B03_bspline_shape>`
        - 递归计算中心化 B-spline 形函数 ``S_order(r)``。

   .. rubric:: 主要接口

   .. code-block:: fortran

      call sub_B03_scatter_3Dxyz_bspline(il,iu,den,np,par,w,order)
      call sub_B03_scatter_3Dxyz_bspline_v(il,iu,den,np,par,d,w,order)

   第一个接口适合沉积粒子数、宏粒子权重或只需要统一权重的标量源项。第二个接口适合沉积
   ``par`` 中的某个分量，例如速度分量、动量分量或其他已经存入 ``par(d,p)``
   的粒子量。两个接口都执行累加语义，调用前通常由调用层清零 ``den``。

   .. rubric:: B-spline 形函数约定

   给定 knot 序列 :math:`u_i`，原始 B-spline 满足 Cox-de Boor 递推：

   .. math::

      N_{i,0}(u)=
      \begin{cases}
      1, & u_i \le u < u_{i+1},\\
      0, & \mathrm{otherwise},
      \end{cases}

   .. math::

      N_{i,p}(u)=
      \frac{u-u_i}{u_{i+p}-u_i}N_{i,p-1}(u)
      +\frac{u_{i+p+1}-u}{u_{i+p+1}-u_{i+1}}N_{i+1,p-1}(u).

   对均匀 PIC 网格取 :math:`u_i=i`，上式变为

   .. math::

      N_{i,p}(u)=
      \frac{u-i}{p}N_{i,p-1}(u)
      +\frac{i+p+1-u}{p}N_{i+1,p-1}(u).

   PIC 中更方便使用粒子坐标到网格指标的距离

   .. math::

      r=x_p-i.

   将 :math:`N_{0,p}` 平移到以 :math:`r=0` 为中心，定义中心化形函数

   .. math::

      S_p(r)=N_{0,p}\left(r+\frac{p+1}{2}\right).

   因此

   .. math::

      S_0(r)=
      \begin{cases}
      1, & -\frac{1}{2}\le r < \frac{1}{2},\\
      0, & \mathrm{otherwise},
      \end{cases}

   并且对 :math:`p>0` 有

   .. math::

      S_p(r)=
      \frac{r+\frac{p+1}{2}}{p}
      S_{p-1}\left(r+\frac{1}{2}\right)
      +\frac{\frac{p+1}{2}-r}{p}
      S_{p-1}\left(r-\frac{1}{2}\right).

   ``fun_B03_bspline_shape`` 实现这个中心化递推。

   .. rubric:: 三维 scatter 公式

   对一个粒子位置 :math:`(x_p,y_p,z_p)`，每个方向先取模板起点

   .. math::

      i_0=\left\lfloor x_p-\frac{p-1}{2}\right\rfloor,\quad
      j_0=\left\lfloor y_p-\frac{p-1}{2}\right\rfloor,\quad
      k_0=\left\lfloor z_p-\frac{p-1}{2}\right\rfloor.

   三个方向的权重为

   .. math::

      w_a^x=S_p(x_p-i_0-a),\quad
      w_b^y=S_p(y_p-j_0-b),\quad
      w_c^z=S_p(z_p-k_0-c).

   粒子数沉积为

   .. math::

      den_{i_0+a,j_0+b,k_0+c}
      \leftarrow
      den_{i_0+a,j_0+b,k_0+c}
      +w\,w_a^xw_b^yw_c^z,

   其中 :math:`a,b,c=0,1,\ldots,p`。分量沉积只把源项换成
   :math:`w\,par(d,p)`：

   .. math::

      den_{i_0+a,j_0+b,k_0+c}
      \leftarrow
      den_{i_0+a,j_0+b,k_0+c}
      +w\,par(d,p)\,w_a^xw_b^yw_c^z.

   因为一维权重归一化，三维张量积权重也归一化，所以每个粒子的总沉积量保持为源项本身。
   当 ``order>=1`` 时，形函数还满足一阶矩条件，因此测试中也检查沉积后的一阶矩是否等于粒子位置加权和。

   .. rubric:: 与 B01 的关系

   ``order=1`` 时，中心化形函数退化为线性 tent 函数：

   .. math::

      S_1(r)=
      \begin{cases}
      1-|r|, & |r|<1,\\
      0, & \mathrm{otherwise}.
      \end{cases}

   每个方向只有两个网格点，三维共有 :math:`2^3=8` 个 stencil 点。这个张量积公式正好是
   B01 的 CIC/三线性沉积。因此 B03 在 ``order=1`` 时应与 B01 逐点一致。

   .. rubric:: 局部约定

   - 粒子位置 ``par(1:3,p)`` 使用网格指标单位。
   - ``den`` 的可访问范围必须至少覆盖 ``ng=(order+2)/2`` 个 guard/halo。
   - 本模块不处理边界、周期折叠或 MPI guard-cell 交换。
   - 本模块不主动清零 ``den``，以便调用层做多物种或分批累加。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>作者</strong></p>
        <p class="ap-home-contact">赵中平 (2026/06/06) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Description

   ``B03_scatter_3Dxyz_bspline`` performs arbitrary-order centered B-spline
   particle deposition on a 3D Cartesian grid. It uses the same centered
   B-spline shape-function family as
   :doc:`C02_gather_3Dxyz_bspline </rst_files/C_Gather/C02_gather_3Dxyz_bspline>`.
   C02 gathers grid data to particles, while B03 scatters particle data to the
   grid.

   In PIC calculations, scatter means distributing each particle source to
   nearby grid points through a shape function. This module provides two
   source choices:

   - Particle number or uniform source weight: each particle contributes total amount ``w``.
   - Particle-component source: each particle contributes total amount ``w*par(d,p)``.

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 40 60

      * - File
        - Role
      * - :doc:`mod_B03_scatter_3Dxyz_bspline.f90 <B03_scatter_3Dxyz_bspline/mod_B03_scatter_3Dxyz_bspline>`
        - Source-level module entry that includes the two top-level deposition routines and two B-spline helpers.
      * - :doc:`sub_B03_scatter_3Dxyz_bspline.f90 <B03_scatter_3Dxyz_bspline/sub_B03_scatter_3Dxyz_bspline>`
        - Particle-number deposition; each particle deposits total amount ``w``.
      * - :doc:`sub_B03_scatter_3Dxyz_bspline_v.f90 <B03_scatter_3Dxyz_bspline/sub_B03_scatter_3Dxyz_bspline_v>`
        - Particle-component deposition; each particle deposits total amount ``w*par(d,p)``.
      * - :doc:`sub_B03_bspline_stencil_1d.f90 <B03_scatter_3Dxyz_bspline/sub_B03_bspline_stencil_1d>`
        - Builds ``order+1`` grid indices and corresponding weights in one direction.
      * - :doc:`fun_B03_bspline_shape.f90 <B03_scatter_3Dxyz_bspline/fun_B03_bspline_shape>`
        - Recursively evaluates the centered B-spline shape function ``S_order(r)``.

   .. rubric:: Main Interfaces

   .. code-block:: fortran

      call sub_B03_scatter_3Dxyz_bspline(il,iu,den,np,par,w,order)
      call sub_B03_scatter_3Dxyz_bspline_v(il,iu,den,np,par,d,w,order)

   The first interface is used for particle number, macro-particle weight, or
   any scalar source with the same weight for every particle. The second
   interface deposits a selected particle quantity stored in ``par(d,p)``,
   such as a velocity component, momentum component, or another particle
   scalar. Both interfaces accumulate into ``den``; callers normally zero
   ``den`` before the first deposition call.

   .. rubric:: B-spline Shape Convention

   Given a knot sequence :math:`u_i`, the original B-spline follows the
   Cox-de Boor recurrence:

   .. math::

      N_{i,0}(u)=
      \begin{cases}
      1, & u_i \le u < u_{i+1},\\
      0, & \mathrm{otherwise},
      \end{cases}

   .. math::

      N_{i,p}(u)=
      \frac{u-u_i}{u_{i+p}-u_i}N_{i,p-1}(u)
      +\frac{u_{i+p+1}-u}{u_{i+p+1}-u_{i+1}}N_{i+1,p-1}(u).

   On a uniform PIC grid, take :math:`u_i=i`, giving

   .. math::

      N_{i,p}(u)=
      \frac{u-i}{p}N_{i,p-1}(u)
      +\frac{i+p+1-u}{p}N_{i+1,p-1}(u).

   PIC scatter is more convenient in terms of the distance from a particle
   coordinate to a grid index,

   .. math::

      r=x_p-i.

   Shift :math:`N_{0,p}` so that the shape is centered at :math:`r=0`:

   .. math::

      S_p(r)=N_{0,p}\left(r+\frac{p+1}{2}\right).

   Thus

   .. math::

      S_0(r)=
      \begin{cases}
      1, & -\frac{1}{2}\le r < \frac{1}{2},\\
      0, & \mathrm{otherwise},
      \end{cases}

   and for :math:`p>0`,

   .. math::

      S_p(r)=
      \frac{r+\frac{p+1}{2}}{p}
      S_{p-1}\left(r+\frac{1}{2}\right)
      +\frac{\frac{p+1}{2}-r}{p}
      S_{p-1}\left(r-\frac{1}{2}\right).

   ``fun_B03_bspline_shape`` implements this centered recurrence.

   .. rubric:: 3D Scatter Formula

   For one particle at :math:`(x_p,y_p,z_p)`, each direction first chooses the
   stencil start

   .. math::

      i_0=\left\lfloor x_p-\frac{p-1}{2}\right\rfloor,\quad
      j_0=\left\lfloor y_p-\frac{p-1}{2}\right\rfloor,\quad
      k_0=\left\lfloor z_p-\frac{p-1}{2}\right\rfloor.

   The 1D weights are

   .. math::

      w_a^x=S_p(x_p-i_0-a),\quad
      w_b^y=S_p(y_p-j_0-b),\quad
      w_c^z=S_p(z_p-k_0-c).

   Particle-number deposition is

   .. math::

      den_{i_0+a,j_0+b,k_0+c}
      \leftarrow
      den_{i_0+a,j_0+b,k_0+c}
      +w\,w_a^xw_b^yw_c^z,

   where :math:`a,b,c=0,1,\ldots,p`. Component deposition only changes the
   source to :math:`w\,par(d,p)`:

   .. math::

      den_{i_0+a,j_0+b,k_0+c}
      \leftarrow
      den_{i_0+a,j_0+b,k_0+c}
      +w\,par(d,p)\,w_a^xw_b^yw_c^z.

   Since each 1D stencil is normalized, the tensor-product stencil is also
   normalized, so the total deposited amount of each particle is its source.
   For ``order>=1``, the shape also satisfies the first moment; the test
   therefore checks that deposited first moments equal weighted particle
   positions.

   .. rubric:: Relation to B01

   For ``order=1``, the centered shape becomes the linear tent function:

   .. math::

      S_1(r)=
      \begin{cases}
      1-|r|, & |r|<1,\\
      0, & \mathrm{otherwise}.
      \end{cases}

   Each direction has two stencil points, so the 3D stencil has
   :math:`2^3=8` points. This tensor-product formula is exactly the B01
   CIC/trilinear deposition. B03 should therefore match B01 pointwise for
   ``order=1``.

   .. rubric:: Local Conventions

   - Particle positions ``par(1:3,p)`` are in grid-index units.
   - The accessible ``den`` range must cover at least ``ng=(order+2)/2`` guard/halo cells.
   - This module does not handle boundaries, periodic folding, or MPI guard-cell exchange.
   - This module does not zero ``den`` internally, so callers can accumulate multiple species or particle batches.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Author</strong></p>
        <p class="ap-home-contact">Zhongping ZHAO (2026/06/06) · Harbin Institute of Technology</p>
      </div>

.. toctree::
   :maxdepth: 1
   :hidden:

   B03_scatter_3Dxyz_bspline/mod_B03_scatter_3Dxyz_bspline
   B03_scatter_3Dxyz_bspline/sub_B03_scatter_3Dxyz_bspline
   B03_scatter_3Dxyz_bspline/sub_B03_scatter_3Dxyz_bspline_v
   B03_scatter_3Dxyz_bspline/sub_B03_bspline_stencil_1d
   B03_scatter_3Dxyz_bspline/fun_B03_bspline_shape
