E_Maxwell E03 FDTD 3D Cartesian Comparison
==========================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-e03 ap-kunpeng-compare

   .. note:: 快速结论

      本页 workload 是 ``160^3`` 网格、每次 repeat 连续 100 步、共 5 次 repeat，
      线程扫描为 ``1-256``。当前这批数据里最快点是
      ``Kunpeng BiSheng ompdo`` 的 224 线程，平均单步耗时 ``8.733e-04 s``；
      但高线程重复波动较大，需要复跑确认。五条曲线同时改变了编译器、kernel 写法
      和线程绑定，因此应把它们理解为“完整配置组合”，而不是单一 CPU 或编译器变量。

   .. rubric:: 测试目标

   本页整理 ``tests/kunpeng_compare/E_Maxwell/E03_fdtd_3d_cartesian`` 的
   3D Cartesian Maxwell/FDTD 场更新性能对比。测试只覆盖
   ``sub_E03_fdtd_3d_cartesian_H/E`` 这两个场更新 kernel，不包含粒子、
   MPI 通信、边界交换、I/O 或完整 PIC 流程。

   统一测试规模为：

   .. code-block:: text

      NX NY NZ NSTEPS REPEATS = 160 160 160 100 5
      THREAD_LIST = 1 2 4 8 12 16 24 32 40 48 56 64 80 96 112 128 160 192 224 256

   每次 repeat 会重新初始化一组三维 E/H 场，然后连续执行 100 个时间步。
   每个时间步依次更新 ``Hx/Hy/Hz`` 和 ``Ex/Ey/Ez``。计时结果中的
   ``single_step_avg_s`` 是 ``avg_s / NSTEPS``，即平均每个时间步耗时。

   .. rubric:: 对比配置

   .. csv-table::
      :header: "配置", "结果目录", "编译器", "核心形式", "OMP 绑定"
      :widths: 20 22 28 20 10

      "AMD 原版", "``data_raw/amd``", "``gfortran 13.3.0``", "``parallel do collapse(3)``", "``close``"
      "AMD ompdo", "``data_raw/amd_ompdo``", "``gfortran 13.3.0``", "外层 ``parallel`` + H/E ``omp do``", "``close``"
      "Kunpeng gcc/mpifort", "``data_raw/kunpeng``", "``/usr/bin/mpifort`` + GNU Fortran 10.3.1", "``parallel do collapse(3)``", "``spread``"
      "Kunpeng BiSheng", "``data_raw/kunpeng_optimized``", "BiSheng ``flang 19.1.7``", "``parallel do collapse(3)``", "``spread``"
      "Kunpeng BiSheng ompdo", "``data_raw/kunpeng_ompdo``", "BiSheng ``flang 19.1.7``", "外层 ``parallel`` + H/E ``omp do``", "``close``"

   所有配置的 checksum 只存在浮点末位差异，说明各平台跑的是同一组计算。

   .. important:: 比较口径

      本页五种配置并非严格的单变量实验：例如 AMD 与鲲鹏的编译器、OpenMP runtime
      和绑定策略不同，原版与 ompdo 又改变了并行区结构。因此图可以回答“哪套完整配置
      在当前环境更快”，但不能单独证明某个 CPU、编译器或绑定策略贡献了全部差异。

   .. rubric:: 优化项和 ompdo 含义

   这页里的“优化”主要分成三类：编译器/编译选项、OpenMP 并行区域写法、
   线程绑定策略。

   .. csv-table::
      :header: "配置", "相对基线的主要变化", "目的"
      :widths: 22 40 38

      "AMD 原版", "``gfortran -O3 -fopenmp``，H/E kernel 内部各自 ``parallel do collapse(3)``", "作为 AMD 基线"
      "AMD ompdo", "增加 ``-DALGOPLASMA_E03_USE_OMPDO``，改成外层 ``parallel`` + H/E 内部 ``omp do``", "减少反复进入 OpenMP parallel region 的开销"
      "Kunpeng gcc/mpifort", "鲲鹏环境下使用 GNU Fortran wrapper，并加 ``-mcpu=native`` 和 ``OMP_PROC_BIND=spread``", "作为鲲鹏 GNU 工具链基线"
      "Kunpeng BiSheng", "换成 BiSheng ``flang``，保留 ``-mcpu=native`` 和 ``OMP_PROC_BIND=spread``", "看鲲鹏专用编译器对同一 kernel 的收益"
      "Kunpeng BiSheng ompdo", "BiSheng ``flang`` + ``-DALGOPLASMA_E03_USE_OMPDO``", "同时测试编译器优化和 OpenMP 并行区域优化"

   这里容易混的一点是：``-mcpu`` 属于编译选项，``OMP_PROC_BIND``、
   ``OMP_PLACES`` 和 ``OMP_DYNAMIC`` 属于 OpenMP 运行时环境变量。它们不是
   flang 独有，也不是 gfortran 独有。

   .. csv-table::
      :header: "项目", "这里的用法", "是否 flang 专属"
      :widths: 24 48 28

      "``-mcpu=native``", "让编译器按当前鲲鹏 CPU 生成和调度代码；脚本里可用 ``KUNPENG_MCPU`` 改成具体 CPU 名称", "不是。本页 GNU 和 BiSheng 脚本都用了它；换到 x86 等架构时可能要改用 ``-march``/``-mtune``"
      "``-cpp`` / ``-DALGOPLASMA_E03_USE_OMPDO``", "开启预处理，并用宏切换到 ompdo 版本", "不是。gfortran 和这套 BiSheng ``flang`` 都接受这类 GNU 风格选项"
      "``-O3`` / ``-fopenmp``", "打开优化和 OpenMP 编译支持", "不是。两边都有对应支持；性能差异主要来自编译器后端和 OpenMP runtime 实现"
      "``-fdefault-real-8`` / ``-ffree-line-length-none``", "保持默认 ``real`` 为 8 字节，并放宽 Fortran 自由格式行长", "不是。这里使用的是两边都接受的 GNU 风格选项"
      "``OMP_NUM_THREADS``", "由 ``THREAD_LIST`` 扫描得到，控制每次运行使用的 OpenMP 线程数", "不是编译选项，而是 OpenMP 运行时变量"
      "``OMP_PROC_BIND=spread/close``", "控制线程和 CPU core 的绑定策略；``spread`` 倾向分散，``close`` 倾向相邻", "不是编译选项，而是 OpenMP 运行时变量；gfortran 和 flang 的 OpenMP runtime 都会读取"
      "``OMP_PLACES=cores`` / ``OMP_DYNAMIC=false``", "指定绑定位置按 core 计，并关闭运行时动态改线程数", "不是编译选项，也是 OpenMP 运行时变量"

   所以本文里的 BiSheng ``flang`` 优化不是靠“flang 独有 flag”完成的，而是
   在大体相同的 GNU 风格编译选项和 OpenMP 运行参数下，比较 BiSheng flang
   与 GNU Fortran wrapper 在鲲鹏 CPU 上生成代码和运行时行为的差异。

   ``ompdo`` 不是 OpenMP 标准里的一个新语法，而是这里给这版 kernel 起的名字。
   原版是每次调用 H kernel、E kernel 时，各自在子程序里进入一次
   ``!$omp parallel do collapse(3)``。``ompdo`` 版是在时间步循环外面先进入一次
   ``!$omp parallel``，然后 H/E 子程序里只写 ``!$omp do collapse(3)``。这样 H
   仍然先更新，E 仍然后更新，中间默认有 OpenMP barrier，只是线程队伍不用在每个
   H/E kernel 里反复创建和销毁。

   .. rubric:: 参考图

   下面几张图画的是性能量，不是电磁场本身的物理量。``single_step_avg_s``
   表示一次 repeat 的 wall time 除以 ``NSTEPS``，单位是秒；相对 AMD 原版耗时
   表示同线程数下 ``当前配置耗时 / AMD 原版耗时 * 100%``。selected threads
   图里的虚线是各配置自己的 ``1 线程耗时 / 线程数``，只用来表示理想时间缩放。

   初学者可以按以下顺序阅读：先看全线程图找最低点和反弹区间，再看精选线程图比较
   实线与理想虚线的距离，最后看相对 AMD 图判断同线程配置快慢。耗时越低越好；
   相对耗时低于 ``100%`` 表示比 AMD 原版快。点击任意图片可查看原始尺寸。

   .. figure:: ../../images/tests/kunpeng_compare/E_Maxwell_E03_fdtd_3d_cartesian/time_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide
      :target: ../../_images/time_vs_threads1.png

      全部线程档位的平均单步耗时。纵轴越低越快；可用来找每条曲线的最低点和高线程回退。

   .. figure:: ../../images/tests/kunpeng_compare/E_Maxwell_E03_fdtd_3d_cartesian/time_vs_selected_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide
      :target: ../../_images/time_vs_selected_threads.png

      只保留 ``1, 2, 4, 8, 16, 32, 64, 128, 256`` 线程档位的平均单步耗时，
      便于观察常用 2 倍线程扩展路径。图里的同色虚线是该配置自己的
      ``1 线程耗时 / 线程数``，也就是“如果时间完全按线程数下降”时的理想耗时。

   .. figure:: ../../images/tests/kunpeng_compare/E_Maxwell_E03_fdtd_3d_cartesian/relative_time_vs_amd.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide
      :target: ../../_images/relative_time_vs_amd.png

      同线程下相对 AMD 原版的耗时百分比。``100%`` 是 AMD 原版；低于
      ``100%`` 表示比 AMD 原版快，高于 ``100%`` 表示更慢。

   .. rubric:: 先看三个代表线程点

   .. csv-table:: single_step_avg_s（秒）
      :header: "线程", "AMD 原版", "AMD ompdo", "鲲鹏 GCC", "鲲鹏 BiSheng", "鲲鹏 BiSheng ompdo"
      :widths: 10 18 18 18 20 24

      "32", "3.901e-03", "3.686e-03", "4.740e-03", "2.744e-03", "4.182e-03"
      "64", "2.191e-03", "1.267e-03", "4.048e-03", "1.672e-03", "2.117e-03"
      "224", "1.522e-03", "1.201e-03", "5.913e-03", "1.169e-03", "8.733e-04"

   32 线程时，稳定的 BiSheng 原版最快；64 线程时 AMD ompdo 最快；224 线程时
   鲲鹏 BiSheng ompdo 给出全表最低均值。单点冠军会随线程数改变，因此应该结合
   整条曲线判断，而不是只比较一个线程档位。

   .. rubric:: 再看整体并行效果

   - **低线程 1–16：** 五种配置总体都随线程数增加而下降，说明场更新 kernel
     有明确并行性。AMD ompdo 在 1–4 线程已经比 AMD 原版快约三倍，表明减少反复
     进入 parallel region 对短时 kernel 尤其重要。
   - **中线程 24–80：** AMD 原版、AMD ompdo 和鲲鹏 BiSheng 继续获得收益；
     鲲鹏 GCC 在 48 线程附近触底，之后不再稳定下降。鲲鹏 BiSheng ompdo 在
     80 线程出现明显低点，但相邻点波动较大。
   - **高线程 96–256：** AMD 原版和鲲鹏 BiSheng 仍缓慢改善；鲲鹏 GCC 明显退化；
     两条 ompdo 曲线保持较低耗时，但不再单调，说明并行区开销已不再是唯一瓶颈。
   - 所有实线在高线程都逐渐偏离各自的理想虚线，表示并行效率随线程数增加而下降。

   .. rubric:: 可能原因与结论边界

   ``ompdo`` 能直接减少每个时间步反复创建/销毁 H、E 线程队伍的次数，这是源码可以
   确认的机制；AMD 和鲲鹏都从中受益，所以它是 kernel 级优化，不是鲲鹏专属技巧。

   鲲鹏 GCC 高线程退化、BiSheng 与 AMD 的差异还可能来自编译器代码生成、OpenMP
   runtime、``spread``/``close`` 绑定、NUMA 距离和内存带宽。由于这些变量没有被逐项
   控制，当前图不能确定其中哪一项占主导。224/256 线程的重复波动还说明最快点可能受
   系统噪声影响；使用它作为最终性能结论前，应固定绑定并复跑，同时报告误差范围。

   .. rubric:: 最佳结果

   .. csv-table::
      :header: "配置", "最佳线程", "single_step_avg_s", "吞吐", "相对自身 1 线程加速"
      :widths: 24 14 20 20 22

      "AMD 原版", "256", "1.411e-03", "1.677e+10", "77.06x"
      "AMD ompdo", "128", "1.076e-03", "2.200e+10", "34.30x"
      "Kunpeng gcc/mpifort", "48", "3.802e-03", "6.224e+09", "27.38x"
      "Kunpeng BiSheng", "256", "1.060e-03", "2.232e+10", "74.09x"
      "Kunpeng BiSheng ompdo", "224", "8.733e-04", "2.710e+10", "53.24x"

   这批数据里，平均最快的是 ``Kunpeng BiSheng ompdo`` 的 224 线程，
   单步耗时 ``8.733e-04 s``。不过它在 224/256 线程的 repeat 波动较大；
   作为结论使用前建议复跑确认。

   .. rubric:: 综合结论

   1. ``Kunpeng gcc/mpifort`` 在高线程下明显退化，不适合作为当前 E03
      高线程性能主结果。
   2. ``Kunpeng BiSheng`` 是更稳定的鲲鹏配置，在绝大多数线程档位低于 AMD 原版，
      耗时通常约为 AMD 原版的 ``55%–78%``。
   3. ``Kunpeng BiSheng ompdo`` 给出当前最高平均吞吐，但 224/256 线程重复波动较大，
      应视为有潜力、仍需确认的调优方向。
   4. ``AMD ompdo`` 同样非常有效，证明外层 ``parallel`` + H/E ``omp do`` 是
      跨平台 kernel 优化。公平比较时应保留两边对应版本。

   .. rubric:: 复现命令

   从 ``tests/kunpeng_compare/E_Maxwell`` 目录运行。下面命令对应本文这批数据的
   网格、步数、repeat 和线程列表：

   .. code-block:: bash

      cd tests/kunpeng_compare/E_Maxwell
      export THREAD_LIST="1 2 4 8 12 16 24 32 40 48 56 64 80 96 112 128 160 192 224 256"

      ./run_amd.sh 160 160 160 100 5
      ./run_amd_ompdo.sh 160 160 160 100 5
      ./run_kunpeng.sh 160 160 160 100 5
      ./run_kunpeng_optimized.sh 160 160 160 100 5
      ./run_kunpeng_ompdo.sh 160 160 160 100 5

   结果分别写到 ``E03_fdtd_3d_cartesian/data_raw/amd``、``amd_ompdo``、
   ``kunpeng``、``kunpeng_optimized`` 和 ``kunpeng_ompdo``。
   ``run_kunpeng_optimized.sh`` 和 ``run_kunpeng_ompdo.sh`` 优先加载鲲鹏服务器的
   BiSheng 工具链；若环境已经设置 ``FC``，则使用当前 ``FC``。

   .. rubric:: 原始单步耗时

   下表是 ``single_step_avg_s``，单位为秒：

   .. csv-table::
      :header: "线程", "AMD 原版", "AMD ompdo", "Kunpeng gcc/mpifort", "Kunpeng BiSheng", "Kunpeng BiSheng ompdo"
      :widths: 10 18 18 22 20 24

      "1", "1.087e-01", "3.690e-02", "1.041e-01", "7.857e-02", "4.649e-02"
      "2", "5.478e-02", "1.878e-02", "5.318e-02", "3.809e-02", "2.662e-02"
      "4", "2.748e-02", "9.628e-03", "2.775e-02", "1.887e-02", "1.951e-02"
      "8", "1.396e-02", "8.463e-03", "1.415e-02", "9.918e-03", "1.077e-02"
      "12", "9.589e-03", "8.402e-03", "9.774e-03", "6.683e-03", "7.747e-03"
      "16", "8.896e-03", "8.541e-03", "7.419e-03", "5.000e-03", "6.153e-03"
      "24", "6.073e-03", "5.737e-03", "5.771e-03", "3.505e-03", "4.861e-03"
      "32", "3.901e-03", "3.686e-03", "4.740e-03", "2.744e-03", "4.182e-03"
      "40", "3.046e-03", "2.584e-03", "4.214e-03", "2.330e-03", "3.828e-03"
      "48", "2.617e-03", "1.937e-03", "3.802e-03", "2.026e-03", "3.213e-03"
      "56", "2.385e-03", "1.553e-03", "4.107e-03", "1.824e-03", "2.628e-03"
      "64", "2.191e-03", "1.267e-03", "4.048e-03", "1.672e-03", "2.117e-03"
      "80", "2.246e-03", "1.235e-03", "4.191e-03", "1.466e-03", "9.221e-04"
      "96", "1.759e-03", "1.164e-03", "4.555e-03", "1.370e-03", "1.051e-03"
      "112", "1.761e-03", "1.144e-03", "4.165e-03", "1.305e-03", "1.076e-03"
      "128", "1.636e-03", "1.076e-03", "4.559e-03", "1.274e-03", "1.170e-03"
      "160", "1.943e-03", "1.603e-03", "3.880e-03", "1.396e-03", "1.057e-03"
      "192", "1.696e-03", "1.371e-03", "5.519e-03", "1.255e-03", "1.206e-03"
      "224", "1.522e-03", "1.201e-03", "5.913e-03", "1.169e-03", "8.733e-04"
      "256", "1.411e-03", "1.077e-03", "4.983e-03", "1.060e-03", "9.516e-04"

   .. rubric:: 相对 AMD 原版耗时

   下表以“同线程下 AMD 原版耗时 = 100%”计算：

   .. csv-table::
      :header: "线程", "AMD 原版", "AMD ompdo", "Kunpeng gcc/mpifort", "Kunpeng BiSheng", "Kunpeng BiSheng ompdo"
      :widths: 10 18 18 22 20 24

      "1", "100.00%", "33.95%", "95.75%", "72.27%", "42.77%"
      "2", "100.00%", "34.29%", "97.08%", "69.52%", "48.60%"
      "4", "100.00%", "35.03%", "100.98%", "68.67%", "70.99%"
      "8", "100.00%", "60.60%", "101.29%", "71.02%", "77.14%"
      "12", "100.00%", "87.62%", "101.93%", "69.69%", "80.79%"
      "16", "100.00%", "96.02%", "83.41%", "56.20%", "69.16%"
      "24", "100.00%", "94.47%", "95.03%", "57.71%", "80.05%"
      "32", "100.00%", "94.48%", "121.49%", "70.33%", "107.21%"
      "40", "100.00%", "84.84%", "138.36%", "76.48%", "125.68%"
      "48", "100.00%", "74.04%", "145.31%", "77.45%", "122.77%"
      "56", "100.00%", "65.10%", "172.19%", "76.47%", "110.19%"
      "64", "100.00%", "57.83%", "184.81%", "76.33%", "96.62%"
      "80", "100.00%", "54.96%", "186.56%", "65.27%", "41.05%"
      "96", "100.00%", "66.16%", "258.95%", "77.86%", "59.76%"
      "112", "100.00%", "64.95%", "236.48%", "74.11%", "61.08%"
      "128", "100.00%", "65.78%", "278.77%", "77.92%", "71.54%"
      "160", "100.00%", "82.50%", "199.71%", "71.83%", "54.40%"
      "192", "100.00%", "80.85%", "325.43%", "74.01%", "71.10%"
      "224", "100.00%", "78.89%", "388.49%", "76.79%", "57.37%"
      "256", "100.00%", "76.31%", "353.19%", "75.16%", "67.45%"

.. container:: ap-lang ap-lang-en ap-e03 ap-kunpeng-compare

   .. note:: Quick take

      The workload is a ``160^3`` grid, 100 time steps per repeat, 5 repeats,
      and a ``1-256`` thread sweep. In this dataset, the fastest point is
      ``Kunpeng BiSheng ompdo`` at 224 threads, with ``8.733e-04 s`` per step,
      but high-thread repeats are noisy and need confirmation. Compiler, kernel
      form, and binding change together across the five curves, so they represent
      complete configurations rather than one isolated CPU or compiler variable.

   .. rubric:: Test Goal

   This page summarizes the
   ``tests/kunpeng_compare/E_Maxwell/E03_fdtd_3d_cartesian`` benchmark. The
   case measures only the E03 3D Cartesian Maxwell/FDTD H/E update kernels. It
   does not include particles, MPI exchange, boundary processing, I/O, or a full
   PIC workflow.

   The common workload is ``160 160 160 100 5``: a ``160^3`` grid, 100 time
   steps per repeat, and 5 repeats per thread count. The thread sweep is:

   .. code-block:: text

      1 2 4 8 12 16 24 32 40 48 56 64 80 96 112 128 160 192 224 256

   .. rubric:: Configurations

   .. csv-table::
      :header: "Configuration", "Result directory", "Compiler", "Kernel form", "Binding"
      :widths: 22 22 28 20 10

      "AMD original", "``data_raw/amd``", "``gfortran 13.3.0``", "``parallel do collapse(3)``", "``close``"
      "AMD ompdo", "``data_raw/amd_ompdo``", "``gfortran 13.3.0``", "outer ``parallel`` + H/E ``omp do``", "``close``"
      "Kunpeng GCC/mpifort", "``data_raw/kunpeng``", "``/usr/bin/mpifort`` + GNU Fortran 10.3.1", "``parallel do collapse(3)``", "``spread``"
      "Kunpeng BiSheng", "``data_raw/kunpeng_optimized``", "BiSheng ``flang 19.1.7``", "``parallel do collapse(3)``", "``spread``"
      "Kunpeng BiSheng ompdo", "``data_raw/kunpeng_ompdo``", "BiSheng ``flang 19.1.7``", "outer ``parallel`` + H/E ``omp do``", "``close``"

   .. important:: Comparison scope

      The five configurations are not a strict one-variable experiment. AMD and
      Kunpeng differ in compiler, OpenMP runtime, and binding; original and ompdo
      also differ in parallel-region structure. The figures show which complete
      configuration is faster here, but they cannot assign the full difference
      to one CPU, compiler, or binding policy.

   .. rubric:: Optimizations and ompdo Meaning

   The differences in this page fall into three groups: compiler/options,
   OpenMP region structure, and thread binding.

   .. csv-table::
      :header: "Configuration", "Main change from the baseline", "Purpose"
      :widths: 22 40 38

      "AMD original", "``gfortran -O3 -fopenmp`` with H/E kernels using their own ``parallel do collapse(3)``", "AMD baseline"
      "AMD ompdo", "Adds ``-DALGOPLASMA_E03_USE_OMPDO`` and uses one outer ``parallel`` region plus H/E ``omp do`` loops", "Reduce repeated OpenMP parallel-region entry cost"
      "Kunpeng GCC/mpifort", "GNU Fortran wrapper on Kunpeng with ``-mcpu=native`` and ``OMP_PROC_BIND=spread``", "Kunpeng GNU-toolchain baseline"
      "Kunpeng BiSheng", "Uses BiSheng ``flang`` with ``-mcpu=native`` and ``OMP_PROC_BIND=spread``", "Measure the compiler/toolchain effect on Kunpeng"
      "Kunpeng BiSheng ompdo", "BiSheng ``flang`` plus ``-DALGOPLASMA_E03_USE_OMPDO``", "Combine the compiler change with the OpenMP-region change"

   One detail is easy to mix up: ``-mcpu`` is a compiler option, while
   ``OMP_PROC_BIND``, ``OMP_PLACES``, and ``OMP_DYNAMIC`` are OpenMP runtime
   environment variables. They are not flang-only or gfortran-only.

   .. csv-table::
      :header: "Item", "Use in this benchmark", "flang-only?"
      :widths: 24 48 28

      "``-mcpu=native``", "Generate and tune code for the local Kunpeng CPU; ``KUNPENG_MCPU`` can override the CPU value", "No. This page uses it in both GNU and BiSheng scripts; on other architectures the spelling may become ``-march``/``-mtune``"
      "``-cpp`` / ``-DALGOPLASMA_E03_USE_OMPDO``", "Enable preprocessing and switch to the ompdo kernel variant with a macro", "No. gfortran and this BiSheng ``flang`` accept these GNU-style options"
      "``-O3`` / ``-fopenmp``", "Enable optimization and OpenMP compilation", "No. Both sides support corresponding options; performance differences mainly come from the compiler backend and OpenMP runtime"
      "``-fdefault-real-8`` / ``-ffree-line-length-none``", "Use 8-byte default ``real`` and relax free-form source line length", "No. These are GNU-style options accepted by both toolchains used here"
      "``OMP_NUM_THREADS``", "Set from ``THREAD_LIST`` for each sweep point", "No. It is an OpenMP runtime variable, not a compiler option"
      "``OMP_PROC_BIND=spread/close``", "Control thread binding to CPU cores; ``spread`` distributes threads, while ``close`` keeps them near each other", "No. It is an OpenMP runtime variable read by both gfortran and flang OpenMP runtimes"
      "``OMP_PLACES=cores`` / ``OMP_DYNAMIC=false``", "Bind against core places and disable dynamic runtime thread-count changes", "No. These are also OpenMP runtime variables"

   So the BiSheng ``flang`` result here should not be read as a flang-only flag
   experiment. It compares BiSheng flang and the GNU Fortran wrapper on Kunpeng
   using mostly the same GNU-style compiler options and OpenMP runtime settings.

   ``ompdo`` is only this benchmark's name for the alternate kernel form. It is
   not a new OpenMP directive. The original form enters ``!$omp parallel do
   collapse(3)`` inside each H and E kernel call. The ompdo form enters one
   outer ``!$omp parallel`` region around the time-step loop, then each H/E
   kernel uses ``!$omp do collapse(3)``. H is still updated before E, and the
   default OpenMP barrier between worksharing loops preserves that order; the
   main change is avoiding repeated thread-team creation around every H/E
   kernel call.

   .. rubric:: Figures

   These figures show performance quantities, not the E/H field values.
   ``single_step_avg_s`` is the repeat wall time divided by ``NSTEPS``, in
   seconds; relative time is ``current configuration time / AMD original time
   at the same thread count * 100%``. In the selected-thread figure, the dashed
   lines are each configuration's own ``T1 / threads`` ideal-time reference.

   A beginner-friendly order is: use the full sweep to find minima and rebound,
   compare solid curves with ideal dashed lines in the selected-thread view,
   and then use the relative plot for equal-thread configuration comparisons.
   Lower time is better; relative time below ``100%`` beats AMD original. Click
   any figure to open it at original size.

   .. figure:: ../../images/tests/kunpeng_compare/E_Maxwell_E03_fdtd_3d_cartesian/time_vs_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide
      :target: ../../_images/time_vs_threads1.png

      Average single-step time for all thread counts. Lower is better; use this
      view to find minima and high-thread regression.

   .. figure:: ../../images/tests/kunpeng_compare/E_Maxwell_E03_fdtd_3d_cartesian/time_vs_selected_threads.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide
      :target: ../../_images/time_vs_selected_threads.png

      Average single-step time for the selected power-of-two-style thread
      counts: ``1, 2, 4, 8, 16, 32, 64, 128, 256``. The dashed same-color
      lines are each configuration's own ``T1 / threads`` ideal-time reference.

   .. figure:: ../../images/tests/kunpeng_compare/E_Maxwell_E03_fdtd_3d_cartesian/relative_time_vs_amd.png
      :align: center
      :figclass: ap-figure-equal-height ap-figure-wide
      :target: ../../_images/relative_time_vs_amd.png

      Time relative to AMD original at the same thread count.

   .. rubric:: Three Representative Thread Counts

   .. csv-table:: ``single_step_avg_s`` (seconds)
      :header: "Threads", "AMD original", "AMD ompdo", "Kunpeng GCC", "Kunpeng BiSheng", "Kunpeng BiSheng ompdo"
      :widths: 10 18 18 18 20 24

      "32", "3.901e-03", "3.686e-03", "4.740e-03", "2.744e-03", "4.182e-03"
      "64", "2.191e-03", "1.267e-03", "4.048e-03", "1.672e-03", "2.117e-03"
      "224", "1.522e-03", "1.201e-03", "5.913e-03", "1.169e-03", "8.733e-04"

   Stable BiSheng is fastest at 32 threads, AMD ompdo at 64, and Kunpeng
   BiSheng ompdo produces the lowest value in the entire table at 224. The
   winner changes with thread count, so the full curves matter more than one point.

   .. rubric:: Overall Parallel Behavior

   - **Low threads, 1–16:** all five configurations generally improve, confirming
     useful parallelism in the field-update kernel. AMD ompdo is already about
     three times faster than AMD original at 1–4 threads, showing that repeated
     parallel-region entry is important for short kernels.
   - **Middle threads, 24–80:** AMD original, AMD ompdo, and Kunpeng BiSheng keep
     improving. Kunpeng GCC bottoms near 48 threads and then stops decreasing
     reliably. Kunpeng BiSheng ompdo has a sharp low point at 80, with noisy neighbors.
   - **High threads, 96–256:** AMD original and Kunpeng BiSheng improve slowly;
     Kunpeng GCC degrades. Both ompdo curves stay low but are no longer monotonic,
     so parallel-region overhead is no longer the only bottleneck.
   - All measured curves gradually separate from their own ideal dashed lines at
     high thread counts, which means parallel efficiency is falling.

   .. rubric:: Possible Causes and Limits

   The source directly confirms that ompdo avoids repeatedly creating and
   destroying H/E thread teams on every time step. Both AMD and Kunpeng benefit,
   so this is a kernel-level optimization rather than a Kunpeng-only technique.

   Kunpeng GCC's high-thread regression and the remaining platform differences
   may involve compiler code generation, OpenMP runtime behavior, ``spread`` versus
   ``close`` placement, NUMA distance, and memory bandwidth. These variables were
   not isolated, so the figure cannot identify one dominant cause. Noisy 224/256
   repeats also mean the fastest point may include system noise; final reporting
   should use fixed placement, reruns, and an error range.

   .. rubric:: Best Results

   .. csv-table::
      :header: "Configuration", "Best threads", "single_step_avg_s", "Throughput", "Speedup over own 1-thread result"
      :widths: 24 14 20 20 22

      "AMD original", "256", "1.411e-03", "1.677e+10", "77.06x"
      "AMD ompdo", "128", "1.076e-03", "2.200e+10", "34.30x"
      "Kunpeng GCC/mpifort", "48", "3.802e-03", "6.224e+09", "27.38x"
      "Kunpeng BiSheng", "256", "1.060e-03", "2.232e+10", "74.09x"
      "Kunpeng BiSheng ompdo", "224", "8.733e-04", "2.710e+10", "53.24x"

   ``Kunpeng BiSheng ompdo`` reaches the best average in this dataset:
   ``8.733e-04 s/step`` at 224 threads, or about ``2.71e10`` component updates/s.
   Its 224/256-thread repeats are noisy, so rerun before using this as a final headline.

   .. rubric:: Conclusions

   1. ``Kunpeng GCC/mpifort`` degrades at high thread counts and is not the
      preferred high-thread E03 configuration in the current dataset.
   2. ``Kunpeng BiSheng`` is the more stable Kunpeng configuration and stays
      below AMD original at almost all thread counts, usually at ``55%–78%``
      of AMD original time.
   3. ``Kunpeng BiSheng ompdo`` gives the highest current average throughput,
      but noisy 224/256-thread repeats make it a promising result that still needs confirmation.
   4. ``AMD ompdo`` is also highly effective, proving that outer ``parallel`` +
      H/E ``omp do`` is a cross-platform kernel optimization. Fair comparisons
      should retain corresponding variants on both platforms.

   .. rubric:: Reproduction Commands

   Run from ``tests/kunpeng_compare/E_Maxwell`` using the workload and thread
   list represented by this page:

   .. code-block:: bash

      cd tests/kunpeng_compare/E_Maxwell
      export THREAD_LIST="1 2 4 8 12 16 24 32 40 48 56 64 80 96 112 128 160 192 224 256"

      ./run_amd.sh 160 160 160 100 5
      ./run_amd_ompdo.sh 160 160 160 100 5
      ./run_kunpeng.sh 160 160 160 100 5
      ./run_kunpeng_optimized.sh 160 160 160 100 5
      ./run_kunpeng_ompdo.sh 160 160 160 100 5

   Outputs are written under ``E03_fdtd_3d_cartesian/data_raw/amd``,
   ``amd_ompdo``, ``kunpeng``, ``kunpeng_optimized``, and ``kunpeng_ompdo``.
   The optimized Kunpeng scripts prefer the cluster BiSheng setup; if ``FC``
   is already set, they use that compiler.

   .. rubric:: Raw Single-Step Times

   Raw ``single_step_avg_s`` values in seconds:

   .. csv-table::
      :header: "Threads", "AMD original", "AMD ompdo", "Kunpeng GCC/mpifort", "Kunpeng BiSheng", "Kunpeng BiSheng ompdo"
      :widths: 10 18 18 22 20 24

      "1", "1.087e-01", "3.690e-02", "1.041e-01", "7.857e-02", "4.649e-02"
      "2", "5.478e-02", "1.878e-02", "5.318e-02", "3.809e-02", "2.662e-02"
      "4", "2.748e-02", "9.628e-03", "2.775e-02", "1.887e-02", "1.951e-02"
      "8", "1.396e-02", "8.463e-03", "1.415e-02", "9.918e-03", "1.077e-02"
      "12", "9.589e-03", "8.402e-03", "9.774e-03", "6.683e-03", "7.747e-03"
      "16", "8.896e-03", "8.541e-03", "7.419e-03", "5.000e-03", "6.153e-03"
      "24", "6.073e-03", "5.737e-03", "5.771e-03", "3.505e-03", "4.861e-03"
      "32", "3.901e-03", "3.686e-03", "4.740e-03", "2.744e-03", "4.182e-03"
      "40", "3.046e-03", "2.584e-03", "4.214e-03", "2.330e-03", "3.828e-03"
      "48", "2.617e-03", "1.937e-03", "3.802e-03", "2.026e-03", "3.213e-03"
      "56", "2.385e-03", "1.553e-03", "4.107e-03", "1.824e-03", "2.628e-03"
      "64", "2.191e-03", "1.267e-03", "4.048e-03", "1.672e-03", "2.117e-03"
      "80", "2.246e-03", "1.235e-03", "4.191e-03", "1.466e-03", "9.221e-04"
      "96", "1.759e-03", "1.164e-03", "4.555e-03", "1.370e-03", "1.051e-03"
      "112", "1.761e-03", "1.144e-03", "4.165e-03", "1.305e-03", "1.076e-03"
      "128", "1.636e-03", "1.076e-03", "4.559e-03", "1.274e-03", "1.170e-03"
      "160", "1.943e-03", "1.603e-03", "3.880e-03", "1.396e-03", "1.057e-03"
      "192", "1.696e-03", "1.371e-03", "5.519e-03", "1.255e-03", "1.206e-03"
      "224", "1.522e-03", "1.201e-03", "5.913e-03", "1.169e-03", "8.733e-04"
      "256", "1.411e-03", "1.077e-03", "4.983e-03", "1.060e-03", "9.516e-04"

   .. rubric:: Relative Time Versus AMD Original

   The table sets AMD original at the same thread count to ``100%``:

   .. csv-table::
      :header: "Threads", "AMD original", "AMD ompdo", "Kunpeng GCC/mpifort", "Kunpeng BiSheng", "Kunpeng BiSheng ompdo"
      :widths: 10 18 18 22 20 24

      "1", "100.00%", "33.95%", "95.75%", "72.27%", "42.77%"
      "2", "100.00%", "34.29%", "97.08%", "69.52%", "48.60%"
      "4", "100.00%", "35.03%", "100.98%", "68.67%", "70.99%"
      "8", "100.00%", "60.60%", "101.29%", "71.02%", "77.14%"
      "12", "100.00%", "87.62%", "101.93%", "69.69%", "80.79%"
      "16", "100.00%", "96.02%", "83.41%", "56.20%", "69.16%"
      "24", "100.00%", "94.47%", "95.03%", "57.71%", "80.05%"
      "32", "100.00%", "94.48%", "121.49%", "70.33%", "107.21%"
      "40", "100.00%", "84.84%", "138.36%", "76.48%", "125.68%"
      "48", "100.00%", "74.04%", "145.31%", "77.45%", "122.77%"
      "56", "100.00%", "65.10%", "172.19%", "76.47%", "110.19%"
      "64", "100.00%", "57.83%", "184.81%", "76.33%", "96.62%"
      "80", "100.00%", "54.96%", "186.56%", "65.27%", "41.05%"
      "96", "100.00%", "66.16%", "258.95%", "77.86%", "59.76%"
      "112", "100.00%", "64.95%", "236.48%", "74.11%", "61.08%"
      "128", "100.00%", "65.78%", "278.77%", "77.92%", "71.54%"
      "160", "100.00%", "82.50%", "199.71%", "71.83%", "54.40%"
      "192", "100.00%", "80.85%", "325.43%", "74.01%", "71.10%"
      "224", "100.00%", "78.89%", "388.49%", "76.79%", "57.37%"
      "256", "100.00%", "76.31%", "353.19%", "75.16%", "67.45%"
