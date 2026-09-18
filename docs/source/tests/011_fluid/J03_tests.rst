J03 continuity tests
======================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 测试目标

   :doc:`J03 模块 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz>` 的单元测试检查闭合系数与更新公式；连接测试检查来自 J01/J02 的接口和稳态求解。以下文件均位于 ``tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/source_f90``。

   .. rubric:: 连续性方程单元测试

   源文件：``test_J03_continuity_units.f90``。

   .. rubric:: 迎风闭合的速度与符号

   测试子程序：``test_upwind_closure_signs``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J03_transport_closure.f90 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_transport_closure>`：``sub_J03_initialize_transport_closure``。

   输入与执行：三单元密度 [2,4,8]，两个面通量 [6,-12]。

   检查内容：构造面速度 [3,-1.5]，验证除以正确的迎风密度。

   .. rubric:: 时间步限制的解析值

   测试子程序：``test_exact_cfl``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J03_continuity_solver.f90 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_continuity_solver>`：``sub_J03_compute_stable_timestep``。

   输入与执行：体积 6，参考密度 2，出口面积 3，参考通量 4，损失频率 1，CFL=0.8。

   检查内容：稳定时间步为 0.4，绝对容差 1e-13。

   .. rubric:: 单步更新与守恒残差

   测试子程序：``test_step_and_residual_formula``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J03_continuity_solver.f90 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_continuity_solver>`：``sub_J03_continuity_step``、``sub_J03_compute_residual``。

   输入与执行：当前密度 3，体源 4，损失频率 1，净通量为零，时间步 0.5。

   检查内容：新密度为 10/3，局部残差 -1，体积积分残差 -6，容差 1e-13。

   .. rubric:: 轴线零面积边界

   测试子程序：``test_axis_zero_area``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J03_transport_closure.f90 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_transport_closure>`：``sub_J03_initialize_transport_closure``。

   输入与执行：径向低端面面积为零、单元体积为正。

   检查内容：初始化成功，接受对称轴。

   .. rubric:: 非法面拓扑

   测试子程序：``test_invalid_topology``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J03_transport_closure.f90 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_transport_closure>`：``sub_J03_initialize_transport_closure``。

   输入与执行：把没有邻居的域边界面标成内部面。

   检查内容：返回 J03_ERR_FACE_TYPE。

   .. rubric:: 未收敛时的诊断

   测试子程序：``test_nonconvergence_diagnostic``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J03_continuity_solver.f90 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_continuity_solver>`：``sub_J03_solve_steady``。

   输入与执行：只允许一次迭代，设置无法在一次迭代满足的阈值。

   检查内容：返回未收敛错误码，converged 为假，迭代次数恰为 1。

   .. rubric:: 负参考密度的截断

   测试子程序：``test_negative_reference_clipping``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J03_transport_closure.f90 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_transport_closure>`：``sub_J03_initialize_transport_closure``。
   * :doc:`sub_J03_continuity_solver.f90 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_continuity_solver>`：``sub_J03_continuity_step``。

   输入与执行：参考密度 -2，分别开启和关闭负值截断。

   检查内容：开启时新密度截为零，关闭时返回负密度错误；该检查不证明截断具有守恒性。

   .. rubric:: 接口与守恒测试

   源文件：``test_J03_neutral_continuity_faceflux_2Drz.f90``。

   .. rubric:: J01 面通量接口

   测试子程序：``test_j01_faceflux``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J01_continuity_freeflow_2Drz.f90 </rst_files/J_Fluid/J01_free_molecular/sub_J01_continuity_freeflow_2Drz>`：``sub_J01_build_faceflux_2Drz``。

   输入与执行：两单元 J01 通量构造。

   检查内容：内部通量 2、出口通量 4，容差 1e-13。

   .. rubric:: J02 输出接口

   测试子程序：``test_j02_contract``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_geometry.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry>`：``sub_J02_initialize_mesh``、``sub_J02_build_geometry``、``sub_J02_initialize_boundary_types``。
   * :doc:`sub_J02_sn_quadrature.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature>`：``sub_J02_build_phase_quadrature``。
   * :doc:`sub_J02_sn_source.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_source>`：``sub_J02_build_sigma_from_frequency``、``sub_J02_build_mc_crossing_pdf_inflow_shape``、``sub_J02_build_mc_crossing_bins_inflow_shape``。
   * :doc:`sub_J02_sn_reconstruction.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reconstruction>`：``sub_J02_reconstruct_open_boundary_fluxes``。
   * :doc:`sub_J02_sn_sweep.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_sweep>`：``sub_J02_sweep_all_directions``。

   输入与执行：构造电离系数、两种穿面概率入口和开放边界通量。

   检查内容：检查 nu/v、连续概率密度与离散概率质量的等价性、入出射符号；开放扫描拒绝反射壁。

   .. rubric:: 边界驱动的稳态平衡

   测试子程序：``test_j03_boundary_equilibrium``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J03_continuity_solver.f90 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_continuity_solver>`：``sub_J03_solve_steady``。
   * :doc:`sub_J03_transport_closure.f90 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_transport_closure>`：``sub_J03_import_J01_closure``、``sub_J03_import_J02_closure``。

   输入与执行：单元入口与出口在参考密度处平衡，分别从 J01/J02 导入。

   检查内容：两种导入产生相同闭合，稳态密度保持 2、残差为零，容差 1e-12。

   .. rubric:: 电离损失下的稳态平衡

   测试子程序：``test_j03_ionization_equilibrium``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J03_continuity_solver.f90 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_continuity_solver>`：``sub_J03_solve_steady``。

   输入与执行：封闭单元中加入体源和线性损失。

   检查内容：稳态密度等于 S/nu=2，容差 2e-11。

   .. rubric:: 封闭区域的总量守恒

   测试子程序：``test_j03_closed_conservation``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J03_transport_closure.f90 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_transport_closure>`：``sub_J03_initialize_transport_closure``。
   * :doc:`sub_J03_continuity_solver.f90 </rst_files/J_Fluid/J03_neutral_continuity_faceflux_2Drz/sub_J03_continuity_solver>`：``sub_J03_continuity_step``。

   输入与执行：封闭两单元、零体源和零损失。

   检查内容：内部面贡献抵消，单步总量保持，容差 1e-13。

   .. rubric:: 运行与结果

   .. code-block:: bash

      bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh

   脚本依次运行 4 个程序，包括 :doc:`J01 二维测试 <J01_tests>` 和 :doc:`J02 补充测试 <J02_tests>`。最近一次全部通过。应用中的迭代相对变化和残差是不同指标，详见 :doc:`应用测试 <application_tests>`。

   .. rubric:: 瞬态、守恒与回归错误测试

   源文件：``J03_neutral_continuity_faceflux_2Drz/source_f90/test_J03_transient.f90``。

   * test_faces：构造两单元域，单侧内部面应返回 J03_ERR_FACE_TYPE；共享面积不一致返回 J03_ERR_GEOMETRY。
   * test_small_timestep：纯损失、CFL=1e-12 时，密度变化虽小，残差仍大，必须返回未收敛；独立残差阈值也须满足。
   * test_time_evolution：在物理时刻 t=1 检查 n=exp(-2t)、恒定源损解及前半段 nu=1、后半段 nu=3 的解。每个物理步更新损失频率。
   * test_transport：两单元固定面速度输运，检查半离散解析解 n1=exp(-t)、n2=2-exp(-t)，以及整个演化的总量守恒；再检查边界与体源损的粒子率。

   指数衰减使用 40、80 步，绝对误差分别约 6.7104e-3、3.3693e-3，误差比约 1.992。
   判据为时间步减半时误差比处于 1.9–2.1。其他数值容差写在各断言旁。
   这里验证的是时间离散；两单元输运解析解针对离散空间算子，不代表空间网格收敛。

   .. rubric:: 应用输入与验收逻辑测试

   ``source_f90/test_application_case.f90`` 调用 application_case.f90，检查有效单元数、通道出口索引、ION 窗口峰值、域外零损失及 B0 零损失。
   ``test_application_checks.py`` 检查验收逻辑：平衡场通过，失衡或大残差不通过，缺失/非有限诊断报错；同时检查随仓库提供的网格和缺失/错误输入。

   .. code-block:: bash

      bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh
      python3 tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/test_application_checks.py


.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Continuity units

   The seven functions in ``test_J03_continuity_units.f90`` verify upwind velocities [3,-1.5], timestep 0.4, update 10/3, residual -1 and integrated balance -6, zero-area axis acceptance, invalid topology, one-step nonconvergence and optional negative clipping. Algebraic tolerance is 1e-13.

   .. rubric:: Connected tests

   ``test_J03_neutral_continuity_faceflux_2Drz.f90`` checks J01 fluxes, the J02 interface, equivalent imports, boundary equilibrium n=2, source/loss equilibrium n=2, and closed-domain conservation. Equilibrium tolerances are 1e-12 and 2e-11 respectively.

   .. rubric:: Run

   Run the J03 script. Its four executables include J01 and J02 supplementary units; all passed.
