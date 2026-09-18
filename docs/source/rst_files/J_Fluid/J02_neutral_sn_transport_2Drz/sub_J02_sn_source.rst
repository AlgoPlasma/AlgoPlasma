sub_J02_sn_source.f90
=====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 入口分布与损失系数

   源码：``J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_source.f90``。
   由 ``mod_J02_neutral_sn_transport_2Drz`` 包含，不能作为独立模块编译。
   :doc:`返回模块总览 <../J02_neutral_sn_transport_2Drz>`。
   正文中的简写过程名省略了所属模块的 sub 前缀，完整接口见下方声明。

   .. rubric:: 入口文件：三类输入不能混用

   ``sub_J02_sn_source.f90`` 中，``build_maxwellian_inflow_shape`` 是零漂移包装；
   ``build_drifted_maxwellian_inflow_shape`` 输入温度 T（K）、质量 M（kg）及漂移速度，
   返回各节点上的二维单位密度麦克斯韦分布形状：

   .. math::

      g_m=\frac{\alpha}{\pi}
      e^{-\alpha[(v_m\mu_m-U_r)^2+(v_m\eta_m-U_z)^2]},\qquad
      \alpha=\frac{M}{2k_BT}.

   ``build_mc_crossing_inflow_shape`` 及其 bins 别名输入速度格的穿面概率质量 P；
   ``build_mc_crossing_pdf_inflow_shape`` 输入相对于速度面积的穿面概率密度 p。
   设外法向为 n，入射法向速率为 :math:`c_m=v_m|\boldsymbol\Omega_m\cdot\boldsymbol n|`，则

   .. math::

      g_m^{\rm bins}=\frac{P_m}{w_mc_m},\qquad
      g_m^{\rm pdf}=\frac{p_m}{c_m},\qquad P_m=w_mp_m.

   最后一个关系成立时两种输入才等价。``normalize_inflow_flux`` 把形状变为实际入口相密度：

   .. math::

      \psi_{{\rm in},m}=
      \frac{J_{\rm in}g_m}{\sum_{\boldsymbol\Omega_l\cdot\boldsymbol n<0}w_lc_lg_l}
      \quad(\boldsymbol\Omega_m\cdot\boldsymbol n<0).

   出射方向输出零。目标入射通量 J_in 是非负大小，法向须为单位向量；
   零分母返回错误。``build_sigma_from_frequency`` 输出
   :math:`\sigma_{ikm}=\nu_{ik}/v_m`，将 s⁻¹ 转为 m⁻¹。
   ``quadrature_is_valid`` 与 ``normal_is_unit`` 检查节点布局和法向，不执行输运。

   .. rubric:: 参数含义速查

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 参数或字段
        - 含义
      * - ``quadrature、normal_r/z``
        - 组合节点及边界外法向；与法向点积小于零为入射。
      * - ``temperature、particle_mass、drift_velocity_r/z``
        - 温度（K）、质量（kg）、漂移速度（m/s），定义入口速度分布。
      * - ``crossing_bin_probability、crossing_pdf``
        - 每个离散格的事件概率质量与相对于速度面积的概率密度，二者单位和权重不同。
      * - ``inflow_shape、target_flux、psi_in``
        - 未定总粒子率的形状、目标入射通量（m⁻²s⁻¹）、归一化后入口相密度。
      * - ``ionization_frequency、sigma_t``
        - 输入损失频率（s⁻¹），输出随速度组变化的吸收系数（m⁻¹）。

   .. rubric:: 逐个过程的接口声明

   以下声明来自本文件。``intent(in)`` 为输入，``intent(out)`` 为本次调用的输出，
   ``intent(inout)`` 表示原值参与计算并被修改；``allocatable, intent(out)`` 数组由过程分配。
   ``optional`` 可省略，数组形状中的 nr、nz 为网格单元数。过程名中的 sub/fun 前缀不改变 Fortran 调用规则。

   .. rubric:: sub_J02_build_maxwellian_inflow_shape

   .. code-block:: fortran

      subroutine sub_J02_build_maxwellian_inflow_shape(quadrature, temperature, &
      particle_mass, inflow_shape, ierr)
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: temperature, particle_mass
      real, allocatable, intent(out) :: inflow_shape(:)
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_build_drifted_maxwellian_inflow_shape

   .. code-block:: fortran

      subroutine sub_J02_build_drifted_maxwellian_inflow_shape(quadrature, &
      temperature, particle_mass, drift_velocity_r, drift_velocity_z, &
      inflow_shape, ierr)
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: temperature, particle_mass
      real, intent(in) :: drift_velocity_r, drift_velocity_z
      real, allocatable, intent(out) :: inflow_shape(:)
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_build_mc_crossing_inflow_shape

   .. code-block:: fortran

      subroutine sub_J02_build_mc_crossing_inflow_shape(quadrature, normal_r, &
      normal_z, crossing_bin_probability, inflow_shape, ierr)
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: normal_r, normal_z
      real, intent(in) :: crossing_bin_probability(:)
      real, allocatable, intent(out) :: inflow_shape(:)
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_build_mc_crossing_bins_inflow_shape

   .. code-block:: fortran

      subroutine sub_J02_build_mc_crossing_bins_inflow_shape(quadrature, normal_r, &
      normal_z, crossing_bin_probability, inflow_shape, ierr)
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: normal_r, normal_z, crossing_bin_probability(:)
      real, allocatable, intent(out) :: inflow_shape(:)
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_build_mc_crossing_pdf_inflow_shape

   .. code-block:: fortran

      subroutine sub_J02_build_mc_crossing_pdf_inflow_shape(quadrature, normal_r, &
      normal_z, crossing_pdf, inflow_shape, ierr)
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: normal_r, normal_z, crossing_pdf(:)
      real, allocatable, intent(out) :: inflow_shape(:)
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_build_sigma_from_frequency

   .. code-block:: fortran

      subroutine sub_J02_build_sigma_from_frequency(quadrature, ionization_frequency, &
      sigma_t, ierr)
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: ionization_frequency(:, :)
      real, allocatable, intent(out) :: sigma_t(:, :, :)
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_normalize_inflow_flux

   .. code-block:: fortran

      subroutine sub_J02_normalize_inflow_flux(quadrature, normal_r, normal_z, &
      target_flux, inflow_shape, psi_in, ierr)
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: normal_r, normal_z, target_flux
      real, intent(in) :: inflow_shape(:)
      real, allocatable, intent(out) :: psi_in(:)
      integer, intent(out) :: ierr

   .. rubric:: fun_J02_quadrature_is_valid

   .. code-block:: fortran

      logical function fun_J02_quadrature_is_valid(quadrature)
      type(sn_quadrature_type), intent(in) :: quadrature

   .. rubric:: fun_J02_normal_is_unit

   .. code-block:: fortran

      logical function fun_J02_normal_is_unit(normal_r, normal_z)
      real, intent(in) :: normal_r, normal_z

   .. rubric:: 测试与源码

   :doc:`对应测试及断言 </tests/011_fluid/J02_tests>` 列出调用本文件的测试项。
   :download:`下载实现源码 <../../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_source.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   This file is included by ``mod_J02_neutral_sn_transport_2Drz``.
   :doc:`Module overview <../J02_neutral_sn_transport_2Drz>` · :doc:`Tests </tests/011_fluid/J02_tests>`.
