I01_par_distribute
==================

.. toctree::
    :maxdepth: 1
    :hidden:

    I01_par_distribute/mod_I01_par_distribute
    I01_par_distribute/sub_I01_par_distribute_equilibrium

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 模块职责

   ``I01_par_distribute`` 提供直接在 Fortran 内存中构造粒子初值的入口。当前实现包含一个均衡初始化例程：粒子位置在每个单元内部按规则子网格精确均匀铺放，速度按带漂移速度的
   Maxwellian 分布采样。

   .. list-table:: 文件
      :header-rows: 1
      :widths: 38 62

      * - 文件
        - 说明
      * - :doc:`mod_I01_par_distribute.f90 <I01_par_distribute/mod_I01_par_distribute>`
        - 模块包装器，通过 ``include`` 暴露初始化例程。
      * - :doc:`sub_I01_par_distribute_equilibrium.f90 <I01_par_distribute/sub_I01_par_distribute_equilibrium>`
        - 生成均匀位置和 Maxwellian 速度的核心子程序。

   .. rubric:: 调用约定

   - 输入 ``il``/``iu`` 是当前初始化范围的 cell-center 下界和上界。
   - ``nppc(1:3)`` 给出每个单元在 ``x,y,z`` 三个方向的粒子子网格数。
   - 调用者需要保证 ``par`` 的第二维长度与 ``il``、``iu`` 和 ``nppc`` 对应的总粒子数一致。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">赵隐剑 (2025/11/03) · 哈尔滨工业大学</p>
      </div>

.. container:: ap-lang ap-lang-en

   .. rubric:: Module Role

   ``I01_par_distribute`` provides Fortran-side particle initialization in memory.
   The current routine builds equilibrium-like particles: positions are placed on
   an exactly uniform subgrid inside each cell, and velocities are sampled from a
   Maxwellian distribution with an optional drift velocity.

   .. list-table:: Files
      :header-rows: 1
      :widths: 38 62

      * - File
        - Description
      * - :doc:`mod_I01_par_distribute.f90 <I01_par_distribute/mod_I01_par_distribute>`
        - Module wrapper that exposes the initialization routine through ``include``.
      * - :doc:`sub_I01_par_distribute_equilibrium.f90 <I01_par_distribute/sub_I01_par_distribute_equilibrium>`
        - Core routine for uniform positions and Maxwellian velocities.

   .. rubric:: Calling Conventions

   - ``il``/``iu`` are the lower and upper cell-center indices of the initialization range.
   - ``nppc(1:3)`` gives the particle subgrid count per cell in ``x,y,z``.
   - The caller must size the second dimension of ``par`` consistently with ``il``, ``iu``, and ``nppc``.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Yinjian ZHAO (2025/11/03) · Harbin Institute of Technology</p>
      </div>
