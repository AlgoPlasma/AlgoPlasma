program test_J01_faceflux_2Drz_units
    use mod_J01_continuity_freeflow
    use mod_J01_neutral_free_molecular_2Drz, only: sub_J01_free_molecular_mc_2Drz
    implicit none
    integer :: n_failed
    n_failed = 0
    write(*, '(a)') '=== J01 2D r-z face-flux unit tests ==='
    call test_lax_friedrichs_signs(n_failed)
    call test_boundary_outflow_signs(n_failed)
    call test_cylindrical_step_formula(n_failed)
    call test_free_molecular_single_cell(n_failed)
    call test_input_errors(n_failed)
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

    subroutine test_lax_friedrichs_signs(n_failed)
        integer, intent(inout) :: n_failed
        logical :: active(2, 1)
        integer :: ft(4, 2, 1), ierr
        real :: n(2, 1), ur(2, 1), uz(2, 1), bin(4, 2, 1)
        real, allocatable :: fr(:, :), fz(:, :), bout(:, :, :)
        active = .true.
        ft = J01_FACE_OPEN
        ft(J01_R_HI, 1, 1) = J01_FACE_INTERIOR
        ft(J01_R_LO, 2, 1) = J01_FACE_INTERIOR
        n(:, 1) = [2.0, 5.0]
        uz = 0.0
        bin = 0.0
        ur = 1.0
        call sub_J01_build_faceflux_2Drz(active, ft, n, ur, uz, bin, fr, fz, bout, ierr)
        call close(fr(1, 1), 2.0, 1.0e-13, 'positive velocity selects left upwind density', n_failed)
        ur = -1.0
        call sub_J01_build_faceflux_2Drz(active, ft, n, ur, uz, bin, fr, fz, bout, ierr)
        call close(fr(1, 1), -5.0, 1.0e-13, 'negative velocity selects right upwind density', n_failed)
        ur(:, 1) = [1.0, 3.0]
        call sub_J01_build_faceflux_2Drz(active, ft, n, ur, uz, bin, fr, fz, bout, ierr)
        call close(fr(1, 1), 0.5*(2.0+15.0)-0.5*3.0*(5.0-2.0), 1.0e-13, &
            'unequal-velocity Lax-Friedrichs formula', n_failed)
    end subroutine test_lax_friedrichs_signs

    subroutine test_boundary_outflow_signs(n_failed)
        integer, intent(inout) :: n_failed
        logical :: active(1, 1)
        integer :: ft(4, 1, 1), ierr
        real :: n(1, 1), ur(1, 1), uz(1, 1), bin(4, 1, 1)
        real, allocatable :: fr(:, :), fz(:, :), bout(:, :, :)
        active = .true.
        ft = J01_FACE_OPEN
        n = 3.0
        bin = 0.0
        ur = -2.0
        uz = 4.0
        call sub_J01_build_faceflux_2Drz(active, ft, n, ur, uz, bin, fr, fz, bout, ierr)
        call close(bout(J01_R_LO, 1, 1), -6.0, 1.0e-13, 'r-lo outgoing sign', n_failed)
        call close(bout(J01_R_HI, 1, 1), 0.0, 1.0e-13, 'r-hi rejects incoming velocity', n_failed)
        call close(bout(J01_Z_LO, 1, 1), 0.0, 1.0e-13, 'z-lo rejects incoming velocity', n_failed)
        call close(bout(J01_Z_HI, 1, 1), 12.0, 1.0e-13, 'z-hi outgoing sign', n_failed)
    end subroutine test_boundary_outflow_signs

    subroutine test_cylindrical_step_formula(n_failed)
        integer, intent(inout) :: n_failed
        logical :: active(1, 1)
        integer :: ft(4, 1, 1), ierr
        real :: vol(1, 1), area(4, 1, 1), n(1, 1), src(1, 1), loss(1, 1)
        real :: fr(0, 1), fz(1, 0), bin(4, 1, 1), bout(4, 1, 1)
        real, allocatable :: next(:, :)
        active = .true.
        ft = J01_FACE_WALL
        ft(J01_Z_LO, 1, 1) = J01_FACE_OPEN
        vol = 2.0
        area = 1.0
        area(J01_Z_LO, 1, 1) = 3.0
        n = 2.0
        src = 4.0
        loss = 1.0
        bin = 0.0
        bout = 0.0
        bin(J01_Z_LO, 1, 1) = 2.0
        call sub_J01_continuity_step_2Drz(active, ft, vol, area, n, src, loss, fr, fz, bin, bout, &
            0.5, next, ierr)
        call close(next(1, 1), (2.0+0.5*3.0+0.5*4.0)/1.5, 1.0e-13, &
            'area-volume source-loss single-step formula', n_failed)
    end subroutine test_cylindrical_step_formula

    subroutine test_free_molecular_single_cell(n_failed)
        integer, intent(inout) :: n_failed
        real :: re(2), ze(2), rate, area, total_expected
        logical :: active(1, 1)
        integer :: ft(4, 1, 1), ierr, n_completed, n_truncated
        real, allocatable :: n(:, :), ur(:, :), uz(:, :), fr(:, :), fz(:, :), bout(:, :, :)
        re = [1.0, 2.0]
        ze = [0.0, 1.0]
        active = .true.
        ft = J01_FACE_WALL
        ft(J01_Z_LO, 1, 1) = J01_FACE_OPEN
        ft(J01_Z_HI, 1, 1) = J01_FACE_OPEN
        call sub_J01_free_molecular_mc_2Drz(re, ze, 1.0, active, ft, 1.0, 2.0, 1.0, &
            1.0, 1.0, 2.0, 3.0, 0.0, 200, 100, 17, n, ur, uz, fr, fz, bout, rate, &
            n_completed, n_truncated, ierr)
        write(*, '(a,3i8)') 'STATUS: FM ierr/completed/truncated: ', ierr, n_completed, n_truncated
        write(*, '(a,3es24.15)') 'VALUE: FM density/axial velocity/history rate: ', n(1,1), uz(1,1), rate
        area = 0.5*(re(2)**2-re(1)**2)
        total_expected = 200.0*rate
        call truth(ierr == J01_SUCCESS, 'FM single-cell solver returns success', n_failed)
        call truth(n_completed == 200 .and. n_truncated == 0, &
            'FM histories leave through an open face without truncation', n_failed)
        call close(bout(J01_Z_HI, 1, 1)*area, total_expected, &
            1.0e-12*max(total_expected, 1.0), 'FM inlet/outlet particle-rate conservation', n_failed)
        call truth(n(1, 1) > 0.0 .and. uz(1, 1) > 0.0, &
            'FM residence estimator returns positive density and axial velocity', n_failed)
    end subroutine test_free_molecular_single_cell

    subroutine test_input_errors(n_failed)
        integer, intent(inout) :: n_failed
        logical :: active(1, 1)
        integer :: ft(4, 1, 1), ierr
        real :: n(1, 1), ur(1, 1), uz(1, 1), bin(4, 1, 1)
        real, allocatable :: fr(:, :), fz(:, :), bout(:, :, :)
        active = .true.
        ft = J01_FACE_WALL
        n = -1.0
        ur = 0.0
        uz = 0.0
        bin = 0.0
        call sub_J01_build_faceflux_2Drz(active, ft, n, ur, uz, bin, fr, fz, bout, ierr)
        write(*, '(a,2i8)') 'STATUS: negative density actual/expected: ', ierr, J01_ERR_NEGATIVE_INPUT
        call truth(ierr == J01_ERR_NEGATIVE_INPUT, 'negative density returns a specific error', n_failed)
    end subroutine test_input_errors
end program test_J01_faceflux_2Drz_units
