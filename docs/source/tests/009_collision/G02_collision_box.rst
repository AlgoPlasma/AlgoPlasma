.. rst-class:: ap-g02 ap-g02-guide

G02_collision_box
=================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - MCC（Monte Carlo Collision，蒙特卡洛碰撞）：用随机抽样决定碰撞何时发生、发生哪种反应，以及粒子怎样变化；大量粒子的统计应符合给定模型。

   .. _g02-collision-box-zh:

   本页介绍 G02 的零维碰撞盒验证：先理解物理模型，再运行程序，最后读图并判断测试是否通过。
   MCC 的基本原理与程序接口见 :doc:`G02_MCC_network </rst_files/G_Collision/G02_MCC_network>`。

   .. rubric:: 1. 物理模型：热粒子与冷背景
      :class: g02-chapter

   这个测试使用一个简单模型：一群又热、又整体向右运动的 A 粒子，
   与较冷的 B 背景反复碰撞。我们想观察 A 的整体运动怎样减弱、温度怎样接近背景。
   这里只有一条弹性通道，方便把随机碰撞和已知理论结果逐项对照。

   .. figure:: ../../images/G_Collision/G02/physical_box_zh.svg
      :alt: 热 A 与固定 B 碰撞后逐渐冷却的物理示意
      :width: 100%

      箭头代表速度，方框用来分组；这张图用于讲解，不是模拟输出。
      点击图片可查看原图。

   “零维”表示把整个气体看作一个均匀区域，只研究随时间的变化。
   每个粒子仍有 x、y、z 三个方向的速度。
   算例不推进位置，没有壁面，也不求解电场，便于单独检查碰撞步骤。

   .. list-table:: 默认实验设置
      :header-rows: 1
      :widths: 30 70

      * - 项目
        - 设置及解释
      * - A 粒子
        - 50,000 个；初始温度 3000 K；整体沿 x 方向以 1000 m/s 运动。
      * - B 背景
        - 固定 300 K，约 27 °C；平均速度为零，单个 B 仍有热运动。
      * - 反应
        - A + B → A + B，等质量弹性碰撞；两者质量均为 4 × 10⁻²⁶ kg。
      * - 碰撞频率
        - 密度 10²⁰ m⁻³ 乘速率系数 10⁻¹⁴ m³/s，得到每个 A 平均每秒碰撞 10⁶ 次。
      * - 模拟时间
        - 每步 0.1 微秒，共 200 步，即 20 微秒；每个 A 的理论平均碰撞次数为 20。

   .. admonition:: 数据用途
      :class: g02-caution

      A、B 是虚构名称，数据是合成值，只用于检查软件，不能用于真实气体的科研结论。

   B 的温度保持固定；程序只记录它收到的动量和能量，不更新其温度。

   .. admonition:: 把过程连起来

      跟着一个编号为 A001 的粒子想一遍：记录速度 → 抽样等待时间 → 碰撞时临时抽一个 B →
      计算碰后速度 → 保存 A001 并登记 B 的收支。每个 A 都经历不同的随机过程，
      大量 A 的平均才组成温度曲线。单个 A 可以偶尔变快，整群 A 仍可逐渐冷却。

   .. rubric:: 2. 用三个数字看清温度与漂移

   .. figure:: ../../images/G_Collision/G02/drift_temperature_zh.svg
      :alt: 400、1000、1600 m/s 的速度减去平均 1000 m/s，得到相对速度
      :width: 100%

      算术示例只画 x 分量；实际程序用三个方向计算温度。
      点击图片可查看原图。

   平均速度为 (400+1000+1600)/3 = 1000 m/s，相对速度为 −600、0、+600 m/s。
   给所有粒子都加 200 m/s，平均速度变为 1200 m/s，相对速度保持原样，
   所以这部分整体加速不会改变温度。

   .. rubric:: 3. 运行与输出

   在 Linux/WSL 终端中，从 AlgoPlasma 仓库根目录运行。
   需要 CMake 3.20 或以上、C/C++ 编译器（C++20），绘图需要 Python 3 和 Matplotlib。
   默认无需 MPI/OpenMP。未传 --model 时生成进程独占的临时合成模型，退出时清理；--model DIR 只加载用户指定目录。

   .. code-block:: bash
      :caption: 从 AlgoPlasma 仓库根目录运行

      bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh

   脚本自动构建、运行并绘图。终端应出现 ``collision_box: PASS``。
   CSV 和图片写到 ``tests/009_collision/G02_MCC_network/examples/collision_box/results/``，
   这个生成结果目录已被 Git 忽略。

   修改参数时先给输出目录，再给选项：

   .. code-block:: bash

      bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh /tmp/box \
          --particles 50000 --steps 200 --dt 1e-7 --seed 42

   ``1e-7`` 表示 10 的负 7 次方。``--seed`` 为随机种子：
   在相同构建和设置下可复现实验，换种子会得到新的统计起伏。
   若模拟已打印 PASS、随后绘图报缺少 Matplotlib，可在有该库的 Python 环境中补画：

   .. code-block:: bash

      python3 tests/009_collision/G02_MCC_network/examples/collision_box/plot.py /tmp/box

   把 ``/tmp/box`` 换成实际结果目录。详细参数说明在算例目录的
   ``README.zh-CN.md`` （中文）和 ``README.en.md`` （英文）中。

   .. rubric:: 4. 三张图怎样读？

   .. list-table::
      :header-rows: 1
      :widths: 30 70

      * - 图片
        - 默认情况下应看到什么
      * - ``thermalization.png``
        - 从上到下为平均 x 速度、扣除整体运动后的温度、速率平方的平均值。
          平均速度趋近零，温度趋近 300 K。MCC 是模拟，Analytic 是理论参照。
      * - ``distributions.png``
        - 左图为 x 速度，末态集中在零附近并包含正负方向；右图为非负的速率。
          末态应接近 300 K 的 Maxwell（麦克斯韦）分布，粒子有快有慢。
      * - ``collision_counts.png``
        - 横轴为单个粒子的真实碰撞次数，纵轴为这样的粒子有多少个。
          平均次数约为 20，柱形统计围绕 Poisson（泊松）理论曲线起伏。

   热化图横轴 :math:`\nu t` 表示到该时刻每个粒子的理论平均碰撞次数，没有单位。
   默认频率下，横轴 1 对应 1 微秒。速度分布图纵轴是概率密度：
   一小段速度范围内的粒子比例约等于“高度 × 宽度”。
   有限样本会产生统计起伏，模拟曲线不需要与理论曲线逐点重合。

   .. rubric:: 5. PASS 检查了什么？

   .. container:: g02-checks

      ``checks.csv`` 每行的 ``observed`` 是实际值，``expected`` 是目标值，
      ``tolerance`` 是允许的绝对偏差，单位与该行被检查的量相同。
      满足 ``abs(observed - expected) <= tolerance`` 时，``pass`` 为 ``true``；
      否则为 ``false``，程序返回非零状态。

      - **守恒**：A 的动量/能量变化加上背景收到的交换量，应接近零；不能只检查 A 自身。
      - **随机计数**：恒定频率下的泊松分布，平均碰撞次数和方差都应接近 :math:`\nu t`。
        方差描述次数有多分散。程序也核对真实事件与空碰撞的计数。
      - **随时间的变化**：在 :math:`\nu t=2,10,20` 附近检查平均速度、平均速率平方；
        足够接近平衡后再检查末态分布。

      默认设置执行 20 项 CSV 检查，另有粒子编号、数量、位置等即时检查。
      缩短时间后，尚未达到的检查点和平衡分布检查会跳过；此时 PASS 只表示已执行的项目通过。
      统计容限考虑样本数，例如平均量主要允许六倍标准误差，即平均值的抽样波动尺度。

   .. rubric:: 6. 两个能自己验证的对照

   .. code-block:: bash

      # 没有背景粒子，应没有碰撞
      bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh /tmp/box_no_gas --density 0
      # 没有经过时间，状态也应保持不变
      bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh /tmp/box_no_time --dt 0

   增加 ``--particles`` 通常能减小统计噪声，不会改变背景密度。
   比较不同时间步长时，保持“步数 × 每步时长”相同。
   完整回归测试还包含初始平衡态及并行对照，见
   :doc:`009_collision 测试说明 </tests/009_collision/index>`。

   .. rubric:: 7. 先预测，再做两个小实验

   - 加上 ``--initial-temperature 300 --drift-x 0``：
     粒子初始就与背景平衡，温度应围绕 300 K 起伏，碰撞仍然持续。
   - 加上 ``--density 2e20 --steps 100 --dt 1e-7``：
     背景密度翻倍，总时间减半，在 10 微秒达到同样的 :math:`\nu t=20`。

   .. code-block:: bash

      bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh /tmp/box_double_density \
          --density 2e20 --steps 100 --dt 1e-7

   热化图横轴已经乘上碰撞频率。比较实际快慢时，看 history.csv 中的 time_s 列；
   按 :math:`\nu t` 看，两次实验仍遵循同一理论规律，允许各自的统计起伏。

   .. raw:: html

      <details class="g02-details">
        <summary>8. 理论曲线从哪里来？ · 展开推导说明</summary>

   .. only:: not html

      .. rubric:: 8. 理论曲线从哪里来？（可第二遍读）

   :math:`U` 为平均速度向量，:math:`Q` 为“先对每个粒子的速率平方，再取平均”；
   :math:`U_0,Q_0` 为实际初始样本的值。:math:`m` 为单个粒子的质量，:math:`T_B` 为背景温度，
   :math:`k_B=1.380649\times10^{-23}\,\mathrm{J/K}` 为联系温度与能量的玻尔兹曼常数。
   :math:`\nu` 为真实碰撞频率，:math:`t` 为经过的时间。

   下面的曲线由本算例模型推导，完整条件期望与 Poisson 平均见
   :ref:`碰撞盒理论曲线的推导 <g02-box-derivation-zh>`。两体运动学依据
   Ristivojevic–Petrović (2012)，事件时钟依据 Skullerud (1968) 与 Gillespie (1977)。
   本算例不声称复现这些论文的气体模型或数值结果；
   :ref:`测试依据 <g02-test-references-zh>` 列出文献与各测试的对应。

   本算例的等质量、恒频率弹性模型给出：

   .. math::

      U(t) = U_0 e^{-\nu t/2}, \qquad
      Q(t) = \frac{3 k_B T_B}{m} +
             \left(Q_0-\frac{3 k_B T_B}{m}\right)e^{-\nu t/2},

      T(t) = \frac{m}{3 k_B}\left(Q(t)-|U(t)|^2\right).

   :math:`e^{-\nu t/2}` 是从 1 逐渐趋近零的衰减因子。
   :math:`|U|^2` 是“平均速度的大小再平方”，与 Q 不同；第三式扣除了整体运动的动能。
   一次碰撞在统计平均上使 U 以及 Q 与背景值的差减半，
   再考虑随机碰撞次数就得到前两式；单次碰撞没有固定减半的要求。

   这些关系还要求背景固定、只有一条弹性通道、散射方向在质心系中各向同性。
   质心系随这对粒子的共同质心运动；各向同性表示在球面上均匀选方向。
   程序会验证这些假设，更换不兼容模型时会报错。

   .. raw:: html

      </details>

   .. rubric:: 9. 本算例中的碰撞概率

   抽样流程见 :ref:`G02 的实现说明 <g02-implementation-zh>`。
   本算例的真实碰撞频率为 :math:`10^6\,\mathrm{s}^{-1}`，默认步长为 0.1 微秒。
   “这一步内至少真实碰撞一次”的概率约 9.52%。
   编译模型的默认上界为真实频率的 1.05 倍，
   因此“已出现的候选被接受”的概率约 95.24%。
   前者针对一段时间，后者针对一个候选；碰撞次数图只统计真实事件。

   更详细的操作和物理解释保留在算例目录的
   :download:`中文教程 <../../../../tests/009_collision/G02_MCC_network/examples/collision_box/README.zh-CN.md>` 与
   :download:`English tutorial <../../../../tests/009_collision/G02_MCC_network/examples/collision_box/README.en.md>` 中。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - MCC (Monte Carlo Collision) uses random draws to decide collision timing, reaction type and outcomes; ensemble statistics should follow the model.
      - A null collision is a rejected candidate: sampled waiting time is consumed but the particle state stays unchanged. It is a sampling device, not a physical reaction.

   .. _g02-collision-box-en:

   This page explains the G02 zero-dimensional collision-box validation: understand the model, run the program,
   then read the plots and check the result. See :doc:`G02_MCC_network </rst_files/G_Collision/G02_MCC_network>`
   for MCC basics and program interfaces.

   .. rubric:: 1. Physical model: hot particles in a cold background
      :class: g02-chapter

   This test uses a simple model: hot A particles with a rightward drift collide with a colder B background.
   We follow the decay of their drift and their approach to the background temperature.
   A single elastic channel makes it possible to compare the random simulation against known reference results.

   .. figure:: ../../images/G_Collision/G02/physical_box_en.svg
      :alt: Hot A particles cool through collisions with a fixed B background
      :width: 100%

      Arrows show velocities and boxes group ideas. This is a schematic, not simulation output.
      Select the image to open it at full size.

   Zero-dimensional means one uniform region evolving in time.
   Each particle still has x, y and z velocity components.
   Positions are not advanced; there are no walls or electric fields, isolating the collision calculation.

   .. list-table:: Default experiment
      :header-rows: 1
      :widths: 30 70

      * - Item
        - Setting and meaning
      * - A particles
        - 50,000 particles, initially 3000 K with average x velocity of 1000 m/s.
      * - B background
        - Fixed at 300 K, about 27 °C; zero mean velocity, with individual particles still moving thermally.
      * - Reaction
        - A + B → A + B, elastic scattering with equal masses of 4 × 10⁻²⁶ kg.
      * - Collision frequency
        - Density 10²⁰ m⁻³ times rate coefficient 10⁻¹⁴ m³/s gives 10⁶ collisions per second per A on average.
      * - Duration
        - 200 steps of 0.1 microseconds: 20 microseconds, or 20 expected real collisions per A.

   .. admonition:: About the data
      :class: g02-caution

      A and B are fictional names. Synthetic data test software and cannot support conclusions about real gases.

   B remains at a fixed temperature: its received energy and momentum are recorded without updating its temperature.

   .. admonition:: Follow one particle

      Follow A001: store its velocity, sample a wait, sample a B partner for a real collision,
      compute velocities, then save A001 and record B exchange.
      Each A has a random history. Their average forms the temperature curve.
      One A may speed up in a collision while the population cools.

   .. rubric:: 2. Three numbers separate drift and temperature

   .. figure:: ../../images/G_Collision/G02/drift_temperature_en.svg
      :alt: Subtract a 1000 m/s mean from three velocities to obtain relative motion
      :width: 100%

      This arithmetic example shows x only; the simulation uses three components.
      Select the image to open it at full size.

   The mean of 400, 1000 and 1600 m/s is 1000 m/s; relative velocities are −600, 0 and +600 m/s.
   Adding 200 m/s to all three changes the mean to 1200 m/s but leaves relative motion,
   and therefore temperature, unchanged.

   .. rubric:: 3. Run and find the output

   Use a Linux/WSL terminal from the AlgoPlasma root.
   You need CMake 3.20 or newer, C/C++ compilers with C++20 support, and Python 3 with Matplotlib for plots.
   MPI and OpenMP are optional. Without --model the program creates a process-private temporary synthetic package and cleans it on exit; --model DIR loads only the specified directory.

   .. code-block:: bash
      :caption: Run from the AlgoPlasma repository root

      bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh

   The script builds, runs and plots. Look for ``collision_box: PASS``.
   CSV files and images go to ``tests/009_collision/G02_MCC_network/examples/collision_box/results/``,
   which Git ignores. To change parameters, give the output directory first:

   .. code-block:: bash

      bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh /tmp/box \
          --particles 50000 --steps 200 --dt 1e-7 --seed 42

   ``1e-7`` means 10 to the power −7. The ``--seed`` value selects a random sequence.
   The same build and settings reproduce it; a new seed gives new statistical fluctuations.
   If simulation prints PASS but plotting reports missing Matplotlib, redraw in a suitable Python environment:

   .. code-block:: bash

      python3 tests/009_collision/G02_MCC_network/examples/collision_box/plot.py /tmp/box

   Replace ``/tmp/box`` with the actual output path.
   Detailed parameter notes are in the example's ``README.en.md`` and ``README.zh-CN.md``.

   .. rubric:: 4. Read the three plots

   .. list-table::
      :header-rows: 1
      :widths: 30 70

      * - Plot
        - What to expect with the defaults
      * - ``thermalization.png``
        - Mean x velocity, temperature excluding drift, and mean squared speed, from top to bottom.
          Mean velocity approaches zero and temperature approaches 300 K. MCC is simulation; Analytic is theory.
      * - ``distributions.png``
        - Left: signed x velocities, finally centred near zero. Right: nonnegative speeds.
          The final state approaches a 300 K Maxwell distribution, with a spread of slow and fast particles.
      * - ``collision_counts.png``
        - Real collisions per particle on the horizontal axis; number of such particles on the vertical axis.
          The mean is about 20, with bars fluctuating around the Poisson expectation.

   The thermalization axis :math:`\nu t` is the expected real collision count per particle by that time.
   It has no units; 1 corresponds to 1 microsecond with the defaults.
   Velocity plots use probability density: the fraction in a small interval is approximately height times width.
   Finite samples fluctuate, so simulation and theory need not coincide at every point.

   .. rubric:: 5. What does PASS check?

   .. container:: g02-checks

      In ``checks.csv``, ``observed`` is the measured value, ``expected`` the target,
      and ``tolerance`` the allowed absolute difference in the units of that quantity.
      ``pass`` is ``true`` if ``abs(observed - expected) <= tolerance``.
      Otherwise it is ``false`` and the program returns a nonzero status.

      - **Conservation:** changes in A plus exchange recorded for B should balance; A alone exchanges energy and momentum.
      - **Random counts:** constant frequency gives Poisson mean and variance near :math:`\nu t`.
        Variance measures count spread. Real/null accounting is also checked.
      - **Time evolution:** mean velocities and squared speed are checked near :math:`\nu t=2,10,20`,
        and the final distribution when sufficiently close to equilibrium.

      Defaults execute 20 CSV checks plus immediate checks of particle IDs, counts and positions.
      Shorter runs skip unreached checkpoints and inapplicable equilibrium checks; PASS covers only executed checks.
      Statistical tolerances account for sample size. Mean checks mainly allow six standard errors,
      an estimate of sampling fluctuations in the mean.

   .. rubric:: 6. Two simple controls

   .. code-block:: bash

      # No background particles: no collisions
      bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh /tmp/box_no_gas --density 0
      # No elapsed time: unchanged states
      bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh /tmp/box_no_time --dt 0

   Increasing ``--particles`` usually reduces noise without changing background density.
   Keep steps × step duration fixed when comparing time steps.
   The full suite also covers equilibrium starts and parallel comparisons.
   See :doc:`009_collision tests </tests/009_collision/index>` for commands.

   .. rubric:: 7. Predict two experiments, then run them

   - Add ``--initial-temperature 300 --drift-x 0``: temperature should remain near 300 K,
     even though collisions continue.
   - Add ``--density 2e20 --steps 100 --dt 1e-7``: double density and halve total time,
     reaching :math:`\nu t=20` in 10 microseconds.

   .. code-block:: bash

      bash tests/009_collision/G02_MCC_network/examples/collision_box/run.sh /tmp/box_double_density \
          --density 2e20 --steps 100 --dt 1e-7

   The thermalization plot already scales time by frequency.
   Use history.csv's time_s to compare physical durations.
   Against :math:`\nu t`, both runs follow the same reference law with sampling fluctuations.

   .. raw:: html

      <details class="g02-details">
        <summary>8. Where do the reference curves come from? · Read the explanation</summary>

   .. only:: not html

      .. rubric:: 8. Where do the reference curves come from? (second reading)

   :math:`U` is mean velocity and :math:`Q` averages individual squared speeds.
   :math:`U_0,Q_0` are their measured initial values, :math:`m` is particle mass, and :math:`T_B` background temperature.
   The Boltzmann constant :math:`k_B=1.380649\times10^{-23}\,\mathrm{J/K}` connects temperature with energy.
   :math:`\nu` is real collision frequency and :math:`t` elapsed time.

   The curves are derived for this test model; see the
   :ref:`conditional-moment and Poisson derivation <g02-box-derivation-en>`.
   Binary kinematics is grounded in Ristivojevic–Petrović (2012), and the clock in
   Skullerud (1968) and Gillespie (1977). This case does not reproduce those papers
   or their numerical data. See :ref:`verification references <g02-test-references-en>`
   for the mapping to individual tests.

   This equal-mass elastic model with constant frequency gives:

   .. math::

      U(t) = U_0 e^{-\nu t/2}, \qquad
      Q(t) = \frac{3 k_B T_B}{m} +
             \left(Q_0-\frac{3 k_B T_B}{m}\right)e^{-\nu t/2},

      T(t) = \frac{m}{3 k_B}\left(Q(t)-|U(t)|^2\right).

   The factor :math:`e^{-\nu t/2}` decays from 1 towards zero.
   :math:`|U|^2` squares the mean velocity's magnitude and differs from Q.
   Subtracting it removes drift energy.
   On average one collision halves U and the difference between Q and its background value.
   Accounting for random collision counts gives the first two equations.
   Individual collisions do not always halve these quantities.

   The equations also assume a fixed background, one elastic channel and isotropic scattering in the centre-of-mass frame.
   This frame moves with the pair's shared centre of mass; isotropic means uniform directions on a sphere.
   The program rejects custom models that violate these assumptions.

   .. raw:: html

      </details>

   .. rubric:: 9. Collision probabilities in this example

   See :ref:`the G02 implementation guide <g02-implementation-en>` for the sampling workflow.
   The real frequency here is :math:`10^6\,\mathrm{s}^{-1}` and the default step is 0.1 microseconds.
   The probability of at least one real collision during that interval is about 9.52%.
   The model's default bound is 1.05 times the real rate, so an existing candidate is accepted with probability about 95.24%.
   One probability describes an interval; the other describes a candidate.
   The collision-count plot includes real events only.

   The example directory retains the more detailed
   :download:`English tutorial <../../../../tests/009_collision/G02_MCC_network/examples/collision_box/README.en.md>` and
   :download:`Chinese tutorial <../../../../tests/009_collision/G02_MCC_network/examples/collision_box/README.zh-CN.md>`.
