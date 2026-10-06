.. rst-class:: ap-g02 ap-g02-reference

common.hpp：基础类型、向量与物理常数
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这个文件做什么

   Vec3 保存三个方向的速度或动量分量；norm 求长度，dot 求点积。这里还定义元电荷、玻尔兹曼常数等。各计算文件共同使用这些类型，避免单位转换和类型定义各写一套。向量运算在头文件内实现，无需独立编译。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      Real, SpeciesId, StateId, ReactionId, Vec3, Error; dot, cross, norm, normalized

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: What this file does

   Vec3 stores three vector components. Shared IDs, constants and vector operations keep the computation consistent. Vector operations are defined inline; there is no separate implementation file.

   .. rubric:: Main types and entry points

   .. code-block:: text

      Real, SpeciesId, StateId, ReactionId, Vec3, Error; dot, cross, norm, normalized

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`common.hpp <../../../../../G_Collision/G02_MCC_network/common.hpp>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/common.hpp
   :language: cpp
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/common.hpp``

:doc:`Basics <group_foundation>`
