sub_J01_fm_trajectory.f90
=========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   由 ``mod_J01_neutral_free_molecular_2Drz`` 包含，编译时只编译 mod 文件，不单独编译此 sub 文件。
   :doc:`模块总览 <particle_transport>`。

   .. rubric:: 单条轨迹推进

   ``sub_J01_trace_fm_history`` 输入网格、有效单元、面类型、反射比例、壁面热速度标准差、事件上限与跨面位移 ``eps_r/eps_z``。``r,z,ur,uz`` 原地更新，``tally`` 累加而不清零。调用方必须预先分配统计数组并保证拓扑有效，主调度接口负责这些检查。

   单元内速度恒定，沿运动方向确定下一径向面和轴向面，取最早到达的事件：

   .. math::

      t_r=\frac{r_f-r}{v_r},\qquad t_z=\frac{z_f-z}{v_z},\qquad \Delta t=\min(t_r,t_z).

   该方向无运动时将候选时间设为大数。每段飞行累加驻留时间 Δt 和速度矩 vΔt。穿内部面按坐标正负记 ±1；开放面记录出射并结束；壁面调用反射过程。跨面微位移避免重复命中同一界面。

   ``escaped`` 表示正常开放面逃逸，``truncated`` 表示未完成；事件耗尽、位置越界或无法找到下一事件均不计为成功。当前没有分别返回这几种截断原因的错误码。

   .. rubric:: 网格定位

   ``fun_J01_locate_cell(x,edge)`` 用二分搜索返回满足 ``edge(i)<=x<edge(i+1)`` 的单元编号，共享边归上侧，最外侧高端不属于网格；域外返回 -1。不做插值。

   主入口取 ``eps_r=max(1e-12,1e-9*min(Δr))``，轴向位移同理。
   这些位移只用于数值定位，不代表额外飞行时间；因此确定性轨迹测试也包含该位移修正。
   直接调用本过程时，应使位移远小于网格尺寸。

   .. rubric:: 模型范围

   仅有径向和轴向速度，按 r-z 平面直线推进，没有周向运动引起的轨迹弯曲，没有体内电离或分子间碰撞。采用柱坐标体积并不等于完整三速度轴对称分子模型。

   .. rubric:: 接口声明

   .. code-block:: fortran

      subroutine sub_J01_trace_fm_history(r_edge, z_edge, active, face_type, diffuse_fraction, &
      sigma_wall, max_events, eps_r, eps_z, r, z, ur, uz, tally, escaped, truncated)
      real, intent(in) :: r_edge(:), z_edge(:), diffuse_fraction, sigma_wall, eps_r, eps_z
      logical, intent(in) :: active(:, :)
      integer, intent(in) :: face_type(:, :, :), max_events
      real, intent(inout) :: r, z, ur, uz
      type(fm_tally_2drz_type), intent(inout) :: tally
      logical, intent(out) :: escaped, truncated

   .. code-block:: fortran

      integer function fun_J01_locate_cell(x, edge)
      real, intent(in) :: x, edge(:)

   .. rubric:: 测试与源码

   :doc:`模块测试 </tests/011_fluid/J01_fm_tests>` 按子程序列出输入与断言。
   :download:`下载源码 <../../../../../J_Fluid/J01_free_molecular/sub_J01_fm_trajectory.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   Included by ``mod_J01_neutral_free_molecular_2Drz``. Compile the module, not this file.
   :doc:`Module overview <particle_transport>` · :doc:`Tests </tests/011_fluid/J01_fm_tests>`.
