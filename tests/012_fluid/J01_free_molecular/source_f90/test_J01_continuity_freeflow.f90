program test_J01_continuity_freeflow

    use mod_J01_continuity_freeflow
    implicit none

! J01 updates lo-1:hi, while lo-2 and hi+1 are guard layers.  Unequal
! bounds in x/y/z make accidental direction swaps visible to the tests.
    integer, parameter :: lo(3) = (/1, 2, 3/)
    integer, parameter :: hi(3) = (/4, 6, 5/)
    integer, parameter :: ax0 = lo(1)-1, ax1 = hi(1)
    integer, parameter :: ay0 = lo(2)-1, ay1 = hi(2)
    integer, parameter :: az0 = lo(3)-1, az1 = hi(3)
    real, parameter :: tol = 1.0e-12

    integer :: n_failed
    real :: max_abs_error

    n_failed = 0
    max_abs_error = 0.0

    write(*, '(A)') '=== J01 continuity free-flow tests ==='

! Keep fast algebraic and contract tests in one executable so run.sh can
! act as a simple CI entry point with a single nonzero failure status.
    call test_zero_velocity_identity()
    call test_source_sign()
    call test_single_step_reference()
    call test_unit_shifts()
    call test_periodic_mass_conservation()

    write(*, '(A,1PE12.4)') 'max_abs_error = ', max_abs_error
    write(*, '(A,I0)') 'n_failed      = ', n_failed

    if (n_failed == 0) then
        write(*, '(A)') 'RESULT: PASS'
    else
        write(*, '(A)') 'RESULT: FAIL'
        stop 1
    end if

contains

    subroutine test_zero_velocity_identity()
        implicit none
        real :: n(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: n_before(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: n0(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: s(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: ux(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: uy(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: uz(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        integer :: before

! With no transport and no source, both active cells and guards must be
! unchanged; n0 must still receive an exact copy of the incoming state.
        before = n_failed
        call fill_density_pattern(n, 2.0)
        n_before = n
        n0 = -huge(1.0)
        s = 0.0
        ux = 0.0
        uy = 0.0
        uz = 0.0

        call invoke_j01(n, s, ux, uy, uz, n0)

        call check_array('zero velocity: n', n, n_before, tol)
        call check_array('zero velocity: n0', n0, n_before, 0.0)
        call report_case('zero velocity and zero source identity', before)
    end subroutine test_zero_velocity_identity


    subroutine test_source_sign()
        implicit none
        real :: n(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: n_before(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: n_ref(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: n0(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: s(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: ux(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: uy(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: uz(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        integer :: i, j, k, before

! The current implementation names s a source but subtracts it.  This test
! records that existing API behavior explicitly so a sign change is never
! introduced silently.
        before = n_failed
        call fill_density_pattern(n, 3.0)
        n_before = n
        n_ref = n
        s = 0.0
        ux = 0.0
        uy = 0.0
        uz = 0.0

        do k = az0, az1
            do j = ay0, ay1
                do i = ax0, ax1
                    s(i, j, k) = 0.002*real(2*i-j+3*k) + 0.015
                    n_ref(i, j, k) = n_before(i, j, k) - s(i, j, k)
                end do
            end do
        end do

        call invoke_j01(n, s, ux, uy, uz, n0)

        call check_array('source sign: n', n, n_ref, tol)
        call check_array('source sign: n0', n0, n_before, 0.0)
        call check_guard_cells('source sign: guards', n, n_before, 0.0)
        call report_case('source convention n_new = n_old - s', before)
    end subroutine test_source_sign


    subroutine test_single_step_reference()
        implicit none
        real :: n(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: n_before(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: n_ref(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: n0(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: s(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: ux(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: uy(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: uz(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        integer :: i, j, k, before

! Use spatially varying data in every direction.  The reference routine
! evaluates left/right face fluxes directly instead of reusing J01 work
! arrays, which helps expose a shifted face or mixed-up direction.
        before = n_failed
        call fill_density_pattern(n, 4.0)
        n_before = n

        do k = lo(3)-2, hi(3)+1
            do j = lo(2)-2, hi(2)+1
                do i = lo(1)-2, hi(1)+1
                    ux(i, j, k) = 0.13 + 0.009*real(i) - 0.004*real(j)
                    uy(i, j, k) = -0.11 + 0.005*real(j) + 0.002*real(k)
                    uz(i, j, k) = 0.07 - 0.003*real(i) + 0.006*real(k)
                    s(i, j, k) = 0.001*real(i-2*j+k)
                end do
            end do
        end do

        call reference_step(n_before, s, ux, uy, uz, n_ref)
        call invoke_j01(n, s, ux, uy, uz, n0)

        call check_array('single step: n', n, n_ref, tol)
        call check_array('single step: n0', n0, n_before, 0.0)
        call check_guard_cells('single step: guards', n, n_before, 0.0)
        call report_case('deterministic 3D single-step formula', before)
    end subroutine test_single_step_reference


    subroutine test_unit_shifts()
        implicit none
        integer :: axis, sgn, before
        character(len = 64) :: label

! For |u|=1 the local Lax-Friedrichs flux reduces exactly to first-order
! upwinding: positive velocity copies i-1 and negative velocity copies i+1
! (and analogously in y/z).
        do axis = 1, 3
            do sgn = -1, 1, 2
                before = n_failed
                call run_unit_shift(axis, sgn)
                write(label, '(A,I0,A,I0)') 'unit cell shift: axis=', axis, ', sign=', sgn
                call report_case(trim(label), before)
            end do
        end do
    end subroutine test_unit_shifts


    subroutine run_unit_shift(axis, sgn)
        implicit none
        integer, intent(in) :: axis, sgn
        real :: n(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: n_before(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: n_ref(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: n0(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: s(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: ux(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: uy(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: uz(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        integer :: i, j, k, ii, jj, kk

! A sentinel outside the active region makes unintended guard writes easy
! to distinguish from valid transported density values.
        n = -9999.0
        do k = az0, az1
            do j = ay0, ay1
                do i = ax0, ax1
                    n(i, j, k) = 10.0 + real(i) + 0.1*real(j) + 0.01*real(k)
                end do
            end do
        end do
        call set_periodic_ghosts(n)
        n_before = n
        n_ref = n

        s = 0.0
        ux = 0.0
        uy = 0.0
        uz = 0.0
        select case (axis)
          case (1)
            ux = real(sgn)
          case (2)
            uy = real(sgn)
          case (3)
            uz = real(sgn)
        end select

        do k = az0, az1
            do j = ay0, ay1
                do i = ax0, ax1
                    ii = i
                    jj = j
                    kk = k
                    select case (axis)
                      case (1)
                        ii = i-sgn
                        if (ii < ax0) ii = ax1
                        if (ii > ax1) ii = ax0
                      case (2)
                        jj = j-sgn
                        if (jj < ay0) jj = ay1
                        if (jj > ay1) jj = ay0
                      case (3)
                        kk = k-sgn
                        if (kk < az0) kk = az1
                        if (kk > az1) kk = az0
                    end select
                    n_ref(i, j, k) = n_before(ii, jj, kk)
                end do
            end do
        end do

        call invoke_j01(n, s, ux, uy, uz, n0)

        call check_array('unit shift: n', n, n_ref, tol)
        call check_array('unit shift: n0', n0, n_before, 0.0)
        call check_guard_cells('unit shift: guards', n, n_before, 0.0)
    end subroutine run_unit_shift


    subroutine test_periodic_mass_conservation()
        implicit none
        real :: n(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: n_before(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: n0(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: s(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: ux(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: uy(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: uz(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: mass_before, mass_after
        integer :: i, j, k, before

! With matching periodic boundary-face fluxes, the discrete divergence
! telescopes and the active-domain density sum must remain constant.
        before = n_failed
        n = -7777.0
        do k = az0, az1
            do j = ay0, ay1
                do i = ax0, ax1
                    n(i, j, k) = 2.0 + 0.08*sin(0.7*real(i)) &
                        + 0.05*cos(0.4*real(j)) + 0.03*sin(0.9*real(k))
                end do
            end do
        end do
        call set_periodic_ghosts(n)
        n_before = n

        s = 0.0
        ux = 0.12
        uy = -0.17
        uz = 0.09
        mass_before = sum(n(ax0:ax1, ay0:ay1, az0:az1))

        call invoke_j01(n, s, ux, uy, uz, n0)

        mass_after = sum(n(ax0:ax1, ay0:ay1, az0:az1))
        write(*, '(a,4es24.15)') 'VALUE: periodic mass actual/reference/error/limit: ', &
            mass_after, mass_before, abs(mass_after-mass_before), tol*max(1.0,abs(mass_before))
        call check_close('periodic mass', mass_after, mass_before, &
            tol*max(1.0, abs(mass_before)))
        call check_array('periodic mass: n0', n0, n_before, 0.0)
        call check_guard_cells('periodic mass: guards', n, n_before, 0.0)
        call report_case('periodic zero-source total-density conservation', before)
    end subroutine test_periodic_mass_conservation


    subroutine invoke_j01(n, s, ux, uy, uz, n0)
        implicit none
        real, intent(inout) :: n(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(inout) :: s(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(inout) :: ux(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(inout) :: uy(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(inout) :: uz(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(out) :: n0(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        integer :: il_arg(3), iu_arg(3)

! The production dummy indices currently have no INTENT.  Pass writable
! local copies rather than named constants so this test remains standard
! conforming even if the compiler treats such dummies as definable.
        il_arg = lo
        iu_arg = hi
        call sub_J01_continuity_freeflow(il_arg, iu_arg, n, s, ux, uy, uz, n0)
    end subroutine invoke_j01


    subroutine reference_step(n_old, s, ux, uy, uz, n_new)
        implicit none
        real, intent(in) :: n_old(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(in) :: s(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(in) :: ux(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(in) :: uy(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(in) :: uz(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(out) :: n_new(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real :: flux_right, flux_left
        integer :: i, j, k

! Independent pointwise reference: calculate both faces of each cell and
! preserve every location outside the documented lo-1:hi update region.
        n_new = n_old
        do k = az0, az1
            do j = ay0, ay1
                do i = ax0, ax1
                    flux_right = rusanov(n_old(i, j, k), n_old(i+1, j, k), &
                        ux(i, j, k), ux(i+1, j, k))
                    flux_left = rusanov(n_old(i-1, j, k), n_old(i, j, k), &
                        ux(i-1, j, k), ux(i, j, k))
                    n_new(i, j, k) = n_new(i, j, k) - (flux_right-flux_left)

                    flux_right = rusanov(n_old(i, j, k), n_old(i, j+1, k), &
                        uy(i, j, k), uy(i, j+1, k))
                    flux_left = rusanov(n_old(i, j-1, k), n_old(i, j, k), &
                        uy(i, j-1, k), uy(i, j, k))
                    n_new(i, j, k) = n_new(i, j, k) - (flux_right-flux_left)

                    flux_right = rusanov(n_old(i, j, k), n_old(i, j, k+1), &
                        uz(i, j, k), uz(i, j, k+1))
                    flux_left = rusanov(n_old(i, j, k-1), n_old(i, j, k), &
                        uz(i, j, k-1), uz(i, j, k))
                    n_new(i, j, k) = n_new(i, j, k) - (flux_right-flux_left) - s(i, j, k)
                end do
            end do
        end do
    end subroutine reference_step


    real function rusanov(n_left, n_right, u_left, u_right)
        implicit none
        real, intent(in) :: n_left, n_right, u_left, u_right
        real :: alpha

        alpha = max(abs(u_left), abs(u_right))
        rusanov = 0.5*(u_left*n_left + u_right*n_right) &
            - 0.5*alpha*(n_right-n_left)
    end function rusanov


    subroutine fill_density_pattern(a, offset)
        implicit none
        real, intent(out) :: a(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(in) :: offset
        integer :: i, j, k

        do k = lo(3)-2, hi(3)+1
            do j = lo(2)-2, hi(2)+1
                do i = lo(1)-2, hi(1)+1
                    a(i, j, k) = offset + 0.11*real(i) - 0.07*real(j) &
                        + 0.03*real(k) + 0.001*real(i*j*k)
                end do
            end do
        end do
    end subroutine fill_density_pattern


    subroutine set_periodic_ghosts(a)
        implicit none
        real, intent(inout) :: a(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        integer :: i, j, k

! Only the face-adjacent ghost planes enter a single J01 update.  Matching
! each lower exterior state to the opposite active edge makes the two
! boundary fluxes identical and closes the periodic finite-volume domain.
        do k = az0, az1
            do j = ay0, ay1
                a(ax0-1, j, k) = a(ax1, j, k)
                a(ax1+1, j, k) = a(ax0, j, k)
            end do
        end do

        do k = az0, az1
            do i = ax0, ax1
                a(i, ay0-1, k) = a(i, ay1, k)
                a(i, ay1+1, k) = a(i, ay0, k)
            end do
        end do

        do j = ay0, ay1
            do i = ax0, ax1
                a(i, j, az0-1) = a(i, j, az1)
                a(i, j, az1+1) = a(i, j, az0)
            end do
        end do
    end subroutine set_periodic_ghosts


    subroutine check_array(label, actual, expected, tolerance)
        implicit none
        character(len = *), intent(in) :: label
        real, intent(in) :: actual(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(in) :: expected(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(in) :: tolerance
        integer :: i, j, k
        character(len = 160) :: point_label

        do k = lo(3)-2, hi(3)+1
            do j = lo(2)-2, hi(2)+1
                do i = lo(1)-2, hi(1)+1
                    write(point_label, '(A,A,I0,A,I0,A,I0,A)') trim(label), ' (', i, ',', j, ',', k, ')'
                    call check_close(trim(point_label), actual(i, j, k), expected(i, j, k), tolerance)
                end do
            end do
        end do
        write(*, '(a,2es24.15)') 'METRIC: '//trim(label)//' max/limit: ', &
            maxval(abs(actual-expected)), tolerance
    end subroutine check_array


    subroutine check_guard_cells(label, actual, expected, tolerance)
        implicit none
        character(len = *), intent(in) :: label
        real, intent(in) :: actual(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(in) :: expected(lo(1)-2:hi(1)+1, lo(2)-2:hi(2)+1, lo(3)-2:hi(3)+1)
        real, intent(in) :: tolerance
        integer :: i, j, k
        character(len = 160) :: point_label

        do k = lo(3)-2, hi(3)+1
            do j = lo(2)-2, hi(2)+1
                do i = lo(1)-2, hi(1)+1
                    if (i < ax0 .or. i > ax1 .or. j < ay0 .or. j > ay1 .or. &
                        k < az0 .or. k > az1) then
                        write(point_label, '(A,A,I0,A,I0,A,I0,A)') trim(label), ' (', i, ',', j, ',', k, ')'
                        call check_close(trim(point_label), actual(i, j, k), expected(i, j, k), tolerance)
                    end if
                end do
            end do
        end do
    end subroutine check_guard_cells


    subroutine check_close(label, actual, expected, tolerance)
        implicit none
        character(len = *), intent(in) :: label
        real, intent(in) :: actual, expected, tolerance
        real :: error

! Limit detailed diagnostics to the first failures while retaining the
! complete failure count and global maximum error for the final summary.
        error = abs(actual-expected)
        max_abs_error = max(max_abs_error, error)
        if (error > tolerance) then
            n_failed = n_failed + 1
            if (n_failed <= 20) then
                write(*, '(A,A,A,1PE16.8,A,1PE16.8,A,1PE12.4)') &
                    '  FAIL: ', trim(label), ', expected=', expected, &
                    ', actual=', actual, ', abs_error=', error
            end if
        end if
    end subroutine check_close


    subroutine report_case(name, before)
        implicit none
        character(len = *), intent(in) :: name
        integer, intent(in) :: before

        if (n_failed == before) then
            write(*, '(A,A)') 'PASS: ', trim(name)
        else
            write(*, '(A,A,A,I0)') 'FAIL: ', trim(name), ', new failures=', n_failed-before
        end if
    end subroutine report_case

end program test_J01_continuity_freeflow
