!> Cell moments and internal face fluxes reconstructed from the angular field.

    subroutine sub_J02_reconstruct_cell_moments(mesh, geometry, quadrature, psi, &
        density, velocity_r, velocity_z, ierr)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: psi(:, :, :, :)
        real, allocatable, intent(out) :: density(:, :), velocity_r(:, :), velocity_z(:, :)
        integer, intent(out) :: ierr
        integer :: i, k, m
        real :: psi_mean, momentum_r, momentum_z

        ierr = SN_SUCCESS
        if (size(psi, 1) /= 3 .or. size(psi, 2) /= mesh%nr .or. &
            size(psi, 3) /= mesh%nz .or. size(psi, 4) /= quadrature%n_dir) then
            ierr = SN_ERR_RECONSTRUCTION_PSI_SHAPE
            return
        end if
        allocate(density(mesh%nr, mesh%nz), velocity_r(mesh%nr, mesh%nz), &
            velocity_z(mesh%nr, mesh%nz))
        density = 0.0
        velocity_r = 0.0
        velocity_z = 0.0
        do k = 1, mesh%nz
            do i = 1, mesh%nr
                if (.not. mesh%active(i, k)) cycle
                momentum_r = 0.0
                momentum_z = 0.0
                do m = 1, quadrature%n_dir
                    psi_mean = psi(1, i, k, m)+geometry%xi_bar(i)*psi(2, i, k, m)
                    density(i, k) = density(i, k)+quadrature%weight(m)*psi_mean
                    momentum_r = momentum_r+quadrature%weight(m)*quadrature%speed(m)* &
                        quadrature%mu(m)*psi_mean
                    momentum_z = momentum_z+quadrature%weight(m)*quadrature%speed(m)* &
                        quadrature%eta(m)*psi_mean
                end do
                if (density(i, k) > tiny(1.0)) then
                    velocity_r(i, k) = momentum_r/density(i, k)
                    velocity_z(i, k) = momentum_z/density(i, k)
                end if
            end do
        end do
    end subroutine sub_J02_reconstruct_cell_moments

    subroutine sub_J02_reconstruct_internal_face_fluxes(mesh, geometry, quadrature, &
        psi, flux_r, flux_z, ierr)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: psi(:, :, :, :)
        real, allocatable, intent(out) :: flux_r(:, :), flux_z(:, :)
        integer, intent(out) :: ierr
        integer :: i, k, m
        real :: trace

        ierr = SN_SUCCESS
        if (size(psi, 1) /= 3 .or. size(psi, 2) /= mesh%nr .or. &
            size(psi, 3) /= mesh%nz .or. size(psi, 4) /= quadrature%n_dir) then
            ierr = SN_ERR_RECONSTRUCTION_PSI_SHAPE
            return
        end if
        allocate(flux_r(max(mesh%nr-1, 0), mesh%nz))
        allocate(flux_z(mesh%nr, max(mesh%nz-1, 0)))
        flux_r = 0.0
        flux_z = 0.0

        do k = 1, mesh%nz
            do i = 1, mesh%nr-1
                if (.not. (mesh%active(i, k) .and. mesh%active(i+1, k))) cycle
                do m = 1, quadrature%n_dir
                    if (quadrature%mu(m) > 0.0) then
                        trace = psi(1, i, k, m)+psi(2, i, k, m)
                    else
                        trace = psi(1, i+1, k, m)-psi(2, i+1, k, m)
                    end if
                    flux_r(i, k) = flux_r(i, k)+quadrature%weight(m)*quadrature%speed(m)* &
                        quadrature%mu(m)*trace
                end do
            end do
        end do
        do k = 1, mesh%nz-1
            do i = 1, mesh%nr
                if (.not. (mesh%active(i, k) .and. mesh%active(i, k+1))) cycle
                do m = 1, quadrature%n_dir
                    if (quadrature%eta(m) > 0.0) then
                        trace = psi(1, i, k, m)+geometry%xi_bar(i)*psi(2, i, k, m)+psi(3, i, k, m)
                    else
                        trace = psi(1, i, k+1, m)+geometry%xi_bar(i)*psi(2, i, k+1, m)- &
                            psi(3, i, k+1, m)
                    end if
                    flux_z(i, k) = flux_z(i, k)+quadrature%weight(m)*quadrature%speed(m)* &
                        quadrature%eta(m)*trace
                end do
            end do
        end do
    end subroutine sub_J02_reconstruct_internal_face_fluxes

    subroutine sub_J02_reconstruct_open_boundary_fluxes(mesh, geometry, boundary, &
        quadrature, psi, prescribed_inflow, inflow_flux, outflow_flux, ierr, &
        zlo_source_xi_lo, zlo_source_xi_hi, zlo_inflow)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_boundary_2drz_type), intent(in) :: boundary
        type(sn_quadrature_type), intent(in) :: quadrature
        real, intent(in) :: psi(:, :, :, :)
        real, intent(in), optional :: prescribed_inflow(:, :, :, :), zlo_inflow(:)
        real, allocatable, intent(out) :: inflow_flux(:, :, :), outflow_flux(:, :, :)
        integer, intent(out) :: ierr
        real, intent(in), optional :: zlo_source_xi_lo(:), zlo_source_xi_hi(:)
        integer :: i, k, m, face_type
        real :: ndot, component, trace, m0, m1, m2, full_m0, area_fraction
        logical :: partial

        ierr = SN_SUCCESS
        if (size(psi, 1) /= 3 .or. size(psi, 2) /= mesh%nr .or. &
            size(psi, 3) /= mesh%nz .or. size(psi, 4) /= quadrature%n_dir) then
            ierr = SN_ERR_RECONSTRUCTION_PSI_SHAPE
            return
        end if
        if (present(prescribed_inflow)) then
            if (size(prescribed_inflow, 1) /= SN_N_FACES .or. &
                size(prescribed_inflow, 2) /= mesh%nr .or. &
                size(prescribed_inflow, 3) /= mesh%nz .or. &
                size(prescribed_inflow, 4) /= quadrature%n_dir) then
                ierr = SN_ERR_RECONSTRUCTION_BOUNDARY_SHAPE
                return
            end if
        end if
        if (present(zlo_inflow)) then
            if (size(zlo_inflow) /= quadrature%n_dir) then
                ierr = SN_ERR_RECONSTRUCTION_BOUNDARY_SHAPE
                return
            end if
        end if
        if (.not. fun_J02_boundary_is_valid(mesh, boundary)) then
            ierr = SN_ERR_BOUNDARY_SHAPE
            return
        end if
        partial = present(zlo_source_xi_lo) .and. present(zlo_source_xi_hi)
        if (present(zlo_source_xi_lo).neqv.present(zlo_source_xi_hi)) then
            ierr = SN_ERR_PARTIAL_INLET
            return
        end if
        if (partial) then
            if (size(zlo_source_xi_lo) /= mesh%nr .or. size(zlo_source_xi_hi) /= mesh%nr .or. &
                any(zlo_source_xi_lo < -1.0) .or. any(zlo_source_xi_hi > 1.0) .or. &
                any(zlo_source_xi_lo > zlo_source_xi_hi)) then
                ierr = SN_ERR_PARTIAL_INLET
                return
            end if
        end if
        allocate(inflow_flux(SN_N_FACES, mesh%nr, mesh%nz), &
            outflow_flux(SN_N_FACES, mesh%nr, mesh%nz))
        inflow_flux = 0.0
        outflow_flux = 0.0
        do k = 1, mesh%nz
            do i = 1, mesh%nr
                if (.not. mesh%active(i, k)) cycle
                do face_type = SN_R_LO, SN_Z_HI
                    if (fun_J02_face_type(boundary, face_type, i, k) /= SN_FACE_OPEN) cycle
                    do m = 1, quadrature%n_dir
                        select case (face_type)
                          case (SN_R_LO)
                            ndot = -quadrature%mu(m)
                            component = quadrature%mu(m)
                            trace = psi(1, i, k, m)-psi(2, i, k, m)
                          case (SN_R_HI)
                            ndot = quadrature%mu(m)
                            component = quadrature%mu(m)
                            trace = psi(1, i, k, m)+psi(2, i, k, m)
                          case (SN_Z_LO)
                            ndot = -quadrature%eta(m)
                            component = quadrature%eta(m)
                            trace = psi(1, i, k, m)+geometry%xi_bar(i)*psi(2, i, k, m)-psi(3, i, k, m)
                          case (SN_Z_HI)
                            ndot = quadrature%eta(m)
                            component = quadrature%eta(m)
                            trace = psi(1, i, k, m)+geometry%xi_bar(i)*psi(2, i, k, m)+psi(3, i, k, m)
                        end select
                        area_fraction = 1.0
                        if (partial .and. face_type == SN_Z_LO .and. k == 1) then
                            call sub_J02_zface_interval_moments(geometry%rc(i), &
                                geometry%hr(i), zlo_source_xi_lo(i), &
                                zlo_source_xi_hi(i), m0, m1, m2)
                            full_m0 = 2.0*geometry%rc(i)*geometry%hr(i)
                            area_fraction = m0/full_m0
                            if (ndot > 0.0) trace = ((psi(1, i, k, m)-psi(3, i, k, m))*m0+ &
                                psi(2, i, k, m)*m1)/full_m0
                        end if
                        if (ndot < 0.0) then
                            inflow_flux(face_type, i, k) = inflow_flux(face_type, i, k)+ &
                                quadrature%weight(m)*quadrature%speed(m)*component* &
                                fun_prescribed_value(face_type, i, k, m)*area_fraction
                        else if (ndot > 0.0) then
                            outflow_flux(face_type, i, k) = outflow_flux(face_type, i, k)+ &
                                quadrature%weight(m)*quadrature%speed(m)*component*trace
                        end if
                    end do
                end do
            end do
        end do
    contains
        real function fun_prescribed_value(face_id, cell_i, cell_k, direction)
            integer, intent(in) :: face_id, cell_i, cell_k, direction
            fun_prescribed_value = 0.0
            if (present(prescribed_inflow)) then
                fun_prescribed_value = prescribed_inflow(face_id, cell_i, cell_k, direction)
            else if (present(zlo_inflow) .and. face_id == SN_Z_LO .and. cell_k == 1) then
                fun_prescribed_value = zlo_inflow(direction)
            end if
        end function fun_prescribed_value
    end subroutine sub_J02_reconstruct_open_boundary_fluxes
