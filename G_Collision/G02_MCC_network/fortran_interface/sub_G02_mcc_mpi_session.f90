! SPDX-License-Identifier: Apache-2.0
! Included by mod_G02_MCC_network_mpi.f90; do not compile separately.

    ! 集体创建：每个进程输入已加载 context 和同一通信组的 communicator。
    ! 输出本地 session 与 status；模型、dt/step/seed 等运行约定应由宿主保持一致。
    ! max_candidates/threads 的 0 表示使用默认设置，不能解释为禁止碰撞/不启动线程。
    subroutine sub_G02_mcc_mpi_session_init(context, communicator, session, status, &
                                        max_candidates, threads, backend, sampler)
        type(g02_mcc_context), intent(inout) :: context
        integer, intent(in) :: communicator
        type(g02_mcc_mpi_session), intent(inout) :: session
        integer(c_int), intent(out) :: status
        integer(c_int32_t), optional, intent(in) :: max_candidates
        integer(c_int), optional, intent(in) :: threads, backend, sampler
        integer(c_int32_t) :: event_cap
        integer(c_int) :: thread_count, backend_id, sampler_id
        integer :: local_invalid, any_invalid, ierr
        character(kind=c_char) :: errbuf(error_length)

        call sub_G02_mcc_mpi_session_close(session)
        event_cap = 0_c_int32_t
        if (present(max_candidates)) event_cap = max_candidates
        thread_count = 0_c_int
        if (present(threads)) thread_count = threads
        backend_id = G02_MCC_BACKEND_AUTO
        if (present(backend)) backend_id = backend
        sampler_id = G02_MCC_SAMPLER_PREFIX
        if (present(sampler)) sampler_id = sampler
        if (communicator == MPI_COMM_NULL) then
            status = 1_c_int
            context%status = status
            context%error_message = 'MPI communicator is null'
            return
        end if
        local_invalid = 0
        if (.not. context%loaded .or. event_cap < 0_c_int32_t .or. thread_count < 0_c_int) &
            local_invalid = 1
        if (storage_size(communicator) /= storage_size(0_c_int)) local_invalid = 1
        ! MPI_MAX 汇总 0/1 错误标记：任一进程输入无效，所有进程一起返回。
        ! 否则一部分进程提前退出、一部分继续通信，就可能一直等待。
        call MPI_Allreduce(local_invalid, any_invalid, 1, MPI_INTEGER, MPI_MAX, communicator, ierr)
        if (any_invalid /= 0) then
            status = 1_c_int
            context%status = status
            context%error_message = 'invalid MPI MCC context or session options on a rank'
            return
        end if
        errbuf = c_null_char
        status = c_mpi_create(context%engine_handle, int(communicator, c_int), event_cap, &
            thread_count, backend_id, sampler_id, session%handle, errbuf, &
            int(error_length, c_size_t))
        call sub_G02_mcc_copy_error(errbuf, context%error_message)
        context%status = status
        if (status == 0_c_int) session%communicator = communicator
    end subroutine sub_G02_mcc_mpi_session_init

    ! 在 MPI_Finalize 之前由会话所属各进程配对调用，释放内部通信器与工作区。
    ! 不负责释放宿主传入的原通信器，也不结束 MPI 环境。
    subroutine sub_G02_mcc_mpi_session_close(session)
        type(g02_mcc_mpi_session), intent(inout) :: session
        integer(c_int) :: ignored
        if (c_associated(session%handle)) then
            ignored = c_mpi_destroy(session%handle)
            session%handle = c_null_ptr
        end if
        session%communicator = MPI_COMM_NULL
    end subroutine sub_G02_mcc_mpi_session_close
