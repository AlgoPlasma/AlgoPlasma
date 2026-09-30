.. rst-class:: ap-g02 ap-g02-reference

mcc_api_version：查询接口版本
====================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - ABI（应用二进制接口）规定不同语言编译后怎样传参和返回结果。handle（句柄）是库对象的引用；保存并通过接口使用它，不直接读取其内部数据。

   .. tip:: Fortran 片段需要的声明

      ``iso_c_binding`` 是 Fortran 自带的 C 类型桥接模块，提供 ``c_double``、``c_int``、``c_int32_t``、``c_int64_t`` 等类型参数。G02 不会把这些名称转导出给主程序。
      在主程序声明区先写 ``use, intrinsic :: iso_c_binding``，再写 ``use mod_G02_MCC_network`` 和 ``implicit none``；``status`` 声明为 ``integer(c_int)``。
      本页简短调用式需要相应的 context、数组和步参数；:doc:`完整声明与初始化 <sub_G02_mcc_load>` 给出可构建示例。

   .. rubric:: 直接用途

   返回当前 C 接口的 ABI 版本号，供主程序检查接口是否匹配。ABI 是不同语言之间
   约定的调用规则；这个数字不是碰撞数据包版本，也不表示物理模型的精度。
   当前返回 ``1_c_int``。此函数无需先加载模型，也不分配资源。

   .. code-block:: fortran

      use, intrinsic :: iso_c_binding
      use mod_G02_MCC_network
      integer(c_int) :: version
      version = fun_G02_mcc_api_version()

   该函数没有输入参数；结果是 ``integer(c_int)``。
   源码由 ``mod_G02_MCC_network`` 包含，内部直接调用 ``ap_g02_mcc_api_version``。
   物种和反应查询见 :doc:`sub_G02_mcc_model_queries`。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.

   .. tip:: Declarations required by Fortran fragments

      The intrinsic ``iso_c_binding`` module provides C-compatible kinds such as ``c_double``, ``c_int``, ``c_int32_t`` and ``c_int64_t``. G02 does not re-export them to the host.
      In the declaration section, write ``use, intrinsic :: iso_c_binding``, ``use mod_G02_MCC_network`` and ``implicit none``; declare status as ``integer(c_int)``.
      Short calls assume initialized context, arrays and step parameters; see :doc:`the complete caller <sub_G02_mcc_load>`.

   .. rubric:: Direct purpose

   Return the C ABI version so a host can check interface compatibility.
   ABI describes the calling contract across languages; it is neither a dataset version nor a measure of model accuracy.
   The current result is ``1_c_int``. No loaded model or allocated resource is needed.

   .. code-block:: fortran

      use, intrinsic :: iso_c_binding
      use mod_G02_MCC_network
      integer(c_int) :: version
      version = fun_G02_mcc_api_version()

   There are no input arguments; the result is ``integer(c_int)``.
   The module includes this file and calls ``ap_g02_mcc_api_version`` internally.
   See :doc:`sub_G02_mcc_model_queries` for species and reaction queries.

.. rubric:: Source / 源码

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/fun_G02_mcc_api_version.f90
   :language: fortran

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fortran_interface/fun_G02_mcc_api_version.f90``

:doc:`Fortran API <group_fortran_interface>`
