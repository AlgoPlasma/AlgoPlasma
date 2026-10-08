.. rst-class:: ap-g02 ap-g02-reference

fun_G02_mcc_csv.cpp：解析 CSV 文本与报告格式错误
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   :ref:`CSV 允许值、必填键与默认值 <g02-schema-zh>`。

   .. rubric:: 这个文件做什么

   读取文件，拆分逗号字段，处理带引号的字段和双引号转义；忽略空行和整行 # 注释。每行字段数必须和表头一致，不支持跨行字段。转换失败时给出文件和行号，方便找到输入错误。fnv1a64_hex 用于可选的完整性校验，不是加密签名。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      read_csv_table(path) -> CsvTable; parse_csv_line; csv_real / csv_int / csv_bool

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   :ref:`CSV allowed values, required keys and defaults <g02-schema-en>`.

   .. rubric:: What this file does

   Reads CSV files with quoted fields and doubled quotes, ignoring blank lines and full-line # comments. Field counts must match the header; multiline fields are unsupported. Conversion errors include source context. FNV-1a is an integrity checksum, not a cryptographic signature.

   .. rubric:: Main types and entry points

   .. code-block:: text

      read_csv_table(path) -> CsvTable; parse_csv_line; csv_real / csv_int / csv_bool

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`fun_G02_mcc_csv.cpp <../../../../../G_Collision/G02_MCC_network/fun_G02_mcc_csv.cpp>`


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fun_G02_mcc_csv.cpp``

:doc:`Model <group_model_data>`
