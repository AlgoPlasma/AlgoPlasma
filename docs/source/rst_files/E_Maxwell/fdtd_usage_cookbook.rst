FDTD Usage Cookbook
===================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这页解决什么问题

   本页从“我要把 E_Maxwell 接进自己的程序”出发，说明如何选择内核、准备数组、组织时间步、
   安排边界/源项/ghost cell，以及什么时候使用 CPML。具体参数顺序仍以各 routine API 页为准；
   本页只给出不容易从单个参数表中看出的整体调用关系。

   .. rubric:: 先选哪个模块

   .. list-table::
      :header-rows: 1
      :widths: 24 26 28 22

      * - 你的问题
        - 使用模块
        - 主要场量
        - 先看
      * - 轴对称 ``(r,z)``，不保留 ``phi`` 变化
        - :doc:`E01_Maxwell_2Drz <E01_Maxwell_2Drz>`
        - ``Ephi,Hr,Hz`` 或 ``Er,Hphi/Ha,Ez``
        - :doc:`E01 notes <E01_Maxwell_2Drz/fdtd_2d_rz_axisymmetric_notes>`
      * - 完整 3D 柱坐标，保留 ``phi`` 变化
        - :doc:`E02_Maxwell_3Drtz <E02_Maxwell_3Drtz>`
        - ``Er,Ephi,Ez,Hr,Hphi,Hz``
        - :doc:`E02 notes <E02_Maxwell_3Drtz/fdtd_3d_cylindrical_notes>`
      * - 普通 3D Cartesian 网格
        - :doc:`E03_Maxwell_3Dxyz <E03_Maxwell_3Dxyz>`
        - ``Ex,Ey,Ez,Hx,Hy,Hz``
        - :doc:`E03 notes <E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes>`

   .. rubric:: 调用方必须负责的事情

   ``E_Maxwell`` 内核是局部场更新 routine，不是完整求解器框架。调用方需要负责：

   - 分配并初始化所有场数组、CPML memory 数组和系数数组。
   - 决定物理单位或归一化单位，并保证 ``dt``、空间步长、``ep``、``mu`` 在同一单位体系中。
   - 选择满足稳定性要求的 ``dt``；routine 不检查 CFL。
   - 在每次 curl 更新前准备好会被访问的相邻点、周期 wrap、物理边界或 MPI ghost cell。
   - 在正确的半步位置注入源项，并决定源项是 hard source 还是 soft source。
   - 组织诊断输出、能量统计、文件 I/O 和并行通信。

   .. rubric:: 编译和精度

   模块 wrapper 中使用 ``#include`` 收纳 subroutine。若编译器不会自动预处理 ``.f90``，
   需要启用 Fortran 预处理，例如 GNU Fortran 使用 ``-cpp``。源码中多数变量声明为默认
   ``real``；若需要双精度，可在项目编译选项中统一决定，例如 GNU Fortran 使用
   ``-fdefault-real-8``。不要在同一个可执行程序里混用不同默认 real 策略。

   .. rubric:: 最小时间步结构

   下面只给一个 3D Cartesian 例子。读完这个例子后，E01 和 E02 的接入方式可以按同样原则迁移：
   先准备边界/ghost，再更新 ``H``，再准备边界/ghost，最后更新 ``E``。这里保留真实 module 名、
   subroutine 名和完整参数顺序；数组分配、源项和 MPI exchange 仍用占位过程表示。

   .. code-block:: fortran

      use mod_E03_fdtd_3d_cartesian, only: sub_E03_fdtd_3d_cartesian_H, sub_E03_fdtd_3d_cartesian_E

      integer :: n, nstep
      integer :: ilo_f, ihi_f, jlo_f, jhi_f, klo_f, khi_f
      integer :: il, iu, jl, ju, kl, ku
      real :: dt, dx, dy, dz, ep, mu
      real, allocatable :: Ex(:,:,:), Ey(:,:,:), Ez(:,:,:)
      real, allocatable :: Hx(:,:,:), Hy(:,:,:), Hz(:,:,:)

      ! Example convention: field arrays include one ghost layer on each side.
      ! The update range is the owned interior region; it must leave the
      ! neighboring points used by the finite differences valid.
      ilo_f = 0; ihi_f = nx + 1
      jlo_f = 0; jhi_f = ny + 1
      klo_f = 0; khi_f = nz + 1
      il = 1; iu = nx
      jl = 1; ju = ny
      kl = 1; ku = nz

      allocate(Ex(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f))
      allocate(Ey(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f))
      allocate(Ez(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f))
      allocate(Hx(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f))
      allocate(Hy(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f))
      allocate(Hz(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f))

      call initialize_fields(Ex, Ey, Ez, Hx, Hy, Hz)

      do n = 1, nstep
          ! H update reads forward E neighbors such as i+1, j+1, and k+1.
          call fill_E_boundaries_or_ghosts(Ex, Ey, Ez)
          call inject_E_sources_if_needed(Ex, Ey, Ez, n)

          call sub_E03_fdtd_3d_cartesian_H(ilo_f, ihi_f, jlo_f, jhi_f, klo_f, khi_f, &
              il, iu, jl, ju, kl, ku, Ex, Ey, Ez, Hx, Hy, Hz, dt, dx, dy, dz, mu)

          ! E update reads backward H neighbors such as i-1, j-1, and k-1.
          call fill_H_boundaries_or_ghosts(Hx, Hy, Hz)
          call inject_H_sources_if_needed(Hx, Hy, Hz, n)

          call sub_E03_fdtd_3d_cartesian_E(ilo_f, ihi_f, jlo_f, jhi_f, klo_f, khi_f, &
              il, iu, jl, ju, kl, ku, Ex, Ey, Ez, Hx, Hy, Hz, dt, dx, dy, dz, ep)

          call diagnostics_if_needed(...)
      end do

   要把这个结构迁移到 E01 或 E02，只需要替换 module 和子程序名称、场分量数组以及几何步长参数；
   调用前准备邻点/ghost cell、每个时间层只更新一次同一区域的原则保持不变。

   .. rubric:: 加入 CPML

   CPML 区域应使用 CPML routine 替代普通 FDTD routine 的同一场分量更新，而不是在普通更新后
   再额外调用一次。典型组织方式是：

   1. 内部普通区域调用普通 FDTD routine。
   2. 吸收层条带调用对应 CPML routine，并传入 persistent ``psi_*`` memory 数组。
   3. 轴线 ``r=0`` 不作为 PML 边界；完整圆周的 ``phi`` 周期方向通常也不设置真实 CPML。
   4. 修改 CPML 参数或调用范围后，运行 :doc:`CPML wave-packet tests </tests/005_maxwell/cpml_wavepacket>`。

   详细规则见 :doc:`CPML cookbook <cpml_cookbook>`。

   .. rubric:: 常见集成错误

   - 更新范围包含了未填好的 ghost cell，导致相邻差分读到旧值或越界。
   - 在同一区域先普通 FDTD 更新，又调用 CPML 更新，导致场量被更新两次。
   - 把 ``i=0`` 当成普通径向内部点，忘记轴线闭合。
   - ``phi`` 周期接缝没有在调用前填好，导致角向差分不连续。
   - 源项放错时间层，例如在需要半步磁场的地方使用整步场。
   - 用双精度数组调用默认 ``real`` 编译出的 routine，或反过来混用精度。

.. container:: ap-lang ap-lang-en

   .. rubric:: What This Page Is For

   This page starts from the practical question: how do I integrate E_Maxwell
   into my own code? It explains kernel choice, array ownership, time-step
   orchestration, boundary/source/ghost handling, and when to use CPML. Exact
   argument order still belongs to each routine API page; this page documents
   the overall calling relationship that is hard to see from one parameter
   table alone.

   .. rubric:: Choose the Module First

   .. list-table::
      :header-rows: 1
      :widths: 24 26 28 22

      * - Your problem
        - Use module
        - Main fields
        - Read first
      * - Axisymmetric ``(r,z)`` without ``phi`` variation
        - :doc:`E01_Maxwell_2Drz <E01_Maxwell_2Drz>`
        - ``Ephi,Hr,Hz`` or ``Er,Hphi/Ha,Ez``
        - :doc:`E01 notes <E01_Maxwell_2Drz/fdtd_2d_rz_axisymmetric_notes>`
      * - Full 3D cylindrical with ``phi`` variation
        - :doc:`E02_Maxwell_3Drtz <E02_Maxwell_3Drtz>`
        - ``Er,Ephi,Ez,Hr,Hphi,Hz``
        - :doc:`E02 notes <E02_Maxwell_3Drtz/fdtd_3d_cylindrical_notes>`
      * - Standard 3D Cartesian grid
        - :doc:`E03_Maxwell_3Dxyz <E03_Maxwell_3Dxyz>`
        - ``Ex,Ey,Ez,Hx,Hy,Hz``
        - :doc:`E03 notes <E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes>`

   .. rubric:: What the Caller Owns

   ``E_Maxwell`` kernels are local field-update routines, not a full solver
   framework. The caller owns:

   - allocation and initialization of all field arrays, CPML memory arrays, and
     coefficient arrays
   - physical or normalized units, with ``dt``, spacing, ``ep``, and ``mu`` kept
     consistent
   - a stable ``dt`` chosen from the CFL condition; the routines do not check it
   - neighbor cells, periodic wrapping, physical boundary values, or MPI ghost
     cells before each curl update
   - source injection at the intended half-step location, including hard-source
     versus soft-source policy
   - diagnostics, energy monitoring, file I/O, and parallel communication

   .. rubric:: Compilation and Precision

   Module wrappers use ``#include`` to collect subroutines. If the compiler does
   not preprocess ``.f90`` files automatically, enable Fortran preprocessing,
   for example ``-cpp`` with GNU Fortran. Most declarations use default
   ``real``. Double precision is normally a project-wide compile-time choice,
   for example ``-fdefault-real-8`` with GNU Fortran. Do not mix different
   default-real policies inside one executable.

   .. rubric:: Minimal Time-Step Structure

   The following example uses the 3D Cartesian routines only. Once this pattern is
   clear, E01 and E02 follow the same idea: prepare boundary or ghost values,
   update ``H``, prepare boundary or ghost values again, and update ``E``. The
   module names, routine names, and argument order are real; allocation, source
   injection, and MPI exchange remain placeholder calls.

   .. code-block:: fortran

      use mod_E03_fdtd_3d_cartesian, only: sub_E03_fdtd_3d_cartesian_H, sub_E03_fdtd_3d_cartesian_E

      integer :: n, nstep
      integer :: ilo_f, ihi_f, jlo_f, jhi_f, klo_f, khi_f
      integer :: il, iu, jl, ju, kl, ku
      real :: dt, dx, dy, dz, ep, mu
      real, allocatable :: Ex(:,:,:), Ey(:,:,:), Ez(:,:,:)
      real, allocatable :: Hx(:,:,:), Hy(:,:,:), Hz(:,:,:)

      ! Example convention: field arrays include one ghost layer on each side.
      ! The update range is the owned interior region; it must leave the
      ! neighboring points used by the finite differences valid.
      ilo_f = 0; ihi_f = nx + 1
      jlo_f = 0; jhi_f = ny + 1
      klo_f = 0; khi_f = nz + 1
      il = 1; iu = nx
      jl = 1; ju = ny
      kl = 1; ku = nz

      allocate(Ex(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f))
      allocate(Ey(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f))
      allocate(Ez(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f))
      allocate(Hx(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f))
      allocate(Hy(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f))
      allocate(Hz(ilo_f:ihi_f,jlo_f:jhi_f,klo_f:khi_f))

      call initialize_fields(Ex, Ey, Ez, Hx, Hy, Hz)

      do n = 1, nstep
          ! H update reads forward E neighbors such as i+1, j+1, and k+1.
          call fill_E_boundaries_or_ghosts(Ex, Ey, Ez)
          call inject_E_sources_if_needed(Ex, Ey, Ez, n)

          call sub_E03_fdtd_3d_cartesian_H(ilo_f, ihi_f, jlo_f, jhi_f, klo_f, khi_f, &
              il, iu, jl, ju, kl, ku, Ex, Ey, Ez, Hx, Hy, Hz, dt, dx, dy, dz, mu)

          ! E update reads backward H neighbors such as i-1, j-1, and k-1.
          call fill_H_boundaries_or_ghosts(Hx, Hy, Hz)
          call inject_H_sources_if_needed(Hx, Hy, Hz, n)

          call sub_E03_fdtd_3d_cartesian_E(ilo_f, ihi_f, jlo_f, jhi_f, klo_f, khi_f, &
              il, iu, jl, ju, kl, ku, Ex, Ey, Ez, Hx, Hy, Hz, dt, dx, dy, dz, ep)

          call diagnostics_if_needed(...)
      end do

   To migrate this structure to E01 or E02, replace only the module and routine
   names, field-component arrays, and geometric spacing parameters. The rules
   about neighbor or ghost preparation and one update per region per time layer
   stay the same.

   .. rubric:: Adding CPML

   In a CPML strip, call the CPML routine instead of the corresponding plain
   FDTD update for the same field component; do not call it as an extra update
   after the normal routine. A typical organization is:

   1. Call plain FDTD routines on the interior non-PML region.
   2. Call matching CPML routines on absorbing strips and pass persistent
      ``psi_*`` memory arrays.
   3. Do not treat the :math:`r=0` axis as a PML boundary; full-periodic
      ``phi`` is normally not a real CPML boundary either.
   4. After changing CPML parameters or update ranges, run
      :doc:`CPML wave-packet tests </tests/005_maxwell/cpml_wavepacket>`.

   See :doc:`CPML cookbook <cpml_cookbook>` for detailed rules.

   .. rubric:: Common Integration Mistakes

   - Including unprepared ghost cells in the update range.
   - Applying both plain FDTD and CPML updates to the same field component in
     the same region.
   - Treating ``i=0`` as a regular radial interior point.
   - Failing to fill the ``phi`` periodic seam before angular differences.
   - Injecting sources on the wrong time layer.
   - Mixing double-precision arrays with routines compiled as default ``real``,
     or the reverse.
