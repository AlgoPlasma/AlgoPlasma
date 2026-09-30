.. rst-class:: ap-g02 ap-g02-reference

fun_G02_mcc_mpi_c_api.cpp：将跨语言数组交给 MPI 步进器
====================================================================================

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

   把 C 或 Fortran 传来的句柄、数组和参数交给 DistributedMccStepper，并把结果转回 C 接口格式。创建和步进属于集合操作，各进程必须一起调用。某个进程准备失败或容量不足时，所有进程的粒子数组均不提交修改。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      ap_g02_mcc_mpi_session_create / create_f / destroy / step

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.

   .. rubric:: What this file does

   Converts handles, arrays and parameters for DistributedMccStepper and returns C-compatible reports. Creation and stepping are collective. A preparation failure or insufficient capacity on any rank prevents particle-array commits on every rank.

   .. rubric:: Main types and entry points

   .. code-block:: text

      ap_g02_mcc_mpi_session_create / create_f / destroy / step

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`fun_G02_mcc_mpi_c_api.cpp <../../../../../G_Collision/G02_MCC_network/fun_G02_mcc_mpi_c_api.cpp>`


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fun_G02_mcc_mpi_c_api.cpp``

:doc:`MPI <group_mpi_interface>`
