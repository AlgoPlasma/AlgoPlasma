E02_Maxwell_3Drtz
=================

.. toctree::
    :maxdepth: 1
    :hidden:

    E02_Maxwell_3Drtz/fdtd_3d_cylindrical_notes
    E02_Maxwell_3Drtz/mod_E02_fdtd_3d_cylindrical
    E02_Maxwell_3Drtz/sub_E02_fdtd_3d_cylindrical_E
    E02_Maxwell_3Drtz/sub_E02_fdtd_3d_cylindrical_H
    E02_Maxwell_3Drtz/mod_E02_cpml_3d_cylindrical

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``E02_Maxwell_3Drtz`` 是完整 3D 柱坐标 ``(r,phi,z)`` Yee-FDTD 内核，保留
   :math:`\partial/\partial\phi` 项并更新全部六个场分量。它适合几何或物理结构天然以柱坐标描述的场问题。

   .. rubric:: 推荐路径

   - 初学完整柱坐标公式：先看 :doc:`3D cylindrical notes <E02_Maxwell_3Drtz/fdtd_3d_cylindrical_notes>`。
   - 准备接入代码：先看 :doc:`FDTD Usage Cookbook <fdtd_usage_cookbook>`，再看 ``sub_E02_fdtd_3d_cylindrical_*``。
   - 使用吸收边界：先看 :doc:`CPML Cookbook <cpml_cookbook>`，再看 ``sub_E02_cpml_3d_cylindrical_*``。
   - 验证改动：优先运行 ``m=0`` equivalence、MMS、stability 和 cylindrical CPML wave-packet 测试。

   .. rubric:: 最小调用顺序

   .. code-block:: fortran

      call fill_E_boundaries_or_ghosts(...)
      call apply_phi_periodic_wrap(...)
      call sub_E02_fdtd_3d_cylindrical_H(..., Er, Ephi, Ez, Hr, Hphi, Hz, dt, dr, dphi, dz, mu)

      call fill_H_boundaries_or_ghosts(...)
      call apply_axis_and_phi_special_handling(...)
      call sub_E02_fdtd_3d_cylindrical_E(..., Er, Ephi, Ez, Hr, Hphi, Hz, dt, dr, dphi, dz, ep)

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 角色
      * - :doc:`3D Cylindrical (rtz) FDTD <E02_Maxwell_3Drtz/fdtd_3d_cylindrical_notes>`
        - 完整柱坐标 Yee 网格、metric 项、轴线闭合和 3D 更新公式说明。
      * - :doc:`mod_E02_fdtd_3d_cylindrical.f90 <E02_Maxwell_3Drtz/mod_E02_fdtd_3d_cylindrical>`
        - 模块包装文件，include 电场和磁场更新核。
      * - :doc:`sub_E02_fdtd_3d_cylindrical_E.f90 <E02_Maxwell_3Drtz/sub_E02_fdtd_3d_cylindrical_E>`
        - 从 ``Hr/Hphi/Hz`` 更新 ``Er/Ephi/Ez``。
      * - :doc:`sub_E02_fdtd_3d_cylindrical_H.f90 <E02_Maxwell_3Drtz/sub_E02_fdtd_3d_cylindrical_H>`
        - 从 ``Er/Ephi/Ez`` 更新 ``Hr/Hphi/Hz``。
      * - :doc:`mod_E02_cpml_3d_cylindrical.f90 <E02_Maxwell_3Drtz/mod_E02_cpml_3d_cylindrical>`
        - 3D 柱坐标 CPML 模块包装文件，include 电场和磁场 CPML 更新核。
      * - :doc:`sub_E02_cpml_3d_cylindrical_E.f90 <E02_Maxwell_3Drtz/sub_E02_cpml_3d_cylindrical_E>`
        - 在柱坐标 CPML 区域中更新 ``Er/Ephi/Ez`` 及其 memory variables。
      * - :doc:`sub_E02_cpml_3d_cylindrical_H.f90 <E02_Maxwell_3Drtz/sub_E02_cpml_3d_cylindrical_H>`
        - 在柱坐标 CPML 区域中更新 ``Hr/Hphi/Hz`` 及其 memory variables。

   .. rubric:: 调用注意

   ``phi`` 方向通常由调用方做周期 wrap/ghost fill。径向 metric 项必须使用正确的节点或半节点半径；
   轴线附近的更新不能直接套用远离轴线的点值公式。CPML memory variables 需要跨时间步保留。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">刘哲，赵隐剑 · 哈尔滨工业大学 · 2026/04/09</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``E02_Maxwell_3Drtz`` is the full 3D cylindrical ``(r,phi,z)`` Yee-FDTD
   kernel. It retains :math:`\partial/\partial\phi` terms and updates all six
   field components, making it suitable for field problems naturally expressed in
   cylindrical geometry.

   .. rubric:: Recommended Path

   - To learn the full cylindrical formulas, start with
     :doc:`3D cylindrical notes <E02_Maxwell_3Drtz/fdtd_3d_cylindrical_notes>`.
   - To integrate code, read :doc:`FDTD Usage Cookbook <fdtd_usage_cookbook>`
     and then the ``sub_E02_fdtd_3d_cylindrical_*`` pages.
   - To use absorbing boundaries, read :doc:`CPML Cookbook <cpml_cookbook>` and
     then the ``sub_E02_cpml_3d_cylindrical_*`` pages.
   - To validate changes, prioritize m=0 equivalence, MMS, stability, and
     cylindrical CPML wave-packet tests.

   .. rubric:: Minimal Call Order

   .. code-block:: fortran

      call fill_E_boundaries_or_ghosts(...)
      call apply_phi_periodic_wrap(...)
      call sub_E02_fdtd_3d_cylindrical_H(..., Er, Ephi, Ez, Hr, Hphi, Hz, dt, dr, dphi, dz, mu)

      call fill_H_boundaries_or_ghosts(...)
      call apply_axis_and_phi_special_handling(...)
      call sub_E02_fdtd_3d_cylindrical_E(..., Er, Ephi, Ez, Hr, Hphi, Hz, dt, dr, dphi, dz, ep)

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`3D Cylindrical (rtz) FDTD <E02_Maxwell_3Drtz/fdtd_3d_cylindrical_notes>`
        - Notes for the full cylindrical Yee grid, metric terms, axis closure, and 3D update formulas.
      * - :doc:`mod_E02_fdtd_3d_cylindrical.f90 <E02_Maxwell_3Drtz/mod_E02_fdtd_3d_cylindrical>`
        - Module wrapper including electric and magnetic update kernels.
      * - :doc:`sub_E02_fdtd_3d_cylindrical_E.f90 <E02_Maxwell_3Drtz/sub_E02_fdtd_3d_cylindrical_E>`
        - Updates ``Er/Ephi/Ez`` from ``Hr/Hphi/Hz``.
      * - :doc:`sub_E02_fdtd_3d_cylindrical_H.f90 <E02_Maxwell_3Drtz/sub_E02_fdtd_3d_cylindrical_H>`
        - Updates ``Hr/Hphi/Hz`` from ``Er/Ephi/Ez``.
      * - :doc:`mod_E02_cpml_3d_cylindrical.f90 <E02_Maxwell_3Drtz/mod_E02_cpml_3d_cylindrical>`
        - 3D cylindrical CPML module wrapper including electric and magnetic CPML kernels.
      * - :doc:`sub_E02_cpml_3d_cylindrical_E.f90 <E02_Maxwell_3Drtz/sub_E02_cpml_3d_cylindrical_E>`
        - Updates ``Er/Ephi/Ez`` and memory variables in the cylindrical CPML region.
      * - :doc:`sub_E02_cpml_3d_cylindrical_H.f90 <E02_Maxwell_3Drtz/sub_E02_cpml_3d_cylindrical_H>`
        - Updates ``Hr/Hphi/Hz`` and memory variables in the cylindrical CPML region.

   .. rubric:: Calling Notes

   The ``phi`` direction is normally wrapped or ghost-filled by the caller. Radial
   metric terms must use the correct node or half-node radius, and axis-near
   updates cannot reuse the pointwise formulas used away from the axis. CPML
   memory variables must persist across time steps.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zhe LIU, Yinjian ZHAO · Harbin Institute of Technology · 2026/04/09</p>
      </div>
