sub_E01_cpml_2d_rz_tmz_E.f90
----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在 E01 的 TMz 分量组中，对径向电场 ``Er`` 和轴向电场 ``Ez`` 执行带
   Convolutional Perfectly Matched Layer (CPML) 修正的更新。它使用半步方位角磁场
   ``Ha``/``Hphi``：``Er`` 的更新对 :math:`\partial_z H_\phi` 加入 ``psi_er_z``，
   ``Ez`` 的更新对柱坐标径向项加入 ``psi_ez_r``。

   注意：普通 FDTD ``tm_E`` routine 对 ``i=0`` 有 ``Ez`` 轴线闭合分支；这个 CPML routine
   没有该分支。源码中的 ``Ez`` 更新会读取 ``Ha(i-1,k)``，并除以 ``real(i)*dr``，因此调用者通常应令
   ``il > 0``，不要把物理轴线点传入此 routine。

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
        - 声明 ``Ha``、``Er``、``Ez``、``psi_*`` 和径向 CPML 系数的第一维范围；``Ez`` 更新会读 ``i-1``。
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - ``r`` 方向数组声明上界
        - 整数下标
        - 必须覆盖 ``iu``；径向系数 ``aer/ber/ker`` 也要覆盖 ``il:iu``。
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明下界
        - 整数下标
        - 更新会读 ``Ha(i,k-1)``，通常需要 ``klo_f <= kl-1``。
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明上界
        - 整数下标
        - 必须覆盖 ``ku``；轴向系数 ``aez/bez/kez`` 也要覆盖 ``kl:ku``。
      * - ``il``
        - ``in``
        - ``integer scalar``
        - 径向更新下界
        - 整数下标
        - 循环从 ``i=il`` 开始；``Ez`` 更新需要 ``Ha(il-1,k)``，且源码分母含 ``real(i)*dr``，通常要求 ``il > 0``。
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - 径向更新上界
        - 整数下标
        - 循环到 ``i=iu`` 结束；``Er``、``Ez`` 和 memory variables 在该范围内原位更新。
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - 轴向更新下界
        - 整数下标
        - 循环从 ``k=kl`` 开始；``Er`` 更新需要 ``Ha(i,kl-1)`` 可读。
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - 轴向更新上界
        - 整数下标
        - 循环到 ``k=ku`` 结束。
      * - ``Ha``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 方位角磁场 ``Hphi``
        - 调用者归一化下的磁场值
        - ``Er`` 更新读 ``Ha(i,k)`` 和 ``Ha(i,k-1)``；``Ez`` 更新读 ``Ha(i,k)`` 和 ``Ha(i-1,k)``。
      * - ``Er``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 径向电场分量
        - 调用者归一化下的电场值
        - 在 ``il:iu, kl:ku`` 内原位累加 CPML 修正后的轴向 curl 项。
      * - ``Ez``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 轴向电场分量
        - 调用者归一化下的电场值
        - 在 ``il:iu, kl:ku`` 内原位累加 CPML 修正后的径向柱坐标项；源码不处理 ``i=0``。
      * - ``dt``
        - ``in``
        - ``real scalar``
        - 时间步长
        - 调用者单位
        - 只通过 ``dt/ep`` 进入本次更新。
      * - ``dr``
        - ``in``
        - ``real scalar``
        - 径向网格间距
        - 调用者单位
        - ``Ez`` 径向项的分母之一；需为正数。
      * - ``dz``
        - ``in``
        - ``real scalar``
        - 轴向网格间距
        - 调用者单位
        - ``Er`` 轴向项的分母；需为正数。
      * - ``ep``
        - ``in``
        - ``real scalar``
        - 介电常数或等效归一化系数
        - 调用者归一化
        - 标量参数，整个更新区域共用；需非零。
      * - ``aer``, ``ber``, ``ker``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - ``Ez`` 径向 CPML 系数
        - CPML 系数
        - 在 ``i=il:iu`` 读取；``ker(i)`` 需非零。
      * - ``aez``, ``bez``, ``kez``
        - ``in``
        - ``real(klo_f:khi_f)``
        - ``Er`` 轴向 CPML 系数
        - CPML 系数
        - 在 ``k=kl:ku`` 读取；``kez(k)`` 需非零。
      * - ``psi_ez_r``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - ``Ez`` 径向项的 CPML memory variable
        - 与场量一致的归一化
        - 在 ``il:iu, kl:ku`` 内按 ``b*psi+a*term_r`` 原位更新，必须跨时间步保存。
      * - ``psi_er_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - ``Er`` 轴向项的 CPML memory variable
        - 与场量一致的归一化
        - 在 ``il:iu, kl:ku`` 内按 ``b*psi+a*term_z`` 原位更新，必须跨时间步保存。

   .. rubric:: 局部假设 / 前置条件

   - 网格是二维轴对称 ``r-z`` Yee staggered 布局；第一维是径向 ``r``，第二维是轴向 ``z``。
   - CPML 系数数组已经初始化；``psi_ez_r`` 和 ``psi_er_z`` 必须跨时间步保存。
   - ``Ha`` 应来自与 leapfrog 对应的半步磁场时间层；``Er`` 和 ``Ez`` 是被原位更新的整步电场。
   - 本 routine 不执行 MPI exchange、外边界填充、源项注入或 FDTD ``Ez`` 的轴线特殊闭合。
   - ``Ez`` 径向更新要求 ``i`` 非零，并要求 ``Ha(i-1,k)`` 可读；``Er`` 轴向更新要求 ``Ha(i,k-1)`` 可读。

   .. rubric:: 实现逻辑

   第一个循环更新 ``Er``：

   .. math::

      d_zH_\phi = \frac{H_{\phi,i,k}-H_{\phi,i,k-1}}{\Delta z},
      \qquad
      \psi_{er,z} \leftarrow b_{ez}\psi_{er,z}+a_{ez}d_zH_\phi,

   .. math::

      E_{r,i,k}
      \leftarrow
      E_{r,i,k}
      -
      \frac{\Delta t}{\epsilon}
      \left(
      \frac{d_zH_\phi}{k_{ez}}+\psi_{er,z}
      \right).

   第二个循环更新 ``Ez``，使用源码中的柱坐标径向离散：

   .. math::

      d_rH_\phi =
      \frac{(i+1/2)H_{\phi,i,k}-(i-1/2)H_{\phi,i-1,k}}
      {i\Delta r},
      \qquad i>0.

   然后执行：

   .. math::

      \psi_{ez,r} \leftarrow b_{er}\psi_{ez,r}+a_{er}d_rH_\phi,
      \qquad
      E_{z,i,k}
      \leftarrow
      E_{z,i,k}
      +\frac{\Delta t}{\epsilon}
      \left(
      \frac{d_rH_\phi}{k_{er}}+\psi_{ez,r}
      \right).

   .. rubric:: 调用注意

   - 不要把 ``i=0`` 物理轴线点交给本 routine 的 ``Ez`` 更新；普通 FDTD routine 中的 ``4*dt/(ep*dr)*Ha`` 轴线分支在这里不存在。
   - 若 ``kl`` 是物理或局部边界，调用前必须准备 ``Ha(:,kl-1)``，或把 ``Er`` 更新范围从可用内点开始。
   - 若 ``il`` 靠近径向边界，调用前必须准备 ``Ha(il-1,:)``，并确认 ``il`` 非零。
   - CPML 系数 ``ker`` 和 ``kez`` 在更新区内不应为零。


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   In the E01 TMz component group, updates the radial electric field
   ``Er`` and axial electric field ``Ez`` with Convolutional Perfectly Matched
   Layer (CPML) corrections. The routine uses the half-step azimuthal magnetic
   field ``Ha``/``Hphi``; the ``Er`` update corrects
   :math:`\partial_z H_\phi` through ``psi_er_z``, and the ``Ez`` update
   corrects the cylindrical radial term through ``psi_ez_r``.

   Unlike the plain FDTD ``tm_E`` routine, this CPML routine has no ``i=0``
   axis branch for ``Ez``. The source reads ``Ha(i-1,k)`` and divides by
   ``real(i)*dr``, so callers should normally use ``il > 0``.

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
        - Declares the first dimension of fields, memory variables, and radial CPML coefficients; the ``Ez`` update reads ``i-1``.
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - declared upper ``r`` bound
        - integer index
        - Must cover ``iu``; radial coefficient arrays must cover ``il:iu``.
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - declared lower ``z`` bound
        - integer index
        - The update reads ``Ha(i,k-1)``, so usually ``klo_f <= kl-1``.
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - declared upper ``z`` bound
        - integer index
        - Must cover ``ku``; axial coefficient arrays must cover ``kl:ku``.
      * - ``il``
        - ``in``
        - ``integer scalar``
        - lower radial update index
        - integer index
        - The loop starts at ``i=il``; the ``Ez`` update requires ``Ha(il-1,k)`` and usually ``il > 0``.
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - upper radial update index
        - integer index
        - The loop ends at ``i=iu``; ``Er``, ``Ez``, and memory variables are updated in place.
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - lower axial update index
        - integer index
        - The loop starts at ``k=kl`` and the ``Er`` update requires ``Ha(i,kl-1)``.
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - upper axial update index
        - integer index
        - The loop ends at ``k=ku``.
      * - ``Ha``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - azimuthal magnetic field ``Hphi``
        - magnetic field in caller normalization
        - ``Er`` reads ``Ha(i,k)`` and ``Ha(i,k-1)``; ``Ez`` reads ``Ha(i,k)`` and ``Ha(i-1,k)``.
      * - ``Er``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - radial electric-field component
        - electric field in caller normalization
        - Updated in place with the CPML-corrected axial curl term.
      * - ``Ez``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - axial electric-field component
        - electric field in caller normalization
        - Updated in place with the CPML-corrected radial cylindrical term; no ``i=0`` component is present.
      * - ``dt``
        - ``in``
        - ``real scalar``
        - time step
        - caller units
        - Used only through ``dt/ep``.
      * - ``dr``
        - ``in``
        - ``real scalar``
        - radial spacing
        - caller units
        - Appears in the ``Ez`` radial denominator; must be positive.
      * - ``dz``
        - ``in``
        - ``real scalar``
        - axial spacing
        - caller units
        - Denominator of the ``Er`` axial term; must be positive.
      * - ``ep``
        - ``in``
        - ``real scalar``
        - permittivity or equivalent normalized coefficient
        - caller normalization
        - Scalar shared by the update range; must be nonzero.
      * - ``aer``, ``ber``, ``ker``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - radial CPML coefficients for ``Ez``
        - CPML coefficients
        - Read at ``i=il:iu``; ``ker(i)`` must be nonzero.
      * - ``aez``, ``bez``, ``kez``
        - ``in``
        - ``real(klo_f:khi_f)``
        - axial CPML coefficients for ``Er``
        - CPML coefficients
        - Read at ``k=kl:ku``; ``kez(k)`` must be nonzero.
      * - ``psi_ez_r``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - radial CPML memory variable for ``Ez``
        - same normalization as fields
        - Updated as ``b*psi+a*term_r`` and must persist across time steps.
      * - ``psi_er_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - axial CPML memory variable for ``Er``
        - same normalization as fields
        - Updated as ``b*psi+a*term_z`` and must persist across time steps.

   .. rubric:: Local Assumptions / Preconditions

   - The grid is a 2D axisymmetric ``r-z`` Yee-staggered layout; the first dimension is radial and the second is axial.
   - CPML coefficients have already been initialized; ``psi_ez_r`` and ``psi_er_z`` persist across time steps.
   - ``Ha`` should be the leapfrog-compatible half-step magnetic field; ``Er`` and ``Ez`` are updated in place as integer-step electric fields.
   - This routine performs no MPI exchange, boundary fill, source injection, or FDTD ``Ez`` axis closure.
   - The ``Ez`` update requires nonzero ``i`` and readable ``Ha(i-1,k)``; the ``Er`` update requires readable ``Ha(i,k-1)``.

   .. rubric:: Implementation Notes

   The first loop updates ``Er``:

   .. math::

      d_zH_\phi = \frac{H_{\phi,i,k}-H_{\phi,i,k-1}}{\Delta z},
      \qquad
      E_{r,i,k}
      \leftarrow
      E_{r,i,k}
      -
      \frac{\Delta t}{\epsilon}
      \left(
      \frac{d_zH_\phi}{k_{ez}}+\psi_{er,z}
      \right),

   with ``psi_er_z = bez*psi_er_z + aez*d_zHphi``.

   The second loop updates ``Ez`` using:

   .. math::

      d_rH_\phi =
      \frac{(i+1/2)H_{\phi,i,k}-(i-1/2)H_{\phi,i-1,k}}
      {i\Delta r},
      \qquad i>0,

   with ``psi_ez_r = ber*psi_ez_r + aer*d_rHphi`` and
   ``Ez = Ez + dt/ep*(d_rHphi/ker + psi_ez_r)``.

   .. rubric:: Calling Notes

   - Do not pass the physical ``i=0`` axis point to the ``Ez`` update in this CPML routine; the plain FDTD axis branch is not present here.
   - If ``kl`` is a physical or local boundary, prepare ``Ha(:,kl-1)`` before the call or start the ``Er`` update range at a valid interior row.
   - If ``il`` is near a radial boundary, prepare ``Ha(il-1,:)`` and ensure ``il`` is nonzero.
   - ``ker`` and ``kez`` must not contain zeros on the update range.

   .. rubric:: Generated API

   .. doxygenfile:: sub_E01_cpml_2d_rz_tmz_E.f90
