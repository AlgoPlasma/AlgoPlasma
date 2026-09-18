sub_J02_sn_error.f90
====================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 错误码说明

   源码：``J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_error.f90``。
   由 ``mod_J02_neutral_sn_transport_2Drz`` 包含，不能作为独立模块编译。
   :doc:`返回模块总览 <../J02_neutral_sn_transport_2Drz>`。
   正文中的简写过程名省略了所属模块的 sub 前缀，完整接口见下方声明。

   .. rubric:: 功能与返回值

   本文件提供 ``fun_J02_error_message(ierr)``，将整数状态码转换为可读字符串。
   它不打印、不终止程序，也不修改数值场。调用方应先检查 ierr，再记录错误信息与上下文。
   成功码为零，未识别的整数返回未知错误说明。错误码仅在所属模块内解释，日志应带模块名。

   .. rubric:: 诊断范围

   网格与几何错误定位输入尺寸或坐标；求积与入口错误定位节点和分布；局部求解与扫描错误结合 failed_direction、failed_i、failed_k 定位；未收敛错误表示反射迭代达到上限。

   .. rubric:: 逐个过程的接口声明

   以下声明来自本文件。``intent(in)`` 为输入，``intent(out)`` 为本次调用的输出，
   ``intent(inout)`` 表示原值参与计算并被修改；``allocatable, intent(out)`` 数组由过程分配。
   ``optional`` 可省略，数组形状中的 nr、nz 为网格单元数。过程名中的 sub/fun 前缀不改变 Fortran 调用规则。

   .. rubric:: fun_J02_error_message

   .. code-block:: fortran

      function fun_J02_error_message(ierr) result(message)
      integer, intent(in) :: ierr

   .. rubric:: 测试与源码

   :doc:`对应测试及断言 </tests/011_fluid/J02_tests>` 列出调用本文件的测试项。
   :download:`下载实现源码 <../../../../../J_Fluid/J02_neutral_sn_transport_2Drz/sub_J02_sn_error.f90>`。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   This file is included by ``mod_J02_neutral_sn_transport_2Drz``.
   :doc:`Module overview <../J02_neutral_sn_transport_2Drz>` · :doc:`Tests </tests/011_fluid/J02_tests>`.
