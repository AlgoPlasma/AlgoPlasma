mod_J01_neutral_free_molecular_2Drz.f90
=================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>


.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 模块组织

   先 ``use mod_J01_neutral_free_molecular_2Drz``，再调用公开过程。此 mod 文件在 contains 下包含五个 sub 文件；
   编译时只编译 mod 文件，开启预处理并把本目录加到 include 路径。
   模块自身不依赖 J02 或 J03。

   .. rubric:: 共享数据

   ``fm_inlet_2drz_type`` 保存分段入口面积、半径上下界、总面积及热速度标准差；
   由 prepare 初始化，sample 只读取它。
   ``fm_tally_2drz_type`` 保存驻留时间、速度矩、内部穿面计数与边界出射计数；
   initialize 分配清零，trace 累加，finalize 读取并归一化。

   面序常量为 ``J01_R_LO/R_HI/Z_LO/Z_HI``，数值依次 1–4。
   面类型 ``INTERIOR/OPEN/WALL`` 数值依次 0、1、2。
   成功码为 0，形状错误 101，配置错误 105，跟踪不完整 106。

   .. rubric:: 调用约束

   主调度过程执行形状、基本参数与内部面拓扑检查。
   独立调用低层采样、轨迹和统计过程时，由调用方满足各页列出的前置条件。
   随机数使用 Fortran 运行时全局状态，当前不提供独立并行随机流。

   :doc:`各实现文件、公式与测试入口 <particle_transport>`。
   :download:`下载模块源码 <../../../../../J_Fluid/J01_free_molecular/mod_J01_neutral_free_molecular_2Drz.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   Compile this module with preprocessing and its include directory enabled.
   Inlet data are prepared once; trajectory tallies are accumulated and normalized separately.
   Low-level helpers require valid prepared data and topology.
