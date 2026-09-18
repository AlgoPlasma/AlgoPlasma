J02 SN transport tests
======================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 测试目标

   :doc:`J02 模块 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz>` 的测试分为基础输运、反射与部分入口、补充边界与吸收三组。以下目录均相对于 ``tests/011_fluid``。

   .. rubric:: 保正与粒子收支

   源文件：``J02_neutral_sn_transport_2Drz/source_f90/test_J02_positivity.f90``。
   被测过程：``sub_J02_enforce_local_positivity`` 和 ``sub_J02_sweep_direction``。
   局部测试检查负角点、负平均值的常数回退，第一行收支方程，
   非负 P1 系数保持不变，以及负入射粒子率的错误返回。

   输运测试采用 8×8 网格、8 个角方向、1 个速度组，下边界仅两个单元入口取 1，
   其余入口为零。分别设置吸收系数为 0 和 10 m⁻¹，逐方向检查所有单元角点非负，
   并独立累加边界出流与体吸收，要求相对粒子收支误差小于 10⁻¹²。
   反射与部分入口测试还检查迭代完成后的角点和密度非负。
   这些是模块测试，不代表完整 ION 算例或网格精度验证已完成。

   .. rubric:: 基础输运

   源文件：``J02_neutral_sn_transport_2Drz/source_f90/test_J02_neutral_sn_transport_2Drz.f90``。

   .. rubric:: 角度求积节点与权重

   测试子程序：``test_quadrature``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_quadrature.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature>`：``sub_J02_build_phase_quadrature``。

   输入与执行：组合角节点和速度组，并分别使用 midpoint 与 gauss-chebyshev。

   检查内容：方向数正确，权重积分得到速度圆盘面积，一阶角矩抵消；两个名称产生相同节点。

   .. rubric:: 柱坐标网格几何量

   测试子程序：``test_geometry``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_geometry.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry>`：``sub_J02_initialize_mesh``、``sub_J02_build_geometry``。

   输入与执行：建立环形柱坐标单元。

   检查内容：检查体积、径向面积和径向加权平均修正量。

   .. rubric:: 局部体积分算子

   测试子程序：``test_local_volume_operator``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_dg_operator.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_dg_operator>`：``sub_J02_add_volume_matrix``。

   输入与执行：向零矩阵加入柱坐标体积分项。

   检查内容：逐项检查 3×3 矩阵，防止径向权重或基函数导数符号错误。

   .. rubric:: 入口分布的通量归一化

   测试子程序：``test_inflow_normalization``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_quadrature.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature>`：``sub_J02_build_phase_quadrature``。
   * :doc:`sub_J02_sn_source.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_source>`：``sub_J02_normalize_inflow_flux``。

   输入与执行：指定入射分布及目标通量。

   检查内容：对归一化分布重新做离散入射通量积分，结果等于目标值。

   .. rubric:: 入口速度分布

   测试子程序：``test_source_shapes``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_quadrature.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature>`：``sub_J02_build_phase_quadrature``。
   * :doc:`sub_J02_sn_source.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_source>`：``sub_J02_build_maxwellian_inflow_shape``、``sub_J02_build_drifted_maxwellian_inflow_shape``、``sub_J02_normalize_inflow_flux``、``sub_J02_build_mc_crossing_inflow_shape``。

   输入与执行：生成零漂移、正径向漂移 Maxwell 分布，以及穿面概率转换分布。

   检查内容：零漂移满足二维公式，漂移改变方向偏好；储气池和穿面概率分别归一化，保留各速度格的入射比例。

   .. rubric:: 错误码与失败位置

   测试子程序：``test_error_diagnostics``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_quadrature.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature>`：``sub_J02_build_phase_quadrature``。
   * :doc:`sub_J02_sn_source.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_source>`：``sub_J02_build_maxwellian_inflow_shape``。
   * :doc:`sub_J02_sn_error.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_error>`：``fun_J02_error_message``。
   * :doc:`sub_J02_sn_geometry.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry>`：``sub_J02_initialize_mesh``、``sub_J02_build_geometry``。
   * :doc:`sub_J02_sn_sweep.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_sweep>`：``sub_J02_sweep_all_directions``。

   输入与执行：传入非法温度并构造局部求解失败。

   检查内容：返回对应错误码、可读错误信息，以及失败方向和单元索引。

   .. rubric:: 密度与速度矩重构

   测试子程序：``test_reconstruction``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_geometry.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry>`：``sub_J02_initialize_mesh``、``sub_J02_build_geometry``。
   * :doc:`sub_J02_sn_quadrature.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature>`：``sub_J02_build_phase_quadrature``。
   * :doc:`sub_J02_sn_reconstruction.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reconstruction>`：``sub_J02_reconstruct_cell_moments``、``sub_J02_reconstruct_internal_face_fluxes``。

   输入与执行：给定角分布的局部系数。

   检查内容：检查柱坐标平均密度、速度矩和内部面的迎风通量。

   .. rubric:: 反射与部分入口

   源文件：``J02_neutral_sn_transport_2Drz/source_f90/test_J02_reflection_partial_inlet.f90``。

   .. rubric:: 部分面入口的面积与区间

   测试子程序：``test_partial_inlet_geometry``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_geometry.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry>`：``sub_J02_initialize_mesh``。
   * :doc:`sub_J02_sn_reflection.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reflection>`：``sub_J02_build_partial_zlo_inlet``。

   输入与执行：径向边界 [1,2,3]，入口 [1.5,2.5]。

   检查内容：面积份额为 7/12 和 0.45，局部区间分别为 [0,1]、[-1,0]，容差 1e-14；入口跨无效单元时报错。

   .. rubric:: 镜面反射的方向映射

   测试子程序：``test_reflection_map``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_quadrature.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature>`：``sub_J02_build_phase_quadrature``。
   * :doc:`sub_J02_sn_reflection.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reflection>`：``fun_J02_reflected_direction_index``。

   输入与执行：8 个角节点、2 个速度组，分别反射径向和轴向法向。

   检查内容：仅法向分量反号，切向分量和速率保持；容差 2e-15。

   .. rubric:: 局部区间的边界积分

   测试子程序：``test_interval_operators``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_dg_operator.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_dg_operator>`：``sub_J02_add_constant_rhs``、``sub_J02_add_zface_constant_interval_rhs``、``sub_J02_zface_interval_moments``。

   输入与执行：将整面和部分面积分分别加入右端项。

   检查内容：整区间退化为整面算子；特定部分区间矩为 1、1/48、1/12，容差 1e-14。

   .. rubric:: 漫反射的通量归一化

   测试子程序：``test_diffuse_normalization``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_reflection.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reflection>`：``sub_J02_compute_diffuse_wall_constants``。

   输入与执行：给定各方向出射系数，构造壁面 Maxwell 再发射系数。

   检查内容：入射和出射粒子通量相等，绝对容差 2e-13。

   .. rubric:: 混合反射的线性组合

   测试子程序：``test_mixed_reflection_linearity``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_reflection.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reflection>`：``sub_J02_sweep_reflecting``。

   输入与执行：分别执行镜面、漫反射和混合反射扫描。

   检查内容：混合边界算子等于两个纯反射算子的加权组合。

   .. rubric:: 部分面入口的源迭代

   测试子程序：``test_partial_inlet_source_iteration``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_reflection.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reflection>`：``sub_J02_solve_source_iteration``。
   * :doc:`sub_J02_sn_reconstruction.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reconstruction>`：``sub_J02_reconstruct_cell_moments``、``sub_J02_reconstruct_open_boundary_fluxes``。

   输入与执行：入口只占轴向低端面的一部分，其余部分反射。

   检查内容：源迭代收敛，进出粒子率平衡，重构使用正确的入口面积份额。

   .. rubric:: 轴向下边界的紧凑入口数组

   测试子程序：``test_compact_zlo_inflow``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_reflection.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reflection>`：``sub_J02_sweep_reflecting``。
   * :doc:`sub_J02_sn_reconstruction.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reconstruction>`：``sub_J02_reconstruct_open_boundary_fluxes``。

   输入与执行：分别提供完整边界数组和紧凑轴向低端入射数组。

   检查内容：角分布和开放边界重构通量一致。

   .. rubric:: 反射参数的错误处理

   测试子程序：``test_reflection_errors``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_reflection.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reflection>`：``sub_J02_sweep_reflecting``、``sub_J02_solve_source_iteration``。

   输入与执行：反射比例超出 [0,1]，或迭代选项非法。

   检查内容：返回具体反射输入或源迭代选项错误码。

   .. rubric:: 补充边界与吸收

   源文件：``J03_neutral_continuity_faceflux_2Drz/source_f90/test_J02_transport_units.f90``。

   .. rubric:: 轴线处的几何量

   测试子程序：``test_axis_geometry``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_geometry.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry>`：``sub_J02_initialize_mesh``、``sub_J02_build_geometry``。

   输入与执行：单元接触 r=0。

   检查内容：轴面面积为零，体积和径向平均量仍正确。

   .. rubric:: 内部面与边界面的拓扑

   测试子程序：``test_face_topology``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_geometry.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry>`：``sub_J02_initialize_mesh``、``sub_J02_initialize_boundary_types``。

   输入与执行：设置相邻有效单元和无效单元。

   检查内容：有效邻接为内部面，域外默认开放，无效邻接为反射壁。

   .. rubric:: 部分面入口的边界装配

   测试子程序：``test_partial_inlet_boundary``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_geometry.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry>`：``sub_J02_initialize_mesh``、``sub_J02_initialize_boundary_types``、``sub_J02_configure_zlo_partial_inlet_boundary``。

   输入与执行：设置入口面积份额。

   检查内容：仅与入口相交的轴向低端面被标为开放。

   .. rubric:: 吸收项矩阵

   测试子程序：``test_absorption_matrix``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_dg_operator.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_dg_operator>`：``sub_J02_add_absorption_matrix``。

   输入与执行：给定吸收系数，加入局部质量矩阵。

   检查内容：检查柱坐标加权吸收矩阵。

   .. rubric:: 损失频率与吸收系数转换

   测试子程序：``test_frequency_conversion``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_quadrature.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature>`：``sub_J02_build_phase_quadrature``。
   * :doc:`sub_J02_sn_source.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_source>`：``sub_J02_build_sigma_from_frequency``。

   输入与执行：对多个速率使用同一电离频率。

   检查内容：sigma_t=nu/v；负频率报错。

   .. rubric:: 四个边界的通量符号

   测试子程序：``test_four_boundary_signs``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_geometry.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry>`：``sub_J02_initialize_mesh``、``sub_J02_build_geometry``、``sub_J02_initialize_boundary_types``。
   * :doc:`sub_J02_sn_quadrature.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature>`：``sub_J02_build_phase_quadrature``。
   * :doc:`sub_J02_sn_reconstruction.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_reconstruction>`：``sub_J02_reconstruct_open_boundary_fluxes``。

   输入与执行：分别为四个开放面构造入射和出射分布。

   检查内容：积分通量按坐标正方向带符号，低端出射为负。

   .. rubric:: 负吸收系数的错误处理

   测试子程序：``test_negative_sigma_error``。

   被测实现（含本例直接调用的初始化接口）：

   * :doc:`sub_J02_sn_geometry.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_geometry>`：``sub_J02_initialize_mesh``、``sub_J02_build_geometry``。
   * :doc:`sub_J02_sn_quadrature.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_quadrature>`：``sub_J02_build_phase_quadrature``。
   * :doc:`sub_J02_sn_sweep.f90 </rst_files/J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_sweep>`：``sub_J02_sweep_all_directions``。

   输入与执行：扫描输入含负吸收系数。

   检查内容：返回负吸收系数错误码。

   .. rubric:: 运行与结果

   .. code-block:: bash

      bash tests/011_fluid/J02_neutral_sn_transport_2Drz/run.sh
      bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh

   三组程序最近一次均通过。各检查使用与其量纲相应的数值容差。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Basic transport

   ``test_J02_neutral_sn_transport_2Drz.f90`` checks quadrature, cylindrical geometry, the volume matrix, inflow normalization, Maxwell/crossing shapes, failure diagnostics, and moment/flux reconstruction.

   .. rubric:: Reflection and partial inlet

   ``test_J02_reflection_partial_inlet.f90`` checks area fractions 7/12 and 0.45, specular direction mapping, analytic interval moments, diffuse flux conservation, mixed-reflection linearity, source iteration, compact inlet equivalence and invalid options. Interval tolerance is 1e-14; specular-map tolerance is 2e-15; diffuse balance tolerance is 2e-13.

   .. rubric:: Supplementary units

   ``test_J02_transport_units.f90`` in the J03 directory checks axis geometry, face topology, partial-inlet types, absorption matrix, nu/v conversion, all four boundary signs and negative absorption rejection.

   .. rubric:: Result

   Run J02 and J03 scripts. All three executables passed.
