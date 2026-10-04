.. _mccstepper-step-prepare-step:

.. rst-class:: ap-g02 ap-g02-reference

MccStepper：批量碰撞步进器
============================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - AoS / SoA 是存储排法：AoS（Array of Structures）按粒子存放 {x,v,…}；SoA（Structure of Arrays）分别存放 x[]、v[] 等字段数组。物理模型相同，适配器负责用统一接口访问这些数据。
      - ParticleAdapter（粒子适配器）：把主程序已有的粒子存储接到 G02 的“转换接头”，负责读取粒子和提交更新，不是额外的物理粒子。
      - workspace（工作区）是反复使用的临时内存。跨时间步复用可减少分配，但同一对象不能同时处理两个调用。

   .. tip:: cell 与 state 的特殊值

      ``cell`` 是网格编号，不是数组下标。背景的 ``UINT32_MAX``表示全域备用背景；正常网格编号必须与粒子一致。
      ``invalid_state`` 是 C++ 的 65535 哨兵值，它只供按物种合并的背景使用，不等于基态，也不代表自动分配各态密度。
      入门时用 ``state_id(species, "ground")`` 查询真实态；名称须存在于模型。被跟踪粒子的态必须有效。

   .. tip:: 可直接构建的最小调用程序

      以下程序已给出必要声明和变量来源。运行参数为 ``BUILD_DIR/generated_models/collision_box_elastic``，不要换成不含 A/B 的模型。

   .. literalinclude:: ../../../../../tests/009_collision/G02_MCC_network/examples/doc_snippets/batch.cpp
      :language: cpp

   实现文件：``fun_G02_mcc_batch.cpp``。下面保留对应 C++ 接口的实际名称，方便对照调用。

   .. rubric:: 直接用途

   C++ 的批量入口位于 ``batch.hpp``，命名空间为 ``algoplasma::mcc``。
   它通过 ParticleAdapter 访问主程序粒子容器，成功后统一写回。
   调用图见 :ref:`架构说明 <g02-architecture-zh>`。

   .. literalinclude:: ../../../../../G_Collision/G02_MCC_network/batch.hpp
      :language: cpp
      :start-at: [[nodiscard]] StepReport step(ParticleAdapter& particles,
      :end-at: std::uint64_t seed, MccWorkspace& workspace) const;

   上面是 ``MccStepper`` 类中的真实声明。五参数版本使用临时工作区；六参数版本复用调用者的工作区。
   同一物理时间步只选一个版本调用；第六个参数不是线程数，也不是 StepOptions。
   省略最后的 workspace 参数也可以，接口会使用一次性的工作区。

   .. list-table:: step 参数
      :header-rows: 1
      :widths: 25 15 60

      * - 参数
        - 方向
        - 约定
      * - particles
        - inout
        - ParticleAdapter 引用；成功后更新其管理的容器。
      * - background
        - in
        - const vector<CellBackground>&；本次调用期间保持有效。
      * - dt_s / global_step / seed
        - in
        - 秒、全局步编号、随机种子；dt 为有限非负数。
      * - workspace
        - inout，可选重载
        - 临时内存跨步复用；同一对象不能同时用于两个活动调用。
      * - 返回 StepReport
        - out
        - 统计、背景收支、账本和分段耗时；异常时不返回成功报告。

   .. rubric:: StepOptions

   默认 backend=Auto，线程数 threads=0，min_parallel_particles=4096，
   max_candidates_per_particle=1000000，record_events=false，exact_pruning=true，
   sampler=Prefix。OpenMP 需要构建时启用；设置 record_events 才会保留逐事件明细。
   exact_pruning 根据当前背景条件收紧可用通道的上界，减少额外候选。

   .. rubric:: 自定义粒子容器的接入

   使用 vector<ParticleState> 时直接用 VectorParticleAdapter。
   按物种分别存放各个字段的 ParticleBank/ParticleSoA 使用 SoaParticleAdapter。
   自定义容器实现以下约定：

   - size、alive、particle 提供只读访问；next_id_hint 返回新 ID 的起点提示。
   - begin_step 刷新索引，不改变当前可见粒子。
   - prepare_commit 可分配内存并失败，但不能提前改动可见粒子。
   - commit 必须不失败，将已准备好的更新一次性写回。

   适配器或 ID 高水位需要跨步保留，防止删除粒子后重新使用旧 ID。
   主程序直接改动容器后，下次 begin_step 会重建必要索引。

   .. rubric:: prepare_step 的进阶用途

   prepare_step 与带 workspace 的 step 接收相同输入，返回 PreparedMccStep。
   它还未提交粒子。report 读暂存统计，largest_id 和 birth_keys 用于分配子粒子 ID，
   prepare_commit 准备存储，commit 写回，take_report 取走报告。
   对象不可复制、可以移动；销毁会释放它对工作区的占用。
   普通主程序直接调用 step 即可，MPI 包装使用分阶段接口协调多进程提交。

   .. rubric:: 完整 C++ 调用程序

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - AoS (Array of Structures) stores one record per particle; SoA (Structure of Arrays) stores separate arrays for fields such as x[] and v[]. Adapters expose either layout through one interface; the physical model is unchanged.
      - ParticleAdapter connects host-owned storage to G02, exposing particle reads and update commits. It is an interface, not another physical particle.
      - A workspace is reusable scratch memory. Reuse reduces allocation, but one instance must not serve concurrent calls.
      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.
      - Reservoir deltas track background gains/losses of particles, momentum and energy. A conservation ledger compares totals before and after reactions. Do not apply both as background source terms.

   .. tip:: Special cell and state values

      cell is a mesh ID, not an array index. Background ``UINT32_MAX`` selects uniform fallback; local IDs must match particles.
      C++ ``invalid_state`` is the 65535 sentinel, only for species-aggregate backgrounds. It is not ground state and does not distribute density over states.
      Beginners can look up a real state with ``state_id(species, "ground")``; the label must exist in the model. Tracked particles must have valid states.

   .. tip:: Complete buildable caller

      Declarations and input initialization are included. Pass ``BUILD_DIR/generated_models/collision_box_elastic``; the caller requires its A/B species.

   .. literalinclude:: ../../../../../tests/009_collision/G02_MCC_network/examples/doc_snippets/batch.cpp
      :language: cpp

   Implementation: ``fun_G02_mcc_batch.cpp``. The C++ interface names below match the callable API.

   .. rubric:: Direct purpose

   The C++ batch entry in batch.hpp uses a ParticleAdapter to access host-owned particles and commit together.
   See :ref:`Architecture <g02-architecture-en>`.

   .. literalinclude:: ../../../../../G_Collision/G02_MCC_network/batch.hpp
      :language: cpp
      :start-at: [[nodiscard]] StepReport step(ParticleAdapter& particles,
      :end-at: std::uint64_t seed, MccWorkspace& workspace) const;

   These are the declarations inside MccStepper. Five arguments use temporary storage; six reuse caller storage.
   Choose one overload per physical step; the sixth argument is neither a thread count nor StepOptions.
   The overload without workspace uses temporary storage.

   .. list-table:: step parameters
      :header-rows: 1
      :widths: 25 15 60

      * - Argument
        - Direction
        - Contract
      * - particles
        - inout
        - ParticleAdapter reference; commits its container on success.
      * - background
        - in
        - const vector<CellBackground>&, valid throughout the call.
      * - dt_s / global_step / seed
        - in
        - Finite nonnegative seconds, global step and random seed.
      * - workspace
        - optional overload, inout
        - Reusable scratch storage, not shared by active calls.
      * - StepReport return
        - out
        - Counts, exchange, ledger and timing; failure throws.

   .. rubric:: Options and storage

   StepOptions defaults: Auto backend, threads=0, min_parallel_particles=4096,
   max_candidates_per_particle=1000000, record_events=false, exact_pruning=true, Prefix sampler.
   OpenMP requires build support. record_events enables event details.
   exact_pruning tightens channel bounds using current background conditions.

   VectorParticleAdapter handles vector storage.
   SoaParticleAdapter handles ParticleBank/ParticleSoA.
   Custom adapters implement size/alive/particle/next_id_hint, refresh indices without changing particles
   in begin_step, prepare storage without visible mutation in prepare_commit, and provide non-failing commit.
   Preserve the adapter or ID high-water mark across steps to avoid reusing deleted IDs.

   .. rubric:: Staged preparation

   prepare_step takes the workspace overload's inputs and returns a movable, noncopyable PreparedMccStep.
   report inspects staged diagnostics; largest_id/birth_keys support child-ID assignment;
   prepare_commit stages storage, commit writes it, and take_report transfers the report.
   Destruction releases workspace occupancy.
   Most hosts use step directly; MPI uses the stages to coordinate commit.

   .. rubric:: Complete C++ caller

.. literalinclude:: ../../../../../tests/009_collision/G02_MCC_network/examples/host_pic/main.cpp
   :language: cpp
   :linenos:

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fun_G02_mcc_batch.cpp``

:doc:`Collision <group_collision>`
