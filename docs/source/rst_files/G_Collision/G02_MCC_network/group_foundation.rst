.. rst-class:: ap-g02 ap-g02-reference

Basics
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
      * - :doc:`mcc.hpp <mcc>`
        - C++ 总入口头文件
      * - :doc:`common.hpp <common>`
        - 基础类型、向量与物理常数
      * - :doc:`rng.hpp <rng>`
        - 可复现的随机数

.. container:: ap-lang ap-lang-en

   This group contains the source files below. Headers define types and interfaces; .cpp files implement them. Small utilities may be implemented inline in headers.

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - Source file
        - Purpose
      * - :doc:`mcc.hpp <mcc>`
        - C++ umbrella header
      * - :doc:`common.hpp <common>`
        - Basic types, vectors and physical constants
      * - :doc:`rng.hpp <rng>`
        - Reproducible random numbers

.. toctree::
   :maxdepth: 1
   :hidden:

   mcc.hpp <mcc>
   common.hpp <common>
   rng.hpp <rng>

:doc:`返回 G02 / Back to G02 <../G02_MCC_network>`
