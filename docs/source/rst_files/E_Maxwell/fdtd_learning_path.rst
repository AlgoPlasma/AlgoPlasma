FDTD Learning Path
==================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这页解决什么问题

   本页面向第一次接触 ``E_Maxwell`` 的读者。它不是完整电磁场教材，而是帮助你把
   Maxwell 旋度方程、Yee 网格、leapfrog 时间推进、柱坐标轴线处理、CPML 边界和 AlgoPlasma
   的 Fortran routine 对上号。读完后，应该能知道该先看哪一页、哪些公式对应哪些代码、
   以及测试为什么能说明实现是可信的。

   .. rubric:: 推荐学习顺序

   .. list-table::
      :header-rows: 1
      :widths: 18 44 38

      * - 步骤
        - 先理解什么
        - 建议阅读
      * - 1
        - FDTD 的基本图景：电场和磁场交错存储，交替推进。
        - 本页“核心图景”，再看 :doc:`E03 Cartesian notes <E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes>`
      * - 2
        - 一个最简单的 3D Cartesian 六分量更新。
        - :doc:`E03_Maxwell_3Dxyz <E03_Maxwell_3Dxyz>` 和其中的 ``sub_E03_fdtd_3d_cartesian_*`` API 页
      * - 3
        - 轴对称 ``(r,z)`` 如何拆成两组互不耦合的分量。
        - :doc:`E01 axisymmetric notes <E01_Maxwell_2Drz/fdtd_2d_rz_axisymmetric_notes>`
      * - 4
        - 完整 3D 柱坐标多出来的 ``phi`` 方向、metric 项和轴线闭合。
        - :doc:`E02 cylindrical notes <E02_Maxwell_3Drtz/fdtd_3d_cylindrical_notes>`
      * - 5
        - CPML 如何把有限区域边界变成吸收层。
        - :doc:`CPML cookbook <cpml_cookbook>`
      * - 6
        - 怎样验证公式、稳定性和边界吸收效果。
        - :doc:`FDTD Testing Guide <fdtd_testing_guide>` 和 :doc:`005_maxwell tests </tests/005_maxwell/index>`

   .. rubric:: 核心图景

   ``E_Maxwell`` 的普通 FDTD routine 只做一件事：把 Maxwell curl 方程离散成局部
   stencil，并对给定数组范围原位更新场量。完整求解器还需要调用方组织边界、源项、
   ghost cell、诊断和时间步循环。

   - **空间交错。** 电场分量 :math:`E_a` 放在该方向的边上，磁场分量
     :math:`H_a` 放在另外两个横向方向的半格位置。这样每个 curl 分量都能用最近邻中心差分。
   - **时间交错。** 一般先用 :math:`\mathbf{E}^n` 更新
     :math:`\mathbf{H}^{n+1/2}`，再用 :math:`\mathbf{H}^{n+1/2}`
     更新 :math:`\mathbf{E}^{n+1}`。这就是 leapfrog。
   - **索引不是坐标。** :math:`i,j,k` 是逻辑网格指标；
     :math:`x,y,z` 或 :math:`r,\phi,z` 是物理坐标方向。半指标表示该分量放在两个网格点之间。
   - **边界不在普通 stencil 里。** 更新式会访问相邻点；调用前必须准备好周期 wrap、
     物理边界值或 MPI ghost cell。
   - **稳定性不由 routine 检查。** ``dt`` 必须由调用方按 CFL 条件和介质波速选择。
     AlgoPlasma routine 使用传入的 ``dt``，不会自动判断是否稳定。
   - **材料参数是调用方约定。** 当前核心 routine 多使用标量 ``ep`` 和 ``mu``；
     若要非均匀介质，需要在外层分块调用，或扩展为按 Yee 位置采样的材料数组。

   .. rubric:: 初学者最容易混的点

   - ``E01`` 源码中的 ``tez`` / ``tmz`` 已按相对于 z 轴的物理模式命名：``tez`` 是 ``Ephi/Hr/Hz``，``tmz`` 是 ``Er/Ez/Hphi``。
   - 柱坐标的 :math:`1/r` 和 :math:`(1/r)\partial_r(r\cdot)` 不是普通常数因子；
     它们决定了径向半径位置和 :math:`r=0` 轴线闭合。
   - CPML routine 不是“在普通 FDTD 更新后再加一次”的补丁；在吸收层区域，应使用
     CPML 版本替代对应的普通 curl 更新，避免重复更新同一场量。
   - 本库使用 Fortran 默认 ``real``。如果需要双精度，通常由编译选项决定，例如
     GNU Fortran 可使用 ``-fdefault-real-8``。

   .. rubric:: 建议练习

   1. 先在 Cartesian notes 中手推 :math:`E_x` 的更新式，确认它只使用
      :math:`H_y` 和 :math:`H_z` 的相邻差分。
   2. 打开 ``sub_E03_fdtd_3d_cartesian_E`` API 页，对照参数表找出 ``Ex``、``Hy``、``Hz``、
      ``dt``、``dy``、``dz`` 在公式中的位置。
   3. 运行 ``tests/005_maxwell/case_fdtd_single_step_formula``，看单步 stencil 是否接近机器精度。
   4. 再看 E01 的 :math:`r=0` 轴线公式，理解为什么不能直接把内部点公式套在轴线上。
   5. 最后运行一个 visualization case，把公式更新和波传播图像连起来。

.. container:: ap-lang ap-lang-en

   .. rubric:: What This Page Is For

   This page is for readers approaching ``E_Maxwell`` for the first time. It is
   not a full electromagnetics textbook; it is a bridge from Maxwell curl
   equations to AlgoPlasma's Yee-grid, leapfrog, cylindrical-axis, CPML, and Fortran
   routine documentation. After reading it, you should know what to read first,
   which formulas correspond to which code paths, and why the tests support the
   implementation.

   .. rubric:: Suggested Learning Order

   .. list-table::
      :header-rows: 1
      :widths: 18 44 38

      * - Step
        - Understand first
        - Suggested pages
      * - 1
        - The FDTD mental model: electric and magnetic fields are staggered and advanced alternately.
        - This page, then :doc:`E03 Cartesian notes <E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes>`
      * - 2
        - The simplest full 3D Cartesian six-component update.
        - :doc:`E03_Maxwell_3Dxyz <E03_Maxwell_3Dxyz>` and the ``sub_E03_fdtd_3d_cartesian_*`` API pages
      * - 3
        - How axisymmetric ``(r,z)`` equations split into two uncoupled field sets.
        - :doc:`E01 axisymmetric notes <E01_Maxwell_2Drz/fdtd_2d_rz_axisymmetric_notes>`
      * - 4
        - The extra ``phi`` direction, metric factors, and axis closure in full 3D cylindrical coordinates.
        - :doc:`E02 cylindrical notes <E02_Maxwell_3Drtz/fdtd_3d_cylindrical_notes>`
      * - 5
        - How CPML turns finite-domain edges into absorbing layers.
        - :doc:`CPML cookbook <cpml_cookbook>`
      * - 6
        - How formulas, stability, and boundary absorption are verified.
        - :doc:`FDTD Testing Guide <fdtd_testing_guide>` and :doc:`005_maxwell tests </tests/005_maxwell/index>`

   .. rubric:: Core Mental Model

   Plain FDTD routines in ``E_Maxwell`` do one job: discretize Maxwell curl
   equations into local stencils and update field arrays in place over a caller
   supplied index range. A complete solver still owns boundaries, sources,
   ghost cells, diagnostics, and the time loop.

   - **Space staggering.** Electric component :math:`E_a` is collocated with
     the edge in direction :math:`a`; magnetic component :math:`H_a` is shifted
     by half a cell in the two transverse directions. This makes each curl term
     a nearest-neighbor centered difference.
   - **Time staggering.** Usually :math:`\mathbf{E}^n` advances
     :math:`\mathbf{H}^{n+1/2}`, then :math:`\mathbf{H}^{n+1/2}` advances
     :math:`\mathbf{E}^{n+1}`. This is leapfrog.
   - **Indices are not coordinates.** :math:`i,j,k` are logical grid indices;
     :math:`x,y,z` or :math:`r,\phi,z` are physical coordinate directions. Half
     indices mean that a component is stored between neighboring grid points.
   - **Boundaries are outside the plain stencil.** Update formulas read neighbor
     cells; periodic wrapping, physical boundary values, or MPI ghost cells must
     be prepared before the call.
   - **Stability is not checked by the routine.** The caller must choose ``dt``
     from the CFL condition and wave speed. AlgoPlasma routines simply use the input
     ``dt``.
   - **Material parameters are caller conventions.** Current core routines
     mostly use scalar ``ep`` and ``mu``. Spatially varying media require outer
     blocking or future component-aligned material arrays.

   .. rubric:: Common Beginner Traps

   - In ``E01``, ``tez`` / ``tmz`` now follow the axial physical mode names: ``tez`` is ``Ephi/Hr/Hz`` and ``tmz`` is ``Er/Ez/Hphi``.
   - Cylindrical :math:`1/r` and :math:`(1/r)\partial_r(r\cdot)` terms are not
     ordinary constants; they determine radial metric locations and the
     :math:`r=0` axis closure.
   - A CPML routine is not a correction to apply after a normal FDTD update. In
     the absorbing strip, use the CPML update instead of the corresponding plain
     curl update to avoid updating the same field twice.
   - The library uses Fortran default ``real``. Double precision is normally a
     compile-time choice, for example ``-fdefault-real-8`` with GNU Fortran.

   .. rubric:: Suggested Exercises

   1. Derive the :math:`E_x` update from the Cartesian notes and check that it
      uses only neighbor differences of :math:`H_y` and :math:`H_z`.
   2. Open the ``sub_E03_fdtd_3d_cartesian_E`` API page and map ``Ex``, ``Hy``,
      ``Hz``, ``dt``, ``dy``, and ``dz`` back to the formula.
   3. Run ``tests/005_maxwell/case_fdtd_single_step_formula`` and inspect the
      near-machine-precision one-step stencil errors.
   4. Study the E01 :math:`r=0` axis formula and note why the interior formula
      cannot be used directly on the axis.
   5. Run one visualization case to connect the update formulas to wave
      propagation.
