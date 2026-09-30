! SPDX-License-Identifier: Apache-2.0
!
! Fortran 2008 adapter for the G02_MCC_network C ABI.
!
! Fortran users work with g02_mcc_context, g02_mcc_particle,
! g02_mcc_background and g02_mcc_outcome only. C handles stay private and the
! flat C result is copied into Fortran arrays by sub_G02_mcc_collide.
! 阅读顺序：公开常量 -> 数据类型 -> C 函数声明 -> contains 内的包装过程。
! 本模块负责语言转换；碰撞概率与碰后速度仍由 C++ 核心计算。
! 使用顺序：load -> 查询物种/能级 -> collide 或 step -> 清理结果/会话 -> close。
! status == 0 表示成功；非零时先处理错误，再读取输出。
! context 保存最近一次状态；带 errbuf 的调用还会更新 error_message。
! context、session、outcome 内的 c_ptr 是资源句柄，不要用赋值复制其所有权。
module mod_G02_MCC_network
    ! ISO_C_BINDING 提供与 C 一致的类型尺寸和指针工具，避免跨语言布局不一致。
    ! c_double 对应 C double；c_size_t 对应数组长度；c_int16_t 等指定整数位宽。
    ! 用户程序也应 use iso_c_binding，并使用 1.0_c_double 等带 kind 的常量。
    use, intrinsic :: iso_c_binding
    implicit none
    private

    public :: g02_mcc_context, g02_mcc_particle, g02_mcc_background, g02_mcc_outcome
    public :: g02_mcc_created, g02_mcc_reservoir, g02_mcc_event, g02_mcc_ledger
    public :: sub_G02_mcc_load, sub_G02_mcc_species_id, sub_G02_mcc_state_id
    public :: sub_G02_mcc_collide, sub_G02_mcc_close, sub_G02_mcc_outcome_destroy
    public :: g02_mcc_cell_background, g02_mcc_cell_reservoir
    public :: g02_mcc_step_stats, g02_mcc_step_report, sub_G02_mcc_step
    public :: g02_mcc_session, sub_G02_mcc_session_init, sub_G02_mcc_session_close
    public :: sub_G02_mcc_report_collect
    public :: sub_G02_mcc_species_count, sub_G02_mcc_species_get
    public :: sub_G02_mcc_state_count, sub_G02_mcc_state_get
    public :: sub_G02_mcc_reaction_count, sub_G02_mcc_reaction_get
    public :: fun_G02_mcc_api_version
    public :: G02_MCC_ACTION_NONE, G02_MCC_ACTION_UPDATE
    public :: G02_MCC_ACTION_REMOVE, G02_MCC_ACTION_MOVE_SPECIES

    ! 单粒子输出中的 primary 是原入射粒子碰撞后的状态。
    ! action 指示宿主保留、更新、删除或把它移入另一物种的粒子集合。
    integer(c_int), parameter :: G02_MCC_ACTION_NONE = 0
    integer(c_int), parameter :: G02_MCC_ACTION_UPDATE = 1
    integer(c_int), parameter :: G02_MCC_ACTION_REMOVE = 2
    integer(c_int), parameter :: G02_MCC_ACTION_MOVE_SPECIES = 3
    integer(c_int), parameter, public :: G02_MCC_BACKEND_AUTO = 0
    integer(c_int), parameter, public :: G02_MCC_BACKEND_SERIAL = 1
    integer(c_int), parameter, public :: G02_MCC_BACKEND_OPENMP = 2
    integer(c_int), parameter, public :: G02_MCC_SAMPLER_PREFIX = 0
    integer(c_int), parameter, public :: G02_MCC_SAMPLER_ALIAS = 1

    integer, parameter :: g02_mcc_error_length = 512

    ! === 1. 跨语言数据：bind(c) 使字段排列与对应 C struct 一致 ===
    ! species/state 是模型 ID，不是 Fortran 数组下标；请用查询过程取得。
    ! position 用 m，velocity 用 m/s；weight 是一个模拟粒子代表的真实粒子数。
    ! id 是跨时间步保持不变的粒子身份，用于可重复随机抽样；不要每步重新编号。
    !> Mirrors ap_g02_mcc_particle.
    type, bind(c) :: g02_mcc_particle
        integer(c_int16_t) :: species = 0
        integer(c_int16_t) :: state = 0
        real(c_double) :: position(3) = 0.0_c_double
        real(c_double) :: velocity(3) = 0.0_c_double
        real(c_double) :: weight = 1.0_c_double
        integer(c_int64_t) :: id = 0_c_int64_t
        integer(c_int64_t) :: birth_step = 0_c_int64_t
        integer(c_int32_t) :: cell = 0_c_int32_t
    end type g02_mcc_particle

    !> Mirrors ap_g02_mcc_background.
    type, bind(c) :: g02_mcc_background
        integer(c_int16_t) :: species = 0
        real(c_double) :: density_m3 = 0.0_c_double
        real(c_double) :: temperature_k = 300.0_c_double
        real(c_double) :: drift_m_per_s(3) = 0.0_c_double
    end type g02_mcc_background

    ! 背景按网格 cell 分配；cell=-1_c_int32_t 对应 C 的 UINT32_MAX，表示统一后备背景。
    ! state=-1_c_int16_t 对应 invalid_state，表示不区分能级的汇总背景。
    ! 核心优先匹配指定能级，找不到时才使用汇总背景；它并不表示基态。
    ! 常规物种/能级 ID 原样传递，不做 Fortran 的加一转换。
    type, bind(c) :: g02_mcc_cell_background
        integer(c_int32_t) :: cell = 0_c_int32_t
        integer(c_int16_t) :: species = 0_c_int16_t
        integer(c_int16_t) :: state = -1_c_int16_t
        real(c_double) :: density_m3 = 0.0_c_double
        real(c_double) :: temperature_k = 300.0_c_double
        real(c_double) :: drift_m_per_s(3) = 0.0_c_double
    end type g02_mcc_cell_background

    ! 背景库的增减账本：记录未作为显式粒子追踪的背景物质获得/损失的量。
    ! 宿主若需要背景随时间变化，应使用这些增量更新自己的背景模型。
    type, bind(c) :: g02_mcc_cell_reservoir
        integer(c_int32_t) :: cell = 0_c_int32_t
        integer(c_int16_t) :: species = 0_c_int16_t
        integer(c_int16_t) :: state = -1_c_int16_t
        real(c_double) :: physical_particles = 0.0_c_double
        real(c_double) :: momentum_kg_m_per_s(3) = 0.0_c_double
        real(c_double) :: kinetic_energy_j = 0.0_c_double
        real(c_double) :: internal_energy_j = 0.0_c_double
    end type g02_mcc_cell_reservoir

    ! candidates 是尝试的候选事件数；其中真实碰撞计入 real_events。
    ! null_events 是被拒绝的候选事件，只推进抽样时间，不改变粒子状态。
    type, bind(c) :: g02_mcc_step_stats
        integer(c_int64_t) :: particles_visited = 0_c_int64_t
        integer(c_int64_t) :: candidates = 0_c_int64_t
        integer(c_int64_t) :: real_events = 0_c_int64_t
        integer(c_int64_t) :: null_events = 0_c_int64_t
        integer(c_int64_t) :: created_particles = 0_c_int64_t
        real(c_double) :: preparation_seconds = 0.0_c_double
        real(c_double) :: sampling_seconds = 0.0_c_double
        real(c_double) :: reduction_seconds = 0.0_c_double
        real(c_double) :: commit_seconds = 0.0_c_double
        real(c_double) :: total_seconds = 0.0_c_double
    end type g02_mcc_step_stats

    type, bind(c) :: g02_mcc_created
        integer(c_int64_t) :: parent_id = 0_c_int64_t
        integer(c_int32_t) :: event_index = 0_c_int32_t
        integer(c_int32_t) :: product_ordinal = 0_c_int32_t
        integer(c_int16_t) :: species = 0
        integer(c_int16_t) :: state = 0
        real(c_double) :: position(3) = 0.0_c_double
        real(c_double) :: velocity(3) = 0.0_c_double
        real(c_double) :: weight = 1.0_c_double
        integer(c_int64_t) :: birth_step = 0_c_int64_t
    end type g02_mcc_created

    type, bind(c) :: g02_mcc_reservoir
        integer(c_int16_t) :: species = 0
        real(c_double) :: physical_particles = 0.0_c_double
        real(c_double) :: momentum_kg_m_per_s(3) = 0.0_c_double
        real(c_double) :: kinetic_energy_j = 0.0_c_double
        real(c_double) :: internal_energy_j = 0.0_c_double
    end type g02_mcc_reservoir

    ! 单事件诊断：majorant 是用于抽样的碰撞频率上界，单位 s^-1。
    ! sampled_rate 是本次候选的真实频率；has_* 非零时对应的诊断值才有效。
    ! algorithm 使用 G02 算法编号，与 C_Gather 模块的编号没有对应关系。
    type, bind(c) :: g02_mcc_event
        integer(c_int32_t) :: event_index = 0_c_int32_t
        integer(c_int32_t) :: reaction = 0_c_int32_t
        integer(c_int) :: algorithm = 0
        integer(c_int) :: real_event = 0
        integer(c_int) :: null_event = 0
        real(c_double) :: majorant_s_inv = 0.0_c_double
        real(c_double) :: sampled_rate_s_inv = 0.0_c_double
        integer(c_int16_t) :: background_species = 0
        integer(c_int) :: has_relative_energy = 0
        real(c_double) :: relative_energy_ev = 0.0_c_double
        integer(c_int) :: has_cross_section = 0
        real(c_double) :: cross_section_m2 = 0.0_c_double
    end type g02_mcc_event

    ! 守恒账本同时考虑显式粒子与背景：比较碰撞前后的电荷、动量和总能量。
    ! kinetic 是平动动能，internal 是内部能；未显式追踪的能量另行记账。
    type, bind(c) :: g02_mcc_ledger
        real(c_double) :: charge_before_c = 0.0_c_double
        real(c_double) :: charge_after_c = 0.0_c_double
        real(c_double) :: momentum_before_kg_m_per_s(3) = 0.0_c_double
        real(c_double) :: momentum_after_kg_m_per_s(3) = 0.0_c_double
        real(c_double) :: kinetic_before_j = 0.0_c_double
        real(c_double) :: kinetic_after_j = 0.0_c_double
        real(c_double) :: internal_before_j = 0.0_c_double
        real(c_double) :: internal_after_j = 0.0_c_double
        real(c_double) :: released_energy_j = 0.0_c_double
        real(c_double) :: radiated_or_unresolved_j = 0.0_c_double
        real(c_double) :: energy_residual_j = 0.0_c_double
        real(c_double) :: tolerance_j = 0.0_c_double
    end type g02_mcc_ledger

    !> Private C request layout (mirrors ap_g02_mcc_request).
    type, bind(c) :: ap_g02_mcc_request
        type(g02_mcc_particle) :: projectile
        type(c_ptr) :: background = c_null_ptr
        integer(c_size_t) :: background_count = 0_c_size_t
        real(c_double) :: dt_s = 0.0_c_double
        integer(c_int64_t) :: global_step = 0_c_int64_t
        integer(c_int64_t) :: seed = 0_c_int64_t
        integer(c_int32_t) :: max_events_per_step = 0_c_int32_t
    end type ap_g02_mcc_request

    ! === 2. Fortran 持有的上下文与结果 ===
    ! c_null_ptr 表示没有 C 对象；c_associated 用来判断句柄是否存在。
    ! Fortran allocatable 数组可以自动释放，但 C 句柄必须调用对应的 close/destroy。
    !> Loaded model and engine handles plus the last diagnostic.
    type :: g02_mcc_context
        type(c_ptr) :: model_handle = c_null_ptr
        type(c_ptr) :: engine_handle = c_null_ptr
        logical :: loaded = .false.
        integer(c_int) :: status = 0
        character(len=g02_mcc_error_length) :: error_message = ''
    end type g02_mcc_context

    !> Result of one collision step, copied out of the C ABI.
    type :: g02_mcc_outcome
        integer(c_int) :: primary_action = G02_MCC_ACTION_NONE
        type(g02_mcc_particle) :: primary
        integer(c_int16_t) :: primary_destination = 0
        integer(c_int32_t) :: candidates = 0
        integer(c_int32_t) :: real_events = 0
        integer(c_int32_t) :: null_events = 0
        logical :: event_limit_reached = .false.
        type(g02_mcc_created), allocatable :: created(:)
        type(g02_mcc_reservoir), allocatable :: reservoir(:)
        type(g02_mcc_event), allocatable :: events(:)
        type(g02_mcc_ledger) :: ledger
        type(c_ptr) :: handle = c_null_ptr
    end type g02_mcc_outcome

    type :: g02_mcc_step_report
        type(g02_mcc_step_stats) :: stats
        type(g02_mcc_ledger) :: ledger
        type(g02_mcc_cell_reservoir), allocatable :: reservoir(:)
        integer(c_int32_t), allocatable :: reaction_id(:)
        integer(c_int64_t), allocatable :: reaction_count(:)
    end type g02_mcc_step_report

    type :: g02_mcc_session
        type(c_ptr) :: handle = c_null_ptr
    end type g02_mcc_session

    ! === 3. C ABI 声明：这里只声明调用约定，函数实现位于 C++ 文件 ===
    ! bind(c, name=...) 指定链接的 C 名称；import 引入模块中的类型/kind。
    ! value 对应 C 按值参数；无 value 的标量通常对应 C 指针输出参数。
    ! C 字符串以 c_null_char 结束，不能直接把 Fortran 定长字符串当 C 字符串。
    interface
        function ap_g02_mcc_api_version() bind(c, name="ap_g02_mcc_api_version") result(version)
            import :: c_int
            integer(c_int) :: version
        end function ap_g02_mcc_api_version

        function ap_g02_mcc_model_load(path, out_model, err, err_size) &
                bind(c, name="ap_g02_mcc_model_load") result(status)
            import :: c_char, c_ptr, c_size_t, c_int
            character(kind=c_char), dimension(*) :: path
            type(c_ptr) :: out_model
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_model_load

        function ap_g02_mcc_model_destroy(model) bind(c, name="ap_g02_mcc_model_destroy") &
                result(status)
            import :: c_ptr, c_int
            type(c_ptr), value :: model
            integer(c_int) :: status
        end function ap_g02_mcc_model_destroy

        function ap_g02_mcc_model_species_id(model, name, out_id, err, err_size) &
                bind(c, name="ap_g02_mcc_model_species_id") result(status)
            import :: c_ptr, c_char, c_size_t, c_int, c_int16_t
            type(c_ptr), value :: model
            character(kind=c_char), dimension(*) :: name
            integer(c_int16_t) :: out_id
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_model_species_id

        function ap_g02_mcc_model_state_id(model, species, label, out_id, err, err_size) &
                bind(c, name="ap_g02_mcc_model_state_id") result(status)
            import :: c_ptr, c_char, c_size_t, c_int, c_int16_t
            type(c_ptr), value :: model
            integer(c_int16_t), value :: species
            character(kind=c_char), dimension(*) :: label
            integer(c_int16_t) :: out_id
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_model_state_id

        function ap_g02_mcc_model_species_count(model, count) &
                bind(c, name="ap_g02_mcc_model_species_count") result(status)
            import :: c_ptr, c_size_t, c_int
            type(c_ptr), value :: model
            integer(c_size_t) :: count
            integer(c_int) :: status
        end function ap_g02_mcc_model_species_count

        function ap_g02_mcc_model_species_get(model, index, id, name, name_capacity, &
                mass, charge, representation) &
                bind(c, name="ap_g02_mcc_model_species_get") result(status)
            import :: c_ptr, c_size_t, c_int, c_int16_t, c_char, c_double
            type(c_ptr), value :: model
            integer(c_size_t), value :: index, name_capacity
            integer(c_int16_t) :: id
            character(kind=c_char) :: name(*)
            real(c_double) :: mass
            integer(c_int) :: charge, representation, status
        end function ap_g02_mcc_model_species_get

        function ap_g02_mcc_model_state_count(model, count) &
                bind(c, name="ap_g02_mcc_model_state_count") result(status)
            import :: c_ptr, c_size_t, c_int
            type(c_ptr), value :: model
            integer(c_size_t) :: count
            integer(c_int) :: status
        end function ap_g02_mcc_model_state_count

        function ap_g02_mcc_model_state_get(model, index, id, species, label, &
                label_capacity, energy) &
                bind(c, name="ap_g02_mcc_model_state_get") result(status)
            import :: c_ptr, c_size_t, c_int, c_int16_t, c_char, c_double
            type(c_ptr), value :: model
            integer(c_size_t), value :: index, label_capacity
            integer(c_int16_t) :: id, species
            character(kind=c_char) :: label(*)
            real(c_double) :: energy
            integer(c_int) :: status
        end function ap_g02_mcc_model_state_get

        function ap_g02_mcc_model_reaction_count(model, count) &
                bind(c, name="ap_g02_mcc_model_reaction_count") result(status)
            import :: c_ptr, c_size_t, c_int
            type(c_ptr), value :: model
            integer(c_size_t) :: count
            integer(c_int) :: status
        end function ap_g02_mcc_model_reaction_count

        function ap_g02_mcc_model_reaction_get(model, index, id, name, name_capacity) &
                bind(c, name="ap_g02_mcc_model_reaction_get") result(status)
            import :: c_ptr, c_size_t, c_int, c_int32_t, c_char
            type(c_ptr), value :: model
            integer(c_size_t), value :: index, name_capacity
            integer(c_int32_t) :: id
            character(kind=c_char) :: name(*)
            integer(c_int) :: status
        end function ap_g02_mcc_model_reaction_get

        function ap_g02_mcc_engine_create(model, out_engine, err, err_size) &
                bind(c, name="ap_g02_mcc_engine_create") result(status)
            import :: c_ptr, c_char, c_size_t, c_int
            type(c_ptr), value :: model
            type(c_ptr) :: out_engine
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_engine_create

        function ap_g02_mcc_engine_destroy(engine) bind(c, name="ap_g02_mcc_engine_destroy") &
                result(status)
            import :: c_ptr, c_int
            type(c_ptr), value :: engine
            integer(c_int) :: status
        end function ap_g02_mcc_engine_destroy

        function ap_g02_mcc_collide(engine, request, out_outcome, err, err_size) &
                bind(c, name="ap_g02_mcc_collide") result(status)
            import :: c_ptr, c_char, c_size_t, c_int, ap_g02_mcc_request
            type(c_ptr), value :: engine
            type(ap_g02_mcc_request) :: request
            type(c_ptr) :: out_outcome
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_collide

        function ap_g02_mcc_outcome_destroy(outcome) &
                bind(c, name="ap_g02_mcc_outcome_destroy") result(status)
            import :: c_ptr, c_int
            type(c_ptr), value :: outcome
            integer(c_int) :: status
        end function ap_g02_mcc_outcome_destroy

        function ap_g02_mcc_outcome_primary(outcome, particle, action, destination, err, &
                err_size) bind(c, name="ap_g02_mcc_outcome_primary") result(status)
            import :: c_ptr, c_char, c_size_t, c_int, c_int16_t, g02_mcc_particle
            type(c_ptr), value :: outcome
            type(g02_mcc_particle) :: particle
            integer(c_int) :: action
            integer(c_int16_t) :: destination
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_outcome_primary

        function ap_g02_mcc_outcome_counters(outcome, candidates, real_events, null_events, &
                limit_reached, err, err_size) &
                bind(c, name="ap_g02_mcc_outcome_counters") result(status)
            import :: c_ptr, c_char, c_size_t, c_int, c_int32_t
            type(c_ptr), value :: outcome
            integer(c_int32_t) :: candidates
            integer(c_int32_t) :: real_events
            integer(c_int32_t) :: null_events
            integer(c_int) :: limit_reached
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_outcome_counters

        function ap_g02_mcc_outcome_created_count(outcome, count, err, err_size) &
                bind(c, name="ap_g02_mcc_outcome_created_count") result(status)
            import :: c_ptr, c_char, c_size_t, c_int
            type(c_ptr), value :: outcome
            integer(c_size_t) :: count
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_outcome_created_count

        function ap_g02_mcc_outcome_created_get(outcome, index, created, err, err_size) &
                bind(c, name="ap_g02_mcc_outcome_created_get") result(status)
            import :: c_ptr, c_char, c_size_t, c_int, g02_mcc_created
            type(c_ptr), value :: outcome
            integer(c_size_t), value :: index
            type(g02_mcc_created) :: created
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_outcome_created_get

        function ap_g02_mcc_outcome_reservoir_count(outcome, count, err, err_size) &
                bind(c, name="ap_g02_mcc_outcome_reservoir_count") result(status)
            import :: c_ptr, c_char, c_size_t, c_int
            type(c_ptr), value :: outcome
            integer(c_size_t) :: count
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_outcome_reservoir_count

        function ap_g02_mcc_outcome_reservoir_get(outcome, index, reservoir, err, err_size) &
                bind(c, name="ap_g02_mcc_outcome_reservoir_get") result(status)
            import :: c_ptr, c_char, c_size_t, c_int, g02_mcc_reservoir
            type(c_ptr), value :: outcome
            integer(c_size_t), value :: index
            type(g02_mcc_reservoir) :: reservoir
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_outcome_reservoir_get

        function ap_g02_mcc_outcome_event_count(outcome, count, err, err_size) &
                bind(c, name="ap_g02_mcc_outcome_event_count") result(status)
            import :: c_ptr, c_char, c_size_t, c_int
            type(c_ptr), value :: outcome
            integer(c_size_t) :: count
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_outcome_event_count

        function ap_g02_mcc_outcome_event_get(outcome, index, event, err, err_size) &
                bind(c, name="ap_g02_mcc_outcome_event_get") result(status)
            import :: c_ptr, c_char, c_size_t, c_int, g02_mcc_event
            type(c_ptr), value :: outcome
            integer(c_size_t), value :: index
            type(g02_mcc_event) :: event
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_outcome_event_get

        function ap_g02_mcc_outcome_ledger_get(outcome, ledger, err, err_size) &
                bind(c, name="ap_g02_mcc_outcome_ledger_get") result(status)
            import :: c_ptr, c_char, c_size_t, c_int, g02_mcc_ledger
            type(c_ptr), value :: outcome
            type(g02_mcc_ledger) :: ledger
            character(kind=c_char), dimension(*) :: err
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_outcome_ledger_get

        function ap_g02_mcc_step(engine, particles, count, capacity, required, background, &
                background_count, dt_s, global_step, seed, max_candidates, threads, backend, &
                report, err, err_size) bind(c, name="ap_g02_mcc_step") result(status)
            import :: c_ptr, c_size_t, c_double, c_int64_t, c_int32_t, c_int, c_char
            type(c_ptr), value :: engine, particles, background
            integer(c_size_t) :: count, required
            integer(c_size_t), value :: capacity, background_count
            real(c_double), value :: dt_s
            integer(c_int64_t), value :: global_step, seed
            integer(c_int32_t), value :: max_candidates
            integer(c_int), value :: threads, backend
            type(c_ptr) :: report
            character(kind=c_char) :: err(*)
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_step

        function ap_g02_mcc_session_create(engine, max_candidates, threads, backend, sampler, &
                session, err, err_size) bind(c, name="ap_g02_mcc_session_create") result(status)
            import :: c_ptr, c_int32_t, c_int, c_char, c_size_t
            type(c_ptr), value :: engine
            integer(c_int32_t), value :: max_candidates
            integer(c_int), value :: threads, backend, sampler
            type(c_ptr) :: session
            character(kind=c_char) :: err(*)
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_session_create

        function ap_g02_mcc_session_destroy(session) &
                bind(c, name="ap_g02_mcc_session_destroy") result(status)
            import :: c_ptr, c_int
            type(c_ptr), value :: session
            integer(c_int) :: status
        end function ap_g02_mcc_session_destroy

        function ap_g02_mcc_session_abort(session) &
                bind(c, name="ap_g02_mcc_session_abort") result(status)
            import :: c_ptr, c_int
            type(c_ptr), value :: session
            integer(c_int) :: status
        end function ap_g02_mcc_session_abort

        function ap_g02_mcc_session_step(session, particles, count, capacity, required, &
                background, background_count, dt_s, global_step, seed, report, err, err_size) &
                bind(c, name="ap_g02_mcc_session_step") result(status)
            import :: c_ptr, c_size_t, c_double, c_int64_t, c_int, c_char
            type(c_ptr), value :: session, particles, background
            integer(c_size_t) :: count, required
            integer(c_size_t), value :: capacity, background_count
            real(c_double), value :: dt_s
            integer(c_int64_t), value :: global_step, seed
            type(c_ptr) :: report
            character(kind=c_char) :: err(*)
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_session_step

        function ap_g02_mcc_session_resume(session, particles, count, capacity, required, &
                report, err, err_size) bind(c, name="ap_g02_mcc_session_resume") result(status)
            import :: c_ptr, c_size_t, c_int, c_char
            type(c_ptr), value :: session, particles
            integer(c_size_t) :: count, required
            integer(c_size_t), value :: capacity
            type(c_ptr) :: report
            character(kind=c_char) :: err(*)
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function ap_g02_mcc_session_resume

        function ap_g02_mcc_step_report_destroy(report) &
                bind(c, name="ap_g02_mcc_step_report_destroy") result(status)
            import :: c_ptr, c_int
            type(c_ptr), value :: report
            integer(c_int) :: status
        end function ap_g02_mcc_step_report_destroy

        function ap_g02_mcc_step_report_stats(report, stats) &
                bind(c, name="ap_g02_mcc_step_report_stats") result(status)
            import :: c_ptr, c_int, g02_mcc_step_stats
            type(c_ptr), value :: report
            type(g02_mcc_step_stats) :: stats
            integer(c_int) :: status
        end function ap_g02_mcc_step_report_stats

        function ap_g02_mcc_step_report_ledger(report, ledger) &
                bind(c, name="ap_g02_mcc_step_report_ledger") result(status)
            import :: c_ptr, c_int, g02_mcc_ledger
            type(c_ptr), value :: report
            type(g02_mcc_ledger) :: ledger
            integer(c_int) :: status
        end function ap_g02_mcc_step_report_ledger

        function ap_g02_mcc_step_report_reservoir_count(report, count) &
                bind(c, name="ap_g02_mcc_step_report_reservoir_count") result(status)
            import :: c_ptr, c_int, c_size_t
            type(c_ptr), value :: report
            integer(c_size_t) :: count
            integer(c_int) :: status
        end function ap_g02_mcc_step_report_reservoir_count

        function ap_g02_mcc_step_report_reservoir_get(report, index, delta) &
                bind(c, name="ap_g02_mcc_step_report_reservoir_get") result(status)
            import :: c_ptr, c_int, c_size_t, g02_mcc_cell_reservoir
            type(c_ptr), value :: report
            integer(c_size_t), value :: index
            type(g02_mcc_cell_reservoir) :: delta
            integer(c_int) :: status
        end function ap_g02_mcc_step_report_reservoir_get

        function ap_g02_mcc_step_report_reaction_count(report, count) &
                bind(c, name="ap_g02_mcc_step_report_reaction_count") result(status)
            import :: c_ptr, c_int, c_size_t
            type(c_ptr), value :: report
            integer(c_size_t) :: count
            integer(c_int) :: status
        end function ap_g02_mcc_step_report_reaction_count

        function ap_g02_mcc_step_report_reaction_get(report, index, reaction, count) &
                bind(c, name="ap_g02_mcc_step_report_reaction_get") result(status)
            import :: c_ptr, c_int, c_size_t, c_int32_t, c_int64_t
            type(c_ptr), value :: report
            integer(c_size_t), value :: index
            integer(c_int32_t) :: reaction
            integer(c_int64_t) :: count
            integer(c_int) :: status
        end function ap_g02_mcc_step_report_reaction_get
    end interface

contains

    ! === 4. 包装过程：字符串转换与按职责拆分的公开过程 ===
    ! 给输入文本补上 C 字符串终止符；最多复制 size(buffer)-1 个字符。
    ! 因此超长文本会截断，调用者应确保路径/名称能放入包装过程的缓冲区。
    subroutine sub_G02_mcc_fill_c_string(text, buffer)
        character(len=*), intent(in) :: text
        character(kind=c_char), dimension(:), intent(out), target :: buffer
        integer :: i
        integer :: length
        buffer = c_null_char
        length = min(len_trim(text), size(buffer) - 1)
        do i = 1, length
            buffer(i) = text(i:i)
        end do
    end subroutine sub_G02_mcc_fill_c_string

    ! 遇到 C 字符串终止符就停止；也用于把物种名称等普通文本复制回 Fortran。
    subroutine sub_G02_mcc_copy_error(buffer, message)
        character(kind=c_char), dimension(:), intent(in) :: buffer
        character(len=*), intent(out) :: message
        integer :: i
        message = ''
        do i = 1, min(size(buffer), len(message))
            if (buffer(i) == c_null_char) exit
            message(i:i) = buffer(i)
        end do
    end subroutine sub_G02_mcc_copy_error

    ! include 是编译时文本插入：下面各文件共享本模块的类型与私有 C 声明。
    ! 只编译本模块文件，不要把这些 include 文件再作为独立编译单元。
    ! Public G02 routines, grouped by their source files.
    include "fun_G02_mcc_api_version.f90"
    include "sub_G02_mcc_load.f90"
    include "sub_G02_mcc_model_queries.f90"
    include "sub_G02_mcc_collide.f90"
    include "sub_G02_mcc_session.f90"
    include "sub_G02_mcc_step.f90"
    include "sub_G02_mcc_cleanup.f90"

end module mod_G02_MCC_network
