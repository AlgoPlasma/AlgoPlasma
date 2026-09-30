.. rst-class:: ap-g02 ap-g02-reference

c_api_internal.hpp：C 接口内部共享的句柄定义
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

   .. rubric:: 这个文件做什么

   供普通 C 接口与 MPI C 接口的实现文件共享内部结构：引擎句柄保存 MccEngine 和粒子 ID 分配状态，报告句柄保存 StepReport。它是私有头文件，不随公共头文件安装；用户程序包含 c_api.h 即可。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      ap_g02_mcc_engine; ap_g02_mcc_step_report

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.

   .. rubric:: What this file does

   Shares concrete handle storage between the C and MPI C implementations. The engine holds MccEngine and ID allocation state; the report holds StepReport. This private header is not installed and should not be included by host programs.

   .. rubric:: Main types and entry points

   .. code-block:: text

      ap_g02_mcc_engine; ap_g02_mcc_step_report

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`c_api_internal.hpp <../../../../../G_Collision/G02_MCC_network/c_api_internal.hpp>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/c_api_internal.hpp
   :language: cpp
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/c_api_internal.hpp``

:doc:`C API <group_c_interface>`
