mod_I02_load_init_particles_bin.f90
-----------------------------------

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 直接用途

   ``mod_I02_load_init_particles_bin`` 汇总离线生成粒子 binary 文件的载入入口。

   .. rubric:: 公开入口与 include 关系

   下列文件在 ``mod_I02_load_init_particles_bin`` 的 ``contains`` 作用域内 include。
   调用方应 ``use mod_I02_load_init_particles_bin`` 后调用具体例程；不要把这些
   include 文件单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - 文件
        - 功能
        - 适用场景
      * - ``sub_I02_load_init_particles_bin.f90``
        - 读取 ``par_ele_init.bin`` 和 ``par_ion_init.bin``，按本地 ``il``/``iu`` 子域筛选粒子并分配数组。
        - 需要把离线初始化数据载入并分发到 MPI 子域。

   .. rubric:: 局部假设

   初始化例程写入调用方提供的粒子数组，不负责后续推进或边界交换。粒子坐标采用网格指标单位；二进制载入流程依赖离线生成文件的字段顺序和实数精度。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: Direct Purpose

   ``mod_I02_load_init_particles_bin`` module wrapper for loading initial particle binary files.

   .. rubric:: Public Entries And Includes

   The following file is included inside the ``contains`` scope of
   ``mod_I02_load_init_particles_bin``. Callers should
   ``use mod_I02_load_init_particles_bin`` and call the concrete routine through
   the module; do not compile the include file separately.

   .. list-table::
      :header-rows: 1
      :widths: 34 34 32

      * - File
        - Function
        - Typical use
      * - ``sub_I02_load_init_particles_bin.f90``
        - Reads ``par_ele_init.bin`` and ``par_ion_init.bin``, filters particles by local ``il``/``iu`` bounds, and allocates local arrays.
        - Load offline initialization data and distribute particles to MPI subdomains.

   .. rubric:: Local Assumptions

   Initializer routines write into caller-provided particle arrays and do not perform later pushing or boundary exchange. Particle coordinates are in grid-index units. Binary loading depends on the offline file field order and real precision.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_I02_load_init_particles_bin.f90
