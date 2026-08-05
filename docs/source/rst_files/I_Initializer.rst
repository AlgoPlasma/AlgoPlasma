I_Initializer
=============

.. toctree::
    :maxdepth: 1

    I_Initializer/I01_par_distribute
    I_Initializer/I02_par_init_and_load

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 概览

   ``I_Initializer`` 放置 AlgoPlasma 的粒子初始化工具。当前分成两类入口：一类在 Fortran
   内部直接生成规则粒子分布，另一类由 Python 离线生成全局二进制粒子文件，再由 MPI
   程序按本地子域筛选载入。

   .. list-table:: 子模块
      :header-rows: 1
      :widths: 25 32 43

      * - 模块
        - 数据来源
        - 主要职责
      * - :doc:`I01_par_distribute <I_Initializer/I01_par_distribute>`
        - 调用时给定的局部网格范围和每格粒子数
        - 在每个网格单元内生成严格均匀的位置，并用 Maxwellian 分布初始化速度。
      * - :doc:`I02_par_init_and_load <I_Initializer/I02_par_init_and_load>`
        - ``output_init_particles_bin/*.bin`` 二进制文件
        - 生成 T 形区域粒子初值，并在 MPI 并行计算中将粒子分配到对应子域。

   .. rubric:: 坐标与数组约定

   - 粒子数组采用 ``par(1:6,...)``，其中 ``1:3`` 为 ``x,y,z``，``4:6`` 为 ``vx,vy,vz``。
   - I01 使用归一化网格间距 ``dx=dy=dz=1``，位置坐标与网格单元索引直接对应。
   - I02 的二进制文件每个粒子保存 6 个 ``float64`` 值，Fortran 端按局部 ``il``/``iu`` 范围筛选。
   - I02 当前默认粒子数很大，适合作为离线初始化数据生成流程，不是轻量级回归测试入口。

   .. rubric:: 测试状态

   当前 ``tests/006_initializer`` 已包含 :doc:`I01_par_distribute 测试 </tests/006_initializer/I01_par_distribute>`，
   用于验证规则粒子分布初始化。I02 更接近离线初始化数据生成和载入流程，
   :doc:`init_particles_bin.py <I_Initializer/I02_par_init_and_load/init_particles_bin>` 页面已给出参考输出图，
   因此当前不单独作为轻量回归测试项。

.. container:: ap-lang ap-lang-en

   .. rubric:: Overview

   ``I_Initializer`` contains AlgoPlasma particle-initialization utilities. The current
   module family has two entry styles: Fortran-side procedural initialization for
   regular particle distributions, and an offline Python binary generator followed
   by an MPI-aware Fortran loader.

   .. list-table:: Submodules
      :header-rows: 1
      :widths: 25 32 43

      * - Module
        - Data source
        - Main responsibility
      * - :doc:`I01_par_distribute <I_Initializer/I01_par_distribute>`
        - Local mesh bounds and particles per cell passed by the caller
        - Generate exactly uniform in-cell particle positions and Maxwellian velocities.
      * - :doc:`I02_par_init_and_load <I_Initializer/I02_par_init_and_load>`
        - Binary files under ``output_init_particles_bin/*.bin``
        - Generate T-shaped-domain particle initial conditions and load them into MPI subdomains.

   .. rubric:: Coordinate and Array Conventions

   - Particle arrays use ``par(1:6,...)``: ``1:3`` are ``x,y,z`` and ``4:6`` are ``vx,vy,vz``.
   - I01 assumes normalized mesh spacing ``dx=dy=dz=1`` so positions map directly to cell indices.
   - I02 binary records store six ``float64`` values per particle; the Fortran loader filters them by local ``il``/``iu`` bounds.
   - The I02 generator currently uses a very large default particle count, so it is an offline data-preparation workflow rather than a lightweight regression test.

   .. rubric:: Test Status

   ``tests/006_initializer`` currently includes the
   :doc:`I01_par_distribute test </tests/006_initializer/I01_par_distribute>`
   for regular particle-distribution initialization. I02 is closer to an offline
   initialization-data generation and loading workflow. The
   :doc:`init_particles_bin.py <I_Initializer/I02_par_init_and_load/init_particles_bin>`
   page already includes reference output figures, so it is not listed as a
   separate lightweight regression test item for now.
