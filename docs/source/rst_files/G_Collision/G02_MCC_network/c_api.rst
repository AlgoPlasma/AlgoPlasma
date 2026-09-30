.. rst-class:: ap-g02 ap-g02-reference

c_api.h：供 C 和跨语言调用的公共接口
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

   头文件定义 C 能识别的数据结构和不透明句柄。句柄可理解为库管理对象的编号，调用者通过接口操作对象，而不访问 C++ 内部成员。调用后检查状态码和错误缓冲区，并用配套 destroy 接口释放对象。C++ 异常不会直接穿过 C 接口。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      ap_g02_mcc_*; engine / outcome / step_report / session handles

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.

   .. rubric:: What this file does

   Defines C-compatible records and opaque handles for engines, outcomes, reports and sessions. Check status codes and error buffers, and destroy owned handles with the matching functions. C++ exceptions do not cross this boundary.

   .. rubric:: Main types and entry points

   .. code-block:: text

      ap_g02_mcc_*; engine / outcome / step_report / session handles

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`c_api.h <../../../../../G_Collision/G02_MCC_network/c_api.h>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/c_api.h
   :language: c
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/c_api.h``

:doc:`C API <group_c_interface>`
