.. rst-class:: ap-g02 ap-g02-reference

model.hpp：描述物种、内部态和反应网络
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   :ref:`CSV 允许值、必填键与默认值 <g02-schema-zh>`。

   .. rubric:: 这个文件做什么

   这些类型相当于碰撞模型的清单：有哪些粒子、每种粒子有哪些内部态、每条反应消耗和生成什么。注册表把名称转换成程序用的 ID。load_model_package 读入 CSV 数据包，返回 ModelDefinition；它还不是可直接推进的运行时模型。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      Species, State, SpeciesRegistry, StateRegistry, ReactantTerm, ProductTerm, ReactionDefinition, ModelDefinition; load_model_package

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   :ref:`CSV allowed values, required keys and defaults <g02-schema-en>`.

   .. rubric:: What this file does

   These types describe species, internal states and reaction terms. Registries resolve names to IDs. load_model_package returns a ModelDefinition from a CSV package; compilation is needed before stepping.

   .. rubric:: Main types and entry points

   .. code-block:: text

      Species, State, SpeciesRegistry, StateRegistry, ReactantTerm, ProductTerm, ReactionDefinition, ModelDefinition; load_model_package

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`model.hpp <../../../../../G_Collision/G02_MCC_network/model.hpp>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/model.hpp
   :language: cpp
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/model.hpp``

:doc:`Model <group_model_data>`
