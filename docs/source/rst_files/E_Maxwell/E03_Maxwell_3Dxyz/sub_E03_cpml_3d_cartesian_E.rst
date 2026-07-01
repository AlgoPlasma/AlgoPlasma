--------------------------------
sub_E03_cpml_3d_cartesian_E.f90
--------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在 3D Cartesian Yee 网格的 CPML 区域中，用 ``Hx/Hy/Hz`` 的 curl 更新
   ``Ex/Ey/Ez``，并同步推进电场更新所需的 CPML memory variables。

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
        - 指定本次更新的局部网格范围；由于电场 curl 公式会访问 ``i-1``、``j-1`` 和 ``k-1`` 相邻点，调用端必须保证这些邻点或 ghost cell 已经有效。
      * - ``Ex, Ey, Ez``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - 电场三分量。例程在指定范围内原地更新这些数组。
      * - ``Hx, Hy, Hz``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - 磁场三分量，用于构造 ``curl H``。调用端负责保证它们处在正确的 Yee 时间层。
      * - ``dt, dx, dy, dz, ep``
        - ``in``
        - ``real scalar``
        - 时间步长、三方向网格间距和介电常数；单位制与归一化由调用端统一。
      * - ``aex, bex, kex``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - x 方向 CPML 系数，用于电场更新中的 ``x`` 向导数缩放和 memory update。
      * - ``aey, bey, key``
        - ``in``
        - ``real(jlo_f:jhi_f)``
        - y 方向 CPML 系数，用于电场更新中的 ``y`` 向导数缩放和 memory update。
      * - ``aez, bez, kez``
        - ``in``
        - ``real(klo_f:khi_f)``
        - z 方向 CPML 系数，用于电场更新中的 ``z`` 向导数缩放和 memory update。
      * - ``psi_ex_y, psi_ex_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``Ex`` 更新中对应 ``dHz/dy`` 和 ``dHy/dz`` 的 CPML memory variables。
      * - ``psi_ey_z, psi_ey_x``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``Ey`` 更新中对应 ``dHx/dz`` 和 ``dHz/dx`` 的 CPML memory variables。
      * - ``psi_ez_x, psi_ez_y``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``Ez`` 更新中对应 ``dHy/dx`` 和 ``dHx/dy`` 的 CPML memory variables。

   .. rubric:: 局部假设 / 前置条件

   - 网格为 3D Cartesian ``x-y-z`` Yee staggered 布局。
   - CPML 系数数组已经由上层按照吸收层剖面预先计算；``kex/key/kez`` 不能为零。
   - ``psi_*`` memory variables 必须跨时间步保留；只有在重新初始化吸收层时才应清零。
   - 本例程只做局部电场更新，不处理 MPI exchange、外边界、源项、电流沉积或 CPML 系数生成。

   .. rubric:: 实现逻辑

   - 对每个网格点先计算磁场的局部差分，例如 ``dHz_dy``、``dHy_dz`` 等。
   - 每个差分先进入对应的 CPML memory update：
     ``psi = b*psi + a*d``。
   - 电场更新使用 ``1/k`` 缩放后的 curl 项，再叠加相应的 memory correction；
     例如 ``Ex`` 同时使用 ``psi_ex_y`` 和 ``psi_ex_z``。
   - 所有更新均为原地更新，不分配临时大数组。

   .. rubric:: 调用注意

   - 调用端负责维护 Yee leapfrog 的时间层关系；通常应在磁场处于电场更新所需时间层后调用本例程。
   - 更新范围需要避开未填充的边界邻点，或者保证 ghost cell 在调用前已经完成同步。
   - 若只在 CPML 区域调用本例程，内部普通区域可继续使用非 CPML 的 ``sub_E03_fdtd_3d_cartesian_E``。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Updates ``Ex/Ey/Ez`` from the curl of ``Hx/Hy/Hz`` in the 3D Cartesian CPML
   region and advances the electric-field CPML memory variables at the same time.

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
        - Local update range. The electric-field curl accesses ``i-1``, ``j-1``, and ``k-1`` neighbors, so those points or ghost cells must be valid.
      * - ``Ex, Ey, Ez``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - Electric-field components updated in place over the requested range.
      * - ``Hx, Hy, Hz``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - Magnetic-field components used to form ``curl H``; the caller keeps them on the correct Yee time level.
      * - ``dt, dx, dy, dz, ep``
        - ``in``
        - ``real scalar``
        - Time step, grid spacings, and permittivity in the caller's normalization.
      * - ``aex, bex, kex``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - x-direction CPML coefficients for derivative scaling and memory updates in the electric-field update.
      * - ``aey, bey, key``
        - ``in``
        - ``real(jlo_f:jhi_f)``
        - y-direction CPML coefficients for derivative scaling and memory updates in the electric-field update.
      * - ``aez, bez, kez``
        - ``in``
        - ``real(klo_f:khi_f)``
        - z-direction CPML coefficients for derivative scaling and memory updates in the electric-field update.
      * - ``psi_ex_y, psi_ex_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - CPML memory variables for the ``dHz/dy`` and ``dHy/dz`` terms in the ``Ex`` update.
      * - ``psi_ey_z, psi_ey_x``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - CPML memory variables for the ``dHx/dz`` and ``dHz/dx`` terms in the ``Ey`` update.
      * - ``psi_ez_x, psi_ez_y``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - CPML memory variables for the ``dHy/dx`` and ``dHx/dy`` terms in the ``Ez`` update.

   .. rubric:: Local Assumptions / Preconditions

   - The grid is a 3D Cartesian ``x-y-z`` Yee-staggered layout.
   - CPML coefficient arrays have already been prepared by the caller; ``kex/key/kez`` must be nonzero.
   - ``psi_*`` memory variables persist across time steps and should only be reset when the absorbing layer is reinitialized.
   - MPI exchange, physical boundaries, sources, current deposition, and CPML coefficient generation are outside this routine.

   .. rubric:: Implementation Notes

   - The routine computes local magnetic-field differences such as ``dHz_dy`` and ``dHy_dz``.
   - Each derivative feeds a memory update of the form ``psi = b*psi + a*d``.
   - The electric update combines the ``1/k``-scaled curl terms with the corresponding memory corrections.
   - All field and memory updates are in place; no large temporary arrays are allocated.

   .. rubric:: Calling Notes

   - The caller maintains Yee leapfrog time staggering and usually calls this routine after the magnetic field is on the time level needed for the electric update.
   - The update range must avoid undefined boundary neighbors or be supplied with synchronized ghost cells.
   - Interior non-CPML regions can continue to use ``sub_E03_fdtd_3d_cartesian_E``.

   .. rubric:: Generated API

   .. doxygenfile:: sub_E03_cpml_3d_cartesian_E.f90
