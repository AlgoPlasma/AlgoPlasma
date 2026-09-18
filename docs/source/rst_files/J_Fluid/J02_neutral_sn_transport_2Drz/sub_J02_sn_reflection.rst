sub_J02_sn_reflection.f90
=========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 反射边界与源迭代

   源码：``J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reflection.f90``。
   由 ``mod_J02_neutral_sn_transport_2Drz`` 包含，不能作为独立模块编译。
   :doc:`返回模块总览 <../J02_neutral_sn_transport_2Drz>`。
   正文中的简写过程名省略了所属模块的 sub 前缀，完整接口见下方声明。

   .. rubric:: 反射文件：部分入口与方向耦合

   ``sub_J02_sn_reflection.f90`` 的 ``build_partial_zlo_inlet`` 将入口范围与网格面求交。
   若交集为 [a,b]，返回入口面积份额及局部坐标：

   .. math::

      f_{\rm inlet}=\frac{b^2-a^2}{r_+^2-r_-^2},\qquad
      \xi_a=(a-r_c)/h_r,\quad \xi_b=(b-r_c)/h_r.

   ``fun_J02_reflected_direction_index`` 查找同速率组中的镜面方向
   :math:`\boldsymbol\Omega'=\boldsymbol\Omega-2(\boldsymbol\Omega\cdot\boldsymbol n)\boldsymbol n`。
   ``build_wall_maxwell_shape`` 生成壁温分布，``compute_diffuse_wall_constants`` 根据旧出射场
   计算再发射系数。漫反射份额为 d 时，

   .. math::

      \psi_{\rm wall,in}=(1-d)\psi_{\rm specular}+dCg_{\rm wall},\qquad
      C=\frac{\sum_{\rm out}w_mv_m(\boldsymbol\Omega_m\cdot\boldsymbol n)
      \langle\psi_m\rangle_f}
      {\sum_{\rm in}w_mv_m|\boldsymbol\Omega_m\cdot\boldsymbol n|g_{{\rm wall},m}}.

   代码把上述 C 的负值截为零，分母为零时保持零；出现负出射积分时，反射不再保持该负通量。壁温形状使用未归一化的指数函数，其常数因子由 C 抵消。

   部分入口面只在剩余壁面区间计算反射。``sweep_reflecting`` 输入旧角分布，
   固定本轮反射入射后扫描，输出新角分布；``solve_source_iteration`` 从零场开始重复，
   至少两次后才检查收敛：

   .. math::

      \epsilon_\psi=\frac{\sum|\psi^{q+1}-\psi^q|}{\max(\sum|\psi^q|,1)}.

   求和覆盖全部局部系数，不是只对密度求和。tolerance 与 max_iterations 控制停止，
   progress_interval 只控制日志。失败位置由 failed_direction、failed_i、failed_k 返回。
   文件内 add_face 分派面类型，两个 add_zlo_complement 辅助过程积分入口之外的壁面，
   fun_boundary_value 读取完整边界输入或紧凑轴向入口数组。

   .. rubric:: 参数含义速查

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 参数或字段
        - 含义
      * - ``r_min/max、face_fraction、xi_lo/hi``
        - 入口物理半径范围，输出交叠面积份额与局部积分区间。
      * - ``wall_shape、diffuse_fraction、diffuse_constant``
        - 壁温分布形状、漫反射比例及按出射通量计算的再发射系数。
      * - ``psi_old、psi_new、psi``
        - 上一轮角分布、本轮扫描输出、最终迭代角分布；均按三系数×网格×方向存储。
      * - ``boundary_inflow、zlo_inflow``
        - 完整四面入口分布或仅轴向下端入口的紧凑方向数组，完整数组存在时优先。
      * - ``zlo_source_xi_lo/hi``
        - 各径向网格上入口的局部区间；成对提供，剩余区间用于壁面反射。
      * - ``tolerance、max_iterations、converged、final_relative_change``
        - 系数变化阈值、迭代上限、收敛标记及最终相对变化；失败位置另由可选索引输出。

   .. rubric:: 逐个过程的接口声明

   以下声明来自本文件。``intent(in)`` 为输入，``intent(out)`` 为本次调用的输出，
   ``intent(inout)`` 表示原值参与计算并被修改；``allocatable, intent(out)`` 数组由过程分配。
   ``optional`` 可省略，数组形状中的 nr、nz 为网格单元数。过程名中的 sub/fun 前缀不改变 Fortran 调用规则。

   .. rubric:: sub_J02_build_partial_zlo_inlet

   .. code-block:: fortran

      subroutine sub_J02_build_partial_zlo_inlet(mesh, r_min, r_max, face_fraction, &
      xi_lo, xi_hi, ierr)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      real, intent(in) :: r_min, r_max
      real, allocatable, intent(out) :: face_fraction(:), xi_lo(:), xi_hi(:)
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_build_wall_maxwell_shape

   .. code-block:: fortran

      subroutine sub_J02_build_wall_maxwell_shape(quadrature, temperature, particle_mass, &
      wall_shape, ierr)
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: temperature, particle_mass
      real, allocatable, intent(out) :: wall_shape(:)
      integer, intent(out) :: ierr

   .. rubric:: fun_J02_reflected_direction_index

   .. code-block:: fortran

      integer function fun_J02_reflected_direction_index(quadrature, direction, normal_r, normal_z)
      type(sn_quadrature_type), intent(in) :: quadrature
      integer, intent(in) :: direction
      real, intent(in) :: normal_r, normal_z

   .. rubric:: sub_J02_compute_diffuse_wall_constants

   .. code-block:: fortran

      subroutine sub_J02_compute_diffuse_wall_constants(mesh, geometry, quadrature, boundary, &
      wall_shape, psi_old, diffuse_constant, ierr, zlo_source_xi_lo, zlo_source_xi_hi)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      type(sn_geometry_2drz_type), intent(in) :: geometry
      type(sn_quadrature_type), intent(in) :: quadrature
      type(sn_boundary_2drz_type), intent(in) :: boundary
      real, intent(in) :: wall_shape(:), psi_old(:, :, :, :)
      real, allocatable, intent(out) :: diffuse_constant(:, :, :)
      integer, intent(out) :: ierr
      real, intent(in), optional :: zlo_source_xi_lo(:), zlo_source_xi_hi(:)

   .. rubric:: sub_J02_sweep_reflecting

   .. code-block:: fortran

      subroutine sub_J02_sweep_reflecting(mesh, geometry, quadrature, sigma_t, boundary_inflow, &
      boundary, wall_shape, diffuse_fraction, psi_old, psi, ierr, failed_direction, &
      failed_i, failed_k, zlo_source_xi_lo, zlo_source_xi_hi, zlo_inflow, &
      progress_interval)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      type(sn_geometry_2drz_type), intent(in) :: geometry
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: sigma_t(:, :, :), wall_shape(:)
      real, intent(in), optional :: boundary_inflow(:, :, :, :), zlo_inflow(:)
      type(sn_boundary_2drz_type), intent(in) :: boundary
      real, intent(in) :: diffuse_fraction, psi_old(:, :, :, :)
      real, allocatable, intent(out) :: psi(:, :, :, :)
      integer, intent(out) :: ierr
      integer, intent(out), optional :: failed_direction, failed_i, failed_k
      integer, intent(in), optional :: progress_interval
      real, intent(in), optional :: zlo_source_xi_lo(:), zlo_source_xi_hi(:)

   .. rubric:: add_face

   .. code-block:: fortran

      subroutine add_face(face_id, outward_dot, neighbor_i, neighbor_k)
      integer, intent(in) :: face_id, neighbor_i, neighbor_k
      real, intent(in) :: outward_dot

   .. rubric:: add_zlo_complement_coeff

   .. code-block:: fortran

      subroutine add_zlo_complement_coeff(vector, s, coefficient)
      real, intent(inout) :: vector(3)
      real, intent(in) :: s, coefficient(3)

   .. rubric:: add_zlo_complement_constant

   .. code-block:: fortran

      subroutine add_zlo_complement_constant(vector, s, value)
      real, intent(inout) :: vector(3)
      real, intent(in) :: s, value

   .. rubric:: fun_boundary_value

   .. code-block:: fortran

      real function fun_boundary_value(face_id, cell_i, cell_k, direction)
      integer, intent(in) :: face_id, cell_i, cell_k, direction

   .. rubric:: sub_J02_solve_source_iteration

   .. code-block:: fortran

      subroutine sub_J02_solve_source_iteration(mesh, geometry, quadrature, sigma_t, &
      boundary_inflow, boundary, wall_shape, diffuse_fraction, max_iterations, tolerance, &
      psi, converged, iterations, final_relative_change, ierr, failed_direction, failed_i, &
      failed_k, zlo_source_xi_lo, zlo_source_xi_hi, zlo_inflow, progress_interval)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      type(sn_geometry_2drz_type), intent(in) :: geometry
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: sigma_t(:, :, :), wall_shape(:)
      real, intent(in), optional :: boundary_inflow(:, :, :, :), zlo_inflow(:)
      type(sn_boundary_2drz_type), intent(in) :: boundary
      real, intent(in) :: diffuse_fraction, tolerance
      integer, intent(in) :: max_iterations
      real, allocatable, intent(out) :: psi(:, :, :, :)
      logical, intent(out) :: converged
      integer, intent(out) :: iterations, ierr
      real, intent(out) :: final_relative_change
      integer, intent(out), optional :: failed_direction, failed_i, failed_k
      integer, intent(in), optional :: progress_interval
      real, intent(in), optional :: zlo_source_xi_lo(:), zlo_source_xi_hi(:)

   .. rubric:: fun_J02_reflection_inputs_valid

   .. code-block:: fortran

      logical function fun_J02_reflection_inputs_valid(mesh, quadrature, boundary, wall_shape, &
      psi_old, zlo_source_xi_lo, zlo_source_xi_hi)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      type(sn_quadrature_type), intent(in) :: quadrature
      type(sn_boundary_2drz_type), intent(in) :: boundary
      real, intent(in) :: wall_shape(:), psi_old(:, :, :, :)
      real, intent(in), optional :: zlo_source_xi_lo(:), zlo_source_xi_hi(:)

   .. rubric:: fun_face_normal

   .. code-block:: fortran

      subroutine fun_face_normal(face_id, normal_r, normal_z)
      integer, intent(in) :: face_id
      real, intent(out) :: normal_r, normal_z

   .. rubric:: fun_face_trace

   .. code-block:: fortran

      real function fun_face_trace(coeff, face_id, xi_bar)
      real, intent(in) :: coeff(3), xi_bar
      integer, intent(in) :: face_id

   .. rubric:: 测试与源码

   :doc:`对应测试及断言 </tests/011_fluid/J02_tests>` 列出调用本文件的测试项。
   :download:`下载实现源码 <../../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reflection.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   This file is included by ``mod_J02_neutral_sn_transport_2Drz``.
   :doc:`Module overview <../J02_neutral_sn_transport_2Drz>` · :doc:`Tests </tests/011_fluid/J02_tests>`.
