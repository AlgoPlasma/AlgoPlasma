B01_scatter_3Dxyz_omp Comparison
================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-kunpeng-compare

   .. note:: 快速结论

      这个 scatter kernel 不是“线程越多越快”。两台机器都只在少量线程时获得有限收益，
      随后进入负扩展；``np = 1e7``、64 线程时甚至都比各自单线程更慢。
      鲲鹏在当前数据中退化得更晚、更缓，但根本问题仍是
      ``firstprivate`` 大数组复制与 ``reduction`` 合并开销，而不是单纯的平台快慢。

   .. rubric:: 测试对象与比较口径

   本页说明 ``tests/kunpeng_compare/B01_scatter_3Dxyz_omp`` 中的性能对比测试。
   测试覆盖上游
   :doc:`sub_B01_scatter_3Dxyz </rst_files/B_Scatter/B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz>`
   在 AMD 服务器和鲲鹏服务器上的 OpenMP 扩展性，并同时扫描粒子数 ``np``
   与线程数 ``nthread``。

   这是平台性能对比，不是数值正确性回归测试。重点观察下面这段并行设计在不同
   硬件和 OpenMP runtime 上的代价：

   ``!$omp parallel default(firstprivate) reduction(+:den)``

   .. list-table:: 实验维度
      :header-rows: 1
      :widths: 24 76

      * - 维度
        - 取值
      * - ``np``
        - 10 000、100 000、1 000 000、10 000 000
      * - ``nthread``
        - 1, 2, 4, 6, 7, 8, 9, 10, 12, 14, 16, 32, 64
      * - ``nrepeat``
        - 10；每个 (np, nthread) 记录平均、最佳和最差时间
      * - grid
        - ``il=(1,1,1)``、``iu=(12,12,12)``，每侧 1 个 guard cell
      * - ``w``
        - 2.0

   粒子位置只在开始时于 ``[il, iu]`` 内随机采样一次，之后在所有线程档位复用；
   ``den = 0`` 放在计时区间外，每次计时只包含一次纯 scatter 调用。

   .. rubric:: 读图前先认识三个量

   - **平均耗时** ``avg_s``：一次 scatter 调用的平均 wall time，越低越好。
   - **加速比** ``t(1)/t(N)``：同平台、同 ``np`` 的单线程时间除以 N 线程时间。
     大于 1 才是真的变快；小于 1 表示比单线程还慢。
   - **并行效率** ``speedup/N``：衡量每个新增线程贡献了多少有效加速。
     理想值为 1；例如 0.5 表示只取得理想加速的一半。

   三张图依次回答：实际时间怎样变化、比单线程快多少、增加的线程利用得怎样。
   图使用 log-log 坐标，以便同时容纳多个数量级。点击图片可查看原始尺寸。

   .. rubric:: 图一：先看实际耗时

   .. figure:: ../../images/tests/kunpeng_compare/B01_scatter_3Dxyz_omp/time_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-panorama
      :target: ../../_images/time_vs_threads.png

      平均单次 scatter 时间。左图为 AMD，右图为鲲鹏；每条曲线对应一个 ``np``，
      横轴为线程数、纵轴为秒。曲线先降后升就是典型的 U 形扩展。

   少线程时，并行计算收益还能覆盖 OpenMP 开销；到最低点以后，继续增加线程反而让
   ``firstprivate`` 复制和 reduction 合并成本超过计算收益。AMD 的最低点多在 2–4
   线程，鲲鹏的大粒子算例多在 8–9 线程附近。

   .. rubric:: 图二：再看是否真的加速

   .. figure:: ../../images/tests/kunpeng_compare/B01_scatter_3Dxyz_omp/speedup_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-panorama
      :target: ../../_images/speedup_vs_threads1.png

      加速比 ``t(1)/t(N)``。虚线 ``ideal = N`` 是完美线性加速；实测曲线跌破 1
      就表示并行版本比单线程还慢。

   理想情况下，64 线程应达到 64× 加速，因此在 log-log 图中形成斜率为 1 的直线。
   实测曲线与理想线之间的距离，就是同步、复制、归并和资源争用等开销吃掉的收益。

   .. rubric:: 图三：最后看线程利用率

   .. figure:: ../../images/tests/kunpeng_compare/B01_scatter_3Dxyz_omp/efficiency_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-panorama
      :target: ../../_images/efficiency_vs_threads.png

      并行效率 ``speedup/N``。虚线 ``ideal = 1`` 表示完美效率；曲线越快接近 0，
      表示越多线程消耗在额外开销而不是有效 scatter 计算上。

   ``np`` 越大，``firstprivate`` 需要复制的 ``(3,np)`` 粒子数组越大，因此大算例的
   效率曲线通常坍塌得更明显。并行效率很低时，即使总时间偶尔下降，也不代表继续加线程划算。

   .. rubric:: 先看一个代表算例：np = 1e7

   .. list-table::
      :header-rows: 1
      :widths: 13 20 21 20 26

      * - 平台
        - 线程
        - 平均时间 (s)
        - 相对单线程
        - 并行效率
      * - AMD
        - 1
        - ``0.1122944``
        - 基线
        - ``1.000``
      * - AMD
        - 8
        - ``0.1703629``
        - 慢 ``1.52×``
        - ``0.082``
      * - AMD
        - 64
        - ``3.506554``
        - 慢 ``31.2×``
        - ``0.00050``
      * - 鲲鹏
        - 1
        - ``0.0692914``
        - 基线
        - ``1.000``
      * - 鲲鹏
        - 8
        - ``0.03137181``
        - 快 ``2.21×``
        - ``0.276``
      * - 鲲鹏
        - 64
        - ``0.1791504``
        - 慢 ``2.59×``
        - ``0.00604``

   在同一个 64 线程档位，鲲鹏比 AMD 快约 ``19.6×``；8 线程时约快 ``5.43×``。
   这说明当前鲲鹏环境对该开销模式更耐受，但两台机器在 64 线程都已经负扩展，
   所以不能把 ``19.6×`` 解读为正常计算 kernel 的通用平台优势。

   单线程基线也呈现一致的平台差异：

   .. list-table::
      :header-rows: 1
      :widths: 14 28 28 30

      * - ``np``
        - AMD (s)
        - 鲲鹏 (s)
        - 鲲鹏优势
      * - ``1e7``
        - ``0.1123``
        - ``0.0693``
        - ``1.62×``
      * - ``1e6``
        - ``0.0128``
        - ``0.0064``
        - ``2.0×``
      * - ``1e5``
        - ``1.36e-3``
        - ``0.72e-3``
        - ``1.9×``

   .. rubric:: 再看整体并行效果

   - AMD 的最佳点随 ``np`` 略有变化，但主要集中在 2–4 线程；``np=1e7`` 从 4
     线程起已经明显退化，8 线程起慢于单线程。
   - 鲲鹏对 ``np=1e5`` 到 ``1e7`` 通常能在 8–9 线程附近取得约 2.2–2.3×
     的最高加速，之后同样持续下降；到 32 或 64 线程时大算例已负扩展。
   - 两个平台的实测曲线都远低于理想线，说明问题首先来自 kernel 的并行组织方式，
     而不是单独来自某台机器。

   .. rubric:: 可能原因与结论边界

   源码能直接确认的开销有两项：``default(firstprivate)`` 会为每个线程复制整个
   ``(3,np)`` 粒子数组，``reduction(+:den)`` 还要为每个线程维护并最终合并私有
   ``den``。二者都随线程数增加，足以解释 U 形曲线和高线程负扩展。

   鲲鹏退化更缓可能与内存带宽、NUMA 拓扑、线程放置或 OpenMP runtime 实现有关，
   但当前测试没有记录足够硬件计数器和拓扑信息，不能确定是哪一项。验证需要固定
   ``OMP_PROC_BIND``/``OMP_PLACES``、记录 NUMA 放置，并分别测量复制、scatter
   计算和 reduction 合并时间。

   根本优化方向是重写 ``sub_B01_scatter_3Dxyz``：避免把粒子数组整体
   ``firstprivate``，改用 shared 只读粒子数据，并重新设计局部累加、原子更新或分块归并。

   .. rubric:: 复现方法与数据字段

   程序结构：

   - ``source_f90/main.f90``：外层 ``np`` 循环、内层线程循环，每点运行 ``nrepeat`` 次；
   - ``source_f90/make.sh`` / ``clean.sh``：编译和清理脚本；
   - ``run_AMD.sh``、``run_kunpeng.sh``：平台入口，自动 clean、make、run；
   - ``source_py/analyze.py``：解析两份日志并写 ``summary.csv``；
   - ``plot.sh``：后处理入口，仅在两边日志都存在时生成对比图。

   在 AMD 服务器上：

   .. code-block:: bash

      cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
      bash run_AMD.sh        # 写到 data_raw/from_AMD/log.run

   在鲲鹏服务器上：

   .. code-block:: bash

      cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
      bash run_kunpeng.sh    # 写到 data_raw/from_kunpeng/log.run

   日志齐全后：

   .. code-block:: bash

      bash plot.sh

   ``run_*.sh`` 已设置 ``ulimit -s unlimited`` 和 ``OMP_STACKSIZE=1G``。
   原因是 ``firstprivate`` 把大粒子数组放到各线程栈上；``np=1e7`` 时默认 8 MB
   系统栈会直接溢出。

   ``output/summary.csv`` 每行对应一个 (平台, np, nthread) 组合：

   .. list-table::
      :header-rows: 1
      :widths: 28 52

      * - 字段
        - 含义
      * - ``platform`` / ``np`` / ``threads``
        - 平台、粒子数和 OpenMP 线程数。
      * - ``avg_s``
        - ``nrepeat`` 次单次 scatter 调用的平均 wall time。
      * - ``best_s`` / ``worst_s``
        - 同一测试点十次运行中的最佳和最差时间。
      * - ``speedup_vs_1``
        - 同平台、同 ``np`` 下的 ``t(1)/t(N)``。
      * - ``efficiency_vs_1``
        - ``speedup_vs_1/N``。

.. container:: ap-lang ap-lang-en ap-kunpeng-compare

   .. note:: Quick take

      This scatter kernel is not faster with every added thread. Both servers
      gain only at low thread counts and then enter negative scaling; at
      ``np=1e7`` and 64 threads both are slower than their own serial runs.
      Kunpeng degrades later and more gradually in this dataset, but the primary
      issue is large ``firstprivate`` copies plus reduction merging, not simply
      platform speed.

   .. rubric:: What Is Compared

   This page documents ``tests/kunpeng_compare/B01_scatter_3Dxyz_omp`` and the
   OpenMP scaling of
   :doc:`sub_B01_scatter_3Dxyz </rst_files/B_Scatter/B01_scatter_3Dxyz/sub_B01_scatter_3Dxyz>`
   on the AMD and Kunpeng servers. Both particle count ``np`` and thread count
   ``nthread`` are swept.

   This is a platform performance comparison, not a numerical-regression test.
   It focuses on the cost of:

   ``!$omp parallel default(firstprivate) reduction(+:den)``

   .. list-table:: Sweep axes
      :header-rows: 1
      :widths: 24 76

      * - Axis
        - Values
      * - ``np``
        - 10 000, 100 000, 1 000 000, 10 000 000
      * - ``nthread``
        - 1, 2, 4, 6, 7, 8, 9, 10, 12, 14, 16, 32, 64
      * - ``nrepeat``
        - 10; average, best, and worst are recorded per point
      * - grid
        - ``il=(1,1,1)``, ``iu=(12,12,12)``, one guard cell per side
      * - ``w``
        - 2.0

   Particle positions are sampled once in ``[il, iu]`` and reused at all thread
   counts. ``den = 0`` is outside the timed region, so each timing contains only
   one scatter call.

   .. rubric:: Three Quantities Used in the Figures

   - **Average time** ``avg_s`` is wall time for one scatter call; lower is better.
   - **Speedup** ``t(1)/t(N)`` compares N threads with the same platform's serial
     result. Values below 1 mean parallel execution is slower than serial.
   - **Parallel efficiency** ``speedup/N`` measures how effectively added threads
     are used. The ideal value is 1.

   The three figures answer, in order: how time changes, whether execution is
   actually faster, and how well added threads are used. The axes are log-log so
   several orders of magnitude fit on one page. Click a figure for original size.

   .. rubric:: Figure 1: Measured Time

   .. figure:: ../../images/tests/kunpeng_compare/B01_scatter_3Dxyz_omp/time_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-panorama
      :target: ../../_images/time_vs_threads.png

      Average scatter time. AMD is on the left and Kunpeng on the right; each
      curve is one ``np``. A curve that falls and then rises has U-shaped scaling.

   At low thread counts, useful parallel work can cover OpenMP overhead. Past the
   minimum, ``firstprivate`` copies and reduction merging cost more than the
   saved compute time. AMD minima are mostly at 2–4 threads, while larger Kunpeng
   cases usually bottom near 8–9 threads.

   .. rubric:: Figure 2: Is It Really Faster?

   .. figure:: ../../images/tests/kunpeng_compare/B01_scatter_3Dxyz_omp/speedup_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-panorama
      :target: ../../_images/speedup_vs_threads1.png

      Speedup ``t(1)/t(N)``. ``ideal = N`` is perfect linear scaling; measured
      curves below 1 are slower than serial.

   Ideally, 64 threads would produce 64× speedup, giving a slope-1 line on a
   log-log plot. The gap to this line is the performance consumed by copying,
   synchronization, merging, and resource contention.

   .. rubric:: Figure 3: Thread Utilization

   .. figure:: ../../images/tests/kunpeng_compare/B01_scatter_3Dxyz_omp/efficiency_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-panorama
      :target: ../../_images/efficiency_vs_threads.png

      Parallel efficiency ``speedup/N``. ``ideal = 1`` is perfect efficiency;
      rapid decay toward 0 means overhead consumes most added capacity.

   Larger ``np`` means a larger ``(3,np)`` array is copied for every thread, so
   the large-case efficiency curves collapse especially strongly. A small time
   decrease is not automatically worthwhile when efficiency is already tiny.

   .. rubric:: Representative Case: np = 1e7

   .. list-table::
      :header-rows: 1
      :widths: 13 20 21 20 26

      * - Platform
        - Threads
        - Average time (s)
        - Versus serial
        - Efficiency
      * - AMD
        - 1
        - ``0.1122944``
        - baseline
        - ``1.000``
      * - AMD
        - 8
        - ``0.1703629``
        - ``1.52×`` slower
        - ``0.082``
      * - AMD
        - 64
        - ``3.506554``
        - ``31.2×`` slower
        - ``0.00050``
      * - Kunpeng
        - 1
        - ``0.0692914``
        - baseline
        - ``1.000``
      * - Kunpeng
        - 8
        - ``0.03137181``
        - ``2.21×`` faster
        - ``0.276``
      * - Kunpeng
        - 64
        - ``0.1791504``
        - ``2.59×`` slower
        - ``0.00604``

   At 64 threads Kunpeng is about ``19.6×`` faster than AMD, and at 8 threads it
   is about ``5.43×`` faster. This shows greater tolerance of this overhead
   pattern in the current Kunpeng environment. Because both 64-thread results
   are negatively scaling, ``19.6×`` is not a general platform ratio for a
   well-scaling compute kernel.

   The serial baselines show a consistent platform difference:

   .. list-table::
      :header-rows: 1
      :widths: 14 28 28 30

      * - ``np``
        - AMD (s)
        - Kunpeng (s)
        - Kunpeng advantage
      * - ``1e7``
        - ``0.1123``
        - ``0.0693``
        - ``1.62×``
      * - ``1e6``
        - ``0.0128``
        - ``0.0064``
        - ``2.0×``
      * - ``1e5``
        - ``1.36e-3``
        - ``0.72e-3``
        - ``1.9×``

   .. rubric:: Overall Parallel Behavior

   - AMD's optimum varies slightly with ``np`` but is mostly at 2–4 threads.
     For ``np=1e7`` performance degrades after 2 threads and is slower than
     serial from 8 threads onward.
   - For ``np=1e5`` through ``1e7``, Kunpeng usually peaks near 8–9 threads at
     roughly 2.2–2.3× speedup, then declines; large cases negatively scale by
     32 or 64 threads.
   - Both platforms stay far below the ideal line, so the kernel's parallel
     organization is the first-order problem, not either machine alone.

   .. rubric:: Possible Causes and Limits

   Two costs are directly confirmed by the source. ``default(firstprivate)``
   copies the entire ``(3,np)`` particle array for every thread, and
   ``reduction(+:den)`` creates and then merges private ``den`` values. Both
   grow with thread count and explain the U shape and negative scaling.

   Kunpeng's slower degradation may involve memory bandwidth, NUMA topology,
   thread placement, or OpenMP runtime behavior. The current benchmark records
   too little topology and counter data to isolate one cause. Confirmation needs
   fixed ``OMP_PROC_BIND``/``OMP_PLACES``, NUMA placement records, and separate
   timings for copying, useful scatter work, and reduction merging.

   The fundamental optimization is to rewrite ``sub_B01_scatter_3Dxyz``: keep
   particle data shared and read-only, avoid whole-array ``firstprivate``, and
   redesign local accumulation, atomic updates, or blocked merging.

   .. rubric:: Reproduction and Output Fields

   Program structure:

   - ``source_f90/main.f90``: outer ``np`` loop and inner thread sweep, with ``nrepeat`` runs per point;
   - ``source_f90/make.sh`` / ``clean.sh``: build and clean helpers;
   - ``run_AMD.sh`` and ``run_kunpeng.sh``: per-platform clean/build/run entry points;
   - ``source_py/analyze.py``: parses both logs and writes ``summary.csv``;
   - ``plot.sh``: post-processing entry; figures require both platform logs.

   On AMD:

   .. code-block:: bash

      cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
      bash run_AMD.sh        # writes data_raw/from_AMD/log.run

   On Kunpeng:

   .. code-block:: bash

      cd tests/kunpeng_compare/B01_scatter_3Dxyz_omp
      bash run_kunpeng.sh    # writes data_raw/from_kunpeng/log.run

   After both logs are present:

   .. code-block:: bash

      bash plot.sh

   ``run_*.sh`` sets ``ulimit -s unlimited`` and ``OMP_STACKSIZE=1G`` because
   ``firstprivate`` puts large particle copies on thread stacks. The default
   8 MB process stack overflows at ``np=1e7``.

   Each ``output/summary.csv`` row is one (platform, np, thread) point:

   .. list-table::
      :header-rows: 1
      :widths: 28 52

      * - Field
        - Meaning
      * - ``platform`` / ``np`` / ``threads``
        - Platform, particle count, and OpenMP thread count.
      * - ``avg_s``
        - Mean wall time for one scatter call across ``nrepeat`` runs.
      * - ``best_s`` / ``worst_s``
        - Best and worst time at that point.
      * - ``speedup_vs_1``
        - ``t(1)/t(N)`` for the same platform and ``np``.
      * - ``efficiency_vs_1``
        - ``speedup_vs_1/N``.
