! SPDX-License-Identifier: Apache-2.0
! Included by mod_G02_MCC_network.f90; do not compile separately.

    ! 单粒子路径：输入 projectile（入射粒子）、背景和时间步 dt_s（秒）。
    ! 输出 outcome 与 status；输入粒子本身不被修改，宿主按 primary_action 应用结果。
    ! created 是新增粒子，reservoir 是背景增量，events/ledger 用于诊断。
    ! 使用完 outcome 必须调用 outcome_destroy；再次调用前也应先释放旧结果。
    ! global_step、seed 和粒子 id 一起确定随机序列，便于复现实验。
    subroutine sub_G02_mcc_collide(context, projectile, background, dt_s, global_step, seed, &
                               outcome, status, max_events_per_step)
        type(g02_mcc_context), intent(inout) :: context
        type(g02_mcc_particle), intent(in) :: projectile
        type(g02_mcc_background), intent(in), target :: background(:)
        real(c_double), intent(in) :: dt_s
        integer(c_int64_t), intent(in) :: global_step
        integer(c_int64_t), intent(in) :: seed
        type(g02_mcc_outcome), intent(out) :: outcome
        integer(c_int), intent(out) :: status
        integer(c_int32_t), intent(in), optional :: max_events_per_step
        character(kind=c_char) :: errbuf(g02_mcc_error_length)
        type(ap_g02_mcc_request) :: request
        type(c_ptr) :: handle
        integer(c_size_t) :: count
        integer(c_size_t) :: i
        integer(c_int) :: action
        integer(c_int16_t) :: destination
        integer(c_int32_t) :: candidates
        integer(c_int32_t) :: real_events
        integer(c_int32_t) :: null_events
        integer(c_int) :: limit_reached
        type(g02_mcc_created) :: created
        type(g02_mcc_reservoir) :: reservoir
        type(g02_mcc_event) :: event
        type(g02_mcc_ledger) :: ledger

        call sub_G02_mcc_outcome_destroy(outcome)
        errbuf = c_null_char
        request%projectile = projectile
        ! c_loc 取得数组首地址；空数组必须传空指针，不能访问 background(1)。
        ! background 的 target 属性允许取地址，C 层只在本次调用期间借用该数组。
        request%background_count = int(size(background), c_size_t)
        if (size(background) > 0) then
            request%background = c_loc(background(1))
        else
            request%background = c_null_ptr
        end if
        request%dt_s = dt_s
        request%global_step = global_step
        request%seed = seed
        request%max_events_per_step = 0_c_int32_t
        if (present(max_events_per_step)) request%max_events_per_step = max_events_per_step

        handle = c_null_ptr
        status = ap_g02_mcc_collide(context%engine_handle, request, handle, errbuf, &
                                    int(g02_mcc_error_length, c_size_t))
        call sub_G02_mcc_copy_error(errbuf, context%error_message)
        context%status = status
        if (status /= 0_c_int) return
        outcome%handle = handle

        status = ap_g02_mcc_outcome_primary(handle, outcome%primary, action, destination, &
                                            errbuf, int(g02_mcc_error_length, c_size_t))
        if (status /= 0_c_int) then
            call sub_G02_mcc_copy_error(errbuf, context%error_message)
            context%status = status
            call sub_G02_mcc_outcome_destroy(outcome)
            return
        end if
        outcome%primary_action = action
        outcome%primary_destination = destination

        status = ap_g02_mcc_outcome_counters(handle, candidates, real_events, null_events, &
                                             limit_reached, errbuf, &
                                             int(g02_mcc_error_length, c_size_t))
        if (status /= 0_c_int) then
            call sub_G02_mcc_copy_error(errbuf, context%error_message)
            context%status = status
            call sub_G02_mcc_outcome_destroy(outcome)
            return
        end if
        outcome%candidates = candidates
        outcome%real_events = real_events
        outcome%null_events = null_events
        outcome%event_limit_reached = (limit_reached /= 0_c_int)

        ! C 结果的数组长度由本次反应决定：先查询长度，再分配并逐项复制。
        ! Fortran 数组位置 i 从 1 起；传给 C getter 的位置因此是 i-1。
        if (allocated(outcome%created)) deallocate (outcome%created)
        status = ap_g02_mcc_outcome_created_count(handle, count, errbuf, &
                                                  int(g02_mcc_error_length, c_size_t))
        if (status /= 0_c_int) then
            call sub_G02_mcc_copy_error(errbuf, context%error_message)
            context%status = status
            call sub_G02_mcc_outcome_destroy(outcome)
            return
        end if
        if (count > 0_c_size_t) then
            allocate (outcome%created(count))
            do i = 1, count
                status = ap_g02_mcc_outcome_created_get(handle, i - 1_c_size_t, created, errbuf, &
                                                        int(g02_mcc_error_length, c_size_t))
                if (status /= 0_c_int) then
                    call sub_G02_mcc_copy_error(errbuf, context%error_message)
                    context%status = status
                    call sub_G02_mcc_outcome_destroy(outcome)
                    return
                end if
                outcome%created(i) = created
            end do
        end if

        if (allocated(outcome%reservoir)) deallocate (outcome%reservoir)
        status = ap_g02_mcc_outcome_reservoir_count(handle, count, errbuf, &
                                                    int(g02_mcc_error_length, c_size_t))
        if (status /= 0_c_int) then
            call sub_G02_mcc_copy_error(errbuf, context%error_message)
            context%status = status
            call sub_G02_mcc_outcome_destroy(outcome)
            return
        end if
        if (count > 0_c_size_t) then
            allocate (outcome%reservoir(count))
            do i = 1, count
                status = ap_g02_mcc_outcome_reservoir_get(handle, i - 1_c_size_t, reservoir, &
                                                          errbuf, &
                                                          int(g02_mcc_error_length, c_size_t))
                if (status /= 0_c_int) then
                    call sub_G02_mcc_copy_error(errbuf, context%error_message)
                    context%status = status
                    call sub_G02_mcc_outcome_destroy(outcome)
                    return
                end if
                outcome%reservoir(i) = reservoir
            end do
        end if

        if (allocated(outcome%events)) deallocate (outcome%events)
        status = ap_g02_mcc_outcome_event_count(handle, count, errbuf, &
                                                int(g02_mcc_error_length, c_size_t))
        if (status /= 0_c_int) then
            call sub_G02_mcc_copy_error(errbuf, context%error_message)
            context%status = status
            call sub_G02_mcc_outcome_destroy(outcome)
            return
        end if
        if (count > 0_c_size_t) then
            allocate (outcome%events(count))
            do i = 1, count
                status = ap_g02_mcc_outcome_event_get(handle, i - 1_c_size_t, event, errbuf, &
                                                      int(g02_mcc_error_length, c_size_t))
                if (status /= 0_c_int) then
                    call sub_G02_mcc_copy_error(errbuf, context%error_message)
                    context%status = status
                    call sub_G02_mcc_outcome_destroy(outcome)
                    return
                end if
                outcome%events(i) = event
            end do
        end if

        ! 最后取守恒账本；任何取数失败都释放 C 结果，避免留下半有效的输出。
        status = ap_g02_mcc_outcome_ledger_get(handle, ledger, errbuf, &
                                               int(g02_mcc_error_length, c_size_t))
        if (status /= 0_c_int) then
            call sub_G02_mcc_copy_error(errbuf, context%error_message)
            context%status = status
            call sub_G02_mcc_outcome_destroy(outcome)
            return
        end if
        outcome%ledger = ledger
    end subroutine sub_G02_mcc_collide
