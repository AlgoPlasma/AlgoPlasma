.. rst-class:: ap-g02 ap-g02-reference

csv.hpp：CSV 读取接口与数据容器
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   :ref:`CSV 允许值、必填键与默认值 <g02-schema-zh>`。

   .. rubric:: 这个文件做什么

   CsvTable 保存表头、数据行和文件路径；按列名取值后，可转换成数值或布尔值。这个层只负责文本读取，物种和反应含义由模型层检查。对应实现是 fun_G02_mcc_csv.cpp。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      CsvRow, CsvTable; parse_csv_line, read_csv_table, csv_real, csv_real_or, csv_int, csv_bool, trim, to_lower, fnv1a64_hex

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.

   :ref:`CSV allowed values, required keys and defaults <g02-schema-en>`.

   .. rubric:: What this file does

   CsvTable stores a header, rows and source path. Named fields can be converted to numbers or booleans. This layer handles text; model validation handles physical meaning. Implemented in fun_G02_mcc_csv.cpp.

   .. rubric:: Main types and entry points

   .. code-block:: text

      CsvRow, CsvTable; parse_csv_line, read_csv_table, csv_real, csv_real_or, csv_int, csv_bool, trim, to_lower, fnv1a64_hex

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`csv.hpp <../../../../../G_Collision/G02_MCC_network/csv.hpp>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/csv.hpp
   :language: cpp
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/csv.hpp``

:doc:`Model <group_model_data>`
