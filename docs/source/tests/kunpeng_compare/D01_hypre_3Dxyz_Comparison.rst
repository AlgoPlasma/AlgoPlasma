D01_hypre_3Dxyz Comparison
==========================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-kunpeng-compare

   .. note:: 快速结论

      OMP 扫描表明，固定 4 个 MPI rank 时，中等线程数能降低 HYPRE solve 时间，
      但端到端总时间改善更小；AMD 在 ``OMP=32`` 之后明显退化，``OMP=48`` 和
      ``OMP=64`` 的高线程点被纵轴裁剪。MPI 扫描表明，在 ``OMP=1`` 时，鲲鹏 GCC
      可以继续随 ``np`` 增大改善到 ``np=128``，鲲鹏 BiSheng 在 ``np=64`` 附近触底，
      AMD 在 ``np=24`` 后不再继续改善。线程数或 MPI 数增加并不自动带来加速，
      未绑定运行和 NUMA 影响会改变曲线形状。

   .. rubric:: 测试模型

   本页是 ``tests/kunpeng_compare/D01_hypre_3Dxyz`` 的对比说明页。它复用 D01
   ``hypre_3Dxyz_bc`` 基准，在固定 ``320 x 80 x 320`` 网格上比较鲲鹏 GCC、
   鲲鹏 BiSheng 和 AMD 的性能。目录下有两个子测试：``test_OMP`` 固定
   ``4`` 个 MPI rank，扫描 OpenMP 线程数；``test_MPI`` 固定 ``OMP=1``，
   扫描 MPI 进程数。页面按这两个并行口径分别解释，不把它们混成同一条序列。

   .. rubric:: OpenMP 线程扫描

   .. rubric:: 运行环境

   这部分使用 ``test_OMP``。测试驱动固定 ``mpi_size = 4``，日志报告
   ``n_global = 6144000``；OpenMP 线程列表为
   ``1,2,4,6,8,10,12,14,16,20,22,24,26,28,30,32,48,64``，
   每个点重复 ``5`` 次并取均值。当前 D01 日志没有记录 ``lscpu``、
   ``/proc/cpuinfo`` 或 NUMA 拓扑，因此无法从本页直接确认 KP 和 AMD 的 CPU 型号、
   物理核心数、socket 数或 SMT 状态。运行脚本使用 ``mpirun --bind-to none``，
   并且没有设置 ``OMP_PROC_BIND``、``OMP_PLACES`` 或 ``OMP_DYNAMIC``，
   所以 rank 和线程都不是固定落点。

   .. list-table:: OMP 扫描参数
      :header-rows: 1
      :widths: 28 72

      * - 项目
        - 取值
      * - MPI rank
        - ``mpi_size = 4``
      * - 全局网格
        - 几何范围为 ``320 x 80 x 320``；4-rank 分区日志报告 ``n_global = 6144000``
      * - HYPRE 容差
        - ``1.0e-6``
      * - OpenMP 线程
        - ``1,2,4,6,8,10,12,14,16,20,22,24,26,28,30,32,48,64``
      * - 重复次数
        - 每个点重复 ``5`` 次并取均值

   .. rubric:: 测试结果

   .. figure:: ../../images/tests/kunpeng_compare/D01_hypre_3Dxyz_Comparison/time_3compares_np4.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide
      :target: ../../_images/time_3compares_np4.png

      ``np=4`` 时鲲鹏 GCC、鲲鹏 BiSheng 与 AMD 的时间对比，纵轴限制为
      ``0-14 s``。虚线为 HYPRE solve，实线为端到端总时间；AMD ``OMP=48``
      和 ``OMP=64`` 的异常值因超过上限被裁剪，具体数值应以日志和表格为准。

   .. list-table:: OMP 线程扫描的最佳重复均值
      :header-rows: 1
      :widths: 20 20 28 32

      * - 数据组
        - 最佳线程数
        - 最佳 HYPRE 时间
        - 最佳总时间
      * - 鲲鹏 GCC
        - ``OMP=14``
        - ``8.37466804e-01 s``
        - ``5.47168238e+00 s``
      * - 鲲鹏 BiSheng
        - ``OMP=22``
        - ``9.44460594e-01 s``
        - ``8.55064794e+00 s``
      * - AMD
        - ``OMP=14`` / ``OMP=12``
        - ``1.18674834e+00 s``
        - ``6.81510274e+00 s``

   OpenMP 扫描的日志内部诊断一致，三组环境都给出
   ``rho_l2=1.13137085e+02``、``phi_l2=4.75953652e+02``、
   ``phi_min=9.36912590e-07`` 和 ``phi_max=4.98805065e-01``。

   .. rubric:: 分析结论

   鲲鹏 GCC 的最佳 HYPRE 时间和最佳总时间都最低。鲲鹏 BiSheng 的 HYPRE 时间接近
   GCC，但总时间明显更高，说明求解后处理拖慢了端到端结果。AMD 的最佳总时间出现在
   ``OMP=12``，但从 ``OMP=32`` 开始，高线程端的 HYPRE 和总时间都快速恶化，
   因而不应把高线程点解读成可持续扩展区间。三组曲线的共同特征是：中等线程数
   能带来收益，但总时间提升远小于 solve 时间，端到端排序主要仍受 gather/write 影响。

   .. rubric:: 数据处理

   ``plot-time.py`` 读取 ``run_gcc_np4_omp*_*.log``、``run_bisheng_np4_omp*_*.log``
   和 ``run_AMD_np4_omp*_*.log``，对每个点的 5 次重复取均值，并生成
   ``time_3compares_np4.png``。当路径里存在 ``/mnt/e/kunpeng`` 时，它还会同步写出
   ``time_kp_amd_np4_ylim0_14.png``。页面把纵轴固定为 ``0-14 s``，是为了保留中低线程
   区间的可读性；AMD 的高线程异常值仍保留在原始日志和统计结果中，只是被图面裁剪。
   输出字段主要包括 ``compiler``、``np``、``omp``、``hypre_avg(s)``、``total_avg(s)`` 和
   ``gather_write_time``。

   .. rubric:: MPI 进程数扫描

   .. rubric:: 运行环境

   这部分使用 ``test_MPI``。测试固定 ``OMP_NUM_THREADS=1``，扫描
   ``np=1,2,4,8,16,24,32,48,64,128``；日志报告 ``n_global=8192000``，
   对应完整 ``320 x 80 x 320`` 网格。该测试使用 x-slab 分解，且日志中
   ``write_phi=0``，因此主要观察 HYPRE solve 随 MPI rank 增加的变化，不把
   大规模 ``phi.dat`` gather/write 混进曲线。当前日志同样没有记录 CPU 型号和 NUMA
   拓扑，运行时也使用 ``mpirun --bind-to none``，所以这里仍然是未绑定基线。

   .. list-table:: MPI 扫描参数
      :header-rows: 1
      :widths: 28 72

      * - 项目
        - 取值
      * - OpenMP 线程
        - ``OMP_NUM_THREADS = 1``
      * - MPI rank
        - ``1,2,4,8,16,24,32,48,64,128``
      * - 全局网格
        - ``n_global = 8192000``；对应完整 ``320 x 80 x 320`` 网格
      * - 输出策略
        - ``write_phi=0``
      * - 分解方式
        - x-slab 分解
      * - 重复次数
        - 每个点重复 ``5`` 次并取均值

   .. rubric:: 测试结果

   .. figure:: ../../images/tests/kunpeng_compare/D01_hypre_3Dxyz_Comparison/time_compare_gcc_bisheng_AMD_np_omp1.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide
      :target: ../../_images/time_compare_gcc_bisheng_AMD_np_omp1.png

      ``OMP=1`` 时鲲鹏 GCC、鲲鹏 BiSheng 与 AMD 的 HYPRE 平均时间随 MPI rank
      的变化。该图只绘制 HYPRE solve 平均时间；对应的 ``total_time`` 均值见下表。

   .. list-table:: MPI rank 扫描的最佳重复均值
      :header-rows: 1
      :widths: 18 22 30 30

      * - 数据组
        - 最佳 MPI rank
        - 最佳 HYPRE 时间
        - 对应总时间
      * - 鲲鹏 GCC
        - ``np=128``
        - ``8.73988344e-01 s``
        - ``8.78493008e-01 s``
      * - 鲲鹏 BiSheng
        - ``np=64``
        - ``1.21118856e+00 s``
        - ``1.21813115e+00 s``
      * - AMD
        - ``np=24``
        - ``2.65074565e+00 s``
        - ``2.66110870e+00 s``

   MPI 扫描的日志内部诊断也一致，给出相同的
   ``rho_l2=1.13137085e+02``，并给出 ``phi_l2=3.69023170e+02``、
   ``phi_min=9.28662532e-07`` 和 ``phi_max=4.97780785e-01``。

   .. rubric:: 分析结论

   MPI 扫描说明，在 ``OMP=1`` 条件下，鲲鹏 GCC 可以继续随 rank 增加改善到
   ``np=128``；鲲鹏 BiSheng 在 ``np=64`` 附近达到低点，之后回升；AMD 在
   ``np=24`` 后不再继续改善，``np=128`` 已经接近低 rank 的慢区间。由于这里固定
   ``OMP=1``，这张图反映的是 MPI rank 扩展趋势，不应和前面的 OpenMP 线程扫描
   直接混用。因为 ``write_phi=0``，这部分曲线更接近纯 solve 行为，能更清楚地看到
   rank 扩展本身的差异。

   .. rubric:: 数据处理

   ``plot-time-np.py`` 读取 ``run_gcc_np*_omp1_*.log``、
   ``run_bisheng_np*_omp1_*.log`` 和 ``run_AMD_np*_omp1_*.log``，生成
   ``time_compare_gcc_bisheng_AMD_np.csv`` 和
   ``time_compare_gcc_bisheng_AMD_np_omp1.png``。脚本按每个 ``np`` 点汇总重复均值，
   输出 HYPRE solve 和总时间的统计结果；CSV 同时保留标准差，便于查看点间波动。
   这里和 OMP 扫描一样，结果应按同一并行口径单独解读，不能把 ``phi_l2`` 或总时间
   跨图直接对比。

.. container:: ap-lang ap-lang-en ap-kunpeng-compare

   .. note:: Quick Take

      The OpenMP sweep at fixed 4 MPI ranks shows moderate HYPRE solve speedup
      at middle thread counts, but the end-to-end gain is much smaller. AMD
      degrades sharply after ``OMP=32``; ``OMP=48`` and ``OMP=64`` are clipped
      by the ``0-14 s`` y-axis. The MPI sweep at ``OMP=1`` shows Kunpeng GCC
      keeps improving through ``np=128``, Kunpeng BiSheng bottoms near
      ``np=64``, and AMD stops improving after ``np=24``. More threads or more
      ranks do not automatically mean faster runs, and unpinned execution plus
      NUMA effects can change the curve shape.

   .. rubric:: Test Model

   This page is the comparison guide for ``tests/kunpeng_compare/D01_hypre_3Dxyz``.
   It reuses the D01 ``hypre_3Dxyz_bc`` benchmark on a fixed ``320 x 80 x 320``
   grid. The directory has two subtests: ``test_OMP`` fixes 4 MPI ranks and
   scans OpenMP threads; ``test_MPI`` fixes ``OMP=1`` and scans MPI process
   counts. The two sweeps should be read separately.

   .. rubric:: OpenMP Thread Sweep

   .. rubric:: Runtime Environment

   This part uses ``test_OMP``. The driver fixes ``mpi_size = 4`` and the
   logs report ``n_global = 6144000``. The thread list is
   ``1,2,4,6,8,10,12,14,16,20,22,24,26,28,30,32,48,64`` and each point is
   repeated ``5`` times. The current logs do not record ``lscpu``,
   ``/proc/cpuinfo``, or NUMA topology, so the exact KP and AMD CPU models,
   core counts, and SMT state are not available here. The scripts use
   ``mpirun --bind-to none`` and do not set ``OMP_PROC_BIND``,
   ``OMP_PLACES``, or ``OMP_DYNAMIC``, so ranks and threads are not pinned.

   .. list-table:: OMP Sweep Parameters
      :header-rows: 1
      :widths: 28 72

      * - Item
        - Value
      * - MPI ranks
        - ``mpi_size = 4``
      * - Global grid
        - Geometric extent ``320 x 80 x 320``; the four-rank partition reports ``n_global = 6144000``
      * - HYPRE tolerance
        - ``1.0e-6``
      * - OpenMP threads
        - ``1,2,4,6,8,10,12,14,16,20,22,24,26,28,30,32,48,64``
      * - Repeats
        - ``5`` per point

   .. rubric:: Test Results

   .. figure:: ../../images/tests/kunpeng_compare/D01_hypre_3Dxyz_Comparison/time_3compares_np4.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide
      :target: ../../_images/time_3compares_np4.png

      Kunpeng GCC, Kunpeng BiSheng, and AMD at ``np=4`` with the y-axis
      limited to ``0-14 s``. Dashed lines show HYPRE solve time; solid lines
      show end-to-end total time. The AMD ``OMP=48`` and ``OMP=64`` outliers
      are clipped by the y-axis limit, so use the logs and table for exact
      values.

   .. list-table:: OMP Sweep Best Repeat Means
      :header-rows: 1
      :widths: 20 20 28 32

      * - Data group
        - Best thread count
        - Best HYPRE time
        - Best total time
      * - Kunpeng GCC
        - ``OMP=14``
        - ``8.37466804e-01 s``
        - ``5.47168238e+00 s``
      * - Kunpeng BiSheng
        - ``OMP=22``
        - ``9.44460594e-01 s``
        - ``8.55064794e+00 s``
      * - AMD
        - ``OMP=14`` / ``OMP=12``
        - ``1.18674834e+00 s``
        - ``6.81510274e+00 s``

   The OMP logs are internally consistent: all three environments report
   ``rho_l2=1.13137085e+02``, ``phi_l2=4.75953652e+02``,
   ``phi_min=9.36912590e-07``, and ``phi_max=4.98805065e-01``.

   .. rubric:: Analysis

   Kunpeng GCC has the lowest HYPRE time and the lowest end-to-end time.
   Kunpeng BiSheng is close to GCC for HYPRE time, but its total time is
   higher because post-solve work is heavier. AMD reaches its best total time
   at ``OMP=12``, but after ``OMP=32`` both HYPRE solve and total time
   degrade rapidly, so the high-thread region is not a useful scaling range.
   Overall, middle thread counts help, but end-to-end gains are much smaller
   than solve-time gains.

   .. rubric:: Data Processing

   ``plot-time.py`` reads ``run_gcc_np4_omp*_*.log``,
   ``run_bisheng_np4_omp*_*.log``, and ``run_AMD_np4_omp*_*.log``, averages
   the 5 repeats at each point, and writes ``time_3compares_np4.png``. When
   ``/mnt/e/kunpeng`` exists, it also writes
   ``time_kp_amd_np4_ylim0_14.png``. The y-axis is fixed to ``0-14 s`` to
   keep the middle-thread range readable; the AMD high-thread outliers remain
   in the raw logs and statistics. The output fields include ``compiler``,
   ``np``, ``omp``, ``hypre_avg(s)``, ``total_avg(s)``, and
   ``gather_write_time``.

   .. rubric:: MPI Rank Sweep

   .. rubric:: Runtime Environment

   This part uses ``test_MPI``. It fixes ``OMP_NUM_THREADS=1`` and scans
   ``np=1,2,4,8,16,24,32,48,64,128``. The logs report ``n_global=8192000``,
   which corresponds to the full ``320 x 80 x 320`` grid. The test uses
   x-slab partitioning and keeps ``write_phi=0``, so the curve focuses on
   HYPRE solve behavior. The logs still do not record CPU model or NUMA
   topology, and the run scripts use ``mpirun --bind-to none``, so this is an
   unpinned baseline as well.

   .. list-table:: MPI Sweep Parameters
      :header-rows: 1
      :widths: 28 72

      * - Item
        - Value
      * - OpenMP threads
        - ``OMP_NUM_THREADS = 1``
      * - MPI ranks
        - ``1,2,4,8,16,24,32,48,64,128``
      * - Global grid
        - ``n_global = 8192000``; full ``320 x 80 x 320`` grid
      * - Output policy
        - ``write_phi=0``
      * - Partitioning
        - x-slab partitioning
      * - Repeats
        - ``5`` per point

   .. rubric:: Test Results

   .. figure:: ../../images/tests/kunpeng_compare/D01_hypre_3Dxyz_Comparison/time_compare_gcc_bisheng_AMD_np_omp1.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide
      :target: ../../_images/time_compare_gcc_bisheng_AMD_np_omp1.png

      HYPRE average time versus MPI rank count for Kunpeng GCC, Kunpeng
      BiSheng, and AMD at ``OMP=1``. The figure plots HYPRE solve time only;
      the matching ``total_time`` means are listed in the table below.

   .. list-table:: MPI Sweep Best Repeat Means
      :header-rows: 1
      :widths: 18 22 30 30

      * - Data group
        - Best MPI rank
        - Best HYPRE time
        - Matching total time
      * - Kunpeng GCC
        - ``np=128``
        - ``8.73988344e-01 s``
        - ``8.78493008e-01 s``
      * - Kunpeng BiSheng
        - ``np=64``
        - ``1.21118856e+00 s``
        - ``1.21813115e+00 s``
      * - AMD
        - ``np=24``
        - ``2.65074565e+00 s``
        - ``2.66110870e+00 s``

   The MPI logs are also internally consistent. Representative logs report
   ``rho_l2=1.13137085e+02``, ``phi_l2=3.69023170e+02``,
   ``phi_min=9.28662532e-07``, and ``phi_max=4.97780785e-01``.

   .. rubric:: Analysis

   Kunpeng GCC keeps improving through ``np=128`` in this scan. Kunpeng
   BiSheng bottoms near ``np=64`` and rises again at ``np=128``. AMD reaches
   its minimum at ``np=24`` and then regresses, so ``np=128`` is already back
   near the slower low-rank region. Because this sweep fixes ``OMP=1`` and
   keeps ``write_phi=0``, it reflects MPI-rank scaling and should not be
   mixed with the OMP sweep.

   .. rubric:: Data Processing

   ``plot-time-np.py`` reads ``run_gcc_np*_omp1_*.log``,
   ``run_bisheng_np*_omp1_*.log``, and ``run_AMD_np*_omp1_*.log``, then
   generates ``time_compare_gcc_bisheng_AMD_np.csv`` and
   ``time_compare_gcc_bisheng_AMD_np_omp1.png``. It aggregates the repeated
   runs by ``np`` and keeps both mean and standard deviation in the CSV for
   later inspection. As with the OMP sweep, this output should be interpreted
   within the same parallelization mode; ``phi_l2`` and total time should not
   be compared directly across the two sweeps.
