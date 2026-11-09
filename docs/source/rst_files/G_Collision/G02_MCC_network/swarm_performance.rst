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

   .. rubric:: 怎样知道结果没变？

   给原版和优化版同一份初始电子文件和同一个种子，各跑一次，称为“一对”。先比较随时间记录的全部数据，再比较最后每个粒子的位置、速度、编号等状态。在下表所属的测速批次中，九对主测和三对调换顺序的补测，这两类文件逐对、逐字节一致。

   历史七轮试验也做过这种比较。下面的图取其中一个例子：氦气开启电离，约化电场为 200 Td。约化电场是电场强度除以背景气体数密度，Td 是它的单位。电离指一次电子碰撞可以产生新的电子。

   .. figure:: ../../../../../tests/009_collision/G02_MCC_network/he200_replay.png
      :alt: 历史氦气算例中，优化前后的平均能量和漂移速度曲线分别重合。

      蓝实线为第一轮改动前，橙虚线为第七轮采用版。横轴是模拟时间；左图看平均能量，右图看电子群的平均漂移速度。两个量在全部记录时刻分别相等。图只展示这个历史算例，两版使用同一个种子 104729。

   .. rubric:: 同样的工作，实际快了多少？

   从三类算例中各选一个：氦气关闭电离，考察没有新电子的情况；氦气开启电离，考察新电子出现时的工作；Reid 是人为规定碰撞截面的模型气体，提供另一种对照。两版在同一台机器上各用一个 CPU 线程，从同一批 4,000 个电子开始。每步 0.05 ps，先走 40,000 步，再测后 40,000 步（2–4 ns）的实际用时。计时包括粒子运动、碰撞、粒子数控制、诊断计算和写出记录。

   .. list-table::
      :header-rows: 1

      * - 工况
        - 原版平均用时
        - 优化版平均用时
        - 加速比
      * - 氦气关闭电离，50 Td
        - 15.205 s
        - 4.657 s
        - 3.26 倍
      * - 氦气开启电离，200 Td
        - 19.860 s
        - 4.617 s
        - 4.30 倍
      * - Reid，12 Td
        - 16.083 s
        - 4.756 s
        - 3.38 倍

   第一行的意思是：同样走完计时段，原版平均要 15.205 秒，优化版要 4.657 秒。加速比用三次原版总用时除以优化版总用时。表中比较的是上游版本与首次测速的优化版，不含后续两项边界修复。这是给定模拟时间段的单线程速度，不代表多核并行速度，也不要求电子群已达到稳态。

   .. raw:: html

      <details><summary>为什么每个工况跑三对，又为什么调换运行顺序？</summary>
      <p>第一对用种子 104729，旧版与新版各跑一次；换成 130363 做第二对，再换成 155921 做第三对。每一对内部都用相同的种子和对应的初始电子；换种子是为了看看结果是否只在一种抽样下成立。</p>
      <p>另取第一对的输入，把谁先运行、谁后运行对调，再计一次时。三个工况仍是优化版更快。这三对是补测，没有混入表中的平均用时。</p></details>

   :download:`最初九个算例：旧 G02 和 WarpX 的逐次用时（CSV） <../../../../../tests/009_collision/G02_MCC_network/warpx_runs.csv>`。每行是一次运行：engine 是程序，steps 是计时步数，seconds 是用时（秒）。

   :download:`本次三个算例：原版和优化版 G02 的逐对用时（CSV） <../../../../../tests/009_collision/G02_MCC_network/timings.csv>`。选 first（首次批次）和 main（主测），即可重算上表。想看碰撞本身怎样验证，可接着读 :doc:`弹性碰撞盒教程 </tests/009_collision/G02_collision_box>`。

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

   One pair runs both versions with the same initial electron file and seed. For all nine main pairs and three reversed-order pairs in the first batch, both the time records and final particle state files matched byte for byte.

   An earlier seven-round study also compared these outputs. The following example uses ionizing helium at 200 Td. Ionization can create new electrons. Td is the unit of reduced field (electric field divided by neutral gas number density).

   .. figure:: ../../../../../tests/009_collision/G02_MCC_network/he200_replay.png
      :alt: The mean-energy and drift-velocity histories overlap before and after optimization.

      Historical run, seed 104729: solid blue is the original version before round one, dashed orange the retained round-seven version. Read mean energy on the left and drift velocity on the right, both against simulation time. Both quantities matched at every recorded time.

   .. rubric:: How long did the same work take?

   Three representative cases cover helium without new electrons, helium with new electrons and Reid, a gas defined by model cross sections. Each version used one CPU thread on the same machine, with 4,000 initial electrons and a 0.05 ps step. After 40,000 steps we timed the next 40,000 (2–4 ns), including particle motion, collisions, population control, diagnostics and output.

   .. list-table::
      :header-rows: 1

      * - Case
        - Original mean
        - Optimized mean
        - Speedup
      * - He, ionization off, 50 Td
        - 15.205 s
        - 4.657 s
        - 3.26×
      * - He, ionization on, 200 Td
        - 19.860 s
        - 4.617 s
        - 4.30×
      * - Reid, 12 Td
        - 16.083 s
        - 4.756 s
        - 3.38×

   Divide the sum of the three original times by the sum of the three optimized times. The table compares upstream G02 with the first timed version, before the two subsequent edge-case fixes. These results describe single-thread performance in this time window; they do not measure multicore performance or require a steady-state swarm.

   .. raw:: html

      <details><summary>Why three pairs, and why reverse their run order?</summary>
      <p>Use seed 104729 for the first pair, 130363 for the second and 155921 for the third. Within a pair both versions get the same initial particles and seed. To check whether running first affects timing, reuse the first pair's input and swap which program runs first. The optimized version was faster in all three cases. The extra pairs are excluded from the table.</p></details>

   :download:`Original G02 vs WarpX: individual runs (CSV) <../../../../../tests/009_collision/G02_MCC_network/warpx_runs.csv>`. One row per run: engine, measured steps and elapsed seconds.

   :download:`Original vs optimized G02: paired timings (CSV) <../../../../../tests/009_collision/G02_MCC_network/timings.csv>`. Select first (first batch) and main (main comparison) to reproduce the table. For a physics check, see the :doc:`elastic collision box tutorial </tests/009_collision/G02_collision_box>`.
