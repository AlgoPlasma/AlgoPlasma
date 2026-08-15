A01_Boris_3Dxyz_omp Comparison
==============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-kunpeng-compare

   .. note:: 快速结论

      两台服务器从 8 线程增加到 256 线程时，总体都能缩短 Boris 推进时间；
      AMD 在 512 线程出现回退，鲲鹏仍继续变快，但高线程并行效率已经明显下降。
      当前每个平台、每个线程档位只有一份日志，而且运行脚本没有固定线程绑定，
      因此个别交叉点只能视为现象，不能直接归因于 CPU 平台。

   .. rubric:: 测试对象与比较口径

   本页说明 ``tests/kunpeng_compare/A01_Boris_3Dxyz_omp`` 中的性能对比测试。
   测试让同一个 OpenMP Boris pusher 主程序 ``boris_xyz_SoA_omp.f90``
   在 AMD 服务器和鲲鹏服务器上运行，比较计算时间、吞吐率和并行扩展性。

   这是平台性能对比，不是数值正确性回归测试。固定工作量为：

   - ``np = 10000000``：每个时间步推进一千万个粒子；
   - ``nt = 100000``：连续推进十万个时间步；
   - OpenMP 线程数 ``8,16,32,64,128,256,512``。

   同线程平台对比回答“此时哪台机器更快”；同一平台沿线程数观察则回答
   “增加线程是否真正带来收益”。这两个问题不能混为一谈。

   .. rubric:: 读图前先认识三个量

   .. list-table::
      :header-rows: 1
      :widths: 24 76

      * - 指标
        - 初学者可以怎样理解
      * - ``Compute wall time``
        - 完成固定计算所经过的真实时间，单位秒；越低越快。
      * - ``Throughput``
        - 每秒完成多少十亿次粒子推进；工作量固定时，它与计算时间方向相反，越高越好。
      * - ``speedup_vs_8``
        - 同一平台的 8 线程时间除以当前时间。线程从 8 增到 16 时，理想加速为 2；
          增到 256 时，理想加速为 32。
      * - ``parallel_efficiency_vs_8``
        - 实际加速比除以线程倍数。接近 1 表示新增线程大多在做有效工作，越接近 0
          表示并行开销或资源争用越严重。

   .. rubric:: 参考图与读图顺序

   建议先看计算时间图确认“绝对快慢”，再用吞吐率图核对同一结论，最后看加速比图
   判断“多加的线程值不值得”。点击任意图片可查看原始尺寸。

   .. figure:: ../../images/tests/kunpeng_compare/A01_Boris_3Dxyz_omp/wall_time_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-readable
      :target: ../../_images/wall_time_vs_threads.png

      计算时间对比。横轴为 OpenMP 线程数，纵轴为计算 wall time；曲线越低表示越快。

   .. figure:: ../../images/tests/kunpeng_compare/A01_Boris_3Dxyz_omp/throughput_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-readable
      :target: ../../_images/throughput_vs_threads.png

      吞吐率对比。横轴仍为线程数，纵轴为 G particle-pushes/s；曲线越高表示越快。

   .. figure:: ../../images/tests/kunpeng_compare/A01_Boris_3Dxyz_omp/speedup_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-readable
      :target: ../../_images/speedup_vs_threads.png

      并行扩展性对比。纵轴是各平台相对自身 8 线程的加速比，不是两台机器之间的速度比。

   .. rubric:: 先看几个代表线程点

   .. list-table:: 计算时间（秒）
      :header-rows: 1
      :widths: 16 24 24 36

      * - 线程数
        - AMD
        - 鲲鹏
        - 同线程观察
      * - 8
        - ``5460.933``
        - ``3262.718``
        - 鲲鹏约快 ``1.67×``。
      * - 32
        - ``1380.607``
        - ``1537.848``
        - AMD 约快 ``1.11×``，鲲鹏在这里出现局部异常。
      * - 128
        - ``350.194``
        - ``301.091``
        - 鲲鹏约快 ``1.16×``。
      * - 256
        - ``195.466``
        - ``234.492``
        - AMD 约快 ``1.20×``。
      * - 512
        - ``364.370``
        - ``192.734``
        - 鲲鹏约快 ``1.89×``；AMD 已比自身 256 线程更慢。

   单点表说明两条曲线会交叉，不能用某一个线程档位概括整个平台。
   ``Total wall time`` 与 ``Compute wall time`` 在日志中几乎相同，也说明本算例的
   总时间主要由推进 kernel 决定，而不是初始化或收尾阶段。

   .. rubric:: 再看整体并行效果

   - AMD 从 8 到 128 线程接近理想缩放，256 线程仍有收益；512 线程反而比 256
     线程慢约 ``1.86×``，说明已经越过当前运行环境的有效扩展区间。
   - 鲲鹏从 8 到 16 线程正常变快，32 线程收益异常偏低，64 线程后又恢复下降趋势；
     到 512 线程仍比 256 线程快，但相对 8 线程的效率只剩约 ``26%``。
   - 两个平台在高线程区间都出现效率下降，所以“耗时还在下降”不等于“新增线程仍被充分利用”。

   .. rubric:: 可能原因与结论边界

   下面是与曲线形状相符的可能原因，不是当前日志直接证明的结论：

   - 线程数跨过物理核、socket 或 NUMA 边界后，内存访问距离和同步成本可能上升；
   - 运行脚本只设置 ``OMP_NUM_THREADS``，没有记录 ``OMP_PROC_BIND``、``OMP_PLACES``
     或 NUMA 策略，线程落点变化可能造成 32 线程异常和高线程回退；
   - 512 线程可能超过有效物理核数，或让多个硬件线程竞争同一核心和内存带宽；
   - 当前每个点只有一次运行，系统噪声也可能放大局部交叉。

   若要确认原因，需要补充两台机器的 CPU/socket/NUMA 拓扑、编译器与 OpenMP runtime
   版本、固定绑定策略，并对每个线程数做多次重复测量。

   .. rubric:: 复现方法与数据字段

   程序结构：

   - ``source_f90/boris_xyz_SoA_omp.f90``：原始 Boris pusher OpenMP 测试主程序；
   - ``source_f90/make.sh``、``source_f90/run.sh``、``source_f90/clean.sh``：原始编译、运行和清理脚本；
   - ``data_raw/from_AMD/log*.run``：AMD 服务器原始运行日志；
   - ``data_raw/from_kunpeng/log*.run``：鲲鹏服务器原始运行日志；
   - ``source_py/analyze.py``：解析日志，生成 ``summary.csv`` 和对比图。

   .. code-block:: bash

      cd tests/kunpeng_compare/A01_Boris_3Dxyz_omp
      bash run.sh

   ``run.sh`` 只后处理现有日志，不会重新运行 Fortran 基准程序。若要复现实验，进入
   ``source_f90/`` 使用保留的原始脚本。

   ``output/summary.csv`` 每行对应一个平台和一个线程数：

   .. list-table::
      :header-rows: 1
      :widths: 28 52

      * - 字段
        - 含义
      * - ``platform`` / ``threads``
        - 平台名称与 OpenMP 线程数。
      * - ``total_wall_time_s`` / ``compute_wall_time_s``
        - 日志中的总 wall time 和计算 wall time，单位秒。
      * - ``throughput_gpushes_s``
        - ``np*nt/compute_wall_time``，单位 G particle-pushes/s。
      * - ``speedup_vs_8`` / ``parallel_efficiency_vs_8``
        - 相对同平台 8 线程的加速比和并行效率。
      * - ``kunpeng_speed_vs_AMD``
        - 同线程下 ``AMD compute time / Kunpeng compute time``；大于 1 表示鲲鹏更快。

.. container:: ap-lang ap-lang-en ap-kunpeng-compare

   .. note:: Quick take

      Both servers generally reduce Boris-pusher time when scaling from 8 to
      256 threads. AMD regresses at 512 threads; Kunpeng keeps improving, but
      its high-thread parallel efficiency has already fallen substantially.
      There is only one log per platform/thread point, and the run script does
      not pin threads, so isolated crossovers are observations rather than
      proof of an architectural cause.

   .. rubric:: What Is Compared

   This page documents ``tests/kunpeng_compare/A01_Boris_3Dxyz_omp``. The same
   OpenMP Boris pusher, ``boris_xyz_SoA_omp.f90``, runs on the AMD and Kunpeng
   servers. We compare compute time, throughput, and parallel scaling.

   This is a platform performance comparison, not a numerical-regression test.
   The fixed workload is:

   - ``np = 10000000`` particles per step;
   - ``nt = 100000`` time steps;
   - OpenMP threads ``8,16,32,64,128,256,512``.

   A same-thread comparison asks which server is faster at that point. Following
   one platform across thread counts asks whether extra threads help. These are
   different questions.

   .. rubric:: Three Quantities Used in the Figures

   .. list-table::
      :header-rows: 1
      :widths: 24 76

      * - Quantity
        - Beginner-friendly meaning
      * - ``Compute wall time``
        - Real elapsed time for the fixed computation, in seconds; lower is better.
      * - ``Throughput``
        - Billions of particle pushes completed per second; higher is better.
      * - ``speedup_vs_8``
        - The same platform's 8-thread time divided by the current time. Ideal
          speedup is 2 at 16 threads and 32 at 256 threads.
      * - ``parallel_efficiency_vs_8``
        - Measured speedup divided by the thread-count multiplier. Values near 1
          mean most added threads do useful work; values near 0 mean overhead or
          resource contention dominates.

   .. rubric:: Figures and Reading Order

   Read compute time first for absolute performance, use throughput to confirm
   the same result, and then use speedup to judge whether additional threads are
   worthwhile. Click any figure to open it at its original size.

   .. figure:: ../../images/tests/kunpeng_compare/A01_Boris_3Dxyz_omp/wall_time_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-readable
      :target: ../../_images/wall_time_vs_threads.png

      Compute-time comparison. x-axis: OpenMP threads. y-axis: compute wall time; lower is faster.

   .. figure:: ../../images/tests/kunpeng_compare/A01_Boris_3Dxyz_omp/throughput_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-readable
      :target: ../../_images/throughput_vs_threads.png

      Throughput comparison in G particle-pushes/s; higher is faster.

   .. figure:: ../../images/tests/kunpeng_compare/A01_Boris_3Dxyz_omp/speedup_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-readable
      :target: ../../_images/speedup_vs_threads.png

      Scaling relative to each platform's own 8-thread result; this is not a cross-platform speed ratio.

   .. rubric:: Representative Thread Counts

   .. list-table:: Compute time (seconds)
      :header-rows: 1
      :widths: 16 24 24 36

      * - Threads
        - AMD
        - Kunpeng
        - Same-thread observation
      * - 8
        - ``5460.933``
        - ``3262.718``
        - Kunpeng is about ``1.67×`` faster.
      * - 32
        - ``1380.607``
        - ``1537.848``
        - AMD is about ``1.11×`` faster; Kunpeng has a local anomaly.
      * - 128
        - ``350.194``
        - ``301.091``
        - Kunpeng is about ``1.16×`` faster.
      * - 256
        - ``195.466``
        - ``234.492``
        - AMD is about ``1.20×`` faster.
      * - 512
        - ``364.370``
        - ``192.734``
        - Kunpeng is about ``1.89×`` faster; AMD is slower than at 256 threads.

   The curves cross, so one thread count cannot summarize an entire platform.
   Total and compute wall times are almost identical in the logs, showing that
   the pusher kernel dominates this case rather than setup or teardown.

   .. rubric:: Overall Parallel Behavior

   - AMD scales close to ideally from 8 to 128 threads and still improves at
     256, but 512 threads are about ``1.86×`` slower than 256.
   - Kunpeng improves normally from 8 to 16 threads, shows unusually weak gain
     at 32, and resumes improving after 64. It still improves at 512 threads,
     but efficiency relative to 8 threads is only about ``26%``.
   - On both platforms, falling time at high thread counts does not imply that
     the added threads are being used efficiently.

   .. rubric:: Possible Causes and Limits

   The following explanations are consistent with the curves but are not
   directly proven by the available logs:

   - crossing core, socket, or NUMA boundaries may increase memory distance and synchronization cost;
   - the script sets only ``OMP_NUM_THREADS`` and records no ``OMP_PROC_BIND``,
     ``OMP_PLACES``, or NUMA policy, so placement changes may affect the 32-thread
     anomaly and high-thread regression;
   - 512 threads may exceed the useful physical-core count or introduce shared-core
     and memory-bandwidth contention;
   - one run per point leaves local results sensitive to system noise.

   Confirming these causes requires CPU/socket/NUMA topology, compiler and OpenMP
   runtime versions, fixed placement, and repeated measurements.

   .. rubric:: Reproduction and Output Fields

   Program structure:

   - ``source_f90/boris_xyz_SoA_omp.f90``: original OpenMP Boris benchmark;
   - ``source_f90/make.sh``, ``source_f90/run.sh``, ``source_f90/clean.sh``: original build/run/clean scripts;
   - ``data_raw/from_AMD/log*.run`` and ``data_raw/from_kunpeng/log*.run``: raw platform logs;
   - ``source_py/analyze.py``: parser that writes ``summary.csv`` and the figures.

   .. code-block:: bash

      cd tests/kunpeng_compare/A01_Boris_3Dxyz_omp
      bash run.sh

   ``run.sh`` only post-processes existing logs. Use the scripts under
   ``source_f90/`` to reproduce the benchmark itself.

   Each row in ``output/summary.csv`` is one platform/thread result:

   .. list-table::
      :header-rows: 1
      :widths: 28 52

      * - Field
        - Meaning
      * - ``platform`` / ``threads``
        - Platform name and OpenMP thread count.
      * - ``total_wall_time_s`` / ``compute_wall_time_s``
        - Total and compute wall time from the log, in seconds.
      * - ``throughput_gpushes_s``
        - ``np*nt/compute_wall_time`` in G particle-pushes/s.
      * - ``speedup_vs_8`` / ``parallel_efficiency_vs_8``
        - Speedup and efficiency relative to the same platform's 8-thread run.
      * - ``kunpeng_speed_vs_AMD``
        - ``AMD compute time / Kunpeng compute time`` at equal threads; values above 1 favor Kunpeng.
