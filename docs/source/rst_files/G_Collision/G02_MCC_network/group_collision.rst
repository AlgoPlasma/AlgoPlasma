.. rst-class:: ap-g02 ap-g02-reference

Collision
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   这一组包含下面这些源码文件。头文件（.hpp / .h）约定可使用的类型和接口，实现文件（.cpp）完成计算；部分小工具直接实现在头文件中。

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - 程序文件
        - 用途
      * - :doc:`engine.hpp <engine>`
        - 单粒子碰撞引擎与结果类型
      * - :doc:`fun_G02_mcc_engine.cpp <fun_G02_mcc_engine>`
        - MccEngine：碰撞抽样与事件处理
      * - :doc:`kinematics.hpp <kinematics>`
        - 碰后速度计算接口
      * - :doc:`fun_G02_mcc_kinematics.cpp <fun_G02_mcc_kinematics>`
        - 碰撞运动学：计算碰后速度
      * - :doc:`batch.hpp <batch>`
        - 粒子容器适配与整批推进接口
      * - :doc:`fun_G02_mcc_batch.cpp <fun_G02_mcc_batch>`
        - MccStepper：批量碰撞步进器

.. container:: ap-lang ap-lang-en

   This group contains the source files below. Headers define types and interfaces; .cpp files implement them. Small utilities may be implemented inline in headers.

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - Source file
        - Purpose
      * - :doc:`engine.hpp <engine>`
        - Single-particle engine and outcome types
      * - :doc:`fun_G02_mcc_engine.cpp <fun_G02_mcc_engine>`
        - MccEngine: collision sampling and events
      * - :doc:`kinematics.hpp <kinematics>`
        - Outgoing-velocity interfaces
      * - :doc:`fun_G02_mcc_kinematics.cpp <fun_G02_mcc_kinematics>`
        - Collision kinematics: outgoing velocities
      * - :doc:`batch.hpp <batch>`
        - Particle adapters and batch interfaces
      * - :doc:`fun_G02_mcc_batch.cpp <fun_G02_mcc_batch>`
        - MccStepper: batch collision stepper

.. toctree::
   :maxdepth: 1
   :hidden:

   engine.hpp <engine>
   fun_G02_mcc_engine.cpp <fun_G02_mcc_engine>
   kinematics.hpp <kinematics>
   fun_G02_mcc_kinematics.cpp <fun_G02_mcc_kinematics>
   batch.hpp <batch>
   fun_G02_mcc_batch.cpp <fun_G02_mcc_batch>

:doc:`返回 G02 / Back to G02 <../G02_MCC_network>`
