Kunpeng Comparison Tests
========================

.. toctree::
   :maxdepth: 1
   :hidden:

   A01_Boris_3Dxyz_omp
   B01_scatter_3Dxyz_omp
   E_Maxwell_E03_fdtd_3d_cartesian
   D01_hypre_3Dxyz_Comparison

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试入口

   本页收集鲲鹏相关的性能对比测试，包括平台对比和编译器工具链对比。目录中保留原始测试
   主程序、运行日志、Python 后处理脚本和对比图。

   .. list-table:: 鲲鹏对比测试
      :header-rows: 1
      :widths: 28 44 28

      * - 目录
        - 说明
        - 文档入口
      * - ``A01_Boris_3Dxyz_omp``
        - A01 Boris pusher 的 OpenMP 并行性能对比：AMD 服务器 vs 鲲鹏服务器。
        - :doc:`A01_Boris_3Dxyz_omp <A01_Boris_3Dxyz_omp>`
      * - ``B01_scatter_3Dxyz_omp``
        - B01 Cartesian scatter 的 OpenMP 扩展性对比：``np`` × ``nthread`` 二维扫描，重点观察 ``firstprivate`` + ``reduction`` 开销。
        - :doc:`B01_scatter_3Dxyz_omp <B01_scatter_3Dxyz_omp>`
      * - ``E_Maxwell/E03_fdtd_3d_cartesian``
        - E03 3D Cartesian Maxwell/FDTD 场更新 kernel 的 AMD、鲲鹏、毕昇和 ompdo 对比。
        - :doc:`E_Maxwell_E03_fdtd_3d_cartesian <E_Maxwell_E03_fdtd_3d_cartesian>`
      * - ``D01_hypre_3Dxyz``
        - D01 Poisson/HYPRE 的 OpenMP 线程扫描和 MPI rank 扫描：鲲鹏 GCC、鲲鹏 BiSheng 与 AMD 服务器。
        - :doc:`D01_hypre_3Dxyz Comparison <D01_hypre_3Dxyz_Comparison>`

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Entry Points

   This page collects Kunpeng-related performance comparisons, including both
   cross-platform and cross-toolchain cases. Each case keeps the original
   benchmark program, raw logs, Python post-processing scripts, and comparison
   figures.

   .. list-table:: Kunpeng Comparison Tests
      :header-rows: 1
      :widths: 28 44 28

      * - Directory
        - Notes
        - Documentation
      * - ``A01_Boris_3Dxyz_omp``
        - OpenMP performance comparison for the A01 Boris pusher: AMD server vs Kunpeng server.
        - :doc:`A01_Boris_3Dxyz_omp <A01_Boris_3Dxyz_omp>`
      * - ``B01_scatter_3Dxyz_omp``
        - OpenMP scalability comparison for the B01 Cartesian scatter kernel: joint ``np`` × ``nthread`` sweep highlighting ``firstprivate`` + ``reduction`` overhead.
        - :doc:`B01_scatter_3Dxyz_omp <B01_scatter_3Dxyz_omp>`
      * - ``E_Maxwell/E03_fdtd_3d_cartesian``
        - AMD, Kunpeng, BiSheng, and ompdo comparison for the E03 3D Cartesian Maxwell/FDTD field-update kernel.
        - :doc:`E_Maxwell_E03_fdtd_3d_cartesian <E_Maxwell_E03_fdtd_3d_cartesian>`
      * - ``D01_hypre_3Dxyz``
        - OpenMP-thread and MPI-rank D01 Poisson/HYPRE comparison for Kunpeng GCC, Kunpeng BiSheng, and AMD.
        - :doc:`D01_hypre_3Dxyz Comparison <D01_hypre_3Dxyz_Comparison>`
