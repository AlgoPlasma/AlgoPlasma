sub_E01_fdtd_2d_rz_tez_H.f90
----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在 E01 的 TEz 分量组中，用整数步方位角电场 ``Ephi`` 更新径向磁场 ``Hr``
   和轴向磁场 ``Hz``。该例程对应柱坐标磁场更新中的
   :math:`\partial_z E_\phi` 和 :math:`(1/r)\partial_r(rE_\phi)` 项；当径向指标
   ``i=0`` 时，代码对 ``Hr`` 施加轴线闭合 ``Hr(0,k)=0``。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 14 10 26 36 22 42

      * - 参数
        - 方向
        - shape / 范围
        - 含义
        - 单位 / 归一化
        - 索引 / ghost-cell 要求
      * - ``ilo_f``
        - ``in``
        - ``integer scalar``
        - ``r`` 方向数组声明下界
        - 整数下标
        - 用于声明 ``Ephi``、``Hr``、``Hz`` 的第一维范围。代码不读取 ``i-1``，但会读取 ``Ephi(i+1,k)``。
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - ``r`` 方向数组声明上界
        - 整数下标
        - ``Hr``、``Hz`` 至少覆盖 ``iu``；``Ephi`` 必须能读到 ``iu+1``，因此通常需要 ``ihi_f >= iu+1``。
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明下界
        - 整数下标
        - 必须覆盖更新下界 ``kl``。本例程不读取 ``k-1``。
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明上界
        - 整数下标
        - ``Hr``、``Hz`` 至少覆盖 ``ku``；``Ephi`` 必须能读到 ``ku+1``，因此通常需要 ``khi_f >= ku+1``。
      * - ``il``
        - ``in``
        - ``integer scalar``
        - 径向更新下界
        - 整数下标
        - 循环从 ``i=il`` 开始。若 ``il=0``，``Hr(0,k)`` 被置零；``Hz(0,k)`` 仍会用 ``Ephi(1,k)`` 更新。
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - 径向更新上界
        - 整数下标
        - 循环到 ``i=iu`` 结束；由于 ``Hz`` 更新读取 ``Ephi(i+1,k)``，需要 ``Ephi(iu+1,k)`` 可读。
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - 轴向更新下界
        - 整数下标
        - 循环从 ``k=kl`` 开始；``Hr`` 更新读取 ``Ephi(i,kl+1)``。
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - 轴向更新上界
        - 整数下标
        - 循环到 ``k=ku`` 结束；由于 ``Hr`` 更新读取 ``Ephi(i,k+1)``，需要 ``Ephi(i,ku+1)`` 可读。
      * - ``Ephi``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 方位角电场分量
        - 调用者归一化下的电场值
        - 用于 ``Hr`` 的轴向差分 ``Ephi(i,k+1)-Ephi(i,k)``，以及 ``Hz`` 的守恒型径向差分 ``rEphi``。
      * - ``Hr``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 径向磁场分量
        - 调用者归一化下的磁场值
        - 普通内点原位累加更新；``i=0`` 处不累加，而是强制设为 ``0.0``。
      * - ``Hz``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 轴向磁场分量
        - 调用者归一化下的磁场值
        - 对所有 ``i=il:iu`` 原位更新；径向差分会读取 ``Ephi(i+1,k)``。
      * - ``dt``
        - ``in``
        - ``real scalar``
        - 时间步长
        - 调用者单位的时间步长
        - 只作为更新系数 ``dt/mu`` 使用；例程不读取全局时间步。
      * - ``dr``
        - ``in``
        - ``real scalar``
        - 径向网格间距
        - 调用者单位的长度
        - 用作 ``Hz`` 守恒型径向差分分母，需为正数。
      * - ``dz``
        - ``in``
        - ``real scalar``
        - z 方向网格间距
        - 调用者单位的长度
        - 用作 ``Hr`` 轴向差分分母，需为正数。
      * - ``mu``
        - ``in``
        - ``real scalar``
        - 磁导率或等效归一化系数
        - 调用者归一化下的磁导率
        - 标量参数，整个更新区间共用同一个值；需非零。

   .. rubric:: 局部假设 / 前置条件

   - 网格是二维轴对称 ``r-z`` Yee staggered 布局；第一维是径向 ``r``，第二维是轴向 ``z``。
   - 所有步长、介质参数和数组边界都由调用者传入；本例程不假设全局 ``dx=1``、``dt=1`` 或固定 real kind。
   - 本例程只更新指定的局部范围；不做 MPI exchange、外边界条件、源项注入或粒子电流沉积。
   - ``Ephi`` 应来自与 leapfrog 对应的整数步电场时间层；``Hr`` 和 ``Hz`` 是被原位更新的半步磁场。
   - ``Hr`` 更新需要 ``Ephi(i,k+1)``；``Hz`` 更新需要 ``Ephi(i+1,k)``。这些相邻值可以来自物理边界条件、周期/对称填充或 MPI ghost cell。
   - ``i=0`` 被代码解释为物理径向轴线，并强制 ``Hr=0``。若某个 MPI 子域的本地下标 0 不是物理轴线，不应把它传入本例程作为物理 ``i=0`` 点。

   .. rubric:: 实现逻辑

   代码分两个循环完成更新。

   第一个循环更新 ``Hr``：

   - 若 ``i==0``，执行轴线闭合 ``Hr(0,k)=0.0``。
   - 若 ``i>0``，计算 ``term_z = (Ephi(i,k+1)-Ephi(i,k))/dz``。
   - 然后执行 ``Hr(i,k) = Hr(i,k) + dt/mu*term_z``。

   对应的普通内点离散式为：

   .. math::

      H_{r,i,k}^{n+1/2}
      =
      H_{r,i,k}^{n-1/2}
      +\frac{\Delta t}{\mu}
      \frac{E_{\phi,i,k+1}^{n}-E_{\phi,i,k}^{n}}{\Delta z},
      \quad i>0.

   轴线上使用：

   .. math::

      H_{r,0,k}^{n+1/2}=0.

   第二个循环更新 ``Hz``。代码使用
   ``ri=max((i+0.5)*dr,0.5*dr)``、``riph=(i+1)*dr``、``rimh=i*dr``，再计算：

   .. math::

      H_{z,i,k}^{n+1/2}
      =
      H_{z,i,k}^{n-1/2}
      -\frac{\Delta t}{\mu}
      \frac{r_{i+1}E_{\phi,i+1,k}^{n}-r_iE_{\phi,i,k}^{n}}
      {r_{i+1/2}\Delta r}.

   当 ``i=0`` 时，``r_i=0``，该公式自然退化为使用 ``Ephi(1,k)`` 的轴线邻近闭合形式。

   .. rubric:: 调用注意

   - 调用者负责维持 Yee leapfrog 时间层关系；本例程只完成一次局部场更新。
   - 若 ``ku`` 是物理或局部边界，调用前必须先准备 ``Ephi(:,ku+1)``，或者把 ``Hr`` 的更新范围从可用内点结束。
   - 若 ``iu`` 是物理或局部边界，调用前必须先准备 ``Ephi(iu+1,:)``，或者把 ``Hz`` 的更新范围从可用内点结束。
   - 该 routine 使用标量 ``mu``，不支持在一次调用内给不同网格点使用不同磁导率。


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   In the E01 TEz component group, updates the radial magnetic field
   ``Hr`` and axial magnetic field ``Hz`` from the integer-step azimuthal
   electric field ``Ephi``. The kernel applies the cylindrical magnetic update
   terms :math:`\partial_z E_\phi` and
   :math:`(1/r)\partial_r(rE_\phi)`; at radial index ``i=0`` it enforces the
   axis closure ``Hr(0,k)=0``.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 14 10 26 36 22 42

      * - Parameter
        - Direction
        - Shape / Range
        - Meaning
        - Units / Normalization
        - Index / ghost-cell requirement
      * - ``ilo_f``
        - ``in``
        - ``integer scalar``
        - declared lower ``r`` bound of the arrays
        - integer index
        - Declares the first dimension of ``Ephi``, ``Hr``, and ``Hz``. The code does not read ``i-1`` but does read ``Ephi(i+1,k)``.
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - declared upper ``r`` bound of the arrays
        - integer index
        - ``Hr`` and ``Hz`` must cover ``iu``; ``Ephi`` must be readable at ``iu+1``, so usually ``ihi_f >= iu+1``.
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - declared lower ``z`` bound of the arrays
        - integer index
        - Must cover the update lower bound ``kl``. The routine does not read ``k-1``.
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - declared upper ``z`` bound of the arrays
        - integer index
        - ``Hr`` and ``Hz`` must cover ``ku``; ``Ephi`` must be readable at ``ku+1``, so usually ``khi_f >= ku+1``.
      * - ``il``
        - ``in``
        - ``integer scalar``
        - lower radial update index
        - integer index
        - The loop starts at ``i=il``. If ``il=0``, ``Hr(0,k)`` is set to zero; ``Hz(0,k)`` is still updated from ``Ephi(1,k)``.
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - upper radial update index
        - integer index
        - The loop ends at ``i=iu``; because the ``Hz`` update reads ``Ephi(i+1,k)``, ``Ephi(iu+1,k)`` must be valid.
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - lower axial update index
        - integer index
        - The loop starts at ``k=kl``; the ``Hr`` update reads ``Ephi(i,kl+1)``.
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - upper axial update index
        - integer index
        - The loop ends at ``k=ku``; because the ``Hr`` update reads ``Ephi(i,k+1)``, ``Ephi(i,ku+1)`` must be valid.
      * - ``Ephi``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - azimuthal electric-field component
        - electric field in caller normalization
        - Used in the axial difference for ``Hr`` and in the conservative radial ``rEphi`` difference for ``Hz``.
      * - ``Hr``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - radial magnetic-field component
        - magnetic field in caller normalization
        - Updated in place for interior points; at ``i=0`` it is overwritten with ``0.0``.
      * - ``Hz``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - axial magnetic-field component
        - magnetic field in caller normalization
        - Updated in place for all ``i=il:iu``; the radial difference reads ``Ephi(i+1,k)``.
      * - ``dt``
        - ``in``
        - ``real scalar``
        - time step
        - time step in caller units
        - Used only through the factor ``dt/mu``; no global time step is read.
      * - ``dr``
        - ``in``
        - ``real scalar``
        - radial grid spacing
        - length in caller units
        - Denominator for the conservative radial ``Hz`` update; must be positive.
      * - ``dz``
        - ``in``
        - ``real scalar``
        - axial grid spacing
        - length in caller units
        - Denominator for the axial ``Hr`` update; must be positive.
      * - ``mu``
        - ``in``
        - ``real scalar``
        - permeability or equivalent normalized coefficient
        - permeability in caller normalization
        - Scalar value shared by the whole update range; must be nonzero.

   .. rubric:: Local Assumptions / Preconditions

   - The grid is a 2D axisymmetric ``r-z`` Yee-staggered layout; the first dimension is radial and the second is axial.
   - All spacings, material parameters, and bounds are passed explicitly; the routine assumes no global ``dx=1``, ``dt=1``, or fixed real kind.
   - Only the requested local range is modified; MPI exchange, external boundary conditions, sources, and current deposition are outside this routine.
   - ``Ephi`` should be the leapfrog-compatible integer-step electric field; ``Hr`` and ``Hz`` are updated in place as half-step magnetic fields.
   - The ``Hr`` update requires ``Ephi(i,k+1)``; the ``Hz`` update requires ``Ephi(i+1,k)``. These values may come from physical boundary conditions, periodic/symmetry fill, or MPI ghost cells.
   - ``i=0`` is interpreted as the physical radial axis and forces ``Hr=0``. If an MPI-local index 0 is not the physical axis, do not pass it as the physical ``i=0`` point.

   .. rubric:: Implementation Notes

   The code performs two loops.

   First, it updates ``Hr``:

   - if ``i==0``, enforce the axis closure ``Hr(0,k)=0.0``;
   - if ``i>0``, compute ``term_z = (Ephi(i,k+1)-Ephi(i,k))/dz``;
   - then apply ``Hr(i,k) = Hr(i,k) + dt/mu*term_z``.

   The interior update is:

   .. math::

      H_{r,i,k}^{n+1/2}
      =
      H_{r,i,k}^{n-1/2}
      +\frac{\Delta t}{\mu}
      \frac{E_{\phi,i,k+1}^{n}-E_{\phi,i,k}^{n}}{\Delta z},
      \quad i>0.

   The axis branch is:

   .. math::

      H_{r,0,k}^{n+1/2}=0.

   Second, it updates ``Hz``. The code uses
   ``ri=max((i+0.5)*dr,0.5*dr)``, ``riph=(i+1)*dr``, and ``rimh=i*dr``:

   .. math::

      H_{z,i,k}^{n+1/2}
      =
      H_{z,i,k}^{n-1/2}
      -\frac{\Delta t}{\mu}
      \frac{r_{i+1}E_{\phi,i+1,k}^{n}-r_iE_{\phi,i,k}^{n}}
      {r_{i+1/2}\Delta r}.

   At ``i=0``, ``r_i=0``, so this formula naturally becomes an axis-neighbor
   closure using ``Ephi(1,k)``.

   .. rubric:: Calling Notes

   - The caller maintains the Yee leapfrog time staggering; this routine performs only one local field update.
   - If ``ku`` is a physical or local boundary, prepare ``Ephi(:,ku+1)`` before the call or end the ``Hr`` update range at a valid interior row.
   - If ``iu`` is a physical or local boundary, prepare ``Ephi(iu+1,:)`` before the call or end the ``Hz`` update range at a valid interior column.
   - This routine uses scalar ``mu`` and does not support different permeability values per grid point within one call.

   .. rubric:: Generated API

   .. doxygenfile:: sub_E01_fdtd_2d_rz_tez_H.f90
