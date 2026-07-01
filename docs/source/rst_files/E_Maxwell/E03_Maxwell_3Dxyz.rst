E03_Maxwell_3Dxyz
=================

.. toctree::
    :maxdepth: 1
    :hidden:

    E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes
    E03_Maxwell_3Dxyz/mod_E03_fdtd_3d_cartesian
    E03_Maxwell_3Dxyz/sub_E03_fdtd_3d_cartesian_E
    E03_Maxwell_3Dxyz/sub_E03_fdtd_3d_cartesian_H
    E03_Maxwell_3Dxyz/mod_E03_cpml_3d_cartesian

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块定位

   ``E03_Maxwell_3Dxyz`` 是 3D Cartesian ``(x,y,z)`` Yee-FDTD 内核。它实现标准六分量 Maxwell
   curl update，并提供 3D Cartesian CPML 扩展。

   .. rubric:: 推荐路径

   - 初学 FDTD：建议先从 :doc:`3D Cartesian notes <E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes>` 开始，
     因为 Cartesian 公式最少受坐标 metric 干扰。
   - 准备接入代码：先看 :doc:`FDTD Usage Cookbook <fdtd_usage_cookbook>`，再看 ``sub_E03_fdtd_3d_cartesian_*``。
   - 使用吸收边界：先看 :doc:`CPML Cookbook <cpml_cookbook>`，再看 ``sub_E03_cpml_3d_cartesian_*``。
   - 验证改动：优先运行 Cartesian single-step、MMS、stability 和 CPML wave-packet 测试。

   .. rubric:: 最小调用顺序

   .. code-block:: fortran

      call fill_E_boundaries_or_ghosts(...)
      call sub_E03_fdtd_3d_cartesian_H(..., Ex, Ey, Ez, Hx, Hy, Hz, dt, dx, dy, dz, mu)

      call fill_H_boundaries_or_ghosts(...)
      call sub_E03_fdtd_3d_cartesian_E(..., Ex, Ey, Ez, Hx, Hy, Hz, dt, dx, dy, dz, ep)

   .. list-table:: 文件角色
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 角色
      * - :doc:`3D Cartesian (xyz) FDTD <E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes>`
        - Cartesian Yee 网格、分量位置和 3D 更新公式说明。
      * - :doc:`mod_E03_fdtd_3d_cartesian.f90 <E03_Maxwell_3Dxyz/mod_E03_fdtd_3d_cartesian>`
        - 标准 3D Cartesian FDTD 模块包装文件。
      * - :doc:`sub_E03_fdtd_3d_cartesian_E.f90 <E03_Maxwell_3Dxyz/sub_E03_fdtd_3d_cartesian_E>`
        - 从 ``Hx/Hy/Hz`` 更新 ``Ex/Ey/Ez``。
      * - :doc:`sub_E03_fdtd_3d_cartesian_H.f90 <E03_Maxwell_3Dxyz/sub_E03_fdtd_3d_cartesian_H>`
        - 从 ``Ex/Ey/Ez`` 更新 ``Hx/Hy/Hz``。
      * - :doc:`mod_E03_cpml_3d_cartesian.f90 <E03_Maxwell_3Dxyz/mod_E03_cpml_3d_cartesian>`
        - 3D Cartesian CPML split-field memory 和修正更新。
      * - :doc:`sub_E03_cpml_3d_cartesian_E.f90 <E03_Maxwell_3Dxyz/sub_E03_cpml_3d_cartesian_E>`
        - 在 3D Cartesian CPML 区域中更新电场分量及其 memory variables。
      * - :doc:`sub_E03_cpml_3d_cartesian_H.f90 <E03_Maxwell_3Dxyz/sub_E03_cpml_3d_cartesian_H>`
        - 在 3D Cartesian CPML 区域中更新磁场分量及其 memory variables。

   .. rubric:: 调用注意

   核心更新例程假设调用方已经准备好边界/ghost 数据。材料参数 ``ep`` 和 ``mu`` 应与被更新分量的位置一致；
   CPML memory variables 需要跨时间步保留。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">刘哲，赵隐剑 · 哈尔滨工业大学 · 2026/04/09</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``E03_Maxwell_3Dxyz`` is the 3D Cartesian ``(x,y,z)`` Yee-FDTD kernel. It
   implements standard six-component Maxwell curl updates and provides a 3D
   Cartesian CPML extension.

   .. rubric:: Recommended Path

   - To learn FDTD, start with
     :doc:`3D Cartesian notes <E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes>`
     because Cartesian formulas have the least coordinate-metric overhead.
   - To integrate code, read :doc:`FDTD Usage Cookbook <fdtd_usage_cookbook>`
     and then the ``sub_E03_fdtd_3d_cartesian_*`` pages.
   - To use absorbing boundaries, read :doc:`CPML Cookbook <cpml_cookbook>` and
     then the ``sub_E03_cpml_3d_cartesian_*`` pages.
   - To validate changes, prioritize Cartesian single-step, MMS, stability, and
     CPML wave-packet tests.

   .. rubric:: Minimal Call Order

   .. code-block:: fortran

      call fill_E_boundaries_or_ghosts(...)
      call sub_E03_fdtd_3d_cartesian_H(..., Ex, Ey, Ez, Hx, Hy, Hz, dt, dx, dy, dz, mu)

      call fill_H_boundaries_or_ghosts(...)
      call sub_E03_fdtd_3d_cartesian_E(..., Ex, Ey, Ez, Hx, Hy, Hz, dt, dx, dy, dz, ep)

   .. list-table:: File Roles
      :header-rows: 1
      :widths: 38 62

      * - File
        - Role
      * - :doc:`3D Cartesian (xyz) FDTD <E03_Maxwell_3Dxyz/fdtd_3d_cartesian_notes>`
        - Notes for the Cartesian Yee grid, component placement, and 3D update formulas.
      * - :doc:`mod_E03_fdtd_3d_cartesian.f90 <E03_Maxwell_3Dxyz/mod_E03_fdtd_3d_cartesian>`
        - Standard 3D Cartesian FDTD module wrapper.
      * - :doc:`sub_E03_fdtd_3d_cartesian_E.f90 <E03_Maxwell_3Dxyz/sub_E03_fdtd_3d_cartesian_E>`
        - Updates ``Ex/Ey/Ez`` from ``Hx/Hy/Hz``.
      * - :doc:`sub_E03_fdtd_3d_cartesian_H.f90 <E03_Maxwell_3Dxyz/sub_E03_fdtd_3d_cartesian_H>`
        - Updates ``Hx/Hy/Hz`` from ``Ex/Ey/Ez``.
      * - :doc:`mod_E03_cpml_3d_cartesian.f90 <E03_Maxwell_3Dxyz/mod_E03_cpml_3d_cartesian>`
        - 3D Cartesian CPML split-field memory and corrected updates.
      * - :doc:`sub_E03_cpml_3d_cartesian_E.f90 <E03_Maxwell_3Dxyz/sub_E03_cpml_3d_cartesian_E>`
        - Updates electric-field components and memory variables in the 3D Cartesian CPML region.
      * - :doc:`sub_E03_cpml_3d_cartesian_H.f90 <E03_Maxwell_3Dxyz/sub_E03_cpml_3d_cartesian_H>`
        - Updates magnetic-field components and memory variables in the 3D Cartesian CPML region.

   .. rubric:: Calling Notes

   Core update routines assume boundary or ghost data has already been prepared
   by the caller. Material parameters ``ep`` and ``mu`` should be sampled at the
   updated component locations; CPML memory variables must persist across time
   steps.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zhe LIU, Yinjian ZHAO · Harbin Institute of Technology · 2026/04/09</p>
      </div>
