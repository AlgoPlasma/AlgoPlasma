! SPDX-License-Identifier: Apache-2.0
program g02_mcc_host_fortran
    use, intrinsic :: iso_c_binding
    use mod_G02_MCC_network
    implicit none
    type(g02_mcc_context) :: context
    type(g02_mcc_particle), allocatable :: particles(:)
    type(g02_mcc_cell_background) :: gas(3)
    type(g02_mcc_step_report) :: report
    type(g02_mcc_session) :: session
    character(len=2048) :: model_dir
    character(len=3) :: gas_name(3)
    integer(c_int) :: status
    integer(c_int64_t) :: step
    integer :: i

    call get_command_argument(1, model_dir)
    if (len_trim(model_dir) == 0) stop 1
    call sub_G02_mcc_load(context, trim(model_dir), status)
    if (status /= 0_c_int) stop 2
    allocate (particles(1))
    call sub_G02_mcc_species_id(context, 'e-', particles(1)%species, status)
    if (status /= 0_c_int) stop 3
    call sub_G02_mcc_state_id(context, particles(1)%species, 'ground', &
                          particles(1)%state, status)
    if (status /= 0_c_int) stop 4
    particles(1)%velocity(1) = 2.0e6_c_double
    particles(1)%id = 1_c_int64_t
    gas_name = [character(len=3) :: 'M', 'M2', 'M2+']
    do i = 1, 3
        call sub_G02_mcc_species_id(context, trim(gas_name(i)), gas(i)%species, status)
        if (status /= 0_c_int) stop 5
        call sub_G02_mcc_state_id(context, gas(i)%species, 'ground', gas(i)%state, status)
        if (status /= 0_c_int) stop 6
        gas(i)%cell = -1_c_int32_t
        gas(i)%density_m3 = 0.0_c_double
    end do
    gas(1)%density_m3 = 2.0e20_c_double
    call sub_G02_mcc_session_init(context, session, status)
    if (status /= 0_c_int) stop 7
    do step = 0_c_int64_t, 2_c_int64_t
        call sub_G02_mcc_step(context, particles, gas, 1.0e-8_c_double, step, &
                          1234_c_int64_t, report, status, session=session)
        if (status /= 0_c_int) stop 8
        print '(A,I0,A,I0,A,I0)', 'step=', step, ' particles=', size(particles), &
            ' candidates=', report%stats%candidates
    end do
    call sub_G02_mcc_session_close(session)
    deallocate (particles)
    call sub_G02_mcc_close(context)
end program g02_mcc_host_fortran
