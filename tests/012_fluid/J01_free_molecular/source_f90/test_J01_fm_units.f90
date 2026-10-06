program test_J01_fm_units
    use mod_J01_neutral_free_molecular_2Drz
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
    implicit none
    integer :: n_failed = 0
    call test_sampling()
    call test_reflection()
    call test_trajectory()
    call test_statistics()
    call test_driver_errors()
    write(*, '(a,i0)') 'n_failed = ', n_failed
    if (n_failed /= 0) error stop 1
    write(*, '(a)') 'RESULT: PASS'
contains
    subroutine check(ok, label)
        logical, intent(in) :: ok
        character(len=*), intent(in) :: label
        if (.not. ok) then
            n_failed = n_failed+1
            write(*, '(a)') 'FAIL: '//label
        end if
    end subroutine check

    subroutine close(actual, expected, label)
        real, intent(in) :: actual, expected
        character(len=*), intent(in) :: label
        logical :: ok
        ok = abs(actual-expected) <= 1.0e-11*max(1.0,abs(expected))
        ! One numerical record per assertion, including successful runs.
        write(*, '(a,4es24.15)') 'VALUE: '//label//' actual/reference/error/limit: ', &
            actual, expected, abs(actual-expected), 1.0e-11*max(1.0,abs(expected))
        if (.not. ok) call check(ok, label)
    end subroutine close

    subroutine test_sampling()
        type(fm_inlet_2drz_type) :: inlet
        real :: edges(3) = [1.0,2.0,3.0], rate, r, z, ur, uz, first(4)
        logical :: active(2,1), valid
        integer :: face(4,2,1), ierr, p
        active = .true.
        face = J01_FACE_WALL
        face(J01_Z_LO,:,1) = J01_FACE_OPEN
        ! Choose kB*T/m=1 so the zero-drift half-normal mean is analytical.
        call sub_J01_prepare_fm_inlet(edges,active,face,2.0,1.5,2.5, &
            1.380649e-23,1.0,0.0,10.0,100,inlet,rate,ierr)
        call check(ierr == J01_SUCCESS, 'prepare partial inlet')
        call close(inlet%segment_area(1),1.75,'first annular overlap area')
        call close(inlet%segment_area(2),2.25,'second annular overlap area')
        call close(rate,0.4*sqrt(2.0/acos(-1.0)),'history particle-rate normalization')
        call sub_J01_set_random_seed(17)
        call sub_J01_sample_fm_inlet(inlet,0.01,0.0,r,z,ur,uz)
        first = [r,z,ur,uz]
        call sub_J01_set_random_seed(17)
        call sub_J01_sample_fm_inlet(inlet,0.01,0.0,r,z,ur,uz)
        call check(maxval(abs(first-[r,z,ur,uz])) < epsilon(1.0), 'same-runtime seed repeatability')
        write(*, '(a,es24.15)') 'VALUE: seed repeatability max difference: ', maxval(abs(first-[r,z,ur,uz]))
        valid = .true.
        do p = 1,1000
            call sub_J01_sample_fm_inlet(inlet,0.01,0.0,r,z,ur,uz)
            valid = valid .and. r >= 1.5 .and. r <= 2.5 .and. uz > 0.0
            valid = valid .and. all(ieee_is_finite([r,z,ur,uz]))
        end do
        call check(valid,'sampled inlet bounds, positive axial velocity and finite values')
        active = .false.
        call sub_J01_prepare_fm_inlet(edges,active,face,2.0,1.5,2.5, &
            1.380649e-23,1.0,0.0,10.0,100,inlet,rate,ierr)
        call check(ierr == J01_ERR_CONFIGURATION,'empty inlet rejected')
        write(*, '(a,2i8)') 'STATUS: empty inlet actual/expected: ', ierr, J01_ERR_CONFIGURATION
    end subroutine test_sampling

    subroutine test_reflection()
        real :: ur, uz
        integer :: face, p
        logical :: valid
        do face = 1,4
            ur = 2.0
            uz = 3.0
            call sub_J01_reflect_velocity(ur,uz,face,0.0,1.0)
            if (face <= 2) then
                call close(ur,-2.0,'specular radial normal')
                call close(uz,3.0,'specular axial tangent')
            else
                call close(ur,2.0,'specular radial tangent')
                call close(uz,-3.0,'specular axial normal')
            end if
        end do
        valid = .true.
        do face = 1,4
            do p = 1,100
                call sub_J01_reflect_velocity(ur,uz,face,1.0,1.0)
                valid = valid .and. all(ieee_is_finite([ur,uz]))
                select case(face)
                case(J01_R_LO)
                    valid = valid .and. ur > 0.0
                case(J01_R_HI)
                    valid = valid .and. ur < 0.0
                case(J01_Z_LO)
                    valid = valid .and. uz > 0.0
                case(J01_Z_HI)
                    valid = valid .and. uz < 0.0
                end select
            end do
        end do
        call check(valid,'diffuse reflection points into domain on all four faces')
    end subroutine test_reflection

    subroutine test_trajectory()
        type(fm_tally_2drz_type) :: tally
        real :: re(2) = [1.0,2.0], ze(3) = [0.0,1.0,2.0]
        real :: r, z, ur, uz
        integer :: face(4,1,2)
        logical :: active(1,2), escaped, truncated
        active = .true.
        face = J01_FACE_OPEN
        face(J01_Z_HI,1,1) = J01_FACE_INTERIOR
        face(J01_Z_LO,1,2) = J01_FACE_INTERIOR
        call check(fun_J01_locate_cell(1.0,ze) == 2,'locator assigns shared edge to upper cell')
        call check(fun_J01_locate_cell(2.0,ze) == -1,'locator excludes final edge')
        call sub_J01_initialize_fm_tally(1,2,tally)
        r = 1.5
        z = 0.25
        ur = 0.0
        uz = 2.0
        call sub_J01_trace_fm_history(re,ze,active,face,0.0,1.0,10, &
            1.0e-9,1.0e-9,r,z,ur,uz,tally,escaped,truncated)
        call check(escaped .and. .not. truncated,'straight trajectory escapes')
        call close(tally%residence(1,1),0.375,'first cell residence')
        call close(tally%residence(1,2),(1.0-1.0e-9)/2.0,'second cell residence including face offset')
        call close(tally%count_z(1,1),1.0,'positive internal crossing')
        call close(tally%boundary_count(J01_Z_HI,1,2),1.0,'positive boundary exit')
        call sub_J01_initialize_fm_tally(1,2,tally)
        r = 1.5
        z = 1.75
        uz = -2.0
        call sub_J01_trace_fm_history(re,ze,active,face,0.0,1.0,10, &
            1.0e-9,1.0e-9,r,z,ur,uz,tally,escaped,truncated)
        call close(tally%count_z(1,1),-1.0,'negative internal crossing')
        call close(tally%boundary_count(J01_Z_LO,1,1),-1.0,'negative boundary exit')
        call sub_J01_initialize_fm_tally(1,2,tally)
        r = 1.5
        z = 0.25
        uz = 2.0
        call sub_J01_trace_fm_history(re,ze,active,face,0.0,1.0,1, &
            1.0e-9,1.0e-9,r,z,ur,uz,tally,escaped,truncated)
        call check(truncated .and. .not. escaped,'event limit is truncation, not successful escape')
        r = 0.5
        call sub_J01_trace_fm_history(re,ze,active,face,0.0,1.0,10, &
            1.0e-9,1.0e-9,r,z,ur,uz,tally,escaped,truncated)
        call check(truncated .and. .not. escaped,'outside start rejected without invalid array access')
    end subroutine test_trajectory

    subroutine test_statistics()
        type(fm_tally_2drz_type) :: tally
        real :: re(3) = [1.0,2.0,3.0], ze(3) = [0.0,1.0,2.0]
        logical :: active(2,2)
        real, allocatable :: n(:,:), ur(:,:), uz(:,:), fr(:,:), fz(:,:), bout(:,:,:)
        active = .true.
        call sub_J01_initialize_fm_tally(2,2,tally)
        call check(maxval(abs(tally%residence)) < tiny(1.0),'new tally starts at zero')
        tally%residence(1,1) = 2.0
        tally%moment_r(1,1) = 6.0
        tally%moment_z(1,1) = -4.0
        tally%count_r(1,1) = -2.0
        tally%count_z(1,1) = 3.0
        tally%boundary_count(J01_R_LO,1,1) = -1.0
        call sub_J01_finalize_fm_tally(re,ze,2.0,active,6.0,tally,n,ur,uz,fr,fz,bout)
        call close(n(1,1),4.0,'density equals rate times residence divided by volume')
        call close(ur(1,1),3.0,'radial residence-weighted mean')
        call close(uz(1,1),-2.0,'axial residence-weighted mean')
        call close(fr(1,1),-3.0,'radial count normalized by radial area')
        call close(fz(1,1),6.0,'axial count normalized by annular area')
        call close(bout(J01_R_LO,1,1),-3.0,'low-face boundary flux keeps coordinate sign')
        call close(n(2,2),0.0,'unvisited cell stays zero')
    end subroutine test_statistics

    subroutine test_driver_errors()
        real :: re(2) = [1.0,2.0], ze(3) = [0.0,1.0,2.0], rate
        logical :: active(1,2)
        integer :: face(4,1,2), done, truncated, ierr
        real, allocatable :: n(:,:), ur(:,:), uz(:,:), fr(:,:), fz(:,:), bout(:,:,:)
        active = .true.
        face = J01_FACE_WALL
        face(J01_Z_LO,1,1) = J01_FACE_OPEN
        face(J01_Z_HI,1,1) = J01_FACE_INTERIOR
        face(J01_Z_LO,1,2) = J01_FACE_INTERIOR
        ! One event cannot reach the only open exit after positive-z injection.
        call sub_J01_free_molecular_mc_2Drz(re,ze,2.0,active,face,1.0,2.0, &
            1.380649e-23,1.0,1.0,1.0,1.0,0.0,20,1,17, &
            n,ur,uz,fr,fz,bout,rate,done,truncated,ierr)
        call check(ierr == J01_ERR_PARTICLE_TRACKING .and. done == 0 .and. truncated == 20, &
            'driver reports all truncated histories as a tracking failure')
        write(*, '(a,4i8)') 'STATUS: event limit ierr/expected/completed/truncated: ', &
            ierr, J01_ERR_PARTICLE_TRACKING, done, truncated

        face(J01_R_LO,1,1) = J01_FACE_INTERIOR
        call sub_J01_free_molecular_mc_2Drz(re,ze,2.0,active,face,1.0,2.0, &
            1.380649e-23,1.0,1.0,1.0,1.0,0.0,20,1,17, &
            n,ur,uz,fr,fz,bout,rate,done,truncated,ierr)
        call check(ierr == J01_ERR_CONFIGURATION .and. done == 0, &
            'domain edge cannot be an internal face')
        write(*, '(a,3i8)') 'STATUS: domain edge ierr/expected/completed: ', ierr, J01_ERR_CONFIGURATION, done
    end subroutine test_driver_errors
end program test_J01_fm_units
