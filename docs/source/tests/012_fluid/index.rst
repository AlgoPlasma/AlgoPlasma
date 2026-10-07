012_fluid
==========================================================================================

.. toctree::
   :maxdepth: 2
   :hidden:

   J01_test_overview
   J02_test_overview
   J03_test_overview

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh ap-fluid-doc

   .. rubric:: 测试怎样展开

   测试按被测源码分为 J01、J02、J03 三组。每组先用小数组或单条轨迹验证一个计算过程，
   再组装多个过程求解小问题。J03 组继续接入实际前处理结果，最后运行器件规模算例。

   .. list-table::
      :header-rows: 1
      :widths: 16 27 29 28

      * - 分组
        - 第一层：逐过程
        - 第二层：模块内组装
        - 后续检查
      * - J01
        - 入口概率、反射速度、轨迹驻留时间、穿面计数、统计归一化
        - 完整主入口执行采样、跟踪和统计；核对注入与逃逸粒子率
        - 保留的三维更新及二维给定速度通量单独列页
      * - J02
        - 网格几何、速度求积、边界分布、DG 积分、场重构
        - 迎风扫描、反射迭代、局部保正、完整求解入口
        - 同一算例的串行、OpenMP、MPI 和混合并行结果
      * - J03
        - 面系数、稳定步长、单步密度、残差与收支
        - 重复推进至指定时间，核对解析解；另检查平衡解和收敛条件
        - J01→J03、J02→J03 小规模串联，然后运行完整应用

   “逐过程”测试固定该过程所需的输入，直接核对输出。
   例如，给统计过程一组已知驻留时间，密度应等于粒子率乘驻留时间再除以体积。
   “组装”测试则让前一过程实际生成后一过程的输入。
   例如，完整 FM 计算由粒子跟踪得到驻留时间和穿面计数，再生成密度和通量。
   这样，局部公式有误时可由第一层定位，调用或数据传递有误时可由第二层发现。

   J03 的串联测试进一步使用前处理的真实输出构造面系数，推进新的密度场。
   其中，FM 两单元问题核对时间解析解；SN 有损失输运问题核对空间解析解和网格加密误差。
   完整应用使用较大网格、部分入口和混合反射，检查收敛、密度及粒子收支。

   .. rubric:: 阅读一项测试时看什么

   每个具体页面按计算顺序说明四项内容：

   1. **问题与输入**：网格、边界、速度或损失设置，以及哪些数组由测试指定。
   2. **调用过程**：测试子程序名称、正式计算过程，以及数据传递顺序。
   3. **参考值推导**：解析积分、已知轨迹、时间解析解或独立粒子收支。
   4. **断言与结果**：核对哪些数值、允许多大误差、日志写到哪里。

   侧栏中的 J01、J02、J03 首页列出各自的阅读顺序和程序清单。
   一个测试程序可能包含局部与组装两类子测试，页面会注明具体子程序；
   文档层级按检查内容划分，源码目录仍按所属模块组织。

   .. rubric:: 编译和执行

   在仓库根目录运行以下三个脚本。每个脚本先编译正式模块和测试程序，再执行断言，
   逐程序日志保存在对应测试目录的 ``build/*.log``。

   .. code-block:: bash

      bash tests/012_fluid/J01_free_molecular/run.sh
      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh
      bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh

   .. list-table::
      :header-rows: 1

      * - 脚本
        - 实际执行
        - 输出
      * - J01 / run.sh
        - 5 个程序：保留更新、二维通量、粒子局部过程、角点轨迹、采样概率
        - 公式误差、统计概率、完成与截断状态
      * - J02 / run.sh
        - 9 个非 MPI 程序：局部算子、边界、扫描、迭代、保正及完整入口
        - 公式与守恒断言、求解状态；并行测试程序在此以串行构建运行
      * - J03 / run.sh
        - 4 个局部/时间/配置程序，再运行 2 个串联程序
        - 时间误差、收支、空间加密误差和接续后的密度误差

   编译需要 Bash 和 GNU Fortran。普通测试使用八字节实数并启用数组越界检查。
   J02 的线程和进程一致性由 ``run_parallel.sh``、``run_mpi.sh`` 单独执行；
   运行顺序及精度组合见 J02 分组。完整应用使用 J03 分组中的独立脚本。

   .. rubric:: 结果记录

   数值结果放在对应小测试的说明之后：标量列出计算值、参考值、误差与容差；
   数组列出明确的误差范数；采样列出实测概率范围；错误路径列出返回码和位置。
   表中 0 表示本次计算得到零差值。计算值通常保留 10 位有效数字，误差列来自舍入前的独立计算。
   完整数值保存在下方下载记录中。
   未另注单位的小数组算例使用归一化测试数值。

   本轮记录日期为 2026-10-06，环境为 WSL Ubuntu、GNU Fortran 13.3.0。
   普通测试使用八字节实数并启用数组越界与浮点异常检查。
   J01、J02、J03 的 5、9、6 个程序均成功退出；另执行 18 次 OpenMP 一致性检查、
   16 次串行/线程辅助运行和 76 次 MPI/混合并行启动。应用验收工具的 9 项测试无跳过。

   :download:`数值记录与运行条件 <records/small_tests_2026-10-06.txt>`
   保存了测试程序实际输出的数值、错误状态和源码指纹；完整本地日志仍在各测试的 build 目录。
   网页按算例选取并解释这些数据，不嵌入整段运行日志。

   大型应用页面单独记录运行来源、参数与图片。FM B0 已在近角点修复后复跑；
   SN B0、ION 使用同日完成的结果。

   判断一次运行是否成功，以程序零退出状态和全部断言通过为准。
   若失败，先找日志中的测试名称，再按对应页面的输入、参考值和容差核查。
   例如 ``self-face integral and accumulation`` 对应 J02 面矩阵积分，
   ``transient storage equals ...`` 对应 J03 新旧时间层的总粒子数收支。

   .. rubric:: 验证范围

   小测试验证解析公式、离散算子、数据传递及同机并行一致性；
   完整应用验证当前设置下的收敛、非负性与粒子收支。
   这些结果不替代大型算例的空间与速度网格收敛、FM 采样误差或多节点性能评估。

.. container:: ap-lang ap-lang-en ap-fluid-doc

   .. rubric:: Organization and progression

   Tests are grouped by J01, J02 and J03. Within each group, verify individual
   processes first, then assembled calculations. J03 continues with actual
   preprocessing-to-continuity connections and full applications.

   * J01: sampling, reflection, trajectories and tally normalization → complete FM driver.
     The retained 3D update and 2D prescribed-velocity utilities have a separate page.
   * J02: geometry, quadrature, boundary distributions, DG integrals and reconstruction
     → sweeps, reflection iteration, positivity and complete transport → parallel consistency.
   * J03: closure, timestep, single step and balance → analytical time evolution and equilibria
     → FM/SN coupling → application cases.

   Each detailed page identifies the setup, production calls, independent reference,
   assertions, tolerances and output. Some executables contain checks at more than one level;
   the documentation names the relevant test subroutines.

   .. rubric:: Execution

   From the repository root:

   .. code-block:: bash

      bash tests/012_fluid/J01_free_molecular/run.sh
      bash tests/012_fluid/J02_neutral_sn_transport_2Drz/run.sh
      bash tests/012_fluid/J03_neutral_continuity_faceflux_2Drz/run.sh

   These runners compile and execute 5, 9 and 6 programs respectively, using GNU
   Fortran with promoted eight-byte real values and bounds checking.
   Logs are stored in each directory's ``build/*.log``.
   J02 OpenMP and MPI consistency runners and full application runs are separate.

   .. rubric:: Recorded verification

   Results dated 2026-10-06 were obtained in WSL with GNU Fortran 13.3.0.
   All 5/9/6 ordinary programs, 18 OpenMP consistency runs, 16 auxiliary
   serial/threaded runs, 76 MPI/hybrid launches and nine helper unittests passed.
   Ordinary tests use real8 with bounds and floating-point checks.

   Each test's explanation is followed by measured values, independent references,
   errors and acceptance limits. Array records name their norm; probability records
   give observed ranges. Zero means a measured zero difference, not an inference
   from passing. Values are generally displayed to 10 significant digits; errors are computed before
   display rounding. The downloadable record retains full precision.
   Small-array fixtures use normalized values unless units are given.
   The :download:`numerical record <records/small_tests_2026-10-06.txt>` retains
   numerical diagnostics, error codes and a source fingerprint without embedding raw logs.

   Application provenance, parameters and figures are recorded separately.
   FM B0 was rerun after the near-corner correction; SN B0 and ION retain their
   completed runs from the same date.
   A successful run requires all assertions to pass and a zero process exit status.

   .. rubric:: Verification scope

   Small tests check analytical formulas, discrete operators, data transfer and
   same-machine parallel consistency. Full applications check convergence,
   nonnegativity and particle balance for the stated setup. They do not establish
   large-case spatial or velocity-grid convergence, FM sampling uncertainty,
   or multi-node performance.
