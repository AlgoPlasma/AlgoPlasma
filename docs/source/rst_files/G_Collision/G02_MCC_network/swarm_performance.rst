.. rst-class:: ap-g02 ap-g02-reference

Performance optimization and verification of the G02 Monte Carlo collision module
=================================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. rubric:: 为什么测电子群？

   给一群电子施加均匀电场，让它们在背景气体中运动。每走一个时间步，主程序都请 G02 判断：哪些电子与气体发生了碰撞，碰后速度怎样变化？G02 用随机抽样作判断，这种方法叫蒙特卡洛碰撞（MCC）。这里的电场由主程序给定，不需要根据粒子分布重新求解。

   最初，我们用另一套程序 WarpX 运行相同类型的算例。在九个单线程算例中，做完相同步数，旧版 G02 都花了更长时间。为了判断修改 G02 本身带来了多少收益，最后的测速换成了 **原版 G02 与优化版 G02** 的直接比较。

   .. rubric:: 怎样少做工作，又让电子得到原来的结果？

   **例一：排一次的顺序，可以用几步？** 实际测速从 4,000 个电子开始。为看清排序过程，假设数组中只有三个电子，存放顺序是 30、10、20。计算时要按 10、20、30 访问，所以程序先整理出“第 2、3、1 个位置”这个顺序。下一步如果存放情况没变，旧版还会为这个无序数组再排一次；新版核对数量、各位置的编号和存活状态后，沿用这个顺序。它照样处理全部电子，也不移动电子本身。

   .. raw:: html

      <details><summary>试一试：下一步存放顺序变成 20、10、30，还能沿用“第 2、3、1 个位置”吗？</summary>
      <p>不能。沿用旧顺序会读到 10、30、20。编号检查会发现变化；重新排序得到第 2、1、3 个位置，又按 10、20、30 处理。</p></details>

   **例二：两个电子会拿到同一个随机数吗？** 种子是控制随机抽样的一项输入。假设编号 10 和 20 的电子处于同一步，并使用同一个种子。旧版为两个电子各算一遍“种子和步号”这一段；新版算一次并保留中间值。后半段仍分别代入电子自己的编号、事件号和抽样用途，所以每个电子拿到的数都和它优化前拿到的数相同。

   **例三：这一步来不及发生的碰撞，还要做哪些准备？** 假设一步长 0.05 ps（皮秒），抽到的第一个候选事件在 0.20 ps 后。候选只是一次可能的碰撞，还要进一步判断才知道是否真的碰撞。既然它在本步之外，这个电子就不需要准备本步的碰撞数据。若候选落在本步内，程序把刚抽出的等待时间交给碰撞计算，不再重复抽取。

   .. raw:: html

      <details><summary>怎样避免把步末附近的候选错判为“本步之外”？</summary>
      <p>只有能留出足够数值余量时才提前排除；拿不准就用原来的对数公式。若编译器启用可能改变浮点运算规则的快速数学模式（定义了 <code>__FAST_MATH__</code>），代码直接禁用这条提前排除的捷径，仍按原公式判定。</p></details>

   另外，连续存放的粒子可以整批复制到工作区，随后仍逐个检查；相邻粒子具有相同物种和内部状态时，可以沿用刚查到的定义。想对照代码，可看 :doc:`批量步进 <fun_G02_mcc_batch>` 和 :doc:`随机抽样 <rng>`。

   七轮试验保留了六轮改动。第三轮预计算事件号为零的部分运算，因提速不稳定而未采用。
   复核另外修正了两处边界问题。排序缓存重建前先标为无效，避免内存分配中途失败后重试越界。
   等待时间快速判断会先检查乘法范围，极端输入下退回原公式，避免新增浮点溢出。

   .. rubric:: 怎样知道结果没变？

   给原版和优化版同一份初始电子文件和同一个种子，各跑一次，称为“一对”。先比较随时间记录的全部数据，再比较最后每个粒子的位置、速度、编号等状态。18 对运行的过程记录（每次 800 个时刻）和最终粒子状态逐对、逐字节相同。候选碰撞数、真实碰撞数、计时段及全程的电离新生电子数也逐对相等。

   历史七轮试验也做过这种比较。下面的图取其中一个例子：氦气开启电离，约化电场为 200 Td。约化电场是电场强度除以背景气体数密度，Td 是它的单位。电离指一次电子碰撞可以产生新的电子。

   .. figure:: ../../../../../tests/009_collision/G02_MCC_network/he200_replay.png
      :alt: 历史氦气算例中，优化前后的平均能量和漂移速度曲线分别重合。

      蓝实线为第一轮改动前，橙虚线为第七轮采用版。横轴是模拟时间；左图看平均能量，右图看电子群的平均漂移速度。两个量在全部记录时刻分别相等。图只展示这个历史算例，两版使用同一个种子 104729。

   .. rubric:: 同样的工作，实际快了多少？

   :ref:`复现这两张表 <reproduce-tables-zh>`

   从三类算例中各选一个：氦气关闭电离，考察没有新电子的情况；氦气开启电离，考察新电子出现时的工作；Reid 是人为规定碰撞截面的模型气体，提供另一种对照。两版在同一台机器上各用一个 CPU 线程，从同一批 4,000 个电子开始。每步 0.05 ps，先走 40,000 步，再测后 40,000 步（2–4 ns）的实际用时。计时包括粒子运动、碰撞、粒子数控制、诊断计算和写出记录。

   .. list-table::
      :header-rows: 1

      * - 工况
        - develop 平均用时
        - 修复版平均用时
        - 综合加速比
        - 主测加速比
        - 换序加速比
      * - He 关闭电离，50 Td
        - 17.740 s
        - 5.070 s
        - 3.50×
        - 3.29×
        - 3.74×
      * - He 开启电离，200 Td
        - 21.623 s
        - 5.996 s
        - 3.61×
        - 3.39×
        - 3.85×
      * - Reid 模型气体，12 Td
        - 17.905 s
        - 5.408 s
        - 3.31×
        - 3.39×
        - 3.23×

   表中比较上游 develop（``7db6abe``）和完成两项边界修复的 G02（``8c9e151``）。每个工况用三个种子。两版按主测顺序各跑一次，再用相同输入交换运行顺序。因此每版在每个工况各有六个用时。表中两列秒数是各版六次运行的平均用时。综合加速比用 develop 六次总用时除以修复版六次总用时，最后两列分别只取对应顺序的三次。 这批单线程结果适用于上述三个工况和计时窗口。

   .. raw:: html

      <details><summary>为什么每个工况跑三对，又为什么调换运行顺序？</summary>
      <p>第一对用种子 104729，旧版与新版各跑一次；换成 130363 做第二对，再换成 155921 做第三对。每一对内部都用相同的种子和对应的初始电子；换种子是为了看看结果是否只在一种抽样下成立。</p>
      <p>九个组合全部复测。若主测先跑 develop，就先跑修复版复测，反之亦然。这样每一版都有一次先跑、一次后跑。</p></details>

   :download:`最初九个算例：旧 G02 和 WarpX 的逐次用时（CSV） <../../../../../tests/009_collision/G02_MCC_network/warpx_runs.csv>`。每行是一次运行：engine 是程序，steps 是计时步数，seconds 是用时（秒）。

   :download:`最终版与 develop 的全部配对记录（CSV） <../../../../../tests/009_collision/G02_MCC_network/final_timings.csv>`。每一行是一对，main 表示主测，reverse 表示换序复测。baseline_s 和 candidate_s 分别是 develop 和修复版的用时（秒）。想看碰撞本身怎样验证，可接着读 :doc:`弹性碰撞盒教程 </tests/009_collision/G02_collision_box>`。

   .. rubric:: G02 的峰值内存是多少？

   本次另跑一批内存复测。每次运行由 G02 在写完最终粒子状态后，读取自身 /proc/self/status 中的 VmHWM，即该进程截至此时的峰值常驻内存，包含初始化和模拟。每格给出六次独立运行的最低和最高峰值，右端是该工况观测到的最高值。

   .. list-table::
      :header-rows: 1

      * - 工况
        - develop 峰值范围（MiB）
        - 修复版峰值范围（MiB）
      * - He 关闭电离，50 Td
        - 20.79–22.30
        - 20.56–23.32
      * - He 开启电离，200 Td
        - 22.66–24.44
        - 22.57–23.79
      * - Reid 模型气体，12 Td
        - 5.59–5.75
        - 5.61–5.72

   此前报告的 39.4 MiB 来自 getrusage，在这套启动方式下会受父进程内存占用影响。该数值已撤回。三个工况各用三个种子，并交换运行顺序，共 18 对。每对的过程记录和最终粒子状态逐字节相同，碰撞计数一致，也与上一批测速中相同输入的结果一致。

   速度表由 6ccb13e 中的脚本复现，内存表使用 c20880e 中的脚本。两次比较的 G02 代码都是 develop 的 7db6abe 和修复版 8c9e151。 :download:`逐对内存读数（CSV） <../../../../../tests/009_collision/G02_MCC_network/vmhwm_pairs.csv>`。

   .. rubric:: 自动测试和碰撞盒核对

   修复后通过 21 项 CTest。测试覆盖固定输入下的随机数核对、串行与 OpenMP 结果对照，
   以及 1、2、4 个 MPI 进程的测试。弹性碰撞盒还对比了优化前后的过程记录、分布和碰撞计数，
   三类输出逐字节一致。碰撞盒的物理量与通过标准见 :doc:`弹性碰撞盒 </tests/009_collision/G02_collision_box>`。
   多线程与 MPI 的配置和验证方法见 :doc:`MPI 接口 <group_mpi_interface>`。

   :download:`历史试验输出和核对脚本 <../../../../../tests/009_collision/G02_MCC_network/benchmark_evidence.tar.xz>`，
   :download:`历史曲线数据 <../../../../../tests/009_collision/G02_MCC_network/he200_replay.csv>`。

   .. rubric:: 算例输入和早期记录

   最初的对照选了三组工况。氦气关闭电离和开启电离时各测 20、50、200 Td。
   氦气弹性、激发和电离截面来自 WarpX 收录的 Biagi 数据（MAGBOLTZ 7.1），
   能量轴已换算为 G02 使用的相对能量。Reid 模型使用解析截面，场强 1、12、24 Td
   取自 `Dias 等（2023）表 1 <https://doi.org/10.1016/j.cpc.2022.108554>`_。
   最初与 WarpX 的对照在 2.5–5 ns 计时，电子群最终版对照在 2–4 ns 计时。

   :download:`电子群固定输入（初始电子、模型和截面来源） <../../../../../tests/009_collision/G02_MCC_network/examples/swarm_benchmark/swarm_inputs.zip>`。
   早期数据包括 :download:`修复前的两批用时 <../../../../../tests/009_collision/G02_MCC_network/timings.csv>`、
   :download:`边界修复前后的用时 <../../../../../tests/009_collision/G02_MCC_network/safeguard_timings.csv>`
   和 :download:`修复后的三对结果核对 <../../../../../tests/009_collision/G02_MCC_network/review_replay.csv>`。

   .. rubric:: 并行测试与历史参考

   上游还曾用 32 个物理核、Release 构建和 OpenMPI 4.1.6 做过两组并行基准。
   预热 2 至 3 次后取 5 次中位数。计时范围是完整 MCC 步，未计入粒子推进和场求解。
   两组使用不同碰撞模型，各组的时间用于比较组内的并行配置。

   .. list-table::
      :header-rows: 1

      * - 负载
        - 配置
        - 整步时间（秒）
      * - 100 万粒子、100 通道
        - 1 线程，前缀
        - 1.003
      * - 100 万粒子、100 通道
        - 32 线程，前缀
        - 0.110
      * - 100 万粒子、100 通道
        - 32 线程，别名
        - 0.105
      * - 100 万粒子、单通道碰撞盒
        - 1 rank × 1 thread
        - 0.288
      * - 100 万粒子、单通道碰撞盒
        - 2 ranks × 1 thread
        - 0.130
      * - 100 万粒子、单通道碰撞盒
        - 4 ranks × 1 thread
        - 0.068
      * - 100 万粒子、单通道碰撞盒
        - 4 ranks × 4 threads
        - 0.029

   运行命令后，100 通道基准读 ``median_step_s`` 列，MPI 碰撞盒读 ``distributed_step_s`` 列，单位均为秒。实际用时随机器和并行配置而变化。

   .. include:: /_includes/g02_parallel_reproduce.inc

   .. _reproduce-tables-zh:

   .. rubric:: 复现这两张表

   在 Linux 或 WSL 的完整 Git 仓库中运行下面的命令。仓库需要包含 !37 的提交，环境需要 Python 3、Git、CMake、支持 C++20 和 OpenMP 的 G++、MPI 开发库及 taskset。两个输出目录均须使用新路径。若本机不能使用逻辑 CPU 2，请在两条命令中指定同一个可用的逻辑 CPU。每批运行会在各自输出目录的 pairs.csv 中写入逐对结果。

   如果只想检查环境和输入文件，可先从仓库根目录运行三个工况的短算例。
   短跑用于验证安装和流程。

   .. code-block:: bash

      python3 tests/009_collision/G02_MCC_network/examples/swarm_benchmark/run.py --smoke --out ../g02-swarm-smoke

   按原设置复现上面的用时和内存表时，使用以下固定版本。

   .. include:: /_includes/g02_swarm_reproduce.inc

.. container:: ap-lang ap-lang-en

   .. rubric:: Why time a swarm of electrons?

   A driver moves electrons through a prescribed uniform electric field. At each time step it asks G02 which electrons collide with the gas and how their velocities change. G02 uses random draws to answer these questions, a method called Monte Carlo collisions (MCC). The driver does not need to solve for a field from the particle distribution here.

   The original G02 took longer than WarpX to advance the same number of steps in nine single-thread cases. To measure the gain from changing G02, the final benchmark compares the original and optimized **G02** directly.

   .. rubric:: What work can be skipped?

   **Order.** Each benchmark run starts with 4,000 electrons. To illustrate sorting, consider an array of just three electrons stored as 30, 10, 20. They must be visited as 10, 20, 30. The old code sorted the index again while the array remained unordered. After checking the count, IDs at each position and live flags, the new code can reuse the visit order (positions 2, 3, 1). Every electron is still processed.

   .. raw:: html

      <details><summary>Try it: if storage changes to 20, 10, 30, can we still visit positions 2, 3, 1?</summary>
      <p>No. That would visit IDs 10, 30, 20. The check detects the change; sorting now yields positions 2, 1, 3 and restores the required ID order.</p></details>

   **Random draws.** A seed is an input to random sampling. Electrons 10 and 20 share the seed and step, so their draws can reuse that intermediate calculation. Each electron's ID, event number and draw purpose still enter separately; each gets the same number as before.

   **Collision preparation.** A candidate is a possible collision that requires a further decision. If the first candidate would occur after 0.20 ps and the step lasts only 0.05 ps, there is no collision to prepare for in that step. An in-step candidate passes the sampled waiting time to the collision calculation.

   .. raw:: html

      <details><summary>What protects a candidate close to the end of a step?</summary>
      <p>The early rejection requires a numerical margin; otherwise G02 uses the original logarithmic expression. Builds defining <code>__FAST_MATH__</code> disable this shortcut and still evaluate the waiting time.</p></details>

   Contiguous particles can also be copied in bulk and still checked individually. Neighbours with the same species and internal state can reuse the definition just looked up. See :doc:`batch stepping <fun_G02_mcc_batch>` and :doc:`random sampling <rng>`.

   .. rubric:: Did the results change?

   One pair runs both versions with the same initial electron file and seed. All nine main pairs and all nine reversed-order pairs matched byte for byte for the 800 time records and the final particle states. Candidate events, real collisions and ionization births also matched in each pair.

   An earlier seven-round study also compared these outputs. The following example uses ionizing helium at 200 Td. Ionization can create new electrons. Td is the unit of reduced field (electric field divided by neutral gas number density).

   .. figure:: ../../../../../tests/009_collision/G02_MCC_network/he200_replay.png
      :alt: The mean-energy and drift-velocity histories overlap before and after optimization.

      Historical run, seed 104729: solid blue is the original version before round one, dashed orange the retained round-seven version. Read mean energy on the left and drift velocity on the right, both against simulation time. Both quantities matched at every recorded time.

   .. rubric:: How long did the same work take?

   :ref:`Reproduce both tables <reproduce-tables-en>`

   Three representative cases cover helium without new electrons, helium with new electrons and Reid, a gas defined by model cross sections. Each version used one CPU thread on the same machine, with 4,000 initial electrons and a 0.05 ps step. After 40,000 steps we timed the next 40,000 (2–4 ns), including particle motion, collisions, population control, diagnostics and output.

   .. list-table::
      :header-rows: 1

      * - Case
        - Mean, develop
        - Mean, fixed G02
        - Overall speedup
        - Main order
        - Reversed order
      * - He, ionization off, 50 Td
        - 17.740 s
        - 5.070 s
        - 3.50×
        - 3.29×
        - 3.74×
      * - He, ionization on, 200 Td
        - 21.623 s
        - 5.996 s
        - 3.61×
        - 3.39×
        - 3.85×
      * - Reid, 12 Td
        - 17.905 s
        - 5.408 s
        - 3.31×
        - 3.39×
        - 3.23×

   The table compares develop (``7db6abe``) with the fixed G02 (``8c9e151``). Each seed was run in both orders, giving six times per version in each case. The overall speedup divides total develop time by total fixed-version time. The last two columns use three pairs each. These timings describe the single-thread workload in the stated window.

   .. raw:: html

      <details><summary>Why three pairs, and why reverse their run order?</summary>
      <p>Use seed 104729 for the first pair, 130363 for the second and 155921 for the third. Within a pair both versions get the same initial particles and seed. Every pair is repeated with its run order reversed. Each version runs first once for each case and seed.</p></details>

   :download:`Original G02 vs WarpX: individual runs (CSV) <../../../../../tests/009_collision/G02_MCC_network/warpx_runs.csv>`. One row per run: engine, measured steps and elapsed seconds.

   :download:`Final G02 vs develop: all 18 pairs (CSV) <../../../../../tests/009_collision/G02_MCC_network/final_timings.csv>`. Each row is one pair. main and reverse identify the two orders. baseline_s and candidate_s are the elapsed seconds for develop and the fixed G02. For a physics check, see the :doc:`elastic collision box tutorial </tests/009_collision/G02_collision_box>`.

   .. rubric:: How much memory did G02 use?

   In a separate batch each G02 process read VmHWM from /proc/self/status after writing its final particle state. This gives its peak resident memory up to that point, including initialization and simulation. Each cell shows the lowest and highest of six run peaks.

   .. list-table::
      :header-rows: 1

      * - Case
        - develop peaks (MiB)
        - Fixed G02 peaks (MiB)
      * - He, ionization off, 50 Td
        - 20.79–22.30
        - 20.56–23.32
      * - He, ionization on, 200 Td
        - 22.66–24.44
        - 22.57–23.79
      * - Reid, 12 Td
        - 5.59–5.75
        - 5.61–5.72

   The previous 39.4 MiB getrusage reading was sensitive to the launching process and has been withdrawn. The 18 pairs matched byte for byte for diagnostics and final particle states. Collision counts and outputs also matched the corresponding runs in the speed batch.

   Use the runner from 6ccb13e for the speed table and c20880e for memory. Both compare G02 at 7db6abe and 8c9e151. :download:`Paired VmHWM readings (CSV) <../../../../../tests/009_collision/G02_MCC_network/vmhwm_pairs.csv>`.

   .. rubric:: Automated tests and the collision box check

   The fixed code passed all 21 CTest tests. The suite covers random draws with fixed
   inputs, serial and OpenMP agreement, and runs with 1, 2 and 4 MPI processes.
   The pre- and post-optimization elastic collision box histories, distributions and
   collision counts also matched byte for byte. See the
   :doc:`elastic collision box </tests/009_collision/G02_collision_box>`
   for the physical checks and :doc:`MPI integration <group_mpi_interface>`
   for parallel configuration and verification.

   Six of the seven trial rounds were adopted. The third precalculated part of the
   draw for event zero and gave inconsistent timing gains. The review also corrected
   two edge cases. Cache rebuilds invalidate the previous order before allocating
   memory, so an allocation failure cannot leave a partial cache marked valid.
   The early waiting-time check falls back to the original expression when its
   multiplication could overflow.

   :download:`Historical outputs and verification scripts <../../../../../tests/009_collision/G02_MCC_network/benchmark_evidence.tar.xz>`
   and :download:`historical plot data <../../../../../tests/009_collision/G02_MCC_network/he200_replay.csv>`.

   .. rubric:: Benchmark inputs and earlier records

   The original comparison used helium with and without ionization at 20, 50
   and 200 Td. Its electron collision tables come from the Biagi data bundled
   by WarpX (MAGBOLTZ 7.1), with energies converted to the relative energy
   used by G02. The Reid model uses analytical cross sections at 1, 12 and
   24 Td from `Table 1 of Dias et al. (2023) <https://doi.org/10.1016/j.cpc.2022.108554>`_.
   The initial WarpX runs timed 2.5–5 ns. The final G02 comparison timed 2–4 ns.

   :download:`Fixed inputs and cross-section attribution <../../../../../tests/009_collision/G02_MCC_network/examples/swarm_benchmark/swarm_inputs.zip>`.
   Earlier records include :download:`two pre-fix timing batches <../../../../../tests/009_collision/G02_MCC_network/timings.csv>`,
   :download:`timings before and after the two fixes <../../../../../tests/009_collision/G02_MCC_network/safeguard_timings.csv>`,
   and :download:`three post-fix replay checks <../../../../../tests/009_collision/G02_MCC_network/review_replay.csv>`.

   .. rubric:: Parallel tests and historical reference timings

   Earlier upstream benchmarks ran on 32 physical cores with a Release build and
   OpenMPI 4.1.6. The table reports the median of five measurements after two or
   three warmup runs. It covers the complete MCC step, excluding particle
   advancement and the field solve. Compare configurations within each workload.

   .. list-table::
      :header-rows: 1

      * - Workload
        - Configuration
        - Time per step (s)
      * - 1 million particles, 100 channels
        - 1 thread, prefix
        - 1.003
      * - 1 million particles, 100 channels
        - 32 threads, prefix
        - 0.110
      * - 1 million particles, 100 channels
        - 32 threads, alias
        - 0.105
      * - 1 million particles, 1-channel box
        - 1 rank × 1 thread
        - 0.288
      * - 1 million particles, 1-channel box
        - 2 ranks × 1 thread
        - 0.130
      * - 1 million particles, 1-channel box
        - 4 ranks × 1 thread
        - 0.068
      * - 1 million particles, 1-channel box
        - 4 ranks × 4 threads
        - 0.029

   Read ``median_step_s`` for the 100-channel benchmark and ``distributed_step_s`` for the MPI collision box. Both columns report seconds. Measured times depend on the machine and parallel configuration.

   .. include:: /_includes/g02_parallel_reproduce.inc

   .. _reproduce-tables-en:

   .. rubric:: Reproduce both tables

   Run these commands in a full Linux or WSL Git checkout containing the !37 commits. Install Python 3, Git, CMake, G++ with C++20 and OpenMP support, MPI development libraries and taskset. Use fresh output directories. If logical CPU 2 is unavailable, use the same available CPU in both commands. Each output directory contains a pairs.csv file with the individual measurements.

   To check the build environment and input files, first run the short
   three-case benchmark from the repository root.

   .. code-block:: bash

      python3 tests/009_collision/G02_MCC_network/examples/swarm_benchmark/run.py --smoke --out ../g02-swarm-smoke

   To repeat the measurements for the two tables, use the pinned versions below.

   .. include:: /_includes/g02_swarm_reproduce.inc

.. G02 contribution history (Git author dates; edit times include timezone).
   2026-11-09 09:53 +08:00 | Wushunzzz | git 1c20092c7f45
   2026-11-09 10:07 +08:00 | Wushunzzz | git 91c37adedc11
   2026-11-09 13:15 +08:00 | Wushunzzz | git dcd3c48f6a11
   2026-11-09 13:51 +08:00 | Wushunzzz | git 6ccb13e796b1
   2026-11-09 14:45 +08:00 | Wushunzzz | git c5cf932645d9
   2026-11-09 15:37 +08:00 | Wushunzzz | git d37657fd65ef
   2026-11-25 11:54 +08:00 | Wushunzzz | git 65cc283b8592
   2026-11-25 15:54 +08:00 | Wushunzzz | edit (Codex-assisted)
   2026-11-25 16:28 +08:00 | Wushunzzz | edit (Codex-assisted)
