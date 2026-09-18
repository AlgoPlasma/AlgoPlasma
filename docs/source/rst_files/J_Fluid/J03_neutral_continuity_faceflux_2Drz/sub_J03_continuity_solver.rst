sub_J03_continuity_solver.f90
=============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 连续性更新与稳态迭代

   源码：``J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_continuity_solver.f90``。
   由 ``mod_J03_neutral_continuity_faceflux_2Drz`` 包含，不能作为独立模块编译。
   :doc:`返回模块总览 <../J03_neutral_continuity_faceflux_2Drz>`。
   正文中的简写过程名省略了所属模块的 sub 前缀，完整接口见下方声明。

   .. rubric:: 求解文件：四面通量怎样取值

   ``sub_J03_cell_fluxes`` 输入 closure、当前 density 及单元索引 i、k，
   输出 frlo、frhi、fzlo、fzhi，即四个按坐标正方向计的面通量。
   内部面用固定速度乘当前迎风密度；开放面使用

   .. math::

      \Gamma_b(n)=\Gamma_{b,\rm in}
      +\frac{\Gamma_{b,\rm out,ref}}{\max(n_{\rm cell,ref},n_{\rm floor})}n_{\rm cell}.

   壁面通量为零。径向下端向外的通量为负，轴向下端同理；
   计算净流出量时再乘负号，不能提前把所有出射通量改为正数。
   J03 中壁面只表示净粒子通量为零，不在这里重新求解镜面或漫反射分布。


   .. rubric:: 求解文件：稳定时间步如何计算

   ``sub_J03_compute_stable_timestep`` 遍历有效单元，累加内部面的绝对速度、
   开放面的绝对出口速度以及损失频率：

   .. math::

      \lambda_K=\nu_K+
      \frac{\sum_{f\in{\rm interior}}A_f|u_f|
      +\sum_{f\in{\rm open}}A_f|u_{b,\rm out}|}{V_K},\qquad
      \Delta t=\frac{\mathrm{CFL}}{\max_K\lambda_K}.

   CFL 必须位于 (0,1]。代码包含全部内部面的绝对速度，而非只累加出流面，
   因而这是保守限制。若所有速率不大于 tiny，返回 dt=1。
   入口为固定粒子率，不作为与本单元密度相乘的损失系数加入该式。


   .. rubric:: 求解文件：单步、残差与稳态迭代

   ``sub_J03_continuity_step`` 输入当前密度、非负体源和正时间步，
   按以下半隐式公式生成 density_new：

   .. math::

      D_K(n)=\frac{A_{r+}\Gamma_{r+}-A_{r-}\Gamma_{r-}
      +A_{z+}\Gamma_{z+}-A_{z-}\Gamma_{z-}}{V_K},\qquad
      n_K^{q+1}=\frac{n_K^q-\Delta tD_K(n^q)+\Delta tS_K}{1+\Delta t\nu_K}.

   无效单元输出零；
   clip_negative 开启时将负更新值置零，关闭时拒绝负输入密度。
   此处截断不具备守恒保证，不能用来掩盖不合理的时间步或闭合数据。

   ``sub_J03_compute_residual`` 不执行时间推进，而是检查给定密度满足稳态方程的程度：

   .. math::

      R_K=D_K(n)+\nu_Kn_K-S_K,\qquad
      R_{\max}=\max_{\rm active}|R_K|,\qquad
      B=\sum_{\rm active}V_KR_K.

   residual、max_abs_residual 的单位为 m⁻³s⁻¹，global_balance 的单位为 s⁻¹。
   内部面几何和符号一致时，其贡献在 B 中抵消；B 剩下边界净流出加体损失减体源。
   B 很小仍可能是正负局部残差抵消，因此应同时检查 R_max。

   ``sub_J03_solve_steady`` 从 density_ref 开始，先算一次固定 dt，再反复调用 continuity_step；
   每步计算有效区域相对密度变化，且同时要求归一化残差达到 residual_tolerance：

   .. math::

      \epsilon_n=\frac{\sum_{K\in{\rm active}}|n_K^{q+1}-n_K^q|}
      {\max(\sum_{K\in{\rm active}}|n_K^q|,\mathrm{tiny})}.

   到达 max_iterations 仍未满足时返回 J03_ERR_NOT_CONVERGED，
   同时保留最后密度、迭代次数和诊断量。
   残差每步检查；progress_interval 控制输出间隔。可选 final_scaled_residual 返回最后的归一化残差。

   .. rubric:: 残差尺度与总量诊断

   ``sub_J03_reference_residual_scale`` 用参考场而非当前场构造固定尺度：

   .. math::

      Q_{\rm ref}=\max_K\left(\frac{\sum_f A_f|\Gamma_f(n_{\rm ref})|}{V_K}
      +|S_K|+\nu_K|n_{K,\rm ref}|\right),\qquad
      \epsilon_R=\frac{\max_K|R_K|}{\max(Q_{\rm ref},\mathrm{tiny})}.

   尺度不含 dt，避免很小的时间步使未平衡的场提前收敛。省略 residual_tolerance 时取
   max(tolerance,100*epsilon(1.0))。这一准则用于固定源项、损失和边界的稳态迭代。

   ``sub_J03_compute_balance`` 返回 inflow、outflow、production、removal，单位均为粒子每秒。
   内部面不计入边界交换；体源和损失按体积积分。相对总量失衡为：

   .. math::

      \epsilon_B=\frac{|\dot N_{\rm out}+\dot N_{\rm loss}-\dot N_{\rm in}-\dot N_{\rm src}|}
      {\max(|\dot N_{\rm in}|+|\dot N_{\rm src}|,|\dot N_{\rm out}|+|\dot N_{\rm loss}|,\mathrm{tiny})}.

   此相对量用于稳态验收。瞬态中总量允许变化，应检查其变化率是否等于入射加体源减出射减损失，
   而不是要求此相对量为零。

   .. rubric:: 瞬态调用

   单步接口的 dt 是以秒为单位的物理时间。给定初始密度后，调用方每步更新体源及电离频率，
   使用不超过稳定限制且能分辨物理变化的时间步。输出 density_new 后再推进时钟；
   单步接口不会自行检查 dt 是否满足 CFL，也不会在内部迭代到稳态。
   全部速率为零时稳定时间步接口返回的 1 秒只是缺省值，不能代替物理时间分辨率选择。

   .. rubric:: 参数含义速查

   .. list-table::
      :header-rows: 1
      :widths: 34 66

      * - 参数或字段
        - 含义
      * - ``closure、density、source_rate``
        - 已初始化的固定闭合、当前密度（m⁻³）、体产生率（m⁻³s⁻¹）。
      * - ``cfl、dt``
        - 无量纲稳定系数与物理时间步（s）；稳态驱动中作为迭代步长。
      * - ``clip_negative、density_new``
        - 是否截断负更新值，以及一次推进输出密度。
      * - ``residual、max_abs_residual、global_balance``
        - 单元残差、最大绝对残差（m⁻³s⁻¹）、体积积分粒子率残差（s⁻¹）。
      * - ``tolerance、max_iterations、iterations、converged``
        - 密度变化阈值、允许步数、实际步数、停止标记；阈值不是残差标准。
      * - ``i、k、frlo/frhi/fzlo/fzhi``
        - 当前单元索引与四面通量，按径向下/上、轴向下/上排列。

   .. rubric:: 逐个过程的接口声明

   以下声明来自本文件。``intent(in)`` 为输入，``intent(out)`` 为本次调用的输出，
   ``intent(inout)`` 表示原值参与计算并被修改；``allocatable, intent(out)`` 数组由过程分配。
   ``optional`` 可省略，数组形状中的 nr、nz 为网格单元数。过程名中的 sub/fun 前缀不改变 Fortran 调用规则。

   .. rubric:: sub_J03_compute_stable_timestep

   .. code-block:: fortran

      subroutine sub_J03_compute_stable_timestep(closure, cfl, dt, ierr)
      type(neutral_transport_closure_2drz_type), intent(in) :: closure
      real, intent(in) :: cfl
      real, intent(out) :: dt
      integer, intent(out) :: ierr

   .. rubric:: sub_J03_continuity_step

   .. code-block:: fortran

      subroutine sub_J03_continuity_step(closure, density, source_rate, dt, clip_negative, &
      density_new, ierr)
      type(neutral_transport_closure_2drz_type), intent(in) :: closure
      real, intent(in) :: density(:, :), source_rate(:, :), dt
      logical, intent(in) :: clip_negative
      real, allocatable, intent(out) :: density_new(:, :)
      integer, intent(out) :: ierr

   .. rubric:: sub_J03_compute_residual

   .. code-block:: fortran

      subroutine sub_J03_compute_residual(closure, density, source_rate, residual, &
      max_abs_residual, global_balance, ierr)
      type(neutral_transport_closure_2drz_type), intent(in) :: closure
      real, intent(in) :: density(:, :), source_rate(:, :)
      real, allocatable, intent(out) :: residual(:, :)
      real, intent(out) :: max_abs_residual, global_balance
      integer, intent(out) :: ierr

   .. rubric:: sub_J03_solve_steady

   .. code-block:: fortran

      subroutine sub_J03_solve_steady(closure, source_rate, cfl, tolerance, max_iterations, &
      clip_negative, density, converged, iterations, final_relative_change, &
      max_abs_residual, global_balance, ierr, progress_interval, residual_tolerance, final_scaled_residual)
      type(neutral_transport_closure_2drz_type), intent(in) :: closure
      real, intent(in) :: source_rate(:, :), cfl, tolerance
      integer, intent(in) :: max_iterations
      logical, intent(in) :: clip_negative
      real, allocatable, intent(out) :: density(:, :)
      logical, intent(out) :: converged
      integer, intent(out) :: iterations, ierr
      integer, intent(in), optional :: progress_interval
      real, intent(in), optional :: residual_tolerance
      real, intent(out), optional :: final_scaled_residual
      real, intent(out) :: final_relative_change, max_abs_residual, global_balance

   .. rubric:: sub_J03_reference_residual_scale

   .. code-block:: fortran

      subroutine sub_J03_reference_residual_scale(closure, source_rate, scale)
      type(neutral_transport_closure_2drz_type), intent(in) :: closure
      real, intent(in) :: source_rate(:, :)
      real, intent(out) :: scale

   .. rubric:: sub_J03_compute_balance

   .. code-block:: fortran

      subroutine sub_J03_compute_balance(closure, density, source_rate, inflow, outflow, &
          production, removal, relative_balance, ierr)
      type(neutral_transport_closure_2drz_type), intent(in) :: closure
      real, intent(in) :: density(:, :), source_rate(:, :)
      real, intent(out) :: inflow, outflow, production, removal, relative_balance
      integer, intent(out) :: ierr

   .. rubric:: sub_J03_cell_fluxes

   .. code-block:: fortran

      subroutine sub_J03_cell_fluxes(closure, density, i, k, frlo, frhi, fzlo, fzhi)
      type(neutral_transport_closure_2drz_type), intent(in) :: closure
      real, intent(in) :: density(:, :)
      integer, intent(in) :: i, k
      real, intent(out) :: frlo, frhi, fzlo, fzhi

   .. rubric:: 测试与源码

   :doc:`对应测试及断言 </tests/011_fluid/J03_tests>` 列出调用本文件的测试项。
   :download:`下载实现源码 <../../../../../J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_continuity_solver.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   This file is included by ``mod_J03_neutral_continuity_faceflux_2Drz``.
   :doc:`Module overview <../J03_neutral_continuity_faceflux_2Drz>` · :doc:`Tests </tests/011_fluid/J03_tests>`.
