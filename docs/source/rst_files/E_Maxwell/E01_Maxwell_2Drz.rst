E01_Maxwell_2Drz
================

.. toctree::
    :maxdepth: 1
    :hidden:

    E01_Maxwell_2Drz/fdtd_2d_rz_axisymmetric_notes
    E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tmz
    E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tez
    E01_Maxwell_2Drz/sub_E01_fdtd_2d_rz_tez_E
    E01_Maxwell_2Drz/sub_E01_fdtd_2d_rz_tez_H
    E01_Maxwell_2Drz/sub_E01_fdtd_2d_rz_tmz_E
    E01_Maxwell_2Drz/sub_E01_fdtd_2d_rz_tmz_H
    E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tez
    E01_Maxwell_2Drz/sub_E01_cpml_2d_rz_tez_E
    E01_Maxwell_2Drz/sub_E01_cpml_2d_rz_tez_H
    E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tmz
    E01_Maxwell_2Drz/sub_E01_cpml_2d_rz_tmz_E
    E01_Maxwell_2Drz/sub_E01_cpml_2d_rz_tmz_H

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``E01_Maxwell_2Drz`` 是轴对称 2D ``(r,z)`` FDTD 内核。它把完整柱坐标 Maxwell 方程在
   :math:`\partial/\partial\phi=0` 条件下拆成两个互不耦合的子系统：TMz ``Er, Hphi, Ez`` 和 TEz ``Ephi, Hr, Hz``。

   .. rubric:: 推荐路径

   - 初学公式和轴线处理：先看 :doc:`2D RZ notes <E01_Maxwell_2Drz/fdtd_2d_rz_axisymmetric_notes>`。
   - 准备调用 routine：先看 :doc:`FDTD Usage Cookbook <fdtd_usage_cookbook>`，再进入下表的具体 subroutine。
   - 使用吸收边界：先看 :doc:`CPML Cookbook <cpml_cookbook>`，再看 ``mod_E01_cpml_*`` 和 ``sub_E01_cpml_*`` 页面。
   - 验证改动：运行 ``tests/005_maxwell`` 中的 single-step、m=0 equivalence、MMS 和 CPML wave-packet 测试。

   .. rubric:: 最小调用顺序

   每个时间步通常先用整步电场更新半步磁场，再用半步磁场更新下一整步电场。若只求解一个分量组，
   只调用对应的一对 ``H`` / ``E`` routine。

   .. code-block:: fortran

      ! Ephi / Hr / Hz field set
      call sub_E01_fdtd_2d_rz_tez_H(..., Ephi, Hr, Hz, dt, dr, dz, mu)
      call fill_H_boundaries_or_ghosts(...)
      call sub_E01_fdtd_2d_rz_tez_E(..., Ephi, Hr, Hz, dt, dr, dz, ep)

      ! Er / Ha(Hphi) / Ez field set
      call sub_E01_fdtd_2d_rz_tmz_H(..., Ha, Er, Ez, dt, dr, dz, mu)
      call fill_H_boundaries_or_ghosts(...)
      call sub_E01_fdtd_2d_rz_tmz_E(..., Ha, Er, Ez, dt, dr, dz, ep)

   下表同时列出 module wrapper 和可直接调用的 subroutine 页面。module 行说明 include/use
   关系，sub 行说明实际执行的场分量更新。

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 36 64

      * - 文件
        - 角色
      * - :doc:`2D Cylindrical (rz) FDTD <E01_Maxwell_2Drz/fdtd_2d_rz_axisymmetric_notes>`
        - 2D RZ Yee 网格、TEz/TMz 拆分、轴线闭合和更新公式说明。
      * - :doc:`mod_E01_fdtd_2d_rz_tez.f90 <E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tez>`
        - FDTD TEz 分量组 module wrapper，include ``Ephi`` 和 ``Hr/Hz`` 更新核。
      * - :doc:`sub_E01_fdtd_2d_rz_tez_E.f90 <E01_Maxwell_2Drz/sub_E01_fdtd_2d_rz_tez_E>`
        - FDTD TEz 分量组电场更新核；用 ``Hr/Hz`` 更新 ``Ephi``。
      * - :doc:`sub_E01_fdtd_2d_rz_tez_H.f90 <E01_Maxwell_2Drz/sub_E01_fdtd_2d_rz_tez_H>`
        - FDTD TEz 分量组磁场更新核；用 ``Ephi`` 更新 ``Hr/Hz``。
      * - :doc:`mod_E01_fdtd_2d_rz_tmz.f90 <E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tmz>`
        - FDTD TMz 分量组 module wrapper，include ``Er/Ez`` 和 ``Ha/Hphi`` 更新核。
      * - :doc:`sub_E01_fdtd_2d_rz_tmz_E.f90 <E01_Maxwell_2Drz/sub_E01_fdtd_2d_rz_tmz_E>`
        - FDTD TMz 分量组电场更新核；用 ``Ha/Hphi`` 更新 ``Er/Ez``。
      * - :doc:`sub_E01_fdtd_2d_rz_tmz_H.f90 <E01_Maxwell_2Drz/sub_E01_fdtd_2d_rz_tmz_H>`
        - FDTD TMz 分量组磁场更新核；用 ``Er/Ez`` 更新 ``Ha/Hphi``。
      * - :doc:`mod_E01_cpml_2d_rz_tez.f90 <E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tez>`
        - CPML TEz 分量组 module wrapper，include 对应 ``E`` 和 ``H`` CPML 更新核。
      * - :doc:`sub_E01_cpml_2d_rz_tez_E.f90 <E01_Maxwell_2Drz/sub_E01_cpml_2d_rz_tez_E>`
        - CPML 电场更新核；对 ``Ephi`` 加入 split-field memory 修正，调用者需保证 ``i-1/k-1`` 相邻点可读。
      * - :doc:`sub_E01_cpml_2d_rz_tez_H.f90 <E01_Maxwell_2Drz/sub_E01_cpml_2d_rz_tez_H>`
        - CPML 磁场更新核；对 ``Hr/Hz`` 加入 split-field memory 修正，并把径向几何项留在 memory variable 外。
      * - :doc:`mod_E01_cpml_2d_rz_tmz.f90 <E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tmz>`
        - CPML TMz 分量组 module wrapper，include 对应 ``E`` 和 ``H`` CPML 更新核。
      * - :doc:`sub_E01_cpml_2d_rz_tmz_E.f90 <E01_Maxwell_2Drz/sub_E01_cpml_2d_rz_tmz_E>`
        - CPML 电场更新核；对 ``Er/Ez`` 加入 split-field memory 修正，``Ez`` 径向项要求 ``i>0``。
      * - :doc:`sub_E01_cpml_2d_rz_tmz_H.f90 <E01_Maxwell_2Drz/sub_E01_cpml_2d_rz_tmz_H>`
        - CPML 磁场更新核；对 ``Ha/Hphi`` 加入 split-field memory 修正。

   .. rubric:: 调用注意

   更新区间 ``il:iu``、``kl:ku`` 应避开未准备好的 ghost cells。轴线 ``i=0`` 有专门闭合逻辑；
   调用方应保持场数组范围、边界填充和 CPML memory variables 与更新核使用的位置一致。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">刘哲，赵隐剑 · 哈尔滨工业大学 · 2026/04/09</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``E01_Maxwell_2Drz`` contains axisymmetric 2D ``(r,z)`` FDTD kernels. Under
   :math:`\partial/\partial\phi=0`, the full cylindrical Maxwell equations split
   into two decoupled subsystems: TMz ``Er, Hphi, Ez`` and TEz ``Ephi, Hr, Hz``.

   .. rubric:: Recommended Path

   - To learn the formulas and axis handling, start with
     :doc:`2D RZ notes <E01_Maxwell_2Drz/fdtd_2d_rz_axisymmetric_notes>`.
   - To integrate routines, read :doc:`FDTD Usage Cookbook <fdtd_usage_cookbook>`
     and then open the specific subroutine page from the table below.
   - To use absorbing boundaries, read :doc:`CPML Cookbook <cpml_cookbook>` and
     then the ``mod_E01_cpml_*`` and ``sub_E01_cpml_*`` pages.
   - To validate changes, run the ``tests/005_maxwell`` single-step, m=0
     equivalence, MMS, and CPML wave-packet tests.

   .. rubric:: Minimal Call Order

   A time step usually advances half-step magnetic fields from integer-time
   electric fields, then advances the next integer-time electric fields from
   half-step magnetic fields. If you solve only one field set, call only its
   matching ``H`` / ``E`` routine pair.

   .. code-block:: fortran

      ! Ephi / Hr / Hz field set
      call sub_E01_fdtd_2d_rz_tez_H(..., Ephi, Hr, Hz, dt, dr, dz, mu)
      call fill_H_boundaries_or_ghosts(...)
      call sub_E01_fdtd_2d_rz_tez_E(..., Ephi, Hr, Hz, dt, dr, dz, ep)

      ! Er / Ha(Hphi) / Ez field set
      call sub_E01_fdtd_2d_rz_tmz_H(..., Ha, Er, Ez, dt, dr, dz, mu)
      call fill_H_boundaries_or_ghosts(...)
      call sub_E01_fdtd_2d_rz_tmz_E(..., Ha, Er, Ez, dt, dr, dz, ep)

   The table lists both module wrappers and directly callable subroutine pages.
   Module rows describe include/use relations; subroutine rows describe the
   actual field-component update performed by each kernel.

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 36 64

      * - File
        - Role
      * - :doc:`2D Cylindrical (rz) FDTD <E01_Maxwell_2Drz/fdtd_2d_rz_axisymmetric_notes>`
        - Notes for the 2D RZ Yee grid, TEz/TMz split, axis closure, and update formulas.
      * - :doc:`mod_E01_fdtd_2d_rz_tez.f90 <E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tez>`
        - FDTD TEz component group module wrapper including ``Ephi`` and ``Hr/Hz`` kernels.
      * - :doc:`sub_E01_fdtd_2d_rz_tez_E.f90 <E01_Maxwell_2Drz/sub_E01_fdtd_2d_rz_tez_E>`
        - FDTD TEz component group electric-field kernel; updates ``Ephi`` from ``Hr/Hz``.
      * - :doc:`sub_E01_fdtd_2d_rz_tez_H.f90 <E01_Maxwell_2Drz/sub_E01_fdtd_2d_rz_tez_H>`
        - FDTD TEz component group magnetic-field kernel; updates ``Hr/Hz`` from ``Ephi``.
      * - :doc:`mod_E01_fdtd_2d_rz_tmz.f90 <E01_Maxwell_2Drz/mod_E01_fdtd_2d_rz_tmz>`
        - FDTD TMz component group module wrapper including ``Er/Ez`` and ``Ha/Hphi`` kernels.
      * - :doc:`sub_E01_fdtd_2d_rz_tmz_E.f90 <E01_Maxwell_2Drz/sub_E01_fdtd_2d_rz_tmz_E>`
        - FDTD TMz component group electric-field kernel; updates ``Er/Ez`` from ``Ha/Hphi``.
      * - :doc:`sub_E01_fdtd_2d_rz_tmz_H.f90 <E01_Maxwell_2Drz/sub_E01_fdtd_2d_rz_tmz_H>`
        - FDTD TMz component group magnetic-field kernel; updates ``Ha/Hphi`` from ``Er/Ez``.
      * - :doc:`mod_E01_cpml_2d_rz_tez.f90 <E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tez>`
        - CPML TEz component group module wrapper including the corresponding ``E`` and ``H`` CPML kernels.
      * - :doc:`sub_E01_cpml_2d_rz_tez_E.f90 <E01_Maxwell_2Drz/sub_E01_cpml_2d_rz_tez_E>`
        - CPML electric-field kernel; adds split-field memory corrections to ``Ephi`` and requires readable ``i-1/k-1`` neighbors.
      * - :doc:`sub_E01_cpml_2d_rz_tez_H.f90 <E01_Maxwell_2Drz/sub_E01_cpml_2d_rz_tez_H>`
        - CPML magnetic-field kernel; adds split-field memory corrections to ``Hr/Hz`` while keeping the radial metric term outside the memory variable.
      * - :doc:`mod_E01_cpml_2d_rz_tmz.f90 <E01_Maxwell_2Drz/mod_E01_cpml_2d_rz_tmz>`
        - CPML TMz component group module wrapper including the corresponding ``E`` and ``H`` CPML kernels.
      * - :doc:`sub_E01_cpml_2d_rz_tmz_E.f90 <E01_Maxwell_2Drz/sub_E01_cpml_2d_rz_tmz_E>`
        - CPML electric-field kernel; adds split-field memory corrections to ``Er/Ez``; the ``Ez`` radial term requires ``i>0``.
      * - :doc:`sub_E01_cpml_2d_rz_tmz_H.f90 <E01_Maxwell_2Drz/sub_E01_cpml_2d_rz_tmz_H>`
        - CPML magnetic-field kernel; adds split-field memory corrections to ``Ha/Hphi``.

   .. rubric:: Calling Notes

   Update ranges ``il:iu`` and ``kl:ku`` should avoid ghost cells that have not
   been prepared. The axis ``i=0`` has dedicated closure logic; callers should
   keep field-array bounds, boundary fill, and CPML memory variables consistent
   with the locations used by the kernels.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zhe LIU, Yinjian ZHAO · Harbin Institute of Technology · 2026/04/09</p>
      </div>
