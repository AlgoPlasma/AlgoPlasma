! SPDX-License-Identifier: Apache-2.0
! Included by mod_G02_MCC_network.f90; do not compile separately.

    ! 输入 package_dir 是包含 manifest.csv 等文件的模型目录。
    ! 成功后 context 同时持有模型和引擎；失败时 status 非零，并保留诊断文字。
    ! 重复 load 会先关闭旧 context；因此先关闭依赖旧模型的会话，再重新加载。
    subroutine sub_G02_mcc_load(context, package_dir, status)
        type(g02_mcc_context), intent(inout) :: context
        character(len=*), intent(in) :: package_dir
        integer(c_int), intent(out) :: status
        character(kind=c_char), dimension(1024), target :: cpath
        character(kind=c_char) :: errbuf(g02_mcc_error_length)
        type(c_ptr) :: engine
        integer(c_int) :: ignored_status

        call sub_G02_mcc_close(context)
        errbuf = c_null_char
        call sub_G02_mcc_fill_c_string(package_dir, cpath)
        status = ap_g02_mcc_model_load(cpath, context%model_handle, errbuf, &
                                       int(g02_mcc_error_length, c_size_t))
        call sub_G02_mcc_copy_error(errbuf, context%error_message)
        context%status = status
        if (status /= 0_c_int) return

        ! CSV 模型读入成功后，再创建执行碰撞所需的引擎。
        ! 只有两个步骤都成功，才能把 loaded 置为真。
        engine = c_null_ptr
        status = ap_g02_mcc_engine_create(context%model_handle, engine, errbuf, &
                                          int(g02_mcc_error_length, c_size_t))
        call sub_G02_mcc_copy_error(errbuf, context%error_message)
        context%status = status
        if (status /= 0_c_int) then
            ! Keep the engine_create failure status: destroying the model must not
            ! overwrite it with OK.
            ignored_status = ap_g02_mcc_model_destroy(context%model_handle)
            context%model_handle = c_null_ptr
            return
        end if
        context%engine_handle = engine
        context%loaded = .true.
    end subroutine sub_G02_mcc_load
