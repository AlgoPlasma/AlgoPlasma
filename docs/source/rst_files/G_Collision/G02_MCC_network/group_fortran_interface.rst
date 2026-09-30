.. rst-class:: ap-g02 ap-g02-reference

Fortran API
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - MCC（Monte Carlo Collision，蒙特卡洛碰撞）：用随机抽样决定碰撞何时发生、发生哪种反应，以及粒子怎样变化；大量粒子的统计应符合给定模型。
      - workspace（工作区）是反复使用的临时内存；session（会话）是 C/Fortran 接口持有这类工作状态的对象。跨时间步复用可减少分配，但同一对象不能同时处理两个调用。

   这些文件位于 fortran_interface/。模块文件通过 include 汇总子程序文件；编译模块文件即可，不要把被包含的文件再次单独编译。

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - 程序文件
        - 用途
      * - :doc:`mod_G02_MCC_network.f90 <mod_G02_MCC_network>`
        - MCC：Fortran 接口与整体架构
      * - :doc:`sub_G02_mcc_load.f90 <sub_G02_mcc_load>`
        - mcc_load：加载碰撞模型
      * - :doc:`sub_G02_mcc_model_queries.f90 <sub_G02_mcc_model_queries>`
        - 模型查询：物种、能级与反应
      * - :doc:`sub_G02_mcc_step.f90 <sub_G02_mcc_step>`
        - mcc_step：批量碰撞步进
      * - :doc:`sub_G02_mcc_collide.f90 <sub_G02_mcc_collide>`
        - mcc_collide：单粒子碰撞
      * - :doc:`sub_G02_mcc_session.f90 <sub_G02_mcc_session>`
        - 碰撞会话：创建与关闭工作区
      * - :doc:`sub_G02_mcc_cleanup.f90 <sub_G02_mcc_cleanup>`
        - 结果整理与资源释放
      * - :doc:`fun_G02_mcc_api_version.f90 <fun_G02_mcc_api_version>`
        - mcc_api_version：查询接口版本

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - MCC (Monte Carlo Collision) uses random draws to decide collision timing, reaction type and outcomes; ensemble statistics should follow the model.
      - A workspace is reusable scratch memory. A session holds this state for C/Fortran callers. Reuse reduces allocation, but one instance must not serve concurrent calls.

   These files live in fortran_interface/. Module files include the routine files; do not compile included files separately.

   .. list-table::
      :header-rows: 1
      :widths: 45 55

      * - Source file
        - Purpose
      * - :doc:`mod_G02_MCC_network.f90 <mod_G02_MCC_network>`
        - MCC: Fortran interface and architecture
      * - :doc:`sub_G02_mcc_load.f90 <sub_G02_mcc_load>`
        - mcc_load: load collision models
      * - :doc:`sub_G02_mcc_model_queries.f90 <sub_G02_mcc_model_queries>`
        - Model queries: species, states and reactions
      * - :doc:`sub_G02_mcc_step.f90 <sub_G02_mcc_step>`
        - mcc_step: batch collision stepping
      * - :doc:`sub_G02_mcc_collide.f90 <sub_G02_mcc_collide>`
        - mcc_collide: single-particle collisions
      * - :doc:`sub_G02_mcc_session.f90 <sub_G02_mcc_session>`
        - Collision sessions: create and close workspaces
      * - :doc:`sub_G02_mcc_cleanup.f90 <sub_G02_mcc_cleanup>`
        - Collect results and release resources
      * - :doc:`fun_G02_mcc_api_version.f90 <fun_G02_mcc_api_version>`
        - mcc_api_version: query the interface version

.. toctree::
   :maxdepth: 1
   :hidden:

   mod_G02_MCC_network.f90 <mod_G02_MCC_network>
   sub_G02_mcc_load.f90 <sub_G02_mcc_load>
   sub_G02_mcc_model_queries.f90 <sub_G02_mcc_model_queries>
   sub_G02_mcc_step.f90 <sub_G02_mcc_step>
   sub_G02_mcc_collide.f90 <sub_G02_mcc_collide>
   sub_G02_mcc_session.f90 <sub_G02_mcc_session>
   sub_G02_mcc_cleanup.f90 <sub_G02_mcc_cleanup>
   fun_G02_mcc_api_version.f90 <fun_G02_mcc_api_version>

:doc:`返回 G02 / Back to G02 <../G02_MCC_network>`
