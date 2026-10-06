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
   010_diagnostics/index
   011_K04_breathing_waveform/index
   012_fluid/index
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
        - C01 三线性、C02 B-spline，以及 :doc:`C03 非均匀柱坐标 gather <007_gather/C03_gather_3Draz_nonuniform>` 测试。
        - :doc:`C_Gather </rst_files/C_Gather>`
        - :doc:`007_gather 测试总览 <007_gather/index>`
      * - ``008_mpi_exchange``
        - H_MPI_Exchange 的 4-rank 小算例 MPI 回归测试。
        - :doc:`H_MPI_Exchange </rst_files/H_MPI_Exchange>`
        - :doc:`008_mpi_exchange 测试总览 <008_mpi_exchange/index>`
      * - ``009_collision``
        - G01 截面表加载器回归，以及 G02 碰撞网络和零维碰撞盒验证。
        - :doc:`G_Collision </rst_files/G_Collision>`
        - :doc:`009_collision 测试总览 <009_collision/index>`
      * - ``010_diagnostics``
        - K_Diagnostics 基础数值测试与合成宽带链路测试。
        - :doc:`K_Diagnostics </rst_files/K_Diagnostics>`
        - :doc:`010_diagnostics 测试总览 <010_diagnostics/index>`
      * - ``011_K04_breathing_waveform``
        - 呼吸波形提取的本地测试、人工示例、画图和清理。
        - :doc:`K04 </rst_files/K_Diagnostics/K04_breathing_waveform>`
        - :doc:`011_K04 测试说明 <011_K04_breathing_waveform/index>`
      * - ``012_fluid``
        - J01 自由分子历史、J02 SN P1-DG 和 J03 面通量连续性方程测试。
        - :doc:`J_Fluid </rst_files/J_Fluid>`
        - :doc:`012_fluid 测试总览 <012_fluid/index>`
      * - ``kunpeng_compare``
        - 鲲鹏相关的平台/编译器性能对比测试。
        - :doc:`A_Pusher </rst_files/A_Pusher>`
        - :doc:`kunpeng_compare 测试总览 <kunpeng_compare/index>`

   .. rubric:: 覆盖状态说明

   ``G_Collision`` 的 G01 测试覆盖截面表加载器边界；G02 测试覆盖算法、统计和零维碰撞盒，
   使用合成数据。``tests/012_fluid`` 覆盖 J01 单步/自由分子历史、
   J02 求积、离散算子、反射边界及并行一致性，以及 J03 瞬态推进和稳态求解。
   应用测试页记录 FM B0、SN B0、SN ION 前处理与各自的 J03 结果。
   ``K_Diagnostics`` 的 K01–K03 由 ``tests/010_diagnostics``、K04 由 ``tests/011_K04_breathing_waveform`` 覆盖；
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
        - C01 trilinear, C02 B-spline, and :doc:`C03 nonuniform cylindrical gather <007_gather/C03_gather_3Draz_nonuniform>` tests.
        - :doc:`C_Gather </rst_files/C_Gather>`
        - :doc:`007_gather test overview <007_gather/index>`
      * - ``008_mpi_exchange``
        - 4-rank small-case MPI regression tests for H_MPI_Exchange.
        - :doc:`H_MPI_Exchange </rst_files/H_MPI_Exchange>`
        - :doc:`008_mpi_exchange test overview <008_mpi_exchange/index>`
      * - ``009_collision``
        - G01 cross-section loader regressions plus G02 collision-network and zero-dimensional collision-box validation.
        - :doc:`G_Collision </rst_files/G_Collision>`
        - :doc:`009_collision test overview <009_collision/index>`
      * - ``010_diagnostics``
        - basic_numerical tests and a synthetic broadband chain test for K_Diagnostics.
        - :doc:`K_Diagnostics </rst_files/K_Diagnostics>`
        - :doc:`010_diagnostics test overview <010_diagnostics/index>`
      * - ``011_K04_breathing_waveform``
        - Local waveform-extraction tests, artificial examples, plotting and cleanup.
        - :doc:`K04 </rst_files/K_Diagnostics/K04_breathing_waveform>`
        - :doc:`011_K04 test guide <011_K04_breathing_waveform/index>`
      * - ``012_fluid``
        - J01 free-molecular histories, J02 SN P1-DG, and J03 face-flux continuity tests.
        - :doc:`J_Fluid </rst_files/J_Fluid>`
        - :doc:`012_fluid test overview <012_fluid/index>`
      * - ``kunpeng_compare``
        - Kunpeng-related platform and compiler performance comparisons.
        - :doc:`A_Pusher </rst_files/A_Pusher>`
        - :doc:`kunpeng_compare test overview <kunpeng_compare/index>`

   .. rubric:: Coverage Notes

   ``G_Collision`` has G01 loader-boundary tests and G02 algorithm, statistical
   and zero-dimensional collision-box tests using synthetic data.
   ``tests/012_fluid`` covers the J01 legacy/FM paths, J02 quadrature/DG/reflection
   and parallel consistency, plus J03 transient and steady solvers.
   The application page reports FM B0, SN B0 and SN ION preprocessing runs
   and their respective J03 solutions.
   K01–K03 are covered by ``tests/010_diagnostics``; K04 is covered by ``tests/011_K04_breathing_waveform``.
   ``H_MPI_Exchange`` is covered by ``tests/008_mpi_exchange``.
