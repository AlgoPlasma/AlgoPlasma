.. _mccengine-load-collide-collide-full:

.. rst-class:: ap-g02 ap-g02-reference

MccEngine：碰撞抽样与事件处理
==============================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - majorant（频率上界）：一个不小于真实碰撞频率的数，用它安排候选事件，再按“真实频率÷上界”接受候选。上界过松会增加空碰撞；低于真实频率则报错。
      - projectile / primary：projectile 是当前跟踪的入射粒子；primary 是一次事件后对这条原粒子记录的处理结果，可更新、移除或改变物种。background 是用密度、温度等描述的碰撞伙伴。

   实现文件：``fun_G02_mcc_engine.cpp``。下面保留对应 C++ 接口的实际名称，方便对照调用。

   .. rubric:: 直接用途

   MccEngine 保存已校验的反应网络，处理一个被跟踪粒子与背景的碰撞。
   它不拥有主程序的粒子数组。所有接口位于 engine.hpp。

   .. code-block:: cpp

      static MccEngine load(const std::filesystem::path& package_dir,
                            CompileOptions options = {});
      StepOutcome collide(const CollisionRequest& request) const;
      StepOutcome collide_full(const CollisionRequest& request,
                               std::uint32_t max_candidates = 1000000,
                               bool record_events = false) const;
      std::vector<ChannelDiagnostics> evaluate_channels(const CollisionRequest& request) const;

   .. rubric:: 输入与输出

   load 的目录指向模型包；options 控制校验容差与上界余量，见 :doc:`fun_G02_mcc_model`。
   构造出的引擎共享只读 CompiledModel。也可先 compile_model，再交给构造函数。

   CollisionRequest 的 projectile 是输入粒子，background 是背景数组，
   dt_s 为秒，global_step/seed 控制随机序列。
   普通调用使用拥有数据的 background；background_view、cached_channels 等借用指针
   供同步批量路径使用，初次接入保持默认即可。返回 StepOutcome，字段见 :ref:`数据对象与单位 <g02-data-types-zh>`。

   .. list-table:: 三个计算入口
      :header-rows: 1
      :widths: 23 42 35

      * - 入口
        - 行为
        - 限制/返回
      * - collide
        - 受限单粒子推进；更新后可继续，物种改变或移除时停止。
        - request.max_events_per_step=0 选模型默认 64 个候选（包含空碰撞）；达到上限设置 event_limit_reached。
      * - collide_full
        - 物种改变后继续剩余 dt；移除则结束。
        - 超过 max_candidates 抛 Error，不返回截断成功；可选事件记录。
      * - evaluate_channels
        - 查询当前状态可用通道的频率上界和诊断。
        - 不推进粒子；温度速率系数通道给出实际速率，截面通道需看 rate_defined。

   collide 的物种迁移停止不一定设置 event_limit_reached；返回结果不能当作完整 dt 已处理。推荐整步调用 collide_full 或批量 step。

   StepOutcome 不会自行写回粒子。需要整个容器更新时，调用 :doc:`fun_G02_mcc_batch`。
   输入无效、背景缺失、越出数据范围、上界失效或守恒失败都会抛 algoplasma::mcc::Error。

   .. rubric:: 查询与查找

   species_id(name)、state_id(species,label)、species_name(id) 在名称和 ID 之间转换；
   model() 返回 const CompiledModel&，用于遍历物种、态、反应。查找失败抛 Error。
   内部活动通道以 species 和 state 同时作为键，内部态改变后会重新选择可用通道。

   随机时钟与通道抽样见 :ref:`碰撞抽样 <g02-sampling-zh>`，碰撞后速度计算见 :doc:`fun_G02_mcc_kinematics`。

   .. _g02-sampling-zh:

   .. rubric:: 碰撞事件与随机数抽样
      :class: g02-chapter

   空碰撞、指数等待与热背景接受步骤的文献和公式见
   :ref:`方法出处与实现对应 <g02-method-references-zh>`；该流程允许一步内多个候选。

   .. rubric:: G02 算法 C01 的位置

   G02 算法 C01 是碰撞事件的抽样流程，实现在 MccEngine 中；
   源码中没有一个需要主程序额外调用的 sub_C01 子程序。
   它解决“何时尝试碰撞、选择哪条通道、候选是否接受”。
   G02 算法 C02–C08 随后决定被接受的反应怎样产生末态。

   .. figure:: ../../../images/G_Collision/G02/event_timeline_zh.svg
      :alt: 一个时间步内的真实碰撞、空碰撞和超过时间边界的候选
      :width: 100%

      候选时刻是流程示意，未使用模拟输出。
      点击图片可查看原图。

   .. rubric:: 输入、输出与过程

   输入是当前粒子的 species/state、背景数密度和温度、剩余 dt，以及随机数键。
   输出是下一候选、是否真实发生以及更新后的剩余时间。

   1. 找到当前物种和态完全匹配的通道。
   2. 各通道频率上界相加为 Λ；按 −ln(1−u)/Λ 抽取等待时间。
   3. 等待超过剩余 dt 就结束，否则按各通道上界占比选一条。
   4. 用真实速率与该通道上界的比值决定接受与否，拒绝即空碰撞。
   5. 接受后更新物种/态，再处理剩余时间；无可用通道时直接结束。

   实际速率超过上界会报错。Lambda 为零时不计算倒数。
   单次全局步内可发生多次事件，空碰撞也要扣除等待时间。

   .. rubric:: CounterRng 接口

   .. code-block:: cpp

      CounterRng rng(seed, global_step, particle_id, event_index, slot);
      auto u = rng.uniform_open();
      auto direction = rng.isotropic_direction();

   五个构造参数均为 uint64_t，用来给随机序列定位。
   next_u64 返回整数随机数，normal 返回标准正态样本，
   random_vector 返回三个独立标准正态分量，isotropic_direction 返回球面随机单位向量。
   这些方法会推进对象内部计数。该类用于模拟抽样，不用于加密。

   child_id 与 stream_slot 是确定性的键辅助函数。
   批量生产路径的新 ID 由批量层或 MPI 层分配，不应由宿主任意替换为 child_id 的散列结果。
   同一种子、步编号和稳定粒子 ID 让抽样不依赖 OpenMP 调度；完整复现还应保持构建和模型一致。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - A null collision is a rejected candidate: sampled waiting time is consumed but the particle state stays unchanged. It is a sampling device, not a physical reaction.
      - The projectile is the tracked incoming particle. The primary outcome tells what happens to that original particle record: update, removal or species change. Background partners are described by density and temperature.

   Implementation: ``fun_G02_mcc_engine.cpp``. The C++ interface names below match the callable API.

   .. rubric:: Direct purpose

   MccEngine holds a validated network and samples one tracked particle against a background.
   It does not own the host particle array. Interfaces are in engine.hpp.

   .. code-block:: cpp

      static MccEngine load(const std::filesystem::path& package_dir,
                            CompileOptions options = {});
      StepOutcome collide(const CollisionRequest& request) const;
      StepOutcome collide_full(const CollisionRequest& request,
                               std::uint32_t max_candidates = 1000000,
                               bool record_events = false) const;
      std::vector<ChannelDiagnostics> evaluate_channels(const CollisionRequest& request) const;

   load takes a package directory and :doc:`CompileOptions <fun_G02_mcc_model>`.
   The engine shares a read-only CompiledModel; it can also be constructed from one directly.
   CollisionRequest supplies projectile, background, dt_s in seconds, global_step and seed.
   Leave borrowed background_view/cached_channels fields at defaults for ordinary calls.
   See :ref:`Data objects and units <g02-data-types-en>` for StepOutcome.

   .. list-table:: Calculation entries
      :header-rows: 1
      :widths: 23 42 35

      * - Entry
        - Behavior
        - Limit/result
      * - collide
        - Bounded advancement; stops on MoveSpecies or Remove.
        - request.max_events_per_step=0 selects model default 64 candidates, including nulls; reaching it sets event_limit_reached.
      * - collide_full
        - Continues remaining dt after species moves; removal stops.
        - Throws on candidate cap; optional event recording.
      * - evaluate_channels
        - Queries active channel bounds and diagnostics without a collision step.
        - Exact rates for temperature coefficients; inspect rate_defined for cross sections.

   A species move can end collide without event_limit_reached. Do not treat its return as proof of full-dt completion; use collide_full or batch step for complete advancement.

   The host commits StepOutcome. Use :doc:`fun_G02_mcc_batch` for whole-container updates.
   Invalid inputs, missing backgrounds, domain/bound violations or conservation failures throw Error.

   species_id, state_id and species_name perform lookups; model returns const CompiledModel&.
   Unknown names/IDs throw Error. Active channels match both species and state and are rebuilt after state changes.
   See :ref:`Collision sampling <g02-sampling-en>` and :doc:`fun_G02_mcc_kinematics`.

   .. _g02-sampling-en:

   .. rubric:: Collision events and random sampling
      :class: g02-chapter

   See :ref:`methods and implementation mapping <g02-method-references-en>` for
   null collisions, exponential waits and thermal-partner acceptance. The loop allows multiple candidates per step.

   .. rubric:: Where G02 algorithm C01 lives

   G02 algorithm C01 is the event-sampling workflow inside MccEngine, not a separate sub_C01 routine for the host to call.
   It chooses candidate times, channels and acceptance; G02 algorithm C02–C08 determine accepted-event outcomes.

   .. figure:: ../../../images/G_Collision/G02/event_timeline_en.svg
      :alt: Real and null candidates within a step, followed by a wait beyond dt
      :width: 100%

      Schematic times, not simulation output.
      Select the image to open it at full size.

   Inputs are particle species/state, background density/temperature, remaining dt and random keys.
   Match active channels, sum their bounds into Lambda, sample -ln(1-u)/Lambda,
   stop beyond dt, otherwise select a channel by its bound and accept by real rate/channel bound.
   After accepted state changes, rebuild active channels and continue.
   Zero total rate requires no inverse; rate-bound violations fail.
   Null events consume waiting time too.

   .. rubric:: CounterRng

   .. code-block:: cpp

      CounterRng rng(seed, global_step, particle_id, event_index, slot);
      auto u = rng.uniform_open();
      auto direction = rng.isotropic_direction();

   All five keys are uint64_t.
   next_u64 returns an integer draw; normal returns a standard normal sample;
   random_vector returns three normal components; isotropic_direction returns a random unit vector.
   Draws advance the local counter. This is simulation sampling, not cryptography.

   child_id and stream_slot are deterministic key helpers.
   Production batch/MPI layers assign child IDs; hosts should not substitute arbitrary child_id hashes.
   Stable particle IDs, seeds and steps make sampling independent of OpenMP scheduling.
   Full replay also assumes the same build and model.

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fun_G02_mcc_engine.cpp``

:doc:`Collision <group_collision>`
