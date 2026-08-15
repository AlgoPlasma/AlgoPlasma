sub_E01_cpml_2d_rz_tmz_H.f90
----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在 E01 的 TMz 分量组中，对方位角磁场 ``Ha``/``Hphi`` 执行带
   Convolutional Perfectly Matched Layer (CPML) 修正的更新。它使用整步径向电场 ``Er`` 和轴向电场
   ``Ez``，分别对 :math:`\partial_r E_z` 与 :math:`\partial_z E_r` 加入
   ``psi_ha_r``、``psi_ha_z`` memory variable。

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
        - 声明 ``Ha``、``Er``、``Ez``、``psi_ha_*`` 和径向 CPML 系数的第一维范围。
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - ``r`` 方向数组声明上界
        - 整数下标
        - ``Ha`` 至少覆盖 ``iu``；``Ez`` 必须能读到 ``iu+1``。
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
        - ``Ha`` 至少覆盖 ``ku``；``Er`` 必须能读到 ``ku+1``。
      * - ``il``
        - ``in``
        - ``integer scalar``
        - 径向更新下界
        - 整数下标
        - 循环从 ``i=il`` 开始；会读取 ``Ez(i+1,k)``。
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
        - 循环从 ``k=kl`` 开始；会读取 ``Er(i,k+1)``。
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - 轴向更新上界
        - 整数下标
        - 循环到 ``k=ku`` 结束；需要 ``Er(i,ku+1)`` 可读。
      * - ``Ha``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 方位角磁场 ``Hphi``
        - 调用者归一化下的磁场值
        - 在 ``il:iu, kl:ku`` 内原位累加 CPML 修正后的 curl 更新。
      * - ``Er``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 径向电场分量
        - 调用者归一化下的电场值
        - 用于 ``term_z=(Er(i,k+1)-Er(i,k))/dz``；需要 ``k+1`` 相邻/ghost cell。
      * - ``Ez``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 轴向电场分量
        - 调用者归一化下的电场值
        - 用于 ``term_r=(Ez(i+1,k)-Ez(i,k))/dr``；需要 ``i+1`` 相邻/ghost cell。
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
        - ``term_r`` 的分母；需为正数。
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
      * - ``ahr``, ``bhr``, ``khr``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - ``Ha`` 径向 CPML 系数
        - CPML 系数
        - 在 ``i=il:iu`` 读取；``khr(i)`` 需非零。
      * - ``ahz``, ``bhz``, ``khz``
        - ``in``
        - ``real(klo_f:khi_f)``
        - ``Ha`` 轴向 CPML 系数
        - CPML 系数
        - 在 ``k=kl:ku`` 读取；``khz(k)`` 需非零。
      * - ``psi_ha_r``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - ``Ha`` 径向导数的 CPML memory variable
        - 与场量一致的归一化
        - 在 ``il:iu, kl:ku`` 内按 ``b*psi+a*term_r`` 原位更新，必须跨时间步保存。
      * - ``psi_ha_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - ``Ha`` 轴向导数的 CPML memory variable
        - 与场量一致的归一化
        - 在 ``il:iu, kl:ku`` 内按 ``b*psi+a*term_z`` 原位更新，必须跨时间步保存。

   .. rubric:: 局部假设 / 前置条件

   - 网格是二维轴对称 ``r-z`` Yee staggered 布局；第一维是径向 ``r``，第二维是轴向 ``z``。
   - CPML 系数数组已经初始化；``psi_ha_r`` 和 ``psi_ha_z`` 必须跨时间步保存。
   - ``Er`` 和 ``Ez`` 应来自与 leapfrog 对应的整步电场时间层；``Ha`` 是被原位更新的半步磁场。
   - 本 routine 不执行 MPI exchange、外边界条件、源项注入或更新区选择。
   - 更新区必须保证 ``Ez(i+1,k)`` 和 ``Er(i,k+1)`` 可读；这些值可以来自边界条件、对称填充或 MPI ghost cell。

   .. rubric:: 实现逻辑

   对 ``k=kl:ku``、``i=il:iu`` 循环，先计算两个方向导数：

   .. math::

      d_rE_z = \frac{E_{z,i+1,k}-E_{z,i,k}}{\Delta r},
      \qquad
      d_zE_r = \frac{E_{r,i,k+1}-E_{r,i,k}}{\Delta z}.

   CPML memory variables 更新为：

   .. math::

      \psi_{ha,r} \leftarrow b_{hr}\psi_{ha,r}+a_{hr}d_rE_z,
      \qquad
      \psi_{ha,z} \leftarrow b_{hz}\psi_{ha,z}+a_{hz}d_zE_r.

   然后执行：

   .. math::

      H_{\phi,i,k}
      \leftarrow
      H_{\phi,i,k}
      +\frac{\Delta t}{\mu}
      \left[
      \frac{d_rE_z}{k_{hr}}
      -
      \frac{d_zE_r}{k_{hz}}
      +\psi_{ha,r}
      -\psi_{ha,z}
      \right].

   .. rubric:: 调用注意

   - 若 ``iu`` 是物理或局部边界，调用前必须准备 ``Ez(iu+1,:)``，或把更新范围从可用内点结束。
   - 若 ``ku`` 是物理或局部边界，调用前必须准备 ``Er(:,ku+1)``，或把更新范围从可用内点结束。
   - 该 routine 不对 ``i=0`` 做特殊处理；若更新区包含轴线附近单元，调用者需要保证传入的 ``Er/Ez`` 与局部离散约定一致。
   - CPML 系数 ``khr`` 和 ``khz`` 在更新区内不应为零。


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   In the E01 TMz component group, updates the azimuthal magnetic field
   ``Ha``/``Hphi`` with Convolutional Perfectly Matched Layer (CPML)
   corrections. The routine uses integer-step radial and axial electric fields
   ``Er`` and ``Ez``; :math:`\partial_r E_z` and :math:`\partial_z E_r` receive
   the memory variables ``psi_ha_r`` and ``psi_ha_z``.

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
        - ``Ha`` must cover ``iu``; ``Ez`` must be readable at ``iu+1``.
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
        - ``Ha`` must cover ``ku``; ``Er`` must be readable at ``ku+1``.
      * - ``il``
        - ``in``
        - ``integer scalar``
        - lower radial update index
        - integer index
        - The loop starts at ``i=il`` and reads ``Ez(i+1,k)``.
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - upper radial update index
        - integer index
        - The loop ends at ``i=iu`` and requires ``Ez(iu+1,k)`` readable.
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - lower axial update index
        - integer index
        - The loop starts at ``k=kl`` and reads ``Er(i,k+1)``.
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - upper axial update index
        - integer index
        - The loop ends at ``k=ku`` and requires ``Er(i,ku+1)`` readable.
      * - ``Ha``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - azimuthal magnetic field ``Hphi``
        - magnetic field in caller normalization
        - Updated in place with the CPML-corrected curl over ``il:iu, kl:ku``.
      * - ``Er``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - radial electric-field component
        - electric field in caller normalization
        - Used in ``term_z=(Er(i,k+1)-Er(i,k))/dz``; needs the ``k+1`` neighbor or ghost cell.
      * - ``Ez``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - axial electric-field component
        - electric field in caller normalization
        - Used in ``term_r=(Ez(i+1,k)-Ez(i,k))/dr``; needs the ``i+1`` neighbor or ghost cell.
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
        - Denominator of ``term_r``; must be positive.
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
      * - ``ahr``, ``bhr``, ``khr``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - radial CPML coefficients for ``Ha``
        - CPML coefficients
        - Read at ``i=il:iu``; ``khr(i)`` must be nonzero.
      * - ``ahz``, ``bhz``, ``khz``
        - ``in``
        - ``real(klo_f:khi_f)``
        - axial CPML coefficients for ``Ha``
        - CPML coefficients
        - Read at ``k=kl:ku``; ``khz(k)`` must be nonzero.
      * - ``psi_ha_r``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - radial-derivative CPML memory variable for ``Ha``
        - same normalization as fields
        - Updated as ``b*psi+a*term_r`` and must persist across time steps.
      * - ``psi_ha_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - axial-derivative CPML memory variable for ``Ha``
        - same normalization as fields
        - Updated as ``b*psi+a*term_z`` and must persist across time steps.

   .. rubric:: Local Assumptions / Preconditions

   - The grid is a 2D axisymmetric ``r-z`` Yee-staggered layout; the first dimension is radial and the second is axial.
   - CPML coefficients have already been initialized; ``psi_ha_r`` and ``psi_ha_z`` persist across time steps.
   - ``Er`` and ``Ez`` should be leapfrog-compatible integer-step electric fields; ``Ha`` is updated in place as a half-step magnetic field.
   - This routine performs no MPI exchange, external boundary condition, source injection, or update-region selection.
   - The update range must make ``Ez(i+1,k)`` and ``Er(i,k+1)`` readable.

   .. rubric:: Implementation Notes

   For each ``i,k`` point:

   .. math::

      d_rE_z = \frac{E_{z,i+1,k}-E_{z,i,k}}{\Delta r},
      \qquad
      d_zE_r = \frac{E_{r,i,k+1}-E_{r,i,k}}{\Delta z}.

   The memory variables are advanced as:

   .. math::

      \psi_{ha,r} \leftarrow b_{hr}\psi_{ha,r}+a_{hr}d_rE_z,
      \qquad
      \psi_{ha,z} \leftarrow b_{hz}\psi_{ha,z}+a_{hz}d_zE_r.

   Then:

   .. math::

      H_{\phi,i,k}
      \leftarrow
      H_{\phi,i,k}
      +\frac{\Delta t}{\mu}
      \left[
      \frac{d_rE_z}{k_{hr}}
      -
      \frac{d_zE_r}{k_{hz}}
      +\psi_{ha,r}
      -\psi_{ha,z}
      \right].

   .. rubric:: Calling Notes

   - If ``iu`` is a physical or local boundary, prepare ``Ez(iu+1,:)`` before the call or end the update range at a valid interior column.
   - If ``ku`` is a physical or local boundary, prepare ``Er(:,ku+1)`` before the call or end the update range at a valid interior row.
   - This routine has no special ``i=0`` axis branch; callers that include axis-near cells must ensure ``Er/Ez`` follow the intended local discretization.
   - ``khr`` and ``khz`` must not contain zeros on the update range.

   .. rubric:: Generated API

   .. doxygenfile:: sub_E01_cpml_2d_rz_tmz_H.f90
