sub_E01_cpml_2d_rz_tez_E.f90
----------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在 E01 的 TEz 分量组中，对方位角电场 ``Ephi`` 执行带 Convolutional Perfectly Matched Layer
   (CPML) 修正的更新。它使用半步磁场 ``Hr`` 和 ``Hz``，对
   :math:`\partial_z H_r` 与 :math:`\partial_r H_z` 两个方向导数分别加入
   ``psi_ephi_z``、``psi_ephi_r`` memory variable，并用 ``kephi_z``、``kephi_r`` 缩放导数。

   注意：这个 CPML 版本没有 FDTD ``te_E`` 中的 ``i=0`` 轴线闭合分支。源码会读取
   ``Hz(i-1,k)`` 和 ``Hr(i,k-1)``，因此常规用法是把它用于吸收层局部区域，并由调用者保证相邻点或
   ghost cell 已准备好。

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
        - 声明 ``Ephi``、``Hr``、``Hz``、``psi_ephi_*`` 和径向 CPML 系数的第一维范围；更新会读 ``i-1``。
      * - ``ihi_f``
        - ``in``
        - ``integer scalar``
        - ``r`` 方向数组声明上界
        - 整数下标
        - 必须覆盖 ``iu``；径向系数 ``aephi_r/bephi_r/kephi_r`` 也要覆盖 ``il:iu``。
      * - ``klo_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明下界
        - 整数下标
        - 更新会读 ``Hr(i,k-1)``，通常需要 ``klo_f <= kl-1``。
      * - ``khi_f``
        - ``in``
        - ``integer scalar``
        - ``z`` 方向数组声明上界
        - 整数下标
        - 必须覆盖 ``ku``；轴向系数 ``aephi_z/bephi_z/kephi_z`` 也要覆盖 ``kl:ku``。
      * - ``il``
        - ``in``
        - ``integer scalar``
        - 径向更新下界
        - 整数下标
        - 循环从 ``i=il`` 开始；需要 ``Hz(il-1,k)`` 可读。若 ``il=0``，调用者必须显式提供合法的 ``i=-1`` 存储或避免这样调用。
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - 径向更新上界
        - 整数下标
        - 循环到 ``i=iu`` 结束；``Ephi`` 和 ``psi_ephi_*`` 在 ``il:iu`` 内原位更新。
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - 轴向更新下界
        - 整数下标
        - 循环从 ``k=kl`` 开始；需要 ``Hr(i,kl-1)`` 可读。
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - 轴向更新上界
        - 整数下标
        - 循环到 ``k=ku`` 结束。
      * - ``Ephi``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 方位角电场分量
        - 调用者归一化下的电场值
        - 在 ``il:iu, kl:ku`` 内原位累加 CPML 修正后的 curl 更新。
      * - ``Hr``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 径向磁场分量
        - 调用者归一化下的磁场值
        - 用于 ``term_z=(Hr(i,k)-Hr(i,k-1))/dz``；需要 ``k-1`` 相邻/ghost cell。
      * - ``Hz``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - 轴向磁场分量
        - 调用者归一化下的磁场值
        - 用于 ``term_r=(Hz(i,k)-Hz(i-1,k))/dr``；需要 ``i-1`` 相邻/ghost cell。
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
        - ``term_r`` 的分母；需为正数。
      * - ``dz``
        - ``in``
        - ``real scalar``
        - 轴向网格间距
        - 调用者单位
        - ``term_z`` 的分母；需为正数。
      * - ``ep``
        - ``in``
        - ``real scalar``
        - 介电常数或等效归一化系数
        - 调用者归一化
        - 标量参数，整个更新区域共用；需非零。
      * - ``aephi_r``, ``bephi_r``, ``kephi_r``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - ``Ephi`` 径向 CPML 系数
        - CPML 系数
        - 在 ``i=il:iu`` 读取；``kephi_r(i)`` 需非零。
      * - ``aephi_z``, ``bephi_z``, ``kephi_z``
        - ``in``
        - ``real(klo_f:khi_f)``
        - ``Ephi`` 轴向 CPML 系数
        - CPML 系数
        - 在 ``k=kl:ku`` 读取；``kephi_z(k)`` 需非零。
      * - ``psi_ephi_r``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - ``Ephi`` 径向导数的 CPML memory variable
        - 与场量一致的归一化
        - 在 ``il:iu, kl:ku`` 内按 ``b*psi+a*term_r`` 原位更新，必须跨时间步保存。
      * - ``psi_ephi_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - ``Ephi`` 轴向导数的 CPML memory variable
        - 与场量一致的归一化
        - 在 ``il:iu, kl:ku`` 内按 ``b*psi+a*term_z`` 原位更新，必须跨时间步保存。

   .. rubric:: 局部假设 / 前置条件

   - 网格是二维轴对称 ``r-z`` Yee staggered 布局；第一维是径向 ``r``，第二维是轴向 ``z``。
   - CPML 系数数组已经由上层代码初始化，并且与当前吸收层方向、网格间距和时间步匹配。
   - ``psi_ephi_r`` 与 ``psi_ephi_z`` 是有记忆的历史变量，不能在每个时间步调用前清零，除非正在重新初始化吸收层。
   - 本 routine 不执行 MPI exchange、物理边界填充、轴线闭合、源项注入或普通 FDTD 更新区选择。
   - 更新区必须保证 ``Hz(i-1,k)`` 与 ``Hr(i,k-1)`` 可读；若更新区触及局部边界，应先完成 ghost fill。

   .. rubric:: 实现逻辑

   对 ``k=kl:ku``、``i=il:iu`` 循环，源码逐点执行：

   .. math::

      d_z H_r = \frac{H_{r,i,k}-H_{r,i,k-1}}{\Delta z},
      \qquad
      d_r H_z = \frac{H_{z,i,k}-H_{z,i-1,k}}{\Delta r}.

   两个 CPML memory variable 分别更新为：

   .. math::

      \psi_{\phi,z} \leftarrow b_{\phi,z}\psi_{\phi,z}+a_{\phi,z}d_zH_r,
      \qquad
      \psi_{\phi,r} \leftarrow b_{\phi,r}\psi_{\phi,r}+a_{\phi,r}d_rH_z.

   最后原位更新：

   .. math::

      E_{\phi,i,k}
      \leftarrow
      E_{\phi,i,k}
      +\frac{\Delta t}{\epsilon}
      \left[
      \frac{d_zH_r}{k_{\phi,z}}
      -
      \frac{d_rH_z}{k_{\phi,r}}
      +\psi_{\phi,z}
      -\psi_{\phi,r}
      \right].

   .. rubric:: 调用注意

   - 若需要在物理轴线附近更新 ``Ephi``，应优先使用带轴线分支的 FDTD routine 或在上层明确设计 CPML 轴线处理；本 routine 自身不做 ``Ephi(0,k)=0``。
   - 若 ``kl`` 是物理或局部边界，调用前必须准备 ``Hr(:,kl-1)``，或把更新区从可用内点开始。
   - 若 ``il`` 是物理或局部边界，调用前必须准备 ``Hz(il-1,:)``，或把更新区从可用内点开始。
   - CPML 系数 ``kephi_r`` 和 ``kephi_z`` 不应为零，否则会在对应方向导数缩放处除零。


.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   In the E01 TEz component group, updates the azimuthal electric field
   ``Ephi`` with Convolutional Perfectly Matched Layer (CPML) corrections. The
   routine uses half-step magnetic fields ``Hr`` and ``Hz``; the
   :math:`\partial_z H_r` and :math:`\partial_r H_z` derivatives receive
   separate memory variables ``psi_ephi_z`` and ``psi_ephi_r`` and are scaled by
   ``kephi_z`` and ``kephi_r``.

   Unlike the plain FDTD ``te_E`` routine, this CPML routine has no explicit
   ``i=0`` axis-closure branch. The source reads ``Hz(i-1,k)`` and
   ``Hr(i,k-1)``, so callers must provide the required neighboring or ghost
   cells.

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
        - Declares the first dimension of fields, memory variables, and radial CPML coefficients; the update reads ``i-1``.
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
        - The update reads ``Hr(i,k-1)``, so usually ``klo_f <= kl-1``.
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
        - The loop starts at ``i=il`` and requires ``Hz(il-1,k)`` readable.
      * - ``iu``
        - ``in``
        - ``integer scalar``
        - upper radial update index
        - integer index
        - The loop ends at ``i=iu``; ``Ephi`` and both memory arrays are updated in place over ``il:iu``.
      * - ``kl``
        - ``in``
        - ``integer scalar``
        - lower axial update index
        - integer index
        - The loop starts at ``k=kl`` and requires ``Hr(i,kl-1)`` readable.
      * - ``ku``
        - ``in``
        - ``integer scalar``
        - upper axial update index
        - integer index
        - The loop ends at ``k=ku``.
      * - ``Ephi``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - azimuthal electric-field component
        - electric field in caller normalization
        - Updated in place with the CPML-corrected curl over ``il:iu, kl:ku``.
      * - ``Hr``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - radial magnetic-field component
        - magnetic field in caller normalization
        - Used in ``term_z=(Hr(i,k)-Hr(i,k-1))/dz``; needs the ``k-1`` neighbor or ghost cell.
      * - ``Hz``
        - ``in``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - axial magnetic-field component
        - magnetic field in caller normalization
        - Used in ``term_r=(Hz(i,k)-Hz(i-1,k))/dr``; needs the ``i-1`` neighbor or ghost cell.
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
        - Denominator of ``term_r``; must be positive.
      * - ``dz``
        - ``in``
        - ``real scalar``
        - axial spacing
        - caller units
        - Denominator of ``term_z``; must be positive.
      * - ``ep``
        - ``in``
        - ``real scalar``
        - permittivity or equivalent normalized coefficient
        - caller normalization
        - Scalar shared by the update range; must be nonzero.
      * - ``aephi_r``, ``bephi_r``, ``kephi_r``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - radial CPML coefficients for ``Ephi``
        - CPML coefficients
        - Read at ``i=il:iu``; ``kephi_r(i)`` must be nonzero.
      * - ``aephi_z``, ``bephi_z``, ``kephi_z``
        - ``in``
        - ``real(klo_f:khi_f)``
        - axial CPML coefficients for ``Ephi``
        - CPML coefficients
        - Read at ``k=kl:ku``; ``kephi_z(k)`` must be nonzero.
      * - ``psi_ephi_r``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - radial-derivative CPML memory variable for ``Ephi``
        - same normalization as fields
        - Updated as ``b*psi+a*term_r`` and must persist across time steps.
      * - ``psi_ephi_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,klo_f:khi_f)``
        - axial-derivative CPML memory variable for ``Ephi``
        - same normalization as fields
        - Updated as ``b*psi+a*term_z`` and must persist across time steps.

   .. rubric:: Local Assumptions / Preconditions

   - The grid is a 2D axisymmetric ``r-z`` Yee-staggered layout; the first dimension is radial and the second is axial.
   - CPML coefficient arrays have already been initialized by the caller for the active absorbing-layer cells.
   - ``psi_ephi_r`` and ``psi_ephi_z`` are history variables and must persist across time steps.
   - This routine performs no MPI exchange, physical boundary fill, axis closure, source injection, or update-region selection.
   - The update range must make ``Hz(i-1,k)`` and ``Hr(i,k-1)`` readable, either from valid interior cells or ghost cells.

   .. rubric:: Implementation Notes

   For each ``i,k`` point:

   .. math::

      d_z H_r = \frac{H_{r,i,k}-H_{r,i,k-1}}{\Delta z},
      \qquad
      d_r H_z = \frac{H_{z,i,k}-H_{z,i-1,k}}{\Delta r}.

   The CPML memory variables are updated as:

   .. math::

      \psi_{\phi,z} \leftarrow b_{\phi,z}\psi_{\phi,z}+a_{\phi,z}d_zH_r,
      \qquad
      \psi_{\phi,r} \leftarrow b_{\phi,r}\psi_{\phi,r}+a_{\phi,r}d_rH_z.

   Then:

   .. math::

      E_{\phi,i,k}
      \leftarrow
      E_{\phi,i,k}
      +\frac{\Delta t}{\epsilon}
      \left[
      \frac{d_zH_r}{k_{\phi,z}}
      -
      \frac{d_rH_z}{k_{\phi,r}}
      +\psi_{\phi,z}
      -\psi_{\phi,r}
      \right].

   .. rubric:: Calling Notes

   - For physical-axis updates, use or reproduce the axis treatment from the plain FDTD routine; this CPML routine itself does not set ``Ephi(0,k)=0``.
   - If ``kl`` is a physical or local boundary, prepare ``Hr(:,kl-1)`` before the call or start the update range at a valid interior row.
   - If ``il`` is a physical or local boundary, prepare ``Hz(il-1,:)`` before the call or start the update range at a valid interior column.
   - ``kephi_r`` and ``kephi_z`` must not contain zeros on the update range.

   .. rubric:: Generated API

   .. doxygenfile:: sub_E01_cpml_2d_rz_tez_E.f90
