.. rst-class:: ap-g02 ap-g02-reference

fun_G02_mcc_table.cpp：执行插值与计算区间上界
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这个文件做什么

   检查至少两个采样点、横坐标严格递增和纵坐标非负；执行 linear、log-linear 或 log-log 插值。越界可选择报错、返回零或取边界值。区间上界用于后续构造安全的碰撞抽样频率；截面上界本身不是碰撞频率，还要考虑相对速率和密度。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      Table::validate; Table::sample; Table::segment_upper_bounds; Table::upper_bound

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: What this file does

   Validates grids and performs linear, log-linear or log-log interpolation. Domain policies reject, return zero or clamp. Segment bounds support collision-rate bounds; a cross-section bound alone is not a collision frequency.

   .. rubric:: Main types and entry points

   .. code-block:: text

      Table::validate; Table::sample; Table::segment_upper_bounds; Table::upper_bound

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`fun_G02_mcc_table.cpp <../../../../../G_Collision/G02_MCC_network/fun_G02_mcc_table.cpp>`


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fun_G02_mcc_table.cpp``

:doc:`Model <group_model_data>`
