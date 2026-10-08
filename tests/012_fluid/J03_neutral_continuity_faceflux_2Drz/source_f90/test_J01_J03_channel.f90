! Real FM trajectories -> residence/crossing fields -> J03 closure and evolution.
program test_J01_J03_channel
    use mod_J01_neutral_free_molecular_2Drz
    use mod_J03_neutral_continuity_faceflux_2Drz
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
    implicit none
    integer :: failed = 0, ft(4,1,2), ierr
    logical :: active(1,2)
    real :: re(2), ze(3), volume(1,2), area(4,1,2), source(1,2), nu(1,2)
    re = [1.0,2.0]
    ze = [0.0,1.0,2.0]
    active = .true.
    ft = J01_FACE_WALL
    ft(J01_Z_LO,1,1) = J01_FACE_OPEN
    ft(J01_Z_HI,1,1) = J01_FACE_INTERIOR
    ft(J01_Z_LO,1,2) = J01_FACE_INTERIOR
    ft(J01_Z_HI,1,2) = J01_FACE_OPEN
    ! Sector angle 2: axial area=3, volume=3, radial areas=2 and 4.
    volume = 3.0
    area(J01_R_LO,:,:) = 2.0
    area(J01_R_HI,:,:) = 4.0
    area(J01_Z_LO,:,:) = 3.0
    area(J01_Z_HI,:,:) = 3.0
    source = 0.0
    nu = 0.0
    call test_known_histories()
    call test_complete_driver()
    write(*,'(a,i0)') 'n_failed = ', failed
    if (failed /= 0) error stop 1
    write(*,'(a)') 'RESULT: PASS'
contains
    subroutine check(ok, label)
        logical, intent(in) :: ok
        character(len=*), intent(in) :: label
        if (.not. ok) then
            failed = failed+1
            write(*,'(a)') 'FAIL: '//label
        end if
    end subroutine check

    subroutine test_known_histories()
        type(fm_tally_2drz_type) :: tally
        type(neutral_transport_closure_2drz_type) :: closure
        real, allocatable :: n(:,:), vr(:,:), vz(:,:), fr(:,:), fz(:,:), bout(:,:,:)
        real :: r, z, ur, uz, bin(4,1,2), errors(2), exact(2), rate
        logical :: escaped, truncated
        integer :: h, level
        call sub_J01_initialize_fm_tally(1,2,tally)
        do h = 1, 2
            r = 1.5
            z = 0.0
            ur = 0.0
            uz = real(2*h-1)
            call sub_J01_trace_fm_history(re,ze,active,ft,0.0,1.0,20, &
                1.e-12,1.e-12,r,z,ur,uz,tally,escaped,truncated)
            call check(escaped .and. .not. truncated, 'known history escapes at channel outlet')
        end do
        rate = 6.0
        call sub_J01_finalize_fm_tally(re,ze,2.0,active,rate,tally,n,vr,vz,fr,fz,bout)
        ! Two histories with vz=1,3: n=q*(1+1/3)/A=8/3; Gamma=2q/A=4.
        call check(maxval(abs(n-8.0/3.0)) < 1.e-11, 'residence density matches exact two-speed value')
        call check(maxval(abs(fz-4.0)) < 1.e-13, 'actual crossing tally gives internal flux 4')
        call check(abs(bout(J01_Z_HI,1,2)-4.0) < 1.e-13, 'actual exit tally gives outlet flux 4')
        bin = 0.0
        bin(J01_Z_LO,1,1) = 4.0
        call sub_J03_initialize_transport_closure(active,ft,volume,area,n,fr,fz,bin,bout,nu, &
            1.e-12,closure,ierr)
        if (ierr /= J03_SUCCESS) error stop 'FM fields rejected by J03'
        call check(abs(closure%velocity_z_face(1,1)-1.5) < 1.e-11, 'FM fields give face coefficient 1.5')
        write(*,'(a,6es24.15)') 'VALUE: two-history densities/flux/outlet/coefficient/density max error: ', &
            n(1,:),fz(1,1),bout(J01_Z_HI,1,2),closure%velocity_z_face(1,1),maxval(abs(n-8.0/3.0))
        ! Empty channel filled by fixed inflow: exact solution of two-cell ODE.
        exact = (8.0/3.0)*[1.0-exp(-1.5),1.0-2.5*exp(-1.5)]
        do level = 1, 2
            call fill_channel(closure,200*level,exact,errors(level))
        end do
        write(*,'(a,3es24.15)') 'VALUE: FM-to-J03 coarse error/fine error/ratio: ', errors,errors(1)/errors(2)
        call check(errors(2) < 0.004, 'FM-to-J03 density matches semidiscrete analytical solution')
        call check(errors(1)/errors(2) > 1.9 .and. errors(1)/errors(2) < 2.1, &
            'FM-to-J03 transient is first order in time')
    end subroutine test_known_histories

    subroutine fill_channel(closure,steps,exact,error)
        type(neutral_transport_closure_2drz_type), intent(in) :: closure
        integer, intent(in) :: steps
        real, intent(in) :: exact(2)
        real, intent(out) :: error
        real, allocatable :: n(:,:), next(:,:)
        integer :: j
        allocate(n(1,2))
        n = 0.0
        do j = 1, steps
            call sub_J03_continuity_step(closure,n,source,1.0/steps,.false.,next,ierr)
            if (ierr /= J03_SUCCESS) error stop 'FM-to-J03 step failed'
            if (any(next < 0.0)) error stop 'negative FM-to-J03 density'
            call move_alloc(next,n)
        end do
        error = maxval(abs(n(1,:)-exact))
        write(*,'(a,i6,4es24.15)') 'VALUE: filling steps/densities/exact densities: ',steps,n(1,:),exact
    end subroutine fill_channel

    subroutine test_complete_driver()
        type(neutral_transport_closure_2drz_type) :: closure
        real, allocatable :: n(:,:), vr(:,:), vz(:,:), fr(:,:), fz(:,:), bout(:,:,:), next(:,:)
        real :: rate, bin(4,1,2), expected_flux, pin, pout, prod, loss, balance
        integer :: completed, truncated
        call sub_J01_free_molecular_mc_2Drz(re,ze,2.0,active,ft,1.0,2.0, &
            1.380649e-23,1.0,1.0,4.0,2.0,0.0,4096,100000,19873, &
            n,vr,vz,fr,fz,bout,rate,completed,truncated,ierr)
        call check(ierr == J01_SUCCESS .and. completed == 4096 .and. truncated == 0, &
            'complete sampled FM driver finishes every history')
        if (ierr /= J01_SUCCESS) return
        if (.not. all(ieee_is_finite(n)) .or. any(n <= 0.0)) error stop 'invalid FM reference density'
        ! Analytic conditional Gaussian mean determines the imposed injection.
        expected_flux = 2.0*(4.0+exp(-8.0)/sqrt(2.0*acos(-1.0))/(0.5*erfc(-4.0/sqrt(2.0))))
        call check(abs(4096*rate/3.0-expected_flux) < 1.e-12, 'complete FM injection normalization')
        call check(maxval(abs(fz-expected_flux)) < 1.e-12 .and. &
            abs(bout(J01_Z_HI,1,2)-expected_flux) < 1.e-12, 'complete FM internal and outlet number balance')
        bin = 0.0
        bin(J01_Z_LO,1,1) = 4096*rate/3.0
        call sub_J03_initialize_transport_closure(active,ft,volume,area,n,fr,fz,bin,bout,nu, &
            1.e-12,closure,ierr)
        if (ierr /= J03_SUCCESS) error stop 'sampled FM closure failed'
        call sub_J03_continuity_step(closure,n,source,0.01,.false.,next,ierr)
        if (ierr /= J03_SUCCESS) error stop 'sampled FM continuity step failed'
        call check(maxval(abs(next-n))/maxval(n) < 1.e-12, 'J03 preserves sampled balanced reference')
        call sub_J03_compute_balance(closure,n,source,pin,pout,prod,loss,balance,ierr)
        if (ierr /= J03_SUCCESS) error stop 'sampled FM balance failed'
        call check(balance < 1.e-12, 'complete FM-to-J03 open-boundary balance')
        write(*,'(a,2i8,5es24.15)') 'VALUE: sampled completed/truncated/inlet/reference/flux error/step error/balance: ', &
            completed,truncated,4096*rate/3.0,expected_flux,maxval(abs(fz-expected_flux)), &
            maxval(abs(next-n))/maxval(n),balance
        ! No exact stochastic density is asserted; the analytic density above
        ! belongs only to the explicitly prescribed two-speed histories.
    end subroutine test_complete_driver
end program test_J01_J03_channel
