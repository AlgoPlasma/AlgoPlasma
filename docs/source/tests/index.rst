Tests
=====

.. toctree::
   :maxdepth: 2
   :hidden:

   001_poisson/index
   002_pusher/index
   003_F_IO/index
   004_scatter/index
   005_maxwell/index
   006_initializer/index
   007_gather/index
   008_mpi_exchange/index
   009_collision/index
   kunpeng_compare/index

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试入口

   本页按 ``tests/`` 顶层目录名排序，作为测试文档的主入口。每个测试页说明对应目录的运行方式、
   输出文件、结果判断方式，并反向链接到相关算法/API 页面。

   .. list-table:: 测试目录总览
      :header-rows: 1
      :widths: 18 34 24 34

      * - 目录
        - 说明
        - 相关模块
        - 文档入口
      * - ``001_poisson``
        - Poisson 边界条件、MPI、均匀/非均匀网格测试。
        - :doc:`D_Poisson </rst_files/D_Poisson>`
        - :doc:`001_poisson 测试总览 <001_poisson/index>`
      * - ``002_pusher``
        - A_Pusher 的粒子推进器参考测试。
        - :doc:`A_Pusher </rst_files/A_Pusher>`
        - :doc:`002_pusher 测试总览 <002_pusher/index>`
      * - ``003_F_IO``
        - F_IO 粒子和场数据读写回归测试。
        - :doc:`F_IO </rst_files/F_IO>`
        - :doc:`003_F_IO 测试总览 <003_F_IO/index>`
      * - ``004_scatter``
        - B_Scatter 的 Cartesian scatter 和 cylindrical deposition 测试脚本。
        - :doc:`B_Scatter </rst_files/B_Scatter>`
        - :doc:`004_scatter 测试总览 <004_scatter/index>`
      * - ``005_maxwell``
        - Maxwell/FDTD 公式、稳定性、MMS、CPML wave-packet 和可视化测试。
        - :doc:`E_Maxwell </rst_files/E_Maxwell>`
        - :doc:`005_maxwell 测试总览 <005_maxwell/index>`
      * - ``006_initializer``
        - I_Initializer 粒子初始化单元测试：均匀空间分布和 Maxwell 速度采样验证。
        - :doc:`I_Initializer </rst_files/I_Initializer>`
        - :doc:`006_initializer 测试总览 <006_initializer/index>`
      * - ``007_gather``
        - C_Gather 三线性 gather 和 B-spline 权重测试。
        - :doc:`C_Gather </rst_files/C_Gather>`
        - :doc:`007_gather 测试总览 <007_gather/index>`
      * - ``008_mpi_exchange``
        - H_MPI_Exchange 的 4-rank 小算例 MPI 回归测试。
        - :doc:`H_MPI_Exchange </rst_files/H_MPI_Exchange>`
        - :doc:`008_mpi_exchange 测试总览 <008_mpi_exchange/index>`
      * - ``009_collision``
        - G_Collision 截面表加载器的数组边界回归测试。
        - :doc:`G_Collision </rst_files/G_Collision>`
        - :doc:`009_collision 测试总览 <009_collision/index>`
      * - ``kunpeng_compare``
        - 鲲鹏相关的平台/编译器性能对比测试。
        - :doc:`A_Pusher </rst_files/A_Pusher>`
        - :doc:`kunpeng_compare 测试总览 <kunpeng_compare/index>`

   .. rubric:: 覆盖状态说明

   ``G_Collision`` 当前由 ``tests/009_collision`` 覆盖截面表加载器的数组边界行为，
   尚不包含完整 MCC 物理验证。``J_Fluid`` 尚无独立的顶层 ``tests/`` 回归目录；
   ``H_MPI_Exchange`` 已由 ``tests/008_mpi_exchange`` 覆盖。

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Entry Points

   This page is the main entry point for test documentation, ordered by the
   top-level directory names under ``tests/``. Each test page explains how to
   run the directory, what files it writes, how to interpret results, and links
   back to the relevant algorithm/API pages.

   .. list-table:: Test Directory Overview
      :header-rows: 1
      :widths: 18 34 24 34

      * - Directory
        - Notes
        - Related module
        - Documentation
      * - ``001_poisson``
        - Poisson boundary-condition, MPI, and uniform/nonuniform grid tests.
        - :doc:`D_Poisson </rst_files/D_Poisson>`
        - :doc:`001_poisson test overview <001_poisson/index>`
      * - ``002_pusher``
        - Particle-pusher reference tests for A_Pusher.
        - :doc:`A_Pusher </rst_files/A_Pusher>`
        - :doc:`002_pusher test overview <002_pusher/index>`
      * - ``003_F_IO``
        - F_IO particle and field I/O regression tests.
        - :doc:`F_IO </rst_files/F_IO>`
        - :doc:`003_F_IO test overview <003_F_IO/index>`
      * - ``004_scatter``
        - B_Scatter Cartesian scatter and cylindrical deposition test scripts.
        - :doc:`B_Scatter </rst_files/B_Scatter>`
        - :doc:`004_scatter test overview <004_scatter/index>`
      * - ``005_maxwell``
        - Maxwell/FDTD formula, stability, MMS, CPML wave-packet, and visualization tests.
        - :doc:`E_Maxwell </rst_files/E_Maxwell>`
        - :doc:`005_maxwell test overview <005_maxwell/index>`
      * - ``006_initializer``
        - I_Initializer particle initialization unit tests: uniform spatial
          distribution and Maxwellian velocity sampling.
        - :doc:`I_Initializer </rst_files/I_Initializer>`
        - :doc:`006_initializer test overview <006_initializer/index>`
      * - ``007_gather``
        - C_Gather trilinear gather and B-spline weight tests.
        - :doc:`C_Gather </rst_files/C_Gather>`
        - :doc:`007_gather test overview <007_gather/index>`
      * - ``008_mpi_exchange``
        - 4-rank small-case MPI regression tests for H_MPI_Exchange.
        - :doc:`H_MPI_Exchange </rst_files/H_MPI_Exchange>`
        - :doc:`008_mpi_exchange test overview <008_mpi_exchange/index>`
      * - ``009_collision``
        - Array-bound regression tests for the G_Collision cross-section loader.
        - :doc:`G_Collision </rst_files/G_Collision>`
        - :doc:`009_collision test overview <009_collision/index>`
      * - ``kunpeng_compare``
        - Kunpeng-related platform and compiler performance comparisons.
        - :doc:`A_Pusher </rst_files/A_Pusher>`
        - :doc:`kunpeng_compare test overview <kunpeng_compare/index>`

   .. rubric:: Coverage Notes

   ``G_Collision`` currently has array-bound coverage for its cross-section
   loader under ``tests/009_collision``; this is not a complete MCC physics
   validation. ``J_Fluid`` has no standalone top-level regression directory.
   ``H_MPI_Exchange`` is covered by ``tests/008_mpi_exchange``.
