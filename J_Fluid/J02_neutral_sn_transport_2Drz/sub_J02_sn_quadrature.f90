!> Angular and speed-group quadrature for two-dimensional velocity space.

    subroutine sub_J02_build_angular_nodes(n_angles, scheme, mu, eta, weight, ierr)
        integer, intent(in) :: n_angles
        character(len = *), intent(in) :: scheme
        real, allocatable, intent(out) :: mu(:), eta(:), weight(:)
        integer, intent(out) :: ierr
        integer :: a
        real :: pi, theta

        ierr = SN_SUCCESS
        if (n_angles < 8 .or. mod(n_angles, 4) /= 0) then
            ierr = SN_ERR_ANGLE_COUNT
            return
        end if
        allocate(mu(n_angles), eta(n_angles), weight(n_angles))
        pi = acos(-1.0)

        select case (trim(scheme))
          case ('midpoint', 'gauss-chebyshev')
! The full-circle Gauss-Chebyshev rule has exactly these midpoint
! nodes and equal weights; the second name is a documented alias.
            do a = 1, n_angles
                theta = 2.0*pi*(real(a)-0.5)/real(n_angles)
                mu(a) = cos(theta)
                eta(a) = sin(theta)
                weight(a) = 2.0*pi/real(n_angles)
            end do
          case default
            ierr = SN_ERR_ANGLE_SCHEME
            deallocate(mu, eta, weight)
        end select
    end subroutine sub_J02_build_angular_nodes

    subroutine sub_J02_build_speed_groups(n_speeds, speed_max, speed, weight, ierr)
        integer, intent(in) :: n_speeds
        real, intent(in) :: speed_max
        real, allocatable, intent(out) :: speed(:), weight(:)
        integer, intent(out) :: ierr
        integer :: g
        real :: vlo, vhi, dv

        ierr = SN_SUCCESS
        if (n_speeds < 1) then
            ierr = SN_ERR_SPEED_COUNT
            return
        end if
        if (speed_max <= 0.0) then
            ierr = SN_ERR_SPEED_MAX
            return
        end if
        allocate(speed(n_speeds), weight(n_speeds))
        dv = speed_max/real(n_speeds)
        do g = 1, n_speeds
            vlo = real(g-1)*dv
            vhi = real(g)*dv
            speed(g) = 0.5*(vlo+vhi)
            weight(g) = 0.5*(vhi*vhi-vlo*vlo)
        end do
    end subroutine sub_J02_build_speed_groups

    subroutine sub_J02_build_phase_quadrature(n_angles, n_speeds, angular_scheme, &
        speed_max, quadrature, ierr)
        integer, intent(in) :: n_angles, n_speeds
        character(len = *), intent(in) :: angular_scheme
        real, intent(in) :: speed_max
        type(sn_quadrature_type), intent(out) :: quadrature
        integer, intent(out) :: ierr
        real, allocatable :: mu_a(:), eta_a(:), wa(:), speed_g(:), wg(:)
        integer :: a, g, m

        call sub_J02_build_angular_nodes(n_angles, angular_scheme, mu_a, eta_a, wa, ierr)
        if (ierr /= 0) return
        call sub_J02_build_speed_groups(n_speeds, speed_max, speed_g, wg, ierr)
        if (ierr /= 0) return

        quadrature%n_angles = n_angles
        quadrature%n_speeds = n_speeds
        quadrature%n_dir = n_angles*n_speeds
        quadrature%speed_max = speed_max
        allocate(quadrature%mu(quadrature%n_dir), quadrature%eta(quadrature%n_dir))
        allocate(quadrature%speed(quadrature%n_dir), quadrature%weight(quadrature%n_dir))
        do g = 1, n_speeds
            do a = 1, n_angles
                m = (g-1)*n_angles+a
                quadrature%mu(m) = mu_a(a)
                quadrature%eta(m) = eta_a(a)
                quadrature%speed(m) = speed_g(g)
                quadrature%weight(m) = wg(g)*wa(a)
            end do
        end do
        ierr = SN_SUCCESS
    end subroutine sub_J02_build_phase_quadrature
