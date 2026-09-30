.. rst-class:: ap-g02 ap-g02-reference

fun_G02_mcc_compile.cpp：检查物理约束并准备抽样数据
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这个文件做什么

   把名称和反应项整理成运行时结构，检查反应阶数、单位、电荷与元素守恒、能量阈值以及支持的模型组合。根据插值区间构造保守上界，用于候选碰撞抽样。发现不一致就抛出 Error，防止错误数据进入时间推进。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      compile_model(definition, options) -> CompiledModel

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: What this file does

   Resolves runtime reaction data and checks order, units, charge, elements, energy thresholds and supported model combinations. Builds conservative bounds from interpolation segments. Invalid data raises Error before stepping.

   .. rubric:: Main types and entry points

   .. code-block:: text

      compile_model(definition, options) -> CompiledModel

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`fun_G02_mcc_compile.cpp <../../../../../G_Collision/G02_MCC_network/fun_G02_mcc_compile.cpp>`


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fun_G02_mcc_compile.cpp``

:doc:`Model <group_model_data>`
