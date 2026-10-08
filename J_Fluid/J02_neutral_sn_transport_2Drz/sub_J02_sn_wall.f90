!> Wall physics: thermal shape, specular direction map, and diffuse flux normalization.
!> The transport iteration consumes these values but does not define the wall model.
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
        if (.not. any(wall_shape > 0.0)) ierr = SN_ERR_WALL_NORMALIZATION
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
                        if (denominator <= tiny(1.0)) then
                            ierr = SN_ERR_WALL_NORMALIZATION
                            return
                        end if
                        diffuse_constant(f, i, k) = max(numerator/denominator, 0.0)
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
                            if (m0 <= tiny(1.0)) then
                                ierr = SN_ERR_WALL_NORMALIZATION
                                return
                            end if
                            diffuse_constant(f, i, k) = max(numerator/m0, 0.0)
                        end if
                    end if
                end do
            end do
        end do
    end subroutine sub_J02_compute_diffuse_wall_constants

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
