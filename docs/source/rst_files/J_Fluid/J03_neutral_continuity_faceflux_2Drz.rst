J03_neutral_continuity_faceflux_2Drz
=================================================================

.. toctree::
   :maxdepth: 1
   :hidden:

   J03_neutral_continuity_faceflux_2Drz/sub_J03_transport_closure
   J03_neutral_continuity_faceflux_2Drz/sub_J03_continuity_solver
   J03_neutral_continuity_faceflux_2Drz/sub_J03_error

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 按实现文件阅读

   * :doc:`面速度闭合与导入：sub_J03_transport_closure.f90 <J03_neutral_continuity_faceflux_2Drz/sub_J03_transport_closure>`
   * :doc:`连续性更新与稳态迭代：sub_J03_continuity_solver.f90 <J03_neutral_continuity_faceflux_2Drz/sub_J03_continuity_solver>`
   * :doc:`错误码说明：sub_J03_error.f90 <J03_neutral_continuity_faceflux_2Drz/sub_J03_error>`

   .. rubric:: 模块职责

   J03 的主要用途是按物理时间推进中性粒子连续性方程。J01 或 J02 提供参考密度和面通量，
   J03 据此确定面速度；之后更新的是密度，面通量随当前密度变化。稳态迭代是额外提供的辅助入口。

   .. math::

      \frac{\partial n}{\partial t}+\frac{1}{r}\frac{\partial(r\Gamma_r)}{\partial r}
      +\frac{\partial\Gamma_z}{\partial z}=S-\nu n.

   .. rubric:: 闭合与更新公式

   内部面取通量方向上的迎风参考密度：

   .. math::

      u_f=\frac{\Gamma_{f,\mathrm{ref}}}{\max(n_{\mathrm{upwind,ref}},n_{\mathrm{floor}})},
      \qquad \Gamma_f(n)=u_fn_{\mathrm{upwind}}.

   每次调用使用当前给定的入口通量；开放边界出口通量按当前单元密度缩放。每个单元的更新式为

   .. math::

      n^{q+1}=\frac{n^q-\Delta t D(n^q)+\Delta t S}{1+\Delta t\nu},
      \quad D=\frac{A_{r+}\Gamma_{r+}-A_{r-}\Gamma_{r-}
      +A_{z+}\Gamma_{z+}-A_{z-}\Gamma_{z-}}{V}.

   正体源 S 增加密度，损失频率 nu 采用半隐式处理。

   .. rubric:: 函数、输入与输出

   .. list-table::
      :header-rows: 1

      * - 接口
        - 输入
        - 输出与行为
      * - sub_J03_initialize_transport_closure
        - 几何、面类型、参考密度、内面/边界通量、nu、密度下限比例
        - closure：保存几何与参考场，计算迎风面速度和出口速度。
      * - sub_J03_import_J01_closure / sub_J03_import_J02_closure
        - 相同的标准化数组
        - 调用共用初始化逻辑；不在函数内重新运行输运。
      * - sub_J03_compute_stable_timestep
        - closure、cfl
        - dt、ierr；以面积/体积加权的绝对面速度和损失频率给出保守时间步。
      * - sub_J03_continuity_step
        - closure、density、source_rate、dt、clip_negative
        - 分配 density_new 并完成一次更新。
      * - sub_J03_compute_residual
        - closure、density、source_rate
        - residual=D+nu*n-S；最大绝对残差；sum(V*residual)。
      * - sub_J03_compute_balance
        - closure、当前密度、体源
        - 入射、出射、体产生、体损失粒子率及相对总量失衡。
      * - sub_J03_solve_steady
        - closure、体源、cfl、阈值、最大迭代数、截断选项
        - 从参考密度开始迭代；返回密度、收敛标记、步数、变化量及残差。
      * - fun_J03_error_message
        - ierr
        - 错误说明。


   .. rubric:: 数组布局

   单元数组为 ``(nr,nz)``；径向内部面为 ``(nr-1,nz)``，轴向内部面为 ``(nr,nz-1)``；面类型、面积与边界通量为 ``(4,nr,nz)``。四面的顺序与 J01/J02 相同，通量正负号按坐标正方向。

   .. rubric:: 收敛与限制

   稳态入口同时检查有效单元的相对变化与归一化方程残差。相对变化为：

   .. math::

      \epsilon_q=\frac{\sum|n^{q+1}-n^q|}{\max(\sum|n^q|,\mathrm{tiny})}.

   归一化残差为 ``max_abs_residual / reference_scale``。reference_scale 在迭代前用参考密度、
   各面绝对通量、体源与损失建立，单位为 m⁻³s⁻¹，不随时间步和当前迭代密度缩小。
   两项都满足才返回 converged。可选 residual_tolerance 独立指定残差阈值；
   省略时取 max(tolerance,100*epsilon(1.0))，避免要求残差低于浮点舍入尺度。
   达到步数上限仍不满足时返回未收敛错误。

   瞬态计算不使用该停止条件：从给定初始密度推进到指定物理时刻即可。
   在 PIC/MCC 耦合中，每个中性时间步可更新 source_rate、closure%loss_frequency 和入口通量；
   重新计算允许时间步，必要时子步进。不要在每个 PIC 步内反复迭代到稳态。

   开启 clip_negative 会将负更新值置零，可能改变总粒子数；它不能代替保正离散。固定面速度是一种闭合假设，较大损失或边界变化可能需要重新计算输运场。


   .. rubric:: 文件分工及共享数据

   ``mod_J03_neutral_continuity_faceflux_2Drz.f90`` 定义
   ``neutral_transport_closure_2drz_type``、面常量及错误码，在 contains 下包含三个实现文件。
   closure 中 active、face_type、volume、face_area 保存计算域；
   density_ref、flux_r_ref、flux_z_ref 保存前处理结果；
   velocity_r_face、velocity_z_face、boundary_outflow_velocity 保存固定闭合系数；
   boundary_inflow_flux 和 loss_frequency 保存给定入口与线性损失。

   ``sub_J03_transport_closure.f90`` 负责初始化闭合，不推进密度。
   ``sub_J03_continuity_solver.f90`` 负责面通量、时间步、单步更新、残差与稳态迭代。
   ``sub_J03_error.f90`` 的 fun_J03_error_message 只把状态码转换成说明。

   .. rubric:: 测试

   :doc:`J03 子测试 </tests/011_fluid/J03_tests>` 给出闭合、时间步、单步公式、残差及平衡算例。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Model

   J03 advances transient continuity, with an optional steady driver. It uses :math:`u_f=\Gamma_{\rm ref}/\max(n_{\rm upwind,ref},n_{\rm floor})` and evaluates flux with the current upwind density. Inflow is fixed, outflow scales with density, and loss is semi-implicit.

   .. rubric:: Interfaces

   Initialize/import the closure, compute a stable timestep, then call continuity_step or solve_steady. compute_residual returns divergence plus loss minus source, its maximum magnitude and volume-integrated balance. Scalars use physical SI units; arrays follow the shared four-face convention.

   .. rubric:: Convergence

   The main step advances physical time. The optional steady solver requires both relative L1 iterate change and a scaled residual threshold. The residual scale is fixed from reference transport and source/loss rates, independent of dt. Clipping can change particle number; significant transport changes may invalidate the frozen closure.

   .. rubric:: Tests

   :doc:`J03 tests </tests/011_fluid/J03_tests>`.
