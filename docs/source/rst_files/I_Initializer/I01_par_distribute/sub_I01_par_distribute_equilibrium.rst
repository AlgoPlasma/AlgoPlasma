sub_I01_par_distribute_equilibrium.f90
--------------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``sub_I01_par_distribute_equilibrium`` 在局部网格内生成均匀分布粒子，并按给定热速度/漂移速度初始化速度。

   .. rubric:: 参数表

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - 参数
        - 方向
        - shape/范围
        - 含义与局部约定
      * - ``par``
        - out
        - ``(1:6,1:np)``
        - 粒子数组；通常 ``1:3`` 为位置，``4:6`` 为速度，列或第二维为粒子编号。
      * - ``nppc``
        - in
        - ``(1:3)``
        - 每个网格单元的粒子数。
      * - ``il``
        - in
        - ``(1:3)``
        - 本地 active cell 下界索引。
      * - ``iu``
        - in
        - ``(1:3)``
        - 本地 active cell 上界索引。
      * - ``vt``
        - in
        - ``(1:3)``
        - 热速度尺度。
      * - ``vd``
        - in
        - ``(1:3)``
        - 漂移速度向量。

   .. rubric:: 局部假设

   初始化例程写入调用方提供的粒子数组，不负责后续推进或边界交换。粒子坐标采用网格指标单位；二进制载入流程依赖离线生成文件的字段顺序和实数精度。

   .. rubric:: 实现逻辑

   实现按 cell 和每格粒子编号生成规则位置，并用随机数生成 Maxwellian 速度后叠加漂移速度。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``sub_I01_par_distribute_equilibrium`` particle initialization utilities. Exactly uniform in space and Maxwellian velocity (dx=dy=dz=1).

   .. rubric:: Parameter Table

   .. list-table::
      :header-rows: 1
      :widths: 18 10 24 48

      * - Parameter
        - Direction
        - Shape/range
        - Meaning and local convention
      * - ``par``
        - out
        - ``(1:6,1:np)``
        - real (1:6,1:np), particle array; 1-3 are ``x,y,z``, 4-6 are ``vx,vy,vz``; ``np`` is
          number of particles.
      * - ``nppc``
        - in
        - ``(1:3)``
        - integer (1:3), number of particles per cell in ``x,y,z``.
      * - ``il``
        - in
        - ``(1:3)``
        - integer (1:3), cell-center lower indices in ``x,y,z``.
      * - ``iu``
        - in
        - ``(1:3)``
        - integer (1:3), cell-center upper indices in ``x,y,z``.
      * - ``vt``
        - in
        - ``(1:3)``
        - real (1:3), thermal velocity in ``x,y,z``, \f$v_t=\sqrt{2kT/m}\f$.
      * - ``vd``
        - in
        - ``(1:3)``
        - real (1:3), drifting velocity in ``x,y,z``.

   .. rubric:: Local Assumptions

   Initializer routines write into caller-provided particle arrays and do not perform later pushing or boundary exchange. Particle coordinates are in grid-index units. Binary loading depends on the offline file field order and real precision.

   .. rubric:: Implementation Notes

   The implementation loops over cells and particles-per-cell to generate regular positions, then samples Maxwellian velocities and adds drift velocity.

   .. rubric:: Generated API

   .. doxygenfile:: sub_I01_par_distribute_equilibrium.f90
