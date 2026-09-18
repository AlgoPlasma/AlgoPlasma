!> Reflecting-wall source iteration and partial z-low inlet support.

    subroutine sub_J02_build_partial_zlo_inlet(mesh, r_min, r_max, face_fraction, &
        xi_lo, xi_hi, ierr)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        real, intent(in) :: r_min, r_max
        real, allocatable, intent(out) :: face_fraction(:), xi_lo(:), xi_hi(:)
        integer, intent(out) :: ierr
        integer :: i
        real :: lo, hi, rc, hr, full_area, overlap_area
        ierr = SN_SUCCESS
        if (.not. allocated(mesh%r_edge) .or. .not. allocated(mesh%active) .or. &
            mesh%nr < 1 .or. mesh%nz < 1) then
            ierr = SN_ERR_GEOMETRY_MESH
            return
        end if
        if (r_min >= r_max .or. r_min < mesh%r_edge(1) .or. &
            r_max > mesh%r_edge(mesh%nr+1)) then
            ierr = SN_ERR_PARTIAL_INLET
            return
        end if
        allocate(face_fraction(mesh%nr), xi_lo(mesh%nr), xi_hi(mesh%nr))
        face_fraction = 0.0
        xi_lo = 0.0
        xi_hi = 0.0
        do i = 1, mesh%nr
            if (.not. mesh%active(i, 1)) cycle
            lo = max(mesh%r_edge(i), r_min)
            hi = min(mesh%r_edge(i+1), r_max)
            if (hi <= lo) cycle
            rc = 0.5*(mesh%r_edge(i)+mesh%r_edge(i+1))
            hr = 0.5*(mesh%r_edge(i+1)-mesh%r_edge(i))
            full_area = 0.5*(mesh%r_edge(i+1)**2-mesh%r_edge(i)**2)
            overlap_area = 0.5*(hi**2-lo**2)
            face_fraction(i) = overlap_area/full_area
            xi_lo(i) = max(-1.0, min(1.0, (lo-rc)/hr))
            xi_hi(i) = max(-1.0, min(1.0, (hi-rc)/hr))
        end do
        if (maxval(face_fraction) <= 0.0) then
            ierr = SN_ERR_PARTIAL_INLET
            deallocate(face_fraction, xi_lo, xi_hi)
        end if
    end subroutine sub_J02_build_partial_zlo_inlet

    subroutine sub_J02_build_wall_maxwell_shape(quadrature, temperature, particle_mass, &
        wall_shape, ierr)
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: temperature, particle_mass
        real, allocatable, intent(out) :: wall_shape(:)
        integer, intent(out) :: ierr
        real, parameter :: boltzmann_constant = 1.380649e-23
        real :: sigma_squared
        ierr = SN_SUCCESS
        if (.not. fun_J02_quadrature_is_valid(quadrature)) then
            ierr = SN_ERR_QUADRATURE_LAYOUT
            return
        end if
        if (temperature <= 0.0) then
            ierr = SN_ERR_SOURCE_TEMPERATURE
            return
        end if
        if (particle_mass <= 0.0) then
            ierr = SN_ERR_SOURCE_MASS
            return
        end if
        sigma_squared = boltzmann_constant*temperature/particle_mass
        allocate(wall_shape(quadrature%n_dir))
        wall_shape = exp(-0.5*quadrature%speed**2/sigma_squared)
    end subroutine sub_J02_build_wall_maxwell_shape

    integer function fun_J02_reflected_direction_index(quadrature, direction, normal_r, normal_z)
        type(sn_quadrature_type), intent(in) :: quadrature
        integer, intent(in) :: direction
        real, intent(in) :: normal_r, normal_z
        integer :: q, first, last
        real :: dot, mu_reflected, eta_reflected, score, best_score
        dot = quadrature%mu(direction)*normal_r+quadrature%eta(direction)*normal_z
        mu_reflected = quadrature%mu(direction)-2.0*dot*normal_r
        eta_reflected = quadrature%eta(direction)-2.0*dot*normal_z
        first = ((direction-1)/quadrature%n_angles)*quadrature%n_angles+1
        last = first+quadrature%n_angles-1
        fun_J02_reflected_direction_index = first
        best_score = -huge(1.0)
        do q = first, last
            score = quadrature%mu(q)*mu_reflected+quadrature%eta(q)*eta_reflected
            if (score > best_score) then
                best_score = score
                fun_J02_reflected_direction_index = q
            end if
        end do
    end function fun_J02_reflected_direction_index

    subroutine sub_J02_compute_diffuse_wall_constants(mesh, geometry, quadrature, boundary, &
        wall_shape, psi_old, diffuse_constant, ierr, zlo_source_xi_lo, zlo_source_xi_hi)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_quadrature_type), intent(in) :: quadrature
        type(sn_boundary_2drz_type), intent(in) :: boundary
        real, intent(in) :: wall_shape(:), psi_old(:, :, :, :)
        real, allocatable, intent(out) :: diffuse_constant(:, :, :)
        integer, intent(out) :: ierr
        real, intent(in), optional :: zlo_source_xi_lo(:), zlo_source_xi_hi(:)
        integer :: i, k, f, m
        real :: nr, nz, ndot, numerator, denominator, trace, m0, m1, m2
        logical :: partial
        ierr = SN_SUCCESS
        partial = present(zlo_source_xi_lo) .and. present(zlo_source_xi_hi)
        if (.not. fun_J02_geometry_is_valid(mesh, geometry)) then
            ierr = SN_ERR_SWEEP_GEOMETRY_SHAPE
            return
        end if
        if (.not. fun_J02_reflection_inputs_valid(mesh, quadrature, boundary, wall_shape, &
            psi_old, zlo_source_xi_lo, zlo_source_xi_hi)) then
            ierr = SN_ERR_REFLECTION_INPUT
            return
        end if
        allocate(diffuse_constant(SN_N_FACES, mesh%nr, mesh%nz))
        diffuse_constant = 0.0
        do k = 1, mesh%nz
            do i = 1, mesh%nr
                if (.not. mesh%active(i, k)) cycle
                do f = SN_R_LO, SN_Z_HI
                    if (fun_J02_face_type(boundary, f, i, k) == SN_FACE_WALL) then
                        call fun_face_normal(f, nr, nz)
                        numerator = 0.0
                        denominator = 0.0
                        do m = 1, quadrature%n_dir
                            ndot = quadrature%mu(m)*nr+quadrature%eta(m)*nz
                            if (ndot > 0.0) then
                                trace = fun_face_trace(psi_old(:, i, k, m), f, geometry%xi_bar(i))
                                numerator = numerator+quadrature%weight(m)*quadrature%speed(m)* &
                                    ndot*trace
                            else if (ndot < 0.0) then
                                denominator = denominator+quadrature%weight(m)* &
                                    quadrature%speed(m)*(-ndot)*wall_shape(m)
                            end if
                        end do
                        if (denominator > 0.0) diffuse_constant(f, i, k) = &
                            max(numerator/denominator, 0.0)
                    else if (partial .and. f == SN_Z_LO .and. k == 1 .and. &
                        fun_J02_face_type(boundary, f, i, k) == SN_FACE_OPEN) then
                        call sub_J02_zface_interval_moments(geometry%rc(i), geometry%hr(i), &
                            -1.0, zlo_source_xi_lo(i), m0, m1, m2)
                        denominator = m0
                        call sub_J02_zface_interval_moments(geometry%rc(i), geometry%hr(i), &
                            zlo_source_xi_hi(i), 1.0, m0, m1, m2)
                        denominator = denominator+m0
                        numerator = 0.0
                        if (denominator > 0.0) then
                            do m = 1, quadrature%n_dir
                                ndot = -quadrature%eta(m)
                                if (ndot > 0.0) then
                                    trace = fun_J02_zface_coeff_interval_integral( &
                                        psi_old(:, i, k, m), -1.0, -1.0, zlo_source_xi_lo(i), &
                                        geometry%rc(i), geometry%hr(i))
                                    trace = trace+fun_J02_zface_coeff_interval_integral( &
                                        psi_old(:, i, k, m), -1.0, zlo_source_xi_hi(i), 1.0, &
                                        geometry%rc(i), geometry%hr(i))
                                    numerator = numerator+quadrature%weight(m)* &
                                        quadrature%speed(m)*ndot*trace
                                end if
                            end do
                            m0 = 0.0
                            do m = 1, quadrature%n_dir
                                ndot = -quadrature%eta(m)
                                if (ndot < 0.0) m0 = m0+quadrature%weight(m)* &
                                    quadrature%speed(m)*(-ndot)*wall_shape(m)*denominator
                            end do
                            if (m0 > 0.0) diffuse_constant(f, i, k) = max(numerator/m0, 0.0)
                        end if
                    end if
                end do
            end do
        end do
    end subroutine sub_J02_compute_diffuse_wall_constants

    subroutine sub_J02_sweep_reflecting(mesh, geometry, quadrature, sigma_t, boundary_inflow, &
        boundary, wall_shape, diffuse_fraction, psi_old, psi, ierr, failed_direction, &
        failed_i, failed_k, zlo_source_xi_lo, zlo_source_xi_hi, zlo_inflow, &
        progress_interval)
        use iso_fortran_env, only:output_unit
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: sigma_t(:, :, :), wall_shape(:)
        real, intent(in), optional :: boundary_inflow(:, :, :, :), zlo_inflow(:)
        type(sn_boundary_2drz_type), intent(in) :: boundary
        real, intent(in) :: diffuse_fraction, psi_old(:, :, :, :)
        real, allocatable, intent(out) :: psi(:, :, :, :)
        integer, intent(out) :: ierr
        integer, intent(out), optional :: failed_direction, failed_i, failed_k
        integer, intent(in), optional :: progress_interval
        real, intent(in), optional :: zlo_source_xi_lo(:), zlo_source_xi_hi(:)
        real, allocatable :: diffuse(:, :, :)
        integer :: m, i, k, i0, i1, di, k0, k1, dk, solve_ierr, progress_every
        real :: mu, eta, rc, hr, hz, a(3, 3), rhs(3), coeff(3)
        logical :: partial
        ierr = SN_SUCCESS
        partial = present(zlo_source_xi_lo) .and. present(zlo_source_xi_hi)
        progress_every = 0
        if (present(progress_interval)) progress_every = progress_interval
        if (present(failed_direction)) failed_direction = 0
        if (present(failed_i)) failed_i = 0
        if (present(failed_k)) failed_k = 0
        if (.not. fun_J02_quadrature_is_valid(quadrature)) then
            ierr = SN_ERR_QUADRATURE_LAYOUT
            return
        end if
        if (.not. fun_J02_geometry_is_valid(mesh, geometry)) then
            ierr = SN_ERR_SWEEP_GEOMETRY_SHAPE
            return
        end if
        if (diffuse_fraction < 0.0 .or. diffuse_fraction > 1.0 .or. progress_every < 0 .or. &
            size(sigma_t, 1) /= mesh%nr .or. size(sigma_t, 2) /= mesh%nz .or. &
            size(sigma_t, 3) /= quadrature%n_dir .or. any(sigma_t < 0.0)) then
            ierr = SN_ERR_REFLECTION_INPUT
            return
        end if
        if (present(boundary_inflow)) then
            if (size(boundary_inflow, 1) /= SN_N_FACES .or. &
                size(boundary_inflow, 2) /= mesh%nr .or. &
                size(boundary_inflow, 3) /= mesh%nz .or. &
                size(boundary_inflow, 4) /= quadrature%n_dir) then
                ierr = SN_ERR_REFLECTION_INPUT
                return
            end if
        end if
        if (present(zlo_inflow)) then
            if (size(zlo_inflow) /= quadrature%n_dir) then
                ierr = SN_ERR_REFLECTION_INPUT
                return
            end if
        end if
        call sub_J02_compute_diffuse_wall_constants(mesh, geometry, quadrature, boundary, &
            wall_shape, psi_old, diffuse, ierr, zlo_source_xi_lo, zlo_source_xi_hi)
        if (ierr /= SN_SUCCESS) return
        allocate(psi(3, mesh%nr, mesh%nz, quadrature%n_dir))
        psi = 0.0
        do m = 1, quadrature%n_dir
            mu = quadrature%mu(m)
            eta = quadrature%eta(m)
            if (mu >= 0.0) then
                i0 = 1
                i1 = mesh%nr
                di = 1
            else
                i0 = mesh%nr
                i1 = 1
                di = -1
            end if
            if (eta >= 0.0) then
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
                    call add_face(SN_R_LO, -mu, i-1, k)
                    if (ierr /= SN_SUCCESS) exit
                    call add_face(SN_R_HI, mu, i+1, k)
                    if (ierr /= SN_SUCCESS) exit
                    call add_face(SN_Z_LO, -eta, i, k-1)
                    if (ierr /= SN_SUCCESS) exit
                    call add_face(SN_Z_HI, eta, i, k+1)
                    if (ierr /= SN_SUCCESS) exit
                    call sub_J02_add_volume_matrix(a, mu, eta, rc, hr, hz)
                    call sub_J02_add_absorption_matrix(a, sigma_t(i, k, m), rc, hr, hz)
                    call sub_J02_solve_local_3x3(a, rhs, coeff, solve_ierr)
                    if (solve_ierr /= SN_SUCCESS) then
                        ierr = SN_ERR_SWEEP_LOCAL_SOLVE
                        exit
                    end if
                    call sub_J02_enforce_local_positivity(a, rhs, coeff, ierr)
                    if (ierr /= SN_SUCCESS) exit
                    psi(:, i, k, m) = coeff
                end do
                if (ierr /= SN_SUCCESS) exit
            end do
            if (ierr /= SN_SUCCESS) then
                if (present(failed_direction)) failed_direction = m
                if (present(failed_i)) failed_i = i
                if (present(failed_k)) failed_k = k
                return
            end if
            if (progress_every > 0) then
                if (m == 1 .or. mod(m, progress_every) == 0 .or. m == quadrature%n_dir) then
                    write(output_unit, '(a,i0,a,i0)') '[J02] angular direction ', m, '/', &
                        quadrature%n_dir
                    flush(output_unit)
                end if
            end if
        end do
    contains
        subroutine add_face(face_id, outward_dot, neighbor_i, neighbor_k)
            integer, intent(in) :: face_id, neighbor_i, neighbor_k
            real, intent(in) :: outward_dot
            integer :: kind, q
            real :: s, nr, nz, spec(3), diff(3)
            logical :: neighbor_active
            if (outward_dot > 0.0) then
                call sub_J02_add_self_face_matrix(a, face_id, outward_dot, rc, hr, hz)
                return
            else if (outward_dot >= 0.0) then
                return
            end if
            s = -outward_dot
            kind = fun_J02_face_type(boundary, face_id, i, k)
            neighbor_active = neighbor_i >= 1 .and. neighbor_i <= mesh%nr .and. &
                neighbor_k >= 1 .and. neighbor_k <= mesh%nz
            if (neighbor_active) neighbor_active = mesh%active(neighbor_i, neighbor_k)
            if (kind == SN_FACE_INTERIOR) then
                if (.not. neighbor_active) then
                    ierr = SN_ERR_SWEEP_FACE_TOPOLOGY
                    return
                end if
                call sub_J02_add_neighbor_rhs(rhs, face_id, s, &
                    psi(:, neighbor_i, neighbor_k, m), rc, hr, hz)
            else if (kind == SN_FACE_OPEN) then
                if (partial .and. face_id == SN_Z_LO .and. k == 1) then
                    call sub_J02_add_zface_constant_interval_rhs(rhs, s, &
                        fun_boundary_value(face_id, i, k, m), -1.0, zlo_source_xi_lo(i), &
                        zlo_source_xi_hi(i), rc, hr)
                    q = fun_J02_reflected_direction_index(quadrature, m, 0.0, -1.0)
                    spec = 0.0
                    diff = 0.0
                    call add_zlo_complement_coeff(spec, s, psi_old(:, i, k, q))
                    call add_zlo_complement_constant(diff, s, diffuse(face_id, i, k)*wall_shape(m))
                    rhs = rhs+(1.0-diffuse_fraction)*spec+diffuse_fraction*diff
                else
                    call sub_J02_add_constant_rhs(rhs, face_id, s, &
                        fun_boundary_value(face_id, i, k, m), rc, hr, hz)
                end if
            else if (kind == SN_FACE_WALL) then
                call fun_face_normal(face_id, nr, nz)
                q = fun_J02_reflected_direction_index(quadrature, m, nr, nz)
                spec = 0.0
                diff = 0.0
                call sub_J02_add_specular_rhs(spec, face_id, s, psi_old(:, i, k, q), rc, hr, hz)
                call sub_J02_add_constant_rhs(diff, face_id, s, &
                    diffuse(face_id, i, k)*wall_shape(m), rc, hr, hz)
                rhs = rhs+(1.0-diffuse_fraction)*spec+diffuse_fraction*diff
            else
                ierr = SN_ERR_SWEEP_FACE_TOPOLOGY
            end if
        end subroutine add_face

        subroutine add_zlo_complement_coeff(vector, s, coefficient)
            real, intent(inout) :: vector(3)
            real, intent(in) :: s, coefficient(3)
            call sub_J02_add_zface_coeff_interval_rhs(vector, s, coefficient, -1.0, &
                -1.0, zlo_source_xi_lo(i), rc, hr)
            call sub_J02_add_zface_coeff_interval_rhs(vector, s, coefficient, -1.0, &
                zlo_source_xi_hi(i), 1.0, rc, hr)
        end subroutine add_zlo_complement_coeff

        subroutine add_zlo_complement_constant(vector, s, value)
            real, intent(inout) :: vector(3)
            real, intent(in) :: s, value
            call sub_J02_add_zface_constant_interval_rhs(vector, s, value, -1.0, &
                -1.0, zlo_source_xi_lo(i), rc, hr)
            call sub_J02_add_zface_constant_interval_rhs(vector, s, value, -1.0, &
                zlo_source_xi_hi(i), 1.0, rc, hr)
        end subroutine add_zlo_complement_constant

        real function fun_boundary_value(face_id, cell_i, cell_k, direction)
            integer, intent(in) :: face_id, cell_i, cell_k, direction
            fun_boundary_value = 0.0
            if (present(boundary_inflow)) then
                fun_boundary_value = boundary_inflow(face_id, cell_i, cell_k, direction)
            else if (present(zlo_inflow) .and. face_id == SN_Z_LO .and. cell_k == 1) then
                fun_boundary_value = zlo_inflow(direction)
            end if
        end function fun_boundary_value
    end subroutine sub_J02_sweep_reflecting

    subroutine sub_J02_solve_source_iteration(mesh, geometry, quadrature, sigma_t, &
        boundary_inflow, boundary, wall_shape, diffuse_fraction, max_iterations, tolerance, &
        psi, converged, iterations, final_relative_change, ierr, failed_direction, failed_i, &
        failed_k, zlo_source_xi_lo, zlo_source_xi_hi, zlo_inflow, progress_interval)
        use iso_fortran_env, only:output_unit
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: sigma_t(:, :, :), wall_shape(:)
        real, intent(in), optional :: boundary_inflow(:, :, :, :), zlo_inflow(:)
        type(sn_boundary_2drz_type), intent(in) :: boundary
        real, intent(in) :: diffuse_fraction, tolerance
        integer, intent(in) :: max_iterations
        real, allocatable, intent(out) :: psi(:, :, :, :)
        logical, intent(out) :: converged
        integer, intent(out) :: iterations, ierr
        real, intent(out) :: final_relative_change
        integer, intent(out), optional :: failed_direction, failed_i, failed_k
        integer, intent(in), optional :: progress_interval
        real, intent(in), optional :: zlo_source_xi_lo(:), zlo_source_xi_hi(:)
        real, allocatable :: psi_old(:, :, :, :), psi_new(:, :, :, :)
        real :: difference, base
        integer :: fd, fi, fk, progress_every, direction_progress
        ierr = SN_SUCCESS
        converged = .false.
        iterations = 0
        final_relative_change = huge(1.0)
        fd = 0
        fi = 0
        fk = 0
        progress_every = 0
        if (present(progress_interval)) progress_every = progress_interval
        direction_progress = 0
        if (progress_every > 0) direction_progress = 800
        if (max_iterations < 2 .or. tolerance <= 0.0 .or. progress_every < 0) then
            ierr = SN_ERR_SOURCE_ITERATION_OPTIONS
            return
        end if
        allocate(psi_old(3, mesh%nr, mesh%nz, quadrature%n_dir))
        psi_old = 0.0
        do iterations = 1, max_iterations
            call sub_J02_sweep_reflecting(mesh, geometry, quadrature, sigma_t, boundary_inflow, &
                boundary, wall_shape, diffuse_fraction, psi_old, psi_new, ierr, fd, fi, fk, &
                zlo_source_xi_lo, zlo_source_xi_hi, zlo_inflow, direction_progress)
            if (ierr /= SN_SUCCESS) exit
            difference = sum(abs(psi_new-psi_old))
            base = sum(abs(psi_old))
            final_relative_change = difference/max(base, 1.0)
            call move_alloc(psi_new, psi_old)
            if (progress_every > 0) then
                if (iterations == 1 .or. mod(iterations, progress_every) == 0) then
                    write(output_unit, '(a,i0,a,i0,a,es12.4)') '[J02] source iteration ', &
                        iterations, '/', max_iterations, ', relative change=', &
                        final_relative_change
                    flush(output_unit)
                end if
            end if
            if (iterations >= 2 .and. final_relative_change <= tolerance) then
                converged = .true.
                exit
            end if
        end do
        if (ierr == SN_SUCCESS .and. .not. converged) ierr = SN_ERR_SOURCE_ITERATION_NOT_CONVERGED
        call move_alloc(psi_old, psi)
        if (present(failed_direction)) failed_direction = fd
        if (present(failed_i)) failed_i = fi
        if (present(failed_k)) failed_k = fk
    end subroutine sub_J02_solve_source_iteration

    logical function fun_J02_reflection_inputs_valid(mesh, quadrature, boundary, wall_shape, &
        psi_old, zlo_source_xi_lo, zlo_source_xi_hi)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_quadrature_type), intent(in) :: quadrature
        type(sn_boundary_2drz_type), intent(in) :: boundary
        real, intent(in) :: wall_shape(:), psi_old(:, :, :, :)
        real, intent(in), optional :: zlo_source_xi_lo(:), zlo_source_xi_hi(:)
        logical :: has_lo, has_hi
        has_lo = present(zlo_source_xi_lo)
        has_hi = present(zlo_source_xi_hi)
        fun_J02_reflection_inputs_valid = fun_J02_boundary_is_valid(mesh, boundary) .and. &
            size(wall_shape) == quadrature%n_dir .and. all(wall_shape >= 0.0) .and. &
            size(psi_old, 1) == 3 .and. size(psi_old, 2) == mesh%nr .and. &
            size(psi_old, 3) == mesh%nz .and. size(psi_old, 4) == quadrature%n_dir .and. &
            (has_lo.eqv.has_hi)
        if (.not. fun_J02_reflection_inputs_valid .or. .not. has_lo) return
        fun_J02_reflection_inputs_valid = size(zlo_source_xi_lo) == mesh%nr .and. &
            size(zlo_source_xi_hi) == mesh%nr
        if (.not. fun_J02_reflection_inputs_valid) return
        fun_J02_reflection_inputs_valid = all(zlo_source_xi_lo >= -1.0) .and. &
            all(zlo_source_xi_hi <= 1.0) .and. all(zlo_source_xi_lo <= zlo_source_xi_hi)
    end function fun_J02_reflection_inputs_valid

    subroutine fun_face_normal(face_id, normal_r, normal_z)
        integer, intent(in) :: face_id
        real, intent(out) :: normal_r, normal_z
        normal_r = 0.0
        normal_z = 0.0
        select case (face_id)
          case (SN_R_LO)
            normal_r = -1.0
          case (SN_R_HI)
            normal_r = 1.0
          case (SN_Z_LO)
            normal_z = -1.0
          case (SN_Z_HI)
            normal_z = 1.0
        end select
    end subroutine fun_face_normal

    real function fun_face_trace(coeff, face_id, xi_bar)
        real, intent(in) :: coeff(3), xi_bar
        integer, intent(in) :: face_id
        select case (face_id)
          case (SN_R_LO)
            fun_face_trace = coeff(1)-coeff(2)
          case (SN_R_HI)
            fun_face_trace = coeff(1)+coeff(2)
          case (SN_Z_LO)
            fun_face_trace = coeff(1)+xi_bar*coeff(2)-coeff(3)
          case default
            fun_face_trace = coeff(1)+xi_bar*coeff(2)+coeff(3)
        end select
    end function fun_face_trace
