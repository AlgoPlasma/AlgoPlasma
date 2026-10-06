.. rst-class:: ap-g02 ap-g02-reference

engine.hpp：单粒子碰撞引擎与结果类型
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这个文件做什么

   ParticleState 描述被跟踪粒子，BackgroundComponent 描述背景，CollisionRequest 给出一次推进的输入。MccEngine 根据已编译模型计算碰撞；StepOutcome 记录原粒子变化、新产物和背景交换量。调用单粒子接口后，主程序要自行提交结果。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      MccEngine, ParticleState, BackgroundComponent, CollisionRequest, StepOutcome, EventRecord, ConservationLedger

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - The projectile is the tracked incoming particle. The primary outcome tells what happens to that original particle record: update, removal or species change. Background partners are described by density and temperature.
      - Reservoir deltas track background gains/losses of particles, momentum and energy. A conservation ledger compares totals before and after reactions. Do not apply both as background source terms.

   .. rubric:: What this file does

   ParticleState and BackgroundComponent describe the inputs. CollisionRequest controls a call; StepOutcome describes primary changes, products and reservoir exchange. The host must apply single-particle outcomes. See the implementation page for sampling details.

   .. rubric:: Main types and entry points

   .. code-block:: text

      MccEngine, ParticleState, BackgroundComponent, CollisionRequest, StepOutcome, EventRecord, ConservationLedger

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`engine.hpp <../../../../../G_Collision/G02_MCC_network/engine.hpp>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/engine.hpp
   :language: cpp
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/engine.hpp``

:doc:`Collision <group_collision>`
