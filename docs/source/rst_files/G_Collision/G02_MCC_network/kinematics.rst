.. rst-class:: ap-g02 ap-g02-reference

kinematics.hpp：碰后速度计算接口
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这个文件做什么

   已选定反应后，这组接口决定产物怎样运动。输入质量、总动量和可用动能等，输出速度以及未分配能量；内部使用 kg、J 和 m/s。能量不够时不能随意生成速度。实现见 fun_G02_mcc_kinematics.cpp。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      FinalState; two_body_final_state, identity_exchange_final_state, n_body_phase_space_final_state, equal_share_final_state, single_product_final_state

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: What this file does

   After selecting a reaction, these routines construct product velocities from masses, momentum and available kinetic energy. Units are kg, J and m/s. FinalState also records unallocated energy. Implemented in fun_G02_mcc_kinematics.cpp.

   .. rubric:: Main types and entry points

   .. code-block:: text

      FinalState; two_body_final_state, identity_exchange_final_state, n_body_phase_space_final_state, equal_share_final_state, single_product_final_state

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`kinematics.hpp <../../../../../G_Collision/G02_MCC_network/kinematics.hpp>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/kinematics.hpp
   :language: cpp
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/kinematics.hpp``

:doc:`Collision <group_collision>`
