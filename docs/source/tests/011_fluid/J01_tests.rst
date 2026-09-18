J01 continuity and face-flux tests
======================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 测试目标

   :doc:`J01 模块 </rst_files/J_Fluid/J01_free_molecular/continuity>` 包含三维更新与二维接口，本页分别说明两组子测试。独立粒子模块的分层检查见 :doc:`J01_fm_tests`。以下源文件位置均相对于 ``tests/011_fluid``。

   .. rubric:: 三维更新测试

   源文件：``J01_free_molecular/source_f90/test_J01_continuity_freeflow.f90``。

   .. rubric:: 零速度下的密度保持

   测试子程序：``test_zero_velocity_identity``。

   调用的源码与过程：

   * :doc:`sub_J01_continuity_freeflow.f90 </rst_files/J_Fluid/J01_free_molecular/sub_J01_continuity_freeflow>`：``sub_J01_continuity_freeflow``。

   输入与执行：速度与扣减项为零；调用三维更新。

   检查内容：密度不变；n0 精确复制原密度。

   .. rubric:: 密度扣减项的符号

   测试子程序：``test_source_sign``。

   调用的源码与过程：

   * :doc:`sub_J01_continuity_freeflow.f90 </rst_files/J_Fluid/J01_free_molecular/sub_J01_continuity_freeflow>`：``sub_J01_continuity_freeflow``。

   输入与执行：速度为零，设置非零 s。

   检查内容：更新区满足 n_new=n_old-s；保护层不变。

   .. rubric:: 三维单步更新公式

   测试子程序：``test_single_step_reference``。

   调用的源码与过程：

   * :doc:`sub_J01_continuity_freeflow.f90 </rst_files/J_Fluid/J01_free_molecular/sub_J01_continuity_freeflow>`：``sub_J01_continuity_freeflow``。

   输入与执行：确定性的三维密度、速度与 s，独立计算三方向通量。

   检查内容：逐点检查密度、旧场副本和保护层；密度绝对容差 1e-12。

   .. rubric:: 六个方向的整格平移

   测试子程序：``test_unit_shifts``。

   调用的源码与过程：

   * :doc:`sub_J01_continuity_freeflow.f90 </rst_files/J_Fluid/J01_free_molecular/sub_J01_continuity_freeflow>`：``sub_J01_continuity_freeflow``。

   输入与执行：x、y、z 方向速度依次取 +1 或 -1，其余为零。

   检查内容：六种情况下均为一个网格距离的平移；验证方向、索引和保护层。

   .. rubric:: 周期边界下的总量守恒

   测试子程序：``test_periodic_mass_conservation``。

   调用的源码与过程：

   * :doc:`sub_J01_continuity_freeflow.f90 </rst_files/J_Fluid/J01_free_molecular/sub_J01_continuity_freeflow>`：``sub_J01_continuity_freeflow``。

   输入与执行：周期保护层、非均匀场、零 s。

   检查内容：更新区密度总和守恒；容差按测试内总量缩放。

   .. rubric:: 二维通量与粒子历史测试

   源文件：``J01_free_molecular/source_f90/test_J01_faceflux_2Drz_units.f90``，由 J01_free_molecular/run.sh 执行。

   .. rubric:: 内部面通量的方向

   测试子程序：``test_lax_friedrichs_signs``。

   调用的源码与过程：

   * :doc:`sub_J01_continuity_freeflow_2Drz.f90 </rst_files/J_Fluid/J01_free_molecular/sub_J01_continuity_freeflow_2Drz>`：``sub_J01_build_faceflux_2Drz``。

   输入与执行：两单元密度 [2,5]，速度取 +1、-1 和 [1,3]。

   检查内容：面通量分别为 2、-5、4，绝对容差 1e-13。

   .. rubric:: 边界流出通量的符号

   测试子程序：``test_boundary_outflow_signs``。

   调用的源码与过程：

   * :doc:`sub_J01_continuity_freeflow_2Drz.f90 </rst_files/J_Fluid/J01_free_molecular/sub_J01_continuity_freeflow_2Drz>`：``sub_J01_build_faceflux_2Drz``。

   输入与执行：密度 3，径向速度 -2，轴向速度 4。

   检查内容：四面流出通量为 -6、0、0、12；只记录向外运动分量。

   .. rubric:: 柱坐标单步更新公式

   测试子程序：``test_cylindrical_step_formula``。

   调用的源码与过程：

   * :doc:`sub_J01_continuity_freeflow_2Drz.f90 </rst_files/J_Fluid/J01_free_molecular/sub_J01_continuity_freeflow_2Drz>`：``sub_J01_continuity_step_2Drz``。

   输入与执行：体积 2，入口面积 3、通量 2，密度 2，体源 4，损失频率 1，时间步 0.5。

   检查内容：新密度为 (2+0.5×3+0.5×4)/1.5；检查面积/体积与半隐式损失。

   .. rubric:: 单网格自由分子输运

   测试子程序：``test_free_molecular_single_cell``。

   调用的源码与过程：

   * :doc:`sub_J01_free_molecular_mc_2Drz.f90 </rst_files/J_Fluid/J01_free_molecular/sub_J01_free_molecular_mc_2Drz>`：``sub_J01_free_molecular_mc_2Drz``。

   输入与执行：r=[1,2]、z=[0,1]，径向镜面壁，轴向开放；200 条历史，种子 17。

   检查内容：全部完成且无截断；出口面积×通量等于 200×历史粒子率，密度和轴向均速为正。该算例不覆盖一般热分布的统计精度。

   .. rubric:: 非法密度输入

   测试子程序：``test_input_errors``。

   调用的源码与过程：

   * :doc:`sub_J01_continuity_freeflow_2Drz.f90 </rst_files/J_Fluid/J01_free_molecular/sub_J01_continuity_freeflow_2Drz>`：``sub_J01_build_faceflux_2Drz``。

   输入与执行：传入负密度。

   检查内容：返回 J01_ERR_NEGATIVE_INPUT。

   .. rubric:: 运行与结果

   .. code-block:: bash

      bash tests/011_fluid/J01_free_molecular/run.sh

   最近一次三维测试最大绝对误差为 ``1.7053e-13``；两组均通过。完整场测试见 :doc:`应用测试 <application_tests>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Legacy tests

   The source checks identity, the subtractive source convention, an independent 3D step, six unit shifts and periodic conservation. Density tolerance is 1e-12; old-state copies and guards are also verified.

   .. rubric:: Cylindrical units

   The J01_free_molecular directory contains ``test_J01_faceflux_2Drz_units.f90``: fluxes 2, -5 and 4 for the two-cell sign cases; boundary values -6, 0, 0, 12; area/volume update; a 200-history cell with no truncation and particle-rate conservation; and negative-density rejection. Flux tolerances are 1e-13.

   .. rubric:: Run and result

   Run the J01_free_molecular script on :doc:`the index <index>`. Both groups passed. The legacy maximum error was 1.7053e-13.
