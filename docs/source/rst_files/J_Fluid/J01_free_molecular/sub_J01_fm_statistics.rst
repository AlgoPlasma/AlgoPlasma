sub_J01_fm_statistics.f90
=========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   由 ``mod_J01_neutral_free_molecular_2Drz`` 包含，编译时只编译 mod 文件，不单独编译此 sub 文件。
   :doc:`模块总览 <particle_transport>`。

   .. rubric:: 原始统计结构

   ``sub_J01_initialize_fm_tally(nr,nz,tally)`` 分配并清零统计。``residence`` 是累积驻留时间（s），``moment_r/z`` 是速度乘时间累积量（m），均为 (nr,nz)；``count_r/z`` 是有符号内部穿越次数，形状为 (nr-1,nz)、(nr,nz-1)；``boundary_count`` 为 (4,nr,nz) 的边界出射计数。

   .. rubric:: 场量归一化

   ``sub_J01_finalize_fm_tally`` 输入网格几何、有效单元、每历史粒子率和统计结构，分配并输出密度、平均速度、内部面和边界出射通量。调用方保证尺寸匹配与有效体积为正。

   .. math::

      V_{ik}=\frac{\Theta}{2}(r_{i+1}^2-r_i^2)\Delta z_k,\qquad A_r=\Theta r_f\Delta z_k,\qquad A_z=\frac{\Theta}{2}(r_{i+1}^2-r_i^2).

   .. math::

      n_{ik}=\frac{\dot w\sum_p\tau_{p,ik}}{V_{ik}},\qquad u_{r,z}=\frac{\sum_pv_{r,z,p}\tau_p}{\sum_p\tau_p},\qquad \Gamma_f=\frac{\dot w(N_f^+-N_f^-)}{A_f}.

   通量直接来自穿面事件，不用单元均速乘密度替代。未访问单元密度和速度为零，轴线零面积面通量置零。低端出射为负，高端为正，符号统一按坐标正向。这里不生成入射通量、不推进连续性方程。

   输出数组由本过程分配。密度和两个平均速度均为 ``(nr,nz)``；
   径向、轴向内部通量分别为 ``(nr-1,nz)`` 和 ``(nr,nz-1)``，
   边界出射通量为 ``(4,nr,nz)``。密度单位 m⁻³，速度 m/s，通量 m⁻²s⁻¹。
   单元只有一个径向或轴向网格时，该方向的内部面数组长度为零，这是正常情况。

   .. rubric:: 接口声明

   .. code-block:: fortran

      subroutine sub_J01_initialize_fm_tally(nr, nz, tally)
      integer, intent(in) :: nr, nz
      type(fm_tally_2drz_type), intent(out) :: tally

   .. code-block:: fortran

      subroutine sub_J01_finalize_fm_tally(r_edge, z_edge, theta_span, active, history_rate, &
      tally, density, velocity_r, velocity_z, flux_r, flux_z, boundary_outflow_flux)
      real, intent(in) :: r_edge(:), z_edge(:), theta_span, history_rate
      logical, intent(in) :: active(:, :)
      type(fm_tally_2drz_type), intent(in) :: tally
      real, allocatable, intent(out) :: density(:,:), velocity_r(:,:), velocity_z(:,:)
      real, allocatable, intent(out) :: flux_r(:,:), flux_z(:,:), boundary_outflow_flux(:,:,:)

   .. rubric:: 测试与源码

   :doc:`模块测试 </tests/011_fluid/J01_fm_tests>` 按子程序列出输入与断言。
   :download:`下载源码 <../../../../../J_Fluid/J01_free_molecular/sub_J01_fm_statistics.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   Included by ``mod_J01_neutral_free_molecular_2Drz``. Compile the module, not this file.
   :doc:`Module overview <particle_transport>` · :doc:`Tests </tests/011_fluid/J01_fm_tests>`.
