! SPDX-License-Identifier: Apache-2.0
! MPI 包装层：每个进程持有本地粒子，通信器内所有进程共同推进同一时间步。
! 阅读顺序：会话类型 -> C ABI 声明 -> mpi_session -> mpi_step。
! 宿主负责 MPI_Init_thread（至少 MPI_THREAD_FUNNELED）、粒子分区和迁移。
! 即使本地没有粒子，也必须参加集体调用；所有进程按相同顺序进入这些过程。
! 先集体关闭会话，再 MPI_Finalize；这里只编译本文件，不单独编译 include 文件。
module mod_G02_MCC_network_mpi
    use, intrinsic :: iso_c_binding
    use mpi
    use mod_G02_MCC_network
    implicit none
    private

    public :: g02_mcc_mpi_session, sub_G02_mcc_mpi_session_init
    public :: sub_G02_mcc_mpi_session_close, sub_G02_mcc_mpi_step

    integer, parameter :: error_length = 512

    ! handle 指向 C++ 并行工作区；communicator 保存供本包装层一致性检查使用的通信器。
    ! 核心内部复制通信器，但这里仍使用传入的通信器，宿主应在关闭会话前保持它有效。
    type :: g02_mcc_mpi_session
        type(c_ptr) :: handle = c_null_ptr
        integer :: communicator = MPI_COMM_NULL
    end type g02_mcc_mpi_session

    ! C ABI 是 Fortran 与 C++ 之间的桥：value 按值传参，其余输出由 C 写回。
    ! create_f 接受 Fortran 整数通信器，由 C 层转换为 C MPI_Comm。
    interface
        function c_mpi_create(engine, communicator, max_candidates, threads, backend, sampler, &
            session, err, err_size) bind(c, name="ap_g02_mcc_mpi_session_create_f") result(status)
            import :: c_ptr, c_int, c_int32_t, c_char, c_size_t
            type(c_ptr), value :: engine
            integer(c_int), value :: communicator, max_candidates, threads, backend, sampler
            type(c_ptr) :: session
            character(kind=c_char) :: err(*)
            integer(c_size_t), value :: err_size
            integer(c_int) :: status
        end function c_mpi_create

        function c_mpi_destroy(session) bind(c, name="ap_g02_mcc_mpi_session_destroy") result(status)
            import :: c_ptr, c_int
            type(c_ptr), value :: session
            integer(c_int) :: status
        end function c_mpi_destroy

        function c_mpi_step(session, particles, count, capacity, required, background, &
            background_count, dt_s, global_step, seed, report, err, err_size) &
            bind(c, name="ap_g02_mcc_mpi_session_step") result(status)
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
        end function c_mpi_step

        function c_report_destroy(report) bind(c, name="ap_g02_mcc_step_report_destroy") &
            result(status)
            import :: c_ptr, c_int
            type(c_ptr), value :: report
            integer(c_int) :: status
        end function c_report_destroy
    end interface

contains

    subroutine sub_G02_mcc_copy_error(buffer, message)
        character(kind=c_char), intent(in) :: buffer(:)
        character(len=*), intent(out) :: message
        integer :: i
        message = ''
        do i = 1, min(size(buffer), len(message))
            if (buffer(i) == c_null_char) exit
            message(i:i) = buffer(i)
        end do
    end subroutine sub_G02_mcc_copy_error

    ! Public G02 routines, grouped by their source files.
    include "sub_G02_mcc_mpi_session.f90"
    include "sub_G02_mcc_mpi_step.f90"

end module mod_G02_MCC_network_mpi
