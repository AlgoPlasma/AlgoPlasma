.. rst-class:: ap-g02 ap-g02-reference

batch.hpp：粒子容器适配与整批推进接口
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - AoS / SoA 是存储排法：AoS（Array of Structures）按粒子存放 {x,v,…}；SoA（Structure of Arrays）分别存放 x[]、v[] 等字段数组。物理模型相同，适配器负责用统一接口访问这些数据。
      - ParticleAdapter（粒子适配器）：把主程序已有的粒子存储接到 G02 的“转换接头”，负责读取粒子和提交更新，不是额外的物理粒子。

   .. tip:: cell 与 state 的特殊值

      ``cell`` 是网格编号，不是数组下标。背景的 ``UINT32_MAX``表示全域备用背景；正常网格编号必须与粒子一致。
      ``invalid_state`` 是 C++ 的 65535 哨兵值，它只供按物种合并的背景使用，不等于基态，也不代表自动分配各态密度。
      入门时用 ``state_id(species, "ground")`` 查询真实态；名称须存在于模型。被跟踪粒子的态必须有效。

   .. rubric:: 这个文件做什么

   适配器让不同存储方式的粒子数组接入同一个步进器。MccStepper 处理整批粒子及其增删；MccWorkspace 复用工作内存。PreparedMccStep 把“准备结果”和“提交修改”分开，失败时可保持粒子状态不变。StepReport 汇总事件和背景交换量。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      ParticleAdapter, VectorParticleAdapter, SoaParticleAdapter, ParticleBank, MccStepper, MccWorkspace, PreparedMccStep, StepReport

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - AoS (Array of Structures) stores one record per particle; SoA (Structure of Arrays) stores separate arrays for fields such as x[] and v[]. Adapters expose either layout through one interface; the physical model is unchanged.
      - ParticleAdapter connects host-owned storage to G02, exposing particle reads and update commits. It is an interface, not another physical particle.
      - Reservoir deltas track background gains/losses of particles, momentum and energy. A conservation ledger compares totals before and after reactions. Do not apply both as background source terms.

   .. tip:: Special cell and state values

      cell is a mesh ID, not an array index. Background ``UINT32_MAX`` selects uniform fallback; local IDs must match particles.
      C++ ``invalid_state`` is the 65535 sentinel, only for species-aggregate backgrounds. It is not ground state and does not distribute density over states.
      Beginners can look up a real state with ``state_id(species, "ground")``; the label must exist in the model. Tracked particles must have valid states.

   .. rubric:: What this file does

   Adapters connect particle storage to MccStepper. Workspaces reuse memory; PreparedMccStep separates preparation from committing changes. StepReport collects events and reservoir exchange. Implemented in fun_G02_mcc_batch.cpp.

   .. rubric:: Main types and entry points

   .. code-block:: text

      ParticleAdapter, VectorParticleAdapter, SoaParticleAdapter, ParticleBank, MccStepper, MccWorkspace, PreparedMccStep, StepReport

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`batch.hpp <../../../../../G_Collision/G02_MCC_network/batch.hpp>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/batch.hpp
   :language: cpp
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/batch.hpp``

:doc:`Collision <group_collision>`
