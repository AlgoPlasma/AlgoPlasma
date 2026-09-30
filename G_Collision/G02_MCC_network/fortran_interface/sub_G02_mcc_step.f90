! SPDX-License-Identifier: Apache-2.0
! Included by mod_G02_MCC_network.f90; do not compile separately.

    ! 批量路径：输入一组粒子、按网格给出的背景及 dt_s（秒）。
    ! 成功后 particles 被碰后粒子数组替换，report 返回统计和守恒账本。
    ! particles 必须已分配；零粒子情形可 allocate(particles(0))。
    ! session 可选：提供后复用缓存，执行选项应在 session_init 时设置。
    subroutine sub_G02_mcc_step(context, particles, background, dt_s, global_step, seed, &
                            report, status, max_candidates, threads, backend, session)
        type(g02_mcc_context), intent(inout) :: context
        type(g02_mcc_particle), allocatable, target, intent(inout) :: particles(:)
        type(g02_mcc_cell_background), target, intent(in) :: background(:)
        real(c_double), intent(in) :: dt_s
        integer(c_int64_t), intent(in) :: global_step, seed
        type(g02_mcc_step_report), intent(out) :: report
        integer(c_int), intent(out) :: status
        integer(c_int32_t), optional, intent(in) :: max_candidates
        integer(c_int), optional, intent(in) :: threads, backend
        type(g02_mcc_session), optional, intent(inout) :: session
        type(g02_mcc_particle), allocatable, target :: work(:), finished(:)
        character(kind=c_char) :: errbuf(g02_mcc_error_length)
        type(c_ptr) :: background_ptr, handle
        integer(c_size_t) :: old_count, count, capacity, required
        integer(c_int32_t) :: event_cap
        integer(c_int) :: thread_count, backend_id, ignored, allocation_status
        logical :: resume_pending

        status = 1_c_int
        context%status = status
        context%error_message = ''
        if (.not. context%loaded .or. .not. allocated(particles)) then
            context%error_message = 'context is not loaded or particles are not allocated'
            return
        end if
        if (present(session)) then
            if (.not. c_associated(session%handle) .or. present(max_candidates) .or. &
                present(threads) .or. present(backend)) then
                context%error_message = 'session must be initialized; set options in session_init'
                return
            end if
        end if
        ! count 是有效粒子数，capacity 是存储空间；生成新粒子会使 count 增大。
        ! 先留少量余量。至少分配一个元素，保证 c_loc(work(1)) 总是有效。
        old_count = size(particles, kind=c_size_t)
        capacity = max(1_c_size_t, old_count + max(16_c_size_t, old_count / 8_c_size_t))
        event_cap = 0_c_int32_t
        if (present(max_candidates)) event_cap = max_candidates
        thread_count = 0_c_int
        if (present(threads)) thread_count = threads
        backend_id = G02_MCC_BACKEND_AUTO
        if (present(backend)) backend_id = backend
        if (global_step < 0_c_int64_t .or. event_cap < 0_c_int32_t .or. thread_count < 0_c_int) then
            context%error_message = 'global_step, max_candidates and threads must be non-negative'
            return
        end if
        background_ptr = c_null_ptr
        if (size(background) > 0) background_ptr = c_loc(background(1))
        resume_pending = .false.

        ! 在 work 中计算，直到收集结果成功才替换宿主的 particles。
        ! 自动数组空间不足与物理错误分开处理：前者扩容后重试，后者退出。
        do
            allocate (work(capacity), stat=allocation_status)
            if (allocation_status /= 0) then
                status = 8_c_int
                context%error_message = 'cannot allocate particle batch workspace'
                exit
            end if
            if (old_count > 0_c_size_t) work(1:old_count) = particles
            count = old_count
            required = old_count
            errbuf = c_null_char
            handle = c_null_ptr
            if (present(session)) then
                if (resume_pending) then
                    status = ap_g02_mcc_session_resume(session%handle, c_loc(work(1)), &
                        count, capacity, required, handle, errbuf, &
                        int(g02_mcc_error_length, c_size_t))
                else
                    status = ap_g02_mcc_session_step(session%handle, c_loc(work(1)), &
                        count, capacity, required, background_ptr, &
                        size(background, kind=c_size_t), dt_s, global_step, seed, &
                        handle, errbuf, int(g02_mcc_error_length, c_size_t))
                end if
            else
                status = ap_g02_mcc_step(context%engine_handle, c_loc(work(1)), count, capacity, &
                                         required, background_ptr, size(background, kind=c_size_t), &
                                         dt_s, global_step, seed, event_cap, thread_count, backend_id, &
                                         handle, errbuf, int(g02_mcc_error_length, c_size_t))
            end if
            ! 7 = BUFFER_TOO_SMALL：required 告诉我们所需容量。
            ! 有 session 时 resume 提交已准备的结果；无 session 时重新进行确定性计算。
            if (status == 7_c_int .and. required > capacity) then
                deallocate (work)
                capacity = required
                resume_pending = .true.
                cycle
            end if
            if (status /= 0_c_int) then
                call sub_G02_mcc_copy_error(errbuf, context%error_message)
                exit
            end if

            call sub_G02_mcc_report_collect(handle, report, status)
            if (status == 0_c_int) then
                allocate (finished(count), stat=allocation_status)
                if (allocation_status /= 0) status = 8_c_int
                if (status == 0_c_int .and. count > 0_c_size_t) finished = work(1:count)
            end if
            ignored = ap_g02_mcc_step_report_destroy(handle)
            if (status == 0_c_int) then
                ! move_alloc 转移数组所有权，避免再复制整组粒子。
                call move_alloc(finished, particles)
                context%error_message = ''
            else
                context%error_message = 'cannot collect the batch step result'
            end if
            exit
        end do
        if (allocated(work)) deallocate (work)
        ! 失败后丢弃会话中待提交的结果，防止下一时间步误用上一步的暂存数据。
        if (status /= 0_c_int .and. present(session)) then
            ignored = ap_g02_mcc_session_abort(session%handle)
        end if
        context%status = status
    end subroutine sub_G02_mcc_step
