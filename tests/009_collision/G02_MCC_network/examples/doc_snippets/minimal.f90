! SPDX-License-Identifier: Apache-2.0
program g02_documented_example
    use, intrinsic :: iso_c_binding
    use mod_G02_MCC_network
    implicit none
    type(g02_mcc_context) :: context
    type(g02_mcc_particle), allocatable :: particles(:)
    type(g02_mcc_cell_background) :: gas(1)
    type(g02_mcc_step_report) :: report
    integer(c_int) :: status
    character(len=2048) :: model_dir
    call get_command_argument(1, model_dir)
    if (len_trim(model_dir) == 0) stop 2
    call sub_G02_mcc_load(context, trim(model_dir), status)
    call check_status()
    allocate(particles(1))
    call sub_G02_mcc_species_id(context, "A", particles(1)%species, status)
    call check_status()
    call sub_G02_mcc_state_id(context, particles(1)%species, "ground", particles(1)%state, status)
    call check_status()
    particles(1)%id = 1_c_int64_t
    particles(1)%cell = 0_c_int32_t
    particles(1)%velocity(1) = 1000.0_c_double
    call sub_G02_mcc_species_id(context, "B", gas(1)%species, status)
    call check_status()
    call sub_G02_mcc_state_id(context, gas(1)%species, "ground", gas(1)%state, status)
    call check_status()
    gas(1)%cell = 0_c_int32_t ! Local cell; -1_c_int32_t means uniform fallback.
    gas(1)%density_m3 = 1.0e20_c_double
    gas(1)%temperature_k = 300.0_c_double
    call sub_G02_mcc_step(context, particles, gas, 1.0e-7_c_double, &
                         0_c_int64_t, 1234_c_int64_t, report, status)
    call check_status()
    print *, "PASS"
    call sub_G02_mcc_close(context)
contains
    subroutine check_status()
        if (status /= 0_c_int) then
            print *, trim(context%error_message)
            call sub_G02_mcc_close(context)
            stop 1
        end if
    end subroutine check_status
end program g02_documented_example
