G_collision
===========

.. toctree::
    :maxdepth: 1

    G_collision/G01_MCC

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   ``G_collision`` 收集 AlgoPlasma 中的碰撞模型。当前实现的子模块是
   :doc:`G01_MCC <G_collision/G01_MCC>`，用于基于截面表的 Monte Carlo
   Collision (MCC) 采样，包括电子-中性粒子、离子-中性粒子以及电离产生的二次粒子处理。

   .. list-table:: 子模块
      :header-rows: 1
      :widths: 22 34 44

      * - 模块
        - 数据对象
        - 主要职责
      * - :doc:`G01_MCC <G_collision/G01_MCC>`
        - 粒子数组 ``par(1:6,1:npmax)``、截面表、背景中性气体密度
        - 用 null-collision 方法抽样碰撞，更新粒子速度，并在电离时生成新电子/离子和源项。

   .. rubric:: 数据和调用边界

   - 截面表由两列组成：能量和截面值；当前插值函数假设能量网格等间隔。
   - 电子和离子碰撞例程依赖 ``MPI_Allreduce`` 取得全局最大 null-collision 频率，调用方需要在 MPI 环境中运行。
   - 例程只处理粒子碰撞本身；粒子推进、边界处理、负载均衡和截面文件管理由外层程序负责。
   - 当前仓库中未发现独立的 ``tests`` 回归入口覆盖 ``G_collision``。

   .. rubric:: 文档组织

   详细 MCC 公式、碰撞选择流程、例程职责和限制见
   :doc:`G01_MCC <G_collision/G01_MCC>`。各 Fortran 文件页面保留简短中文说明，完整
   Doxygen API 位于英文视图。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   ``G_collision`` contains collision models used by AlgoPlasma. The current module is
   :doc:`G01_MCC <G_collision/G01_MCC>`, a tabulated-cross-section Monte Carlo
   Collision (MCC) layer for electron-neutral collisions, ion-neutral collisions,
   and secondary particles produced by ionization.

   .. list-table:: Submodules
      :header-rows: 1
      :widths: 22 34 44

      * - Module
        - Data objects
        - Main responsibility
      * - :doc:`G01_MCC <G_collision/G01_MCC>`
        - Particle arrays ``par(1:6,1:npmax)``, cross-section tables, background neutral density
        - Sample collisions with the null-collision method, update particle velocities, and create electron/ion particles and source terms for ionization events.

   .. rubric:: Data and Call Boundaries

   - Cross-section tables use two columns: energy and cross-section value. The current interpolation helper assumes uniform energy spacing.
   - The electron and ion collision routines use ``MPI_Allreduce`` to obtain the global maximum null-collision frequency, so callers must run them inside an MPI program.
   - These routines handle only collision sampling and velocity/source updates; pushing, boundary handling, load balancing, and cross-section file management belong to the caller.
   - No standalone ``tests`` regression entry for ``G_collision`` was found in the current repository.

   .. rubric:: Documentation Layout

   See :doc:`G01_MCC <G_collision/G01_MCC>` for the MCC formulas, collision
   selection flow, routine roles, and limitations. Individual Fortran pages keep
   short Chinese summaries and place the generated Doxygen API in the English view.
