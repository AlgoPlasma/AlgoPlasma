sub_E01_fdtd_2d_rz_tez_E.f90
----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在 E01 的 TEz 分量组中，用半步磁场 ``Hr`` 和 ``Hz`` 更新方位角电场
   ``Ephi``。该例程对应柱坐标旋度中的
   :math:`\partial_z H_r-\partial_r H_z` 项；当径向指标 ``i=0`` 时，代码直接施加轴线闭合
   ``Ephi(0,k)=0``。

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
        - 用于声明 ``Ephi``、``Hr``、``Hz`` 的第一维范围。若更新普通内点，需保证 ``Hz(i-1,k)`` 可读；若 ``i=0``，代码走轴线分支，不读取 ``i-1``。
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - ``r`` 方向数组声明上界
        - 整数下标
        - 必须覆盖更新上界 ``iu``。本例程不读取 ``i+1``。
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明下界
        - 整数下标
        - 普通内点更新会读取 ``Hr(i,k-1)``，因此通常需满足 ``klo_f <= kl-1``，除非更新区间只包含轴线点。
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明上界
        - 整数下标
        - 必须覆盖更新上界 ``ku``。本例程不读取 ``k+1``。
      * - ``il``
        - ``in``
        - ``integer scalar``
        - 径向更新下界
        - 整数下标
        - 循环从 ``i=il`` 开始。若 ``il=0``，``Ephi(0,k)`` 被置零；若 ``il>0``，需要 ``Hz(il-1,k)`` 已存在。
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
        - 循环从 ``k=kl`` 开始。普通内点会读取 ``Hr(i,kl-1)``。
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - 轴向更新上界
        - 整数下标
        - 循环到 ``k=ku`` 结束，必须满足 ``ku <= khi_f``。
      * - ``Ephi``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 方位角电场分量
        - 调用者归一化下的电场值
        - 普通内点执行原位累加更新；``i=0`` 处不累加，而是强制设为 ``0.0``。
      * - ``Hr``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 径向磁场分量
        - 调用者归一化下的磁场值
        - 用于轴向差分 ``(Hr(i,k)-Hr(i,k-1))/dz``；普通内点需要 ``k-1`` 相邻/ghost cell 已填好。
      * - ``Hz``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 轴向磁场分量
        - 调用者归一化下的磁场值
        - 用于径向差分 ``(Hz(i,k)-Hz(i-1,k))/dr``；普通内点需要 ``i-1`` 相邻/ghost cell 已填好。
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
        - 用作 ``Hz`` 径向差分分母，需为正数。
      * - ``dz``
        - ``in``
        - ``real scalar``
        - z 方向网格间距
        - 调用者单位的长度
        - 用作 ``Hr`` 轴向差分分母，需为正数。
      * - ``ep``
        - ``in``
        - ``real scalar``
        - 介电常数或等效归一化系数
        - 调用者归一化下的介电常数
        - 标量参数，整个更新区间共用同一个值；需非零。

   .. rubric:: 局部假设 / 前置条件

   - 网格是二维轴对称 ``r-z`` Yee staggered 布局；第一维是径向 ``r``，第二维是轴向 ``z``。
   - 所有步长、介质参数和数组边界都由调用者传入；本例程不假设全局 ``dx=1``、``dt=1`` 或固定 real kind。
   - 本例程只更新指定的局部范围；不做 MPI exchange、外边界条件、源项注入或粒子电流沉积。
   - ``Hr`` 和 ``Hz`` 应来自与 leapfrog 对应的半步磁场时间层；``Ephi`` 是被原位更新的整数步电场。
   - 普通内点需要可读的 ``Hr(i,k-1)`` 和 ``Hz(i-1,k)``。这些值可以来自物理边界条件、周期/对称填充或 MPI ghost cell。
   - ``i=0`` 被代码解释为物理径向轴线，并强制 ``Ephi=0``。若某个 MPI 子域的本地下标 0 不是物理轴线，不应把它传入本例程作为 ``i=0``。

   .. rubric:: 实现逻辑

   对 ``k=kl:ku``、``i=il:iu`` 循环：

   - 若 ``i==0``，执行轴线闭合 ``Ephi(0,k)=0.0``。
   - 若 ``i>0``，先计算
     ``term_z = (Hr(i,k)-Hr(i,k-1))/dz`` 和
     ``term_r = (Hz(i,k)-Hz(i-1,k))/dr``。
   - 然后执行
     ``Ephi(i,k) = Ephi(i,k) + dt/ep*(term_z-term_r)``。

   对应的离散公式为：

   .. math::

      E_{\phi,i,k}^{n+1}
      =
      E_{\phi,i,k}^{n}
      +\frac{\Delta t}{\epsilon}
      \left[
      \frac{H_{r,i,k}^{n+1/2}-H_{r,i,k-1}^{n+1/2}}{\Delta z}
      -
      \frac{H_{z,i,k}^{n+1/2}-H_{z,i-1,k}^{n+1/2}}{\Delta r}
      \right],
      \quad i>0.

   轴线上使用：

   .. math::

      E_{\phi,0,k}^{n+1}=0.

   .. rubric:: 调用注意

   - 调用者负责维持 Yee leapfrog 时间层关系；本例程只完成一次局部场更新。
   - 若 ``kl`` 是物理或局部边界，调用前必须先准备 ``Hr(:,kl-1)``，或者把更新范围从可用内点开始。
   - 若 ``il>0``，调用前必须先准备 ``Hz(il-1,:)``；若 ``il=0``，轴线点会被置零，但 ``i=1`` 仍会读取 ``Hz(0,:)``。
   - 该 routine 使用标量 ``ep``，不支持在一次调用内给不同网格点使用不同介电常数。


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   In the E01 TEz component group, updates the azimuthal electric field
   ``Ephi`` from half-step magnetic fields ``Hr`` and ``Hz``. The kernel applies
   the cylindrical curl term :math:`\partial_z H_r-\partial_r H_z`; at radial
   index ``i=0`` it enforces the axis closure ``Ephi(0,k)=0``.

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
        - Declares the first dimension of ``Ephi``, ``Hr``, and ``Hz``. Interior updates need ``Hz(i-1,k)`` readable; the ``i=0`` axis branch does not read ``i-1``.
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - declared upper ``r`` bound of the arrays
        - integer index
        - Must cover the update upper bound ``iu``. The routine does not read ``i+1``.
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - declared lower ``z`` bound of the arrays
        - integer index
        - Interior updates read ``Hr(i,k-1)``, so usually ``klo_f <= kl-1`` unless only axis points are updated.
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - declared upper ``z`` bound of the arrays
        - integer index
        - Must cover the update upper bound ``ku``. The routine does not read ``k+1``.
      * - ``il``
        - ``in``
        - ``integer scalar``
        - lower radial update index
        - integer index
        - The loop starts at ``i=il``. If ``il=0``, ``Ephi(0,k)`` is set to zero; if ``il>0``, ``Hz(il-1,k)`` must exist.
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
        - The loop starts at ``k=kl``. Interior updates read ``Hr(i,kl-1)``.
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - upper axial update index
        - integer index
        - The loop ends at ``k=ku`` and requires ``ku <= khi_f``.
      * - ``Ephi``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - azimuthal electric-field component
        - electric field in caller normalization
        - Updated in place for interior points; at ``i=0`` it is overwritten with ``0.0``.
      * - ``Hr``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - radial magnetic-field component
        - magnetic field in caller normalization
        - Used in the axial difference ``(Hr(i,k)-Hr(i,k-1))/dz``; interior updates require the ``k-1`` neighbor or ghost cell.
      * - ``Hz``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - axial magnetic-field component
        - magnetic field in caller normalization
        - Used in the radial difference ``(Hz(i,k)-Hz(i-1,k))/dr``; interior updates require the ``i-1`` neighbor or ghost cell.
      * - ``dt``
        - ``in``
        - ``real scalar``
        - time step.
        - time step in caller units
        - Used only through the factor ``dt/ep``; no global time step is read.
      * - ``dr``
        - ``in``
        - ``real scalar``
        - radial grid spacing.
        - length in caller units
        - Denominator for the ``Hz`` radial difference; must be positive.
      * - ``dz``
        - ``in``
        - ``real scalar``
        - axial grid spacing.
        - length in caller units
        - Denominator for the ``Hr`` axial difference; must be positive.
      * - ``ep``
        - ``in``
        - ``real scalar``
        - permittivity or equivalent normalized coefficient.
        - permittivity in caller normalization
        - Scalar value shared by the whole update range; must be nonzero.

   .. rubric:: Local Assumptions / Preconditions

   - The grid is a 2D axisymmetric ``r-z`` Yee-staggered layout; the first dimension is radial and the second is axial.
   - All spacings, material parameters, and bounds are passed explicitly; the routine assumes no global ``dx=1``, ``dt=1``, or fixed real kind.
   - Only the requested local range is modified; MPI exchange, external boundary conditions, sources, and current deposition are outside this routine.
   - ``Hr`` and ``Hz`` should be the leapfrog-compatible half-step magnetic fields; ``Ephi`` is updated in place as an integer-step electric field.
   - Interior updates require readable ``Hr(i,k-1)`` and ``Hz(i-1,k)`` values. These may come from physical boundary conditions, periodic/symmetry fill, or MPI ghost cells.
   - ``i=0`` is interpreted as the physical radial axis and forces ``Ephi=0``. If an MPI-local index 0 is not the physical axis, do not pass it as the physical ``i=0`` point.

   .. rubric:: Implementation Notes

   For ``k=kl:ku`` and ``i=il:iu``:

   - if ``i==0``, enforce the axis closure ``Ephi(0,k)=0.0``;
   - if ``i>0``, compute
     ``term_z = (Hr(i,k)-Hr(i,k-1))/dz`` and
     ``term_r = (Hz(i,k)-Hz(i-1,k))/dr``;
   - then apply
     ``Ephi(i,k) = Ephi(i,k) + dt/ep*(term_z-term_r)``.

   The interior update is:

   .. math::

      E_{\phi,i,k}^{n+1}
      =
      E_{\phi,i,k}^{n}
      +\frac{\Delta t}{\epsilon}
      \left[
      \frac{H_{r,i,k}^{n+1/2}-H_{r,i,k-1}^{n+1/2}}{\Delta z}
      -
      \frac{H_{z,i,k}^{n+1/2}-H_{z,i-1,k}^{n+1/2}}{\Delta r}
      \right],
      \quad i>0.

   The axis branch is:

   .. math::

      E_{\phi,0,k}^{n+1}=0.

   .. rubric:: Calling Notes

   - The caller maintains the Yee leapfrog time staggering; this routine performs only one local field update.
   - If ``kl`` is a physical or local boundary, prepare ``Hr(:,kl-1)`` before the call or start the update range at a valid interior row.
   - If ``il>0``, prepare ``Hz(il-1,:)`` before the call; if ``il=0``, the axis point is zeroed, but ``i=1`` still reads ``Hz(0,:)``.
   - This routine uses scalar ``ep`` and does not support different permittivity values per grid point within one call.

   .. rubric:: Generated API

   .. doxygenfile:: sub_E01_fdtd_2d_rz_tez_E.f90
