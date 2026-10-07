program test_J03_continuity_units
    use mod_J03_neutral_continuity_faceflux_2Drz
    implicit none
    integer :: n_failed
    n_failed = 0
    write(*, '(a)') '=== J03 frozen face-flux continuity unit tests ==='
    call test_upwind_closure_signs(n_failed)
    call test_exact_cfl(n_failed)
    call test_step_and_residual_formula(n_failed)
    call test_axis_zero_area(n_failed)
    call test_invalid_topology(n_failed)
    call test_nonconvergence_diagnostic(n_failed)
    call test_negative_reference_clipping(n_failed)
    write(*, '(a,i0)') 'n_failed = ', n_failed
    if (n_failed == 0) then
        write(*, '(a)') 'RESULT: PASS'
    else
        write(*, '(a)') 'RESULT: FAIL'
        error stop 1
    end if
contains
    subroutine close(actual, expected, tol, label, n_failed)
        real, intent(in) :: actual, expected, tol
        character(len = *), intent(in) :: label
        integer, intent(inout) :: n_failed
        write(*, '(a,4es24.15)') 'VALUE: '//trim(label)//' actual/reference/error/limit: ', &
            actual, expected, abs(actual-expected), tol
        if (.not. (abs(actual-expected) <= tol)) then
            write(*, '(a)') 'FAIL: '//trim(label)
            n_failed = n_failed+1
        end if
    end subroutine close
    subroutine truth(condition, label, n_failed)
        logical, intent(in) :: condition
        character(len = *), intent(in) :: label
        integer, intent(inout) :: n_failed
        if (.not. condition) then
            write(*, '(a)') 'FAIL: '//trim(label)
            n_failed = n_failed+1
        end if
    end subroutine truth

    subroutine test_upwind_closure_signs(n_failed)
        integer, intent(inout) :: n_failed
        type(neutral_transport_closure_2drz_type) :: c
        logical :: active(3, 1)
        integer :: ft(4, 3, 1), ierr
        real :: vol(3, 1), area(4, 3, 1), dens(3, 1), fr(2, 1), fz(3, 0), bin(4, 3, 1), &
            bout(4, 3, 1), nu(3, 1)
        active = .true.
        ft = J03_FACE_WALL
        ft(J03_R_HI, 1, 1) = J03_FACE_INTERIOR
        ft(J03_R_LO, 2, 1) = J03_FACE_INTERIOR
        ft(J03_R_HI, 2, 1) = J03_FACE_INTERIOR
        ft(J03_R_LO, 3, 1) = J03_FACE_INTERIOR
        vol = 1.0
        area = 1.0
        dens(:, 1) = [2.0, 4.0, 8.0]
        fr(:, 1) = [6.0, -12.0]
        bin = 0.0
        bout = 0.0
        nu = 0.0
        call sub_J03_initialize_transport_closure(active, ft, vol, area, dens, fr, fz, bin, bout, &
            nu, 1.0e-12, c, ierr)
        call close(c%velocity_r_face(1, 1), 3.0, 1.0e-13, &
            'positive reference flux divides by left density', n_failed)
        call close(c%velocity_r_face(2, 1), -1.5, 1.0e-13, &
            'negative reference flux divides by right density', n_failed)
    end subroutine test_upwind_closure_signs

    subroutine build_one_cell(bin, bout, loss, area, closure, ierr)
        real, intent(in) :: bin(4, 1, 1), bout(4, 1, 1), loss, area(4, 1, 1)
        type(neutral_transport_closure_2drz_type), intent(out) :: closure
        integer, intent(out) :: ierr
        logical :: active(1, 1)
        integer :: ft(4, 1, 1)
        real :: vol(1, 1), dens(1, 1), fr(0, 1), fz(1, 0), nu(1, 1)
        active = .true.
        ft = J03_FACE_WALL
        if (abs(bin(J03_Z_LO, 1, 1))+abs(bout(J03_Z_LO, 1, 1)) > tiny(1.0)) &
            ft(J03_Z_LO, 1, 1) = J03_FACE_OPEN
        if (abs(bin(J03_Z_HI, 1, 1))+abs(bout(J03_Z_HI, 1, 1)) > tiny(1.0)) &
            ft(J03_Z_HI, 1, 1) = J03_FACE_OPEN
        vol = 6.0
        dens = 2.0
        nu = loss
        call sub_J03_initialize_transport_closure(active, ft, vol, area, dens, fr, fz, bin, bout, &
            nu, 1.0e-12, closure, ierr)
    end subroutine build_one_cell

    subroutine test_exact_cfl(n_failed)
        integer, intent(inout) :: n_failed
        type(neutral_transport_closure_2drz_type) :: c
        real :: bin(4, 1, 1), bout(4, 1, 1), area(4, 1, 1), dt
        integer :: ierr
        bin = 0.0
        bout = 0.0
        area = 0.0
        bout(J03_Z_HI, 1, 1) = 4.0
        area(J03_Z_HI, 1, 1) = 3.0
        call build_one_cell(bin, bout, 1.0, area, c, ierr)
        call sub_J03_compute_stable_timestep(c, 0.8, dt, ierr)
        call close(dt, 0.4, 1.0e-13, 'CFL includes area/volume outflow and loss rate', n_failed)
    end subroutine test_exact_cfl

    subroutine test_step_and_residual_formula(n_failed)
        integer, intent(inout) :: n_failed
        type(neutral_transport_closure_2drz_type) :: c
        real :: bin(4, 1, 1), bout(4, 1, 1), area(4, 1, 1), n(1, 1), src(1, 1), maxr, balance
        real, allocatable :: next(:, :), residual(:, :)
        integer :: ierr
        bin = 0.0
        bout = 0.0
        area = 0.0
        bin(J03_Z_LO, 1, 1) = 2.0
        bout(J03_Z_HI, 1, 1) = 4.0
        area(J03_Z_LO, 1, 1) = 3.0
        area(J03_Z_HI, 1, 1) = 1.0
        call build_one_cell(bin, bout, 1.0, area, c, ierr)
        n = 3.0
        src = 4.0
        call sub_J03_continuity_step(c, n, src, 0.5, .true., next, ierr)
! z-lo=2, z-hi=(4/2)*3=6: net=1*6-3*2=0.
        call close(next(1, 1), (3.0+0.5*4.0)/1.5, 1.0e-13, &
            'semi-implicit source-loss step formula', n_failed)
        call sub_J03_compute_residual(c, n, src, residual, maxr, balance, ierr)
        call close(residual(1, 1), -1.0, 1.0e-13, &
            'local residual divergence plus loss minus source', n_failed)
        call close(balance, -6.0, 1.0e-13, 'volume-integrated global balance', n_failed)
    end subroutine test_step_and_residual_formula

    subroutine test_axis_zero_area(n_failed)
        integer, intent(inout) :: n_failed
        type(neutral_transport_closure_2drz_type) :: c
        logical :: active(1, 1)
        integer :: ft(4, 1, 1), ierr
        real :: vol(1, 1), area(4, 1, 1), dens(1, 1), fr(0, 1), fz(1, 0), bin(4, 1, 1), &
            bout(4, 1, 1), nu(1, 1)
        active = .true.
        ft = J03_FACE_WALL
        vol = 1.0
        area = 1.0
        area(J03_R_LO, 1, 1) = 0.0
        dens = 1.0
        bin = 0.0
        bout = 0.0
        nu = 0.0
        call sub_J03_initialize_transport_closure(active, ft, vol, area, dens, fr, fz, bin, bout, &
            nu, 1.0e-12, c, ierr)
        call truth(ierr == J03_SUCCESS, 'zero-area symmetry-axis face is valid', n_failed)
    end subroutine test_axis_zero_area

    subroutine test_invalid_topology(n_failed)
        integer, intent(inout) :: n_failed
        type(neutral_transport_closure_2drz_type) :: c
        logical :: active(1, 1)
        integer :: ft(4, 1, 1), ierr
        real :: vol(1, 1), area(4, 1, 1), dens(1, 1), fr(0, 1), fz(1, 0), bin(4, 1, 1), &
            bout(4, 1, 1), nu(1, 1)
        active = .true.
        ft = J03_FACE_WALL
        ft(J03_R_LO, 1, 1) = J03_FACE_INTERIOR
        vol = 1.0
        area = 1.0
        dens = 1.0
        bin = 0.0
        bout = 0.0
        nu = 0.0
        call sub_J03_initialize_transport_closure(active, ft, vol, area, dens, fr, fz, bin, bout, &
            nu, 1.0e-12, c, ierr)
        write(*,'(a,2i8)') 'STATUS: invalid face actual/expected: ',ierr,J03_ERR_FACE_TYPE
        call truth(ierr == J03_ERR_FACE_TYPE, 'boundary face cannot be marked internal', n_failed)
    end subroutine test_invalid_topology

    subroutine test_nonconvergence_diagnostic(n_failed)
        integer, intent(inout) :: n_failed
        type(neutral_transport_closure_2drz_type) :: c
        real :: bin(4, 1, 1), bout(4, 1, 1), area(4, 1, 1), src(1, 1), change, maxr, balance
        real, allocatable :: density(:, :)
        integer :: ierr, it
        logical :: converged
        bin = 0.0
        bout = 0.0
        area = 1.0
        call build_one_cell(bin, bout, 1.0, area, c, ierr)
        src = 10.0
        call sub_J03_solve_steady(c, src, 0.5, 1.0e-15, 1, .true., density, converged, it, &
            change, maxr, balance, ierr)
        write(*,'(a,3i8,l3)') 'STATUS: step limit ierr/expected/iterations/converged: ', &
            ierr,J03_ERR_NOT_CONVERGED,it,converged
        call truth(ierr == J03_ERR_NOT_CONVERGED .and. .not. converged .and. it == 1, &
            'max-iteration failure reports status and exact iteration count', n_failed)
    end subroutine test_nonconvergence_diagnostic

    subroutine test_negative_reference_clipping(n_failed)
        integer, intent(inout) :: n_failed
        type(neutral_transport_closure_2drz_type) :: c
        logical :: active(1, 1)
        integer :: ft(4, 1, 1), ierr
        real :: vol(1, 1), area(4, 1, 1), dens(1, 1), fr(0, 1), fz(1, 0), bin(4, 1, 1), &
            bout(4, 1, 1), nu(1, 1), src(1, 1)
        real, allocatable :: next(:, :)
        active = .true.
        ft = J03_FACE_WALL
        vol = 1.0
        area = 1.0
        dens = -2.0
        bin = 0.0
        bout = 0.0
        nu = 0.0
        src = 0.0
        call sub_J03_initialize_transport_closure(active, ft, vol, area, dens, fr, fz, bin, bout, &
            nu, 1.0e-6, c, ierr)
        call truth(ierr == J03_SUCCESS, 'negative SN reference density is accepted for clipping', &
            n_failed)
        call sub_J03_continuity_step(c, dens, src, 0.1, .true., next, ierr)
        call truth(ierr == J03_SUCCESS .and. abs(next(1, 1)) <= tiny(1.0), &
            'clip-negative mode accepts and clips the initial negative cell', n_failed)
        write(*,'(a,es24.15)') 'VALUE: clipped density: ',next(1,1)
        call sub_J03_continuity_step(c, dens, src, 0.1, .false., next, ierr)
        write(*,'(a,2i8)') 'STATUS: negative density actual/expected: ',ierr,J03_ERR_NEGATIVE_INPUT
        call truth(ierr == J03_ERR_NEGATIVE_INPUT, &
            'non-clipping mode still rejects a negative density', n_failed)
    end subroutine test_negative_reference_clipping
end program test_J03_continuity_units
