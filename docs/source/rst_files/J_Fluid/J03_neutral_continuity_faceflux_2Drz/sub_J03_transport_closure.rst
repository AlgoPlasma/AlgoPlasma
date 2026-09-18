sub_J03_transport_closure.f90
=============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 面速度闭合与导入

   源码：``J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_transport_closure.f90``。
   由 ``mod_J03_neutral_continuity_faceflux_2Drz`` 包含，不能作为独立模块编译。
   :doc:`返回模块总览 <../J03_neutral_continuity_faceflux_2Drz>`。
   正文中的简写过程名省略了所属模块的 sub 前缀，完整接口见下方声明。

   .. rubric:: 闭合文件：为什么要除以迎风参考密度

   ``sub_J03_initialize_transport_closure`` 输入几何、面类型、参考密度和参考通量。
   正内部通量使用低索引单元密度，负通量使用高索引单元密度作为迎风值。
   密度下限由有效区域的最大密度幅值确定：

   .. math::

      n_{\rm floor}=\max\{\epsilon_{\rm floor}\max_{\rm active}|n_{\rm ref}|,\mathrm{tiny}\},
      \qquad u_f=\frac{\Gamma_{f,\rm ref}}{\max(n_{{\rm up},\rm ref},n_{\rm floor})}.

   epsilon_floor 对应 density_floor_fraction。下限用于防止除零，不是对参考密度的保正修复。
   当下限生效时，用参考密度重新计算通量也未必还原原始参考通量。

   sub_J03_import_J01_closure 与 sub_J03_import_J02_closure 接收完全相同的标准化数组，
   都转调此初始化过程；它们不依赖或再次调用前处理模块。
   初始化检查数组尺寸、有效单元体积、非负面积、损失频率和内部面邻居；
   fun_J03_active_at 仅读取有效单元标记，调用方须先保证索引有效。

   .. rubric:: 参数含义速查

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 参数或字段
        - 含义
      * - ``active、face_type、volume、face_area``
        - 有效区域、面类型、m³ 体积与 m² 面积。
      * - ``density_ref、flux_r_ref、flux_z_ref``
        - 前处理参考密度和内部面通量，用于计算一次固定面速度。
      * - ``boundary_inflow_flux、boundary_outflow_flux_ref``
        - 给定入射及参考出射通量；前者固定，后者除以参考密度得到出口速度。
      * - ``loss_frequency、density_floor_fraction``
        - 损失频率（s⁻¹）及相对于最大参考密度的无量纲下限比例。
      * - ``closure、ierr``
        - 输出完整闭合数据及状态码；两个 import 包装器不重新运行前处理。

   .. rubric:: 逐个过程的接口声明

   以下声明来自本文件。``intent(in)`` 为输入，``intent(out)`` 为本次调用的输出，
   ``intent(inout)`` 表示原值参与计算并被修改；``allocatable, intent(out)`` 数组由过程分配。
   ``optional`` 可省略，数组形状中的 nr、nz 为网格单元数。过程名中的 sub/fun 前缀不改变 Fortran 调用规则。

   .. rubric:: sub_J03_initialize_transport_closure

   .. code-block:: fortran

      subroutine sub_J03_initialize_transport_closure(active, face_type, volume, face_area, &
      density_ref, flux_r_ref, flux_z_ref, boundary_inflow_flux, &
      boundary_outflow_flux_ref, loss_frequency, density_floor_fraction, closure, ierr)
      logical, intent(in) :: active(:, :)
      integer, intent(in) :: face_type(:, :, :)
      real, intent(in) :: volume(:, :), face_area(:, :, :), density_ref(:, :), &
      flux_r_ref(:, :), flux_z_ref(:, :), boundary_inflow_flux(:, :, :), &
      boundary_outflow_flux_ref(:, :, :), loss_frequency(:, :), density_floor_fraction
      type(neutral_transport_closure_2drz_type), intent(out) :: closure
      integer, intent(out) :: ierr

   .. rubric:: sub_J03_import_J01_closure

   .. code-block:: fortran

      subroutine sub_J03_import_J01_closure(active, face_type, volume, face_area, density_ref, &
      flux_r_ref, flux_z_ref, boundary_inflow_flux, boundary_outflow_flux_ref, &
      loss_frequency, density_floor_fraction, closure, ierr)
      logical, intent(in) :: active(:, :)
      integer, intent(in) :: face_type(:, :, :)
      real, intent(in) :: volume(:, :), face_area(:, :, :), density_ref(:, :), flux_r_ref(:, :), &
      flux_z_ref(:, :), boundary_inflow_flux(:, :, :), boundary_outflow_flux_ref(:, :, :), &
      loss_frequency(:, :), density_floor_fraction
      type(neutral_transport_closure_2drz_type), intent(out) :: closure
      integer, intent(out) :: ierr

   .. rubric:: sub_J03_import_J02_closure

   .. code-block:: fortran

      subroutine sub_J03_import_J02_closure(active, face_type, volume, face_area, density_ref, &
      flux_r_ref, flux_z_ref, boundary_inflow_flux, boundary_outflow_flux_ref, &
      loss_frequency, density_floor_fraction, closure, ierr)
      logical, intent(in) :: active(:, :)
      integer, intent(in) :: face_type(:, :, :)
      real, intent(in) :: volume(:, :), face_area(:, :, :), density_ref(:, :), flux_r_ref(:, :), &
      flux_z_ref(:, :), boundary_inflow_flux(:, :, :), boundary_outflow_flux_ref(:, :, :), &
      loss_frequency(:, :), density_floor_fraction
      type(neutral_transport_closure_2drz_type), intent(out) :: closure
      integer, intent(out) :: ierr

   .. rubric:: fun_J03_active_at

   .. code-block:: fortran

      logical function fun_J03_active_at(active, i, k)
      logical, intent(in) :: active(:, :)
      integer, intent(in) :: i, k

   内部面两侧必须都标为内部面，且共享面积为正。面积差不能超过
   ``100*epsilon(1.0)*max(A_left,A_right)``；拓扑不一致返回面类型错误，面积不一致返回几何错误。
   这样同一面在相邻单元的散度中才能抵消。轴线边界的零面积仍被允许。

   .. rubric:: 测试与源码

   :doc:`对应测试及断言 </tests/011_fluid/J03_tests>` 列出调用本文件的测试项。
   :download:`下载实现源码 <../../../../../J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_transport_closure.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   This file is included by ``mod_J03_neutral_continuity_faceflux_2Drz``.
   :doc:`Module overview <../J03_neutral_continuity_faceflux_2Drz>` · :doc:`Tests </tests/011_fluid/J03_tests>`.
