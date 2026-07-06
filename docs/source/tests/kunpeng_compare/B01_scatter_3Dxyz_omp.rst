B01_scatter_3Dxyz_omp Comparison
================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本页说明 ``tests/kunpeng_compare/B01_scatter_3Dxyz_omp`` 中的性能对比测试。
   测试覆盖上游 :doc:`sub_B01_scatter_3Dxyz </rst_files/B_Scatter/B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz>`
   在 AMD服务器和鲲鹏服务器上的 OpenMP 扩展性，并对比两台机器在不同
   ``np`` 和 ``nthread`` 组合下的单次 scatter 耗时、加速比和并行效率。

   这是平台性能对比，不是数值正确性回归测试。重点观察
   ``sub_B01_scatter_3Dxyz`` 的
   ``!$omp parallel default(firstprivate) reduction(+:den)`` 设计在
   不同硬件 / 内存子系统下的开销差异。

   .. rubric:: 实验维度

   .. list-table::
      :header-rows: 1
      :widths: 24 76

      * - 维度
        - 取值
      * - ``np``
        - 10 000、100 000、1 000 000、10 000 000
      * - ``nthread``
        - 1, 2, 4, 6, 7, 8, 9, 10, 12, 14, 16, 32, 64
      * - ``nrepeat``
        - 10（每个 (np, nthread) 取均值 / 最佳 / 最差）
      * - grid
        - ``il=(1,1,1)``、``iu=(12,12,12)``，每侧 1 个 guard cell
      * - ``w``
        - 2.0

   粒子位置一次性在 ``[il, iu]`` 内随机采样，跨所有 thread 档位复用；
   ``den = 0`` 放在计时区间外，每次计时只统计一次纯 scatter 调用。

   .. rubric:: 程序结构

   - ``source_f90/main.f90``：外层 ``np`` 循环 × 内层 thread 循环，每点跑 ``nrepeat`` 次。
   - ``source_f90/make.sh`` / ``clean.sh``：编译 / 清理，被顶层 ``run_*.sh`` 内部调用。
   - ``run_AMD.sh``、``run_kunpeng.sh``：平台入口，自动 clean + make + run，日志直接落到对应 ``data_raw/from_*`` 子目录。
   - ``source_py/analyze.py``：解析两份 log，写 ``summary.csv``；仅当两个平台都有 log 时才出图。
   - ``plot.sh``：顶层后处理入口，调 analyze.py。

   .. rubric:: 运行方式

   在 AMD服务器上：

   .. code-block:: bash

      cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
      bash run_AMD.sh        # 写到 data_raw/from_AMD/log.run

   在鲲鹏上（把这个目录同步过去后）：

   .. code-block:: bash

      cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
      bash run_kunpeng.sh    # 写到 data_raw/from_kunpeng/log.run

   两边 log 齐了之后在任一台分析机上：

   .. code-block:: bash

      bash plot.sh

   ``run_*.sh`` 内部已设 ``ulimit -s unlimited`` 和
   ``OMP_STACKSIZE=1G``，因为 ``sub_B01_scatter_3Dxyz`` 把整个 ``(3, np)``
   粒子数组 firstprivate 到每个线程栈上；``np = 1e7`` 时默认 8 MB 系统栈直接溢出。

   .. rubric:: 输出字段

   ``output/summary.csv`` 每行对应一个 (平台, np, nthread) 三元组：

   .. list-table::
      :header-rows: 1
      :widths: 28 52

      * - 字段
        - 含义
      * - ``platform``
        - ``AMD服务器`` 或 ``Kunpeng``。
      * - ``np``
        - 当前粒子数。
      * - ``threads``
        - OpenMP 线程数。
      * - ``avg_s``
        - 该点 ``nrepeat`` 次单次 scatter 调用的平均墙钟时间（秒）。
      * - ``best_s`` / ``worst_s``
        - 同 ``nrepeat`` 次内的最佳和最差时间。
      * - ``speedup_vs_1``
        - 同平台、同 np 下相对 ``nthread = 1`` 的加速比，即 ``t(1) / t(N)``。
      * - ``efficiency_vs_1``
        - ``speedup_vs_1 / N``，理想值为 1.0。

   .. rubric:: 参考图

   .. figure:: ../../images/tests/kunpeng_compare/B01_scatter_3Dxyz_omp/time_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      平均单次 scatter 时间对比（log-log）。横轴为 OpenMP 线程数，
      纵轴为平均耗时；每个子图一个平台，每条曲线一个 ``np``。
      经典 U 形：少线程时 OMP 开销小，4-8 线程附近触底，之后随线程数
      增加 ``firstprivate par`` 拷贝和 reduction merge 反而把时间推高。

   .. figure:: ../../images/tests/kunpeng_compare/B01_scatter_3Dxyz_omp/speedup_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      加速比 ``t(1)/t(N)`` 对比（log-log）。虚线 ``ideal = N`` 代表
      **完美线性加速** ``N`` 个线程把时间砍成 ``1/N`` ，所以 64 线程理论加速 64×；
      在 log-log 下是 45° 直线。实测曲线和它之间的纵向距离 = OMP 额外开销的代价。
      实测曲线远低于 ideal 线，并在高线程档位**跌破 1**（即比串行还慢）。
      AMD服务器上 ``np = 1e7`` 几乎从 ``nthread = 2`` 起就负扩展；鲲鹏在
      1-8 线程区间仍能拿到约 3× 的实际加速。

   .. figure:: ../../images/tests/kunpeng_compare/B01_scatter_3Dxyz_omp/efficiency_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      并行效率 ``speedup / N``。虚线 ``ideal = 1`` 代表
      **完美并行效率**——每个线程都在做 100% 有用功；
      0.5 意味着一半算力被 OMP 开销吃掉，趋近 0 即已经负扩展。
      曲线下跌速度越快，表示 ``firstprivate`` + ``reduction`` 开销吃掉的算力越多。
      ``np`` 越大，曲线坍塌越快——firstprivate 拷贝的成本随 ``np`` 线性增长。

   .. rubric:: 参考结果

   单线程基线（s）：

   .. list-table::
      :header-rows: 1
      :widths: 14 28 28 30

      * - ``np``
        - AMD服务器
        - Kunpeng
        - Kunpeng 优势
      * - ``1e7``
        - 0.111
        - 0.069
        - 1.6×
      * - ``1e6``
        - 0.0128
        - 0.0064
        - 2.0×
      * - ``1e5``
        - 1.36e-3
        - 0.72e-3
        - 1.9×

   高线程档位的灾难差异（``np = 1e7``, ``nthread = 64``）：

   .. list-table::
      :header-rows: 1
      :widths: 22 28 50

      * - 平台
        - 时间 (s)
        - 相对自身串行
      * - AMD服务器
        - 4.10
        - **37× 慢**
      * - Kunpeng
        - 0.179
        - 2.6× 慢

   同档位下 Kunpeng 比 AMD服务器快 23 倍（``nt=64, np=1e7``），``nt=8`` 也快约 6 倍。

   要点总结：

   1. 两台机器都暴露 ``sub_B01_scatter_3Dxyz`` 的根本设计问题——
      ``default(firstprivate) reduction(+:den)`` 复制 ``(3, np)`` 粒子数组到每个线程，
      reduction 还要合并每线程私有 ``den``，二者叠加把 OMP 收益吃光。
   2. Kunpeng 内存子系统对这种压力更耐受：``np = 1e7`` 时在 ``nthread = 8``
      还能维持 ~0.4 的并行效率；AMD服务器同档位已掉到 <0.1。
   3. 即使在 Kunpeng 的最佳档位，实测加速比也只有约 3×，距离 ideal=N
      仍有一个数量级——**说明问题主要在 ``sub_B01_scatter_3Dxyz``，不只在平台**，
      改写 ``sub_B01_scatter_3Dxyz``（去掉 ``default(firstprivate)``、
      改用 shared par + 原子或更聪明的局部累加）才是根本解。

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This page documents the platform comparison under
   ``tests/kunpeng_compare/B01_scatter_3Dxyz_omp``. The case probes how the
   upstream :doc:`sub_B01_scatter_3Dxyz </rst_files/B_Scatter/B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz>`
   subroutine scales on the AMD server and the Kunpeng server, sweeping
   both particle count ``np`` and OpenMP thread count.

   This is a platform performance comparison, not a numerical regression test.
   The focus is the cost of the ``sub_B01_scatter_3Dxyz``
   ``!$omp parallel default(firstprivate) reduction(+:den)`` design on
   different hardware / memory subsystems.

   .. rubric:: Sweep Axes

   .. list-table::
      :header-rows: 1
      :widths: 24 76

      * - Axis
        - Values
      * - ``np``
        - 10 000, 100 000, 1 000 000, 10 000 000
      * - ``nthread``
        - 1, 2, 4, 6, 7, 8, 9, 10, 12, 14, 16, 32, 64
      * - ``nrepeat``
        - 10 (avg/best/worst recorded per (np, nthread))
      * - grid
        - ``il=(1,1,1)``, ``iu=(12,12,12)``, one guard cell on each side
      * - ``w``
        - 2.0

   Particle positions are sampled uniformly in ``[il, iu]`` once per ``np`` and
   reused across all thread counts. ``den = 0`` is done outside the timed
   region; each timing measures one pure scatter call.

   .. rubric:: Program Structure

   - ``source_f90/main.f90``: outer ``np`` loop × inner thread loop benchmark.
   - ``source_f90/make.sh``, ``clean.sh``: build/clean helpers invoked by ``run_*.sh``.
   - ``run_AMD.sh``, ``run_kunpeng.sh``: per-platform entry points; clean + build + run, log goes straight into the matching ``data_raw/from_*`` directory.
   - ``source_py/analyze.py``: parses both logs, writes ``summary.csv``; figures are written **only when both platforms have logs**.
   - ``plot.sh``: top-level post-processing entry point.

   .. rubric:: Run Command

   On the AMD server:

   .. code-block:: bash

      cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
      bash run_AMD.sh        # writes data_raw/from_AMD/log.run

   On the Kunpeng server (after syncing the directory):

   .. code-block:: bash

      cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
      bash run_kunpeng.sh    # writes data_raw/from_kunpeng/log.run

   Once both logs are present on the analysis machine:

   .. code-block:: bash

      bash plot.sh

   ``run_*.sh`` set ``ulimit -s unlimited`` and ``OMP_STACKSIZE=1G`` before
   launching, because ``sub_B01_scatter_3Dxyz`` firstprivatizes the full
   ``(3, np)`` particle array onto each thread's stack; the default 8 MB OS
   stack overflows at ``np = 1e7``.

   .. rubric:: Output Fields

   Each row in ``output/summary.csv`` is one (platform, np, nthread) triple.

   .. list-table::
      :header-rows: 1
      :widths: 28 52

      * - Field
        - Meaning
      * - ``platform``
        - ``AMD server`` or ``Kunpeng``.
      * - ``np``
        - Particle count for this row.
      * - ``threads``
        - OpenMP thread count.
      * - ``avg_s``
        - Average single-scatter wall time over ``nrepeat`` repetitions (s).
      * - ``best_s`` / ``worst_s``
        - Min/max single-call time within the same ``nrepeat`` run.
      * - ``speedup_vs_1``
        - ``t(1) / t(N)`` within the same platform and same ``np``.
      * - ``efficiency_vs_1``
        - ``speedup_vs_1 / N``; ideal value is 1.0.

   .. rubric:: Reference Figures

   .. figure:: ../../images/tests/kunpeng_compare/B01_scatter_3Dxyz_omp/time_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      Avg single-scatter time vs threads (log-log). One subplot per platform,
      one curve per ``np``. The classic U shape — minimum at a few threads,
      then rising — comes from the per-thread ``firstprivate par`` copy plus
      the ``reduction`` merge dominating once compute is amortized.

   .. figure:: ../../images/tests/kunpeng_compare/B01_scatter_3Dxyz_omp/speedup_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      Speedup ``t(1) / t(N)`` (log-log). The dashed ``ideal = N`` line is
      **perfect linear scaling** — ``N`` threads cut wall time to ``1/N``,
      so 64 threads would give a 64× speedup; on log-log that is a 45°
      diagonal. The vertical gap between each curve and the diagonal is the
      cost of OMP overhead. Measured curves stay far below the diagonal
      and bend below 1 (slower than serial) at high thread counts.
      On the AMD server with ``np = 1e7`` the scaling is negative from ``nthread = 2``
      onward; on Kunpeng ``sub_B01_scatter_3Dxyz`` still picks up about 3×
      real speedup in the 1-8 thread range.

   .. figure:: ../../images/tests/kunpeng_compare/B01_scatter_3Dxyz_omp/efficiency_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide

      Parallel efficiency ``speedup / N``. The dashed ``ideal = 1`` line is
      **perfect parallel efficiency** — every thread is doing 100% useful
      work; 0.5 means half the compute is being eaten by overhead and
      approaching 0 means already-negative scaling. The faster a curve
      falls, the more ``firstprivate + reduction`` overhead is eating the
      available compute. Curves collapse faster as ``np`` grows — the
      firstprivate copy cost scales linearly with ``np``.

   .. rubric:: Reference Results

   Single-thread baseline (s):

   .. list-table::
      :header-rows: 1
      :widths: 14 28 28 30

      * - ``np``
        - AMD server
        - Kunpeng
        - Kunpeng advantage
      * - ``1e7``
        - 0.111
        - 0.069
        - 1.6×
      * - ``1e6``
        - 0.0128
        - 0.0064
        - 2.0×
      * - ``1e5``
        - 1.36e-3
        - 0.72e-3
        - 1.9×

   High thread-count divergence (``np = 1e7``, ``nthread = 64``):

   .. list-table::
      :header-rows: 1
      :widths: 22 28 50

      * - Platform
        - Time (s)
        - Relative to own serial
      * - AMD server
        - 4.10
        - **37× slower**
      * - Kunpeng
        - 0.179
        - 2.6× slower

   At the same setting Kunpeng is **23× faster** than the AMD server (``nt=64, np=1e7``);
   it is roughly 6× faster at ``nt=8``.

   Takeaways:

   1. Both machines expose the same fundamental problem in
      ``sub_B01_scatter_3Dxyz`` — ``default(firstprivate)`` copies the
      entire ``(3, np)`` particle array to each thread, and
      ``reduction(+:den)`` then merges per-thread private ``den`` copies.
      Together they eat OMP speedup.
   2. Kunpeng's memory subsystem is much more tolerant of this pressure:
      at ``np = 1e7, nthread = 8`` it still holds ~0.4 efficiency, while
      the same point on the AMD server has already dropped below 0.1.
   3. Even at Kunpeng's sweet spot, measured speedup peaks near 3× —
      an order of magnitude below the ``ideal = N`` line. **This means the
      bottleneck is ``sub_B01_scatter_3Dxyz``, not the platform**: a real
      fix requires rewriting ``sub_B01_scatter_3Dxyz`` (drop
      ``default(firstprivate)``, share ``par`` and use atomic adds or smarter
      local accumulation) rather than waiting for better hardware.
