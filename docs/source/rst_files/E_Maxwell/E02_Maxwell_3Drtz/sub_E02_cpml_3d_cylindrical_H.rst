sub_E02_cpml_3d_cylindrical_H.f90
----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在三维柱坐标 ``r-phi-z`` CPML 区域中，用 ``Er/Ephi/Ez`` 的 curl 更新
   ``Hr/Hphi/Hz``，并同步推进磁场更新中的六个 CPML memory variables。
   该例程保留 ``phi`` 方向差分项，并对 ``Hr`` 的轴线分支做显式闭合。

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
        - 本次磁场更新的局部范围。磁场 curl 会访问 ``i+1``、``j+1`` 和 ``k+1`` 邻点；调用端必须保证相邻点或 ghost cell 有效。
      * - ``Er, Ephi, Ez``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - 电场三分量，用于构造 ``curl E``；调用端负责保证它们处在正确的 Yee 时间层。
      * - ``Hr, Hphi, Hz``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - 磁场三分量，在 ``il:iu, jl:ju, kl:ku`` 范围内原地累加更新。
      * - ``dt, dr, dphi, dz, mu``
        - ``in``
        - ``real scalar``
        - 时间步长、柱坐标网格间距和磁导率；``dr``、``dphi``、``dz`` 与 ``mu`` 应为非零有效值。
      * - ``a_H_r_z, b_H_r_z, k_H_r_z``
        - ``in``
        - ``real(klo_f:khi_f)``
        - ``Hr`` 更新中 ``z`` 向导数 ``dEphi/dz`` 的 CPML 系数。
      * - ``a_H_r_phi, b_H_r_phi, k_H_r_phi``
        - ``in``
        - ``real(jlo_f:jhi_f)``
        - ``Hr`` 更新中 ``phi`` 向导数 ``dEz/dphi`` 的 CPML 系数。
      * - ``a_H_phi_r, b_H_phi_r, k_H_phi_r``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - ``Hphi`` 更新中 ``r`` 向导数 ``dEz/dr`` 的 CPML 系数。
      * - ``a_H_phi_z, b_H_phi_z, k_H_phi_z``
        - ``in``
        - ``real(klo_f:khi_f)``
        - ``Hphi`` 更新中 ``z`` 向导数 ``dEr/dz`` 的 CPML 系数。
      * - ``a_H_z_phi, b_H_z_phi, k_H_z_phi``
        - ``in``
        - ``real(jlo_f:jhi_f)``
        - ``Hz`` 更新中 ``phi`` 向导数 ``dEr/dphi`` 的 CPML 系数。
      * - ``a_H_z_r, b_H_z_r, k_H_z_r``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - ``Hz`` 更新中守恒径向项 ``d(rEphi)/dr`` 的 CPML 系数。
      * - ``psi_H_r_z, psi_H_r_phi``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``Hr`` 的两个 CPML memory variables，分别对应 ``dEphi/dz`` 与 ``dEz/dphi``。
      * - ``psi_H_phi_r, psi_H_phi_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``Hphi`` 的两个 CPML memory variables，分别对应 ``dEz/dr`` 与 ``dEr/dz``。
      * - ``psi_H_z_phi, psi_H_z_r``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``Hz`` 的两个 CPML memory variables，分别对应 ``dEr/dphi`` 与 ``d(rEphi)/dr``。

   .. rubric:: 局部假设 / 前置条件

   - 网格为完整 3D 柱坐标 ``r-phi-z`` Yee staggered 布局，``dphi`` 使用调用端约定的角间距。
   - CPML 系数数组已经初始化，所有 ``k_H_*`` 在更新范围内都不能为零。
   - ``psi_H_*`` memory variables 必须跨时间步保留，不能在每次调用前清零。
   - ``phi`` 方向通常需要周期 wrap 或 ghost fill；``j+1`` 读访问必须在调用前准备好。
   - ``i=0`` 分支表示物理径向轴线；若本地 MPI 子域不含轴线，不应把局部下标 0 当作物理轴线。
   - 本例程只做局部磁场和 CPML memory 更新，不处理 MPI exchange、外边界、源项或系数生成。

   .. rubric:: 实现逻辑

   每个被 CPML 修正的导数先进入对应 memory update：

   .. math::

      \psi \leftarrow b\psi + a d.

   ``Hr`` 在 ``i=0`` 处由 ``Hphi`` 闭合；其他径向点使用 ``dEphi_dz`` 与
   ``dEz_dphi``：

   .. math::

      H_r \leftarrow H_r + \frac{\Delta t}{\mu}
      \left[
      \left(\frac{d_z E_\phi}{k_{H,r,z}}+\psi_{H,r,z}\right)
      -\frac{d_\phi E_z/k_{H,r,\phi}+\psi_{H,r,\phi}}{r}
      \right].

   ``Hphi`` 使用 ``dEz_dr`` 和 ``dEr_dz``：

   .. math::

      H_\phi \leftarrow H_\phi + \frac{\Delta t}{\mu}
      \left[
      \left(\frac{d_r E_z}{k_{H,\phi,r}}+\psi_{H,\phi,r}\right)
      -\left(\frac{d_z E_r}{k_{H,\phi,z}}+\psi_{H,\phi,z}\right)
      \right].

   ``Hz`` 使用 ``phi`` 向项 ``dEr/dphi`` 和守恒径向项 ``d(rEphi)/dr``：

   .. math::

      H_z \leftarrow H_z + \frac{\Delta t}{\mu}
      \left[
      \frac{d_\phi E_r/k_{H,z,\phi}+\psi_{H,z,\phi}}{r}
      -\frac{d_r(rE_\phi)/k_{H,z,r}+\psi_{H,z,r}}{r}
      \right].

   .. rubric:: 调用注意

   - 通常在电场已经处于磁场更新所需的整数时间层后调用本例程。
   - 更新范围必须避开未定义的 ``i+1``、``j+1``、``k+1`` 邻点，或由调用端提供同步后的 ghost cell。
   - 若更新范围包含 ``i=0``，例程会在循环内和末尾都执行 ``Hr(0,j,k)=Hphi(0,j,k)`` 的轴线闭合。
   - 若只在 CPML 区域调用本例程，内部普通区域可继续使用 ``sub_E02_fdtd_3d_cylindrical_H``。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Updates ``Hr/Hphi/Hz`` from the curl of ``Er/Ephi/Ez`` in the 3D cylindrical
   ``r-phi-z`` CPML region and advances the six magnetic-field CPML memory
   variables at the same time. The routine keeps the ``phi`` derivatives and
   handles the explicit axis closure for ``Hr``.

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
        - Local magnetic-field update range. The magnetic curl reads ``i+1``, ``j+1``, and ``k+1`` neighbors, so those points or ghost cells must be valid.
      * - ``Er, Ephi, Ez``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - Electric-field components used to form ``curl E``; the caller keeps them on the correct Yee time level.
      * - ``Hr, Hphi, Hz``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - Magnetic-field components updated in place over ``il:iu, jl:ju, kl:ku``.
      * - ``dt, dr, dphi, dz, mu``
        - ``in``
        - ``real scalar``
        - Time step, cylindrical grid spacings, and permeability; ``dr``, ``dphi``, ``dz``, and ``mu`` must be valid nonzero values.
      * - ``a_H_r_z, b_H_r_z, k_H_r_z``
        - ``in``
        - ``real(klo_f:khi_f)``
        - CPML coefficients for the ``dEphi/dz`` term in the ``Hr`` update.
      * - ``a_H_r_phi, b_H_r_phi, k_H_r_phi``
        - ``in``
        - ``real(jlo_f:jhi_f)``
        - CPML coefficients for the ``dEz/dphi`` term in the ``Hr`` update.
      * - ``a_H_phi_r, b_H_phi_r, k_H_phi_r``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - CPML coefficients for the ``dEz/dr`` term in the ``Hphi`` update.
      * - ``a_H_phi_z, b_H_phi_z, k_H_phi_z``
        - ``in``
        - ``real(klo_f:khi_f)``
        - CPML coefficients for the ``dEr/dz`` term in the ``Hphi`` update.
      * - ``a_H_z_phi, b_H_z_phi, k_H_z_phi``
        - ``in``
        - ``real(jlo_f:jhi_f)``
        - CPML coefficients for the ``dEr/dphi`` term in the ``Hz`` update.
      * - ``a_H_z_r, b_H_z_r, k_H_z_r``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - CPML coefficients for the conservative radial ``d(rEphi)/dr`` term in the ``Hz`` update.
      * - ``psi_H_r_z, psi_H_r_phi``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - CPML memory variables for the ``dEphi/dz`` and ``dEz/dphi`` terms in ``Hr``.
      * - ``psi_H_phi_r, psi_H_phi_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - CPML memory variables for the ``dEz/dr`` and ``dEr/dz`` terms in ``Hphi``.
      * - ``psi_H_z_phi, psi_H_z_r``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - CPML memory variables for the ``dEr/dphi`` and ``d(rEphi)/dr`` terms in ``Hz``.

   .. rubric:: Local Assumptions / Preconditions

   - The grid is a full 3D cylindrical ``r-phi-z`` Yee-staggered layout, with ``dphi`` supplied in the caller's angular-spacing convention.
   - CPML coefficient arrays have already been initialized, and all ``k_H_*`` values on the update range must be nonzero.
   - ``psi_H_*`` memory variables persist across time steps and should not be reset before each call.
   - The ``phi`` direction normally needs periodic wrapping or ghost filling; ``j+1`` reads must be prepared before the call.
   - The ``i=0`` branch denotes the physical radial axis. If the local MPI subdomain does not contain the axis, local index 0 must not be treated as the physical axis.
   - This routine performs only local magnetic-field and CPML-memory updates; MPI exchange, external boundaries, sources, and coefficient generation are outside it.

   .. rubric:: Implementation Notes

   Each CPML-corrected derivative first updates its memory variable:

   .. math::

      \psi \leftarrow b\psi + a d.

   ``Hr`` is closed from ``Hphi`` at ``i=0``; at other radial points it uses
   ``dEphi_dz`` and ``dEz_dphi``:

   .. math::

      H_r \leftarrow H_r + \frac{\Delta t}{\mu}
      \left[
      \left(\frac{d_z E_\phi}{k_{H,r,z}}+\psi_{H,r,z}\right)
      -\frac{d_\phi E_z/k_{H,r,\phi}+\psi_{H,r,\phi}}{r}
      \right].

   ``Hphi`` uses ``dEz_dr`` and ``dEr_dz``:

   .. math::

      H_\phi \leftarrow H_\phi + \frac{\Delta t}{\mu}
      \left[
      \left(\frac{d_r E_z}{k_{H,\phi,r}}+\psi_{H,\phi,r}\right)
      -\left(\frac{d_z E_r}{k_{H,\phi,z}}+\psi_{H,\phi,z}\right)
      \right].

   ``Hz`` combines the ``phi`` derivative of ``Er`` with the conservative radial
   ``d(rEphi)/dr`` term:

   .. math::

      H_z \leftarrow H_z + \frac{\Delta t}{\mu}
      \left[
      \frac{d_\phi E_r/k_{H,z,\phi}+\psi_{H,z,\phi}}{r}
      -\frac{d_r(rE_\phi)/k_{H,z,r}+\psi_{H,z,r}}{r}
      \right].

   .. rubric:: Calling Notes

   - Call this routine after the electric field is on the integer time level required by the magnetic update.
   - The update range must avoid undefined ``i+1``, ``j+1``, and ``k+1`` neighbors or be supplied with synchronized ghost cells.
   - If the update range includes ``i=0``, the routine applies ``Hr(0,j,k)=Hphi(0,j,k)`` both inside the loop and in a final axis-closure pass.
   - Interior non-CPML regions can continue to use ``sub_E02_fdtd_3d_cylindrical_H``.

   .. rubric:: Generated API

   .. doxygenfile:: sub_E02_cpml_3d_cylindrical_H.f90
