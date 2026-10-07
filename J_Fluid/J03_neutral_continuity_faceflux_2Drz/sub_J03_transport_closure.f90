!> Build fixed face transport coefficients from reference density and signed fluxes.
!> Coefficients have velocity units but are not cell-mean particle velocities.
!> Initialization copies inputs; changing the caller's arrays later has no effect.

    subroutine sub_J03_initialize_transport_closure(active, face_type, volume, face_area, &
        density_ref, flux_r_ref, flux_z_ref, boundary_inflow_flux, &
        boundary_outflow_flux_ref, loss_frequency, density_floor_fraction, closure, ierr)
        logical, intent(in) :: active(:, :)
        integer, intent(in) :: face_type(:, :, :)
        real, intent(in) :: volume(:, :), face_area(:, :, :), density_ref(:, :), &
            flux_r_ref(:, :), flux_z_ref(:, :), boundary_inflow_flux(:, :, :), &
            boundary_outflow_flux_ref(:, :, :), loss_frequency(:, :), density_floor_fraction
        type(neutral_transport_closure_2drz_type), intent(out) :: closure
        integer, intent(out) :: ierr
        integer :: nr, nz, i, k, f, ni, nk, opposite
        integer, parameter :: di(4) = [-1, 1, 0, 0], dk(4) = [0, 0, -1, 1]
        integer, parameter :: opposing(4) = [2, 1, 4, 3]
        real :: area_scale
        real :: scale, floor, nup

        ierr = J03_SUCCESS
        nr = size(active, 1)
        nz = size(active, 2)
        if (density_floor_fraction <= 0.0) then
            ierr = J03_ERR_OPTIONS
            return
        end if
        ! Cell arrays, unique internal faces, and four per-cell boundary faces
        ! have distinct layouts. Check layouts before accessing any element.
        if (any(shape(face_type) /= [J03_N_FACES,nr,nz]) .or. &
            any(shape(volume) /= [nr,nz]) .or. any(shape(density_ref) /= [nr,nz]) .or. &
            any(shape(face_area) /= [J03_N_FACES,nr,nz]) .or. &
            any(shape(flux_r_ref) /= [max(nr-1,0),nz]) .or. &
            any(shape(flux_z_ref) /= [nr,max(nz-1,0)]) .or. &
            any(shape(boundary_inflow_flux) /= [J03_N_FACES,nr,nz]) .or. &
            any(shape(boundary_outflow_flux_ref) /= [J03_N_FACES,nr,nz]) .or. &
            any(shape(loss_frequency) /= [nr,nz])) then
            ierr = J03_ERR_SHAPE
            return
        end if
        if (any(loss_frequency < 0.0)) then
            ierr = J03_ERR_NEGATIVE_INPUT
            return
        end if
        if (.not. any(active)) then
            ierr = J03_ERR_GEOMETRY
            return
        end if
        do k = 1, nz
            do i = 1, nr
                if (.not. active(i, k)) cycle
                if (volume(i, k) <= 0.0 .or. any(face_area(:, i, k) < 0.0)) then
                    ierr = J03_ERR_GEOMETRY
                    return
                end if
                do f = 1, J03_N_FACES
                    if (face_type(f, i, k) < J03_FACE_INTERIOR .or. &
                        face_type(f, i, k) > J03_FACE_WALL) then
                        ierr = J03_ERR_FACE_TYPE
                        return
                    end if
                end do
                ! Each internal face is shared: topology and physical area must agree.
                do f = 1, J03_N_FACES
                    if (face_type(f, i, k) /= J03_FACE_INTERIOR) cycle
                    ni = i+di(f)
                    nk = k+dk(f)
                    ierr = J03_ERR_FACE_TYPE
                    if (ni < 1 .or. ni > nr .or. nk < 1 .or. nk > nz) return
                    if (.not. active(ni, nk)) return
                    opposite = opposing(f)
                    if (face_type(opposite, ni, nk) /= J03_FACE_INTERIOR) return
                    ierr = J03_ERR_GEOMETRY
                    area_scale = max(face_area(f, i, k), face_area(opposite, ni, nk))
                    if (min(face_area(f, i, k), face_area(opposite, ni, nk)) <= 0.0) return
                    if (abs(face_area(f, i, k)-face_area(opposite, ni, nk)) > &
                        100.0*epsilon(1.0)*area_scale) return
                    ierr = J03_SUCCESS
                end do
            end do
        end do

        closure%nr = nr
        closure%nz = nz
        closure%active = active
        closure%face_type = face_type
        closure%volume = volume
        closure%face_area = face_area
        closure%density_ref = density_ref
        closure%flux_r_ref = flux_r_ref
        closure%flux_z_ref = flux_z_ref
        closure%boundary_inflow_flux = boundary_inflow_flux
        closure%boundary_outflow_flux_ref = boundary_outflow_flux_ref
        closure%loss_frequency = loss_frequency
        allocate(closure%velocity_r_face(max(nr-1, 0), nz), &
            closure%velocity_z_face(nr, max(nz-1, 0)), &
            closure%boundary_outflow_velocity(J03_N_FACES, nr, nz))
        closure%velocity_r_face = 0.0
        closure%velocity_z_face = 0.0
        closure%boundary_outflow_velocity = 0.0
        scale = maxval(abs(density_ref), mask = active)
        ! The floor regularizes Gamma_ref / n_up_ref. It does not repair an
        ! invalid reference field; applications must check finite/nonnegative n.
        ! The resulting face coefficient stays fixed while J03 advances n.
        floor = max(scale*density_floor_fraction, tiny(1.0))
        do k = 1, nz
            do i = 1, nr-1
                if (.not. (active(i, k) .and. active(i+1, k))) cycle
                if (flux_r_ref(i, k) >= 0.0) then
                    nup = density_ref(i, k)
                else
                    nup = density_ref(i+1, k)
                end if
                closure%velocity_r_face(i, k) = flux_r_ref(i, k)/max(nup, floor)
            end do
        end do
        do k = 1, nz-1
            do i = 1, nr
                if (.not. (active(i, k) .and. active(i, k+1))) cycle
                if (flux_z_ref(i, k) >= 0.0) then
                    nup = density_ref(i, k)
                else
                    nup = density_ref(i, k+1)
                end if
                closure%velocity_z_face(i, k) = flux_z_ref(i, k)/max(nup, floor)
            end do
        end do
        do k = 1, nz
            do i = 1, nr
                if (.not. active(i, k)) cycle
                do f = 1, J03_N_FACES
                    if (face_type(f, i, k) == J03_FACE_OPEN) &
                        closure%boundary_outflow_velocity(f, i, k) = &
                        boundary_outflow_flux_ref(f, i, k)/max(density_ref(i, k), floor)
                end do
            end do
        end do
    end subroutine sub_J03_initialize_transport_closure
