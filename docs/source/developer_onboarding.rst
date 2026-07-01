PMSL Quick Start
================

.. toctree::
   :maxdepth: 1
   :hidden:

   user_quick_start
   developer_quick_start

.. raw:: html

   <div class="pmsl-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="zh">中文</button>
     <button type="button" class="pmsl-lang-button" data-pmsl-set-lang="en">English</button>
   </div>

.. container:: pmsl-lang pmsl-lang-zh pmsl-onboarding

   .. container:: pmsl-onboarding-hero

      .. rubric:: PMSL 快速入门

      先选路线，不要一上来读完整仓库。只是想调用 PMSL 的人走“使用者路线”；要参与维护和开发的人走“开发者路线”。

      .. raw:: html

         <div class="pmsl-onboarding-path" aria-label="Onboarding routes">
           <span>选路线</span>
           <span>跑通一个例子</span>
           <span>调用一个子程序</span>
           <span>再决定是否参与开发</span>
         </div>

   .. container:: pmsl-onboarding-grid

      .. container:: pmsl-onboarding-step pmsl-onboarding-user

         .. rubric:: 路线一：只想调用 PMSL

         目标是把库用起来。重点是怎么拿到源码、怎么跑一个已有测试、怎么在自己的 Fortran 程序里调用子程序。

         :doc:`进入使用者快速入门 <user_quick_start>`

      .. container:: pmsl-onboarding-step pmsl-onboarding-dev

         .. rubric:: 路线二：参与 PMSL 开发

         目标是能安全地改库。重点是目录结构、测试位置、文档入口、第一次贡献和提交前检查。

         :doc:`进入开发者快速入门 <developer_quick_start>`

   .. container:: pmsl-onboarding-done

      .. rubric:: 怎么判断选哪条

      - 只想在自己的程序里调用 PMSL 子程序：看使用者路线。
      - 要给 PMSL 补文档、补测试、改算法或维护模块：看开发者路线。

.. container:: pmsl-lang pmsl-lang-en pmsl-onboarding

   .. container:: pmsl-onboarding-hero

      .. rubric:: PMSL Quick Start

      Pick a route first. If you only want to call PMSL routines, use the user route. If you want to maintain or extend the library, use the developer route.

      .. raw:: html

         <div class="pmsl-onboarding-path" aria-label="Onboarding routes">
           <span>Pick a route</span>
           <span>Run one example</span>
           <span>Call one routine</span>
           <span>Then decide whether to develop</span>
         </div>

   .. container:: pmsl-onboarding-grid

      .. container:: pmsl-onboarding-step pmsl-onboarding-user

         .. rubric:: Route 1: Call PMSL Routines

         The goal is to use the library. Focus on getting the source tree,
         running one existing test, and calling one public subroutine from your
         own Fortran program.

         :doc:`Open User Quick Start <user_quick_start>`

      .. container:: pmsl-onboarding-step pmsl-onboarding-dev

         .. rubric:: Route 2: Develop PMSL

         The goal is to change the library safely. Focus on the directory
         layout, test locations, documentation entry points, first contributions,
         and pre-submit checks.

         :doc:`Open Developer Quick Start <developer_quick_start>`

   .. container:: pmsl-onboarding-done

      .. rubric:: Which Route To Choose

      - To call PMSL routines from your own code, use the user route.
      - To write documentation, add tests, change algorithms, or maintain modules, use the developer route.
      - Neither route requires understanding the full PIC workflow first.
