.. rst-class:: ap-g02 ap-g02-reference

mpi_c_api.h：MPI 的 C 与 Fortran 桥接接口
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

   声明分布式会话的创建、销毁与步进。create 接收 C 的 MPI_Comm，create_f 接收 Fortran 通信器对应的整数句柄。粒子数组还要提供当前数量和容量；容量不足时可读取 required，扩容后重试。实现见 fun_G02_mcc_mpi_c_api.cpp。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      ap_g02_mcc_mpi_session_create; create_f; destroy; session_step

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.

   .. rubric:: What this file does

   Declares distributed sessions. create accepts MPI_Comm; create_f accepts a Fortran communicator handle. Array calls provide count and capacity; required reports needed capacity for retry. Implemented in fun_G02_mcc_mpi_c_api.cpp.

   .. rubric:: Main types and entry points

   .. code-block:: text

      ap_g02_mcc_mpi_session_create; create_f; destroy; session_step

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`mpi_c_api.h <../../../../../G_Collision/G02_MCC_network/mpi_c_api.h>`

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/mpi_c_api.h
   :language: c
   :linenos:


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/mpi_c_api.h``

:doc:`MPI <group_mpi_interface>`
