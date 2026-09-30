.. _g02-mcc-load:

.. rst-class:: ap-g02 ap-g02-reference

mcc_load：加载碰撞模型
======================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip:: Fortran 片段需要的声明

      ``iso_c_binding`` 是 Fortran 自带的 C 类型桥接模块，提供 ``c_double``、``c_int``、``c_int32_t``、``c_int64_t`` 等类型参数。G02 不会把这些名称转导出给主程序。
      在主程序声明区先写 ``use, intrinsic :: iso_c_binding``，再写 ``use mod_G02_MCC_network`` 和 ``implicit none``；``status`` 声明为 ``integer(c_int)``。
      本页简短调用式需要相应的 context、数组和步参数；:doc:`完整声明与初始化 <sub_G02_mcc_load>` 给出可构建示例。

   .. tip:: 可直接构建的最小调用程序

      以下程序已给出必要声明和变量来源。运行参数为 ``tests/009_collision/G02_MCC_network/data/collision_box_elastic``，不要换成不含 A/B 的模型。

   .. literalinclude:: ../../../../../tests/009_collision/G02_MCC_network/examples/doc_snippets/minimal.f90
      :language: fortran

   源码：``fortran_interface/sub_G02_mcc_load.f90``，由 ``mod_G02_MCC_network`` 包含。

   .. rubric:: 直接用途

   从一个模型包目录加载反应数据，并建立可调用的碰撞上下文。
   “模型包”就是带有 ``manifest.csv`` 的目录。通常在模拟开始前调用一次。

   .. code-block:: fortran

      call sub_G02_mcc_load(context, package_dir, status)

   .. list-table:: 参数
      :header-rows: 1
      :widths: 22 12 26 40

      * - 参数
        - 方向
        - 类型/范围
        - 含义
      * - ``context``
        - inout
        - ``type(g02_mcc_context)``
        - 保存模型、引擎及最近的诊断。
      * - ``package_dir``
        - in
        - ``character(len=*)``
        - 模型目录；相对路径以运行程序时的工作目录为基准。
      * - ``status``
        - out
        - ``integer(c_int)``
        - 0 成功；其他值见 :doc:`fun_G02_mcc_c_api`。

   .. rubric:: 内部顺序与失败行为

   先调用 ``sub_G02_mcc_close`` 释放 context 中的旧模型，再加载并校验 CSV，
   然后创建 C++ 引擎。成功后 ``context%loaded=.true.``。
   重新加载失败时，旧模型已经释放；本函数没有“失败后保留旧模型”的约定。
   要比较两个模型，使用两个独立 context。

   Fortran 包装使用 1024 字节路径缓冲（包含字符串结束符）；模型路径应短于它。
   错误文字放在 ``context%error_message``，例如文件不存在、单位不匹配、反应不守恒。
   加载只建立规则，不会生成粒子或推进物理时间。

   .. code-block:: fortran

      call sub_G02_mcc_load(context, "tests/009_collision/G02_MCC_network/data/collision_box_elastic", status)
      if (status /= 0_c_int) then
          print *, trim(context%error_message)
          stop 1
      end if

   随后用 :doc:`sub_G02_mcc_model_queries` 查物种 ID，建立粒子，再调用 :doc:`sub_G02_mcc_step`。
   结束时调用 :doc:`sub_G02_mcc_close <sub_G02_mcc_cleanup>`。

.. container:: ap-lang ap-lang-en

   .. tip:: Declarations required by Fortran fragments

      The intrinsic ``iso_c_binding`` module provides C-compatible kinds such as ``c_double``, ``c_int``, ``c_int32_t`` and ``c_int64_t``. G02 does not re-export them to the host.
      In the declaration section, write ``use, intrinsic :: iso_c_binding``, ``use mod_G02_MCC_network`` and ``implicit none``; declare status as ``integer(c_int)``.
      Short calls assume initialized context, arrays and step parameters; see :doc:`the complete caller <sub_G02_mcc_load>`.

   .. tip:: Complete buildable caller

      Declarations and input initialization are included. Pass ``tests/009_collision/G02_MCC_network/data/collision_box_elastic``; the caller requires its A/B species.

   .. literalinclude:: ../../../../../tests/009_collision/G02_MCC_network/examples/doc_snippets/minimal.f90
      :language: fortran

   Source: ``fortran_interface/sub_G02_mcc_load.f90``, included by ``mod_G02_MCC_network``.

   .. rubric:: Direct purpose

   Load reaction data from a directory containing ``manifest.csv`` and create a collision context.
   Call once before the time loop.

   .. code-block:: fortran

      call sub_G02_mcc_load(context, package_dir, status)

   .. list-table:: Parameters
      :header-rows: 1
      :widths: 22 12 26 40

      * - Parameter
        - Direction
        - Type
        - Meaning
      * - ``context``
        - inout
        - ``type(g02_mcc_context)``
        - Model, engine and last diagnostic.
      * - ``package_dir``
        - in
        - ``character(len=*)``
        - Package directory, relative to the process working directory if not absolute.
      * - ``status``
        - out
        - ``integer(c_int)``
        - 0 on success; see :doc:`fun_G02_mcc_c_api`.

   .. rubric:: Sequence and failure

   The routine first closes the old context, then loads/validates CSV data and creates the C++ engine.
   Success sets ``context%loaded=.true.``. A failed reload does not preserve the previous model.
   Use two contexts to compare models.

   The wrapper has a 1024-byte path buffer including the terminator; keep paths shorter.
   Diagnostics go to ``context%error_message``.
   Loading creates rules, not particles, and does not advance time.

   .. code-block:: fortran

      call sub_G02_mcc_load(context, "tests/009_collision/G02_MCC_network/data/collision_box_elastic", status)
      if (status /= 0_c_int) then
          print *, trim(context%error_message)
          stop 1
      end if

   Continue with :doc:`sub_G02_mcc_model_queries` and :doc:`sub_G02_mcc_step`.
   Finish with :doc:`sub_G02_mcc_close <sub_G02_mcc_cleanup>`.

.. rubric:: Declarations in source / 源码中的接口声明

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_load.f90
   :language: fortran
   :start-at: subroutine sub_G02_mcc_load(context, package_dir, status)
   :end-before: character(kind=c_char), dimension(1024), target :: cpath

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fortran_interface/sub_G02_mcc_load.f90``

:doc:`Fortran API <group_fortran_interface>`
