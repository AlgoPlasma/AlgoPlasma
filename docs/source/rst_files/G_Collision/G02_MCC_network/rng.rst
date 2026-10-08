.. rst-class:: ap-g02 ap-g02-reference

rng.hpp：可复现的随机数
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这个文件做什么

   用种子、时间步、粒子 ID、事件序号和抽样槽定位随机序列。uniform_open 产生开区间 (0,1) 内的数，normal 产生标准正态随机数，isotropic_direction 抽取各向同性方向。固定这些标识可复现抽样；主程序应保持粒子 ID 稳定。批量推进的新粒子 ID 由其专用分配逻辑管理。

   五个字段分别标记，再按固定顺序逐层混合，避免事件编号与抽样槽互换造成随机流复用。这次修复会改变旧版本同一种子的具体序列；可重复性指同一实现、同一五元组和同一取数顺序。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      CounterRng; next_u64, uniform_open, normal, isotropic_direction, stream_slot, child_id

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: What this file does

   A seed, step, particle ID, event index and slot identify a stream. Methods provide open-interval uniforms, standard normals and isotropic directions. Preserve particle IDs for reproducibility. Batch stepping uses its own child-ID allocation logic.

   Each field has a separate tag and is folded in a fixed order, avoiding stream reuse caused by swapping the event index and slot. This fix changes the exact sequences produced by older versions. Replay requires the same implementation, tuple and draw order.

   .. rubric:: Main types and entry points

   .. code-block:: text

      CounterRng; next_u64, uniform_open, normal, isotropic_direction, stream_slot, child_id

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`rng.hpp <../../../../../G_Collision/G02_MCC_network/rng.hpp>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/rng.hpp
   :language: cpp
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/rng.hpp``

:doc:`Basics <group_foundation>`
