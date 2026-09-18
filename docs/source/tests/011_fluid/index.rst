011_fluid
======================================================================

.. toctree::
   :maxdepth: 1
   :hidden:

   J01_tests
   J01_fm_tests
   J02_tests
   J03_tests
   application_tests

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 测试范围

   先用小规模算例检查离散公式、边界处理和错误诊断，再运行完整网格上的前处理与连续性方程测试。各页注明源文件、子测试函数、输入条件和预期结果。

   .. rubric:: 测试页面

   .. list-table::
      :header-rows: 1

      * - 页面
        - 内容
      * - :doc:`J01 测试 <J01_tests>`
        - 三维更新、保护层、周期守恒；二维通量、单步更新和粒子历史。
      * - :doc:`J01 自由分子模块测试 <J01_fm_tests>`
        - 入口采样、反射、单轨迹、统计归一化和失败诊断。
      * - :doc:`J02 测试 <J02_tests>`
        - 求积、几何、入口、局部矩阵、扫描、反射及重构。
      * - :doc:`J03 测试 <J03_tests>`
        - 迎风闭合、时间步、源损平衡、残差及连接测试。
      * - :doc:`应用测试 <application_tests>`
        - FM 前处理与其 J03 密度；SN 前处理与其 J03 密度。



   .. rubric:: 测试文件与被测源码

   下表中的测试文件位于各测试目录的 source_f90 下；源码文件位于对应的 J_Fluid 模块目录。
   测试源码负责构造输入和断言，正式计算由右栏列出的实现完成。
   各子页面进一步列出每个子测试调用的具体接口。

   .. list-table::
      :header-rows: 1
      :widths: 34 18 48

      * - 测试文件
        - 测试目录
        - 被测实现
      * - test_J01_continuity_freeflow.f90
        - J01
        - sub_J01_continuity_freeflow.f90：三维密度单步更新。
      * - test_J01_fm_units.f90
        - J01
        - sub_J01_fm_sampling、trajectory、reflection、statistics 以及 free_molecular_mc_2Drz 主入口。
      * - test_J01_faceflux_2Drz_units.f90
        - J01
        - sub_J01_continuity_freeflow_2Drz.f90 的通量和单步；sub_J01_free_molecular_mc_2Drz.f90 的单网格粒子输运。
      * - test_J02_neutral_sn_transport_2Drz.f90
        - J02
        - sub_J02_sn_quadrature、geometry、source、dg_operator、sweep、reconstruction、error 各文件的基础接口。
      * - test_J02_reflection_partial_inlet.f90
        - J02
        - sub_J02_sn_reflection.f90 的入口区间、方向映射和反射迭代；dg_operator 的区间积分及 reconstruction 的边界通量。
      * - test_J02_transport_units.f90
        - J03
        - sub_J02_sn_geometry.f90 的轴线/拓扑，source 的损失系数，dg_operator 的吸收矩阵，reconstruction 的四面符号。
      * - test_J03_transient.f90
        - J03
        - 瞬态解析解、时间步收敛、时变损失、内部面一致性与稳态残差判据。
      * - test_application_case.f90
        - J03
        - application_case.f90：共享有效区域、B0/ION 损失。
      * - test_J03_continuity_units.f90
        - J03
        - sub_J03_transport_closure.f90 的初始化；sub_J03_continuity_solver.f90 的时间步、单步、残差和失败诊断。
      * - test_J03_neutral_continuity_faceflux_2Drz.f90
        - J03
        - J01 通量、J02 输入输出接口、J03 两种导入入口与稳态平衡；不是完整几何上的粒子统计测试。

   .. rubric:: 目录与执行入口

   J01 的三维、二维通量和粒子测试统一由 J01_free_molecular/run.sh 执行。J02 补充测试仍由 J03 脚本执行，具体文件见上表。

   .. code-block:: bash

      bash tests/011_fluid/J01_free_molecular/run.sh
      bash tests/011_fluid/J02_neutral_sn_transport_2Drz/run.sh
      bash tests/011_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh

   .. rubric:: 结果判定

   三个目录的快速测试最近一次运行均通过。每个程序须输出 ``n_failed = 0`` 和 ``RESULT: PASS``，并以零状态退出。各项数值判据见子页面。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Scope

   Pages describe individual test functions, setup and expected results. All J01 unit tests run from J01_free_molecular. Supplementary J02 units run from the J03 directory.

   .. rubric:: Pages

   .. list-table::
      :header-rows: 1

      * - Page
        - Coverage
      * - :doc:`J01 <J01_tests>`
        - Updates, fluxes and histories.
      * - :doc:`J01 particles <J01_fm_tests>`
        - Sampling, reflection, trajectories and statistics.
      * - :doc:`J02 <J02_tests>`
        - Quadrature, DG and boundaries.
      * - :doc:`J03 <J03_tests>`
        - Closure and connected regression.
      * - :doc:`Applications <application_tests>`
        - Preprocessing and continuity fields.


   .. rubric:: Result

   All fast suites passed. Success requires zero failed checks and a zero exit status.
