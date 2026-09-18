!> Upwind directional sweeps for open-boundary P1-DG transport.

    subroutine sub_J02_sweep_all_directions(mesh, geometry, quadrature, sigma_t, &
        boundary_inflow, psi, ierr, failed_direction, failed_i, failed_k, boundary)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: sigma_t(:, :, :)
        real, intent(in) :: boundary_inflow(:, :, :, :)
        real, allocatable, intent(out) :: psi(:, :, :, :)
        integer, intent(out) :: ierr
        integer, intent(out), optional :: failed_direction, failed_i, failed_k
        type(sn_boundary_2drz_type), intent(in), optional :: boundary
        integer :: m, cell_i, cell_k

        ierr = SN_SUCCESS
        if (present(failed_direction)) failed_direction = 0
        if (present(failed_i)) failed_i = 0
        if (present(failed_k)) failed_k = 0
        if (.not. fun_J02_quadrature_is_valid(quadrature)) then
            ierr = SN_ERR_QUADRATURE_LAYOUT
            return
        end if
        if (size(sigma_t, 1) /= mesh%nr .or. size(sigma_t, 2) /= mesh%nz .or. &
            size(sigma_t, 3) /= quadrature%n_dir) then
            ierr = SN_ERR_SWEEP_SIGMA_SHAPE
            return
        end if
        if (any(sigma_t < 0.0)) then
            ierr = SN_ERR_SWEEP_NEGATIVE_SIGMA
            return
        end if
        if (size(boundary_inflow, 1) /= SN_N_FACES .or. &
            size(boundary_inflow, 2) /= mesh%nr .or. &
            size(boundary_inflow, 3) /= mesh%nz .or. &
            size(boundary_inflow, 4) /= quadrature%n_dir) then
            ierr = SN_ERR_SWEEP_BOUNDARY_SHAPE
            return
        end if
        if (.not. fun_J02_geometry_is_valid(mesh, geometry)) then
            ierr = SN_ERR_SWEEP_GEOMETRY_SHAPE
            return
        end if
        allocate(psi(3, mesh%nr, mesh%nz, quadrature%n_dir))
        psi = 0.0
        do m = 1, quadrature%n_dir
            call sub_J02_sweep_direction(mesh, geometry, quadrature, m, sigma_t(:, :, m), &
                boundary_inflow(:, :, :, m), psi(:, :, :, m), ierr, cell_i, cell_k, boundary)
            if (ierr /= SN_SUCCESS) then
                if (present(failed_direction)) failed_direction = m
                if (present(failed_i)) failed_i = cell_i
                if (present(failed_k)) failed_k = cell_k
                return
            end if
        end do
    end subroutine sub_J02_sweep_all_directions

    subroutine sub_J02_sweep_direction(mesh, geometry, quadrature, idir, sigma_t, &
        boundary_inflow, psi_direction, ierr, failed_i, failed_k, boundary)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_quadrature_type), intent(in) :: quadrature
        integer, intent(in) :: idir
        real, intent(in) :: sigma_t(:, :)
        real, intent(in) :: boundary_inflow(:, :, :)
        real, intent(out) :: psi_direction(:, :, :)
        integer, intent(out) :: ierr
        integer, intent(out), optional :: failed_i, failed_k
        type(sn_boundary_2drz_type), intent(in), optional :: boundary
        integer :: i, k, i0, i1, di, k0, k1, dk, solve_ierr
        real :: mu, eta, rc, hr, hz, ndot
        real :: a(3, 3), rhs(3), coeff(3)

        ierr = SN_SUCCESS
        psi_direction = 0.0
        if (present(failed_i)) failed_i = 0
        if (present(failed_k)) failed_k = 0
        if (.not. fun_J02_quadrature_is_valid(quadrature)) then
            ierr = SN_ERR_QUADRATURE_LAYOUT
            return
        end if
        if (idir < 1 .or. idir > quadrature%n_dir) then
            ierr = SN_ERR_SWEEP_DIRECTION
            return
        end if
        if (size(sigma_t, 1) /= mesh%nr .or. size(sigma_t, 2) /= mesh%nz) then
            ierr = SN_ERR_SWEEP_DIRECTION_SIGMA_SHAPE
            return
        end if
        if (any(sigma_t < 0.0)) then
            ierr = SN_ERR_SWEEP_NEGATIVE_SIGMA
            return
        end if
        if (size(boundary_inflow, 1) /= SN_N_FACES .or. &
            size(boundary_inflow, 2) /= mesh%nr .or. &
            size(boundary_inflow, 3) /= mesh%nz) then
            ierr = SN_ERR_SWEEP_DIRECTION_BOUNDARY_SHAPE
            return
        end if
        if (size(psi_direction, 1) /= 3 .or. size(psi_direction, 2) /= mesh%nr .or. &
            size(psi_direction, 3) /= mesh%nz) then
            ierr = SN_ERR_SWEEP_DIRECTION_PSI_SHAPE
            return
        end if
        if (.not. fun_J02_geometry_is_valid(mesh, geometry)) then
            ierr = SN_ERR_SWEEP_GEOMETRY_SHAPE
            return
        end if
        mu = quadrature%mu(idir)
        eta = quadrature%eta(idir)
        if (abs(mu) <= epsilon(mu) .or. abs(eta) <= epsilon(eta)) then
            ierr = SN_ERR_SWEEP_AXIS_DIRECTION
            return
        end if
        if (mu >= 0) then
            i0 = 1
            i1 = mesh%nr
            di = 1
        else
            i0 = mesh%nr
            i1 = 1
            di = -1
        end if
        if (eta >= 0) then
            k0 = 1
            k1 = mesh%nz
            dk = 1
        else
            k0 = mesh%nz
            k1 = 1
            dk = -1
        end if

        do i = i0, i1, di
            do k = k0, k1, dk
                if (.not. mesh%active(i, k)) cycle
                rc = geometry%rc(i)
                hr = geometry%hr(i)
                hz = geometry%hz(k)
                a = 0.0
                rhs = 0.0

                ndot = -mu
                call add_face(SN_R_LO, ndot, i-1, k)
                if (ierr /= SN_SUCCESS) return
                ndot = mu
                call add_face(SN_R_HI, ndot, i+1, k)
                if (ierr /= SN_SUCCESS) return
                ndot = -eta
                call add_face(SN_Z_LO, ndot, i, k-1)
                if (ierr /= SN_SUCCESS) return
                ndot = eta
                call add_face(SN_Z_HI, ndot, i, k+1)
                if (ierr /= SN_SUCCESS) return

                call sub_J02_add_volume_matrix(a, mu, eta, rc, hr, hz)
                call sub_J02_add_absorption_matrix(a, sigma_t(i, k), rc, hr, hz)
                call sub_J02_solve_local_3x3(a, rhs, coeff, solve_ierr)
                if (solve_ierr /= SN_SUCCESS) then
                    ierr = SN_ERR_SWEEP_LOCAL_SOLVE
                    if (present(failed_i)) failed_i = i
                    if (present(failed_k)) failed_k = k
                    return
                end if
                call sub_J02_enforce_local_positivity(a, rhs, coeff, ierr)
                if (ierr /= SN_SUCCESS) then
                    if (present(failed_i)) failed_i = i
                    if (present(failed_k)) failed_k = k
                    return
                end if
                psi_direction(:, i, k) = coeff
            end do
        end do

    contains

        subroutine add_face(face_id, outward_dot, neighbor_i, neighbor_k)
            integer, intent(in) :: face_id, neighbor_i, neighbor_k
            real, intent(in) :: outward_dot
            logical :: neighbor_active, use_neighbor
            integer :: boundary_kind

            boundary_kind = SN_FACE_OPEN
            if (present(boundary)) then
                if (.not. fun_J02_boundary_is_valid(mesh, boundary)) then
                    ierr = SN_ERR_BOUNDARY_SHAPE
                    return
                end if
                boundary_kind = fun_J02_face_type(boundary, face_id, i, k)
                if (boundary_kind == SN_FACE_WALL) then
                    ierr = SN_ERR_SWEEP_WALL_UNSUPPORTED
                    return
                end if
                if (boundary_kind /= SN_FACE_INTERIOR .and. &
                    boundary_kind /= SN_FACE_OPEN) then
                    ierr = SN_ERR_SWEEP_FACE_TOPOLOGY
                    return
                end if
            end if

            if (outward_dot > 0.0) then
                call sub_J02_add_self_face_matrix(a, face_id, outward_dot, rc, hr, hz)
            else if (outward_dot < 0.0) then
                neighbor_active = neighbor_i >= 1 .and. neighbor_i <= mesh%nr .and. &
                    neighbor_k >= 1 .and. neighbor_k <= mesh%nz
                if (neighbor_active) neighbor_active = mesh%active(neighbor_i, neighbor_k)
                use_neighbor = neighbor_active
                if (present(boundary)) then
                    if (boundary_kind == SN_FACE_INTERIOR .and. .not. neighbor_active) then
                        ierr = SN_ERR_SWEEP_FACE_TOPOLOGY
                        return
                    end if
                    use_neighbor = boundary_kind == SN_FACE_INTERIOR
                end if
                if (use_neighbor) then
                    call sub_J02_add_neighbor_rhs(rhs, face_id, -outward_dot, &
                        psi_direction(:, neighbor_i, neighbor_k), rc, hr, hz)
                else
                    call sub_J02_add_constant_rhs(rhs, face_id, -outward_dot, &
                        boundary_inflow(face_id, i, k), rc, hr, hz)
                end if
            end if
        end subroutine add_face

    end subroutine sub_J02_sweep_direction

    logical function fun_J02_geometry_is_valid(mesh, geometry)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry

        fun_J02_geometry_is_valid = mesh%nr > 0 .and. mesh%nz > 0 .and. &
            allocated(mesh%active)
        if (.not. fun_J02_geometry_is_valid) return
        fun_J02_geometry_is_valid = size(mesh%active, 1) == mesh%nr .and. &
            size(mesh%active, 2) == mesh%nz
        if (.not. fun_J02_geometry_is_valid) return
        fun_J02_geometry_is_valid = allocated(geometry%rc) .and. &
            allocated(geometry%hr) .and. allocated(geometry%hz) .and. &
            allocated(geometry%xi_bar)
        if (.not. fun_J02_geometry_is_valid) return
        fun_J02_geometry_is_valid = size(geometry%rc) == mesh%nr .and. &
            size(geometry%hr) == mesh%nr .and. size(geometry%hz) == mesh%nz .and. &
            size(geometry%xi_bar) == mesh%nr
    end function fun_J02_geometry_is_valid
