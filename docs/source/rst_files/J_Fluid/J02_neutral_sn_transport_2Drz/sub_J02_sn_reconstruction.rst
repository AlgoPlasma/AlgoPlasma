sub_J02_sn_reconstruction.f90
=============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 密度、速度与面通量重构

   源码：``J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reconstruction.f90``。
   由 ``mod_J02_neutral_sn_transport_2Drz`` 包含，不能作为独立模块编译。
   :doc:`返回模块总览 <../J02_neutral_sn_transport_2Drz>`。
   正文中的简写过程名省略了所属模块的 sub 前缀，完整接口见下方声明。

   .. rubric:: 重构文件：角分布如何变为密度与面通量

   ``sub_J02_sn_reconstruction.f90`` 中，``reconstruct_cell_moments`` 先取
   :math:`\bar\psi_m=a_{0m}+\bar\xi a_{1m}`，再计算

   .. math::

      n=\sum_m w_m\bar\psi_m,\qquad
      u_r=\frac{\sum_m w_mv_m\mu_m\bar\psi_m}{n},\qquad
      u_z=\frac{\sum_m w_mv_m\eta_m\bar\psi_m}{n}.

   密度不大于 tiny 时速度保持零。``reconstruct_internal_face_fluxes`` 为每个方向选迎风迹值：
   径向为 :math:`a_0\pm a_1`，轴向面积平均为 :math:`a_0+\bar\xi a_1\pm a_2`；
   通量为 :math:`\Gamma_r=\sum_mw_mv_m\mu_m\psi_{f,m}` 或轴向对应形式。

   ``reconstruct_open_boundary_fluxes`` 分开积分给定入射场与计算出射场。
   部分入口通量按完整网格面面积平均；交给 J03 后不能再乘一次入口份额。
   ``fun_J02_boundary_is_valid`` 检查面数组布局，``fun_J02_face_type`` 按面号取类型。
   ``sub_J02_sn_error.f90`` 的 ``fun_J02_error_message`` 只将错误码转为文字，不修改场量。

   .. rubric:: 参数含义速查

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 参数或字段
        - 含义
      * - ``psi、quadrature、geometry``
        - P1 系数、速度权重、几何加权平均；缺少任何一项都不能从系数直接得到密度。
      * - ``density、velocity_r/z``
        - 体积加权的单元数密度与平均速度。
      * - ``flux_r/z``
        - 内部面面积平均的坐标方向通量，不含乘面积后的粒子率。
      * - ``prescribed_inflow、zlo_inflow``
        - 完整边界或紧凑轴向下端入射相密度，完整输入优先。
      * - ``inflow_flux、outflow_flux``
        - 分别保存开放面的入射和出射通量，均按坐标方向带符号。

   .. rubric:: 逐个过程的接口声明

   以下声明来自本文件。``intent(in)`` 为输入，``intent(out)`` 为本次调用的输出，
   ``intent(inout)`` 表示原值参与计算并被修改；``allocatable, intent(out)`` 数组由过程分配。
   ``optional`` 可省略，数组形状中的 nr、nz 为网格单元数。过程名中的 sub/fun 前缀不改变 Fortran 调用规则。

   .. rubric:: sub_J02_reconstruct_cell_moments

   .. code-block:: fortran

      subroutine sub_J02_reconstruct_cell_moments(mesh, geometry, quadrature, psi, &
      density, velocity_r, velocity_z, ierr)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      type(sn_geometry_2drz_type), intent(in) :: geometry
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: psi(:, :, :, :)
      real, allocatable, intent(out) :: density(:, :), velocity_r(:, :), velocity_z(:, :)
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_reconstruct_internal_face_fluxes

   .. code-block:: fortran

      subroutine sub_J02_reconstruct_internal_face_fluxes(mesh, geometry, quadrature, &
      psi, flux_r, flux_z, ierr)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      type(sn_geometry_2drz_type), intent(in) :: geometry
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: psi(:, :, :, :)
      real, allocatable, intent(out) :: flux_r(:, :), flux_z(:, :)
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_reconstruct_open_boundary_fluxes

   .. code-block:: fortran

      subroutine sub_J02_reconstruct_open_boundary_fluxes(mesh, geometry, boundary, &
      quadrature, psi, prescribed_inflow, inflow_flux, outflow_flux, ierr, &
      zlo_source_xi_lo, zlo_source_xi_hi, zlo_inflow)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      type(sn_geometry_2drz_type), intent(in) :: geometry
      type(sn_boundary_2drz_type), intent(in) :: boundary
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: psi(:, :, :, :)
      real, intent(in), optional :: prescribed_inflow(:, :, :, :), zlo_inflow(:)
      real, allocatable, intent(out) :: inflow_flux(:, :, :), outflow_flux(:, :, :)
      integer, intent(out) :: ierr
      real, intent(in), optional :: zlo_source_xi_lo(:), zlo_source_xi_hi(:)

   .. rubric:: fun_prescribed_value

   .. code-block:: fortran

      real function fun_prescribed_value(face_id, cell_i, cell_k, direction)
      integer, intent(in) :: face_id, cell_i, cell_k, direction

   .. rubric:: fun_J02_boundary_is_valid

   .. code-block:: fortran

      logical function fun_J02_boundary_is_valid(mesh, boundary)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      type(sn_boundary_2drz_type), intent(in) :: boundary

   .. rubric:: fun_J02_face_type

   .. code-block:: fortran

      integer function fun_J02_face_type(boundary, face_id, i, k)
      type(sn_boundary_2drz_type), intent(in) :: boundary
      integer, intent(in) :: face_id, i, k

   .. rubric:: 测试与源码

   :doc:`对应测试及断言 </tests/011_fluid/J02_tests>` 列出调用本文件的测试项。
   :download:`下载实现源码 <../../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reconstruction.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   This file is included by ``mod_J02_neutral_sn_transport_2Drz``.
   :doc:`Module overview <../J02_neutral_sn_transport_2Drz>` · :doc:`Tests </tests/011_fluid/J02_tests>`.
