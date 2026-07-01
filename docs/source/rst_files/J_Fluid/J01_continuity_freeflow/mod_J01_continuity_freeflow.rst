mod_J01_continuity_freeflow.f90
-------------------------------

.. raw:: html

   <div class="pmsl-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="zh">中文</button>
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="en">English</button>
   </div>

.. container:: pmsl-lang pmsl-lang-zh

   .. rubric:: 直接用途

   ``mod_J01_continuity_freeflow`` 是该目录的模块包装器，集中 include 或暴露本组公开入口。

   .. rubric:: 公开入口与 include 关系

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - 文件/符号
        - 角色
        - 调用约定
      * - ``sub_J01_continuity_freeflow.f90``
        - 被模块 include 的公开源码入口
        - 调用方通常通过本模块 ``use`` 后访问具体例程；不要把 include 文件当作独立 translation unit 编译。

   .. rubric:: 局部假设

   连续性方程例程只更新 ``il``/``iu`` 定义的 active cell。当前实现采用归一化 ``dx=dy=dz=dt=1``；边界和 ghost cell 需要调用方在进入本例程前准备好。

   .. rubric:: 实现逻辑

   该模块主要通过 ``include`` 或 ``contains`` 汇总本目录公开入口；调用方通常 ``use`` 模块后调用具体子程序。

   .. rubric:: 调用注意

   本页只说明该例程本身的调用边界和实现事实；完整接口声明和源码级 API 仍以英文侧的 generated API 为准。

.. container:: pmsl-lang pmsl-lang-en

   .. rubric:: Direct Purpose

   ``mod_J01_continuity_freeflow`` module wrapper for the free-flow continuity update routine.

   .. rubric:: Public Entries And Includes

   .. list-table::
      :header-rows: 1
      :widths: 34 24 42

      * - File/symbol
        - Role
        - Calling convention
      * - ``sub_J01_continuity_freeflow.f90``
        - included public source entry
        - Call concrete routines through this module after ``use``; include files are not
          standalone translation units.

   .. rubric:: Local Assumptions

   The continuity routine updates only active cells defined by ``il``/``iu``. The current implementation uses normalized ``dx=dy=dz=dt=1``; boundary and ghost-cell values must be prepared by the caller before entry.

   .. rubric:: Implementation Notes

   This module groups public entries through ``include`` or ``contains``; callers normally ``use`` the module and call the concrete routine.

   .. rubric:: Generated API

   .. doxygenfile:: mod_J01_continuity_freeflow.f90
