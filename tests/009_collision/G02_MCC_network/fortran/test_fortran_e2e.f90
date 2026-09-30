! SPDX-License-Identifier: Apache-2.0
! Fortran end-to-end test: load a package, look up species/state, collide,
! read the result arrays and release everything.
program test_fortran_e2e
    use, intrinsic :: iso_c_binding
    use mod_G02_MCC_network
    implicit none

    integer :: failures = 0
    integer :: checks = 0
    integer :: nargs
    integer :: status
    character(len=1024) :: package_dir
    type(g02_mcc_context) :: context
    type(g02_mcc_particle) :: projectile
    type(g02_mcc_background) :: background(3)
    type(g02_mcc_outcome) :: outcome
    integer(c_int16_t) :: electron_id
    integer(c_int16_t) :: neutral_id
    integer(c_int16_t) :: molecule_id
    integer(c_int16_t) :: molecular_ion_id
    integer(c_int16_t) :: unknown_id
    integer(c_int16_t) :: ground_state

    nargs = command_argument_count()
    call check(nargs >= 1, 'package directory argument')
    if (nargs < 1) then
        call finish()
        stop
    end if
    call get_command_argument(1, package_dir)

    call check(fun_G02_mcc_api_version() == 1_c_int, 'api version')

    call sub_G02_mcc_load(context, trim(package_dir), status)
    call check(status == 0_c_int, 'load package')
    if (status /= 0_c_int) then
        write (*, '(a)') 'load error: '//trim(context%error_message)
        call finish()
        stop
    end if

    call sub_G02_mcc_species_id(context, 'e-', electron_id, status)
    call check(status == 0_c_int, 'species e-')
    call sub_G02_mcc_species_id(context, 'M', neutral_id, status)
    call check(status == 0_c_int, 'species M')
    call sub_G02_mcc_species_id(context, 'M2', molecule_id, status)
    call check(status == 0_c_int, 'species M2')
    call sub_G02_mcc_species_id(context, 'M2+', molecular_ion_id, status)
    call check(status == 0_c_int, 'species M2+')
    call sub_G02_mcc_species_id(context, 'not-a-species', unknown_id, status)
    call check(status /= 0_c_int, 'unknown species is rejected')
    call check(len_trim(context%error_message) > 0, 'unknown species message')

    call sub_G02_mcc_state_id(context, electron_id, 'ground', ground_state, status)
    call check(status == 0_c_int, 'state lookup')

    projectile%species = electron_id
    projectile%state = ground_state
    projectile%weight = 1.0_c_double
    projectile%id = 99_c_int64_t
    projectile%birth_step = 0_c_int64_t
    projectile%cell = 0_c_int32_t
    projectile%position = [0.0_c_double, 0.0_c_double, 0.0_c_double]
    projectile%velocity = [2.3e6_c_double, 0.0_c_double, 0.0_c_double]

    background(1)%species = neutral_id
    background(1)%density_m3 = 2.0e20_c_double
    background(1)%temperature_k = 300.0_c_double
    background(1)%drift_m_per_s = [0.0_c_double, 0.0_c_double, 0.0_c_double]
    background(2)%species = molecule_id
    background(2)%density_m3 = 5.0e19_c_double
    background(2)%temperature_k = 300.0_c_double
    background(2)%drift_m_per_s = [0.0_c_double, 0.0_c_double, 0.0_c_double]
    background(3)%species = molecular_ion_id
    background(3)%density_m3 = 1.0e19_c_double
    background(3)%temperature_k = 300.0_c_double
    background(3)%drift_m_per_s = [0.0_c_double, 0.0_c_double, 0.0_c_double]

    call sub_G02_mcc_collide(context, projectile, background, 1.0e-5_c_double, &
                         0_c_int64_t, 1234_c_int64_t, outcome, status)
    call check(status == 0_c_int, 'collide status')
    if (status /= 0_c_int) then
        write (*, '(a)') 'collide error: '//trim(context%error_message)
    end if
    if (status == 0_c_int) then
        call check(outcome%candidates >= 1_c_int32_t, 'at least one candidate')
        call check(int(size(outcome%events), c_int32_t) == outcome%candidates, &
                   'event array matches counters')
        call check(outcome%real_events + outcome%null_events == outcome%candidates, &
                   'real + null equals candidates')
        call check(abs(outcome%ledger%energy_residual_j) <= outcome%ledger%tolerance_j, &
                   'energy ledger balances')
        call check(abs(outcome%ledger%charge_before_c - outcome%ledger%charge_after_c) < &
                   1.0e-30_c_double, 'charge ledger balances')
        call check(outcome%primary_action >= G02_MCC_ACTION_NONE .and. &
                   outcome%primary_action <= G02_MCC_ACTION_MOVE_SPECIES, 'primary action range')
    end if

    call sub_G02_mcc_outcome_destroy(outcome)
    call check(.not. c_associated(outcome%handle), 'outcome handle released')

    call sub_G02_mcc_close(context)
    call check(.not. context%loaded, 'context closed')

    ! Error path: a missing package must fail with a message and no leak.
    call sub_G02_mcc_load(context, '/no/such/g02/package', status)
    call check(status /= 0_c_int, 'missing package rejected')
    call check(len_trim(context%error_message) > 0, 'missing package message')
    call sub_G02_mcc_close(context)

    ! A failure after a successful engine creation must not leak the outcome
    ! handle or leave half-filled result arrays behind.
    call sub_G02_mcc_load(context, trim(package_dir), status)
    call check(status == 0_c_int, 'reload package for failure path')
    projectile%species = electron_id
    projectile%state = ground_state
    projectile%weight = 1.0_c_double
    projectile%id = 321_c_int64_t
    projectile%velocity = [2.3e6_c_double, 0.0_c_double, 0.0_c_double]
    call sub_G02_mcc_collide(context, projectile, background, -1.0e-5_c_double, &
                         0_c_int64_t, 7_c_int64_t, outcome, status)
    call check(status /= 0_c_int, 'negative dt rejected')
    call check(len_trim(context%error_message) > 0, 'negative dt message')
    call check(.not. c_associated(outcome%handle), 'failed outcome has no handle')
    call check(.not. allocated(outcome%created), 'failed outcome has no created array')
    call check(.not. allocated(outcome%reservoir), 'failed outcome has no reservoir array')
    call check(.not. allocated(outcome%events), 'failed outcome has no events array')
    call sub_G02_mcc_close(context)

    call finish()
contains
    subroutine check(condition, label)
        logical, intent(in) :: condition
        character(len=*), intent(in) :: label
        checks = checks + 1
        if (.not. condition) then
            failures = failures + 1
            write (*, '(a,i0,a,a)') 'CHECK failed at ', checks, ': ', trim(label)
        end if
    end subroutine check

    subroutine finish()
        if (failures == 0) then
            write (*, '(a,i0,a)') 'PASS test_fortran_e2e (', checks, ' checks)'
        else
            write (*, '(a,i0,a,i0,a)') 'FAIL test_fortran_e2e (', failures, '/', checks, &
                ' checks failed)'
            stop 1
        end if
    end subroutine finish
end program test_fortran_e2e
