J02 Parallel Consistency
==========================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 测试目标

   本页检查同一物理问题在串行、线程并行和空间分区并行下是否得到一致结果。
   先运行本目录 ``run.sh`` 中的局部与组装测试，再运行下面两个脚本；
   普通构建会重新建立 ``build``，因此并行日志应在普通测试之后生成。

   测试都通过 ``sub_J02_sweep`` 和 ``sub_J02_solve_transport`` 进入正式求解器。
   一致性参考来自串行或未分区计算；另外检查非负性、粒子收支和错误诊断。
   例如把 5×3 空间网格分给四个进程后，测试取每块的计算结果，
   与未分区场在同一位置的值逐项核对；线程测试则核对同精度下的完整输出记录。

   .. list-table:: 脚本的执行顺序
      :header-rows: 1
      :widths: 12 44 44

      * - 步骤
        - OpenMP：同一空间域，多线程处理离散速度
        - MPI：划分空间，每块由一个进程处理
      * - 1. 建立参考
        - 编译串行版本，对各组输入保存完整数值记录
        - 测试程序在小网格上求未分区参考场
      * - 2. 改变执行方式
        - 保持输入不变，分别用 1、2、4 个线程重复计算
        - 划分径向、轴向或二维空间块，交换交界面数据；混合版本再启用线程
      * - 3. 核对数值
        - 对照分布、矩、通量与诊断记录，检查实际线程数
        - 对照各块对应位置的场和通量，检查全域收支
      * - 4. 核对失败行为
        - 同时制造多个方向错误，检查确定的失败位置和输出清理
        - 只使一个进程输入出错，检查所有进程都能返回，且后续合法调用仍成功

   .. rubric:: 1. OpenMP：算例与公共入口

   源文件：``source_f90/test_J02_parallel.f90``。
   运行脚本：``run_parallel.sh``，位于 J02 测试目录。

   非均匀 2×2 网格使用 16 个角方向、3 个速率区间。第一组采用开放边界，
   检查分布角点非负和入口—出口粒子率平衡。第二组增加一个无效单元形成的内部壁面、
   下端部分入口和空间变化的体损失；分别采用纯镜面、各占一半的混合反射和纯漫反射。
   检查收敛状态、非负角点、无效单元零密度，以及
   “入口率 = 开放出射率 + 体损失率”。完整四面入口和紧凑下端入口应给出相同分布。

   错误测试同时令两个离散速度失败，要求报告编号最小的离散速度；
   负入射测试要求返回保正失败的具体方向与单元；
   迭代步数不足时必须报未收敛，且不能留下上次调用成功时的密度。

   .. rubric:: 2. OpenMP：运行组合、断言与结果

   运行脚本分别构建默认四字节实数和提升为八字节实数的版本。
   在每种精度内，以串行构建为基准，运行 OpenMP 1、2、4 线程，
   每种线程数重复三次。日志必须确认实际线程数。
   比较记录包含全部分布系数、密度、两分量速度、内部面通量、边界入流与出流，
   以及迭代数、相对变化和错误位置。
   记录按 17 位有效数字输出，要求同精度记录完全相同；
   不要求四字节与八字节结果完全相同。

   非负性与开放收支使用 ``max(1e-12,100*epsilon)`` 容差；
   反射迭代容差为 ``max(1e-10,8*epsilon)``，相对收支误差不超过该容差的 100 倍。
   脚本同时启用越界检查、非法浮点运算和除零等异常检查，
   并在串行与四线程的八字节构建中运行其余非 MPI 的 J02 测试程序。

   .. code-block:: bash

      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_parallel.sh

   2026-10-06 在 WSL 的 GNU Fortran 环境中，上述检查全部通过。
   日志与数值记录保存在本测试的 ``build/parallel/r4`` 和 ``build/parallel/r8`` 下。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 实数精度
        - 漫反射比例
        - 实际迭代次数
        - 相对粒子收支误差
        - 收支容差
      * - real4
        - 0 / 0.5 / 1
        - 51 / 34 / 31
        - 1.0358e−6 / 9.1248e−7 / 1.5290e−6
        - 9.5367e−5
      * - real8
        - 0 / 0.5 / 1
        - 90 / 56 / 52
        - 4.0121e−10 / 8.2980e−11 / 1.3212e−10
        - 1e−8

   1、2、4 线程、每项三次重复均与同精度串行记录逐字节一致；数值数组与诊断记录的差为零。
   全开放算例的相对收支误差为 real4：1.2183e−7，real8：3.4039e−16，
   对应容差为 1.1921e−5、1e−12；最小角点值均为零。
   人为错误实际定位为 ``(608,3,0,0)`` 和 ``(502,1,1,1)``，依次是返回码、方向、i、k。

   .. rubric:: 3. MPI：空间分区与通信检查

   源文件为 ``source_f90/test_J02_mpi.f90``，脚本为 ``run_mpi.sh``。
   通过公共接口 ``sub_J02_sweep`` 与 ``sub_J02_solve_transport`` 检查结果；
   ``sub_J02_initialize_partition`` 准备各进程的本地空间块；
   随后的扫描和完整求解会执行实际的交界面通信。

   .. list-table::
      :header-rows: 1
      :widths: 27 36 37

      * - 被测功能与实现文件
        - 测试条件
        - 判断内容
      * - 单轮扫描；``sweep``、``mpi_sweep``、``dg_operator``
        - 从轴线起始的非均匀 5×3 网格，16 个角方向、2 个速率区间，四象限与体损失
        - 本地全部三个空间系数等于未分区参考场的对应区域；角点非负
      * - 分区接口；``partition``、``geometry``
        - 径向、轴向、二维分块；重排通信器；不均匀自定义块
        - 无遗漏或重复单元；求解不依赖 world rank 编号
      * - 反射迭代；``reflection``、``wall``
        - 纯镜面、混合、纯漫反射，部分入口、跨块障碍和体损失
        - 收敛状态与迭代数一致，密度、两分量速度和分布在精度容差内一致
      * - 通量重构；``reconstruction``、``mpi_sweep``
        - 本块内部面、径向与轴向的四类开放边界、所有 REMOTE 面
        - 各通量等于未分区相应位置；独立检查全局入口、逸出与体损失收支
      * - 集体错误；``transport``、``sweep``、``partition``
        - 仅一个进程输入负损失、NaN 容差/比例、不同求积/迭代选项、破损边坐标或错误面类型
        - 各进程返回明确错误码，不超时；不残留上次成功的密度
      * - 局部数值错误；``sweep``
        - 同时两个方向出错；负入流触发保正失败
        - 报告最小失败方向及原迎风顺序中的全局单元位置
      * - 无有效单元的分区与重复调用；完整求解接口
        - 某个进程全部单元无效；多次错误后重新提供合法输入
        - 所有进程正常参与并返回；结果仍与未分区计算一致

   测试程序为了取得小规模参考解，会在每个进程计算一次未分区的 5×3 场；
   随后按分区的全局索引取出对应值，与本地求解结果核对。
   正式 MPI 求解接口接收本地网格与场。

   .. rubric:: 4. MPI：运行组合、容差与日志

   脚本分别使用默认四字节和提升到八字节的实数。
   每种精度构建纯 MPI 和混合版本，
   检查 1×1、2×1、1×2、2×2、3×1、1×3 六种空间布局；
   纯 MPI 每进程一个执行线程，混合版本每进程 2、4 个线程，各重复两次。
   每种精度和构建另测一次自定义 2×2 块：径向 4+1、轴向 2+1。
   共 76 次启动；脚本核对实际线程数，单次运行默认超时 90 秒。

   场和通量以未分区解的相应尺度归一化，容差为
   ``max(1e-12,100*epsilon)``；
   反射收敛容差为 ``max(1e-10,8*epsilon)``。
   粒子收支误差除以入口率，容差为上述两类容差较大值的 100 倍。
   不要求不同 MPI 划分逐位一致，也不跨精度比较。
   迭代到上限时须返回未收敛，且报告轮数不超过请求上限。

   .. code-block:: bash

      MPIEXEC_FLAGS=--oversubscribe bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_mpi.sh

   上述参数适用于本机 Open MPI 可用 slot 不足的功能测试；
   其他 MPI 实现或正式资源分配下可省略。
   2026-10-06 在 WSL、GNU Fortran 13.3 和 Open MPI 上，76 次启动全部通过，
   同时启用了越界与浮点异常检查。
   日志在 ``build/mpi/r4``、``build/mpi/r8`` 下，按布局与线程数分别保存。

   **实测结果。**

   .. list-table::
      :header-rows: 1

      * - 精度
        - 分布/密度/均速缩放最大差
        - 内部/开放面通量缩放最大差
        - 进程交界面通量缩放最大差
        - 相对收支最大值
        - 收支容差
      * - real4
        - 0
        - 0
        - 0
        - 5.7782e−7
        - 1.1921e−3
      * - real8
        - 0
        - 0
        - 0
        - 6.8311e−11
        - 1e−8

   表中最大值覆盖 76 次启动中的全部进程、空间布局、线程数、反射条件及合法重复调用。
   测试用 MPI 最大值归约收集各进程的误差，而非仅输出主进程自己的数值。
   本次场量与通量差均为零，迭代次数也与未分区计算相同；自动判据仍使用所述精度容差。
   粒子收支是另一次全域求和，不以场量相等代替守恒检查。

   .. rubric:: 验证范围

   以上结果来自同一台 WSL 主机，验证 J02 的线程一致性、空间分区通信与错误处理。
   跨物理节点通信和加速比仍需在目标计算设备上测量；完整应用结果见 J03 的应用测试页。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Execution sequence

   First run the ordinary J02 tests. Then build a serial reference for each precision,
   rerun identical inputs with multiple threads or spatial partitions, and check the
   resulting fields, fluxes, balance and failure diagnostics.
   OpenMP records are compared exactly within each precision; MPI fields are compared
   against the matching region of the unsplit reference within the stated tolerance.

   .. rubric:: Serial/OpenMP consistency

   ``source_f90/test_J02_parallel.f90`` exercises ``sub_J02_sweep`` and
   ``sub_J02_solve_transport`` through their public interfaces. A nonuniform
   2×2 mesh with 16×3 velocity nodes covers open transport, specular/mixed/diffuse
   reflection, a partial inlet, an inactive cell and nonuniform loss. It checks
   nonnegative corner values, particle balance, compact/full inlet equivalence,
   deterministic failure locations and no stale density after nonconvergence.

   ``run_parallel.sh`` builds real4 and real8 serial references, then runs
   OpenMP with 1, 2 and 4 workers, repeating each three times. It verifies the
   actual worker count and exact same-precision agreement of 17-digit records:
   distribution, density, both velocities, internal and boundary fluxes,
   convergence and failure diagnostics. The other non-MPI J02 programs also
   run in serial and four-thread real8 builds, with bounds and floating-point
   exception checks. All passed on 2026-10-06 in WSL with GNU Fortran.

   .. code-block:: bash

      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_parallel.sh

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Precision
        - Diffuse fraction
        - Iterations
        - Relative balance
        - Limit
      * - real4
        - 0 / 0.5 / 1
        - 51 / 34 / 31
        - 1.0358e−6 / 9.1248e−7 / 1.5290e−6
        - 9.5367e−5
      * - real8
        - 0 / 0.5 / 1
        - 90 / 56 / 52
        - 4.0121e−10 / 8.2980e−11 / 1.3212e−10
        - 1e−8

   All 18 threaded records matched the same-precision serial record byte for byte.
   Open-sweep relative balances: real4 1.2183e-7 (limit 1.1921e-5), real8 3.4039e-16
   (limit 1e-12). Error tuples (code,direction,i,k) were (608,3,0,0) and (502,1,1,1).

   .. rubric:: Spatial MPI and MPI/OpenMP tests

   ``test_J02_mpi.f90`` exercises the public sweep and transport entries on a nonuniform
   5×3 grid with 16×2 velocity nodes, including the axis, all quadrants, specular/mixed/diffuse
   walls, a partial inlet, loss, an obstacle across interfaces and wholly inactive blocks.
   It checks local distributions, moments, every internal/open/REMOTE flux, global particle
   balance, compact inlet ownership, iteration diagnostics, collective input errors,
   global failure locations and successful reuse after errors.
   A small unsplit reference is replicated only in the test driver, not in the solver.

   ``run_mpi.sh`` builds real4/real8 pure MPI and hybrid variants. Six spatial layouts
   (1×1, 2×1, 1×2, 2×2, 3×1, 1×3) run twice with one worker for pure MPI and 2/4 workers
   for hybrid. Four additional custom 2×2 runs use radial 4+1 and axial 2+1 blocks.
   Reordered communicators ensure no dependence on world-rank numbering.
   All 76 launches passed on 2026-10-06 in WSL with GNU Fortran 13.3 and Open MPI.
   Worker counts, bounds checks, floating-point traps and 90-second per-run timeouts are enforced.

   Normalized field/flux tolerance is ``max(1e-12,100*epsilon)``. Reflection tolerance is
   ``max(1e-10,8*epsilon)``; relative balance tolerance is 100 times the larger tolerance.
   MPI layouts are not required to agree bitwise. No cross-precision comparison is made.
   Logs are in ``build/mpi/r4`` and ``build/mpi/r8``.

   .. code-block:: bash

      MPIEXEC_FLAGS=--oversubscribe bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run_mpi.sh

   **Measured results.**

   .. list-table::
      :header-rows: 1

      * - Precision
        - Max field difference
        - Max internal/open flux difference
        - Max remote flux difference
        - Max relative balance
        - Balance limit
      * - real4
        - 0
        - 0
        - 0
        - 5.7782e−7
        - 1.1921e−3
      * - real8
        - 0
        - 0
        - 0
        - 6.8311e−11
        - 1e−8

   Maxima include all ranks in all 76 launches. Field and flux errors are reduced by
   MPI maximum; they were zero for this run. Iteration counts matched the unsplit reference.

   The optional launcher flag is Open MPI-specific and only needed for insufficient local slots.
   These are same-host functional tests, not multi-node tests, speed measurements or full B0/ION runs.
   J03 remains single-domain.
