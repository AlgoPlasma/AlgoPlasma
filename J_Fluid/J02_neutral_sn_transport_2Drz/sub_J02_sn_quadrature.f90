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
        use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
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
        if (.not.ieee_is_finite(speed_max)) then
            ierr = SN_ERR_SPEED_MAX
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

    !> Explicit radial velocity bins on [0,speed_edge(end)], in m/s.
    !> Nodes are arithmetic midpoints; weights integrate v dv exactly per bin.
    !> Angular ordering and the reduced two-velocity model are unchanged.
    subroutine sub_J02_build_speed_groups_from_edges(speed_edge, speed, weight, ierr)
        use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
        real, intent(in) :: speed_edge(:)
        real, allocatable, intent(out) :: speed(:), weight(:)
        integer, intent(out) :: ierr
        integer :: n
        real, allocatable :: dv(:), group_speed(:), group_weight(:)

        ierr = SN_ERR_SPEED_EDGES
        n = size(speed_edge)-1
        if (n < 1) return
        if (.not.all(ieee_is_finite(speed_edge))) return
        if (abs(speed_edge(1)) > 0.0) return
        if (any(speed_edge(2:) <= speed_edge(:n))) return

        ! Midpoint form avoids cancellation of squared edges. Publish only valid bins.
        dv = speed_edge(2:)-speed_edge(:n)
        group_speed = speed_edge(:n)+0.5*dv
        ierr = SN_ERR_SPEED_RANGE
        if (any(group_speed <= 0.0)) return
        if (any(dv > huge(1.0)/max(1.0,group_speed))) return
        group_weight = dv*group_speed
        if (any(group_weight <= 0.0)) return
        call move_alloc(group_speed, speed)
        call move_alloc(group_weight, weight)
        ierr = SN_SUCCESS
    end subroutine sub_J02_build_speed_groups_from_edges

    !> Original uniform-grid interface; keeps its original nodes and arithmetic.
    subroutine sub_J02_build_phase_quadrature(n_angles, n_speeds, angular_scheme, &
        speed_max, quadrature, ierr)
        integer, intent(in) :: n_angles, n_speeds
        character(len = *), intent(in) :: angular_scheme
        real, intent(in) :: speed_max
        type(sn_quadrature_type), intent(out) :: quadrature
        integer, intent(out) :: ierr
        real, allocatable :: angular_mu(:), angular_eta(:), angular_weight(:), group_speed(:), group_weight(:)

        call sub_J02_build_angular_nodes(n_angles, angular_scheme, angular_mu, angular_eta, angular_weight, ierr)
        if (ierr /= SN_SUCCESS) return
        call sub_J02_build_speed_groups(n_speeds, speed_max, group_speed, group_weight, ierr)
        if (ierr /= SN_SUCCESS) return
        call sub_J02_combine_phase_quadrature(angular_mu, angular_eta, angular_weight, group_speed, group_weight, &
            speed_max, quadrature)
    end subroutine sub_J02_build_phase_quadrature

    !> Nonuniform-grid interface. Group count and cutoff are inferred from edges.
    !> All groups use the same angular rule, preserving specular reflection pairs.
    subroutine sub_J02_build_phase_quadrature_from_edges(n_angles, speed_edge, angular_scheme, quadrature, ierr)
        integer, intent(in) :: n_angles
        real, intent(in) :: speed_edge(:)
        character(len = *), intent(in) :: angular_scheme
        type(sn_quadrature_type), intent(out) :: quadrature
        integer, intent(out) :: ierr
        real, allocatable :: angular_mu(:), angular_eta(:), angular_weight(:), group_speed(:), group_weight(:)

        call sub_J02_build_angular_nodes(n_angles, angular_scheme, angular_mu, angular_eta, angular_weight, ierr)
        if (ierr /= SN_SUCCESS) return
        call sub_J02_build_speed_groups_from_edges(speed_edge, group_speed, group_weight, ierr)
        if (ierr /= SN_SUCCESS) return
        call sub_J02_combine_phase_quadrature(angular_mu, angular_eta, angular_weight, group_speed, group_weight, &
            speed_edge(size(speed_edge)), quadrature)
    end subroutine sub_J02_build_phase_quadrature_from_edges

    ! Internal tensor-product assembly shared by both public constructors.
    subroutine sub_J02_combine_phase_quadrature(angular_mu, angular_eta, angular_weight, group_speed, group_weight, &
        speed_max, quadrature)
        real, intent(in) :: angular_mu(:), angular_eta(:), angular_weight(:), group_speed(:), group_weight(:), speed_max
        type(sn_quadrature_type), intent(out) :: quadrature
        integer :: a, g, m, n_angles, n_speeds

        n_angles = size(angular_mu)
        n_speeds = size(group_speed)
        quadrature%n_angles = n_angles
        quadrature%n_speeds = n_speeds
        quadrature%n_dir = n_angles*n_speeds
        quadrature%speed_max = speed_max
        allocate(quadrature%mu(quadrature%n_dir), quadrature%eta(quadrature%n_dir))
        allocate(quadrature%speed(quadrature%n_dir), quadrature%weight(quadrature%n_dir))
        do g = 1, n_speeds
            do a = 1, n_angles
                m = (g-1)*n_angles+a
                quadrature%mu(m) = angular_mu(a)
                quadrature%eta(m) = angular_eta(a)
                quadrature%speed(m) = group_speed(g)
                quadrature%weight(m) = group_weight(g)*angular_weight(a)
            end do
        end do
    end subroutine sub_J02_combine_phase_quadrature
