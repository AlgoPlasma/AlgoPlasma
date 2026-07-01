case_fdtd_single_step_formula
=============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   ``case_fdtd_single_step_formula`` 是最局部的 FDTD 公式测试：它只推进一步，把生产内核的
   ``E``/``H`` 更新结果和测试程序中手写的显式 stencil 公式逐点比较。它不测试 CPML、源项、粒子、
   碰撞或滤波。

   .. rubric:: 覆盖子程序

   - :doc:`E01 TEz/TMz </rst_files/E_Maxwell/E01_Maxwell_2Drz>`：
     ``sub_E01_fdtd_2d_rz_tez_*`` 和 ``sub_E01_fdtd_2d_rz_tmz_*``。
   - :doc:`E02 3D cylindrical </rst_files/E_Maxwell/E02_Maxwell_3Drtz>`：
     ``sub_E02_fdtd_3d_cylindrical_E`` 和 ``sub_E02_fdtd_3d_cylindrical_H``。
   - :doc:`E03 3D Cartesian </rst_files/E_Maxwell/E03_Maxwell_3Dxyz>`：
     ``sub_E03_fdtd_3d_cartesian_E`` 和 ``sub_E03_fdtd_3d_cartesian_H``。

   .. rubric:: 文件说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 文件
        - 作用
      * - ``test_*_single_step.f90``
        - 五个主测试：2D RZ TEz、2D RZ TMz、3D Cartesian、3D cylindrical ``m=0``、``m=1``。
      * - ``test_single_step_utils.f90``
        - 误差统计、PGM 误差图输出和公共辅助函数。
      * - ``make.sh`` / ``run.sh`` / ``clean.sh``
        - 编译、运行全部单步测试、清理 ``*.o/*.mod/*.out/*.pgm`` 等产物。
      * - ``*.pgm``
        - 每个 E-step、H-step、full-step 的灰度误差图；数值回归以终端误差为准。

   .. rubric:: 运行方式

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_single_step_formula
      bash run.sh

   .. rubric:: 主流程

   1. 在每个几何中构造确定性的光滑初始场。
   2. 保存一份 ``*_old`` 场作为手写参考公式输入。
   3. 调用生产内核推进 ``H`` 或 ``E`` 一步。
   4. 在相同网格位置用显式 stencil 公式计算参考值。
   5. 统计 ``max_abs_err``、``max_rel_err`` 和 ``n_failed``。
   6. 写出 PGM 误差投影图，方便定位异常点。

   .. rubric:: 典型例子：3D Cartesian 单步测试

   ``test_3d_cartesian_single_step.f90`` 是最容易读懂的一个子测试。它先设定一个很小的三维网格和一组固定参数；
   网格小是为了让单步测试运行快，参数固定是为了让每次回归结果完全可重复。

   .. code-block:: fortran

      integer, parameter :: nx = 10, ny = 9, nz = 8
      real, parameter :: dx = 0.08, dy = 0.11, dz = 0.09
      real, parameter :: dt = 0.35e-10
      real, parameter :: ep = 8.854187817e-12
      real, parameter :: mu = 1.2566370614e-6

      call init_staggered_periodic_fields(nx,ny,nz,dx,dy,dz, &
          Ex0,Ey0,Ez0,Hx0,Hy0,Hz0)

   初始化函数的重点不是构造一个严格物理解析解，而是把六个分量都填成光滑、非平凡、可重复的场。每个分量都按 Yee
   网格自己的位置取样：例如 ``Ex`` 在 ``x=i*dx, y=(j+1/2)*dy, z=(k+1/2)*dz``，而 ``Hy`` 在
   ``x=i*dx, y=(j+1/2)*dy, z=k*dz``。这样做可以让差分 curl 的每一项都有机会被测到。

   .. code-block:: fortran

      lx = real(nx0)*dx0
      ly = real(ny0)*dy0
      lz = real(nz0)*dz0
      kx = 2.0*pi/lx
      ky = 2.0*pi/ly
      kz = 2.0*pi/lz

      do k = 0, nz0
      do j = 0, ny0
      do i = 0, nx0
          x = real(i)*dx0
          y = (real(j)+0.5)*dy0
          z = (real(k)+0.5)*dz0
          Ex(i,j,k) = 0.26*sin(kx*x+0.2)*cos(ky*y+0.3)*cos(kz*z+0.1) + &
                      0.08*cos(2.0*kx*x-0.4)*sin(ky*y)*sin(kz*z+0.5)

          x = (real(i)+0.5)*dx0
          y = real(j)*dy0
          z = (real(k)+0.5)*dz0
          Ey(i,j,k) = 0.31*cos(kx*x+0.1)*sin(ky*y+0.2)*cos(kz*z+0.4) + &
                      0.06*sin(2.0*ky*y+0.7)*sin(kx*x)*cos(kz*z)

          x = (real(i)+0.5)*dx0
          y = (real(j)+0.5)*dy0
          z = real(k)*dz0
          Ez(i,j,k) = 0.29*cos(kx*x+0.5)*cos(ky*y+0.6)*sin(kz*z+0.3) + &
                      0.09*sin(kx*x-0.2)*sin(2.0*ky*y)*cos(kz*z+0.2)

          x = (real(i)+0.5)*dx0
          y = real(j)*dy0
          z = real(k)*dz0
          Hx(i,j,k) = 0.23*sin(kx*x+0.15)*cos(ky*y+0.35)*sin(kz*z+0.55) + &
                      0.07*cos(2.0*kz*z+0.2)*cos(kx*x)*sin(ky*y)

          x = real(i)*dx0
          y = (real(j)+0.5)*dy0
          z = real(k)*dz0
          Hy(i,j,k) = 0.27*cos(kx*x+0.45)*sin(ky*y+0.25)*sin(kz*z+0.05) + &
                      0.05*sin(2.0*kx*x)*cos(ky*y)*cos(kz*z+0.3)

          x = real(i)*dx0
          y = real(j)*dy0
          z = (real(k)+0.5)*dz0
          Hz(i,j,k) = 0.24*sin(kx*x+0.65)*sin(ky*y+0.15)*cos(kz*z+0.45) + &
                      0.08*cos(2.0*ky*y-0.1)*sin(kx*x+0.3)*sin(kz*z)
      end do
      end do
      end do

   ``E-step`` 展示了这个测试的核心结构。第一条路径是“生产内核路径”：复制初始场到 ``*_num``，然后直接调用真正要验证的
   ``sub_E03_fdtd_3d_cartesian_E``。注意参数里先给出全数组范围 ``0:nx,0:ny,0:nz``，再给出实际更新范围
   ``1:nx-1,1:ny-1,1:nz-1``；这是为了只在有完整差分 stencil 的内部点更新 ``E``。

   .. code-block:: fortran

      Ex_num = Ex0; Ey_num = Ey0; Ez_num = Ez0
      Hx_num = Hx0; Hy_num = Hy0; Hz_num = Hz0
      call sub_E03_fdtd_3d_cartesian_E(0,nx,0,ny,0,nz,1,nx-1,1,ny-1,1,nz-1, &
          Ex_num,Ey_num,Ez_num,Hx_num,Hy_num,Hz_num,dt,dx,dy,dz,ep)

   第二条路径是“参考公式路径”：复制初始场到 ``*_ref``，然后用测试文件内部的 ``ref_update_cartesian_E`` 计算期望答案。
   这段参考代码不调用生产子程序，而是把离散 curl 直接写出来，所以它能独立检查被测内核是否把差分方向、符号和索引写对。

   .. code-block:: fortran

      Ex_ref = Ex0; Ey_ref = Ey0; Ez_ref = Ez0
      call ref_update_cartesian_E(nx,ny,nz,1,nx-1,1,ny-1,1,nz-1, &
          Ex0,Ey0,Ez0,Hx0,Hy0,Hz0,dt,dx,dy,dz,ep,Ex_ref,Ey_ref,Ez_ref)

      curl_x = (Hz_old(i,j,k)-Hz_old(i,j-1,k))/dy0 - &
               (Hy_old(i,j,k)-Hy_old(i,j,k-1))/dz0
      Ex_new(i,j,k) = Ex_old(i,j,k) + dt0/ep0*curl_x

      curl_y = (Hx_old(i,j,k)-Hx_old(i,j,k-1))/dz0 - &
               (Hz_old(i,j,k)-Hz_old(i-1,j,k))/dx0
      Ey_new(i,j,k) = Ey_old(i,j,k) + dt0/ep0*curl_y

      curl_z = (Hy_old(i,j,k)-Hy_old(i-1,j,k))/dx0 - &
               (Hx_old(i,j,k)-Hx_old(i,j-1,k))/dy0
      Ez_new(i,j,k) = Ez_old(i,j,k) + dt0/ep0*curl_z

   最后，测试逐点逐分量比较生产结果和参考结果。边界点使用稍宽松的容差，内部点使用更严格的容差；如果任一点超过阈值，
   ``report_check`` 会增加 ``n_failed``，最终 ``RESULT`` 就会变成 ``FAIL``。

   .. code-block:: fortran

      call check_cartesian_E_domain(nx,ny,nz,Ex_ref,Ey_ref,Ez_ref, &
          Ex_num,Ey_num,Ez_num,rep)

      tol = tol_interior
      if (i == 0 .or. i == nx0 .or. j == 0 .or. j == ny0 .or. &
          k == 0 .or. k == nz0) tol = tol_boundary
      call report_check(rep,'domain','Ex',i,j,k, &
          Ex_ref(i,j,k),Ex_num(i,j,k),tol,tol)

   ``H-step`` 的逻辑完全类似，只是被测对象换成 ``sub_E03_fdtd_3d_cartesian_H``，参考对象换成
   ``ref_update_cartesian_H``。最后的 ``full-step`` 会先做一次 E 更新、再做一次 H 更新；参考路径也按同样顺序计算，
   其中 H 参考公式使用已经更新过的 E 参考场。这样测试打开了黑箱：生产内核负责给出数值结果，测试文件中的独立 stencil
   负责给出答案，二者差值决定 PASS/FAIL。

   .. rubric:: 重点调用方式

   .. code-block:: text

      call sub_*_H(..., E_fields, H_fields, dt, spacing, mu)
      call compare_against_explicit_H_formula(...)
      call sub_*_E(..., E_fields, H_fields, dt, spacing, ep)
      call compare_against_explicit_E_formula(...)

   .. rubric:: 结果判断

   通过时每个子测试的 ``n_failed`` 应为 ``0``，误差应接近机器精度。参考摘要：

   .. code-block:: text

      2D RZ TMz full-step: max_abs_err=1.7764e-15, n_failed=0
      2D RZ TEz full-step: max_abs_err=0,          n_failed=0
      3D Cartesian full-step: max_abs_err=0,       n_failed=0
      3D Cyl m=0 full-step: max_abs_err=0,         n_failed=0
      3D Cyl m=1 full-step: max_abs_err=0,         n_failed=0

   .. rubric:: 常见误读

   单步测试只说明当前离散公式实现和参考 stencil 一致；它不能证明长期稳定，也不能证明 CPML 吸收效果。
   2D RZ 的 TEz/TMz 以实际场分量为准：TEz 是 ``Ephi,Hr,Hz``，TMz 是 ``Er,Hphi,Ez``。

   .. include:: _contributors_zh.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   ``case_fdtd_single_step_formula`` is the most local FDTD formula check. It
   advances one step and compares production ``E``/``H`` kernels against
   explicit stencil formulas written in the test. It does not cover CPML,
   sources, particles, collisions, or filtering.

   .. rubric:: Covered Routines

   - :doc:`E01 TEz/TMz </rst_files/E_Maxwell/E01_Maxwell_2Drz>`:
     ``sub_E01_fdtd_2d_rz_tez_*`` and ``sub_E01_fdtd_2d_rz_tmz_*``.
   - :doc:`E02 3D cylindrical </rst_files/E_Maxwell/E02_Maxwell_3Drtz>`:
     ``sub_E02_fdtd_3d_cylindrical_E`` and ``sub_E02_fdtd_3d_cylindrical_H``.
   - :doc:`E03 3D Cartesian </rst_files/E_Maxwell/E03_Maxwell_3Dxyz>`:
     ``sub_E03_fdtd_3d_cartesian_E`` and ``sub_E03_fdtd_3d_cartesian_H``.

   .. rubric:: Files

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - File
        - Role
      * - ``test_*_single_step.f90``
        - Five main checks: 2D RZ TEz, 2D RZ TMz, 3D Cartesian, 3D cylindrical ``m=0``, and ``m=1``.
      * - ``test_single_step_utils.f90``
        - Error statistics, PGM error-map output, and shared helpers.
      * - ``make.sh`` / ``run.sh`` / ``clean.sh``
        - Build, run all checks, and remove generated objects/executables/maps.
      * - ``*.pgm``
        - Grayscale error maps for E-step, H-step, and full-step diagnostics.

   .. rubric:: Run Command

   .. code-block:: bash

      source ~/.venv/bin/activate
      cd tests/005_maxwell/case_fdtd_single_step_formula
      bash run.sh

   .. rubric:: Main Flow

   1. Build deterministic smooth initial fields for each geometry.
   2. Keep ``*_old`` fields as inputs for the reference formulas.
   3. Advance one production ``H`` or ``E`` step.
   4. Compute the same update with explicit stencil formulas.
   5. Report ``max_abs_err``, ``max_rel_err``, and ``n_failed``.
   6. Write PGM error projections for localization.

   .. rubric:: Example: 3D Cartesian Single-Step Test

   ``test_3d_cartesian_single_step.f90`` is the simplest representative case.
   It starts with a small grid and fixed material/time-step parameters. The grid
   is small so the formula check is fast; the constants are fixed so every
   regression run is reproducible.

   .. code-block:: fortran

      integer, parameter :: nx = 10, ny = 9, nz = 8
      real, parameter :: dx = 0.08, dy = 0.11, dz = 0.09
      real, parameter :: dt = 0.35e-10
      real, parameter :: ep = 8.854187817e-12
      real, parameter :: mu = 1.2566370614e-6

      call init_staggered_periodic_fields(nx,ny,nz,dx,dy,dz, &
          Ex0,Ey0,Ez0,Hx0,Hy0,Hz0)

   The initializer is not trying to build one exact physical solution. Its job
   is to fill all six components with smooth, deterministic, nontrivial values.
   Each component is sampled at its own Yee-staggered position: for example,
   ``Ex`` uses ``x=i*dx, y=(j+1/2)*dy, z=(k+1/2)*dz``, while ``Hy`` uses
   ``x=i*dx, y=(j+1/2)*dy, z=k*dz``. That makes all curl terms active.

   .. code-block:: fortran

      lx = real(nx0)*dx0
      ly = real(ny0)*dy0
      lz = real(nz0)*dz0
      kx = 2.0*pi/lx
      ky = 2.0*pi/ly
      kz = 2.0*pi/lz

      do k = 0, nz0
      do j = 0, ny0
      do i = 0, nx0
          x = real(i)*dx0
          y = (real(j)+0.5)*dy0
          z = (real(k)+0.5)*dz0
          Ex(i,j,k) = 0.26*sin(kx*x+0.2)*cos(ky*y+0.3)*cos(kz*z+0.1) + &
                      0.08*cos(2.0*kx*x-0.4)*sin(ky*y)*sin(kz*z+0.5)

          x = (real(i)+0.5)*dx0
          y = real(j)*dy0
          z = (real(k)+0.5)*dz0
          Ey(i,j,k) = 0.31*cos(kx*x+0.1)*sin(ky*y+0.2)*cos(kz*z+0.4) + &
                      0.06*sin(2.0*ky*y+0.7)*sin(kx*x)*cos(kz*z)

          x = (real(i)+0.5)*dx0
          y = (real(j)+0.5)*dy0
          z = real(k)*dz0
          Ez(i,j,k) = 0.29*cos(kx*x+0.5)*cos(ky*y+0.6)*sin(kz*z+0.3) + &
                      0.09*sin(kx*x-0.2)*sin(2.0*ky*y)*cos(kz*z+0.2)

          x = (real(i)+0.5)*dx0
          y = real(j)*dy0
          z = real(k)*dz0
          Hx(i,j,k) = 0.23*sin(kx*x+0.15)*cos(ky*y+0.35)*sin(kz*z+0.55) + &
                      0.07*cos(2.0*kz*z+0.2)*cos(kx*x)*sin(ky*y)

          x = real(i)*dx0
          y = (real(j)+0.5)*dy0
          z = real(k)*dz0
          Hy(i,j,k) = 0.27*cos(kx*x+0.45)*sin(ky*y+0.25)*sin(kz*z+0.05) + &
                      0.05*sin(2.0*kx*x)*cos(ky*y)*cos(kz*z+0.3)

          x = real(i)*dx0
          y = real(j)*dy0
          z = (real(k)+0.5)*dz0
          Hz(i,j,k) = 0.24*sin(kx*x+0.65)*sin(ky*y+0.15)*cos(kz*z+0.45) + &
                      0.08*cos(2.0*ky*y-0.1)*sin(kx*x+0.3)*sin(kz*z)
      end do
      end do
      end do

   The ``E-step`` shows the core testing pattern. The production path copies
   the initial fields into ``*_num`` and calls the actual kernel under test,
   ``sub_E03_fdtd_3d_cartesian_E``. The first index range describes the full arrays;
   the second index range, ``1:nx-1,1:ny-1,1:nz-1``, is the interior update
   domain where the E-field stencil has all required neighbors.

   .. code-block:: fortran

      Ex_num = Ex0; Ey_num = Ey0; Ez_num = Ez0
      Hx_num = Hx0; Hy_num = Hy0; Hz_num = Hz0
      call sub_E03_fdtd_3d_cartesian_E(0,nx,0,ny,0,nz,1,nx-1,1,ny-1,1,nz-1, &
          Ex_num,Ey_num,Ez_num,Hx_num,Hy_num,Hz_num,dt,dx,dy,dz,ep)

   The reference path copies the same initial fields into ``*_ref`` and calls a
   test-local routine, ``ref_update_cartesian_E``. That routine does not call
   the production implementation; it writes the discrete curl formulas directly,
   which is what lets the test catch sign, direction, or index mistakes.

   .. code-block:: fortran

      Ex_ref = Ex0; Ey_ref = Ey0; Ez_ref = Ez0
      call ref_update_cartesian_E(nx,ny,nz,1,nx-1,1,ny-1,1,nz-1, &
          Ex0,Ey0,Ez0,Hx0,Hy0,Hz0,dt,dx,dy,dz,ep,Ex_ref,Ey_ref,Ez_ref)

      curl_x = (Hz_old(i,j,k)-Hz_old(i,j-1,k))/dy0 - &
               (Hy_old(i,j,k)-Hy_old(i,j,k-1))/dz0
      Ex_new(i,j,k) = Ex_old(i,j,k) + dt0/ep0*curl_x

      curl_y = (Hx_old(i,j,k)-Hx_old(i,j,k-1))/dz0 - &
               (Hz_old(i,j,k)-Hz_old(i-1,j,k))/dx0
      Ey_new(i,j,k) = Ey_old(i,j,k) + dt0/ep0*curl_y

      curl_z = (Hy_old(i,j,k)-Hy_old(i-1,j,k))/dx0 - &
               (Hx_old(i,j,k)-Hx_old(i,j-1,k))/dy0
      Ez_new(i,j,k) = Ez_old(i,j,k) + dt0/ep0*curl_z

   Finally, the test compares the production and reference arrays point by
   point and component by component. Boundary points use a slightly looser
   tolerance; interior points use the stricter tolerance. Any point outside the
   tolerance increments ``n_failed``, which eventually turns ``RESULT`` into
   ``FAIL``.

   .. code-block:: fortran

      call check_cartesian_E_domain(nx,ny,nz,Ex_ref,Ey_ref,Ez_ref, &
          Ex_num,Ey_num,Ez_num,rep)

      tol = tol_interior
      if (i == 0 .or. i == nx0 .or. j == 0 .or. j == ny0 .or. &
          k == 0 .or. k == nz0) tol = tol_boundary
      call report_check(rep,'domain','Ex',i,j,k, &
          Ex_ref(i,j,k),Ex_num(i,j,k),tol,tol)

   The ``H-step`` repeats the same idea with ``sub_E03_fdtd_3d_cartesian_H`` and
   ``ref_update_cartesian_H``. The final ``full-step`` runs E first and H
   second; the reference path follows the same order and uses the updated
   reference E field when computing the H reference. This is the whole test in
   miniature: the production kernel produces the numerical answer, an
   independent stencil in the test produces the expected answer, and their
   difference decides PASS/FAIL.

   .. rubric:: Core Call Pattern

   .. code-block:: text

      call sub_*_H(..., E_fields, H_fields, dt, spacing, mu)
      call compare_against_explicit_H_formula(...)
      call sub_*_E(..., E_fields, H_fields, dt, spacing, ep)
      call compare_against_explicit_E_formula(...)

   .. rubric:: Result Interpretation

   Passing runs should report ``n_failed=0`` with near-machine-precision errors:

   .. code-block:: text

      2D RZ TMz full-step: max_abs_err=1.7764e-15, n_failed=0
      2D RZ TEz full-step: max_abs_err=0,          n_failed=0
      3D Cartesian full-step: max_abs_err=0,       n_failed=0
      3D Cyl m=0 full-step: max_abs_err=0,         n_failed=0
      3D Cyl m=1 full-step: max_abs_err=0,         n_failed=0

   .. rubric:: Common Pitfall

   A one-step test proves agreement with the intended stencil, not long-run
   stability or CPML absorption. For 2D RZ, use the physical components:
   TEz is ``Ephi,Hr,Hz`` and TMz is ``Er,Hphi,Ez``.

   .. include:: _contributors_en.inc
