sub_J02_sn_quadrature.f90
=========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 速度空间求积

   源码：``J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature.f90``。
   由 ``mod_J02_neutral_sn_transport_2Drz`` 包含，不能作为独立模块编译。
   :doc:`返回模块总览 <../J02_neutral_sn_transport_2Drz>`。
   正文中的简写过程名省略了所属模块的 sub 前缀，完整接口见下方声明。

   .. rubric:: 求积文件：节点、速度组与权重

   ``sub_J02_sn_quadrature.f90`` 的 ``build_angular_nodes``、``build_speed_groups``、
   ``build_phase_quadrature`` 分别构造角节点、速率组及其直积。
   n_angles 至少为 8 且能被 4 整除，n_speeds 和 speed_max 必须为正。

   .. math::

      \theta_a=\frac{2\pi(a-\tfrac12)}{N_\theta},\quad
      \mu_a=\cos\theta_a,\quad\eta_a=\sin\theta_a,\quad w_a=\frac{2\pi}{N_\theta},
      \qquad v_g=\frac{v_{g-}+v_{g+}}2,\quad w_g=\frac{v_{g+}^2-v_{g-}^2}{2}.

   组合索引为 ``m=(g-1)*n_angles+a``，组合权重为 :math:`w_m=w_aw_g`。
   因而 :math:`\int f\,dv_r\,dv_z\approx\sum_m w_mf_m`；
   权重已包含雅可比 v，密度积分不能再乘一次速率。
   midpoint 与 gauss-chebyshev 是同节点规则的别名。有限最大速率会截断分布尾部。

   .. rubric:: 参数含义速查

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 参数或字段
        - 含义
      * - ``n_angles、scheme``
        - 全圆方向数和求积规则名称；必须满足四象限反射对称布局。
      * - ``n_speeds、speed_max``
        - 速率组数与截断上限（m/s）。
      * - ``mu、eta、speed``
        - 两个方向余弦（无量纲）与节点速率（m/s）。
      * - ``weight、quadrature``
        - 角度权重、速率权重或两者乘积，取决于调用接口；quadrature 存储展平后的组合节点。

   .. rubric:: 逐个过程的接口声明

   以下声明来自本文件。``intent(in)`` 为输入，``intent(out)`` 为本次调用的输出，
   ``intent(inout)`` 表示原值参与计算并被修改；``allocatable, intent(out)`` 数组由过程分配。
   ``optional`` 可省略，数组形状中的 nr、nz 为网格单元数。过程名中的 sub/fun 前缀不改变 Fortran 调用规则。

   .. rubric:: sub_J02_build_angular_nodes

   .. code-block:: fortran

      subroutine sub_J02_build_angular_nodes(n_angles, scheme, mu, eta, weight, ierr)
      integer, intent(in) :: n_angles
      character(len = *), intent(in) :: scheme
      real, allocatable, intent(out) :: mu(:), eta(:), weight(:)
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_build_speed_groups

   .. code-block:: fortran

      subroutine sub_J02_build_speed_groups(n_speeds, speed_max, speed, weight, ierr)
      integer, intent(in) :: n_speeds
      real, intent(in) :: speed_max
      real, allocatable, intent(out) :: speed(:), weight(:)
      integer, intent(out) :: ierr

   .. rubric:: sub_J02_build_phase_quadrature

   .. code-block:: fortran

      subroutine sub_J02_build_phase_quadrature(n_angles, n_speeds, angular_scheme, &
      speed_max, quadrature, ierr)
      integer, intent(in) :: n_angles, n_speeds
      character(len = *), intent(in) :: angular_scheme
      real, intent(in) :: speed_max
      type(sn_quadrature_type), intent(out) :: quadrature
      integer, intent(out) :: ierr

   .. rubric:: 测试与源码

   :doc:`对应测试及断言 </tests/011_fluid/J02_tests>` 列出调用本文件的测试项。
   :download:`下载实现源码 <../../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   This file is included by ``mod_J02_neutral_sn_transport_2Drz``.
   :doc:`Module overview <../J02_neutral_sn_transport_2Drz>` · :doc:`Tests </tests/011_fluid/J02_tests>`.
