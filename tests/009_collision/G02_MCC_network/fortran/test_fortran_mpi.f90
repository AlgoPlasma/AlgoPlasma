! SPDX-License-Identifier: Apache-2.0
program test_fortran_mpi
    use, intrinsic :: iso_c_binding
    use mpi
    use mod_G02_MCC_network
    use mod_G02_MCC_network_mpi
    implicit none

    type(g02_mcc_context) :: context
    type(g02_mcc_mpi_session) :: session
    type(g02_mcc_particle), allocatable :: local(:), reference(:)
    type(g02_mcc_cell_background) :: gas(3)
    type(g02_mcc_step_report) :: report, serial_report
    integer(c_int16_t) :: electron, ground
    integer(c_int) :: status
    integer :: ierr, provided, rank, ranks, i, j, local_total, global_total
    real(c_double) :: speed
    character(len=2048) :: package_dir
    character(len=3), parameter :: names(3) = [character(len=3) :: 'M', 'M2', 'M2+']

    call MPI_Init_thread(MPI_THREAD_FUNNELED, provided, ierr)
    call check(provided >= MPI_THREAD_FUNNELED, 'MPI thread level')
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, ranks, ierr)
    call get_command_argument(1, package_dir)
    call check(len_trim(package_dir) > 0, 'model path')
    call sub_G02_mcc_load(context, trim(package_dir), status)
    call check(status == 0_c_int, 'load model')
    call sub_G02_mcc_species_id(context, 'e-', electron, status)
    call check(status == 0_c_int, 'electron ID')
    call sub_G02_mcc_state_id(context, electron, 'ground', ground, status)
    call check(status == 0_c_int, 'electron state')
    do i = 1, 3
        call sub_G02_mcc_species_id(context, trim(names(i)), gas(i)%species, status)
        call check(status == 0_c_int, 'background species')
        call sub_G02_mcc_state_id(context, gas(i)%species, 'ground', gas(i)%state, status)
        call check(status == 0_c_int, 'background state')
        gas(i)%cell = -1_c_int32_t
        gas(i)%density_m3 = 0.0_c_double
        gas(i)%temperature_k = 300.0_c_double
    end do
    gas(1)%density_m3 = 2.0e20_c_double
    speed = sqrt(2.0_c_double * 40.0_c_double * 1.602176634e-19_c_double / &
                 9.1093837139e-31_c_double)
    allocate (reference(256))
    allocate (local((256 + ranks - 1 - rank) / ranks))
    j = 0
    do i = 1, 256
        reference(i)%species = electron
        reference(i)%state = ground
        reference(i)%weight = 1.0_c_double
        reference(i)%id = int(i, c_int64_t)
        reference(i)%velocity(1) = speed
        if (mod(i - 1, ranks) == rank) then
            j = j + 1
            local(j) = reference(i)
        end if
    end do
    call check(j == size(local), 'local partition')
    call sub_G02_mcc_mpi_session_init(context, MPI_COMM_WORLD, session, status, &
                                  backend=G02_MCC_BACKEND_SERIAL)
    call check(status == 0_c_int, 'MPI session init')
    call sub_G02_mcc_mpi_step(context, session, local, gas, 1.0e-7_c_double, &
                          1_c_int64_t, 157_c_int64_t, report, status)
    if (status /= 0_c_int) print *, trim(context%error_message)
    call check(status == 0_c_int, 'MPI step')
    call sub_G02_mcc_step(context, reference, gas, 1.0e-7_c_double, 1_c_int64_t, &
                      157_c_int64_t, serial_report, status, backend=G02_MCC_BACKEND_SERIAL)
    call check(status == 0_c_int, 'serial reference')
    local_total = size(local)
    call MPI_Allreduce(local_total, global_total, 1, MPI_INTEGER, MPI_SUM, MPI_COMM_WORLD, ierr)
    call check(global_total == size(reference), 'global particle count')
    do i = 1, size(local)
        do j = 1, size(reference)
            if (local(i)%id == reference(j)%id) exit
        end do
        call check(j <= size(reference), 'particle ID')
        call check(local(i)%species == reference(j)%species, 'particle species')
        call check(all(abs(local(i)%velocity - reference(j)%velocity) <= &
                       tiny(1.0_c_double)), 'particle velocity')
    end do
    call sub_G02_mcc_mpi_session_close(session)
    call sub_G02_mcc_close(context)
    call MPI_Finalize(ierr)

contains

    subroutine check(condition, message)
        logical, intent(in) :: condition
        character(len=*), intent(in) :: message
        if (condition) return
        print *, 'rank', rank, ': ', message
        call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
    end subroutine check

end program test_fortran_mpi
