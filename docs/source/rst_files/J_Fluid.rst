J_Fluid
==========================================================================================

.. toctree::
   :maxdepth: 1
   :titlesonly:

   J01 Free Molecular <J_Fluid/J01_free_molecular>
   J02 Discrete Ordinates <J_Fluid/J02_neutral_sn_transport_2Drz>
   J03 Continuity <J_Fluid/J03_neutral_continuity_faceflux_2Drz>
   Legacy Utilities <J_Fluid/J01_free_molecular/continuity>

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
      * - Legacy Utilities
        - 已有三维归一化更新、二维给定速度通量工具
        - 使用保留接口，不需要先学习粒子前处理

   第一次阅读可完整阅读所需的一个前处理模块，再阅读 J03。
   网格、数组位置和通量约定在使用它们的模块中说明。
   若已有满足接口约定的参考密度与通量，可以直接进入 J03。
   三维保留接口单独放在最后，不穿插在二维中性输运的阅读顺序中。

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

   J_Fluid supplies neutral reference fields and density evolution for applications.
   Charged-particle pushing, electromagnetic fields, and reaction-rate models remain outside this group.

   Read one complete reference-field route, including its local geometry, indexing and signs,
   followed by J03 for transient density evolution. J01 and J02 are alternatives, not successive stages.
   Existing reference arrays can be passed directly to J03.

   - J01: inlet sampling, wall reflection, particle histories, residence and crossing estimators.
   - J02: velocity quadrature, boundary distributions, DG equations, sweeps, iteration and reconstruction.
   - J03: reference-field closure, current fluxes, physical-time steps, balance diagnostics and an optional steady solver.
   - Legacy Utilities: separate Cartesian and prescribed-velocity interfaces retained in the J01 directory.

   The current kinetic preprocessors retain only r,z and two velocity components.
   Cylindrical measures do not provide full axisymmetric three-velocity dynamics.
   J03 evolves scalar density and never reruns a preprocessor.

   Compile module files with preprocessing, not their included implementation files.
   Use one real precision consistently. Detailed tests and results belong to
   :doc:`Tests / 012_fluid </tests/012_fluid/index>`, separate from the algorithm documentation.
