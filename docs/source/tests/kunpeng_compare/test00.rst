D01_hypre_3Dxyz_omp Comparison
================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本页说明 ``tests/kunpeng_compare/D01_hypre_3Dxyz_omp`` 中的性能对比测试。
   该测试复用 D01 _hypre_3Dxyz_bc 基准，比较同一个 4-rank MPI
   主程序在鲲鹏 GCC、鲲鹏 BiSheng 和 AMD 服务器上的 HYPRE 求解时间与端到端耗时。

   这是平台 / 工具链性能对比，不是数值正确性回归测试。数值规模和 MPI 拆分固定为：

   - ``mpi_size = 4``
   - 全局网格 ``32 x 8 x 32``，总网格点数 ``6144``
   - HYPRE 求解容差 ``1.0e-6``
   - OpenMP 线程数 ``1,2,4,6,8,10,12,14,16,20,22,24,26,28,30,32,48,64``
   - 每个线程数重复 ``5`` 次

   .. rubric:: 实验维度

   .. list-table::
      :header-rows: 1
      :widths: 24 76

      * - 维度
        - 取值
      * - ``platform/toolchain``
        - Kunpeng ``gcc``、Kunpeng ``bisheng``、``AMD``
      * - ``np``
        - 固定为 ``4`` 个 MPI rank
      * - ``OMP_NUM_THREADS``
        - ``1,2,4,6,8,10,12,14,16,20,22,24,26,28,30,32,48,64``
      * - ``nrepeat``
        - ``5``，对每个 (platform/toolchain, thread) 组合取均值
      * - grid
        - ``32 x 8 x 32``，共 ``6144`` 个网格点
      * - solver tolerance
        - ``1.0e-6``

   计时区间拆成 HYPRE solve 核心和整程序 wall time 两部分。日志还保留
   ``gather_write_time``，用于判断端到端差异是否来自求解后的 gather/write 阶段。

   .. rubric:: 程序结构

   - ``main_time.f90``：4-rank Poisson 基准主程序，调用 ``sub_D01_hypre_3Dxyz_interface``，并输出时间与范数诊断。
   - ``make.sh``：鲲鹏侧构建入口，通过 ``TOOLCHAIN=gcc`` 或 ``TOOLCHAIN=bisheng`` 切换 HYPRE、MPI 和编译器包装器。
   - ``make_AMD.sh``：AMD 服务器本地 HYPRE 构建入口，生成 ``main.out``。
   - ``run_threads_gcc.sh``、``run_threads_bisheng.sh``：鲲鹏侧线程扫描入口，分别生成 ``run_gcc_np4_omp*_*.log`` 和 ``run_bisheng_np4_omp*_*.log``。
   - ``run_AMD.sh``：AMD 服务器线程扫描入口，生成 ``run_AMD_np4_omp*_*.log``。
   - ``plot-time.py``：解析三组日志，打印均值统计表，并生成 ``time_3compares_np4.png``。

   .. rubric:: 运行方式

   在鲲鹏上：

   .. code-block:: bash

      cd tests/kunpeng_compare/D01_hypre_3Dxyz_omp
      TOOLCHAIN=gcc bash make.sh
      bash run_threads_gcc.sh
      TOOLCHAIN=bisheng bash make.sh
      bash run_threads_bisheng.sh

   在 AMD 服务器上：

   .. code-block:: bash

      cd tests/kunpeng_compare/D01_hypre_3Dxyz_omp
      bash make_AMD.sh
      bash run_AMD.sh

   三组 log 齐了之后在任一台分析机上：

   .. code-block:: bash

      python3 plot-time.py

   ``plot-time.py`` 按文件名匹配 ``run_gcc_np4_omp*_*.log``、
   ``run_bisheng_np4_omp*_*.log`` 和 ``run_AMD_np4_omp*_*.log``。如果缺少某个平台的
   log，该平台曲线会被跳过。

   .. rubric:: 输出字段

   ``plot-time.py`` 输出表格中每行对应一个 (platform/toolchain, np, OMP thread)
   组合：

   .. list-table::
      :header-rows: 1
      :widths: 28 52

      * - 字段
        - 含义
      * - ``compiler``
        - ``gcc``、``bisheng`` 或 ``AMD``。
      * - ``np``
        - MPI rank 数，本测试固定为 ``4``。
      * - ``omp``
        - OpenMP 线程数。
      * - ``repeats``
        - 该点成功解析到的重复次数。
      * - ``hypre_avg(s)``
        - ``hypre_time_avg`` 的重复均值，单位秒。
      * - ``total_avg(s)``
        - ``total_time`` 的重复均值，单位秒。

   .. rubric:: 参考图

   .. figure:: ../../images/tests/kunpeng_compare/test00/time_3compares_np4.png
      :align: center
      :width: 62%

      ``np=4`` 时鲲鹏 GCC、鲲鹏 BiSheng 与 AMD 服务器的时间对比。
      虚线为 HYPRE solve 时间，实线为端到端总时间。

   .. rubric:: 参考结果

   最优均值统计：

   .. list-table::
      :header-rows: 1
      :widths: 18 18 24 24

      * - 数据组
        - 最优线程数
        - 最优 HYPRE 时间
        - 最优总时间
      * - Kunpeng GCC
        - ``OMP=32``
        - ``7.01989550e-03 s``
        - ``1.22567360e-02 s``
      * - Kunpeng BiSheng
        - ``OMP=10`` / ``OMP=12``
        - ``6.88668600e-03 s``
        - ``1.73678340e-02 s``
      * - AMD
        - ``OMP=12``
        - ``4.33449085e-03 s``
        - ``1.40202044e-02 s``

   要点总结：

   1. 三组环境的数值诊断一致，日志都给出 ``rho_l2=1.13137085e+01``、
      ``phi_l2=1.53428727e+01``、``phi_min=1.05795206e-04``、
      ``phi_max=4.88507716e-01``，说明当前对比没有数值漂移。
   2. AMD 的 HYPRE solve 时间最低，最佳均值为 ``4.334e-03 s``；鲲鹏 BiSheng
      和鲲鹏 GCC 的最佳 HYPRE 均值分别为 ``6.887e-03 s`` 和 ``7.020e-03 s``。
   3. 端到端总时间仍是鲲鹏 GCC 最低，最佳均值为 ``1.226e-02 s``；AMD
      最佳均值为 ``1.402e-02 s``，约为 GCC 的 ``1.14x``；BiSheng 最佳均值为
      ``1.737e-02 s``，约为 GCC 的 ``1.42x``。
   4. 代表性日志显示，``gather_write_time`` 在鲲鹏 GCC 上约为 ``5.2e-03 s``，
      在 AMD 上约为 ``9.6e-03 s``，在鲲鹏 BiSheng 上约为 ``1.03e-02 s``。
      因此当前端到端差异主要来自求解后的 gather/write 等阶段，而不是 HYPRE solve 核心。

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This page documents the performance comparison under
   ``tests/kunpeng_compare/D01_hypre_3Dxyz_omp``. The case reuses the D01
   _hypre_3Dxyz_bc benchmark and compares the same 4-rank MPI
   program on Kunpeng GCC, Kunpeng BiSheng, and the AMD server.

   This is a platform / toolchain performance comparison, not a numerical
   correctness regression test. The fixed workload is:

   - ``mpi_size = 4``
   - global grid ``32 x 8 x 32`` with ``6144`` total cells
   - HYPRE solver tolerance ``1.0e-6``
   - OpenMP threads ``1,2,4,6,8,10,12,14,16,20,22,24,26,28,30,32,48,64``
   - ``5`` repeats per thread count

   .. rubric:: Sweep Axes

   .. list-table::
      :header-rows: 1
      :widths: 24 76

      * - Axis
        - Values
      * - ``platform/toolchain``
        - Kunpeng ``gcc``, Kunpeng ``bisheng``, ``AMD``
      * - ``np``
        - fixed at ``4`` MPI ranks
      * - ``OMP_NUM_THREADS``
        - ``1,2,4,6,8,10,12,14,16,20,22,24,26,28,30,32,48,64``
      * - ``nrepeat``
        - ``5``; means are computed per (platform/toolchain, thread) point
      * - grid
        - ``32 x 8 x 32`` with ``6144`` cells
      * - solver tolerance
        - ``1.0e-6``

   The timing is split into the HYPRE solve kernel and the end-to-end wall
   time. Logs also keep ``gather_write_time`` so the post-solve overhead can be
   separated from the solver cost.

   .. rubric:: Program Structure

   - ``main_time.f90``: 4-rank Poisson benchmark that calls ``sub_D01_hypre_3Dxyz_interface`` and prints timing plus norm diagnostics.
   - ``make.sh``: Kunpeng build entry point; ``TOOLCHAIN=gcc`` or ``TOOLCHAIN=bisheng`` selects HYPRE, MPI, and compiler wrappers.
   - ``make_AMD.sh``: AMD local HYPRE build entry point, producing ``main.out``.
   - ``run_threads_gcc.sh`` and ``run_threads_bisheng.sh``: Kunpeng thread sweeps, writing ``run_gcc_np4_omp*_*.log`` and ``run_bisheng_np4_omp*_*.log``.
   - ``run_AMD.sh``: AMD thread sweep, writing ``run_AMD_np4_omp*_*.log``.
   - ``plot-time.py``: parses the three log groups, prints mean statistics, and writes ``time_3compares_np4.png``.

   .. rubric:: Run Command

   On Kunpeng:

   .. code-block:: bash

      cd tests/kunpeng_compare/D01_hypre_3Dxyz_omp
      TOOLCHAIN=gcc bash make.sh
      bash run_threads_gcc.sh
      TOOLCHAIN=bisheng bash make.sh
      bash run_threads_bisheng.sh

   On the AMD server:

   .. code-block:: bash

      cd tests/kunpeng_compare/D01_hypre_3Dxyz_omp
      bash make_AMD.sh
      bash run_AMD.sh

   Once all three log groups are present on the analysis machine:

   .. code-block:: bash

      python3 plot-time.py

   ``plot-time.py`` matches ``run_gcc_np4_omp*_*.log``,
   ``run_bisheng_np4_omp*_*.log``, and ``run_AMD_np4_omp*_*.log`` by filename.
   Missing platforms are skipped in the figure.

   .. rubric:: Output Fields

   Each row printed by ``plot-time.py`` is one (platform/toolchain, np, OpenMP
   thread) point.

   .. list-table::
      :header-rows: 1
      :widths: 28 52

      * - Field
        - Meaning
      * - ``compiler``
        - ``gcc``, ``bisheng``, or ``AMD``.
      * - ``np``
        - MPI rank count, fixed at ``4`` in this test.
      * - ``omp``
        - OpenMP thread count.
      * - ``repeats``
        - Number of successfully parsed repeats for this point.
      * - ``hypre_avg(s)``
        - Mean ``hypre_time_avg`` across repeats, in seconds.
      * - ``total_avg(s)``
        - Mean ``total_time`` across repeats, in seconds.

   .. rubric:: Reference Figure

   .. figure:: ../../images/tests/kunpeng_compare/test00/time_3compares_np4.png
      :align: center
      :width: 62%

      Timing comparison for Kunpeng GCC, Kunpeng BiSheng, and AMD at ``np=4``.
      Dashed lines show HYPRE solve time; solid lines show end-to-end total time.

   .. rubric:: Reference Result

   Best mean timings:

   .. list-table::
      :header-rows: 1
      :widths: 18 18 24 24

      * - Data group
        - Best thread count
        - Best HYPRE time
        - Best total time
      * - Kunpeng GCC
        - ``OMP=32``
        - ``7.01989550e-03 s``
        - ``1.22567360e-02 s``
      * - Kunpeng BiSheng
        - ``OMP=10`` / ``OMP=12``
        - ``6.88668600e-03 s``
        - ``1.73678340e-02 s``
      * - AMD
        - ``OMP=12``
        - ``4.33449085e-03 s``
        - ``1.40202044e-02 s``

   Summary:

   1. The numerical diagnostics match across all three data groups:
      ``rho_l2=1.13137085e+01``, ``phi_l2=1.53428727e+01``,
      ``phi_min=1.05795206e-04``, and ``phi_max=4.88507716e-01``.
   2. AMD has the lowest HYPRE solve time, with a best mean of ``4.334e-03 s``.
      The best Kunpeng BiSheng and Kunpeng GCC HYPRE means are ``6.887e-03 s``
      and ``7.020e-03 s``.
   3. End-to-end total time is still lowest for Kunpeng GCC, with a best mean
      of ``1.226e-02 s``. AMD reaches ``1.402e-02 s``, about ``1.14x`` the GCC
      value; BiSheng reaches ``1.737e-02 s``, about ``1.42x`` the GCC value.
   4. Representative logs show ``gather_write_time`` around ``5.2e-03 s`` on
      Kunpeng GCC, around ``9.6e-03 s`` on AMD, and around ``1.03e-02 s`` on
      Kunpeng BiSheng. The current end-to-end gap therefore mainly comes from
      post-solve gather/write overhead rather than the HYPRE solve kernel.
