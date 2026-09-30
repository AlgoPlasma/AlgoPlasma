! SPDX-License-Identifier: Apache-2.0
! Included by mod_G02_MCC_network.f90; do not compile separately.

    ! 创建可跨时间步复用的工作区，避免每步重复分配缓存。
    ! 输入已加载 context；输出 session 句柄和 status；使用后调用 session_close。
    ! max_candidates=0 使用 C 层默认上限，threads=0 使用运行时默认线程数。
    ! backend 选择串行/OpenMP，sampler 选择前缀和/别名采样；两者都不改变物理模型。
    subroutine sub_G02_mcc_session_init(context, session, status, max_candidates, threads, backend, sampler)
        type(g02_mcc_context), intent(inout) :: context
        type(g02_mcc_session), intent(inout) :: session
        integer(c_int), intent(out) :: status
        integer(c_int32_t), optional, intent(in) :: max_candidates
        integer(c_int), optional, intent(in) :: threads, backend, sampler
        integer(c_int32_t) :: event_cap
        integer(c_int) :: thread_count, backend_id, sampler_id
        character(kind=c_char) :: errbuf(g02_mcc_error_length)

        call sub_G02_mcc_session_close(session)
        status = 1_c_int
        context%status = status
        context%error_message = ''
        if (.not. context%loaded) then
            context%error_message = 'context is not loaded'
            return
        end if
        event_cap = 0_c_int32_t
        if (present(max_candidates)) event_cap = max_candidates
        thread_count = 0_c_int
        if (present(threads)) thread_count = threads
        backend_id = G02_MCC_BACKEND_AUTO
        if (present(backend)) backend_id = backend
        sampler_id = G02_MCC_SAMPLER_PREFIX
        if (present(sampler)) sampler_id = sampler
        if (event_cap < 0_c_int32_t .or. thread_count < 0_c_int) then
            context%error_message = 'max_candidates and threads must be non-negative'
            return
        end if
        errbuf = c_null_char
        status = ap_g02_mcc_session_create(context%engine_handle, event_cap, thread_count, &
            backend_id, sampler_id, session%handle, errbuf, int(g02_mcc_error_length, c_size_t))
        call sub_G02_mcc_copy_error(errbuf, context%error_message)
        context%status = status
    end subroutine sub_G02_mcc_session_init

    ! 释放 C 侧会话并清空句柄；先关闭会话，再关闭其来源 context。
    subroutine sub_G02_mcc_session_close(session)
        type(g02_mcc_session), intent(inout) :: session
        integer(c_int) :: ignored
        if (c_associated(session%handle)) then
            ignored = ap_g02_mcc_session_destroy(session%handle)
            session%handle = c_null_ptr
        end if
    end subroutine sub_G02_mcc_session_close
