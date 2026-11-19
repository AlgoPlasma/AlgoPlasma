.. _g03-top:

.. rst-class:: ap-g03

G03_DSMC
========================================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   DSMC（Direct Simulation Monte Carlo，直接模拟蒙特卡洛）用带统计权重的粒子表示气体分布，
   把分子运动与局部碰撞分开处理，并用随机选对和散射抽样近似 Boltzmann 碰撞项。
   先从它与背景式 MCC 的区别、完整时间步和交互演示建立整体印象，
   随后沿合并的物理与算法正文理解推导，再用源码导读梳理整步调用。各模块的验证判据集中在验证页面。

.. container:: ap-lang ap-lang-en

   DSMC (Direct Simulation Monte Carlo) represents a gas distribution with weighted particle samples.
   Free motion and local collisions are split; random pair selection and scattering approximate the Boltzmann collision term.
   Start with the DSMC/MCC comparison, full time loop and interactive demonstration on this page, then follow
   Theory & Algorithm and Source Guide. Quantitative checks are collected on the validation page.

.. container:: ap-lang ap-lang-zh

   文中“调用程序”指组织初始化、粒子推进与边界处理、整个时间循环，
   并在碰撞阶段调用 G03 碰撞库的模拟程序。

.. container:: ap-lang ap-lang-en

   The calling program organizes initialization, particle transport, physical boundaries, the time loop and output,
   and invokes the G03 library during the collision stage.

.. _g03-reading-map:

.. rubric:: Two reading routes

.. container:: ap-lang ap-lang-zh

   .. list-table:: 子目录分别解决什么问题
      :header-rows: 1
      :widths: 24 46 30

      * - 左侧入口
        - 内容与作用
        - 适合什么时候阅读
      * - :doc:`Theory & Algorithm <G03_DSMC/fundamentals>`
        - 从粒子表示、分布与二体守恒开始，推导 HS/VHS/VSS 和输运标定；接着由 Boltzmann 碰撞算子推导配对率、上界、NTC 与连续时钟，最后说明非均匀柱坐标单元和随机抽样。公式旁展示实际函数、变量和源码行号。
        - 理解“物理依据是什么、怎样得到算法、公式具体在哪里实现”。
      * - :doc:`Source Guide <G03_DSMC/implementation>`
        - 沿 ``DsmcStepper::step`` 阅读柱坐标粒子定位、速度转换、分组、逐单元碰撞与统一写回，再说明模型构造和文件职责。
        - 阅读或修改主库时，追踪“一次调用怎样经过各个源码模块”。

.. container:: ap-lang ap-lang-en

   .. list-table:: What each chapter provides
      :header-rows: 1
      :widths: 24 46 30

      * - Navigation entry
        - Content and purpose
        - Use it to
      * - :doc:`Theory & Algorithm <G03_DSMC/fundamentals>`
        - Derive HS/VHS/VSS models and transport calibration from distributions and two-body invariants, then derive pair rates, majorants, NTC and the continuous clock from the Boltzmann collision operator. Nonuniform cylindrical cells and random sampling complete the chain. Equations are followed by actual functions, variables and source line numbers.
        - Connect physical assumptions, sampling algorithms and their implementation.
      * - :doc:`Source Guide <G03_DSMC/implementation>`
        - Follow ``DsmcStepper::step`` through particle location, coordinate conversion, grouping, cell collisions and velocity commit, then examine model construction and file responsibilities.
        - Trace one complete library call when reading or modifying the code.

.. container:: ap-lang ap-lang-zh

   初次学习可先读完本页的 DSMC/MCC 对比、完整流程与交互演示，
   再顺序阅读 **Theory & Algorithm → Source Guide**。
   完整调用示例与验证判据集中在 :doc:`Tests → 009_collision Tests → G03_DSMC Validation </tests/009_collision/G03_DSMC>`，
   用于组织算例和检查结果。

.. container:: ap-lang ap-lang-en

   For a first reading, finish this page before proceeding through **Theory & Algorithm → Source Guide**.
   Complete call examples and regression criteria are under :doc:`Tests → 009_collision Tests → G03_DSMC Validation </tests/009_collision/G03_DSMC>`.

.. toctree::
   :hidden:
   :maxdepth: 1
   :titlesonly:

   Theory & Algorithm <G03_DSMC/fundamentals>
   Source Guide <G03_DSMC/implementation>

.. _g03-overview-notation:

.. rubric:: Notation used on this page

.. container:: ap-lang ap-lang-zh

   .. list-table::
      :header-rows: 1
      :widths: 28 72

      * - 符号
        - 含义与单位
      * - :math:`\mathbf x_i,\mathbf v_i;\ g_{ij}=|\mathbf v_i-\mathbf v_j|`
        - 粒子位置（m）、速度（m/s）；一对粒子的相对速率（m/s）。
      * - :math:`\sigma(g),K(g)=\sigma(g)g`
        - 总碰撞截面（m²）与碰撞率核（m³/s）。截面描述有效碰撞面积，核还计入相对运动扫过的距离。
      * - :math:`W,N_c,V_c,n_c`
        - 每个模拟粒子代表的真实分子数、单元模拟粒子数、真实体积（m³）、物理数密度（m⁻³）；等权重样本给出的密度估计为 :math:`\widehat n_c=WN_c/V_c`。
      * - :math:`n_b,\phi_b(\mathbf w)`
        - 背景靶数密度（m⁻³）与归一化速度概率密度，:math:`\int\phi_b(\mathbf w)\,d^3w=1`。
      * - :math:`\nu_i,\lambda_{ij},\Delta t`
        - 单粒子碰撞频率与一对模拟粒子的事件率（s⁻¹）；物理时间步（s）。
      * - :math:`M_c,\omega,\alpha`
        - 单元碰撞核上界（m³/s）；黏度温度指数与 VSS 散射角参数（无量纲）。

.. container:: ap-lang ap-lang-en

   .. list-table::
      :header-rows: 1
      :widths: 28 72

      * - Symbol
        - Meaning and units
      * - :math:`\mathbf x_i,\mathbf v_i;\ g_{ij}=|\mathbf v_i-\mathbf v_j|`
        - Position (m), velocity (m/s), and pair relative speed (m/s).
      * - :math:`\sigma(g),K(g)=\sigma(g)g`
        - Total collision cross section (m²) and collision-rate kernel (m³/s). The kernel combines collision area and relative motion.
      * - :math:`W,N_c,V_c,n_c`
        - Real molecules represented per sample, cell sample count, physical volume (m³), and number density (m⁻³). For equal weights, :math:`\widehat n_c=WN_c/V_c`.
      * - :math:`n_b,\phi_b(\mathbf w)`
        - Background number density (m⁻³) and normalized velocity density, :math:`\int\phi_b\,d^3w=1`.
      * - :math:`\nu_i,\lambda_{ij},\Delta t`
        - Single-particle frequency and simulated-pair event rate (s⁻¹); physical time step (s).
      * - :math:`M_c,\omega,\alpha`
        - Cell kernel majorant (m³/s), viscosity-temperature exponent and VSS angular parameter (dimensionless).

.. _g03-comparison:

.. rubric:: DSMC and background MCC: representing and updating the target distribution

.. container:: ap-lang ap-lang-zh

   这里的 MCC 特指 G02 所采用的背景式实现。两者都使用蒙特卡洛抽样，也可以采用相同的碰撞截面。
   关键在于：**靶分布是由背景模型给定，还是由会被逐次更新的显式粒子表示。**
   这一区别决定了碰撞反冲和非平衡分布怎样影响后续事件。

.. container:: ap-lang ap-lang-en

   Here MCC means the background formulation used by G02. Both methods use Monte Carlo sampling and may use identical cross sections.
   The key distinction is how the target distribution is represented and updated: by prescribed background fields or by explicit particles retained after each collision.
   This determines how recoil and nonequilibrium structure influence later events.

.. container:: ap-lang ap-lang-zh

   对速度为 :math:`\mathbf v_i` 的粒子，背景式 MCC 先给定靶数密度 :math:`n_b` 与靶速度分布
   :math:`\phi_b(\mathbf w)`，将所有可能靶速度的贡献积分起来。
   等权重 DSMC 则以同单元的显式速度样本代替这一分布积分：

.. container:: ap-lang ap-lang-en

   For particle velocity :math:`\mathbf v_i`, background MCC integrates the kernel over the specified target density
   :math:`n_b` and normalized velocity distribution :math:`\phi_b(\mathbf w)`.
   Equal-weight DSMC replaces that distribution integral with explicit same-cell samples:

.. math::
   :label: g03-eq-mcc-dsmc-rates

   \begin{aligned}
   \text{background MCC:}\qquad
   \nu_i^{\mathrm{MCC}}
   &=n_b\int K(|\mathbf v_i-\mathbf w|)\phi_b(\mathbf w)\,d^3w,\\
   \text{equal-weight DSMC:}\qquad
   \lambda_{ij}
   &=\frac{W}{V_c}K(|\mathbf v_i-\mathbf v_j|),
   \qquad
   \nu_i^{\mathrm{DSMC}}=\sum_{j\ne i}\lambda_{ij}.
   \end{aligned}

.. container:: ap-lang ap-lang-zh

   这里应比较单粒子频率 :math:`\nu_i^{\mathrm{MCC}}` 与 :math:`\nu_i^{\mathrm{DSMC}}`，
   :math:`\lambda_{ij}` 是求和中的单对贡献。若背景由 :math:`N_b` 个等权重样本表示，且
   :math:`n_b=WN_b/V_c`，用样本均值近似积分就得到上述求和的结构。
   同种粒子配对排除自身，因此每个粒子的可选伙伴数为 :math:`N_c-1`。
   一次等权重模拟碰撞更新双方各 :math:`W` 个真实分子的代表状态，
   所以模拟事件率中只保留一个 :math:`W`；Theory & Algorithm 将从碰撞算子的弱形式推导这一事件率。

.. container:: ap-lang ap-lang-en

   Compare the single-particle frequencies :math:`\nu_i^{\mathrm{MCC}}` and :math:`\nu_i^{\mathrm{DSMC}}`;
   :math:`\lambda_{ij}` is one term in the latter sum. If :math:`n_b=WN_b/V_c`, a sample-mean approximation to the background integral has the same sum structure.
   Same-species pairing excludes the particle itself, leaving :math:`N_c-1` possible partners.
   One simulated event updates representatives of :math:`W` molecules on each side, so its statistical rate contains one factor of :math:`W`.
   Theory & Algorithm derives this rate from the weak collision operator.

.. container:: ap-lang ap-lang-zh

   .. list-table::
      :header-rows: 1
      :widths: 18 41 41

      * - 环节
        - 背景式 MCC
        - 显式粒子对 DSMC
      * - 保存靶分布
        - 由给定或耦合演化的背景密度、温度及分布模型描述。
        - 同单元内现有粒子的速度集合就是分布样本，可以表达双束流等非 Maxwell 分布。
      * - 选择碰撞伙伴
        - 从背景分布抽取临时靶速度，并按碰撞核筛选，使被接受事件具有正确的速率权重。
        - 从同单元现有粒子中选两个不同 ID，再按它们当前的相对速率筛选。
      * - 更新状态
        - 更新被跟踪粒子；背景的动量、能量收支可以交给调用程序中的背景演化模型。G02 用 ``report.reservoir`` 返回这类收支。
        - 更新双方速度并保留在粒子集合中；弹性二体更新保持这对粒子的总动量与总动能。
      * - 下一次事件
        - 固定背景仍使用原分布；有反馈时，变化取决于调用程序实际演化的背景变量。
        - 读取已经更新的粒子速度，反冲直接改变后续配对及散射结果。
      * - 适合表达的问题
        - 被跟踪组分与给定或可用少量宏观量描述的背景之间的碰撞。
        - 气体自身的分布演化、碰撞弛豫，以及需要显式保留碰撞双方反馈的过程。

.. container:: ap-lang ap-lang-en

   .. list-table::
      :header-rows: 1
      :widths: 18 41 41

      * - Stage
        - Background MCC
        - Explicit-pair DSMC
      * - Target distribution
        - Specified or coupled background density, temperature and distribution model.
        - The current particle velocities represent the distribution, including two-beam and other non-Maxwellian states.
      * - Partner selection
        - Draw a temporary target velocity and apply kernel weighting.
        - Select distinct particle IDs in the same cell and accept using their current relative speed.
      * - State update
        - Update the tracked particle; the calling program can evolve background momentum and energy using G02's ``report.reservoir``.
        - Update and retain both velocities. Elastic pair momentum and kinetic energy are conserved.
      * - Next event
        - A fixed background retains its specified distribution; feedback depends on the background evolution model.
        - Updated velocities directly affect subsequent selection and scattering.
      * - Typical use
        - Collisions with a prescribed background or one described by a few evolving macroscopic fields.
        - Gas self-relaxation and processes requiring explicit feedback from both collision partners.

.. container:: ap-lang ap-lang-zh

   **用一次碰撞看清差别。** 两个等质量粒子以
   :math:`\mathbf v_i=(1000,0,0)`、:math:`\mathbf v_j=(0,0,0)\,\mathrm{m/s}` 入射。
   质心速度为 :math:`(500,0,0)\,\mathrm{m/s}`；如果弹性散射把相对速度从 x 轴转到 y 轴，末态为

.. container:: ap-lang ap-lang-en

   **A single collision illustrates the difference.** Let two equal-mass particles enter with
   :math:`\mathbf v_i=(1000,0,0)` and :math:`\mathbf v_j=(0,0,0)\,\mathrm{m/s}`.
   Their center-of-mass velocity is :math:`(500,0,0)\,\mathrm{m/s}`. Rotating the relative velocity from x to y gives

.. math::
   :label: g03-eq-comparison-example

   \mathbf v_i'=(500,500,0)\,\mathrm{m/s},\qquad
   \mathbf v_j'=(500,-500,0)\,\mathrm{m/s}.

.. container:: ap-lang ap-lang-zh

   两者的速度和仍为 :math:`(1000,0,0)\,\mathrm{m/s}`，速度平方和也保持不变，
   所以等质量条件下总动量、总动能均守恒。DSMC 把这两个末态都留在粒子表中。
   固定背景 MCC 保留被跟踪粒子的末态，下次重新抽靶时仍使用原背景；
   带反馈的 MCC 可以把另一方的收支交给背景方程，但保留多少分布信息由背景模型决定。

.. container:: ap-lang ap-lang-en

   The velocity sum remains :math:`(1000,0,0)\,\mathrm{m/s}` and the sum of squared speeds is unchanged,
   so equal-mass momentum and energy are conserved. DSMC retains both final states.
   Fixed-background MCC retains the tracked particle and samples the original target distribution again at the next event.
   A coupled background model may receive the other partner's balance, with retained distribution information determined by that model.

.. container:: ap-lang ap-lang-zh

   物种、碰撞通道和分布反馈需求共同决定具体建模；这里的区别在于靶分布的表示与更新方式。

.. container:: ap-lang ap-lang-en

   Species, reaction channels and required distribution feedback determine the application model;
   the comparison here concerns representation and updating of the target distribution.

.. _g03-framework:

.. rubric:: The complete DSMC time loop

.. container:: ap-lang ap-lang-zh

   空间 DSMC 的完整循环包含粒子运动、边界、局部分组、随机碰撞和宏观采样。
   下面用带终止判断的程序循环图表示它；主路径是中性气体 DSMC，右侧虚线框是在调用程序中耦合 PIC 时才需要的场处理。
   图中采用“先输运、后碰撞”的一阶分裂。

.. container:: ap-lang ap-lang-en

   Spatial DSMC combines transport, boundaries, cell assignment, stochastic collisions and macroscopic sampling.
   The diagram shows a loop with a stopping condition. Neutral DSMC follows the main path;
   the blue dashed branch adds PIC field operations in the calling program.
   The illustrated first-order split performs transport before collisions.

.. container:: g03-diagram g03-program-loop

   .. figure:: /_static/G_Collision/G03_DSMC/dsmc-pic-loop.svg
      :alt: DSMC program loop: initialization, stop condition, optional PIC deposition and field solve, particle transport and boundaries, cell assignment, cell collisions, sampling, and time update. The collision substep loops over cells.
      :width: 760px

      DSMC / PIC program loop.

.. container:: ap-lang ap-lang-zh

   灰色：调用程序的流程控制与粒子输运；绿色：DSMC 局部碰撞；蓝色虚线：可选 PIC 场耦合。
   主循环沿竖直方向推进，右侧连线返回时间步判断；绿色框内逐单元处理碰撞。

.. container:: ap-lang ap-lang-en

   Gray denotes application control and transport; green denotes local DSMC collisions; the dashed blue branch denotes optional PIC field coupling.
   The main loop proceeds downward and returns along the right edge to the time-step condition; the green region iterates over cells.

.. container:: ap-lang ap-lang-zh

   **怎样区分 DSMC 与 PIC。** DSMC 用局部随机二体碰撞近似 Boltzmann 碰撞项，完整空间算法还包含分子飞行。
   PIC 用粒子样本与网格场之间的沉积和插值求解自洽场作用；PIC 本身可以是无碰撞的。
   把两者耦合时，调用程序可以对相应组分调用 DSMC 或 MCC 碰撞模块。
   纯中性、无外力 DSMC 跳过蓝色分支，按直线飞行；带电粒子则由调用程序结合场推进速度与位置。
   G03 提供中性单组分弹性碰撞；电子、离子与场的演化由调用程序中相应的物理模块承担。

.. container:: ap-lang ap-lang-en

   **DSMC and PIC responsibilities.** DSMC approximates the local Boltzmann collision term using random binary events;
   a spatial simulation also transports the molecules. PIC couples particle deposition and field interpolation to self-consistent fields and can operate without collisions.
   A coupled calling program applies DSMC or MCC to the appropriate species.
   Force-free neutrals follow straight trajectories along the neutral branch; charged particles require a field-dependent pusher.
   G03 supplies single-species neutral elastic collisions; electron, ion and field evolution belong to the corresponding application modules.

.. container:: ap-lang ap-lang-zh

   PIC 场网格、DSMC 碰撞单元和宏观采样网格承担不同任务，可以分开设置。
   本页用一条顺序表示信息流；实际 PIC 采用何种沉积时刻、推进器、时间交错与子循环，由调用程序的离散方案决定。

.. container:: ap-lang ap-lang-en

   PIC field cells, DSMC collision cells and sampling cells serve different purposes and may use different meshes.
   This diagram shows information flow. Deposition timing, velocity staggering and subcycling follow the calling program's discrete scheme.

.. container:: ap-lang ap-lang-zh

   **① 初始化：先确定要模拟的分布。** 初始位置来自空间密度分布，速度来自局部速度分布，
   例如带平均流速的 Maxwell 分布或两束相向气流。统一权重下，
   :math:`\mathbb E[N_c]\approx n_cV_c/W`；粒子数和体积必须相互匹配。
   柱坐标中的均匀体积分布按 :math:`r\,dr\,d\theta\,dz` 抽样，径向样本的 :math:`r^2` 均匀分布；
   Theory & Algorithm 的单元部分给出非均匀三维柱坐标的真实体积与单元归属。

.. container:: ap-lang ap-lang-en

   **① Initialization: choose the represented distribution.** Sample positions from spatial density and velocities from the local velocity distribution,
   for example a drifting Maxwellian or counterstreaming beams. Equal weights require :math:`\mathbb E[N_c]\approx n_cV_c/W`.
   Uniform cylindrical volume sampling uses :math:`r\,dr\,d\theta\,dz`, so :math:`r^2` is uniform radially.
   The cell section derives volumes and location rules for a nonuniform three-dimensional cylindrical mesh.

.. container:: ap-lang ap-lang-zh

   **② 运动与边界：改变粒子所在的位置和可配对的邻居。** 无外力且未遇边界时，
   :math:`\mathbf x_i\leftarrow\mathbf x_i+\mathbf v_i\Delta t`。
   壁面可能改变速度，开口边界可能增删粒子；这些过程完成后才能建立本次碰撞的成员表。
   碰撞单元面用于分组，物理壁面由调用程序的边界模型指定。

.. container:: ap-lang ap-lang-en

   **② Transport and boundaries: update positions and possible neighbors.** A force-free uninterrupted flight gives
   :math:`\mathbf x_i\leftarrow\mathbf x_i+\mathbf v_i\Delta t`.
   Walls can change velocities; open boundaries can add or remove particles. Finish these operations before building collision membership.
   Collision-cell faces define grouping, while the calling program defines physical walls.

.. container:: ap-lang ap-lang-zh

   **③ 分组：用小单元实现碰撞的局部性。** Boltzmann 碰撞项针对同一位置的分布，
   DSMC 以足够小单元中的粒子集合近似这一局部分布。
   粒子可以在输运阶段跨单元；在随后的弹性碰撞子步中，位置与单元成员保持不变。
   非均匀单元逐个使用自己的真实体积；柱坐标局部速度须先转换到共同基底后才能相减。

.. container:: ap-lang ap-lang-en

   **③ Grouping: approximate spatial locality.** The Boltzmann collision term acts on a distribution at one position;
   DSMC approximates it with particles in a sufficiently small cell. Transport may cross cell faces;
   positions and membership remain fixed during the subsequent elastic collision substep.
   Each nonuniform cell uses its physical volume. Transform local cylindrical velocity components to a common basis before taking differences.

.. container:: ap-lang ap-lang-zh

   **④ 碰撞：生成候选，按碰撞核接受。** 对单元 c，令
   :math:`M_c` 是整段碰撞子步内 :math:`K(g)` 的有效上界，候选次数的期望为

.. container:: ap-lang ap-lang-en

   **④ Collisions: generate and accept candidates.** For cell c, let :math:`M_c` bound the kernel throughout the collision substep.
   The expected candidate count and acceptance probability are

.. math::
   :label: g03-eq-overview-ntc

   A_c=\frac{N_c(N_c-1)}{2}\frac{W\Delta t}{V_c}M_c,
   \qquad
   P_{\mathrm{acc}}(i,j)=\frac{K(g_{ij})}{M_c}.

.. container:: ap-lang ap-lang-zh

   主库提供两种候选调度。默认 **NTC** 对 :math:`A_c` 无偏随机舍入，得到本步候选数；
   可选的 **连续时间候选时钟** 按总候选率 :math:`\Lambda_c=N_c(N_c-1)WM_c/(2V_c)` 抽取指数等待时间，
   逐次处理落在本步内的候选。两者的候选数期望均为 :math:`A_c`，
   前者取相邻两个整数，后者服从 Poisson 分布。

.. container:: ap-lang ap-lang-en

   The default **NTC** schedule rounds :math:`A_c` without bias. The alternative **continuous candidate clock** samples exponential waiting times
   at total candidate rate :math:`\Lambda_c=N_c(N_c-1)WM_c/(2V_c)` and processes events inside the substep.
   Both counts have mean :math:`A_c`; randomized rounding takes adjacent integers, while the clock produces a Poisson count.

.. container:: ap-lang ap-lang-zh

   每次均匀选择一对不同粒子，以 :math:`P_{\mathrm{acc}}` 接受，接受后按模型角分布更新双方速度；
   后续候选使用更新后的速度。这一共同过程使选对和接受抽样对应目标配对率。
   在有效上界下，连续时钟精确抽样固定位置、固定成员的有限粒子碰撞跳跃过程；
   NTC 以有限时间步近似该过程。完整空间 DSMC 还包含时间分裂、单元尺度和有限样本误差。
   Theory & Algorithm 的“单元碰撞：NTC 与连续时钟”逐步推导两种调度及其区别。

.. container:: ap-lang ap-lang-en

   For each candidate, select a distinct pair uniformly, accept with :math:`P_{\mathrm{acc}}`, and sample the model's outgoing direction.
   Later candidates use the updated velocities. This thinning recovers the target pair rates.
   With a valid majorant, the continuous clock exactly samples the fixed-position, fixed-membership finite-particle collision jump process;
   NTC approximates it at finite time step. Spatial DSMC also has splitting, cell-size and finite-sample errors.
   The collision-schedule section derives these statements.

.. container:: ap-lang ap-lang-zh

   **⑤—⑥ 采样与推进时间：从样本回到宏观量。** 对单组分等权重粒子，单元中有足够样本时可估计

.. container:: ap-lang ap-lang-en

   **⑤–⑥ Sampling and time advancement: recover macroscopic quantities.** With enough equal-weight samples in a single-species cell, estimate

.. math::
   :label: g03-eq-overview-moments

   \widehat n_c=\frac{WN_c}{V_c},\qquad
   \widehat{\mathbf u}_c=\frac{1}{N_c}\sum_{i\in c}\mathbf v_i,\qquad
   \widehat T_c=\frac{m}{3k_BN_c}\sum_{i\in c}
                  |\mathbf v_i-\widehat{\mathbf u}_c|^2.

.. container:: ap-lang ap-lang-zh

   温度由相对平均流速的二阶矩估计；有限样本修正和时间平均在统计处理中完成。
   输运与碰撞各推进同一个 :math:`\Delta t`，合成一步后物理时间增加 :math:`\Delta t`。
   NTC 记录候选序号，连续时钟记录碰撞子问题中的局部事件时间。

.. container:: ap-lang ap-lang-en

   Temperature uses the central second moment; finite-sample corrections and time averages belong to statistical processing.
   Transport and collisions each evolve the same :math:`\Delta t`, and their composition advances physical time by :math:`\Delta t`.
   NTC records a candidate index; the continuous clock records local event time in the collision subproblem.

.. container:: ap-lang ap-lang-zh

   时间步解析局部碰撞和流动变化，碰撞单元控制配对的空间局部性，样本数决定统计分辨率。
   这些误差分别通过时间、空间和粒子数收敛试验评估。

.. container:: ap-lang ap-lang-en

   Time-step refinement resolves collision and flow changes, cell refinement tests spatial locality, and particle-count refinement tests statistical resolution.
   Evaluate these errors separately.

.. rubric:: G03 responsibilities in this loop

.. container:: ap-lang ap-lang-zh

   本主库实现 **单组分、中性单原子、等统计权重的 HS/VHS/VSS 弹性碰撞**，
   通过统一的柱坐标入口完成③的定位与分组以及④的局部碰撞。
   它支持不等体积碰撞单元；调用程序组织粒子推进、物理边界和整个时间循环。

.. container:: ap-lang ap-lang-en

   The library implements **single-species, neutral, monatomic, equal-weight HS/VHS/VSS elastic collisions**.
   Its cylindrical entry performs location and grouping in ③ and the local collisions in ④.
   Cells may have unequal volumes. The calling program organizes transport, physical boundaries and the outer time loop.

.. container:: ap-lang ap-lang-zh

   .. list-table::
      :header-rows: 1
      :widths: 23 47 30

      * - 工作
        - 需要的数据与结果
        - 负责者
      * - 初始化、运动与边界
        - 创建粒子并推进位置；按实际边界处理速度和粒子进出。
        - 调用程序。
      * - 准备碰撞单元
        - 根据位置确定粒子 ``cell_id``，从网格取得真实体积，并建立共同基底下的速度。
        - 调用程序提供柱坐标位置；G03 在创建碰撞快照时完成单元定位与速度基底转换。
      * - 执行一次碰撞步
        - 读取工作副本，逐单元使用 NTC 或连续候选时钟，检查守恒；全部成功后统一写回速度。
        - ``DsmcStepper::step()``。
      * - 采样、输出、下一步
        - 使用更新后的粒子和碰撞报告，组织统计与时间循环。
        - 调用程序。

.. container:: ap-lang ap-lang-en

   .. list-table::
      :header-rows: 1
      :widths: 23 47 30

      * - Task
        - Data and result
        - Owner
      * - Initialization, transport and boundaries
        - Create particles, advance positions, and handle boundary velocities and particle entry/exit.
        - Calling program.
      * - Prepare collision cells
        - Determine ``cell_id``, physical volume and common-frame velocities from particle positions.
        - The calling program supplies cylindrical positions; G03 locates particles and rotates velocities when creating snapshots.
      * - Collision substep
        - Evolve a working copy cell by cell using NTC or the clock, check conservation, then commit all velocities.
        - ``DsmcStepper::step()``.
      * - Sampling, output and next step
        - Use updated particles and reports to organize diagnostics and the time loop.
        - Calling program.

.. container:: ap-lang ap-lang-zh

   均匀气体弛豫可以省略空间运动，固定单元后反复执行④—⑥；它仍能展示碰撞率、守恒和分布弛豫。
   空间流动则必须补齐②—③。本页开头列出阅读入口，完整源码索引集中在 Source Guide。

.. container:: ap-lang ap-lang-en

   A homogeneous relaxation experiment can hold one cell fixed and repeat ④–⑥ to study rates, conservation and distribution relaxation.
   Spatial flow also needs transport and regrouping in ②–③. Source Guide provides the complete source index.

.. _g03-animation:

.. rubric:: Interactive walkthrough

.. container:: ap-lang ap-lang-zh

   先看“DSMC 核心过程”，跟随运动、分组、候选与接受事件走完一步；
   再进入“碰撞模型比较”，区分碰撞频率与碰后方向这两个不同问题。

.. container:: ap-lang ap-lang-en

   Start with “DSMC 核心过程” (DSMC core process) to follow transport, grouping, candidates and accepted events through one step.
   Then use “碰撞模型比较” (collision-model comparison) to separate event frequency from outgoing directions.

.. container:: ap-lang ap-lang-zh

   演示采用教学截面与单位，提供粒子运动、选对、散射及反应过程的可视化。
   先按下面的读图指南了解各面板的入射条件、坐标与统计量，再操作演示面板。

.. container:: ap-lang ap-lang-en

   The demonstration uses teaching cross sections and units to visualize transport, selection, scattering and reactions.
   Read the guide below for incident conditions, axes and statistics before operating its panels.

.. _g03-demo-guide:

.. rubric:: Three suggested observations

.. container:: ap-lang ap-lang-zh

   1. **走完一个时间步。** 在“DSMC 核心过程”中选择“撞壁与跨胞元”，点击“单步”或“完成本步”，
      观察粒子先移动、再按新位置分组，随后在单元内进行碰撞。
      “下一碰撞 / 步末”会停在下次接受事件或本步结束；没有接受事件也是正常结果。
   2. **看一次碰撞究竟更新什么。** 选择一个事件，检查两个粒子的 ID、碰前碰后速度和随机决策。
      通道筛选及“寻找下一目标碰撞”可以定位所需记录。固定种子后，可用“从种子运行这些步”重复观察同一次实验。
   3. **区分频率和方向。** 在“碰撞模型比较”中选择 A–A，先使用“相同初态（固定相对能量）”，
      再切换“一群不同速率的粒子”，比较改变 :math:`\omega` 与 :math:`\alpha` 后各图的变化。

.. container:: ap-lang ap-lang-en

   1. **Complete one time step.** In “DSMC 核心过程”, choose “撞壁与跨胞元” (wall hits and cell crossings), then “单步” or “完成本步”.
      Watch transport precede grouping and collisions. “下一碰撞 / 步末” stops at the next accepted event or the end of the step; a step can have no accepted event.
   2. **Inspect the pair update.** Select an event and inspect IDs, pre/post velocities and random decisions.
      Channel filters and “寻找下一目标碰撞” locate records. Fix the seed and use “从种子运行这些步” to replay the experiment.
   3. **Separate frequency from direction.** Select A–A in the model-comparison panel. Compare fixed-relative-energy incidents with a population of different incident speeds,
      then vary :math:`\omega` and :math:`\alpha`.

.. include:: G03_DSMC/extensions.inc

.. rubric:: Interactive demonstration

.. raw:: html

   <iframe class="g03-collision-demo" title="Interactive DSMC process and collision-model demonstration" src="../../_static/G_Collision/G03_DSMC/collision-demo.html" loading="lazy" height="1600"></iframe>

.. container:: ap-lang ap-lang-zh

   .. raw:: html

      <p><a href="../../_static/G_Collision/G03_DSMC/collision-demo.html" target="_blank" rel="noopener">在独立页面打开交互演示</a></p>

.. container:: ap-lang ap-lang-en

   .. raw:: html

      <p><a href="../../_static/G_Collision/G03_DSMC/collision-demo.html" target="_blank" rel="noopener">Open the interactive demonstration in a separate page</a></p>
