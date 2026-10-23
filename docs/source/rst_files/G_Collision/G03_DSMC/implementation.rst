.. _g03-implementation:

.. rst-class:: ap-g03

Source Guide
========================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   本章从 ``DsmcStepper::step`` 出发，沿真实调用顺序说明数据怎样进入工作区、怎样分组和碰撞，
   以及怎样写回原始粒子数组。Theory & Algorithm 中的核、散射函数与候选循环在这里接成完整调用链。
   代码摘录直接来自主库，标题给出文件和函数，左侧行号对应源文件。
   这里的“调用程序”负责初始化、粒子推进与边界处理、时间循环，并调用 G03 完成碰撞。

.. container:: ap-lang ap-lang-en

   Follow ``DsmcStepper::step`` through snapshot input, grouping, cell collisions and velocity commit. The kernels and candidate loops derived in Theory & Algorithm are assembled into the actual call chain. Excerpts come directly from the library with original line numbers. The calling program supplies initialization, transport, boundaries and the outer time loop.

.. contents:: Contents
   :local:
   :depth: 1

.. include:: implementation.inc

.. include:: particles.inc

.. include:: model.inc
