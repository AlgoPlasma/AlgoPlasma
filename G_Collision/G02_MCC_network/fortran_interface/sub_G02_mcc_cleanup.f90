! SPDX-License-Identifier: Apache-2.0
! Included by mod_G02_MCC_network.f90; do not compile separately.

    ! 把 C 报告复制到 Fortran report；输入 handle，输出 report 和 status。
    ! 本过程不销毁 handle，调用它的 step 过程负责在复制后释放 C 报告。
    ! C getter 使用零基索引，Fortran 数组使用一基索引；失败时停止继续取数。
    subroutine sub_G02_mcc_report_collect(handle, report, status)
        type(c_ptr), intent(in) :: handle
        type(g02_mcc_step_report), intent(out) :: report
        integer(c_int), intent(out) :: status
        integer(c_size_t) :: nitems, i
        integer(c_int) :: allocation_status

        status = ap_g02_mcc_step_report_stats(handle, report%stats)
        if (status == 0_c_int) status = ap_g02_mcc_step_report_ledger(handle, report%ledger)
        if (status == 0_c_int) then
            status = ap_g02_mcc_step_report_reservoir_count(handle, nitems)
            if (status == 0_c_int) then
                allocate (report%reservoir(nitems), stat=allocation_status)
                if (allocation_status /= 0) status = 8_c_int
            end if
            if (status == 0_c_int) then
                do i = 1, nitems
                    status = ap_g02_mcc_step_report_reservoir_get(handle, i - 1_c_size_t, &
                                                                   report%reservoir(i))
                    if (status /= 0_c_int) exit
                end do
            end if
        end if
        if (status == 0_c_int) then
            status = ap_g02_mcc_step_report_reaction_count(handle, nitems)
            if (status == 0_c_int) then
                allocate (report%reaction_id(nitems), report%reaction_count(nitems), &
                          stat=allocation_status)
                if (allocation_status /= 0) status = 8_c_int
            end if
            if (status == 0_c_int) then
                do i = 1, nitems
                    status = ap_g02_mcc_step_report_reaction_get(handle, i - 1_c_size_t, &
                        report%reaction_id(i), report%reaction_count(i))
                    if (status /= 0_c_int) exit
                end do
            end if
        end if
    end subroutine sub_G02_mcc_report_collect

    ! 释放单粒子结果的 C 句柄和 Fortran 数组，并恢复空结果。
    ! 清空句柄后再次调用是安全的；不要对复制了同一 C 句柄的两个对象各释放一次。
    subroutine sub_G02_mcc_outcome_destroy(outcome)
        type(g02_mcc_outcome), intent(inout) :: outcome
        integer(c_int) :: status
        if (c_associated(outcome%handle)) then
            status = ap_g02_mcc_outcome_destroy(outcome%handle)
            outcome%handle = c_null_ptr
        end if
        if (allocated(outcome%created)) deallocate (outcome%created)
        if (allocated(outcome%reservoir)) deallocate (outcome%reservoir)
        if (allocated(outcome%events)) deallocate (outcome%events)
        outcome%primary_action = G02_MCC_ACTION_NONE
        outcome%primary = g02_mcc_particle()
        outcome%primary_destination = 0
        outcome%candidates = 0
        outcome%real_events = 0
        outcome%null_events = 0
        outcome%event_limit_reached = .false.
        outcome%ledger = g02_mcc_ledger()
    end subroutine sub_G02_mcc_outcome_destroy

    ! 关闭上下文：先释放引擎，再释放模型，最后重置状态。
    ! 调用前由宿主关闭关联会话；本过程不会替宿主遍历并关闭其他对象。
    subroutine sub_G02_mcc_close(context)
        type(g02_mcc_context), intent(inout) :: context
        integer(c_int) :: status
        if (c_associated(context%engine_handle)) then
            status = ap_g02_mcc_engine_destroy(context%engine_handle)
            context%engine_handle = c_null_ptr
        end if
        if (c_associated(context%model_handle)) then
            status = ap_g02_mcc_model_destroy(context%model_handle)
            context%model_handle = c_null_ptr
        end if
        context%loaded = .false.
        context%status = 0_c_int
        context%error_message = ''
    end subroutine sub_G02_mcc_close
