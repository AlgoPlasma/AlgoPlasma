.. _g03-implementation:

.. rst-class:: ap-g03

DSMC 源码导读：沿一次碰撞步阅读主库
========================================================================

本章从 ``DsmcStepper::step`` 出发，沿真实调用顺序说明数据怎样进入工作区、怎样分组和碰撞，
以及怎样写回原始粒子数组。Theory & Algorithm 中的核、散射函数与候选循环在这里接成完整调用链。
代码摘录直接来自主库，标题给出文件和函数，左侧行号对应源文件。
这里的“调用程序”负责初始化、粒子推进与边界处理、时间循环，并调用 G03 完成碰撞。

.. contents:: 本章阅读顺序
   :local:
   :depth: 1

.. include:: implementation.inc

.. include:: particles.inc

.. include:: model.inc
