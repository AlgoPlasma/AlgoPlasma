! SPDX-License-Identifier: Apache-2.0
! Included by mod_G02_MCC_network.f90; do not compile separately.

    ! 本文件只查询模型，不修改反应数据，也不执行碰撞。
    ! *_id 按名称查询；*_count 返回条目数；*_get 按位置枚举条目。
    ! 注意 *_get 的 index 沿用 C 约定：0 到 count-1，不是 1 到 count。
    ! 返回的 ID 是模型标识，与枚举位置是不同概念；先检查 status 再使用输出。
    ! count/get 只更新 context%status，不刷新 error_message。

    ! 输入物种名称（如 CSV 中的名字），输出后续碰撞参数所需的 species_id。
    subroutine sub_G02_mcc_species_id(context, name, species_id, status)
        type(g02_mcc_context), intent(inout) :: context
        character(len=*), intent(in) :: name
        integer(c_int16_t), intent(out) :: species_id
        integer(c_int), intent(out) :: status
        character(kind=c_char), dimension(256), target :: cname
        character(kind=c_char) :: errbuf(g02_mcc_error_length)
        integer(c_int16_t) :: value

        value = 0_c_int16_t
        errbuf = c_null_char
        call sub_G02_mcc_fill_c_string(name, cname)
        status = ap_g02_mcc_model_species_id(context%model_handle, cname, value, errbuf, &
                                             int(g02_mcc_error_length, c_size_t))
        call sub_G02_mcc_copy_error(errbuf, context%error_message)
        context%status = status
        species_id = value
    end subroutine sub_G02_mcc_species_id

    ! 输入物种 ID 和能级标签，输出该物种的能级 ID；不要猜测基态一定是 0。
    subroutine sub_G02_mcc_state_id(context, species, label, state_id, status)
        type(g02_mcc_context), intent(inout) :: context
        integer(c_int16_t), intent(in) :: species
        character(len=*), intent(in) :: label
        integer(c_int16_t), intent(out) :: state_id
        integer(c_int), intent(out) :: status
        character(kind=c_char), dimension(256), target :: clabel
        character(kind=c_char) :: errbuf(g02_mcc_error_length)
        integer(c_int16_t) :: value

        value = 0_c_int16_t
        errbuf = c_null_char
        call sub_G02_mcc_fill_c_string(label, clabel)
        status = ap_g02_mcc_model_state_id(context%model_handle, species, clabel, value, &
                                           errbuf, int(g02_mcc_error_length, c_size_t))
        call sub_G02_mcc_copy_error(errbuf, context%error_message)
        context%status = status
        state_id = value
    end subroutine sub_G02_mcc_state_id

    ! 输出模型的物种总数，count 使用与 C size_t 对应的 c_size_t。
    subroutine sub_G02_mcc_species_count(context, count, status)
        type(g02_mcc_context), intent(inout) :: context
        integer(c_size_t), intent(out) :: count
        integer(c_int), intent(out) :: status
        count = 0_c_size_t
        status = ap_g02_mcc_model_species_count(context%model_handle, count)
        context%status = status
    end subroutine sub_G02_mcc_species_count

    ! 按零基 index 输出物种 ID、名字、质量 kg、电荷数和表示方式。
    ! representation=0 为显式粒子，1 为背景；name 长度不足会返回非零状态。
    subroutine sub_G02_mcc_species_get(context, index, id, name, mass_kg, charge, representation, status)
        type(g02_mcc_context), intent(inout) :: context
        integer(c_size_t), intent(in) :: index
        integer(c_int16_t), intent(out) :: id
        character(len=*), intent(out) :: name
        real(c_double), intent(out) :: mass_kg
        integer(c_int), intent(out) :: charge, representation, status
        character(kind=c_char), allocatable :: raw(:)
        allocate (raw(len(name) + 1))
        raw = c_null_char
        status = ap_g02_mcc_model_species_get(context%model_handle, index, id, raw, &
            size(raw, kind=c_size_t), mass_kg, charge, representation)
        name = ''
        if (status == 0_c_int) call sub_G02_mcc_copy_error(raw, name)
        context%status = status
    end subroutine sub_G02_mcc_species_get

    ! 输出全部物种的能级条目总数。
    subroutine sub_G02_mcc_state_count(context, count, status)
        type(g02_mcc_context), intent(inout) :: context
        integer(c_size_t), intent(out) :: count
        integer(c_int), intent(out) :: status
        count = 0_c_size_t
        status = ap_g02_mcc_model_state_count(context%model_handle, count)
        context%status = status
    end subroutine sub_G02_mcc_state_count

    ! 按零基 index 输出能级 ID、所属物种、标签和内部能量 eV。
    subroutine sub_G02_mcc_state_get(context, index, id, species, label, energy_ev, status)
        type(g02_mcc_context), intent(inout) :: context
        integer(c_size_t), intent(in) :: index
        integer(c_int16_t), intent(out) :: id, species
        character(len=*), intent(out) :: label
        real(c_double), intent(out) :: energy_ev
        integer(c_int), intent(out) :: status
        character(kind=c_char), allocatable :: raw(:)
        allocate (raw(len(label) + 1))
        raw = c_null_char
        status = ap_g02_mcc_model_state_get(context%model_handle, index, id, species, &
            raw, size(raw, kind=c_size_t), energy_ev)
        label = ''
        if (status == 0_c_int) call sub_G02_mcc_copy_error(raw, label)
        context%status = status
    end subroutine sub_G02_mcc_state_get

    ! 输出反应通道数，用来确定 reaction_get 的枚举范围。
    subroutine sub_G02_mcc_reaction_count(context, count, status)
        type(g02_mcc_context), intent(inout) :: context
        integer(c_size_t), intent(out) :: count
        integer(c_int), intent(out) :: status
        count = 0_c_size_t
        status = ap_g02_mcc_model_reaction_count(context%model_handle, count)
        context%status = status
    end subroutine sub_G02_mcc_reaction_count

    ! 按零基 index 输出反应 ID 与反应名，供统计结果与模型条目对应。
    subroutine sub_G02_mcc_reaction_get(context, index, id, name, status)
        type(g02_mcc_context), intent(inout) :: context
        integer(c_size_t), intent(in) :: index
        integer(c_int32_t), intent(out) :: id
        character(len=*), intent(out) :: name
        integer(c_int), intent(out) :: status
        character(kind=c_char), allocatable :: raw(:)
        allocate (raw(len(name) + 1))
        raw = c_null_char
        status = ap_g02_mcc_model_reaction_get(context%model_handle, index, id, raw, &
            size(raw, kind=c_size_t))
        name = ''
        if (status == 0_c_int) call sub_G02_mcc_copy_error(raw, name)
        context%status = status
    end subroutine sub_G02_mcc_reaction_get
