D01_hypre_3Dxyz_omp Comparison
================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-kunpeng-compare

   .. note:: 快速结论

      这组固定小网格测试在 1–64 个 OpenMP 线程之间几乎没有有效加速：三组
      HYPRE 曲线和总时间曲线都接近水平。AMD 的 HYPRE solve 最快，但鲲鹏 GCC
      的端到端总时间最低；差别主要来自 solve 之后的 gather/write 阶段。
      因此本页更适合分析“时间花在哪里”，不适合证明高线程扩展能力。

   .. rubric:: 测试对象与比较口径

   本页说明 ``tests/kunpeng_compare/D01_hypre_3Dxyz_omp`` 中的性能对比测试。
   测试复用 D01 ``hypre_3Dxyz_bc`` 基准，让同一个 4-rank MPI 主程序分别使用
   鲲鹏 GCC、鲲鹏 BiSheng 和 AMD 环境，比较 HYPRE 求解时间与端到端 wall time。

   这里的 ``np=4`` 表示 **4 个 MPI rank**，不是粒子数。每个 rank 内再设置
   ``OMP_NUM_THREADS``，因此这是 MPI + OpenMP 的混合并行扫描。

   .. list-table:: 固定测试规模
      :header-rows: 1
      :widths: 26 74

      * - 项目
        - 取值
      * - MPI rank
        - ``mpi_size = 4``
      * - 全局网格
        - ``32 x 8 x 32``，共 ``6144`` 个网格点
      * - HYPRE 容差
        - ``1.0e-6``
      * - OpenMP 线程
        - ``1,2,4,6,8,10,12,14,16,20,22,24,26,28,30,32,48,64``
      * - 重复次数
        - 每个 (平台/工具链, 线程数) 重复 ``5`` 次并取均值

   这是平台/工具链性能对比，不是数值正确性回归测试。计时拆成两个层次：

   - ``hypre_time_avg``：HYPRE solve 核心时间；
   - ``total_time``：包含求解前后处理的端到端总时间。

   日志还保留 ``gather_write_time``，用于判断 solve 之后的 gather/write 是否造成差异。

   .. rubric:: 读图方法

   横轴是 **每个 MPI rank 使用的 OpenMP 线程数**，纵轴是秒，越低越快。
   同一种颜色代表一个平台/工具链：

   - 虚线是 HYPRE solve 时间；
   - 实线是端到端总时间；
   - 同色实线与虚线之间的垂直距离，近似表示求解之外的时间；
   - 曲线向下才表示增加线程带来加速；接近水平表示线程增加但时间几乎不变。

   点击图片可查看原始尺寸。

   .. figure:: ../../images/tests/kunpeng_compare/test00/time_3compares_np4.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide
      :target: ../../_images/time_3compares_np4.png

      ``np=4`` 时鲲鹏 GCC、鲲鹏 BiSheng 与 AMD 的时间对比。虚线为 HYPRE solve，
      实线为端到端总时间；同一颜色的两条线应配对阅读。

   .. rubric:: 先看几个代表结果

   .. list-table:: 各配置的最佳重复均值
      :header-rows: 1
      :widths: 20 20 28 32

      * - 数据组
        - 最佳线程数
        - 最佳 HYPRE 时间
        - 最佳总时间
      * - 鲲鹏 GCC
        - ``OMP=32``
        - ``7.01989550e-03 s``
        - ``1.22567360e-02 s``
      * - 鲲鹏 BiSheng
        - ``OMP=10`` / ``OMP=12``
        - ``6.88668600e-03 s``
        - ``1.73678340e-02 s``
      * - AMD
        - ``OMP=12``
        - ``4.33449085e-03 s``
        - ``1.40202044e-02 s``

   AMD 的最佳 HYPRE 时间比两组鲲鹏结果低；但端到端总时间最短的是鲲鹏 GCC。
   这不是矛盾：图中 AMD 虚线最低，而鲲鹏 GCC 的实线与虚线间距最小，说明两个阶段
   的平台排序不同。

   代表性日志给出的 ``gather_write_time`` 约为：鲲鹏 GCC ``5.2e-03 s``、
   AMD ``9.6e-03 s``、鲲鹏 BiSheng ``1.03e-02 s``。因此当前端到端差异主要来自
   solve 之后的 gather/write 等阶段，而不是 HYPRE solve 本身。

   .. rubric:: 再看整体并行效果

   - 从 1 到 64 线程，三组 HYPRE 虚线都只在很窄范围内波动，没有随线程数持续下降；
     这表示当前小问题没有获得有意义的 OpenMP 扩展。
   - 三条总时间实线也近乎水平。最佳线程点只比相邻点略低，不应把某一个最低点解读为
     稳定的最优线程数。
   - 增加线程没有改变三组配置的主要排序：AMD solve 较快，鲲鹏 GCC 的非 solve
     开销较小，鲲鹏 BiSheng 总时间最高。

   .. rubric:: 可能原因与结论边界

   当前曲线与以下原因相符，但现有日志不能把它们逐项分离：

   - 全局只有 6144 个网格点，平均每个 MPI rank 约 1536 点；线程增加后，每个线程
     可分到的有效工作迅速变少，固定调度和同步开销可能占主导；
   - 运行脚本使用 ``mpirun --bind-to none``，且没有设置 ``OMP_PROC_BIND`` 和
     ``OMP_PLACES``；rank 与线程都未固定到核心，可能增加点间波动；
   - 4 个 rank × 64 线程意味着最多 256 个 OpenMP 线程参与同一作业，若超过有效物理核，
     还会出现过度订阅或资源争用；
   - HYPRE、MPI、编译器和运行库同时随配置变化，所以本页比较的是完整软件栈，不是
     单独的编译器变量。

   要验证扩展性，应增加网格规模，固定 rank/线程绑定，记录 CPU/NUMA 拓扑，并分别扫描
   MPI rank 与 OpenMP 线程数。本页数据只能支持“此固定小算例没有明显线程加速”。

   .. rubric:: 数值一致性

   三组环境的日志都给出 ``rho_l2=1.13137085e+01``、
   ``phi_l2=1.53428727e+01``、``phi_min=1.05795206e-04`` 和
   ``phi_max=4.88507716e-01``。这些诊断一致，说明当前性能对比没有伴随可见数值漂移。

   .. rubric:: 复现方法与数据字段

   程序结构：

   - ``main_time.f90``：4-rank Poisson 基准，调用 ``sub_D01_hypre_3Dxyz_interface`` 并输出计时和范数；
   - ``make.sh``：鲲鹏构建入口，以 ``TOOLCHAIN=gcc`` 或 ``TOOLCHAIN=bisheng`` 切换工具链；
   - ``make_AMD.sh``：AMD 本地 HYPRE 构建入口；
   - ``run_threads_gcc.sh`` / ``run_threads_bisheng.sh`` / ``run_AMD.sh``：三组线程扫描；
   - ``plot-time.py``：解析日志、打印均值并生成 ``time_3compares_np4.png``。

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

   三组日志齐全后：

   .. code-block:: bash

      python3 plot-time.py

   ``plot-time.py`` 匹配 ``run_gcc_np4_omp*_*.log``、
   ``run_bisheng_np4_omp*_*.log`` 和 ``run_AMD_np4_omp*_*.log``；缺少某个平台时，
   该平台曲线会被跳过。

   .. list-table:: 输出字段
      :header-rows: 1
      :widths: 28 52

      * - 字段
        - 含义
      * - ``compiler``
        - ``gcc``、``bisheng`` 或 ``AMD``。
      * - ``np`` / ``omp``
        - MPI rank 数（本测试为 4）和每个 rank 的 OpenMP 线程数。
      * - ``repeats``
        - 该点成功解析的重复次数。
      * - ``hypre_avg(s)``
        - ``hypre_time_avg`` 的重复均值。
      * - ``total_avg(s)``
        - ``total_time`` 的重复均值。

.. container:: ap-lang ap-lang-en ap-kunpeng-compare

   .. note:: Quick take

      This fixed small-grid case shows almost no useful speedup from 1 through
      64 OpenMP threads: all HYPRE and total-time curves are nearly flat. AMD
      has the fastest HYPRE solve, while Kunpeng GCC has the lowest end-to-end
      time because post-solve gather/write cost is smaller. The page therefore
      explains where time is spent; it does not demonstrate high-thread scaling.

   .. rubric:: What Is Compared

   This page documents ``tests/kunpeng_compare/D01_hypre_3Dxyz_omp``. The D01
   ``hypre_3Dxyz_bc`` benchmark runs as the same four-rank MPI program under
   Kunpeng GCC, Kunpeng BiSheng, and AMD environments. We compare the HYPRE
   solve with end-to-end wall time.

   Here ``np=4`` means **four MPI ranks**, not a particle count. Each rank also
   receives ``OMP_NUM_THREADS``, making this a hybrid MPI + OpenMP sweep.

   .. list-table:: Fixed problem
      :header-rows: 1
      :widths: 26 74

      * - Item
        - Value
      * - MPI ranks
        - ``mpi_size = 4``
      * - Global grid
        - ``32 x 8 x 32`` with ``6144`` grid points
      * - HYPRE tolerance
        - ``1.0e-6``
      * - OpenMP threads
        - ``1,2,4,6,8,10,12,14,16,20,22,24,26,28,30,32,48,64``
      * - Repeats
        - ``5`` means per (platform/toolchain, thread) point

   This is a platform/toolchain comparison, not a numerical-regression test.
   Timing is split into:

   - ``hypre_time_avg``: the HYPRE solve kernel;
   - ``total_time``: end-to-end execution including surrounding work.

   Logs also retain ``gather_write_time`` to diagnose post-solve cost.

   .. rubric:: How to Read the Figure

   The x-axis is the OpenMP thread count **per MPI rank**; the y-axis is seconds,
   so lower is better. Each color is one platform/toolchain:

   - dashed lines are HYPRE solve time;
   - solid lines are end-to-end total time;
   - the vertical gap between a same-color pair approximates non-solver time;
   - falling curves indicate speedup, while flat curves indicate little change.

   Click the figure to open it at original size.

   .. figure:: ../../images/tests/kunpeng_compare/test00/time_3compares_np4.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide
      :target: ../../_images/time_3compares_np4.png

      Kunpeng GCC, Kunpeng BiSheng, and AMD at ``np=4``. Dashed lines show
      HYPRE solve time; solid lines show end-to-end total time.

   .. rubric:: Representative Results

   .. list-table:: Best repeat means per configuration
      :header-rows: 1
      :widths: 20 20 28 32

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

   AMD has the lowest HYPRE time, but Kunpeng GCC has the lowest end-to-end
   time. This is not contradictory: AMD's dashed curve is lowest, while Kunpeng
   GCC has the smallest gap between its dashed and solid curves.

   Representative ``gather_write_time`` values are about ``5.2e-03 s`` for
   Kunpeng GCC, ``9.6e-03 s`` for AMD, and ``1.03e-02 s`` for Kunpeng BiSheng.
   The current end-to-end difference therefore comes mainly from post-solve
   gather/write work rather than HYPRE solve time.

   .. rubric:: Overall Parallel Behavior

   - From 1 through 64 threads, all three HYPRE curves fluctuate in a narrow
     band rather than decreasing steadily; the small case gains no meaningful
     OpenMP scaling.
   - Total-time curves are also nearly flat. A slightly lower individual point
     should not be interpreted as a stable optimum.
   - Added threads do not change the main ranking: AMD solves faster, Kunpeng
     GCC has lower non-solver overhead, and Kunpeng BiSheng has the highest total time.

   .. rubric:: Possible Causes and Limits

   The curves are consistent with the following causes, but the current logs do
   not isolate them:

   - the global problem has only 6144 points, roughly 1536 per MPI rank, so work
     per OpenMP thread rapidly becomes too small to cover scheduling and synchronization;
   - scripts use ``mpirun --bind-to none`` and set no ``OMP_PROC_BIND`` or
     ``OMP_PLACES``, leaving both ranks and threads unpinned;
   - four ranks times 64 threads can create 256 OpenMP threads, potentially
     oversubscribing useful physical cores or contending for resources;
   - HYPRE, MPI, compiler, and runtime vary together, so each curve represents a
     complete software stack rather than a compiler-only variable.

   A scaling study should increase the grid, pin ranks and threads, record CPU
   and NUMA topology, and sweep MPI ranks separately from OpenMP threads. These
   data support only the conclusion that this fixed small case does not scale.

   .. rubric:: Numerical Consistency

   All three environments report ``rho_l2=1.13137085e+01``,
   ``phi_l2=1.53428727e+01``, ``phi_min=1.05795206e-04``, and
   ``phi_max=4.88507716e-01``. Matching diagnostics show no visible numerical
   drift in the current performance comparison.

   .. rubric:: Reproduction and Output Fields

   Program structure:

   - ``main_time.f90``: four-rank Poisson benchmark with timing and norm diagnostics;
   - ``make.sh``: Kunpeng build entry using ``TOOLCHAIN=gcc`` or ``TOOLCHAIN=bisheng``;
   - ``make_AMD.sh``: AMD local HYPRE build entry;
   - ``run_threads_gcc.sh`` / ``run_threads_bisheng.sh`` / ``run_AMD.sh``: thread sweeps;
   - ``plot-time.py``: log parser, mean table, and ``time_3compares_np4.png`` generator.

   On Kunpeng:

   .. code-block:: bash

      cd tests/kunpeng_compare/D01_hypre_3Dxyz_omp
      TOOLCHAIN=gcc bash make.sh
      bash run_threads_gcc.sh
      TOOLCHAIN=bisheng bash make.sh
      bash run_threads_bisheng.sh

   On AMD:

   .. code-block:: bash

      cd tests/kunpeng_compare/D01_hypre_3Dxyz_omp
      bash make_AMD.sh
      bash run_AMD.sh

   After all logs are present:

   .. code-block:: bash

      python3 plot-time.py

   ``plot-time.py`` matches ``run_gcc_np4_omp*_*.log``,
   ``run_bisheng_np4_omp*_*.log``, and ``run_AMD_np4_omp*_*.log``. Missing
   platforms are skipped.

   .. list-table:: Output fields
      :header-rows: 1
      :widths: 28 52

      * - Field
        - Meaning
      * - ``compiler``
        - ``gcc``, ``bisheng``, or ``AMD``.
      * - ``np`` / ``omp``
        - MPI rank count (4 here) and OpenMP threads per rank.
      * - ``repeats``
        - Number of successfully parsed repeats.
      * - ``hypre_avg(s)``
        - Mean ``hypre_time_avg`` across repeats.
      * - ``total_avg(s)``
        - Mean ``total_time`` across repeats.
