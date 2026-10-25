.. _g03-fundamentals:

.. rst-class:: ap-g03

Theory & Algorithm
========================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   本章沿着气体分布、二体碰撞、碰撞模型、随机事件和单元推进这一条链路展开 DSMC。
   先由分布与守恒律明确碰撞核和角分布，再用输运数据确定模型参数；随后从 Boltzmann 碰撞算子推导模拟粒子对的事件率，构造 NTC 与连续时钟，最后给出非均匀三维柱坐标单元和随机抽样的实现。
   每段公式后接实际源码、变量对应和原始行号，可以在同一页连续阅读物理依据与实现过程。Source Guide 则沿一次 ``DsmcStepper::step`` 说明数据读取、单元遍历、报告汇总和写回。

.. container:: ap-lang ap-lang-en

   This chapter connects gas distributions, binary invariants, collision models, stochastic events and cell evolution. Derive the rate kernel and angular law, calibrate transport parameters, then construct finite-particle pair rates, NTC and the continuous clock. Nonuniform cylindrical cells and random sampling complete the implementation. Equations are paired with actual source functions and line numbers; Source Guide traces one complete ``DsmcStepper::step`` call.

.. contents:: Contents
   :local:
   :depth: 1

.. include:: fundamentals.inc

.. include:: rate.inc

.. include:: scattering.inc

.. include:: calibration.inc

.. include:: algorithm.inc

.. include:: cells.inc

.. include:: random.inc

.. include:: references.inc
