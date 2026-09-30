! SPDX-License-Identifier: Apache-2.0
program test_fortran_batch
    use, intrinsic :: iso_c_binding
    use mod_G02_MCC_network
    implicit none
    type(g02_mcc_context) :: context
    type(g02_mcc_particle), allocatable :: particles(:)
    type(g02_mcc_cell_background) :: gas(3)
    type(g02_mcc_step_report) :: report
    type(g02_mcc_session) :: session
    integer(c_int16_t) :: electron, ground, enumerated, owner
    integer(c_int32_t) :: reaction_id
    integer(c_int) :: status, i, charge, representation
    logical :: found_growth
    integer(c_size_t) :: metadata_count
    real(c_double) :: prior_velocity, mass, energy
    character(len=2048) :: data_dir
    character(len=128) :: metadata_name

    call get_command_argument(1, data_dir)
    if (len_trim(data_dir) == 0) stop 1
    call sub_G02_mcc_load(context, trim(data_dir), status)
    if (status /= 0_c_int) stop 2
    call sub_G02_mcc_species_count(context, metadata_count, status)
    if (status /= 0_c_int .or. metadata_count < 3_c_size_t) stop 15
    call sub_G02_mcc_species_get(context, 0_c_size_t, enumerated, metadata_name, &
                             mass, charge, representation, status)
    if (status /= 0_c_int .or. mass <= 0.0_c_double) stop 16
    call sub_G02_mcc_state_count(context, metadata_count, status)
    if (status /= 0_c_int .or. metadata_count < 3_c_size_t) stop 17
    call sub_G02_mcc_state_get(context, 0_c_size_t, enumerated, owner, metadata_name, &
                           energy, status)
    if (status /= 0_c_int .or. len_trim(metadata_name) == 0) stop 18
    call sub_G02_mcc_reaction_count(context, metadata_count, status)
    if (status /= 0_c_int .or. metadata_count < 3_c_size_t) stop 19
    call sub_G02_mcc_reaction_get(context, 0_c_size_t, reaction_id, metadata_name, status)
    if (status /= 0_c_int .or. len_trim(metadata_name) == 0) stop 20
    call sub_G02_mcc_species_id(context, 'e-', electron, status)
    if (status /= 0_c_int) stop 3
    call sub_G02_mcc_state_id(context, electron, 'ground', ground, status)
    if (status /= 0_c_int) stop 4

    call sub_G02_mcc_species_id(context, 'M', gas(1)%species, status)
    if (status /= 0_c_int) stop 5
    call sub_G02_mcc_species_id(context, 'M2', gas(2)%species, status)
    if (status /= 0_c_int) stop 6
    call sub_G02_mcc_species_id(context, 'M2+', gas(3)%species, status)
    if (status /= 0_c_int) stop 7
    do i = 1, 3
        call sub_G02_mcc_state_id(context, gas(i)%species, 'ground', gas(i)%state, status)
        if (status /= 0_c_int) stop 8
        gas(i)%cell = 0_c_int32_t
        gas(i)%temperature_k = 300.0_c_double
    end do
    gas(1)%density_m3 = 2.0e20_c_double

    allocate (particles(16))
    do i = 1, size(particles)
        particles(i)%species = electron
        particles(i)%state = ground
        particles(i)%velocity(1) = 1.0e6_c_double
        particles(i)%weight = 1.0_c_double
        particles(i)%id = int(1000 + i, c_int64_t)
    end do
    call sub_G02_mcc_step(context, particles, gas, 1.0e-7_c_double, 1_c_int64_t, &
                      42_c_int64_t, report, status, backend=G02_MCC_BACKEND_SERIAL)
    if (status /= 0_c_int) then
        print *, trim(context%error_message)
        stop 9
    end if
    if (size(particles) /= 16) stop 10
    if (report%stats%particles_visited /= 16_c_int64_t) stop 11
    if (.not. allocated(report%reservoir)) stop 12
    prior_velocity = particles(1)%velocity(1)
    particles(2)%id = particles(1)%id
    call sub_G02_mcc_step(context, particles, gas, 1.0e-7_c_double, 2_c_int64_t, &
                      42_c_int64_t, report, status)
    if (status == 0_c_int) stop 13
    if (abs(particles(1)%velocity(1) - prior_velocity) > 0.0_c_double) stop 14
    deallocate (particles)
    call sub_G02_mcc_session_init(context, session, status, backend=G02_MCC_BACKEND_SERIAL)
    if (status /= 0_c_int) stop 26
    found_growth = .false.
    do i = 1, 127
        if (allocated(particles)) deallocate (particles)
        allocate (particles(1))
        particles(1)%species = electron
        particles(1)%state = ground
        particles(1)%velocity(1) = sqrt(2.0_c_double * 40.0_c_double * &
            1.602176634e-19_c_double / 9.1093837139e-31_c_double)
        particles(1)%weight = 1.0_c_double
        particles(1)%id = 8000_c_int64_t
        call sub_G02_mcc_step(context, particles, gas, 1.0e-6_c_double, 3_c_int64_t, &
                          int(i, c_int64_t), report, status, session=session)
        if (status /= 0_c_int) stop 21
        if (size(particles) <= 1) cycle
        found_growth = .true.
        if (report%stats%created_particles /= int(size(particles) - 1, c_int64_t)) stop 22
        if (any(particles(2:)%birth_step /= 4_c_int64_t)) stop 23
        call sub_G02_mcc_step(context, particles, gas, 0.0_c_double, 3_c_int64_t, &
                          int(i, c_int64_t), report, status, session=session)
        if (status /= 0_c_int .or. report%stats%particles_visited /= 1_c_int64_t) stop 24
        exit
    end do
    if (.not. found_growth) stop 25
    deallocate (particles)
    call sub_G02_mcc_session_close(session)
    call sub_G02_mcc_close(context)
end program test_fortran_batch
