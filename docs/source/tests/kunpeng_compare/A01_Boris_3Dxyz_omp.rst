A01_Boris_3Dxyz_omp Comparison
==============================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 测试目标

   本页说明 ``tests/kunpeng_compare/A01_Boris_3Dxyz_omp`` 中的性能对比测试。
   该测试比较同一个 OpenMP Boris pusher 主程序 ``boris_xyz_SoA_omp.f90`` 在
   AMD 服务器和鲲鹏服务器上的运行时间、吞吐率和并行加速比。

   这是平台性能对比，不是数值正确性回归测试。数值参数固定为：

   - ``np = 10000000``
   - ``nt = 100000``
   - 线程数 ``8,16,32,64,128,256,512``

   .. rubric:: 程序结构

   - ``source_f90/boris_xyz_SoA_omp.f90``：原始 Boris pusher OpenMP 测试主程序。
   - ``source_f90/make.sh``、``source_f90/run.sh``、``source_f90/clean.sh``：原始编译、运行和清理脚本。
   - ``data_raw/from_AMD/log*.run``：AMD 服务器原始运行日志。
   - ``data_raw/from_kunpeng/log*.run``：鲲鹏服务器原始运行日志。
   - ``source_py/analyze.py``：解析日志，生成 ``summary.csv`` 和对比图。

   .. rubric:: 运行方式

   .. code-block:: bash

      cd tests/kunpeng_compare/A01_Boris_3Dxyz_omp
      bash run.sh

   ``run.sh`` 只做后处理，不重新运行 Fortran 基准程序。若需要复现实验，可进入
   ``source_f90/`` 使用保留的原始脚本。

   .. rubric:: 输出字段

   ``output/summary.csv`` 每行对应一个平台和一个线程数：

   .. list-table::
      :header-rows: 1
      :widths: 26 54

      * - 字段
        - 含义
      * - ``platform``
        - ``AMD`` 或 ``Kunpeng``。
      * - ``threads``
        - OpenMP 线程数。
      * - ``total_wall_time_s``
        - 日志中的总 wall time，单位秒。
      * - ``compute_wall_time_s``
        - 日志中的 compute wall time，单位秒。
      * - ``throughput_gpushes_s``
        - 吞吐率，单位为 G particle-pushes/s，计算为 ``np*nt/compute_wall_time``。
      * - ``speedup_vs_8``
        - 同一平台相对 8 线程的加速比。
      * - ``parallel_efficiency_vs_8``
        - 同一平台相对 8 线程的并行效率。
      * - ``kunpeng_speed_vs_AMD``
        - 同线程数下 ``AMD compute time / Kunpeng compute time``。

   .. rubric:: 参考图

   .. figure:: ../../images/tests/kunpeng_compare/A01_Boris_3Dxyz_omp/wall_time_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-readable

      计算时间对比。横轴为 OpenMP 线程数，纵轴为 ``Compute wall time``，时间越短表示越快。

   .. figure:: ../../images/tests/kunpeng_compare/A01_Boris_3Dxyz_omp/throughput_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-readable

      吞吐率对比。横轴为 OpenMP 线程数，纵轴为 G particle-pushes/s，数值越高表示单位时间完成的粒子推进越多。

   .. figure:: ../../images/tests/kunpeng_compare/A01_Boris_3Dxyz_omp/speedup_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-readable

      并行扩展性对比。横轴为 OpenMP 线程数，纵轴为相对 8 线程的加速比。

   .. rubric:: 参考结果

   当前日志中，鲲鹏服务器在 8、16、64、128、512 线程下更快；AMD 服务器在 32、256
   线程下更快。该现象应结合机器硬件配置、线程绑定、NUMA 策略和运行时环境进一步解释。

.. container:: ap-lang ap-lang-en

   .. rubric:: Test Goal

   This page documents the performance comparison under
   ``tests/kunpeng_compare/A01_Boris_3Dxyz_omp``. The case compares the same
   OpenMP Boris pusher program, ``boris_xyz_SoA_omp.f90``, on the AMD server
   and the Kunpeng server.

   This is a platform performance comparison, not a numerical correctness
   regression test. The fixed workload is:

   - ``np = 10000000``
   - ``nt = 100000``
   - OpenMP threads ``8,16,32,64,128,256,512``

   .. rubric:: Program Structure

   - ``source_f90/boris_xyz_SoA_omp.f90``: original OpenMP Boris pusher benchmark.
   - ``source_f90/make.sh``, ``source_f90/run.sh``, ``source_f90/clean.sh``: original build/run/clean scripts.
   - ``data_raw/from_AMD/log*.run``: raw logs from the AMD server.
   - ``data_raw/from_kunpeng/log*.run``: raw logs from the Kunpeng server.
   - ``source_py/analyze.py``: parses logs and writes ``summary.csv`` plus figures.

   .. rubric:: Run Command

   .. code-block:: bash

      cd tests/kunpeng_compare/A01_Boris_3Dxyz_omp
      bash run.sh

   ``run.sh`` only post-processes existing logs. To reproduce the benchmark,
   use the original scripts kept under ``source_f90/``.

   .. rubric:: Output Fields

   Each row in ``output/summary.csv`` is one platform/thread-count result.

   .. list-table::
      :header-rows: 1
      :widths: 26 54

      * - Field
        - Meaning
      * - ``platform``
        - ``AMD`` or ``Kunpeng``.
      * - ``threads``
        - OpenMP thread count.
      * - ``total_wall_time_s``
        - Total wall time from the log, in seconds.
      * - ``compute_wall_time_s``
        - Compute wall time from the log, in seconds.
      * - ``throughput_gpushes_s``
        - Throughput in G particle-pushes/s, computed as ``np*nt/compute_wall_time``.
      * - ``speedup_vs_8``
        - Speedup relative to the same platform's 8-thread run.
      * - ``parallel_efficiency_vs_8``
        - Parallel efficiency relative to the 8-thread baseline.
      * - ``kunpeng_speed_vs_AMD``
        - ``AMD compute time / Kunpeng compute time`` at the same thread count.

   .. rubric:: Reference Figures

   .. figure:: ../../images/tests/kunpeng_compare/A01_Boris_3Dxyz_omp/wall_time_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-readable

      Compute-time comparison. x-axis: OpenMP threads. y-axis: compute wall time
      in seconds. Lower is faster.

   .. figure:: ../../images/tests/kunpeng_compare/A01_Boris_3Dxyz_omp/throughput_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-readable

      Throughput comparison. x-axis: OpenMP threads. y-axis:
      G particle-pushes/s. Higher is faster.

   .. figure:: ../../images/tests/kunpeng_compare/A01_Boris_3Dxyz_omp/speedup_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-readable

      Scaling comparison. x-axis: OpenMP threads. y-axis: speedup relative to
      the same platform's 8-thread run.

   .. rubric:: Reference Result

   In the current logs, Kunpeng is faster at 8, 16, 64, 128, and 512 threads;
   the AMD server is faster at 32 and 256 threads. Interpreting this pattern
   requires the hardware configuration, thread binding, NUMA policy, and runtime
   environment.
