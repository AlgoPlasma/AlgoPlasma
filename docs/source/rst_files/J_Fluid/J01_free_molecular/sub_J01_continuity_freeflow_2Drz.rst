sub_J01_continuity_freeflow_2Drz.f90
====================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 二维给定速度通量与更新

   源码：``J_Fluid/J01_free_molecular/sub_J01_continuity_freeflow_2Drz.f90``。
   由 ``mod_J01_continuity_freeflow`` 包含，不能作为独立模块编译。
   :doc:`返回模块总览 <continuity>`。
   正文中的简写过程名省略了所属模块的 sub 前缀，完整接口见下方声明。

   .. rubric:: 二维给定速度通量与单步更新

   ``sub_J01_build_faceflux_2Drz`` 对每个相邻有效单元采用前述局部 Lax-Friedrichs 公式。
   具体通量为

   .. math::

      \Gamma_{L/R}=\tfrac12(u_Ln_L+u_Rn_R)
      -\tfrac12\max(|u_L|,|u_R|)(n_R-n_L).

   当面两侧速度相同，公式退化为迎风通量；速度不同时还包含耗散项。
   开放面的出射通量仅在速度指向域外时取 n*u，否则为零。
   参数 boundary_inflow_flux 在该函数内只作尺寸检查，不被加入输出，
   实际入射项由单步更新函数或 J03 处理。

   ``sub_J01_continuity_step_2Drz`` 按 face_type 选择内部面通量、开放面入射加出射，
   或壁面零通量，使用

   .. math::

      Q=A_{r+}\Gamma_{r+}-A_{r-}\Gamma_{r-}
       +A_{z+}\Gamma_{z+}-A_{z-}\Gamma_{z-},\qquad
      n^{q+1}=\frac{n^q-\Delta t Q/V+\Delta t S}{1+\Delta t\nu}.

   volume 单位为 m³，face_area 为 m²，通量为 m⁻²s⁻¹，
   source_rate 为 m⁻³s⁻¹，loss_frequency 为 s⁻¹，dt 为 s。
   此接口分配并返回 density_new，不原地修改 density，也没有负值截断。
   fun_J01_flux_r_at、fun_J01_flux_z_at 仅取指定内部面数组元素，不重新计算通量。

   .. rubric:: 参数说明

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 参数或字段
        - 含义
      * - ``active、face_type``
        - 有效单元标记与四面类型；决定哪些面参与散度。
      * - ``density、velocity_r/z``
        - 单元数密度（m⁻³）及给定速度（m/s）。
      * - ``flux_r/z、boundary_inflow/outflow_flux``
        - 坐标正方向通量（m⁻²s⁻¹），边界入射和出射分开存储。
      * - ``volume、face_area、dt``
        - 物理体积、面积、时间步，分别为 m³、m²、s。
      * - ``source_rate、loss_frequency、density_new``
        - 非负体产生率、损失频率；返回更新后的数密度。

   .. rubric:: 接口声明

   以下声明来自本文件。``intent(in)`` 为输入，``intent(out)`` 为本次调用的输出，
   ``intent(inout)`` 表示原值参与计算并被修改；``allocatable, intent(out)`` 数组由过程分配。
   ``optional`` 可省略，数组形状中的 nr、nz 为网格单元数。过程名中的 sub/fun 前缀不改变 Fortran 调用规则。

   .. rubric:: sub_J01_build_faceflux_2Drz

   .. code-block:: fortran

      subroutine sub_J01_build_faceflux_2Drz(active, face_type, density, velocity_r, &
      velocity_z, boundary_inflow_flux, flux_r, flux_z, boundary_outflow_flux, ierr)
      logical, intent(in) :: active(:, :)
      integer, intent(in) :: face_type(:, :, :)
      real, intent(in) :: density(:, :), velocity_r(:, :), velocity_z(:, :)
      real, intent(in) :: boundary_inflow_flux(:, :, :)
      real, allocatable, intent(out) :: flux_r(:, :), flux_z(:, :), boundary_outflow_flux(:, :, :)
      integer, intent(out) :: ierr

   .. rubric:: sub_J01_continuity_step_2Drz

   .. code-block:: fortran

      subroutine sub_J01_continuity_step_2Drz(active, face_type, volume, face_area, density, &
      source_rate, loss_frequency, flux_r, flux_z, boundary_inflow_flux, &
      boundary_outflow_flux, dt, density_new, ierr)
      logical, intent(in) :: active(:, :)
      integer, intent(in) :: face_type(:, :, :)
      real, intent(in) :: volume(:, :), face_area(:, :, :), density(:, :), source_rate(:, :), &
      loss_frequency(:, :), flux_r(:, :), flux_z(:, :), boundary_inflow_flux(:, :, :), &
      boundary_outflow_flux(:, :, :), dt
      real, allocatable, intent(out) :: density_new(:, :)
      integer, intent(out) :: ierr

   .. rubric:: fun_J01_flux_r_at

   .. code-block:: fortran

      real function fun_J01_flux_r_at(flux_r, i, k)
      real, intent(in) :: flux_r(:, :)
      integer, intent(in) :: i, k

   .. rubric:: fun_J01_flux_z_at

   .. code-block:: fortran

      real function fun_J01_flux_z_at(flux_z, i, k)
      real, intent(in) :: flux_z(:, :)
      integer, intent(in) :: i, k

   .. rubric:: 测试与源码

   :doc:`对应测试及断言 </tests/011_fluid/J01_tests>` 列出调用本文件的测试项。
   :download:`下载实现源码 <../../../../../J_Fluid/J01_free_molecular/sub_J01_continuity_freeflow_2Drz.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   This file is included by ``mod_J01_continuity_freeflow``.
   :doc:`Module overview <continuity>` · :doc:`Tests </tests/011_fluid/J01_tests>`.
