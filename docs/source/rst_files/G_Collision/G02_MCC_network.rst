.. rst-class:: ap-g02 ap-g02-guide

G02_MCC_network
==================================================

.. toctree::
   :maxdepth: 2
   :hidden:

   Basics <G02_MCC_network/group_foundation>
   Model <G02_MCC_network/group_model_data>
   Collision <G02_MCC_network/group_collision>
   MPI <G02_MCC_network/group_mpi_interface>
   References <G02_MCC_network/references>

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. _g02-mcc-basics-zh:

   .. rubric:: 1. MCC 用概率处理碰撞
      :class: g02-chapter

   MCC（Monte Carlo Collision，蒙特卡洛碰撞）用随机数决定三件事：**什么时候碰撞、选哪条反应、碰后怎样变化**。单个粒子的经历有起伏，大量粒子的统计应符合输入的反应模型。

   被跟踪的粒子叫 projectile；一次事件后这条原记录的结果叫 primary。背景（background）用数密度、温度和平均速度描述，需要碰撞搭档速度时再从背景分布抽样。一个通道定义反应物、产物和发生速率；多个通道组成反应网络。

   截面 σ 的单位是 m²；给定相对速率 g 时，二体碰撞频率为 nσg。温度速率系数 k 的二体单位是 m³/s，频率为 nk；三体单位是 m⁶/s，频率为 n₁n₂k，同种背景计量为 2 时取 n²k。

   .. math::

      P(\text{至少一次真实碰撞}) = 1-\exp(-\nu\Delta t)

   这个式子适用于真实频率 ν 恒定的时间段。νΔt=0.1 时，至少一次的概率约 9.52%；同一步也可以发生多次碰撞。弹性碰撞保留双方总动量和总动能，但单个粒子仍会变快或变慢。温度来自扣除平均漂移后的热运动，不能把整体漂移算进温度。

   .. _g02-implementation-zh:

   .. rubric:: 2. G02 的程序框架
      :class: g02-chapter

   G02 是独立 C++20 实现，**不调用 G01**。主程序提供粒子、背景和 dt；G02 返回粒子变化、反应计数和背景收支。新主程序推荐从批量 ``MccStepper::step()`` 接入。

   .. _g02-csv-input-zh:

   .. rubric:: 2.1 初始化：读取模型

   ``MccEngine::load(model_dir)`` 从用户模型目录读取 ``manifest.csv``，按它的相对路径读取物种、内部态、反应、速率和数值表。先检查文本与引用，再用 ``compile_model`` 核对反应阶数、单位、能量、电荷和已声明的元素组成，整理活动通道与频率上界。这里“编译模型”指整理运行数据。

   模型通常只加载一次。仓库不携带截面数据文件或空白表格；写法、表头、单位和完整内联示例见 :doc:`CSV 数据格式与填写 <G02_MCC_network/csv_format>`。测试运行时生成的数据只用于软件验证。

   .. _g02-architecture-zh:

   .. rubric:: 2.2 程序总流程与模块分工

   .. figure:: ../../images/G_Collision/G02/architecture_zh.svg
      :alt: 标准 MCC 总流程图：初始化、批量碰撞处理、成功判断、统一提交与时间步循环
      :width: 100%
      :figclass: g02-flowchart

      灰字标出对应函数和文件；C++ 源文件位于 ``G_Collision/G02_MCC_network/``。标为“内部”的函数供库内部调用。

   - ``model/compile/table/csv``：读取、检查反应数据，准备查表和频率上界。
   - ``batch``：接入宿主粒子容器、复用工作区、分配产物 ID 和统一提交。
   - ``engine``：按物种和内部态选择通道，抽样候选时间与接受/拒绝。
   - ``kinematics``：生成符合动量、能量和反应规则的末态。
   - 可选 ``mpi``：协调各进程准备、错误状态和全局新 ID；主程序仍负责网格划分和粒子迁移。

   方法依据为 Skullerud (1968) 的空碰撞方法与 Vahedi–Surendra (1995) 的 PIC-MCC 文献；
   指数时钟、热背景及本库流程的具体对应见 :ref:`方法出处 <g02-method-references-zh>`。

   .. rubric:: 2.3 每个时间步

   .. figure:: ../../images/G_Collision/G02/step_flow_zh.svg
      :alt: 标准 MCC 时间步流程图：粒子循环、候选等待、真实与空碰撞分支、剩余时间循环及提交
      :width: 100%
      :figclass: g02-flowchart

      任一准备阶段出错都走异常出口，包括频率上界、候选上限、守恒、产物 ID 和存储容量检查；此时不提交粒子更新。

   1. 读取背景和粒子快照，找到匹配 ``species/state`` 的通道。没有通道或频率上界为零，则该粒子本步无需候选。
   2. 用总频率上界 Λ 抽样等待时间 τ=−ln(1−u)/Λ。等待超过剩余 dt，就结束该粒子。
   3. 候选落在本步内时，先扣除等待时间，再按各通道上界份额选反应，按“该通道真实频率÷该通道上界”接受或拒绝。接受时调用 C02–C08；拒绝就是 null collision（空碰撞），保持状态。
   4. 按更新后的物种和态重新找通道，继续剩余时间；主粒子移除时结束，新产物从下一步参与。
   5. 所有粒子处理成功后，汇总统计、分配新 ID、准备存储，再统一提交。准备或容量检查失败时不改可见粒子。

   真实频率超过上界会报错，不把它截成上界。频率上界过松会增加空碰撞。空碰撞也消耗等待时间；候选超出本步时不执行，下一步重新抽样。

   .. figure:: ../../images/G_Collision/G02/event_timeline_zh.svg
      :alt: 一步内的真实事件、空碰撞和超过剩余时间的候选
      :width: 100%

      时刻是流程示意，不是模拟结果。

   G02 内部的 C01 是公共抽样流程；CSV 的反应算法填 C02–C08，分别表示弹性、离散态跃迁、解离、电离、附着/脱附、电荷交换和复合/中和。不要把这些编号与 ``C_Gather`` 的模块编号混用。

   .. rubric:: 2.4 推荐的 C++ 批量调用

   下面是完整可构建程序。``argv[1]`` 是模型目录；这个演示要求模型含 A/B 物种。文档调用检查在运行时生成合成模型，手动用法见测试目录中的 ``examples/doc_snippets/README.md``。

   .. literalinclude:: ../../../../tests/009_collision/G02_MCC_network/examples/doc_snippets/batch.cpp
      :language: cpp

   适配器和 ``MccWorkspace`` 在时间循环外创建。无工作区的重载也能调用，但会分配一次性临时内存；同一物理时间步只调用一个重载一次。宿主用 ``report.reservoir`` 中的收支更新下一步背景，G02 不自行演化背景。

   .. rubric:: 2.5 单粒子与批量入口的差别

   .. list-table:: 入口定位
      :header-rows: 1
      :widths: 24 76

      * - 入口
        - 时间推进与写回
      * - ``MccStepper::step()``
        - 完整推进原有主粒子的剩余 dt，统一提交更新、移除、物种迁移和新产物。默认每粒子候选上限 1000000，超限抛 Error，准备失败不提交。
      * - ``MccEngine::collide_full()``
        - 单粒子完整推进，物种改变后继续，移除后结束；默认候选上限 1000000，超限抛 Error。返回 StepOutcome，宿主负责写回和产物存储。
      * - ``MccEngine::collide()``
        - 单粒子受限推进。request.max_events_per_step=0 选模型默认 64 个候选（包括空碰撞）；达到上限返回 event_limit_reached。MoveSpecies/Remove 也会提前结束，返回不保证 dt 全部处理完。

   三个入口都在 G02 中；这里的差别是推进行为，与 G01/G02 版本无关。``collide()`` 可处理多次碰撞，名称中的“单粒子”指输入对象数量。

   .. _g02-data-types-zh:

   .. rubric:: 2.6 数据对象和单位

   - ``ParticleState``：物种 ID、内部态 ID、稳定唯一粒子 ID、网格编号 cell、速度 m/s、权重、出生步。保留适配器和 ID 高水位，避免复用删除粒子的 ID。
   - ``CellBackground``：cell 和背景组分；背景数密度 m⁻³、温度 K、平均速度 m/s。cell=UINT32_MAX 表示全域备用背景，局部网格编号须与粒子一致。
   - 背景 ``invalid_state=65535`` 表示按物种合并的密度，不是基态，也不会自动分配各态密度；入门时填写模型的实际内部态 ID。
   - ``StepOutcome``：单粒子的 primary_action/primary_after、产物 created、背景 reservoir 和候选计数；宿主按 Update/MoveSpecies/Remove 写回，event_limit_reached 表示受限入口达到候选上限。
   - ``StepReport``：候选/真实/空事件、反应计数、背景粒子数/动量/能量收支、守恒账本和计时。接口失败抛 ``algoplasma::mcc::Error``。

   .. rubric:: 2.7 构建与检查

   在 Linux/WSL 仓库根目录运行，需要 CMake 3.20 与 C++20 编译器：

   .. code-block:: bash

      cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_build -DCMAKE_BUILD_TYPE=Debug
      cmake --build /tmp/g02_build -j 4
      ctest --test-dir /tmp/g02_build --output-on-failure

   CTest 在 build 的 generated_models 下生成合成模型。只构建库用 ``-DG02_MCC_BUILD_TESTS=OFF``；外部 CMake 使用 ``find_package(G02_MCC_network CONFIG REQUIRED)``，链接 ``AlgoPlasma::G02_MCC``。检查用户模型可运行 ``g02_validate_model /path/to/my_model``。

   .. _g02-acceleration-zh:

   .. rubric:: 3. 工作区与 CPU 并行
      :class: g02-chapter

   复用 ``MccWorkspace`` 可以减少内存分配，并缓存同模型、背景、网格、物种和内部态的活动通道；相关输入变化时缓存失效。同一工作区或适配器不能并发重入。

   OpenMP 需要构建时开启 ``G02_MCC_ENABLE_OPENMP``，并选择 ``CpuBackend::OpenMp``。MPI 需要 ``G02_MCC_ENABLE_MPI``、``mpi.hpp`` 和 ``AlgoPlasma::G02_MCC_MPI``；所有相关进程共同调用分布式步进器。MPI 线程支持至少为 MPI_THREAD_FUNNELED，在 MPI_Finalize 前销毁步进器。

   默认前缀通道抽样，多通道可以选择别名采样。用固定模型、粒子数和步数比较 Release 整步耗时，同时核对统计、守恒和串行/并行一致性。详见 :doc:`MPI 接口 <G02_MCC_network/group_mpi_interface>` 和测试目录 ``PERFORMANCE.md``。

   .. _g02-generality-zh:

   .. rubric:: 4. 配置范围与物理边界
      :class: g02-chapter

   物种、质量、电荷、内部态和已支持的反应网络可以由 CSV 配置。每条反应须有一个 kinetic projectile，以及一到两个 background 反应物。二体可以用截面或温度速率系数，三体使用温度速率系数。背景速度按带漂移的 Maxwell 分布抽样；温度系数数据所假设的速度分布也应适合应用。

   当前末态为经典非相对论运动学。角度模型支持 isotropic、cone 和有严格约束的 identity_exchange；能量模型支持 n_body_phase_space 和恰好两个产物的 equal_share。新散射律或未实现的物理机制需要扩展代码，不能只在 CSV 中填一个新名字。

   G02 只处理局部粒子—背景碰撞，不求场、不推进位置、不处理壁面、不划分网格或迁移粒子。守恒校验不代替真实截面数据和模型验证；元素检查只覆盖已声明的组成。初学者的运行与统计判据见 :ref:`零维碰撞盒教程 <g02-collision-box-zh>`。

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>贡献者</strong></p>
        <p class="ap-home-contact">刘哲、谢礼桓</p>
      </div>

.. container:: ap-lang ap-lang-en

   The null-collision basis is Skullerud (1968), with PIC-MCC context from Vahedi–Surendra (1995).
   See :ref:`method references <g02-method-references-en>` for the clock, thermal partners and implementation mapping.

   .. _g02-mcc-basics-en:

   .. rubric:: 1. MCC samples collision probabilities
      :class: g02-chapter

   Monte Carlo Collision sampling answers three questions: **when an event occurs, which reaction occurs and how the particle changes**. Individual histories fluctuate; many-particle statistics should follow the supplied model.

   A projectile is the tracked incoming particle; primary describes its original record after an event. Background partners are represented by density, temperature and mean velocity, with velocities sampled when needed. A channel defines reactants, products and a rate; channels form a network.

   Cross sections σ have units m². At a given relative speed g, a two-body rate is nσg. Temperature rate coefficients use m³/s for two-body reactions (nk) and m⁶/s for three-body reactions (n₁n₂k, or n²k for two copies of the same background).

   .. math::

      P(\text{at least one real collision}) = 1-\exp(-\nu\Delta t)

   This formula applies at constant real frequency ν. With νΔt=0.1 the probability is about 9.52%; multiple collisions can occur in one step. Elastic collisions conserve the total momentum and kinetic energy of both partners while either particle may speed up or slow down. Temperature measures thermal motion after subtracting mean drift.

   .. _g02-implementation-en:

   .. rubric:: 2. G02 framework
      :class: g02-chapter

   G02 is an independent C++20 implementation and **does not call G01**. The host provides particles, backgrounds and dt; G02 returns particle changes, reaction counts and background exchange. Begin with the batch ``MccStepper::step()`` API.

   .. _g02-csv-input-en:

   .. rubric:: 2.1 Initialization: load a model

   ``MccEngine::load(model_dir)`` reads a user-created ``manifest.csv`` and resolves relative paths to species, states, reactions, rate laws and numerical tables. Text/reference checks precede ``compile_model``, which checks reaction order, units, energy, charge and declared element inventories, then prepares channels and frequency bounds. Model compilation means organizing runtime data.

   Load once during initialization. The repository ships no cross-section data files or blank tables. See :doc:`CSV model format and preparation <G02_MCC_network/csv_format>` for headers, units and a complete inline example. Runtime test fixtures provide software validation only.

   .. _g02-architecture-en:

   .. rubric:: 2.2 Program flow and module roles

   .. figure:: ../../images/G_Collision/G02/architecture_en.svg
      :alt: Standard MCC program flowchart: initialization, batch collisions, success checks, commit and time-step loop
      :width: 100%
      :figclass: g02-flowchart

      Gray labels identify functions and files. C++ source files are under ``G_Collision/G02_MCC_network/``. Functions marked "internal" are used within the library.

   - ``model/compile/table/csv`` read/check reaction data and prepare lookup and bounds.
   - ``batch`` adapts host storage, reuses workspaces, assigns child IDs and commits together.
   - ``engine`` chooses matching species/state channels and samples candidate times and acceptance.
   - ``kinematics`` generates final states obeying reaction, momentum and energy rules.
   - Optional ``mpi`` coordinates preparation, errors and global child IDs. Partitioning and migration remain host responsibilities.

   .. rubric:: 2.3 Every time step

   .. figure:: ../../images/G_Collision/G02/step_flow_en.svg
      :alt: Standard MCC step flowchart: particle loop, candidate waits, real and null branches, remaining-time loop and commit
      :width: 100%
      :figclass: g02-flowchart

      Any preparation failure uses the error exit, including majorant, candidate-limit, conservation, product-ID and storage-capacity checks; particle updates are not committed.

   1. Read backgrounds and particle snapshots; find channels matching species/state. No channels or zero total bound means no candidates.
   2. Draw a wait τ=−ln(1−u)/Λ from total frequency bound Λ. A wait beyond the remaining dt ends this primary.
   3. For a candidate inside this step, consume its waiting time first, then select by channel-bound fractions and accept with actual rate divided by that channel's bound. A real event invokes C02–C08; a null event preserves state.
   4. Rebuild channels for changed species/state and continue the remainder. Removal ends the primary; children participate from the next step.
   5. After all particles succeed, aggregate, assign IDs, prepare storage and commit together. Preparation/capacity failure leaves visible particles unchanged.

   An actual frequency exceeding its bound raises an error. Loose bounds increase null events. Null events also consume time. A candidate outside this step is not executed; the next step resamples.

   .. figure:: ../../images/G_Collision/G02/event_timeline_en.svg
      :alt: Real/null events and a wait beyond the remaining time
      :width: 100%

      Times illustrate the flow; they are not simulation output.

   G02 C01 names the common event-sampling flow. CSV reaction algorithms use C02–C08: elastic, discrete-state transition, dissociation, ionization, attachment/detachment, charge exchange and recombination/neutralization. These local algorithm IDs are separate from module IDs in C_Gather.

   .. rubric:: 2.4 Recommended C++ batch caller

   This complete buildable program takes a model directory as argv[1] and requires A/B species. Documented-caller tests generate a synthetic package at runtime; manual commands are in examples/doc_snippets/README.md.

   .. literalinclude:: ../../../../tests/009_collision/G02_MCC_network/examples/doc_snippets/batch.cpp
      :language: cpp

   Create the adapter/workspace outside the time loop. The overload without workspace uses temporary scratch storage. Call one overload once per physical step. The host applies report.reservoir to subsequent backgrounds; G02 does not evolve backgrounds automatically.

   .. rubric:: 2.5 Single-particle and batch entries

   .. list-table:: Entry behavior
      :header-rows: 1
      :widths: 24 76

      * - Entry
        - Advancement and write-back
      * - ``MccStepper::step()``
        - Completes each primary's remaining dt and commits updates, removals, species changes and children together. Default per-particle candidate limit is 1000000; exceeding it throws, and preparation failure does not commit.
      * - ``MccEngine::collide_full()``
        - Completes one primary, continuing after species changes and ending on removal. Default candidate limit is 1000000; exceeding it throws Error. Returns StepOutcome; the host writes back and stores children.
      * - ``MccEngine::collide()``
        - Bounded advancement. request.max_events_per_step=0 selects the model default of 64 candidates, including nulls. Reaching it returns event_limit_reached. MoveSpecies/Remove also ends processing, so return does not establish dt completion.

   All entries belong to G02. Their difference concerns advancement, not G01/G02 migration. Single-particle describes the number of inputs; collide() can process multiple collisions.

   .. _g02-data-types-en:

   .. rubric:: 2.6 Objects and units

   - ``ParticleState``: species/state IDs, stable unique particle ID, mesh cell, velocity in m/s, weight and birth step. Retain adapters/ID high-water marks to avoid reusing removed IDs.
   - ``CellBackground``: cell plus background component; density m⁻³, temperature K and mean velocity m/s. cell=UINT32_MAX selects uniform fallback; local cells must match particles.
   - Background ``invalid_state=65535`` means species-aggregate density. It is not ground state and does not distribute density among states. Start with explicit valid state IDs.
   - ``StepOutcome``: primary_action/primary_after, created children, background reservoir and candidate counts. The host commits Update/MoveSpecies/Remove; event_limit_reached marks the bounded entry reaching its candidate cap.
   - ``StepReport``: candidate/real/null counts, reaction counts, background number/momentum/energy exchange, ledger and timings. Failures throw ``algoplasma::mcc::Error``.

   .. rubric:: 2.7 Build and check

   From the repository root in Linux/WSL, with CMake 3.20 and a C++20 compiler:

   .. code-block:: bash

      cmake -S tests/009_collision/G02_MCC_network -B /tmp/g02_build -DCMAKE_BUILD_TYPE=Debug
      cmake --build /tmp/g02_build -j 4
      ctest --test-dir /tmp/g02_build --output-on-failure

   CTest generates synthetic models under the build directory's generated_models. Use G02_MCC_BUILD_TESTS=OFF for the library only. External CMake uses find_package(G02_MCC_network CONFIG REQUIRED) and AlgoPlasma::G02_MCC. Run g02_validate_model /path/to/my_model for user data.

   .. _g02-acceleration-en:

   .. rubric:: 3. Workspace and CPU parallelism
      :class: g02-chapter

   Retain ``MccWorkspace`` to reuse scratch memory and cache channels for matching models, backgrounds, cells, species and states. Relevant changes invalidate the cache. A workspace/adapter must not serve concurrent calls.

   OpenMP requires G02_MCC_ENABLE_OPENMP and CpuBackend::OpenMp. MPI requires G02_MCC_ENABLE_MPI, mpi.hpp and AlgoPlasma::G02_MCC_MPI. Every participating rank calls the distributed stepper. Require MPI_THREAD_FUNNELED and destroy the stepper before MPI_Finalize.

   Prefix channel sampling is the default; alias sampling is available for many channels. Compare Release complete-step timings for fixed models/workloads while checking statistics, conservation and serial/parallel agreement. See :doc:`MPI API <G02_MCC_network/group_mpi_interface>` and PERFORMANCE.md in the tests directory.

   .. _g02-generality-en:

   .. rubric:: 4. Configuration and physical boundaries
      :class: g02-chapter

   CSV configures species, masses, charges, states and supported reactions. Each channel has one kinetic projectile plus one or two background reactants. Two-body channels use cross sections or temperature rate coefficients; three-body channels use temperature coefficients. Background velocities follow drifting Maxwell distributions. The distribution assumptions behind rate data must match the application.

   Current kinematics is classical and nonrelativistic. Angular models are isotropic, cone and strictly constrained identity_exchange. Energy models are n_body_phase_space and equal_share with exactly two products. A new scattering law or physical mechanism requires code and validation, not merely a new CSV name.

   G02 performs local particle/background collisions. It does not solve fields, advance positions, handle walls, partition domains or migrate particles. Conservation checks do not replace valid data and model validation; element checks cover declared compositions only. See the :ref:`collision-box tutorial <g02-collision-box-en>` for execution and statistical pass criteria.

   .. raw:: html

      <div class="ap-home-footer-band">
        <p><strong>Contributors</strong></p>
        <p class="ap-home-contact">Zhe LIU, Lihuan XIE</p>
      </div>
