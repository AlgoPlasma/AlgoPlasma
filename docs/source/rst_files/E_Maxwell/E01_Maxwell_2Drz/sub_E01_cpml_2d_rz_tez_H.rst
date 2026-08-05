sub_E01_cpml_2d_rz_tez_H.f90
----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在 E01 的 TEz 分量组中，对径向磁场 ``Hr`` 和轴向磁场 ``Hz`` 执行带
   Convolutional Perfectly Matched Layer (CPML) 修正的更新。它使用整步方位角电场 ``Ephi``：
   ``Hr`` 的更新对 :math:`\partial_z E_\phi` 加入 ``psi_hr_z``，``Hz`` 的更新对
   :math:`\partial_r E_\phi` 加入 ``psi_hz_r``。

   源码把柱坐标 ``Hz`` 更新中的
   :math:`(1/r)\partial_r(rE_\phi)` 写成 ``dEphi_dr + metric_r``。CPML memory variable
   只作用在 ``dEphi_dr`` 上，几何项 ``metric_r`` 保留在 memory variable 外。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 14 10 28 34 22 44

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
        - 声明 ``Ephi``、``Hr``、``Hz``、``psi_*`` 和径向 CPML 系数的第一维范围。
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - ``r`` 方向数组声明上界
        - 整数下标
        - ``Hr``、``Hz`` 至少覆盖 ``iu``；``Ephi`` 必须能读到 ``iu+1``。
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明下界
        - 整数下标
        - 必须覆盖 ``kl``；本 routine 不读 ``k-1``。
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明上界
        - 整数下标
        - ``Hr``、``Hz`` 至少覆盖 ``ku``；``Ephi`` 必须能读到 ``ku+1``。
      * - ``il``
        - ``in``
        - ``integer scalar``
        - 径向更新下界
        - 整数下标
        - 循环从 ``i=il`` 开始；``Hz`` 更新会读 ``Ephi(i+1,k)``。
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - 径向更新上界
        - 整数下标
        - 循环到 ``i=iu`` 结束；需要 ``Ephi(iu+1,k)`` 可读。
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - 轴向更新下界
        - 整数下标
        - 循环从 ``k=kl`` 开始；``Hr`` 更新会读 ``Ephi(i,k+1)``。
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - 轴向更新上界
        - 整数下标
        - 循环到 ``k=ku`` 结束；需要 ``Ephi(i,ku+1)`` 可读。
      * - ``Ephi``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 方位角电场分量
        - 调用者归一化下的电场值
        - 用于 ``Hr`` 的轴向差分和 ``Hz`` 的径向差分/几何项。
      * - ``Hr``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 径向磁场分量
        - 调用者归一化下的磁场值
        - 在 ``il:iu, kl:ku`` 内原位累加更新；本 CPML routine 不强制 ``Hr(0,k)=0``。
      * - ``Hz``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 轴向磁场分量
        - 调用者归一化下的磁场值
        - 在 ``il:iu, kl:ku`` 内原位累加更新；径向更新会读 ``Ephi(i+1,k)``。
      * - ``dt``
        - ``in``
        - ``real scalar``
        - 时间步长
        - 调用者单位
        - 只通过 ``dt/mu`` 进入本次更新。
      * - ``dr``
        - ``in``
        - ``real scalar``
        - 径向网格间距
        - 调用者单位
        - 用于 ``dEphi_dr`` 与 ``ri`` 计算；需为正数。
      * - ``dz``
        - ``in``
        - ``real scalar``
        - 轴向网格间距
        - 调用者单位
        - ``term_z`` 的分母；需为正数。
      * - ``mu``
        - ``in``
        - ``real scalar``
        - 磁导率或等效归一化系数
        - 调用者归一化
        - 标量参数，整个更新区域共用；需非零。
      * - ``ahr_z``, ``bhr_z``, ``khr_z``
        - ``in``
        - ``real(klo_f:khi_f)``
        - ``Hr`` 轴向 CPML 系数
        - CPML 系数
        - 在 ``k=kl:ku`` 读取；``khr_z(k)`` 需非零。
      * - ``ahz_r``, ``bhz_r``, ``khz_r``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - ``Hz`` 径向 CPML 系数
        - CPML 系数
        - 在 ``i=il:iu`` 读取；``khz_r(i)`` 需非零。
      * - ``psi_hr_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - ``Hr`` 轴向导数的 CPML memory variable
        - 与场量一致的归一化
        - 在 ``il:iu, kl:ku`` 内按 ``b*psi+a*term_z`` 原位更新，必须跨时间步保存。
      * - ``psi_hz_r``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - ``Hz`` 径向导数的 CPML memory variable
        - 与场量一致的归一化
        - 在 ``il:iu, kl:ku`` 内按 ``b*psi+a*dEphi_dr`` 原位更新，必须跨时间步保存。

   .. rubric:: 局部假设 / 前置条件

   - 网格是二维轴对称 ``r-z`` Yee staggered 布局；第一维是径向 ``r``，第二维是轴向 ``z``。
   - CPML 系数数组已经由调用者初始化；memory variables 必须跨时间步保存。
   - ``Ephi`` 应来自与 leapfrog 对应的整步电场时间层；``Hr`` 和 ``Hz`` 是被原位更新的半步磁场。
   - 本 routine 不执行 MPI exchange、外边界条件、源项注入、普通 FDTD 区域选择或 ``Hr(0,k)=0`` 轴线闭合。
   - 更新区必须保证 ``Ephi(i,k+1)`` 和 ``Ephi(i+1,k)`` 可读；这些值可以来自物理边界、对称填充或 MPI ghost cell。

   .. rubric:: 实现逻辑

   ``Hr`` 更新使用一个 ``i,k`` 循环：

   .. math::

      d_zE_\phi = \frac{E_{\phi,i,k+1}-E_{\phi,i,k}}{\Delta z},
      \qquad
      \psi_{hr,z} \leftarrow b_{hr,z}\psi_{hr,z}+a_{hr,z}d_zE_\phi,

   .. math::

      H_{r,i,k}
      \leftarrow
      H_{r,i,k}
      +\frac{\Delta t}{\mu}
      \left(
      \frac{d_zE_\phi}{k_{hr,z}}+\psi_{hr,z}
      \right).

   ``Hz`` 更新使用第二个 ``i,k`` 循环。源码先计算
   ``ri=max((i+0.5)*dr,0.5*dr)``、``dEphi_dr=(Ephi(i+1,k)-Ephi(i,k))/dr``，
   再把柱坐标几何项写成：

   .. math::

      metric_r = \frac{E_{\phi,i+1,k}+E_{\phi,i,k}}{2r_{i+1/2}}.

   CPML memory variable 只作用在 ``dEphi_dr`` 上：

   .. math::

      \psi_{hz,r} \leftarrow b_{hz,r}\psi_{hz,r}+a_{hz,r}d_rE_\phi,

   .. math::

      H_{z,i,k}
      \leftarrow
      H_{z,i,k}
      -\frac{\Delta t}{\mu}
      \left(
      \frac{d_rE_\phi}{k_{hz,r}}+\psi_{hz,r}+metric_r
      \right).

   .. rubric:: 调用注意

   - 若 ``ku`` 是物理或局部边界，调用前必须准备 ``Ephi(:,ku+1)``，或把 ``Hr`` 更新范围从可用内点结束。
   - 若 ``iu`` 是物理或局部边界，调用前必须准备 ``Ephi(iu+1,:)``，或把 ``Hz`` 更新范围从可用内点结束。
   - 若更新区包含 ``i=0``，本 routine 会按上式更新 ``Hr(0,k)``，不会像普通 FDTD routine 那样把它强制置零；调用者应确认这正是吸收层设计所需。
   - CPML 的 ``khr_z`` 与 ``khz_r`` 系数在更新区内不应为零。


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   In the E01 TEz component group, updates the radial magnetic field
   ``Hr`` and axial magnetic field ``Hz`` with Convolutional Perfectly Matched
   Layer (CPML) corrections. The routine uses the integer-step azimuthal
   electric field ``Ephi``; ``Hr`` receives the ``psi_hr_z`` correction on
   :math:`\partial_z E_\phi`, and ``Hz`` receives the ``psi_hz_r`` correction on
   :math:`\partial_r E_\phi`.

   For the cylindrical ``Hz`` update, the source writes
   :math:`(1/r)\partial_r(rE_\phi)` as ``dEphi_dr + metric_r``. CPML acts only
   on ``dEphi_dr``; the geometry term ``metric_r`` stays outside the memory
   variable.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 14 10 28 34 22 44

      * - Parameter
        - Direction
        - Shape / Range
        - Meaning
        - Units / Normalization
        - Index / ghost-cell requirement
      * - ``ilo_f``
        - ``in``
        - ``integer scalar``
        - declared lower ``r`` bound
        - integer index
        - Declares the first dimension of fields, memory variables, and radial CPML coefficients.
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - declared upper ``r`` bound
        - integer index
        - ``Hr`` and ``Hz`` must cover ``iu``; ``Ephi`` must be readable at ``iu+1``.
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - declared lower ``z`` bound
        - integer index
        - Must cover ``kl``; this routine does not read ``k-1``.
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - declared upper ``z`` bound
        - integer index
        - ``Hr`` and ``Hz`` must cover ``ku``; ``Ephi`` must be readable at ``ku+1``.
      * - ``il``
        - ``in``
        - ``integer scalar``
        - lower radial update index
        - integer index
        - The loop starts at ``i=il``; the ``Hz`` update reads ``Ephi(i+1,k)``.
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - upper radial update index
        - integer index
        - The loop ends at ``i=iu`` and requires ``Ephi(iu+1,k)`` readable.
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - lower axial update index
        - integer index
        - The loop starts at ``k=kl``; the ``Hr`` update reads ``Ephi(i,k+1)``.
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - upper axial update index
        - integer index
        - The loop ends at ``k=ku`` and requires ``Ephi(i,ku+1)`` readable.
      * - ``Ephi``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - azimuthal electric-field component
        - electric field in caller normalization
        - Used by the axial derivative for ``Hr`` and the radial derivative/metric term for ``Hz``.
      * - ``Hr``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - radial magnetic-field component
        - magnetic field in caller normalization
        - Updated in place over ``il:iu, kl:ku``; this CPML routine does not force ``Hr(0,k)=0``.
      * - ``Hz``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - axial magnetic-field component
        - magnetic field in caller normalization
        - Updated in place and reads ``Ephi(i+1,k)``.
      * - ``dt``
        - ``in``
        - ``real scalar``
        - time step
        - caller units
        - Used only through ``dt/mu``.
      * - ``dr``
        - ``in``
        - ``real scalar``
        - radial spacing
        - caller units
        - Used for ``dEphi_dr`` and ``ri``; must be positive.
      * - ``dz``
        - ``in``
        - ``real scalar``
        - axial spacing
        - caller units
        - Denominator of ``term_z``; must be positive.
      * - ``mu``
        - ``in``
        - ``real scalar``
        - permeability or equivalent normalized coefficient
        - caller normalization
        - Scalar shared by the update range; must be nonzero.
      * - ``ahr_z``, ``bhr_z``, ``khr_z``
        - ``in``
        - ``real(klo_f:khi_f)``
        - axial CPML coefficients for ``Hr``
        - CPML coefficients
        - Read at ``k=kl:ku``; ``khr_z(k)`` must be nonzero.
      * - ``ahz_r``, ``bhz_r``, ``khz_r``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - radial CPML coefficients for ``Hz``
        - CPML coefficients
        - Read at ``i=il:iu``; ``khz_r(i)`` must be nonzero.
      * - ``psi_hr_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - axial-derivative CPML memory variable for ``Hr``
        - same normalization as fields
        - Updated as ``b*psi+a*term_z`` and must persist across time steps.
      * - ``psi_hz_r``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - radial-derivative CPML memory variable for ``Hz``
        - same normalization as fields
        - Updated as ``b*psi+a*dEphi_dr`` and must persist across time steps.

   .. rubric:: Local Assumptions / Preconditions

   - The grid is a 2D axisymmetric ``r-z`` Yee-staggered layout; the first dimension is radial and the second is axial.
   - CPML coefficient arrays are initialized by the caller, and memory variables persist across time steps.
   - ``Ephi`` should be the leapfrog-compatible integer-step electric field; ``Hr`` and ``Hz`` are updated in place as half-step magnetic fields.
   - This routine performs no MPI exchange, external boundary condition, source injection, FDTD-region selection, or ``Hr(0,k)=0`` axis closure.
   - The update range must make ``Ephi(i,k+1)`` and ``Ephi(i+1,k)`` readable.

   .. rubric:: Implementation Notes

   The ``Hr`` loop applies:

   .. math::

      d_zE_\phi = \frac{E_{\phi,i,k+1}-E_{\phi,i,k}}{\Delta z},
      \qquad
      \psi_{hr,z} \leftarrow b_{hr,z}\psi_{hr,z}+a_{hr,z}d_zE_\phi,

   .. math::

      H_{r,i,k}
      \leftarrow
      H_{r,i,k}
      +\frac{\Delta t}{\mu}
      \left(
      \frac{d_zE_\phi}{k_{hr,z}}+\psi_{hr,z}
      \right).

   The ``Hz`` loop computes ``ri=max((i+0.5)*dr,0.5*dr)``,
   ``dEphi_dr=(Ephi(i+1,k)-Ephi(i,k))/dr``, and:

   .. math::

      metric_r = \frac{E_{\phi,i+1,k}+E_{\phi,i,k}}{2r_{i+1/2}}.

   Then:

   .. math::

      H_{z,i,k}
      \leftarrow
      H_{z,i,k}
      -\frac{\Delta t}{\mu}
      \left(
      \frac{d_rE_\phi}{k_{hz,r}}+\psi_{hz,r}+metric_r
      \right).

   .. rubric:: Calling Notes

   - If ``ku`` is a physical or local boundary, prepare ``Ephi(:,ku+1)`` before the call or end the ``Hr`` update range at a valid interior row.
   - If ``iu`` is a physical or local boundary, prepare ``Ephi(iu+1,:)`` before the call or end the ``Hz`` update range at a valid interior column.
   - If the update range includes ``i=0``, this routine updates ``Hr(0,k)`` from the formula instead of forcing it to zero; the caller should verify that this is intended for the absorbing-layer setup.
   - ``khr_z`` and ``khz_r`` must not contain zeros on the update range.

   .. rubric:: Generated API

   .. doxygenfile:: sub_E01_cpml_2d_rz_tez_H.f90
