--------------------------------
sub_E03_cpml_3d_cartesian_H.f90
--------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   在 3D Cartesian Yee 网格的 CPML 区域中，用 ``Ex/Ey/Ez`` 的 curl 更新
   ``Hx/Hy/Hz``，并同步推进磁场更新所需的 CPML memory variables。

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
        - 指定本次更新的局部网格范围；由于磁场 curl 公式会访问 ``i+1``、``j+1`` 和 ``k+1`` 相邻点，调用端必须保证这些邻点或 ghost cell 已经有效。
      * - ``Ex, Ey, Ez``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - 电场三分量，用于构造 ``curl E``。调用端负责保证它们处在正确的 Yee 时间层。
      * - ``Hx, Hy, Hz``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - 磁场三分量。例程在指定范围内原地更新这些数组。
      * - ``dt, dx, dy, dz, mu``
        - ``in``
        - ``real scalar``
        - 时间步长、三方向网格间距和磁导率；单位制与归一化由调用端统一。
      * - ``ahx, bhx, khx``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - x 方向 CPML 系数，用于磁场更新中的 ``x`` 向导数缩放和 memory update。
      * - ``ahy, bhy, khy``
        - ``in``
        - ``real(jlo_f:jhi_f)``
        - y 方向 CPML 系数，用于磁场更新中的 ``y`` 向导数缩放和 memory update。
      * - ``ahz, bhz, khz``
        - ``in``
        - ``real(klo_f:khi_f)``
        - z 方向 CPML 系数，用于磁场更新中的 ``z`` 向导数缩放和 memory update。
      * - ``psi_hx_y, psi_hx_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``Hx`` 更新中对应 ``dEz/dy`` 和 ``dEy/dz`` 的 CPML memory variables。
      * - ``psi_hy_z, psi_hy_x``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``Hy`` 更新中对应 ``dEx/dz`` 和 ``dEz/dx`` 的 CPML memory variables。
      * - ``psi_hz_x, psi_hz_y``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - ``Hz`` 更新中对应 ``dEy/dx`` 和 ``dEx/dy`` 的 CPML memory variables。

   .. rubric:: 局部假设 / 前置条件

   - 网格为 3D Cartesian ``x-y-z`` Yee staggered 布局。
   - CPML 系数数组已经由上层按照吸收层剖面预先计算；``khx/khy/khz`` 不能为零。
   - ``psi_*`` memory variables 必须跨时间步保留；只有在重新初始化吸收层时才应清零。
   - 本例程只做局部磁场更新，不处理 MPI exchange、外边界、源项或 CPML 系数生成。

   .. rubric:: 实现逻辑

   - 对每个网格点先计算电场的局部差分，例如 ``dEz_dy``、``dEy_dz`` 等。
   - 每个差分先进入对应的 CPML memory update：
     ``psi = b*psi + a*d``。
   - 磁场更新使用 ``1/k`` 缩放后的 curl 项，再叠加相应的 memory correction；
     由于 Maxwell 方程中的符号约定，更新式整体带有 ``-dt/mu``。
   - 所有更新均为原地更新，不分配临时大数组。

   .. rubric:: 调用注意

   - 调用端负责维护 Yee leapfrog 的时间层关系；通常应在电场处于磁场更新所需时间层后调用本例程。
   - 更新范围需要避开未填充的边界邻点，或者保证 ghost cell 在调用前已经完成同步。
   - 若只在 CPML 区域调用本例程，内部普通区域可继续使用非 CPML 的 ``sub_E03_fdtd_3d_cartesian_H``。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   Updates ``Hx/Hy/Hz`` from the curl of ``Ex/Ey/Ez`` in the 3D Cartesian CPML
   region and advances the magnetic-field CPML memory variables at the same time.

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
        - Local update range. The magnetic-field curl accesses ``i+1``, ``j+1``, and ``k+1`` neighbors, so those points or ghost cells must be valid.
      * - ``Ex, Ey, Ez``
        - ``in``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - Electric-field components used to form ``curl E``; the caller keeps them on the correct Yee time level.
      * - ``Hx, Hy, Hz``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - Magnetic-field components updated in place over the requested range.
      * - ``dt, dx, dy, dz, mu``
        - ``in``
        - ``real scalar``
        - Time step, grid spacings, and permeability in the caller's normalization.
      * - ``ahx, bhx, khx``
        - ``in``
        - ``real(ilo_f:ihi_f)``
        - x-direction CPML coefficients for derivative scaling and memory updates in the magnetic-field update.
      * - ``ahy, bhy, khy``
        - ``in``
        - ``real(jlo_f:jhi_f)``
        - y-direction CPML coefficients for derivative scaling and memory updates in the magnetic-field update.
      * - ``ahz, bhz, khz``
        - ``in``
        - ``real(klo_f:khi_f)``
        - z-direction CPML coefficients for derivative scaling and memory updates in the magnetic-field update.
      * - ``psi_hx_y, psi_hx_z``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - CPML memory variables for the ``dEz/dy`` and ``dEy/dz`` terms in the ``Hx`` update.
      * - ``psi_hy_z, psi_hy_x``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - CPML memory variables for the ``dEx/dz`` and ``dEz/dx`` terms in the ``Hy`` update.
      * - ``psi_hz_x, psi_hz_y``
        - ``in/out``
        - ``real(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f)``
        - CPML memory variables for the ``dEy/dx`` and ``dEx/dy`` terms in the ``Hz`` update.

   .. rubric:: Local Assumptions / Preconditions

   - The grid is a 3D Cartesian ``x-y-z`` Yee-staggered layout.
   - CPML coefficient arrays have already been prepared by the caller; ``khx/khy/khz`` must be nonzero.
   - ``psi_*`` memory variables persist across time steps and should only be reset when the absorbing layer is reinitialized.
   - MPI exchange, physical boundaries, sources, and CPML coefficient generation are outside this routine.

   .. rubric:: Implementation Notes

   - The routine computes local electric-field differences such as ``dEz_dy`` and ``dEy_dz``.
   - Each derivative feeds a memory update of the form ``psi = b*psi + a*d``.
   - The magnetic update combines the ``1/k``-scaled curl terms with the corresponding memory corrections and the overall ``-dt/mu`` sign.
   - All field and memory updates are in place; no large temporary arrays are allocated.

   .. rubric:: Calling Notes

   - The caller maintains Yee leapfrog time staggering and usually calls this routine after the electric field is on the time level needed for the magnetic update.
   - The update range must avoid undefined boundary neighbors or be supplied with synchronized ghost cells.
   - Interior non-CPML regions can continue to use ``sub_E03_fdtd_3d_cartesian_H``.

   .. rubric:: Generated API

   .. doxygenfile:: sub_E03_cpml_3d_cartesian_H.f90
