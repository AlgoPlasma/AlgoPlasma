sub_E01_fdtd_2d_rz_tmz_E.f90
----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在 E01 的 TMz 分量组中，用半步方位角磁场 ``Ha``，即 ``Hphi``，更新径向电场
   ``Er`` 和轴向电场 ``Ez``。``Er`` 由 ``Ha`` 的轴向差分更新；``Ez`` 由柱坐标
   :math:`(1/r)\partial_r(rH_\phi)` 型径向项更新，并在 ``i=0`` 轴线上使用专门闭合公式。

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
        - 用于声明 ``Ha``、``Er``、``Ez`` 的第一维范围。普通 ``Ez`` 更新会读取 ``Ha(i-1,k)``。
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - ``r`` 方向数组声明上界
        - 整数下标
        - 必须覆盖更新上界 ``iu``；本例程不读取 ``i+1``。
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明下界
        - 整数下标
        - ``Er`` 更新会读取 ``Ha(i,k-1)``，因此通常需要 ``klo_f <= kl-1``。
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明上界
        - 整数下标
        - 必须覆盖更新上界 ``ku``；本例程不读取 ``k+1``。
      * - ``il``
        - ``in``
        - ``integer scalar``
        - 径向更新下界
        - 整数下标
        - 循环从 ``i=il`` 开始。若 ``il=0``，``Ez`` 使用轴线闭合；若 ``il>0``，需要 ``Ha(il-1,k)`` 可读。
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - 径向更新上界
        - 整数下标
        - 循环到 ``i=iu`` 结束，必须满足 ``iu <= ihi_f``。
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - 轴向更新下界
        - 整数下标
        - ``Er`` 更新需要 ``Ha(i,kl-1)`` 可读。
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - 轴向更新上界
        - 整数下标
        - 循环到 ``k=ku`` 结束，必须满足 ``ku <= khi_f``。
      * - ``Ha``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 方位角磁场分量 ``Hphi``
        - 调用者归一化下的磁场值
        - 用于 ``Er`` 的轴向差分 ``Ha(i,k)-Ha(i,k-1)``，以及 ``Ez`` 的守恒型径向差分。
      * - ``Er``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 径向电场分量
        - 调用者归一化下的电场值
        - 在 ``il:iu, kl:ku`` 范围内原位累加更新。
      * - ``Ez``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 轴向电场分量
        - 调用者归一化下的电场值
        - 普通内点读取 ``Ha(i-1,k)``；``i=0`` 处使用 ``4*Ha(0,k)/dr`` 形式的轴线闭合。
      * - ``dt``
        - ``in``
        - ``real scalar``
        - 时间步长
        - 调用者单位的时间步长
        - 只作为更新系数 ``dt/ep`` 使用；例程不读取全局时间步。
      * - ``dr``
        - ``in``
        - ``real scalar``
        - 径向网格间距
        - 调用者单位的长度
        - 用于 ``Ez`` 径向 metric 项和轴线闭合，需为正数。
      * - ``dz``
        - ``in``
        - ``real scalar``
        - z 方向网格间距
        - 调用者单位的长度
        - 用作 ``Er`` 轴向差分分母，需为正数。
      * - ``ep``
        - ``in``
        - ``real scalar``
        - 介电常数或等效归一化系数
        - 调用者归一化下的介电常数
        - 标量参数，整个更新区间共用同一个值；需非零。

   .. rubric:: 局部假设 / 前置条件

   - 网格是二维轴对称 ``r-z`` Yee staggered 布局；第一维是径向 ``r``，第二维是轴向 ``z``。
   - ``Ha`` 应来自与 leapfrog 对应的半步磁场时间层；``Er`` 和 ``Ez`` 是被原位更新的整数步电场。
   - ``Er`` 更新需要 ``Ha(i,k-1)``；普通 ``Ez`` 更新需要 ``Ha(i-1,k)``。这些相邻值可以来自物理边界条件、对称填充或 MPI ghost cell。
   - ``i=0`` 被代码解释为物理径向轴线，并对 ``Ez`` 使用专门闭合。若某个 MPI 子域的本地下标 0 不是物理轴线，不应把它传入本例程作为物理 ``i=0`` 点。
   - 本例程不做 MPI exchange、外边界条件、源项注入或粒子电流沉积。

   .. rubric:: 实现逻辑

   第一个循环更新 ``Er``：

   .. math::

      E_{r,i,k}^{n+1}
      =
      E_{r,i,k}^{n}
      -\frac{\Delta t}{\epsilon}
      \frac{H_{\phi,i,k}^{n+1/2}-H_{\phi,i,k-1}^{n+1/2}}{\Delta z}.

   第二个循环更新 ``Ez``。普通内点 ``i>0`` 使用：

   .. math::

      E_{z,i,k}^{n+1}
      =
      E_{z,i,k}^{n}
      +\frac{\Delta t}{\epsilon\,i\Delta r}
      \left[
      \left(i+\frac{1}{2}\right)H_{\phi,i,k}^{n+1/2}
      -
      \left(i-\frac{1}{2}\right)H_{\phi,i-1,k}^{n+1/2}
      \right].

   轴线上使用：

   .. math::

      E_{z,0,k}^{n+1}
      =
      E_{z,0,k}^{n}
      +\frac{4\Delta t}{\epsilon\Delta r}H_{\phi,0,k}^{n+1/2}.

   .. rubric:: 调用注意

   - 若 ``kl`` 是物理或局部边界，调用前必须先准备 ``Ha(:,kl-1)``，或者把 ``Er`` 的更新范围从可用内点开始。
   - 若 ``il>0``，调用前必须先准备 ``Ha(il-1,:)``；若 ``il=0``，轴线点走专门闭合，但 ``i=1`` 仍会读取 ``Ha(0,:)``。
   - 该 routine 使用标量 ``ep``，不支持在一次调用内给不同网格点使用不同介电常数。


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   In the E01 TMz component group, updates radial electric field ``Er``
   and axial electric field ``Ez`` from the half-step azimuthal magnetic field
   ``Ha`` (``Hphi``). ``Er`` uses an axial difference of ``Ha``; ``Ez`` uses the
   cylindrical :math:`(1/r)\partial_r(rH_\phi)` radial term, with a dedicated
   axis closure at ``i=0``.

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
        - Declares the first dimension of ``Ha``, ``Er``, and ``Ez``. Interior ``Ez`` updates read ``Ha(i-1,k)``.
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - declared upper ``r`` bound of the arrays
        - integer index
        - Must cover ``iu``; the routine does not read ``i+1``.
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - declared lower ``z`` bound of the arrays
        - integer index
        - ``Er`` updates read ``Ha(i,k-1)``, so usually ``klo_f <= kl-1``.
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - declared upper ``z`` bound of the arrays
        - integer index
        - Must cover ``ku``; the routine does not read ``k+1``.
      * - ``il``
        - ``in``
        - ``integer scalar``
        - lower radial update index
        - integer index
        - If ``il=0``, ``Ez`` uses the axis closure; if ``il>0``, ``Ha(il-1,k)`` must be readable.
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - upper radial update index
        - integer index
        - The loop ends at ``i=iu`` and requires ``iu <= ihi_f``.
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - lower axial update index
        - integer index
        - ``Er`` updates require ``Ha(i,kl-1)``.
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - upper axial update index
        - integer index
        - The loop ends at ``k=ku`` and requires ``ku <= khi_f``.
      * - ``Ha``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - azimuthal magnetic field ``Hphi``
        - magnetic field in caller normalization
        - Used in the axial difference for ``Er`` and the conservative radial update for ``Ez``.
      * - ``Er``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - radial electric-field component
        - electric field in caller normalization
        - Updated in place over ``il:iu, kl:ku``.
      * - ``Ez``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - axial electric-field component
        - electric field in caller normalization
        - Interior points read ``Ha(i-1,k)``; ``i=0`` uses the ``4*Ha(0,k)/dr`` axis closure.
      * - ``dt``
        - ``in``
        - ``real scalar``
        - time step
        - time step in caller units
        - Used only through ``dt/ep``; no global time step is read.
      * - ``dr``
        - ``in``
        - ``real scalar``
        - radial grid spacing
        - length in caller units
        - Used in the ``Ez`` radial metric term and axis closure; must be positive.
      * - ``dz``
        - ``in``
        - ``real scalar``
        - axial grid spacing
        - length in caller units
        - Denominator for the ``Er`` axial difference; must be positive.
      * - ``ep``
        - ``in``
        - ``real scalar``
        - permittivity or equivalent normalized coefficient
        - permittivity in caller normalization
        - Scalar value shared by the whole update range; must be nonzero.

   .. rubric:: Local Assumptions / Preconditions

   - The grid is a 2D axisymmetric ``r-z`` Yee-staggered layout; the first dimension is radial and the second is axial.
   - ``Ha`` should be the leapfrog-compatible half-step magnetic field; ``Er`` and ``Ez`` are updated in place as integer-step electric fields.
   - ``Er`` updates require ``Ha(i,k-1)``; interior ``Ez`` updates require ``Ha(i-1,k)``. These values may come from physical boundary conditions, symmetry fill, or MPI ghost cells.
   - ``i=0`` is interpreted as the physical radial axis and uses a dedicated ``Ez`` closure. If an MPI-local index 0 is not the physical axis, do not pass it as the physical ``i=0`` point.
   - MPI exchange, external boundary conditions, sources, and current deposition are outside this routine.

   .. rubric:: Implementation Notes

   The first loop updates ``Er``:

   .. math::

      E_{r,i,k}^{n+1}
      =
      E_{r,i,k}^{n}
      -\frac{\Delta t}{\epsilon}
      \frac{H_{\phi,i,k}^{n+1/2}-H_{\phi,i,k-1}^{n+1/2}}{\Delta z}.

   The second loop updates ``Ez``. For ``i>0``:

   .. math::

      E_{z,i,k}^{n+1}
      =
      E_{z,i,k}^{n}
      +\frac{\Delta t}{\epsilon\,i\Delta r}
      \left[
      \left(i+\frac{1}{2}\right)H_{\phi,i,k}^{n+1/2}
      -
      \left(i-\frac{1}{2}\right)H_{\phi,i-1,k}^{n+1/2}
      \right].

   On axis:

   .. math::

      E_{z,0,k}^{n+1}
      =
      E_{z,0,k}^{n}
      +\frac{4\Delta t}{\epsilon\Delta r}H_{\phi,0,k}^{n+1/2}.

   .. rubric:: Calling Notes

   - If ``kl`` is a physical or local boundary, prepare ``Ha(:,kl-1)`` before the call or start the ``Er`` update range at a valid interior row.
   - If ``il>0``, prepare ``Ha(il-1,:)`` before the call; if ``il=0``, the axis point uses a dedicated closure but ``i=1`` still reads ``Ha(0,:)``.
   - This routine uses scalar ``ep`` and does not support different permittivity values per grid point within one call.

   .. rubric:: Generated API

   .. doxygenfile:: sub_E01_fdtd_2d_rz_tmz_E.f90
