J_Fluid
==========================================================================================

.. toctree::
   :maxdepth: 1
   :titlesonly:

   J01 Free Molecular <J_Fluid/J01_free_molecular>
   J02 Discrete Ordinates <J_Fluid/J02_neutral_sn_transport_2Drz>
   J03 Continuity <J_Fluid/J03_neutral_continuity_faceflux_2Drz>

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   J_Fluid 提供中性气体的参考场计算与密度演化方法。
   在 PIC（Particle-in-Cell，粒子网格法）应用中，它可提供碰撞计算所需的中性密度；
   带电粒子推进、电磁场和反应率仍由其他模块负责。

   .. rubric:: 模块分工

   中性气体从入口进入，沿计算域运动，与壁面反射，最后从出口离开。
   求参考场时，需要考虑粒子的速度分布；参考场建立后，可以用连续性方程继续更新密度。
   这两类计算由不同模块承担。

   .. figure:: /_static/J_Fluid/model_pipeline.svg
      :alt: 从几何和物理输入选择一种参考场算法，再建立面输运系数并推进当前密度
      :width: 900px

      两个前处理模块是可选方法，不是必须依次调用的两个步骤。
      连续性模块只接收场数组，不依赖前处理的内部实现。

   .. list-table::
      :header-rows: 1
      :widths: 24 44 32

      * - 目录
        - 本章内容
        - 阅读后能完成的工作
      * - J01 Free Molecular
        - 入口采样、壁面反射、粒子跟踪、驻留与穿面统计
        - 从独立粒子历史得到参考密度和通量
      * - J02 Discrete Ordinates
        - 速度求积、边界分布、单元方程、扫描与反射迭代
        - 从离散速度分布得到参考密度和通量
      * - J03 Continuity
        - 参考场闭合、当前通量、瞬态单步、收支与稳态辅助求解
        - 从给定初态推进密度，并组织完整调用

   第一次阅读可完整阅读所需的一个前处理模块，再阅读 J03。
   网格、数组位置和通量约定在使用它们的模块中说明。
   若已有满足接口约定的参考密度与通量，可以直接进入 J03。

   .. rubric:: 模型范围与源码组织

   当前两种前处理均只保留 :math:`r,z` 和 :math:`v_r,v_z`，没有周向速度动力学；
   柱坐标面积和体积不意味着实现了完整三速度轴对称模型。
   各自的运动方程、边界模型和限制在相应章节说明，不要求两种方法的全部近似相同。

   J03 只演化单元密度；它不求速度分布，也不自动重算参考场。
   当入口速度分布、壁温或输运条件明显变化时，调用程序需要判断原参考场是否仍适用。

   源码中，``mod_*.f90`` 定义类型与常量，在 ``contains`` 后包含功能文件。
   构建时编译模块文件，不单独编译被包含的 ``sub_*.f90``；所有调用端应使用相同实数精度。
   各章说明每个过程的任务和参数，不在网页重复粘贴源码声明。

   .. rubric:: 源码说明与测试分开阅读

   本目录讲模型、公式、接口和组装顺序。测试的运行命令、断言、误差与结果图集中在
   :doc:`Tests / 012_fluid </tests/012_fluid/index>`。
   讲解中的小示例用于解释算法，不代表已经执行过某个实际算例。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   J_Fluid computes reference fields and evolves the density of a neutral gas.
   In a particle-in-cell (PIC) application, the collision module can use this neutral density.
   Other modules advance charged particles, compute electromagnetic fields and supply reaction rates.

   .. rubric:: How the modules fit together

   Neutrals enter through an inlet, travel through the domain, reflect at walls and leave through an outlet.
   Computing a reference field requires the velocity distribution. Once a reference field is available,
   the continuity equation can advance the density.

   .. figure:: ../images/J_Fluid/model_pipeline_en.svg
      :alt: Geometry and physical inputs feed either reference-field solver. J03 derives face transport coefficients and advances the current density.
      :width: 900px

      Choose one of the two reference-field solvers. The continuity solver receives field arrays
      and can use the output of either solver through the same interface.

   .. list-table::
      :header-rows: 1
      :widths: 24 44 32

      * - Chapter
        - Topics
        - What you can compute
      * - J01 Free Molecular
        - Inlet sampling, wall reflection, particle tracking, residence time and face crossings
        - Reference density and flux from independent particle histories
      * - J02 Discrete Ordinates
        - Velocity quadrature, boundary distributions, cell equations, sweeps and reflection iteration
        - Reference density and flux from the distribution at discrete velocities
      * - J03 Continuity
        - Reference-field closure, current fluxes, transient stepping, balance and the optional steady solver
        - A density history from a prescribed initial state and a complete sequence of solver calls

   On a first reading, follow one reference-field solver through to its outputs, then read J03.
   Each chapter introduces the grid, array locations and flux conventions where it uses them.
   If you already have reference density and flux arrays that satisfy the interface, start with J03.

   .. rubric:: Model scope and source layout

   Both reference-field solvers retain :math:`r,z` and :math:`v_r,v_z`.
   They use cylindrical areas and volumes and omit azimuthal velocity dynamics.
   Each chapter describes its own equations of motion, boundary models and assumptions.

   J03 advances cell density. It uses the supplied reference field throughout the calculation.
   If the inlet velocity distribution, wall temperature or transport conditions change appreciably,
   the application must decide whether that field still applies.

   The ``mod_*.f90`` files define types and constants and include the implementation files after
   ``contains``. Compile each module once with its included ``sub_*.f90`` files and use the same real precision in every caller.
   Each chapter explains the purpose and arguments of its procedures.

   .. rubric:: Algorithm documentation and tests

   This directory describes the models, equations, interfaces and assembly sequence.
   :doc:`Tests / 012_fluid </tests/012_fluid/index>` gives the commands, assertions, errors and result
   plots for the tests. The small examples in these chapters illustrate how the algorithms work.
