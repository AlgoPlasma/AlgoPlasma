sub_J01_free_molecular_mc_2Drz.f90
==================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   由 ``mod_J01_neutral_free_molecular_2Drz`` 包含，编译时只编译 mod 文件，不单独编译此 sub 文件。
   :doc:`模块总览 <particle_transport>`。

   .. rubric:: 调度与返回值

   本文件组织前处理流程：检查输入与面拓扑、准备入口、清零统计量、设置种子、逐条推进轨迹、归一化。不包含器件尺寸、算例名和输出路径。

   ``r_edge(nr+1)``、``z_edge(nz+1)`` 是单调递增的边界坐标（m）；``theta_span`` 是扇区角（rad）。径向坐标非负。``active(nr,nz)`` 指定有效单元，``face_type(4,nr,nz)`` 指定内部面（0）、开放面（1）和壁面（2）。内部面必须连接有效单元，两侧标记须一致。

   ``inlet_r_lo/hi`` 为轴向低端入口半径范围。质量单位 kg，温度 K，漂移速度 m/s。``inlet_density`` 只用于粒子率归一化，``diffuse_fraction`` 为漫反射概率。``n_histories`` 是轨迹数，``max_events`` 是单轨迹事件上限；它们不是物理时间。种子设定由 ``random_seed_value`` 控制，可选参数 ``progress_interval`` 指定日志间隔。

   输出密度和平均速度形状为 (nr,nz)，内部通量为 (nr-1,nz)、(nr,nz-1)，边界出射通量为 (4,nr,nz)。密度单位 m⁻³，速度 m/s，通量 m⁻²s⁻¹，``history_rate`` 为单历史代表的粒子率（s⁻¹）。场数组由本过程分配；输入检查失败时不可读取场数组。

   ``n_completed`` 只计正常逃逸，``n_truncated`` 计未完整结束的轨迹。``ierr=0`` 表示成功；101 为形状错误，105 为配置或拓扑错误，106 为跟踪未完成。截断时场含不完整统计，不能作为有效前处理结果。

   .. rubric:: 与 J03 连接

   应用驱动按相同入口区间和粒子率构造入射通量，将参考密度、内部通量、边界入射/出射通量和几何交给 ``sub_J03_initialize_transport_closure``。J03 不读取粒子轨迹，也不需要链接 J01。

   .. rubric:: 接口声明

   .. code-block:: fortran

      subroutine sub_J01_free_molecular_mc_2Drz(r_edge, z_edge, theta_span, active, &
      face_type, inlet_r_lo, inlet_r_hi, neutral_mass, inlet_temperature, &
      wall_temperature, inlet_drift_z, inlet_density, diffuse_fraction, &
      n_histories, max_events, random_seed_value, density, velocity_r, velocity_z, &
      flux_r, flux_z, boundary_outflow_flux, history_rate, n_completed, n_truncated, &
      ierr, progress_interval)
      real, intent(in) :: r_edge(:), z_edge(:), theta_span
      logical, intent(in) :: active(:, :)
      integer, intent(in) :: face_type(:, :, :)
      real, intent(in) :: inlet_r_lo, inlet_r_hi, neutral_mass, inlet_temperature, &
      wall_temperature, inlet_drift_z, inlet_density, diffuse_fraction
      integer, intent(in) :: n_histories, max_events, random_seed_value
      real, allocatable, intent(out) :: density(:, :), velocity_r(:, :), velocity_z(:, :), &
      flux_r(:, :), flux_z(:, :), boundary_outflow_flux(:, :, :)
      real, intent(out) :: history_rate
      integer, intent(out) :: n_completed, n_truncated, ierr
      integer, intent(in), optional :: progress_interval

   .. rubric:: 测试与源码

   :doc:`模块测试 </tests/011_fluid/J01_fm_tests>` 按子程序列出输入与断言。
   :download:`下载源码 <../../../../../J_Fluid/J01_free_molecular/sub_J01_free_molecular_mc_2Drz.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   Included by ``mod_J01_neutral_free_molecular_2Drz``. Compile the module, not this file.
   :doc:`Module overview <particle_transport>` · :doc:`Tests </tests/011_fluid/J01_fm_tests>`.
