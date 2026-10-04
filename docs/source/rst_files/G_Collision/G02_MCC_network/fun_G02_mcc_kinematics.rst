.. _final-state-kinematics:

.. rst-class:: ap-g02 ap-g02-reference

碰撞运动学：计算碰后速度
================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   实现文件：``fun_G02_mcc_kinematics.cpp``。下面保留对应 C++ 接口的实际名称，方便对照调用。

   .. rubric:: 直接用途

   真实碰撞已经被抽中后，这组函数负责“产物向哪里、以多快的速度运动”。
   它们在 kinematics.hpp 声明，共用 FinalState 返回类型。
   主程序通常通过 MccEngine 间接调用，单独研究运动学时才直接使用。

   .. list-table:: 子程序
      :header-rows: 1
      :widths: 36 34 30

      * - 名称
        - 输入要点
        - 返回与用途
      * - two_body_final_state
        - 两个质量、总动量、入射相对方向、可用动能、最低相对动能、角模型、余弦范围、随机数对象
        - 两个产物速度；各向同性或限定散射方向。
      * - identity_exchange_final_state
        - velocity1、velocity2
        - 按位置返回 velocity2、velocity1；不进行随机抽样。
      * - n_body_phase_space_final_state
        - 产物质量数组、总动量、可用动能、最低相对动能、随机数对象
        - 多产物的统计相空间抽样。
      * - equal_share_final_state
        - 与上项相同，但恰好两个产物
        - 守恒的二体分离；名称不代表不同质量时两者动能一定相等。
      * - single_product_final_state
        - 一个质量、总动量、可用动能
        - 单产物承载质心运动，剩余能量记为未分配量。

   .. rubric:: 参数单位和返回字段

   mass*_kg / masses_kg 用 kg；total_momentum 用 kg·m/s；
   available_kinetic_j、ker_min_j 用 J。前者是可供全部产物使用的总动能，
   后者约束相对质心运动的最低动能，不能把入射能量 eV 原样传入。
   relative_axis 只提供方向，cone 模型使用它，各向同性模型不依赖它。
   cosine_min/max 是角度余弦，范围 −1 到 1，前者不大于后者。
   rng 为可变 CounterRng 引用，调用会消耗随机数。

   返回 FinalState.velocities 与输入产物的排列对应，单位 m/s；
   unallocated_energy_j 记录没有交给被建模产物的能量。
   条件无法满足时抛 Error，例如质量无效、能量不足或产物数量不适合所选模型。

   .. rubric:: 从守恒到速度的思路

   先由总动量和总质量确定质心速度；
   从总可用动能中扣掉质心运动能量，剩余部分分配为产物在质心系的运动，
   最后加回质心速度。这使整体运动与相对运动的能量分别核算。

   G02 算法 C02–C08 的反应语义校验在 compile_model 中完成；
   运动学函数只拿到已准备的质量、能量和角模型，不负责判断一条反应是否属于电离或复合。
   identity_exchange 在引擎中还按产物物种重新映射，不能依赖 CSV 行顺序交换物种。
   支持范围与反应约束保留在 :doc:`原模块说明 <../G02_MCC_network>`。

.. container:: ap-lang ap-lang-en

   Implementation: ``fun_G02_mcc_kinematics.cpp``. The C++ interface names below match the callable API.

   .. rubric:: Direct purpose

   Once a real collision is selected, these helpers construct product velocities.
   Declarations are in kinematics.hpp and return FinalState.
   Ordinary hosts reach them through MccEngine.

   .. list-table:: Routines
      :header-rows: 1
      :widths: 36 34 30

      * - Routine
        - Key inputs
        - Purpose
      * - two_body_final_state
        - Two masses, momentum, relative axis, available/minimum energy, angular model, cosine bounds, RNG
        - Two outgoing velocities with isotropic or restricted angles.
      * - identity_exchange_final_state
        - velocity1, velocity2
        - Returns velocity2, velocity1 without sampling.
      * - n_body_phase_space_final_state
        - Mass array, momentum, available/minimum energy, RNG
        - Statistical multi-product phase space.
      * - equal_share_final_state
        - Same arguments, exactly two masses
        - Conserving two-body separation; unequal masses need not have equal kinetic energy.
      * - single_product_final_state
        - Mass, momentum, available energy
        - Centre-of-mass motion plus unallocated energy.

   .. rubric:: Units and outputs

   Masses use kg, total_momentum kg·m/s, and both energy arguments J.
   available_kinetic_j is total energy for all products; ker_min_j constrains relative kinetic energy.
   Do not pass eV without conversion.
   relative_axis gives the cone model's direction; isotropic scattering ignores it.
   Cosine bounds lie between −1 and 1 in increasing order.
   The mutable CounterRng is advanced.

   FinalState.velocities follows product order in m/s.
   unallocated_energy_j reports energy not given to modeled products.
   Invalid masses, insufficient energy or unsupported product counts throw Error.

   The calculation determines centre-of-mass velocity from momentum,
   removes its kinetic energy, constructs relative motion and adds the mean motion back.
   Reaction semantics are validated by compile_model rather than these helpers.
   The engine maps identity_exchange by product species, not CSV row order.
   See the :doc:`existing module guide <../G02_MCC_network>` for G02 algorithm C02–C08 constraints.

.. rubric:: Source signatures / 源码声明

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/kinematics.hpp
   :language: cpp
   :start-at: struct FinalState
   :end-before: } // namespace mcc

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fun_G02_mcc_kinematics.cpp``

:doc:`Collision <group_collision>`
