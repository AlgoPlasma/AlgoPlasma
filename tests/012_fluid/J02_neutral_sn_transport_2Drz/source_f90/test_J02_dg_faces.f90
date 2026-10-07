! Independent Gauss integration of the public DG face operators.
program test_J02_dg_faces
    use mod_J02_neutral_sn_transport_2Drz
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
    implicit none
    integer :: failures = 0, face
    do face = SN_R_LO, SN_Z_HI
        call test_face(face)
    end do
    call test_linear_system()
    write(*,'(a,i0)') 'n_failed = ', failures
    if (failures /= 0) error stop 1
    write(*,'(a)') 'RESULT: PASS'
contains
    subroutine check(error, label)
        real, intent(in) :: error
        character(len=*), intent(in) :: label
        if (ieee_is_finite(error)) then
            if (error < 2.e-13) then
                write(*,'(a,es14.6)') 'PASS: '//label//' max error=', error
                return
            end if
        end if
        failures = failures+1
        write(*,'(a,es14.6)') 'FAIL: '//label//' max error=', error
    end subroutine check

    subroutine test_face(face)
        integer, intent(in) :: face
        real, parameter :: rc=3.0, hr=0.5, hz=0.25, beta=0.7, inlet=1.3
        real :: nodes(3), weights(3), phi(3), upstream(3), coefficients(3)
        real :: expected(3,3), expected_up(3), expected_in(3), a(3,3), b(3), c(3)
        real :: measure, side, trace
        integer :: q, row, col
        nodes = [-sqrt(3.0/5.0), 0.0, sqrt(3.0/5.0)]
        weights = [5.0/9.0, 8.0/9.0, 5.0/9.0]
        coefficients = [1.2, 0.3, -0.2]
        expected = 0.0
        expected_up = 0.0
        expected_in = 0.0
        side = 1.0
        if (face == SN_R_LO .or. face == SN_Z_LO) side = -1.0
        do q = 1, 3
            if (face == SN_R_LO .or. face == SN_R_HI) then
                phi = [1.0, side, nodes(q)]
                upstream = [1.0, -side, nodes(q)]
                measure = hz*(rc+side*hr)
            else
                phi = [1.0, nodes(q), side]
                upstream = [1.0, nodes(q), -side]
                measure = hr*(rc+hr*nodes(q))
            end if
            ! The neighbour is evaluated on the opposite face, not this face.
            trace = dot_product(coefficients, upstream)
            do row = 1, 3
                expected_in(row) = expected_in(row)+weights(q)*measure*beta*phi(row)*inlet
                expected_up(row) = expected_up(row)+weights(q)*measure*beta*phi(row)*trace
                do col = 1, 3
                    expected(row,col) = expected(row,col)+weights(q)*measure*beta*phi(row)*phi(col)
                end do
            end do
        end do
        ! Nonzero initial arrays detect overwrite instead of accumulation.
        a = 0.25
        b = 0.5
        c = -0.25
        call sub_J02_add_self_face_matrix(a, face, beta, rc, hr, hz)
        call sub_J02_add_neighbor_rhs(b, face, beta, coefficients, rc, hr, hz)
        call sub_J02_add_constant_rhs(c, face, beta, inlet, rc, hr, hz)
        write(*,'(a,i0)') 'face = ', face
        call check(maxval(abs(a-0.25-expected)), 'self-face integral and accumulation')
        call check(maxval(abs(b-0.5-expected_up)), 'opposite neighbour trace integral')
        call check(maxval(abs(c+0.25-expected_in)), 'constant inlet integral')
    end subroutine test_face

    subroutine test_linear_system()
        real :: a(3,3), b(3), x(3), saved(3,3)
        integer :: ierr
        ! Worked system with a zero leading pivot; exact solution (1,-2,3).
        a(1,:) = [0.0, 2.0, 1.0]
        a(2,:) = [1.0, -1.0, 0.0]
        a(3,:) = [2.0, 1.0, 3.0]
        b = [-1.0, 3.0, 9.0]
        saved = a
        call sub_J02_solve_local_3x3(a, b, x, ierr)
        if (ierr /= SN_SUCCESS) error stop 'valid pivoted system rejected'
        call check(maxval(abs(x-[1.0,-2.0,3.0])), 'pivoted local solution')
        call check(maxval(abs(a-saved))+maxval(abs(b-[-1.0,3.0,9.0])), 'local solve preserves inputs')
        a = 0.0
        call sub_J02_solve_local_3x3(a, b, x, ierr)
        if (ierr /= SN_ERR_LOCAL_SINGULAR) error stop 'singular local system accepted'
    end subroutine test_linear_system
end program test_J02_dg_faces
