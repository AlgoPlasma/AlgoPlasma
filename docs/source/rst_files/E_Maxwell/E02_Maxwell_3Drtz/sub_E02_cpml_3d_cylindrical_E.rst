sub_E02_cpml_3d_cylindrical_E.f90
----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在三维柱坐标 ``r-phi-z`` CPML 区域中，用 ``Hr/Hphi/Hz`` 的 curl 更新
   ``Er/Ephi/Ez``，并同步推进电场更新中的六个 CPML memory variables。
   该例程保留 ``phi`` 方向差分项，并对 ``Ephi`` 与 ``Ez`` 的轴线分支做显式闭合。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 24 12 30 44

      * - 参数组
        - 方向
        - shape / 范围
        - 含义与要求
      * - ``ilo_f, ihi_f, jlo_f, jhi_f, klo_f, khi_f``
        - ``in``
        - ``integer scalar``
        - 声明所有场数组、CPML 系数和 memory-variable 数组的有效下标范围。
      * - ``il, iu, jl, ju, kl, ku``
        - ``in``
        - ``integer scalar``
        - 本次电场更新的局部范围。电场 curl 会访问 ``i-1``、``j-1`` 和 ``k-1`` 邻点；调用端必须保证相邻点或 ghost cell 有效。
      * - ``Er, Ephi, Ez``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - 电场三分量，在 ``il:iu, jl:ju, kl:ku`` 范围内原地累加更新。
      * - ``Hr, Hphi, Hz``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - 磁场三分量，用于构造 ``curl H``；调用端负责保证它们处在正确的 Yee 时间层。
      * - ``dt, dr, dphi, dz, ep``
        - ``in``
        - ``real scalar``
        - 时间步长、柱坐标网格间距和介电常数；``dr``、``dphi``、``dz`` 与 ``ep`` 应为非零有效值。
      * - ``a_E_r_phi, b_E_r_phi, k_E_r_phi``
        - ``in``
        - ``real(jlo_f:jhi_f)``
        - ``Er`` 更新中 ``phi`` 向导数 ``dHz/dphi`` 的 CPML 系数。
      * - ``a_E_r_z, b_E_r_z, k_E_r_z``
        - ``in``
        - ``real(klo_f:khi_f)``
        - ``Er`` 更新中 ``z`` 向导数 ``dHphi/dz`` 的 CPML 系数。
      * - ``a_E_phi_z, b_E_phi_z, k_E_phi_z``
        - ``in``
        - ``real(klo_f:khi_f)``
        - ``Ephi`` 更新中 ``z`` 向导数 ``dHr/dz`` 的 CPML 系数。
      * - ``a_E_phi_r, b_E_phi_r, k_E_phi_r``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - ``Ephi`` 更新中 ``r`` 向导数 ``dHz/dr`` 的 CPML 系数。
      * - ``a_E_z_r, b_E_z_r, k_E_z_r``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - ``Ez`` 更新中守恒径向项 ``d(rHphi)/dr`` 的 CPML 系数。
      * - ``a_E_z_phi, b_E_z_phi, k_E_z_phi``
        - ``in``
        - ``real(jlo_f:jhi_f)``
        - ``Ez`` 更新中 ``phi`` 向导数 ``dHr/dphi`` 的 CPML 系数。
      * - ``psi_E_r_phi, psi_E_r_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``Er`` 的两个 CPML memory variables，分别对应 ``dHz/dphi`` 与 ``dHphi/dz``。
      * - ``psi_E_phi_z, psi_E_phi_r``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``Ephi`` 的两个 CPML memory variables，分别对应 ``dHr/dz`` 与 ``dHz/dr``。
      * - ``psi_E_z_r, psi_E_z_phi``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``Ez`` 的两个 CPML memory variables，分别对应 ``d(rHphi)/dr`` 与 ``dHr/dphi``。

   .. rubric:: 局部假设 / 前置条件

   - 网格为完整 3D 柱坐标 ``r-phi-z`` Yee staggered 布局，``dphi`` 使用调用端约定的角间距。
   - CPML 系数数组已经初始化，所有 ``k_E_*`` 在更新范围内都不能为零。
   - ``psi_E_*`` memory variables 必须跨时间步保留，不能在每次调用前清零。
   - ``phi`` 方向通常需要周期 wrap 或 ghost fill；``j-1`` 读访问必须在调用前准备好。
   - ``i=0`` 分支表示物理径向轴线；若本地 MPI 子域不含轴线，不应把局部下标 0 当作物理轴线。
   - 本例程只做局部电场和 CPML memory 更新，不处理 MPI exchange、外边界、源项、电流沉积或系数生成。

   .. rubric:: 实现逻辑

   每个被 CPML 修正的导数先进入对应 memory update：

   .. math::

      \psi \leftarrow b\psi + a d.

   ``Er`` 使用 ``dHz_dphi`` 与 ``dHphi_dz``：

   .. math::

      E_r \leftarrow E_r + \frac{\Delta t}{\epsilon}
      \left[
      \frac{d_\phi H_z/k_{E,r,\phi}+\psi_{E,r,\phi}}{r}
      -\left(\frac{d_z H_\phi}{k_{E,r,z}}+\psi_{E,r,z}\right)
      \right].

   ``Ephi`` 在 ``i=0`` 处直接由 ``Er`` 闭合；其他径向点使用
   ``dHr_dz`` 与 ``dHz_dr`` 的 CPML 修正项。

   ``Ez`` 在 ``i=0`` 处使用 ``Hphi(0,j,k)`` 的 ``phi`` 向平均值进行轴线闭合。
   非轴线点使用守恒形式的径向项 ``d(rHphi)/dr`` 和 ``phi`` 向项 ``dHr/dphi``：

   .. math::

      E_z \leftarrow E_z + \frac{\Delta t}{\epsilon}
      \left[
      \frac{d_r(rH_\phi)/k_{E,z,r}+\psi_{E,z,r}}{r}
      -\frac{d_\phi H_r/k_{E,z,\phi}+\psi_{E,z,\phi}}{r}
      \right].

   .. rubric:: 调用注意

   - 通常在磁场已经处于电场更新所需的半时间层后调用本例程。
   - 更新范围必须避开未定义的 ``i-1``、``j-1``、``k-1`` 邻点，或由调用端提供同步后的 ghost cell。
   - 若更新范围包含 ``i=0``，``Ez`` 轴线闭合会对 ``jl:ju`` 范围内的 ``Hphi`` 求平均；调用端需要确认该范围代表预期的角向集合。
   - 若只在 CPML 区域调用本例程，内部普通区域可继续使用 ``sub_E02_fdtd_3d_cylindrical_E``。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Updates ``Er/Ephi/Ez`` from the curl of ``Hr/Hphi/Hz`` in the 3D cylindrical
   ``r-phi-z`` CPML region and advances the six electric-field CPML memory
   variables at the same time. The routine keeps the ``phi`` derivatives and
   handles explicit axis closures for ``Ephi`` and ``Ez``.

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 24 12 30 44

      * - Parameter group
        - Direction
        - Shape / Range
        - Meaning and requirements
      * - ``ilo_f, ihi_f, jlo_f, jhi_f, klo_f, khi_f``
        - ``in``
        - ``integer scalar``
        - Valid index bounds for all field arrays, CPML coefficients, and memory-variable arrays.
      * - ``il, iu, jl, ju, kl, ku``
        - ``in``
        - ``integer scalar``
        - Local electric-field update range. The electric curl reads ``i-1``, ``j-1``, and ``k-1`` neighbors, so those points or ghost cells must be valid.
      * - ``Er, Ephi, Ez``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - Electric-field components updated in place over ``il:iu, jl:ju, kl:ku``.
      * - ``Hr, Hphi, Hz``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - Magnetic-field components used to form ``curl H``; the caller keeps them on the correct Yee time level.
      * - ``dt, dr, dphi, dz, ep``
        - ``in``
        - ``real scalar``
        - Time step, cylindrical grid spacings, and permittivity; ``dr``, ``dphi``, ``dz``, and ``ep`` must be valid nonzero values.
      * - ``a_E_r_phi, b_E_r_phi, k_E_r_phi``
        - ``in``
        - ``real(jlo_f:jhi_f)``
        - CPML coefficients for the ``dHz/dphi`` term in the ``Er`` update.
      * - ``a_E_r_z, b_E_r_z, k_E_r_z``
        - ``in``
        - ``real(klo_f:khi_f)``
        - CPML coefficients for the ``dHphi/dz`` term in the ``Er`` update.
      * - ``a_E_phi_z, b_E_phi_z, k_E_phi_z``
        - ``in``
        - ``real(klo_f:khi_f)``
        - CPML coefficients for the ``dHr/dz`` term in the ``Ephi`` update.
      * - ``a_E_phi_r, b_E_phi_r, k_E_phi_r``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - CPML coefficients for the ``dHz/dr`` term in the ``Ephi`` update.
      * - ``a_E_z_r, b_E_z_r, k_E_z_r``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - CPML coefficients for the conservative radial ``d(rHphi)/dr`` term in the ``Ez`` update.
      * - ``a_E_z_phi, b_E_z_phi, k_E_z_phi``
        - ``in``
        - ``real(jlo_f:jhi_f)``
        - CPML coefficients for the ``dHr/dphi`` term in the ``Ez`` update.
      * - ``psi_E_r_phi, psi_E_r_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - CPML memory variables for the ``dHz/dphi`` and ``dHphi/dz`` terms in ``Er``.
      * - ``psi_E_phi_z, psi_E_phi_r``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - CPML memory variables for the ``dHr/dz`` and ``dHz/dr`` terms in ``Ephi``.
      * - ``psi_E_z_r, psi_E_z_phi``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - CPML memory variables for the ``d(rHphi)/dr`` and ``dHr/dphi`` terms in ``Ez``.

   .. rubric:: Local Assumptions / Preconditions

   - The grid is a full 3D cylindrical ``r-phi-z`` Yee-staggered layout, with ``dphi`` supplied in the caller's angular-spacing convention.
   - CPML coefficient arrays have already been initialized, and all ``k_E_*`` values on the update range must be nonzero.
   - ``psi_E_*`` memory variables persist across time steps and should not be reset before each call.
   - The ``phi`` direction normally needs periodic wrapping or ghost filling; ``j-1`` reads must be prepared before the call.
   - The ``i=0`` branch denotes the physical radial axis. If the local MPI subdomain does not contain the axis, local index 0 must not be treated as the physical axis.
   - This routine performs only local electric-field and CPML-memory updates; MPI exchange, external boundaries, sources, current deposition, and coefficient generation are outside it.

   .. rubric:: Implementation Notes

   Each CPML-corrected derivative first updates its memory variable:

   .. math::

      \psi \leftarrow b\psi + a d.

   ``Er`` uses ``dHz_dphi`` and ``dHphi_dz``:

   .. math::

      E_r \leftarrow E_r + \frac{\Delta t}{\epsilon}
      \left[
      \frac{d_\phi H_z/k_{E,r,\phi}+\psi_{E,r,\phi}}{r}
      -\left(\frac{d_z H_\phi}{k_{E,r,z}}+\psi_{E,r,z}\right)
      \right].

   ``Ephi`` is closed from ``Er`` at ``i=0``; at other radial points it uses
   the CPML-corrected ``dHr_dz`` and ``dHz_dr`` terms.

   ``Ez`` uses a ``phi`` average of ``Hphi(0,j,k)`` for the axis closure. Away
   from the axis it combines the conservative radial ``d(rHphi)/dr`` term with
   the ``phi`` derivative of ``Hr``:

   .. math::

      E_z \leftarrow E_z + \frac{\Delta t}{\epsilon}
      \left[
      \frac{d_r(rH_\phi)/k_{E,z,r}+\psi_{E,z,r}}{r}
      -\frac{d_\phi H_r/k_{E,z,\phi}+\psi_{E,z,\phi}}{r}
      \right].

   .. rubric:: Calling Notes

   - Call this routine after the magnetic field is on the half-time level required by the electric update.
   - The update range must avoid undefined ``i-1``, ``j-1``, and ``k-1`` neighbors or be supplied with synchronized ghost cells.
   - If the update range includes ``i=0``, the ``Ez`` axis closure averages ``Hphi`` over ``jl:ju``; the caller should ensure that range represents the intended angular set.
   - Interior non-CPML regions can continue to use ``sub_E02_fdtd_3d_cylindrical_E``.

   .. rubric:: Generated API

   .. doxygenfile:: sub_E02_cpml_3d_cylindrical_E.f90
