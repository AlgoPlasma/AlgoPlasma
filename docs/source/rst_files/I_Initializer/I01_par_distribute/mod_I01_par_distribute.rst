mod_I01_par_distribute.f90
--------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_I01_par_distribute`` 汇总规则粒子分布初始化入口。

   .. rubric:: 公开入口与 include 关系

   下列文件在 ``mod_I01_par_distribute`` 的 ``contains`` 作用域内 include。
   调用方应 ``use mod_I01_par_distribute`` 后调用具体例程；不要把这些
   include 文件单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_I01_par_distribute_equilibrium.f90``
        - 在每个 cell 内生成规则空间位置，并用 Box-Muller 采样 Maxwellian 速度。
        - 构造均匀初始粒子分布，带热速度和漂移速度。

   .. rubric:: 局部假设

   初始化例程写入调用方提供的粒子数组，不负责后续推进或边界交换。粒子坐标采用网格指标单位；二进制载入流程依赖离线生成文件的字段顺序和实数精度。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_I01_par_distribute`` module wrapper for particle distribution initialization.

   .. rubric:: Public Entries And Includes

   The following file is included inside the ``contains`` scope of
   ``mod_I01_par_distribute``. Callers should ``use mod_I01_par_distribute`` and
   call the concrete routine through the module; do not compile the include file
   separately.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_I01_par_distribute_equilibrium.f90``
        - Generates regular in-cell positions and Maxwellian velocities using Box-Muller sampling.
        - Build a uniform initial particle distribution with thermal and drift velocities.

   .. rubric:: Local Assumptions

   Initializer routines write into caller-provided particle arrays and do not perform later pushing or boundary exchange. Particle coordinates are in grid-index units. Binary loading depends on the offline file field order and real precision.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_I01_par_distribute.f90
