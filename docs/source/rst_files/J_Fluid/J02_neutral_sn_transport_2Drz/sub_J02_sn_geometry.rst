sub_J02_sn_geometry.f90
=======================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 网格、几何与面类型

   源码：``J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry.f90``。
   由 ``mod_J02_neutral_sn_transport_2Drz`` 包含，不能作为独立模块编译。
   :doc:`返回模块总览 <../J02_neutral_sn_transport_2Drz>`。
   正文中的简写过程名省略了所属模块的 sub 前缀，完整接口见下方声明。

   .. rubric:: 几何文件：网格如何转为积分权重

   ``sub_J02_sn_geometry.f90`` 中，``initialize_mesh`` 检查半径非负、坐标严格递增、
   有效单元数组尺寸后保存输入。``build_geometry`` 输入网格及扇区角 :math:`\Theta`，输出

   .. math::

      r_c=\frac{r_++r_-}{2},\quad h_r=\frac{r_+-r_-}{2},\quad
      V=\frac{\Theta}{2}(r_+^2-r_-^2)\Delta z,\qquad
      A_{r\pm}=\Theta r_\pm\Delta z,\quad
      A_{z\pm}=\frac{\Theta}{2}(r_+^2-r_-^2).

   ``xi_bar`` 是局部坐标的柱坐标加权平均，不是网格中心坐标：

   .. math::

      \bar\xi=\frac{\int_K r\xi\,dr\,dz}{\int_K r\,dr\,dz}=\frac{h_r}{3r_c}.

   ``initialize_boundary_types`` 将有效邻接设为内部面，域外默认开放，无效邻接设为壁面。
   ``configure_zlo_partial_inlet_boundary`` 根据入口份额修改轴向下端面类型：
   份额大于零标为开放，否则为壁面。面内剩余壁面的积分仍由反射文件负责。

   .. rubric:: 参数含义速查

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 参数或字段
        - 含义
      * - ``r_edge、z_edge、active、mesh``
        - 坐标、有效区域输入；mesh 保存其副本和 nr、nz。
      * - ``theta_span、geometry``
        - 扇区角输入（rad）；输出各单元物理体积、面面积及局部几何参数。
      * - ``rc、hr、hz、xi_bar``
        - 径向中心、径向/轴向半宽（m），以及无量纲径向局部坐标平均。
      * - ``boundary、face_fraction``
        - 四面类型；入口份额取 [0,1]，表示环形面面积比例。

   .. rubric:: 逐个过程的接口声明

   以下声明来自本文件。``intent(in)`` 为输入，``intent(out)`` 为本次调用的输出，
   ``intent(inout)`` 表示原值参与计算并被修改；``allocatable, intent(out)`` 数组由过程分配。
   ``optional`` 可省略，数组形状中的 nr、nz 为网格单元数。过程名中的 sub/fun 前缀不改变 Fortran 调用规则。

   .. rubric:: sub_J02_initialize_mesh

   .. code-block:: fortran

      subroutine sub_J02_initialize_mesh(r_edge, z_edge, active, mesh, ierr)
      real, intent(in) :: r_edge(:), z_edge(:)
      logical, intent(in) :: active(:, :)
      type(sn_mesh_2drz_type), intent(out) :: mesh
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_build_geometry

   .. code-block:: fortran

      subroutine sub_J02_build_geometry(mesh, theta_span, geometry, ierr)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      real, intent(in) :: theta_span
      type(sn_geometry_2drz_type), intent(out) :: geometry
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_initialize_boundary_types

   .. code-block:: fortran

      subroutine sub_J02_initialize_boundary_types(mesh, boundary, ierr)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      type(sn_boundary_2drz_type), intent(out) :: boundary
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_configure_zlo_partial_inlet_boundary

   .. code-block:: fortran

      subroutine sub_J02_configure_zlo_partial_inlet_boundary(mesh, face_fraction, boundary, ierr)
      type(sn_mesh_2drz_type), intent(in) :: mesh
      real, intent(in) :: face_fraction(:)
      type(sn_boundary_2drz_type), intent(inout) :: boundary
      integer, intent(out) :: ierr

   .. rubric:: 测试与源码

   :doc:`对应测试及断言 </tests/011_fluid/J02_tests>` 列出调用本文件的测试项。
   :download:`下载实现源码 <../../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   This file is included by ``mod_J02_neutral_sn_transport_2Drz``.
   :doc:`Module overview <../J02_neutral_sn_transport_2Drz>` · :doc:`Tests </tests/011_fluid/J02_tests>`.
