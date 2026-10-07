program test_J03_equilibrium
    use mod_J03_neutral_continuity_faceflux_2Drz
    implicit none
    integer :: n_failed
    n_failed = 0
    write(*, '(a)') '=== J03 equilibrium and conservation tests ==='
    call test_j03_boundary_equilibrium(n_failed)
    call test_j03_ionization_equilibrium(n_failed)
    call test_j03_closed_conservation(n_failed)
    write(*, '(a,i0)') 'n_failed = ', n_failed
    if (n_failed == 0) then
        write(*, '(a)') 'RESULT: PASS'
    else
        write(*, '(a)') 'RESULT: FAIL'
        error stop 1
    end if
contains
    subroutine check(condition, label, n_failed)
        logical, intent(in) :: condition
        character(len = *), intent(in) :: label
        integer, intent(inout) :: n_failed
        if (.not. condition) then
            write(*, '(a)') 'FAIL: '//trim(label)
            n_failed = n_failed+1
        end if
    end subroutine check

    subroutine check_close(actual, expected, tolerance, label, n_failed)
        real, intent(in) :: actual, expected, tolerance
        character(len = *), intent(in) :: label
        integer, intent(inout) :: n_failed
        write(*, '(a,4es24.15)') 'VALUE: '//trim(label)//' actual/reference/error/limit: ', &
            actual, expected, abs(actual-expected), tolerance
        if (.not. (abs(actual-expected) <= tolerance)) then
            write(*, '(a)') 'FAIL: '//trim(label)
            n_failed = n_failed+1
        end if
    end subroutine check_close

    subroutine test_j03_boundary_equilibrium(n_failed)
        integer, intent(inout) :: n_failed
        type(neutral_transport_closure_2drz_type) :: c1
        real :: bin(4, 1, 1), bout(4, 1, 1), src(1, 1), change, resid, balance
        real, allocatable :: density(:, :)
        integer :: ierr, it
        logical :: converged
        bin = 0.0
        bout = 0.0
        bin(J03_Z_LO, 1, 1) = 2.0
        bout(J03_Z_HI, 1, 1) = 2.0
        call initialize_one_cell_from_flux(bin, bout, 0.0, c1, ierr)
        src = 0.0
        call sub_J03_solve_steady(c1, src, 0.8, 1.0e-13, 20, .true., density, converged, it, &
            change, resid, balance, ierr)
        call check(ierr == J03_SUCCESS .and. converged, 'J03 boundary equilibrium converges', n_failed)
        call check_close(density(1, 1), 2.0, 1.0e-12, 'J03 preserves balanced reference density', n_failed)
        call check_close(resid, 0.0, 1.0e-12, 'J03 balanced-boundary residual', n_failed)
    end subroutine test_j03_boundary_equilibrium

    subroutine initialize_one_cell_from_flux(bin, bout, loss, closure, ierr)
        real, intent(in) :: bin(4, 1, 1), bout(4, 1, 1), loss
        type(neutral_transport_closure_2drz_type), intent(out) :: closure
        integer, intent(out) :: ierr
        logical :: active(1, 1)
        integer :: ft(4, 1, 1)
        real :: vol(1, 1), area(4, 1, 1), dens(1, 1), nu(1, 1), fr(0, 1), fz(1, 0)
        active = .true.
        ft = J03_FACE_WALL
        ft(J03_Z_LO, 1, 1) = J03_FACE_OPEN
        ft(J03_Z_HI, 1, 1) = J03_FACE_OPEN
        vol = 1.0
        area = 1.0
        dens = 2.0
        nu = loss
        call sub_J03_initialize_transport_closure(active, ft, vol, area, dens, fr, fz, bin, bout, nu, &
            1.0e-12, closure, ierr)
    end subroutine initialize_one_cell_from_flux

    subroutine test_j03_ionization_equilibrium(n_failed)
        integer, intent(inout) :: n_failed
        type(neutral_transport_closure_2drz_type) :: closure
        real :: bin(4, 1, 1), bout(4, 1, 1), src(1, 1), change, resid, balance
        real, allocatable :: density(:, :)
        integer :: ierr, it
        logical :: converged
        bin = 0.0
        bout = 0.0
        call initialize_one_cell_from_flux(bin, bout, 2.0, closure, ierr)
        src = 4.0
        call sub_J03_solve_steady(closure, src, 0.8, 1.0e-12, 200, .true., density, converged, it, &
            change, resid, balance, ierr)
        call check(ierr == J03_SUCCESS .and. converged, 'J03 ionization case converges', n_failed)
        call check_close(density(1, 1), 2.0, 2.0e-11, 'J03 source-loss equilibrium S/nu', n_failed)
    end subroutine test_j03_ionization_equilibrium

    subroutine test_j03_closed_conservation(n_failed)
        integer, intent(inout) :: n_failed
        type(neutral_transport_closure_2drz_type) :: closure
        logical :: active(2, 1)
        integer :: ft(4, 2, 1), ierr
        real :: vol(2, 1), area(4, 2, 1), dens(2, 1), fr(1, 1), fz(2, 0), bin(4, 2, 1), &
            bout(4, 2, 1), nu(2, 1), src(2, 1)
        real, allocatable :: next(:, :)
        active = .true.
        ft = J03_FACE_WALL
        ft(J03_R_HI, 1, 1) = J03_FACE_INTERIOR
        ft(J03_R_LO, 2, 1) = J03_FACE_INTERIOR
        vol = 1.0
        area = 1.0
        dens(:, 1) = [1.0, 2.0]
        fr = 1.0
        bin = 0.0
        bout = 0.0
        nu = 0.0
        src = 0.0
        call sub_J03_initialize_transport_closure(active, ft, vol, area, dens, fr, fz, bin, bout, &
            nu, 1.0e-12, closure, ierr)
        call sub_J03_continuity_step(closure, dens, src, 0.1, .true., next, ierr)
        call check_close(sum(next), sum(dens), 1.0e-13, &
            'J03 closed-domain finite-volume conservation', n_failed)
    end subroutine test_j03_closed_conservation
end program test_J03_equilibrium
