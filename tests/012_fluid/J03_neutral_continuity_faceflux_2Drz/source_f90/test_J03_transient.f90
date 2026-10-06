program test_J03_transient
    use mod_J03_neutral_continuity_faceflux_2Drz
    implicit none
    integer :: failed = 0
    call test_faces()
    call test_small_timestep()
    call test_time_evolution()
    call test_transport()
    call test_mixed_time_balance()
    write(*,'(a,i0)') 'n_failed = ', failed
    if (failed /= 0) error stop 1
    write(*,'(a)') 'RESULT: PASS'
contains
    subroutine check(ok, label)
        logical, intent(in) :: ok
        character(len=*), intent(in) :: label
        if (.not. ok) then
            write(*,'(a)') 'FAIL: '//label
            failed = failed+1
        end if
    end subroutine check

    subroutine setup(c, ft, area, ierr)
        type(neutral_transport_closure_2drz_type), intent(out) :: c
        integer, intent(in) :: ft(4,2,1)
        real, intent(in) :: area(4,2,1)
        integer, intent(out) :: ierr
        logical :: active(2,1)
        real :: vol(2,1), n(2,1), fr(1,1), fz(2,0), bin(4,2,1), bout(4,2,1), nu(2,1)
        active = .true.
        vol = 1.0
        n = 1.0
        fr = 1.0
        bin = 0.0
        bout = 0.0
        nu = 0.0
        call sub_J03_initialize_transport_closure(active,ft,vol,area,n,fr,fz,bin,bout,nu,1.e-12,c,ierr)
    end subroutine setup

    subroutine test_faces()
        type(neutral_transport_closure_2drz_type) :: c
        integer :: ft(4,2,1), ierr
        real :: area(4,2,1)
        ft = J03_FACE_WALL
        area = 1.0
        ft(J03_R_HI,1,1) = J03_FACE_INTERIOR
        call setup(c,ft,area,ierr)
        call check(ierr == J03_ERR_FACE_TYPE,'one-sided interior face rejected')
        ft(J03_R_LO,2,1) = J03_FACE_INTERIOR
        area(J03_R_LO,2,1) = 2.0
        call setup(c,ft,area,ierr)
        call check(ierr == J03_ERR_GEOMETRY,'shared face with unequal area rejected')
        area(J03_R_LO,2,1) = 1.0
        call setup(c,ft,area,ierr)
        call check(ierr == J03_SUCCESS,'matching shared face accepted')
    end subroutine test_faces

    subroutine test_small_timestep()
        type(neutral_transport_closure_2drz_type) :: c
        integer :: ft(4,2,1), ierr, iterations
        real :: area(4,2,1), source(2,1), change, residual, balance, scaled
        real, allocatable :: n(:,:)
        logical :: converged
        ft = J03_FACE_WALL
        area = 1.0
        source = 0.0
        call setup(c,ft,area,ierr)
        c%loss_frequency = 1.0
        call sub_J03_solve_steady(c,source,1.e-12,1.e-6,3,.false.,n,converged,iterations, &
            change,residual,balance,ierr,final_scaled_residual=scaled)
        call check(ierr == J03_ERR_NOT_CONVERGED .and. .not. converged .and. iterations == 3, &
            'tiny dt cannot masquerade as steady convergence')
        call check(change < 1.e-6 .and. scaled > 0.9,'small update still has a large scaled residual')
        write(*,'(a,i6,2es24.15)') 'VALUE: tiny-dt iterations/change/scaled residual: ',iterations,change,scaled
        call sub_J03_solve_steady(c,source,0.5,0.9,100,.false.,n,converged,iterations, &
            change,residual,balance,ierr,residual_tolerance=1.e-6,final_scaled_residual=scaled)
        call check(ierr == J03_SUCCESS .and. converged .and. scaled <= 1.e-6, &
            'steady solve satisfies independently specified residual tolerance')
        write(*,'(a,i6,2es24.15)') 'VALUE: steady iterations/change/scaled residual: ',iterations,change,scaled
    end subroutine test_small_timestep

    subroutine evolve(steps, source_value, mode, value)
        integer, intent(in) :: steps, mode
        real, intent(in) :: source_value
        real, intent(out) :: value
        type(neutral_transport_closure_2drz_type) :: c
        integer :: ft(4,2,1), ierr, j
        real :: area(4,2,1), source(2,1), dt
        real, allocatable :: n(:,:), next(:,:)
        ft = J03_FACE_WALL
        area = 1.0
        call setup(c,ft,area,ierr)
        n = c%density_ref
        source = source_value
        dt = 1.0/real(steps)
        do j = 1, steps
            c%loss_frequency = 2.0
            if (mode == 1) then
                c%loss_frequency = 1.0
                if (j > steps/2) c%loss_frequency = 3.0
            end if
            call sub_J03_continuity_step(c,n,source,dt,.false.,next,ierr)
            if (ierr /= J03_SUCCESS) error stop 'transient update failed'
            call move_alloc(next,n)
        end do
        value = n(1,1)
    end subroutine evolve

    subroutine test_time_evolution()
        real :: coarse, fine, exact, err_coarse, err_fine
        call evolve(40,0.0,0,coarse)
        call evolve(80,0.0,0,fine)
        exact = exp(-2.0)
        err_coarse = abs(coarse-exact)
        err_fine = abs(fine-exact)
        write(*,'(a,6es24.15)') 'VALUE: decay coarse/fine/exact/errors/ratio: ', &
            coarse,fine,exact,err_coarse,err_fine,err_coarse/err_fine
        call check(err_coarse/err_fine > 1.9 .and. err_coarse/err_fine < 2.1, &
            'physical decay at t=1 converges at first order in time')
        call evolve(80,3.0,0,fine)
        exact = 1.5-0.5*exp(-2.0)
        call check(abs(fine-exact) < 0.002,'source-loss transient agrees with analytical solution')
        write(*,'(a,3es24.15)') 'VALUE: source-loss actual/reference/error: ',fine,exact,abs(fine-exact)
        call evolve(80,0.0,1,fine)
        exact = (1.0+1.0/80.0)**(-40)*(1.0+3.0/80.0)**(-40)
        call check(abs(fine-exact) < 1.e-12,'updated loss frequency is used at each physical step')
        call check(abs(fine-exp(-2.0)) < 0.005,'piecewise loss follows its time integral')
        write(*,'(a,5es24.15)') 'VALUE: piecewise loss actual/discrete ref/discrete error/ODE ref/ODE error: ', &
            fine,exact,abs(fine-exact),exp(-2.0),abs(fine-exp(-2.0))
    end subroutine test_time_evolution

    subroutine test_transport()
        type(neutral_transport_closure_2drz_type) :: c
        integer :: ft(4,2,1), ierr, j
        real :: area(4,2,1), source(2,1), initial, pin, pout, production, removal, balance
        real, allocatable :: n(:,:), next(:,:)
        ft = J03_FACE_WALL
        ft(J03_R_HI,1,1) = J03_FACE_INTERIOR
        ft(J03_R_LO,2,1) = J03_FACE_INTERIOR
        area = 1.0
        source = 0.0
        call setup(c,ft,area,ierr)
        n = c%density_ref
        initial = sum(n*c%volume)
        do j = 1,100
            call sub_J03_continuity_step(c,n,source,0.01,.false.,next,ierr)
            if (ierr /= J03_SUCCESS) error stop 'transport update failed'
            call move_alloc(next,n)
        end do
        call check(abs(n(1,1)-exp(-1.0)) < 0.002, 'two-cell transfer at t=1 matches semidiscrete ODE')
        call check(abs(sum(n*c%volume)-initial) < 1.e-12,'transient internal transport conserves total number')
        write(*,'(a,4es24.15)') 'VALUE: two-cell density/exact/total/initial total: ', &
            n(1,1),exp(-1.0),sum(n*c%volume),initial
        call sub_J03_compute_balance(c,n,source,pin,pout,production,removal,balance,ierr)
        call check(ierr == J03_SUCCESS .and. balance < 1.e-12,'closed-domain boundary balance excludes internal faces')
        c%face_type(J03_Z_LO,1,1) = J03_FACE_OPEN
        c%face_type(J03_Z_HI,2,1) = J03_FACE_OPEN
        c%boundary_inflow_flux(J03_Z_LO,1,1) = 3.0
        c%boundary_outflow_velocity(J03_Z_HI,2,1) = 2.0/n(2,1)
        source = 0.0
        source(1,1) = 1.0
        c%loss_frequency = 2.0/initial
        call sub_J03_compute_balance(c,n,source,pin,pout,production,removal,balance,ierr)
        call check(abs(pin-3.0) < 1.e-12 .and. abs(pout-2.0) < 1.e-12 .and. &
            abs(production-1.0) < 1.e-12 .and. abs(removal-2.0) < 1.e-12 .and. balance < 1.e-12, &
            'open boundary rates and volume source-loss balance')
        write(*,'(a,5es24.15)') 'VALUE: open incoming/outgoing/source/loss/scaled balance: ', &
            pin,pout,production,removal,balance
    end subroutine test_transport
    subroutine test_mixed_time_balance()
        type(neutral_transport_closure_2drz_type) :: c
        logical :: active(2,1)
        integer :: ft(4,2,1), ierr
        real :: area(4,2,1), vol(2,1), ref(2,1), fr(1,1), fz(2,0)
        real :: bin(4,2,1), bout(4,2,1), nu(2,1), source(2,1), old(2,1)
        real :: pin, pout, production, removal, balance, defect
        real, allocatable :: next(:,:)
        active = .true.
        ft = J03_FACE_WALL
        ft(J03_R_LO,1,1) = J03_FACE_OPEN
        ft(J03_R_HI,1,1) = J03_FACE_INTERIOR
        ft(J03_R_LO,2,1) = J03_FACE_INTERIOR
        ft(J03_R_HI,2,1) = J03_FACE_OPEN
        area = 2.0
        area(J03_R_HI,1,1) = 3.0
        area(J03_R_LO,2,1) = 3.0
        vol(:,1) = [2.0,5.0]
        ref(:,1) = [1.0,4.0]
        fr = -2.0
        bin = 0.0
        bout = 0.0
        bin(J03_R_LO,1,1) = 0.7
        bin(J03_R_HI,2,1) = -1.1
        bout(J03_R_LO,1,1) = -0.3
        bout(J03_R_HI,2,1) = 0.6
        nu(:,1) = [0.4,0.7]
        source(:,1) = [0.2,0.5]
        old(:,1) = [2.0,3.0]
        call sub_J03_initialize_transport_closure(active,ft,vol,area,ref,fr,fz,bin,bout,nu,1.e-12,c,ierr)
        if (ierr /= J03_SUCCESS) error stop 'mixed-time closure setup failed'
        ! Caller arrays are not borrowed: changing them must not change c.
        ref = 100.0
        fr = 100.0
        call check(abs(c%velocity_r_face(1,1)+0.5) < 1.e-13 .and. &
            maxval(abs(c%density_ref(:,1)-[1.0,4.0])) < 1.e-13 .and. &
            abs(c%flux_r_ref(1,1)+2.0) < 1.e-13, 'closure owns its reference arrays')
        call sub_J03_continuity_step(c,old,source,0.01,.false.,next,ierr)
        if (ierr /= J03_SUCCESS) error stop 'mixed-time step failed'
        call sub_J03_compute_balance(c,old,source,pin,pout,production,removal,balance,ierr)
        if (ierr /= J03_SUCCESS) error stop 'mixed-time balance failed'
        call check(abs(pin-3.6)+abs(pout-2.1)+abs(production-2.9) < 1.e-12, &
            'signed open rates use old density on a nonuniform mesh')
        ! Transport is explicit; removal is implicit. Internal transfer cancels.
        defect = sum(vol*(next-old))/0.01-(3.6-2.1+2.9-sum(vol*nu*next))
        write(*,'(a,4es24.15)') 'VALUE: mixed-time storage/net input/new loss/defect: ', &
            sum(vol*(next-old))/0.01,3.6-2.1+2.9,sum(vol*nu*next),defect
        call check(abs(defect) < 1.e-12, 'transient storage equals inflow plus source minus outflow and new loss')
        call check(all(next >= 0.0), 'mixed-time step is nonnegative without clipping')
    end subroutine test_mixed_time_balance
end program test_J03_transient
