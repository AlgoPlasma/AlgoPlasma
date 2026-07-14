sub_E01_fdtd_2d_rz_tmz_H.f90
----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在 E01 的 TMz 分量组中，用整数步径向电场 ``Er`` 和轴向电场 ``Ez`` 更新方位角磁场
   ``Ha``，即 ``Hphi``。该例程对应柱坐标中的
   :math:`\partial_r E_z-\partial_z E_r` curl 项。

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
        - 用于声明 ``Ha``、``Er``、``Ez`` 的第一维范围。代码会读取 ``Ez(i+1,k)``。
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - ``r`` 方向数组声明上界
        - 整数下标
        - ``Ha`` 至少覆盖 ``iu``；``Ez`` 必须能读到 ``iu+1``，因此通常需要 ``ihi_f >= iu+1``。
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明下界
        - 整数下标
        - 必须覆盖更新下界 ``kl``；本例程不读取 ``k-1``。
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明上界
        - 整数下标
        - ``Ha`` 至少覆盖 ``ku``；``Er`` 必须能读到 ``ku+1``，因此通常需要 ``khi_f >= ku+1``。
      * - ``il``
        - ``in``
        - ``integer scalar``
        - 径向更新下界
        - 整数下标
        - 循环从 ``i=il`` 开始；会读取 ``Ez(il+1,k)``。
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - 径向更新上界
        - 整数下标
        - 循环到 ``i=iu`` 结束；需要 ``Ez(iu+1,k)`` 可读。
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - 轴向更新下界
        - 整数下标
        - 循环从 ``k=kl`` 开始；会读取 ``Er(i,kl+1)``。
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - 轴向更新上界
        - 整数下标
        - 循环到 ``k=ku`` 结束；需要 ``Er(i,ku+1)`` 可读。
      * - ``Ha``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 方位角磁场分量 ``Hphi``
        - 调用者归一化下的磁场值
        - 在 ``il:iu, kl:ku`` 范围内原位累加更新。
      * - ``Er``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 径向电场分量
        - 调用者归一化下的电场值
        - 用于轴向差分 ``Er(i,k+1)-Er(i,k)``；需要 ``k+1`` 相邻/ghost cell。
      * - ``Ez``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 轴向电场分量
        - 调用者归一化下的电场值
        - 用于径向差分 ``Ez(i+1,k)-Ez(i,k)``；需要 ``i+1`` 相邻/ghost cell。
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
        - 用作 ``Ez`` 径向差分分母，需为正数。
      * - ``dz``
        - ``in``
        - ``real scalar``
        - z 方向网格间距
        - 调用者单位的长度
        - 用作 ``Er`` 轴向差分分母，需为正数。
      * - ``mu``
        - ``in``
        - ``real scalar``
        - 磁导率或等效归一化系数
        - 调用者归一化下的磁导率
        - 标量参数，整个更新区间共用同一个值；需非零。

   .. rubric:: 局部假设 / 前置条件

   - 网格是二维轴对称 ``r-z`` Yee staggered 布局；第一维是径向 ``r``，第二维是轴向 ``z``。
   - ``Er`` 和 ``Ez`` 应来自与 leapfrog 对应的整数步电场时间层；``Ha`` 是被原位更新的半步磁场。
   - 更新需要 ``Ez(i+1,k)`` 和 ``Er(i,k+1)``。这些相邻值可以来自物理边界条件、对称填充或 MPI ghost cell。
   - 本例程没有轴线特殊分支；若更新范围包含 ``i=0``，调用方仍需保证 ``Ez(1,k)`` 可读且符合轴线附近离散约定。
   - 本例程不做 MPI exchange、外边界条件、源项注入或粒子电流沉积。

   .. rubric:: 实现逻辑

   单层 ``i,k`` 循环中计算：

   .. math::

      H_{\phi,i,k}^{n+1/2}
      =
      H_{\phi,i,k}^{n-1/2}
      +\frac{\Delta t}{\mu}
      \left[
      \frac{E_{z,i+1,k}^{n}-E_{z,i,k}^{n}}{\Delta r}
      -
      \frac{E_{r,i,k+1}^{n}-E_{r,i,k}^{n}}{\Delta z}
      \right].

   代码中的实现即：

   ``Ha(i,k) = Ha(i,k)+dt/mu*((Ez(i+1,k)-Ez(i,k))/dr - (Er(i,k+1)-Er(i,k))/dz)``。

   .. rubric:: 调用注意

   - 若 ``iu`` 是物理或局部边界，调用前必须先准备 ``Ez(iu+1,:)``，或者把更新范围从可用内点结束。
   - 若 ``ku`` 是物理或局部边界，调用前必须先准备 ``Er(:,ku+1)``，或者把更新范围从可用内点结束。
   - 该 routine 使用标量 ``mu``，不支持在一次调用内给不同网格点使用不同磁导率。


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   In the E01 TMz component group, updates the azimuthal magnetic field
   ``Ha`` (``Hphi``) from integer-step radial electric field ``Er`` and axial
   electric field ``Ez``. The kernel applies the cylindrical
   :math:`\partial_r E_z-\partial_z E_r` curl term.

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
        - Declares the first dimension of ``Ha``, ``Er``, and ``Ez``. The code reads ``Ez(i+1,k)``.
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - declared upper ``r`` bound of the arrays
        - integer index
        - ``Ha`` must cover ``iu``; ``Ez`` must be readable at ``iu+1``, so usually ``ihi_f >= iu+1``.
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - declared lower ``z`` bound of the arrays
        - integer index
        - Must cover ``kl``; the routine does not read ``k-1``.
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - declared upper ``z`` bound of the arrays
        - integer index
        - ``Ha`` must cover ``ku``; ``Er`` must be readable at ``ku+1``, so usually ``khi_f >= ku+1``.
      * - ``il``
        - ``in``
        - ``integer scalar``
        - lower radial update index
        - integer index
        - The loop starts at ``i=il`` and reads ``Ez(il+1,k)``.
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - upper radial update index
        - integer index
        - The loop ends at ``i=iu`` and requires ``Ez(iu+1,k)``.
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - lower axial update index
        - integer index
        - The loop starts at ``k=kl`` and reads ``Er(i,kl+1)``.
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - upper axial update index
        - integer index
        - The loop ends at ``k=ku`` and requires ``Er(i,ku+1)``.
      * - ``Ha``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - azimuthal magnetic field ``Hphi``
        - magnetic field in caller normalization
        - Updated in place over ``il:iu, kl:ku``.
      * - ``Er``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - radial electric-field component
        - electric field in caller normalization
        - Used in the axial difference ``Er(i,k+1)-Er(i,k)``; requires the ``k+1`` neighbor or ghost cell.
      * - ``Ez``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - axial electric-field component
        - electric field in caller normalization
        - Used in the radial difference ``Ez(i+1,k)-Ez(i,k)``; requires the ``i+1`` neighbor or ghost cell.
      * - ``dt``
        - ``in``
        - ``real scalar``
        - time step
        - time step in caller units
        - Used only through ``dt/mu``; no global time step is read.
      * - ``dr``
        - ``in``
        - ``real scalar``
        - radial grid spacing
        - length in caller units
        - Denominator for the ``Ez`` radial difference; must be positive.
      * - ``dz``
        - ``in``
        - ``real scalar``
        - axial grid spacing
        - length in caller units
        - Denominator for the ``Er`` axial difference; must be positive.
      * - ``mu``
        - ``in``
        - ``real scalar``
        - permeability or equivalent normalized coefficient
        - permeability in caller normalization
        - Scalar value shared by the whole update range; must be nonzero.

   .. rubric:: Local Assumptions / Preconditions

   - The grid is a 2D axisymmetric ``r-z`` Yee-staggered layout; the first dimension is radial and the second is axial.
   - ``Er`` and ``Ez`` should be leapfrog-compatible integer-step electric fields; ``Ha`` is updated in place as a half-step magnetic field.
   - The update requires ``Ez(i+1,k)`` and ``Er(i,k+1)``. These values may come from physical boundary conditions, symmetry fill, or MPI ghost cells.
   - There is no special axis branch in this routine; if the update range includes ``i=0``, the caller must still provide ``Ez(1,k)`` consistent with the axis-near discretization.
   - MPI exchange, external boundary conditions, sources, and current deposition are outside this routine.

   .. rubric:: Implementation Notes

   The single ``i,k`` loop applies:

   .. math::

      H_{\phi,i,k}^{n+1/2}
      =
      H_{\phi,i,k}^{n-1/2}
      +\frac{\Delta t}{\mu}
      \left[
      \frac{E_{z,i+1,k}^{n}-E_{z,i,k}^{n}}{\Delta r}
      -
      \frac{E_{r,i,k+1}^{n}-E_{r,i,k}^{n}}{\Delta z}
      \right].

   The code line is:

   ``Ha(i,k) = Ha(i,k)+dt/mu*((Ez(i+1,k)-Ez(i,k))/dr - (Er(i,k+1)-Er(i,k))/dz)``.

   .. rubric:: Calling Notes

   - If ``iu`` is a physical or local boundary, prepare ``Ez(iu+1,:)`` before the call or end the update range at a valid interior column.
   - If ``ku`` is a physical or local boundary, prepare ``Er(:,ku+1)`` before the call or end the update range at a valid interior row.
   - This routine uses scalar ``mu`` and does not support different permeability values per grid point within one call.

   .. rubric:: Generated API

   .. doxygenfile:: sub_E01_fdtd_2d_rz_tmz_H.f90
