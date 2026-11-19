G_Collision
===========

.. toctree::
    :maxdepth: 1

    G_Collision/G01_MCC
    G_Collision/G02_MCC_network
    G_Collision/G03_DSMC

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   ``G_Collision`` 包含 :doc:`G01_MCC <G_Collision/G01_MCC>` 截面表碰撞模块和
   :doc:`G02_MCC_network <G_Collision/G02_MCC_network>` 数据驱动的批量碰撞网络。
   :doc:`G03_DSMC <G_Collision/G03_DSMC>` 提供中性弹性碰撞 C++20 核心、基础教程、源码导读与验证判据。

   .. list-table:: 子模块
      :header-rows: 1
      :widths: 22 34 44

      * - 模块
        - 数据对象
        - 主要职责
      * - :doc:`G01_MCC <G_Collision/G01_MCC>`
        - 粒子数组 ``par(1:6,1:npmax)``、截面表、背景中性气体密度
        - 用 null-collision 方法抽样碰撞，更新粒子速度，并在电离时生成新电子/离子和源项。
      * - :doc:`G02_MCC_network <G_Collision/G02_MCC_network>`
        - 版本化 CSV 模型包、粒子与背景状态、碰撞结果和源项
        - 每个 PIC 步批量处理粒子，支持二体与三体通道、C++ 接口及零维碰撞盒验证。
      * - :doc:`G03_DSMC <G_Collision/G03_DSMC>`
        - 数值模型参数、柱坐标粒子、非均匀三维网格与逐步统计
        - 对单一中性原子的等权重粒子执行 HS/VHS/VSS 弹性碰撞，默认 NTC，可选连续候选时钟；当前为串行 CPU 实现。

   .. rubric:: 数据和调用边界

   - G01 的截面插值假设等间隔能量网格，碰撞例程使用 ``MPI_Allreduce``。
   - G02 的 C++20 核心可独立构建，MPI/OpenMP 可选；模型包采用显式单位与状态约定。
   - G03 的 C++20 主库直接接收柱坐标粒子数组与非均匀三维网格，提供 NTC 和连续候选时钟；构建方式由调用工程决定。
   - 三个模块均由调用方负责粒子推进和边界处理；G02 附带数据是合成值，不用于科研结论。
   - ``tests/009_collision`` 包含 G01 加载器回归、G02 网络验证与 G03 柱坐标碰撞回归；G03 的运行方式与弛豫算例见 :doc:`G03 DSMC Validation </tests/009_collision/G03_DSMC>`。

   .. rubric:: 文档组织

   初次学习，推荐进入 :doc:`G02 模块页 <G_Collision/G02_MCC_network>`，
   按 :ref:`MCC 基本概念 <g02-mcc-basics-zh>` →
   :ref:`程序实现 <g02-implementation-zh>` →
   :ref:`零维碰撞盒 <g02-collision-box-zh>` 的顺序阅读。
   算例部分保留运行命令、三张图的读法与检查判据。

   DSMC 初学者可从 :doc:`G03_DSMC <G_Collision/G03_DSMC>` 开始，
   先比较 DSMC 与背景式 MCC，再理解完整框架，随后依次阅读
   ``Theory & Algorithm`` 与 ``Source Guide``。

   已实现模块的公式、接口和限制见各自页面；G02 的测试与零维算例运行方式见
   :doc:`009_collision 测试总览 </tests/009_collision/index>`。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   ``G_Collision`` contains the tabulated-cross-section
   :doc:`G01_MCC <G_Collision/G01_MCC>` module and the data-driven, whole-step
   :doc:`G02_MCC_network <G_Collision/G02_MCC_network>` module.
   :doc:`G03_DSMC <G_Collision/G03_DSMC>` provides a C++20 neutral elastic collision
   core, a tutorial, a source walkthrough and validation criteria.

   .. list-table:: Submodules
      :header-rows: 1
      :widths: 22 34 44

      * - Module
        - Data objects
        - Main responsibility
      * - :doc:`G01_MCC <G_Collision/G01_MCC>`
        - Particle arrays ``par(1:6,1:npmax)``, cross-section tables, background neutral density
        - Sample collisions with the null-collision method, update particle velocities, and create electron/ion particles and source terms for ionization events.
      * - :doc:`G02_MCC_network <G_Collision/G02_MCC_network>`
        - Versioned CSV model packages, particle and background states, outcomes and source terms
        - Process a whole PIC step with two- and three-body channels, C++ interfaces and a zero-dimensional collision-box validation case.
      * - :doc:`G03_DSMC <G_Collision/G03_DSMC>`
        - Numerical model parameters, cylindrical particles, a nonuniform 3D grid and per-step reports
        - Apply HS/VHS/VSS elastic collisions to one neutral species with uniform particle weight on a serial CPU, using rounded NTC by default or an optional continuous candidate clock.

   .. rubric:: Data and Call Boundaries

   - G01 assumes uniform energy spacing and uses ``MPI_Allreduce`` in its collision routines.
   - G02's C++20 core builds independently with optional MPI/OpenMP and explicit model units and states.
   - G03's C++20 library accepts cylindrical particles and a nonuniform 3D grid, with rounded NTC or a continuous candidate clock. The calling project chooses its build setup.
   - All three leave pushing and boundary handling to the caller. G02's bundled data are synthetic and cannot support scientific conclusions.
   - ``tests/009_collision`` covers the G01 loader, G02 network and G03 cylindrical collision regression. G03 commands and relaxation examples are in :doc:`G03 DSMC Validation </tests/009_collision/G03_DSMC>`.

   .. rubric:: Documentation Layout

   Start with the :doc:`G02 module page <G_Collision/G02_MCC_network>` and follow
   :ref:`MCC basics <g02-mcc-basics-en>` →
   :ref:`the implementation <g02-implementation-en>` →
   :ref:`the collision box <g02-collision-box-en>`.
   The example section retains commands, plot explanations and pass criteria.

   For DSMC, start at the :doc:`G03 chapter <G_Collision/G03_DSMC>`.
   Compare DSMC with background MCC and follow the full framework first, then
   proceed through Theory & Algorithm and Source Guide.

   See the module pages for formulas, interfaces and limits, and the
   :doc:`009_collision test overview </tests/009_collision/index>` for G02's
   collision-box validation case.
