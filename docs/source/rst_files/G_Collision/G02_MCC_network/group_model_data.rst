.. rst-class:: ap-g02 ap-g02-reference

Model
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   这一组包含下面这些源码文件。头文件（.hpp / .h）约定可使用的类型和接口，实现文件（.cpp）完成计算；部分小工具直接实现在头文件中。

   :doc:`CSV 数据格式与填写 <csv_format>`

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - 程序文件
        - 用途
      * - :doc:`csv.hpp <csv>`
        - CSV 读取接口与数据容器
      * - :doc:`fun_G02_mcc_csv.cpp <fun_G02_mcc_csv>`
        - 解析 CSV 文本与报告格式错误
      * - :doc:`table.hpp <table>`
        - 数据表、插值和越界策略接口
      * - :doc:`fun_G02_mcc_table.cpp <fun_G02_mcc_table>`
        - 执行插值与计算区间上界
      * - :doc:`model.hpp <model>`
        - 描述物种、内部态和反应网络
      * - :doc:`fun_G02_mcc_model.cpp <fun_G02_mcc_model>`
        - 模型加载与校验：读取 CSV 反应数据
      * - :doc:`compile.hpp <compile>`
        - 模型编译接口与运行时数据
      * - :doc:`fun_G02_mcc_compile.cpp <fun_G02_mcc_compile>`
        - 检查物理约束并准备抽样数据

.. container:: ap-lang ap-lang-en

   This group contains the source files below. Headers define types and interfaces; .cpp files implement them. Small utilities may be implemented inline in headers.

   :doc:`CSV model format and preparation <csv_format>`

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - Source file
        - Purpose
      * - :doc:`csv.hpp <csv>`
        - CSV interfaces and containers
      * - :doc:`fun_G02_mcc_csv.cpp <fun_G02_mcc_csv>`
        - Parse CSV text and report format errors
      * - :doc:`table.hpp <table>`
        - Tables, interpolation and domain policies
      * - :doc:`fun_G02_mcc_table.cpp <fun_G02_mcc_table>`
        - Interpolate and bound table segments
      * - :doc:`model.hpp <model>`
        - Describe species, states and reactions
      * - :doc:`fun_G02_mcc_model.cpp <fun_G02_mcc_model>`
        - Model loading and validation: CSV reaction data
      * - :doc:`compile.hpp <compile>`
        - Model compilation and runtime data
      * - :doc:`fun_G02_mcc_compile.cpp <fun_G02_mcc_compile>`
        - Check physical constraints and prepare sampling data

.. toctree::
   :maxdepth: 1
   :hidden:

   CSV format <csv_format>
   csv.hpp <csv>
   fun_G02_mcc_csv.cpp <fun_G02_mcc_csv>
   table.hpp <table>
   fun_G02_mcc_table.cpp <fun_G02_mcc_table>
   model.hpp <model>
   fun_G02_mcc_model.cpp <fun_G02_mcc_model>
   compile.hpp <compile>
   fun_G02_mcc_compile.cpp <fun_G02_mcc_compile>

:doc:`返回 G02 / Back to G02 <../G02_MCC_network>`
