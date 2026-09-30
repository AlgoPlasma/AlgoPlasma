.. _mod-g02-mcc-network-f90:

.. rst-class:: ap-g02 ap-g02-reference

MCC：Fortran 接口与整体架构
==============================================

.. raw:: html

   <div class="ap-language-switch" role="group" aria-label="Language switch">
     <button type="button" class="ap-lang-button" data-ap-set-lang="zh">中文</button>
     <button type="button" class="ap-lang-button" data-ap-set-lang="en">English</button>
   </div>

.. container:: ap-lang ap-lang-zh

   .. tip::
      :class: g02-terms

      - null collision（空碰撞）：算法安排的候选被拒绝，只消耗抽样等待时间，粒子状态不变。它是抽样技巧，不是一种新的物理反应。
      - majorant（频率上界）：一个不小于真实碰撞频率的数，用它安排候选事件，再按“真实频率÷上界”接受候选。上界过松会增加空碰撞；低于真实频率则报错。
      - projectile / primary：projectile 是当前跟踪的入射粒子；primary 是一次事件后对这条原粒子记录的处理结果，可更新、移除或改变物种。background 是用密度、温度等描述的碰撞伙伴。
      - ParticleAdapter（粒子适配器）：把主程序已有的粒子存储接到 G02 的“转换接头”，负责读取粒子和提交更新，不是额外的物理粒子。
      - workspace（工作区）是反复使用的临时内存；session（会话）是 C/Fortran 接口持有这类工作状态的对象。跨时间步复用可减少分配，但同一对象不能同时处理两个调用。
      - ABI（应用二进制接口）规定不同语言编译后怎样传参和返回结果。handle（句柄）是库对象的引用；保存并通过接口使用它，不直接读取其内部数据。
      - reservoir（背景库）记录背景得到或失去的粒子、动量和能量；ledger（守恒账本）记录反应前后总量以核查守恒。两者用途不同，不能重复当作源项加入背景。

   .. tip:: Fortran 片段需要的声明

      ``iso_c_binding`` 是 Fortran 自带的 C 类型桥接模块，提供 ``c_double``、``c_int``、``c_int32_t``、``c_int64_t`` 等类型参数。G02 不会把这些名称转导出给主程序。
      在主程序声明区先写 ``use, intrinsic :: iso_c_binding``，再写 ``use mod_G02_MCC_network`` 和 ``implicit none``；``status`` 声明为 ``integer(c_int)``。
      本页简短调用式需要相应的 context、数组和步参数；:doc:`完整声明与初始化 <sub_G02_mcc_load>` 给出可构建示例。

   .. tip:: cell 与 state 的特殊值

      ``cell`` 是网格编号，不是数组下标。背景的 ``UINT32_MAX``（Fortran 的 ``-1_c_int32_t``）表示全域备用背景；正常网格编号必须与粒子一致。
      ``invalid_state`` 是 C++ 的 65535 哨兵值，C 用 ``UINT16_MAX``，Fortran 用 ``-1_c_int16_t``。它只供旧版按物种合并的背景使用，不等于基态，也不代表自动分配各态密度。
      入门时用 ``state_id(species, "ground")`` 或 Fortran 的 ``sub_G02_mcc_state_id`` 查询真实态；名称须存在于模型。被跟踪粒子的态必须有效。

   .. rubric:: 命名与文件组织

   本组沿用 G01 的文件命名方式：``mod_G02_*`` 汇总模块，``sub_G02_*`` 保存子程序，
   ``fun_G02_*`` 保存函数实现。Fortran 子程序用 ``call`` 调用；函数直接返回一个值。
   例如 ``call sub_G02_mcc_load(...)`` 加载模型，``fun_G02_mcc_api_version()`` 返回接口版本。
   文件名中的 ``G02`` 表示这些例程属于本碰撞模块。

   模块在 ``contains`` 后通过 ``include`` 引入下面的 Fortran 文件。
   同一职责的例程可以放在同一文件，例如 ``sub_G02_mcc_session.f90`` 包含初始化和关闭两个入口。
   这些 include 文件参与模块编译，不能作为独立程序再次编译。

   .. rubric:: 直接用途

   这是 Fortran 用户的模块入口。它通过 C 接口调用同一套 C++ 碰撞核心，
   并把结果整理为 Fortran 类型和可分配数组。建议先使用批量入口 ``sub_G02_mcc_step``。

   .. code-block:: fortran

      use, intrinsic :: iso_c_binding
      use mod_G02_MCC_network

   .. rubric:: 子程序目录

   .. list-table::
      :header-rows: 1
      :widths: 42 58

      * - 页面
        - 什么时候调用
      * - :doc:`sub_G02_mcc_load`
        - 初始化时加载模型；读取物种和反应定义。
      * - :doc:`sub_G02_mcc_model_queries`
        - 按名称查 ID，或枚举物种、内部态与反应。
      * - :doc:`sub_G02_mcc_step`
        - 每个时间步处理整个粒子数组，自动接收新粒子。
      * - :doc:`sub_G02_mcc_collide`
        - 旧程序需要单粒子结果时；结果由主程序自行提交。
      * - :doc:`sub_G02_mcc_session`
        - 连续多步调用时复用工作区和已准备的碰撞结果。
      * - :doc:`sub_G02_mcc_cleanup`
        - 释放旧单粒子结果、会话和上下文；了解报告转换。
      * - :doc:`fun_G02_mcc_api_version`
        - 返回跨语言接口版本号；无需先加载模型。
      * - :doc:`mod_G02_MCC_network_mpi`
        - 通过另一个模块 ``mod_G02_MCC_network_mpi`` 进行多进程调用。

   .. rubric:: 类型与错误约定

   参数的 ``in`` 表示输入，``out`` 表示输出，``inout`` 表示调用前后都使用。
   物理实数使用 ``real(c_double)``；整数按接口使用 ``c_int16_t``、``c_int32_t``、
   ``c_int64_t`` 或 ``c_size_t``，不要凭默认整数宽度替换它们。

   ``status == 0_c_int`` 表示成功。每次调用后先检查状态，再使用输出。
   加载、步进等入口会将诊断写入 ``context%error_message``；
   部分枚举函数仅更新状态码，因此旧的文字消息不能代替当前状态码。
   类型字段与单位见 :ref:`数据对象与单位 <g02-data-types-zh>`，状态码见 :doc:`fun_G02_mcc_c_api`。

   .. rubric:: 构建和完整例子

   G02 使用 CMake 构建并链接 C++ 库。外部 Fortran 工程同时启用 Fortran 和 CXX：

   .. code-block:: cmake

      project(my_pic LANGUAGES Fortran CXX)
      find_package(G02_MCC_network CONFIG REQUIRED)
      add_executable(my_pic main.f90)
      target_link_libraries(my_pic PRIVATE AlgoPlasma::G02_MCC_Fortran)

   可运行的主程序见下面的源码示例；模型选择 ``tests/009_collision/G02_MCC_network/data/demo_binary``。
   此示例检查每次返回状态，展示了加载、查询、会话、步进、清理的完整顺序。

   .. _g02-architecture-zh:

   .. rubric:: 架构与调用流程
      :class: g02-chapter

   .. rubric:: 调用层次与数据流

   G02 像一条处理流水线：读取反应规则，给每个粒子抽样碰撞，准备结果，最后一次性写回。
   粒子数组始终由你的主程序持有。图中的“背景收支”记录气体得到或失去的量，
   主程序可把它交给自己的气体/流体求解器。

   .. figure:: ../../../images/G_Collision/G02/architecture_zh.svg
      :alt: G02 从宿主接口、批量层、碰撞引擎到数据和运动学的调用架构
      :width: 100%

      实线表示主要调用与数据流；背景的时间推进由主程序负责。
      点击图片可查看原图。

   .. rubric:: 按职责找程序

   .. list-table::
      :header-rows: 1
      :widths: 25 35 40

      * - 层
        - 入口
        - 负责什么
      * - Fortran / C 接口
        - :doc:`mod_G02_MCC_network`、:doc:`fun_G02_mcc_c_api`
        - 转换语言类型、管理句柄、传递错误。
      * - 批量处理
        - :doc:`fun_G02_mcc_batch`
        - 遍历本步合格粒子，分配新 ID，汇总结果，统一提交。
      * - 单粒子引擎
        - :doc:`fun_G02_mcc_engine`
        - 按当前物种/态选择通道，抽样候选时间和真实碰撞。
      * - 模型与表格
        - :doc:`fun_G02_mcc_model`
        - 读取 CSV、检查反应与单位、插值、计算频率上界。
      * - 末态运动学
        - :doc:`fun_G02_mcc_kinematics`
        - 根据总动量和可用能量，计算产物速度。
      * - MPI 包装
        - :doc:`mod_G02_MCC_network_mpi`
        - 协调各进程的准备结果、新粒子 ID 与提交。

   .. rubric:: 先准备、后提交：粒子数组的更新约定

   1. ``prepare_step`` 读取粒子，在工作区中计算候选更新；此时主程序还看不到变化。
   2. 为新粒子分配 ID，再调用适配器的 ``prepare_commit``，准备所需内存。
   3. 全部成功后，``commit`` 写回；它按约定不能失败。此前的错误丢弃本步准备结果。

   MPI 会在准备与提交之间做全体进程一致性检查。``MccWorkspace`` 是可跨步复用的临时内存，
   一个尚未提交或释放的 ``PreparedMccStep`` 会占用它，不能同时用于另一调用。

   .. rubric:: 主程序需要提供的功能

   - 当前位置所属的网格编号、粒子唯一 ID、背景密度/温度/平均速度，以及时间步。
   - 电场计算、粒子位置推进、壁面处理和跨 MPI 区域迁移。
   - 如何用 ``reservoir`` 更新背景；固定背景算例只核算交换量。

   加载模型通常在初始化时完成；碰撞函数放在时间循环中。
   :ref:`数据对象与单位 <g02-data-types-zh>` 解释各数据对象，:doc:`sub_G02_mcc_step` 给出 Fortran 的每步调用。

   .. _g02-data-types-zh:

   .. rubric:: 数据对象与单位
      :class: g02-chapter

   .. rubric:: 沿着输入与输出看数据

   一次批量调用读“粒子 + 背景”，写回粒子并返回“报告”。
   下表的字段在 C++、C 和 Fortran 中尽量保持同名；
   C/Fortran 三维向量是长度为 3 的数组，顺序都是 x、y、z。

   .. list-table:: ParticleState / ap_g02_mcc_particle / g02_mcc_particle
      :header-rows: 1
      :widths: 24 28 48

      * - 字段
        - 单位/范围
        - 含义
      * - species / state
        - 16 位 ID
        - 粒子种类与内部态；必须属于模型，并相互匹配。
      * - position / velocity
        - m / m/s
        - 位置与速度；G02 仅更新碰撞速度，不推进位置。
      * - weight
        - 正数，无量纲
        - 一个计算粒子代表多少物理粒子；背景交换量按权重计算。
      * - id
        - 64 位整数
        - 粒子稳定编号，批量中应唯一。
      * - birth_step
        - 64 位整数
        - 从哪一步开始参与；新产物设为当前步+1。
      * - cell
        - 32 位整数
        - 主程序提供的网格编号，用来查找局部背景。

   .. list-table:: CellBackground / g02_mcc_cell_background
      :header-rows: 1
      :widths: 24 28 48

      * - 字段
        - 单位/范围
        - 含义
      * - cell
        - 网格编号
        - UINT32_MAX 是全域备用背景；Fortran 写 -1_c_int32_t。
      * - species / state
        - 模型 ID
        - 背景物种/态；invalid_state 采用按物种合并的旧约定。
      * - density_m3
        - m⁻³，有限非负
        - 物理数密度，不能填入计算粒子样本数。
      * - temperature_k
        - K，有限非负
        - 背景平动温度，还需落在所用速率表允许的范围内。
      * - drift_m_per_s
        - m/s
        - 背景平均速度，与热运动分开提供。

   C++ CellBackground 的物种等字段放在 component 内。
   同一网格同一物种的不同态应共享温度与漂移；
   局部网格有自己的背景集合时，不再逐条从全域集合补齐。

   .. rubric:: 返回量：三种用途

   - **统计**：StepReport 的 candidates、real_events、null_events 与 by_reaction；
     Fortran 分别在 report%stats 与 report%reaction_id/count。
   - **耦合**：reservoir 是背景收到的增量，正值表示增加，负值表示损失。
     physical_particles 为物理粒子数，动量 kg·m/s，能量 J。
   - **核算**：ledger 保存碰撞前后电荷、动量、动能、内部能和能量残差，
     用于诊断，不重复作为背景源项。

   内部态和反应能量字段用 eV，账本用 J，1 eV = 1.602176634 × 10⁻¹⁹ J。
   eV 与 K 都不能直接填入以 J 命名的字段。

   .. rubric:: 批量报告与旧单粒子结果

   StepReport 描述一次批量调用，粒子已成功提交。
   StepOutcome 描述一个待由主程序提交的单粒子结果，包含 primary_action、created 和 events。
   旧 C/Fortran 单粒子背景和交换结构不含 state/cell，批量结构则支持按网格与态区分。
   详见 :doc:`sub_G02_mcc_step`、:doc:`sub_G02_mcc_collide`。

.. container:: ap-lang ap-lang-en

   .. tip::
      :class: g02-terms

      - A null collision is a rejected candidate: sampled waiting time is consumed but the particle state stays unchanged. It is a sampling device, not a physical reaction.
      - A workspace is reusable scratch memory. A session holds this state for C/Fortran callers. Reuse reduces allocation, but one instance must not serve concurrent calls.
      - ABI (Application Binary Interface) defines how compiled code passes arguments and results. A handle refers to a library-owned object; use API functions rather than inspecting its internals.
      - Reservoir deltas track background gains/losses of particles, momentum and energy. A conservation ledger compares totals before and after reactions. Do not apply both as background source terms.

   .. tip:: Declarations required by Fortran fragments

      The intrinsic ``iso_c_binding`` module provides C-compatible kinds such as ``c_double``, ``c_int``, ``c_int32_t`` and ``c_int64_t``. G02 does not re-export them to the host.
      In the declaration section, write ``use, intrinsic :: iso_c_binding``, ``use mod_G02_MCC_network`` and ``implicit none``; declare status as ``integer(c_int)``.
      Short calls assume initialized context, arrays and step parameters; see :doc:`the complete caller <sub_G02_mcc_load>`.

   .. tip:: Special cell and state values

      cell is a mesh ID, not an array index. Background ``UINT32_MAX`` (Fortran ``-1_c_int32_t``) selects uniform fallback; local IDs must match particles.
      C++ ``invalid_state`` is the 65535 sentinel (C ``UINT16_MAX``; Fortran ``-1_c_int16_t``), only for legacy species-aggregate backgrounds. It is not ground state and does not distribute density over states.
      Prefer a real state obtained with ``state_id`` or ``sub_G02_mcc_state_id`` using a label in the model. Tracked particles must have valid states.

   .. rubric:: Names and file organization

   G02 follows G01: ``mod_G02_*`` groups a module, ``sub_G02_*`` contains subroutines,
   and ``fun_G02_*`` contains function implementations. In Fortran, use ``call`` for a
   subroutine and use a function's return value directly. For example,
   ``call sub_G02_mcc_load(...)`` loads a model and ``fun_G02_mcc_api_version()`` returns the ABI version.

   The module includes the Fortran implementation files after ``contains``.
   Related routines can share a file: ``sub_G02_mcc_session.f90`` contains initialization and close.
   These include files are compiled as part of the module, never as separate translation units.

   .. rubric:: Direct purpose

   This is the Fortran entry module. It calls the C++ core through C functions and presents
   Fortran types and allocatable arrays. Start with the batch entry ``sub_G02_mcc_step``.

   .. code-block:: fortran

      use, intrinsic :: iso_c_binding
      use mod_G02_MCC_network

   .. list-table:: Routine pages
      :header-rows: 1
      :widths: 42 58

      * - Page
        - When to use it
      * - :doc:`sub_G02_mcc_load`
        - Load a model during initialization.
      * - :doc:`sub_G02_mcc_model_queries`
        - Look up IDs or enumerate species, states and reactions.
      * - :doc:`sub_G02_mcc_step`
        - Process the whole particle array each step.
      * - :doc:`sub_G02_mcc_collide`
        - Obtain a legacy single-particle outcome for host-side commit.
      * - :doc:`sub_G02_mcc_session`
        - Reuse workspace across steps and preserve pending capacity retries.
      * - :doc:`sub_G02_mcc_cleanup`
        - Release outcomes, sessions and contexts; collect reports.
      * - :doc:`fun_G02_mcc_api_version`
        - Return the ABI version without loading a model.
      * - :doc:`mod_G02_MCC_network_mpi`
        - Use the separate MPI module.

   .. rubric:: Types and errors

   Input, output and input/output parameters are marked in, out and inout.
   Use ``real(c_double)`` and the declared interoperable integer kinds.
   Check ``status == 0_c_int`` before reading outputs.
   Load and step routines populate ``context%error_message``;
   some enumeration routines update only the status, so stale text must not override the current code.
   See :ref:`Data objects and units <g02-data-types-en>` and :doc:`fun_G02_mcc_c_api`.

   .. rubric:: Build and complete example

   An external Fortran project enables both Fortran and CXX and links the installed target:

   .. code-block:: cmake

      project(my_pic LANGUAGES Fortran CXX)
      find_package(G02_MCC_network CONFIG REQUIRED)
      add_executable(my_pic main.f90)
      target_link_libraries(my_pic PRIVATE AlgoPlasma::G02_MCC_Fortran)

   The source example below uses ``tests/009_collision/G02_MCC_network/data/demo_binary`` and checks status after every call.
   It demonstrates load, queries, session, stepping and cleanup.

   .. _g02-architecture-en:

   .. rubric:: Architecture and call flow
      :class: g02-chapter

   .. rubric:: Call layers and data flow

   G02 loads reaction rules, samples particle collisions, prepares results and commits them together.
   The host owns particle storage. Background exchange records can feed the host's gas or fluid solver.

   .. figure:: ../../../images/G_Collision/G02/architecture_en.svg
      :alt: G02 host interfaces, batch processing, engine, model tables and kinematics
      :width: 100%

      Main calls and data flow. The host evolves the background.
      Select the image to open it at full size.

   .. list-table:: Find the code by responsibility
      :header-rows: 1
      :widths: 25 35 40

      * - Layer
        - Entry
        - Responsibility
      * - Fortran / C
        - :doc:`mod_G02_MCC_network`, :doc:`fun_G02_mcc_c_api`
        - Convert types, manage handles and transport errors.
      * - Batch
        - :doc:`fun_G02_mcc_batch`
        - Visit eligible particles, allocate child IDs, aggregate and commit.
      * - Particle engine
        - :doc:`fun_G02_mcc_engine`
        - Match species/state, sample times, channels and collisions.
      * - Model and tables
        - :doc:`fun_G02_mcc_model`
        - Read CSV, validate units/reactions, interpolate and bound rates.
      * - Final-state kinematics
        - :doc:`fun_G02_mcc_kinematics`
        - Construct product velocities from momentum and available energy.
      * - MPI wrapper
        - :doc:`mod_G02_MCC_network_mpi`
        - Coordinate preparation, child IDs and commit across ranks.

   .. rubric:: Prepare before commit

   1. ``prepare_step`` computes staged changes in a workspace, leaving visible particles unchanged.
   2. Allocate child IDs and call adapter ``prepare_commit`` to prepare storage.
   3. Only after success, ``commit`` writes results and must not fail. Earlier errors discard staged changes.

   MPI adds agreement across ranks before commit. A live ``PreparedMccStep`` occupies its
   ``MccWorkspace``, which cannot serve another call until released.

   .. rubric:: Host responsibilities

   The host supplies cell IDs, unique particle IDs, background properties and time steps.
   It handles fields, position pushes, walls and MPI migration, and decides how to apply background exchange.
   Load once during initialization, then call collisions inside the time loop.
   See :ref:`Data objects and units <g02-data-types-en>` and :doc:`sub_G02_mcc_step`.

   .. _g02-data-types-en:

   .. rubric:: Data objects and units
      :class: g02-chapter

   .. rubric:: Follow the data

   A batch call reads particles and background, updates particles and returns a report.
   C/Fortran vectors have three entries in x, y, z order.

   .. list-table:: ParticleState / ap_g02_mcc_particle / g02_mcc_particle
      :header-rows: 1
      :widths: 24 28 48

      * - Field
        - Unit/range
        - Meaning
      * - species / state
        - 16-bit IDs
        - Valid, mutually consistent model species and state.
      * - position / velocity
        - m / m/s
        - G02 changes collision velocities, not positions.
      * - weight
        - Positive, dimensionless
        - Physical particles represented; scales background exchange.
      * - id
        - 64-bit integer
        - Stable unique particle ID.
      * - birth_step
        - 64-bit integer
        - First eligible step; children use current step+1.
      * - cell
        - 32-bit integer
        - Host-supplied cell for background lookup.

   .. list-table:: CellBackground / g02_mcc_cell_background
      :header-rows: 1
      :widths: 24 28 48

      * - Field
        - Unit/range
        - Meaning
      * - cell
        - Cell ID
        - UINT32_MAX is uniform fallback; Fortran uses -1_c_int32_t.
      * - species / state
        - Model IDs
        - invalid_state uses legacy species-aggregated density.
      * - density_m3
        - Finite nonnegative m⁻³
        - Physical number density, separate from sample count.
      * - temperature_k
        - Finite nonnegative K
        - Translational temperature; rate-table domain rules also apply.
      * - drift_m_per_s
        - m/s
        - Mean background velocity, separate from thermal motion.

   C++ stores species and other properties inside component.
   States of the same species in one cell share temperature and drift.
   A cell-specific background set replaces the uniform set; missing entries are not individually filled from it.

   .. rubric:: Three output uses

   Statistics count candidates, real/null events and reactions.
   Reservoir entries are signed increments received by the background: physical particle count,
   momentum in kg·m/s and energies in J.
   The ledger diagnoses before/after charge, momentum and energy; do not add it as another source.

   State/reaction energy fields use eV, while ledgers use J.
   1 eV = 1.602176634 × 10⁻¹⁹ J.
   A StepReport follows a committed batch; a StepOutcome proposes a single-particle update for the host.
   Legacy C/Fortran single-particle background and exchange structures omit cell/state fields.
   See :doc:`sub_G02_mcc_step` and :doc:`sub_G02_mcc_collide`.

.. rubric:: Module includes / 模块包含关系

.. literalinclude:: ../../../../../G_Collision/G02_MCC_network/fortran_interface/mod_G02_MCC_network.f90
   :language: fortran
   :start-at: ! Public G02 routines
   :end-before: end module mod_G02_MCC_network

.. rubric:: Complete caller / 完整调用程序

.. literalinclude:: ../../../../../tests/009_collision/G02_MCC_network/examples/host_fortran/main.f90
   :language: fortran
   :linenos:

.. container:: g02-backlink

   :doc:`返回 G02 教程 / Back to G02 <../G02_MCC_network>`

.. rubric:: 文件归属 / File location

``G_Collision/G02_MCC_network/fortran_interface/mod_G02_MCC_network.f90``

:doc:`Fortran API <group_fortran_interface>`
