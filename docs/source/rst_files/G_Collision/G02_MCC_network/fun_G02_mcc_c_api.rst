.. _c-api-ap-g02-mcc:

.. rst-class:: ap-g02 ap-g02-reference

C 接口：连接 C、C++ 与 Fortran
======================================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - projectile / primary：projectile 是当前跟踪的入射粒子；primary 是一次事件后对这条原粒子记录的处理结果，可更新、移除或改变物种。background 是用密度、温度等描述的碰撞伙伴。
      - workspace（工作区）是反复使用的临时内存；session（会话）是 C/Fortran 接口持有这类工作状态的对象。跨时间步复用可减少分配，但同一对象不能同时处理两个调用。
      - ABI（应用二进制接口）规定不同语言编译后怎样传参和返回结果。handle（句柄）是库对象的引用；保存并通过接口使用它，不直接读取其内部数据。
      - reservoir（背景库）记录背景得到或失去的粒子、动量和能量；ledger（守恒账本）记录反应前后总量以核查守恒。两者用途不同，不能重复当作源项加入背景。

   .. tip:: 可直接构建的最小调用程序

      以下程序已给出必要声明和变量来源。运行参数为 ``tests/009_collision/G02_MCC_network/data/collision_box_elastic``，不要换成不含 A/B 的模型。

   .. literalinclude:: ../../../../../tests/009_collision/G02_MCC_network/examples/doc_snippets/minimal.c
      :language: c

   实现文件：``fun_G02_mcc_c_api.cpp``。下面保留对应 C++ / C 接口的实际名称，方便对照调用。

   .. rubric:: 直接用途

   c_api.h 提供稳定 C 函数边界，既可供 C 主程序使用，也是 Fortran 包装的底层。
   所有对象由不透明句柄表示：调用者保存指针，通过对应函数操作，不读取内部结构。

   .. list-table:: 入口分组
      :header-rows: 1
      :widths: 42 58

      * - 名称（省略公共前缀 ``ap_g02_mcc_`` ）
        - 行为与生命周期
      * - api_version
        - 返回 int，当前为 1。
      * - model_load / model_destroy
        - 读取并编译模型 / 释放模型。
      * - engine_create / engine_destroy
        - 从模型建立引擎 / 释放引擎。
      * - model_species_id / model_state_id
        - 输入名称或物种+态名，输出 uint16_t ID。
      * - model_species_count/get、model_state_count/get、model_reaction_count/get
        - 先取条目数，再按零起点 index 枚举；序号与模型 ID 分开。
      * - collide / outcome_destroy
        - 输入 request，生成需主程序提交的单粒子 outcome / 释放。
      * - outcome_primary / outcome_counters / outcome_ledger_get
        - 读取主粒子动作与目标、候选计数及截断标志、守恒账本。
      * - outcome_created_count/get、outcome_reservoir_count/get、outcome_event_count/get
        - 枚举产物、背景交换量、逐事件记录；get 的 index 从零开始。
      * - step
        - 原地更新一整个粒子数组，返回报告。
      * - session_create/step/resume/abort/destroy
        - 创建工作区 / 抽样本步 / 容量扩展后续接 / 放弃待提交结果 / 释放。
      * - step_report_stats / step_report_ledger
        - 复制统计和账本到调用者结构体。
      * - step_report_reservoir_count/get、step_report_reaction_count/get
        - 枚举背景增量与反应计数。
      * - step_report_destroy
        - 释放批量报告。

   .. rubric:: step：容量和参数

   engine 输入有效引擎句柄；particles 指向容量为 capacity 的数组。
   inout_count 是调用前有效粒子数，成功后变成结果粒子数；
   required 输出容纳结果所需容量。background 为按网格/态的背景数组，
   background_count 给出长度。dt_s 单位秒，global_step/seed 为 uint64_t。
   max_candidates=0 使用默认上限，threads=0 让运行时选择，
   backend 为 0 自动、1 串行、2 OpenMP。成功时 out_report 由调用者释放。
   error_buffer 与 error_buffer_size 是调用者分配的错误消息区。

   容量不足返回 BUFFER_TOO_SMALL，原 particles 与 count 保持不变。
   扩容时保留输入数据，用同一步号、种子重试 step。
   使用会话时改用 session_resume，保留已经准备的结果；
   resume 前输入粒子及 count 必须与抽样时相同。
   需要放弃时调用 session_abort。session_create 还接受 sampler：0 PREFIX、1 ALIAS。

   .. rubric:: 状态码与错误消息

   .. list-table::
      :header-rows: 1
      :widths: 10 35 55

      * - 值
        - 名称（省略 ``AP_G02_MCC_`` ）
        - 含义
      * - 0
        - OK
        - 成功。
      * - 1
        - INVALID_ARGUMENT
        - 指针、索引、数量或参数无效。
      * - 2
        - NOT_FOUND
        - 查不到指定名称或 ID。
      * - 3
        - PARSE_ERROR
        - 解析错误码。
      * - 4
        - COMPILE_ERROR
        - 模型加载/编译失败；当前 model_load 也把解析失败映射到此类。
      * - 5
        - PHYSICS_ERROR
        - 碰撞计算或物理约束失败。
      * - 6
        - RUNTIME_ERROR
        - 运行期失败。
      * - 7
        - BUFFER_TOO_SMALL
        - 粒子容量或名称输出缓冲不足。
      * - 8
        - INTERNAL_ERROR
        - 内部异常等失败。

   有 error_buffer 参数的函数写有界 UTF-8 消息；count/get 等部分查询只返回状态码。
   不要假设每个函数都带消息缓冲。api_version 是返回版本的例外；
   destroy 返回状态，允许 NULL，C++ 异常不会跨出 C 边界。
   v1 不承诺 C ABI 线程安全。资源使用顺序为 model → engine → session/outcome/report，
   清理时先释放结果与会话，再释放引擎与模型。

   :ref:`数据对象与单位 <g02-data-types-zh>` 解释字段和单位，:doc:`mod_G02_MCC_network_mpi` 说明单独的 MPI C 接口。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - The projectile is the tracked incoming particle. The primary outcome tells what happens to that original particle record: update, removal or species change. Background partners are described by density and temperature.
      - A workspace is reusable scratch memory. A session holds this state for C/Fortran callers. Reuse reduces allocation, but one instance must not serve concurrent calls.
      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.
      - Reservoir deltas track background gains/losses of particles, momentum and energy. A conservation ledger compares totals before and after reactions. Do not apply both as background source terms.

   .. tip:: Complete buildable caller

      Declarations and input initialization are included. Pass ``tests/009_collision/G02_MCC_network/data/collision_box_elastic``; the caller requires its A/B species.

   .. literalinclude:: ../../../../../tests/009_collision/G02_MCC_network/examples/doc_snippets/minimal.c
      :language: c

   Implementation: ``fun_G02_mcc_c_api.cpp``. The C++ / C interface names below match the callable API.

   .. rubric:: Direct purpose

   c_api.h is the C function boundary and the basis of the Fortran wrapper.
   Opaque handles are owned by the caller and accessed only through API functions.

   .. list-table:: Entries (common ``ap_g02_mcc_`` prefix omitted)
      :header-rows: 1
      :widths: 42 58

      * - Functions
        - Purpose
      * - api_version
        - Returns int ABI version, currently 1.
      * - model_load/destroy, engine_create/destroy
        - Load/compile model, create engine, release resources.
      * - model_species_id, model_state_id
        - Resolve names to uint16_t IDs.
      * - model_species_count/get, model_state_count/get, model_reaction_count/get
        - Enumerate zero-based positions, distinct from model IDs.
      * - collide, outcome_destroy
        - Produce/release a single-particle outcome for host commit.
      * - outcome_primary/counters/ledger_get
        - Read particle action/destination, counts/limit flag and ledger.
      * - outcome_created_count/get, outcome_reservoir_count/get, outcome_event_count/get
        - Enumerate products, exchange and events using zero-based indices.
      * - step
        - Update a full particle array and return a report.
      * - session_create/step/resume/abort/destroy
        - Create workspace, sample, resume capacity retry, discard pending work, release.
      * - step_report_stats/ledger
        - Copy statistics and ledger.
      * - step_report_reservoir_count/get, step_report_reaction_count/get
        - Enumerate background increments and reaction counts.
      * - step_report_destroy
        - Release a batch report.

   .. rubric:: Batch arguments and capacity

   engine is a valid handle; particles points to capacity entries.
   inout_count is the live input count and becomes the result count on success.
   required gives necessary output capacity. background/background_count provide cell/state fields.
   dt_s is seconds; global_step/seed are uint64_t.
   max_candidates=0 selects the default; threads=0 lets the runtime choose;
   backend is 0 auto, 1 serial, 2 OpenMP.
   The caller destroys out_report and supplies error_buffer/error_buffer_size.

   BUFFER_TOO_SMALL preserves particles and count.
   Grow storage while preserving inputs, then retry with the same step/seed.
   A session uses session_resume to retain prepared outcomes; input particles/count must still match.
   session_abort discards pending work. session_create also accepts sampler 0 PREFIX or 1 ALIAS.

   .. rubric:: Status codes

   0 OK; 1 INVALID_ARGUMENT; 2 NOT_FOUND; 3 PARSE_ERROR; 4 COMPILE_ERROR;
   5 PHYSICS_ERROR; 6 RUNTIME_ERROR; 7 BUFFER_TOO_SMALL; 8 INTERNAL_ERROR.
   The current model_load maps parsing and model-compilation failures to COMPILE_ERROR.
   Status 7 can also mean an output name buffer is too short.

   Only functions declaring an error buffer write bounded UTF-8 diagnostics.
   Some count/get queries return only status; api_version returns a version instead.
   Destructors are NULL-safe. C++ exceptions do not cross the boundary.
   C ABI thread safety is not promised in v1.
   Release reports/outcomes/sessions before engines and models.

   See :ref:`Data objects and units <g02-data-types-en>` and :doc:`mod_G02_MCC_network_mpi`.

.. rubric:: Exact batch declaration / 批量接口原始声明

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/c_api.h
   :language: c
   :start-at: ap_g02_mcc_status ap_g02_mcc_step(
   :end-before: /* Persistent batch workspace.

:download:`Complete C header / 完整 C 接口头文件 <../../../../../G_Collision/G02_MCC_network/c_api.h>`

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fun_G02_mcc_c_api.cpp``

:doc:`C API <group_c_interface>`
