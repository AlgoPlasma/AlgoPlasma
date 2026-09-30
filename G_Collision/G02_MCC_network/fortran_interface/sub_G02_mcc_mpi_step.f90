! SPDX-License-Identifier: Apache-2.0
! Included by mod_G02_MCC_network_mpi.f90; do not compile separately.

    ! 集体步进：particles/background 是本进程数据，report 是本进程报告。
    ! 所有进程均须调用，包括 particles 大小为 0 的进程；数组仍须已分配。
    ! 核心协调新粒子 ID，宿主负责已有 ID 的全局唯一性及粒子跨网格迁移。
    ! status 非零时不要使用 report；本包装层只在所有进程都成功后替换 particles。
    subroutine sub_G02_mcc_mpi_step(context, session, particles, background, dt_s, &
                                 global_step, seed, report, status)
        type(g02_mcc_context), intent(inout) :: context
        type(g02_mcc_mpi_session), intent(inout) :: session
        type(g02_mcc_particle), allocatable, target, intent(inout) :: particles(:)
        type(g02_mcc_cell_background), target, intent(in) :: background(:)
        real(c_double), intent(in) :: dt_s
        integer(c_int64_t), intent(in) :: global_step, seed
        type(g02_mcc_step_report), intent(out) :: report
        integer(c_int), intent(out) :: status
        type(g02_mcc_particle), allocatable, target :: work(:), finished(:)
        type(c_ptr) :: background_ptr, handle
        character(kind=c_char) :: errbuf(error_length)
        integer(c_size_t) :: old_count, count, capacity, required
        integer :: local_invalid, any_invalid, local_failure, any_failure, ierr
        integer(c_int) :: ignored

        if (session%communicator == MPI_COMM_NULL) then
            status = 1_c_int
            context%status = status
            context%error_message = 'MPI MCC session is not initialized'
            return
        end if
        local_invalid = 0
        if (.not. context%loaded .or. .not. allocated(particles) .or. &
            global_step < 0_c_int64_t) local_invalid = 1
        if (.not. c_associated(session%handle)) local_invalid = 1
        call MPI_Allreduce(local_invalid, any_invalid, 1, MPI_INTEGER, MPI_MAX, &
                           session%communicator, ierr)
        if (any_invalid /= 0) then
            status = 1_c_int
            context%status = status
            context%error_message = 'invalid MPI MCC step input on a rank'
            return
        end if
        old_count = size(particles, kind=c_size_t)
        capacity = max(1_c_size_t, old_count + max(16_c_size_t, old_count / 8_c_size_t))
        background_ptr = c_null_ptr
        if (size(background) > 0) background_ptr = c_loc(background(1))
        ! 每轮先在工作数组上计算；分配失败也必须汇总后一起退出。
        ! 不能在某个进程的错误分支里独自跳过后续集体通信。
        do
            allocate (work(capacity), stat=local_failure)
            local_invalid = 0
            if (local_failure /= 0) local_invalid = 1
            call MPI_Allreduce(local_invalid, any_invalid, 1, MPI_INTEGER, MPI_MAX, &
                               session%communicator, ierr)
            if (any_invalid /= 0) then
                status = 8_c_int
                context%error_message = 'cannot allocate MPI particle workspace on a rank'
                exit
            end if
            if (old_count > 0_c_size_t) work(1:old_count) = particles
            count = old_count
            required = old_count
            handle = c_null_ptr
            errbuf = c_null_char
            status = c_mpi_step(session%handle, c_loc(work(1)), count, capacity, required, &
                background_ptr, size(background, kind=c_size_t), dt_s, global_step, seed, &
                handle, errbuf, int(error_length, c_size_t))
            ! 某进程容量不足时所有进程都返回 7，并一起重试这一时间步。
            ! 只有不足的进程扩容；其他进程也必须 cycle，不能独自提交。
            ! seed/global_step/粒子身份保持不变，使重新抽样可重复。
            if (status == 7_c_int) then
                if (required > capacity) capacity = required
                deallocate (work)
                cycle
            end if
            if (status /= 0_c_int) then
                call sub_G02_mcc_copy_error(errbuf, context%error_message)
                exit
            end if
            call sub_G02_mcc_report_collect(handle, report, status)
            if (status == 0_c_int) then
                allocate (finished(count), stat=local_failure)
                if (local_failure /= 0) status = 8_c_int
                if (status == 0_c_int .and. count > 0_c_size_t) finished = work(1:count)
            end if
            ignored = c_report_destroy(handle)
            ! 取报告或最终数组分配也可能失败；再次汇总后统一决定是否替换宿主数组。
            local_failure = int(status)
            call MPI_Allreduce(local_failure, any_failure, 1, MPI_INTEGER, MPI_MAX, &
                               session%communicator, ierr)
            status = int(any_failure, c_int)
            if (status == 0_c_int) then
                call move_alloc(finished, particles)
                context%error_message = ''
            else
                context%error_message = 'cannot collect MPI MCC step result on a rank'
            end if
            exit
        end do
        if (allocated(work)) deallocate (work)
        context%status = status
    end subroutine sub_G02_mcc_mpi_step
