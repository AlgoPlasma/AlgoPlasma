.. rst-class:: ap-g02 ap-g02-reference

mcc.hpp：C++ 总入口头文件
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这个文件做什么

   在主程序中包含这个文件，就能使用常规 C++ 碰撞接口。它只汇总其他头文件，不执行碰撞，也没有对应的独立实现文件。MPI 用户还需要单独包含 mpi.hpp。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      common.hpp, batch.hpp, compile.hpp, csv.hpp, engine.hpp, kinematics.hpp, model.hpp, rng.hpp, table.hpp

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: What this file does

   Include this header to access the regular C++ API. It collects declarations and performs no collisions. MPI users must also include mpi.hpp.

   .. rubric:: Main types and entry points

   .. code-block:: text

      common.hpp, batch.hpp, compile.hpp, csv.hpp, engine.hpp, kinematics.hpp, model.hpp, rng.hpp, table.hpp

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`mcc.hpp <../../../../../G_Collision/G02_MCC_network/mcc.hpp>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/mcc.hpp
   :language: cpp
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/mcc.hpp``

:doc:`Basics <group_foundation>`
