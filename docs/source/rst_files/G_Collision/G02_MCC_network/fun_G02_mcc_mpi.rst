.. rst-class:: ap-g02 ap-g02-reference

fun_G02_mcc_mpi.cpp：协调多进程推进与新粒子编号
================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 这个文件做什么

   先准备各进程的本地碰撞，再协调错误状态和新粒子 ID，全部准备好才提交粒子修改。构造时复制通信器，析构时释放；主程序仍负责 MPI 的初始化和结束。MPI 需提供至少 MPI_THREAD_FUNNELED 的线程支持。

   .. rubric:: 主要类型与入口

   .. code-block:: text

      DistributedMccStepper::step; agree; allocate_child_ids

   上面列出的是入口名称，具体参数以源码声明为准。

.. container:: ap-lang ap-lang-en

   .. rubric:: What this file does

   Prepares local collisions, coordinates failures and child-ID allocation, then commits particle changes. Owns a duplicate communicator; the host owns MPI initialization and finalization. Requires at least MPI_THREAD_FUNNELED.

   .. rubric:: Main types and entry points

   .. code-block:: text

      DistributedMccStepper::step; agree; allocate_child_ids

   The names above are an interface index; consult the source declarations for exact parameters.

.. rubric:: 源码 / Source

:download:`fun_G02_mcc_mpi.cpp <../../../../../G_Collision/G02_MCC_network/fun_G02_mcc_mpi.cpp>`


.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fun_G02_mcc_mpi.cpp``

:doc:`MPI <group_mpi_interface>`
