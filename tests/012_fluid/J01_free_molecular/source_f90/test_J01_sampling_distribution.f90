! Statistical checks use analytic probabilities, not replayed random draws.
program test_J01_sampling_distribution
    use mod_J01_neutral_free_molecular_2Drz
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
    implicit none
    integer, parameter :: samples = 32768
    integer :: failures = 0, seed
    do seed = 1, 3
        call test_inlet(7300+seed)
        call test_diffuse_wall(9400+seed)
    end do
    write(*,'(a,i0)') 'n_failed = ', failures
    if (failures /= 0) error stop 1
    write(*,'(a)') 'RESULT: PASS'
contains
    subroutine close(actual, expected, tolerance, label)
        real, intent(in) :: actual, expected, tolerance
        character(len=*), intent(in) :: label
        write(*,'(a,4es24.15)') 'VALUE: '//label//' actual/reference/error/limit: ', &
            actual, expected, abs(actual-expected), tolerance
        if (ieee_is_finite(actual)) then
            if (abs(actual-expected) <= tolerance) then
                return
            end if
        end if
        failures = failures+1
        write(*,'(a,3es14.6)') 'FAIL: '//label//' actual/expected/tol: ', actual, expected, tolerance
    end subroutine close

    subroutine probability(count, expected, label)
        integer, intent(in) :: count
        real, intent(in) :: expected
        character(len=*), intent(in) :: label
        ! Seven binomial standard errors: robust across supported RNG runtimes.
        call close(real(count)/samples, expected, &
            7.0*sqrt(expected*(1.0-expected)/samples), label)
    end subroutine probability

    subroutine test_inlet(seed)
        integer, intent(in) :: seed
        type(fm_inlet_2drz_type) :: inlet
        logical :: active(2,1)
        integer :: ft(4,2,1), ierr, j, mode, radial_count, axial_count, tangent_count
        real :: rate, r, z, vr, vz, drift, expected, r_edges(3)
        active = .true.
        ft = J01_FACE_OPEN
        r_edges = [1.0, 2.0, 3.0]
        do mode = 0, 1
            drift = real(mode)
            ! kBT/m=1; the inlet covers the full annulus, with area 8.
            call sub_J01_prepare_fm_inlet(r_edges, active, ft, 2.0, 1.0, 3.0, &
                1.380649e-23, 1.0, drift, 5.0, samples, inlet, rate, ierr)
            if (ierr /= J01_SUCCESS) error stop 'inlet setup failed'
            call sub_J01_set_random_seed(seed)
            radial_count = 0
            axial_count = 0
            tangent_count = 0
            do j = 1, samples
                call sub_J01_sample_fm_inlet(inlet, 0.25, drift, r, z, vr, vz)
                if (.not. all(ieee_is_finite([r,z,vr,vz]))) error stop 'nonfinite inlet draw'
                if (r < 1.0 .or. r > 3.0 .or. vz <= 0.0) error stop 'invalid inlet draw'
                ! Uniform annular area: half the events have r^2 < (1+9)/2.
                if (r*r < 5.0) radial_count = radial_count+1
                if (vz < 1.0) axial_count = axial_count+1
                if (abs(vr) < 1.0) tangent_count = tangent_count+1
            end do
            write(*,'(a,2i8)') 'CASE: inlet seed/drift mode: ', seed, mode
            call probability(radial_count, 0.5, 'uniform annular area')
            call probability(tangent_count, erf(1.0/sqrt(2.0)), 'Gaussian tangential velocity')
            if (mode == 0) then
                expected = erf(1.0/sqrt(2.0))
                call close(rate*samples, 40.0*sqrt(2.0/acos(-1.0)), 1.e-12, 'zero-drift injection rate')
            else
                ! P(0<V<1 | V>0), V~N(1,1), from the normal CDF.
                expected = (0.5-0.5*erfc(1.0/sqrt(2.0)))/(1.0-0.5*erfc(1.0/sqrt(2.0)))
            end if
            call probability(axial_count, expected, 'truncated Gaussian axial velocity')
        end do
    end subroutine test_inlet
    subroutine test_diffuse_wall(seed)
        integer, intent(in) :: seed
        integer :: face, j, normal_count, tangent_count
        real :: vr, vz, vn, vt
        do face = J01_R_LO, J01_Z_HI
            call sub_J01_set_random_seed(seed+face)
            normal_count = 0
            tangent_count = 0
            do j = 1, samples
                vr = 3.0
                vz = -2.0
                call sub_J01_reflect_velocity(vr, vz, face, 1.0, 1.0)
                select case (face)
                case (J01_R_LO)
                    vn = vr
                    vt = vz
                case (J01_R_HI)
                    vn = -vr
                    vt = vz
                case (J01_Z_LO)
                    vn = vz
                    vt = vr
                case (J01_Z_HI)
                    vn = -vz
                    vt = vr
                end select
                if (.not. all(ieee_is_finite([vn,vt]))) error stop 'nonfinite wall draw'
                if (vn <= 0.0) error stop 'diffuse reflection points out of gas'
                if (vn < 1.0) normal_count = normal_count+1
                if (abs(vt) < 1.0) tangent_count = tangent_count+1
            end do
            write(*,'(a,2i8)') 'CASE: wall seed/face: ', seed, face
            ! Flux-weighted Maxwell normal speed is Rayleigh, NOT half-normal.
            call probability(normal_count, 1.0-exp(-0.5), 'Rayleigh wall-normal velocity')
            call probability(tangent_count, erf(1.0/sqrt(2.0)), 'Gaussian wall-tangential velocity')
        end do
    end subroutine test_diffuse_wall
end program test_J01_sampling_distribution
