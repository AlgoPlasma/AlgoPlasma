!> Local P1-DG operators for the cylindrical r-z streaming equation.

    subroutine sub_J02_add_self_face_matrix(a, face_id, s, rc, hr, hz)
        real, intent(inout) :: a(3, 3)
        integer, intent(in) :: face_id
        real, intent(in) :: s, rc, hr, hz
        real :: c, c0, c1, c11

        select case (face_id)
          case (SN_R_LO)
            c = s*hz*(rc-hr)
            a(1, 1) = a(1, 1)+2*c
            a(1, 2) = a(1, 2)-2*c
            a(2, 1) = a(2, 1)-2*c
            a(2, 2) = a(2, 2)+2*c
            a(3, 3) = a(3, 3)+(2.0/3.0)*c
          case (SN_R_HI)
            c = s*hz*(rc+hr)
            a(1, 1) = a(1, 1)+2*c
            a(1, 2) = a(1, 2)+2*c
            a(2, 1) = a(2, 1)+2*c
            a(2, 2) = a(2, 2)+2*c
            a(3, 3) = a(3, 3)+(2.0/3.0)*c
          case default
            c0 = s*hr*(2*rc)
            c1 = s*hr*((2.0/3.0)*hr)
            c11 = s*hr*((2.0/3.0)*rc)
            a(1, 1) = a(1, 1)+c0
            a(1, 2) = a(1, 2)+c1
            a(2, 1) = a(2, 1)+c1
            a(2, 2) = a(2, 2)+c11
            if (face_id == SN_Z_LO) then
                a(1, 3) = a(1, 3)-c0
                a(2, 3) = a(2, 3)-c1
                a(3, 1) = a(3, 1)-c0
                a(3, 2) = a(3, 2)-c1
            else
                a(1, 3) = a(1, 3)+c0
                a(2, 3) = a(2, 3)+c1
                a(3, 1) = a(3, 1)+c0
                a(3, 2) = a(3, 2)+c1
            end if
            a(3, 3) = a(3, 3)+c0
        end select
    end subroutine sub_J02_add_self_face_matrix

    subroutine sub_J02_add_neighbor_rhs(rhs, face_id, s, coeff_up, rc, hr, hz)
        real, intent(inout) :: rhs(3)
        integer, intent(in) :: face_id
        real, intent(in) :: s, coeff_up(3), rc, hr, hz
        real :: c, c0, c1, c11, t

        select case (face_id)
          case (SN_R_LO)
            c = s*hz*(rc-hr)
            t = coeff_up(1)+coeff_up(2)
            rhs(1) = rhs(1)+2*c*t
            rhs(2) = rhs(2)-2*c*t
            rhs(3) = rhs(3)+(2.0/3.0)*c*coeff_up(3)
          case (SN_R_HI)
            c = s*hz*(rc+hr)
            t = coeff_up(1)-coeff_up(2)
            rhs(1) = rhs(1)+2*c*t
            rhs(2) = rhs(2)+2*c*t
            rhs(3) = rhs(3)+(2.0/3.0)*c*coeff_up(3)
          case default
            c0 = s*hr*(2*rc)
            c1 = s*hr*((2.0/3.0)*hr)
            c11 = s*hr*((2.0/3.0)*rc)
            if (face_id == SN_Z_LO) then
                rhs(1) = rhs(1)+c0*coeff_up(1)+c1*coeff_up(2)+c0*coeff_up(3)
                rhs(2) = rhs(2)+c1*coeff_up(1)+c11*coeff_up(2)+c1*coeff_up(3)
                rhs(3) = rhs(3)-c0*coeff_up(1)-c1*coeff_up(2)-c0*coeff_up(3)
            else
                rhs(1) = rhs(1)+c0*coeff_up(1)+c1*coeff_up(2)-c0*coeff_up(3)
                rhs(2) = rhs(2)+c1*coeff_up(1)+c11*coeff_up(2)-c1*coeff_up(3)
                rhs(3) = rhs(3)+c0*coeff_up(1)+c1*coeff_up(2)-c0*coeff_up(3)
            end if
        end select
    end subroutine sub_J02_add_neighbor_rhs

    subroutine sub_J02_add_constant_rhs(rhs, face_id, s, g, rc, hr, hz)
        real, intent(inout) :: rhs(3)
        integer, intent(in) :: face_id
        real, intent(in) :: s, g, rc, hr, hz
        real :: c

        select case (face_id)
          case (SN_R_LO)
            c = s*hz*(rc-hr)*g
            rhs(1) = rhs(1)+2*c
            rhs(2) = rhs(2)-2*c
          case (SN_R_HI)
            c = s*hz*(rc+hr)*g
            rhs(1) = rhs(1)+2*c
            rhs(2) = rhs(2)+2*c
          case (SN_Z_LO)
            rhs(1) = rhs(1)+s*hr*g*(2*rc)
            rhs(2) = rhs(2)+s*hr*g*((2.0/3.0)*hr)
            rhs(3) = rhs(3)-s*hr*g*(2*rc)
          case default
            rhs(1) = rhs(1)+s*hr*g*(2*rc)
            rhs(2) = rhs(2)+s*hr*g*((2.0/3.0)*hr)
            rhs(3) = rhs(3)+s*hr*g*(2*rc)
        end select
    end subroutine sub_J02_add_constant_rhs

    subroutine sub_J02_zface_interval_moments(rc, hr, xi_lo, xi_hi, m0, m1, m2)
        real, intent(in) :: rc, hr, xi_lo, xi_hi
        real, intent(out) :: m0, m1, m2
        real :: d1, d2, d3, d4
        if (xi_hi <= xi_lo) then
            m0 = 0.0
            m1 = 0.0
            m2 = 0.0
            return
        end if
        d1 = xi_hi-xi_lo
        d2 = xi_hi**2-xi_lo**2
        d3 = xi_hi**3-xi_lo**3
        d4 = xi_hi**4-xi_lo**4
        m0 = hr*(rc*d1+0.5*hr*d2)
        m1 = hr*(0.5*rc*d2+(hr/3.0)*d3)
        m2 = hr*((rc/3.0)*d3+0.25*hr*d4)
    end subroutine sub_J02_zface_interval_moments

    subroutine sub_J02_add_zface_constant_interval_rhs(rhs, s, g, zeta, xi_lo, xi_hi, rc, hr)
        real, intent(inout) :: rhs(3)
        real, intent(in) :: s, g, zeta, xi_lo, xi_hi, rc, hr
        real :: m0, m1, m2
        call sub_J02_zface_interval_moments(rc, hr, xi_lo, xi_hi, m0, m1, m2)
        rhs(1) = rhs(1)+s*g*m0
        rhs(2) = rhs(2)+s*g*m1
        rhs(3) = rhs(3)+s*g*zeta*m0
    end subroutine sub_J02_add_zface_constant_interval_rhs

    subroutine sub_J02_add_zface_coeff_interval_rhs(rhs, s, coeff, zeta, xi_lo, xi_hi, rc, hr)
        real, intent(inout) :: rhs(3)
        real, intent(in) :: s, coeff(3), zeta, xi_lo, xi_hi, rc, hr
        real :: m0, m1, m2, t0, t1
        call sub_J02_zface_interval_moments(rc, hr, xi_lo, xi_hi, m0, m1, m2)
        t0 = coeff(1)+zeta*coeff(3)
        t1 = coeff(2)
        rhs(1) = rhs(1)+s*(t0*m0+t1*m1)
        rhs(2) = rhs(2)+s*(t0*m1+t1*m2)
        rhs(3) = rhs(3)+s*zeta*(t0*m0+t1*m1)
    end subroutine sub_J02_add_zface_coeff_interval_rhs

    real function fun_J02_zface_coeff_interval_integral(coeff, zeta, xi_lo, xi_hi, rc, hr)
        real, intent(in) :: coeff(3), zeta, xi_lo, xi_hi, rc, hr
        real :: m0, m1, m2
        call sub_J02_zface_interval_moments(rc, hr, xi_lo, xi_hi, m0, m1, m2)
        fun_J02_zface_coeff_interval_integral = (coeff(1)+zeta*coeff(3))*m0+coeff(2)*m1
    end function fun_J02_zface_coeff_interval_integral

    subroutine sub_J02_add_specular_rhs(rhs, face_id, s, coeff_reflected, rc, hr, hz)
        real, intent(inout) :: rhs(3)
        integer, intent(in) :: face_id
        real, intent(in) :: s, coeff_reflected(3), rc, hr, hz
        real :: face_matrix(3, 3)
        face_matrix = 0.0
        call sub_J02_add_self_face_matrix(face_matrix, face_id, s, rc, hr, hz)
        rhs = rhs+matmul(face_matrix, coeff_reflected)
    end subroutine sub_J02_add_specular_rhs

    subroutine sub_J02_add_volume_matrix(a, mu, eta, rc, hr, hz)
        real, intent(inout) :: a(3, 3)
        real, intent(in) :: mu, eta, rc, hr, hz
        a(2, 1) = a(2, 1)-4*mu*rc*hz
        a(2, 2) = a(2, 2)-(4.0/3.0)*mu*hr*hz
        a(3, 1) = a(3, 1)-4*eta*rc*hr
        a(3, 2) = a(3, 2)-(4.0/3.0)*eta*hr*hr
    end subroutine sub_J02_add_volume_matrix

    subroutine sub_J02_add_absorption_matrix(a, sigma, rc, hr, hz)
        real, intent(inout) :: a(3, 3)
        real, intent(in) :: sigma, rc, hr, hz
        if (sigma <= 0.0) return
        a(1, 1) = a(1, 1)+sigma*4*rc*hr*hz
        a(1, 2) = a(1, 2)+sigma*(4.0/3.0)*hr*hr*hz
        a(2, 1) = a(2, 1)+sigma*(4.0/3.0)*hr*hr*hz
        a(2, 2) = a(2, 2)+sigma*(4.0/3.0)*rc*hr*hz
        a(3, 3) = a(3, 3)+sigma*(4.0/3.0)*rc*hr*hz
    end subroutine sub_J02_add_absorption_matrix

    ! Preserve the constant-test-function balance, not the uncorrected P1 mean.
    ! A P0 fallback is used only when the P1 polynomial is negative at a corner.
    subroutine sub_J02_enforce_local_positivity(a, rhs, coeff, ierr, corrected)
        use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
        real, intent(in) :: a(3, 3), rhs(3)
        real, intent(inout) :: coeff(3)
        integer, intent(out) :: ierr
        logical, intent(out), optional :: corrected

        ierr = SN_SUCCESS
        if (present(corrected)) corrected = .false.
        if (.not. all(ieee_is_finite(a)) .or. .not. all(ieee_is_finite(rhs)) .or. &
            .not. all(ieee_is_finite(coeff))) then
            ierr = SN_ERR_LOCAL_POSITIVITY
            return
        end if
        ! Negative incoming particle rate cannot be repaired conservatively here.
        if (a(1, 1) <= 0.0 .or. rhs(1) < 0.0) then
            ierr = SN_ERR_LOCAL_POSITIVITY
            return
        end if
        if (coeff(1) >= abs(coeff(2))+abs(coeff(3))) return
        coeff(1) = rhs(1)/a(1, 1)
        coeff(2:3) = 0.0
        if (.not. ieee_is_finite(coeff(1))) then
            ierr = SN_ERR_LOCAL_POSITIVITY
            return
        end if
        if (present(corrected)) corrected = .true.
    end subroutine sub_J02_enforce_local_positivity

    subroutine sub_J02_solve_local_3x3(a, b, x, ierr)
        real, intent(in) :: a(3, 3), b(3)
        real, intent(out) :: x(3)
        integer, intent(out) :: ierr
        real :: m(3, 3), rhs(3), row_tmp(3), scalar_tmp, factor, pivot_abs
        integer :: col, row, pivot

        m = a
        rhs = b
        ierr = SN_SUCCESS
        do col = 1, 3
            pivot = col
            pivot_abs = abs(m(col, col))
            do row = col+1, 3
                if (abs(m(row, col)) > pivot_abs) then
                    pivot = row
                    pivot_abs = abs(m(row, col))
                end if
            end do
            if (pivot_abs <= 100.0*tiny(1.0)) then
                ierr = SN_ERR_LOCAL_SINGULAR
                x = 0.0
                return
            end if
            if (pivot /= col) then
                row_tmp = m(col, :)
                m(col, :) = m(pivot, :)
                m(pivot, :) = row_tmp
                scalar_tmp = rhs(col)
                rhs(col) = rhs(pivot)
                rhs(pivot) = scalar_tmp
            end if
            do row = col+1, 3
                factor = m(row, col)/m(col, col)
                m(row, col:3) = m(row, col:3)-factor*m(col, col:3)
                rhs(row) = rhs(row)-factor*rhs(col)
            end do
        end do
        do row = 3, 1, -1
            x(row) = (rhs(row)-dot_product(m(row, row+1:3), x(row+1:3)))/m(row, row)
        end do
    end subroutine sub_J02_solve_local_3x3
