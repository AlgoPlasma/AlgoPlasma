.. rst-class:: ap-g02 ap-g02-reference

table.hpp：数据表、插值和越界策略接口
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这个文件做什么

   离散数据只有若干采样点，Table 负责定义怎样查询点与点之间的值。它保存数据及单位、来源等信息。sample 返回插值结果，并通过 outside 告知是否超出表格范围。对应实现是 fun_G02_mcc_table.cpp。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      Table; Interpolation; DomainPolicy; validate, sample, segment_upper_bounds, upper_bound

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: What this file does

   Table stores sampled data and metadata. sample interpolates between samples and reports out-of-domain queries through outside. Implemented in fun_G02_mcc_table.cpp.

   .. rubric:: Main types and entry points

   .. code-block:: text

      Table; Interpolation; DomainPolicy; validate, sample, segment_upper_bounds, upper_bound

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`table.hpp <../../../../../G_Collision/G02_MCC_network/table.hpp>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/table.hpp
   :language: cpp
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/table.hpp``

:doc:`Model <group_model_data>`
