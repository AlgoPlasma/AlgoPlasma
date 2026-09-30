.. rst-class:: ap-g02 ap-g02-reference

C API
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - ABI（应用二进制接口）规定不同语言编译后怎样传参和返回结果。handle（句柄）是库对象的引用；保存并通过接口使用它，不直接读取其内部数据。

   这一组包含下面这些源码文件。头文件（.hpp / .h）约定可使用的类型和接口，实现文件（.cpp）完成计算；部分小工具直接实现在头文件中。

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - 程序文件
        - 用途
      * - :doc:`c_api.h <c_api>`
        - 供 C 和跨语言调用的公共接口
      * - :doc:`c_api_internal.hpp <c_api_internal>`
        - C 接口内部共享的句柄定义
      * - :doc:`fun_G02_mcc_c_api.cpp <fun_G02_mcc_c_api>`
        - C 接口：连接 C、C++ 与 Fortran

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.

   This group contains the source files below. Headers define types and interfaces; .cpp files implement them. Small utilities may be implemented inline in headers.

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - Source file
        - Purpose
      * - :doc:`c_api.h <c_api>`
        - Public C and cross-language API
      * - :doc:`c_api_internal.hpp <c_api_internal>`
        - Private handle definitions for C wrappers
      * - :doc:`fun_G02_mcc_c_api.cpp <fun_G02_mcc_c_api>`
        - C interface: connect C, C++ and Fortran

.. toctree::
   :maxdepth: 1
   :hidden:

   c_api.h <c_api>
   c_api_internal.hpp <c_api_internal>
   fun_G02_mcc_c_api.cpp <fun_G02_mcc_c_api>

:doc:`返回 G02 / Back to G02 <../G02_MCC_network>`
