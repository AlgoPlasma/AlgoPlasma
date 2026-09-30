.. rst-class:: ap-g02 ap-g02-reference

compile.hpp：模型编译接口与运行时数据
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - majorant（频率上界）：一个不小于真实碰撞频率的数，用它安排候选事件，再按“真实频率÷上界”接受候选。上界过松会增加空碰撞；低于真实频率则报错。

   .. rubric:: 这个文件做什么

   这里的“编译”是整理碰撞数据，不是把 C++ 编译成机器码。CompileOptions 配置频率上界的安全系数等；CompiledReaction 保存已解析的反应信息，CompiledModel 供 MccEngine 使用。对应实现是 fun_G02_mcc_compile.cpp。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      CompileOptions, CompiledReaction, CompiledModel; compile_model(ModelDefinition, CompileOptions)

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: What this file does

   Compilation here means preparing collision data, not compiling C++. Options control bounds and validation; CompiledModel is consumed by MccEngine. Implemented in fun_G02_mcc_compile.cpp.

   .. rubric:: Main types and entry points

   .. code-block:: text

      CompileOptions, CompiledReaction, CompiledModel; compile_model(ModelDefinition, CompileOptions)

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`compile.hpp <../../../../../G_Collision/G02_MCC_network/compile.hpp>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/compile.hpp
   :language: cpp
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/compile.hpp``

:doc:`Model <group_model_data>`
