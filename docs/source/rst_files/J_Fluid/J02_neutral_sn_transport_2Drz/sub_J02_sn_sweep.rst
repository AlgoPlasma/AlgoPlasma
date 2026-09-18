sub_J02_sn_sweep.f90
====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 开放边界迎风扫描

   源码：``J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_sweep.f90``。
   由 ``mod_J02_neutral_sn_transport_2Drz`` 包含，不能作为独立模块编译。
   :doc:`返回模块总览 <../J02_neutral_sn_transport_2Drz>`。
   正文中的简写过程名省略了所属模块的 sub 前缀，完整接口见下方声明。

   .. rubric:: 扫描文件：按迎风关系求解全域

   对每个固定速率与方向，求解

   .. math::

      \frac1r\partial_r(r\mu\psi)+\partial_z(\eta\psi)+\sigma_t\psi=0.

   角分布在每个单元内使用三个一次基函数系数。局部矩阵与迎风右端项的推导见
   :doc:`离散算子 <sub_J02_sn_dg_operator>`。扫描只决定装配和求解顺序，不改变局部离散公式。

   ``sub_J02_sn_sweep.f90`` 中，``sweep_direction`` 按 mu、eta 的正负选择网格遍历方向，
   使迎风单元先求解；``sweep_all_directions`` 遍历速度节点，输出 ``psi(3,nr,nz,n_dir)``。
   该路径拒绝反射壁，因为反射会耦合不同方向，单次独立扫描不能闭合。

   .. rubric:: 参数含义速查

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 参数或字段
        - 含义
      * - ``mesh、geometry、quadrature``
        - 有效网格、柱坐标积分量与速度节点；应先调用各初始化接口。
      * - ``direction、sigma_t``
        - 当前展平方向索引及吸收系数；全方向接口接收 (nr,nz,n_dir) 系数。
      * - ``boundary_inflow、boundary``
        - 给定入射分布与可选面类型；该文件不求解反射耦合。
      * - ``psi``
        - 单方向或全方向局部 P1 系数，第一维三个系数。具体维数以对应声明为准。
      * - ``failed_direction、failed_i、failed_k``
        - 失败的速度方向、径向单元、轴向单元索引；用于追踪局部装配/求解错误。

   .. rubric:: 逐个过程的接口声明

   以下声明来自本文件。``intent(in)`` 为输入，``intent(out)`` 为本次调用的输出，
   ``intent(inout)`` 表示原值参与计算并被修改；``allocatable, intent(out)`` 数组由过程分配。
   ``optional`` 可省略，数组形状中的 nr、nz 为网格单元数。过程名中的 sub/fun 前缀不改变 Fortran 调用规则。

   .. rubric:: sub_J02_sweep_all_directions

   .. code-block:: fortran

      subroutine sub_J02_sweep_all_directions(mesh, geometry, quadrature, sigma_t, &
      boundary_inflow, psi, ierr, failed_direction, failed_i, failed_k, boundary)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      type(sn_geometry_2drz_type), intent(in) :: geometry
      type(sn_quadrature_type), intent(in) :: quadrature
      real, intent(in) :: sigma_t(:, :, :)
      real, intent(in) :: boundary_inflow(:, :, :, :)
      real, allocatable, intent(out) :: psi(:, :, :, :)
      integer, intent(out) :: ierr
      integer, intent(out), optional :: failed_direction, failed_i, failed_k
      type(sn_boundary_2drz_type), intent(in), optional :: boundary

   .. rubric:: sub_J02_sweep_direction

   .. code-block:: fortran

      subroutine sub_J02_sweep_direction(mesh, geometry, quadrature, idir, sigma_t, &
      boundary_inflow, psi_direction, ierr, failed_i, failed_k, boundary)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      type(sn_geometry_2drz_type), intent(in) :: geometry
      type(sn_quadrature_type), intent(in) :: quadrature
      integer, intent(in) :: idir
      real, intent(in) :: sigma_t(:, :)
      real, intent(in) :: boundary_inflow(:, :, :)
      real, intent(out) :: psi_direction(:, :, :)
      integer, intent(out) :: ierr
      integer, intent(out), optional :: failed_i, failed_k
      type(sn_boundary_2drz_type), intent(in), optional :: boundary

   .. rubric:: add_face

   .. code-block:: fortran

      subroutine add_face(face_id, outward_dot, neighbor_i, neighbor_k)
      integer, intent(in) :: face_id, neighbor_i, neighbor_k
      real, intent(in) :: outward_dot

   .. rubric:: fun_J02_geometry_is_valid

   .. code-block:: fortran

      logical function fun_J02_geometry_is_valid(mesh, geometry)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      type(sn_geometry_2drz_type), intent(in) :: geometry

   .. rubric:: 测试与源码

   :doc:`对应测试及断言 </tests/011_fluid/J02_tests>` 列出调用本文件的测试项。
   :download:`下载实现源码 <../../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_sweep.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   This file is included by ``mod_J02_neutral_sn_transport_2Drz``.
   :doc:`Module overview <../J02_neutral_sn_transport_2Drz>` · :doc:`Tests </tests/011_fluid/J02_tests>`.
