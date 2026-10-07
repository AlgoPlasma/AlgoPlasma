!> Cell-centred cylindrical r-z free-flow face fluxes and pseudo-time update.

    subroutine sub_J01_build_faceflux_2Drz(active, face_type, density, velocity_r, &
        velocity_z, boundary_inflow_flux, flux_r, flux_z, boundary_outflow_flux, ierr)
        logical, intent(in) :: active(:, :)
        integer, intent(in) :: face_type(:, :, :)
        real, intent(in) :: density(:, :), velocity_r(:, :), velocity_z(:, :)
        real, intent(in) :: boundary_inflow_flux(:, :, :)
        real, allocatable, intent(out) :: flux_r(:, :), flux_z(:, :), boundary_outflow_flux(:, :, :)
        integer, intent(out) :: ierr
        integer :: nr, nz, i, k
        real :: alpha

        ierr = J01_SUCCESS
        nr = size(active, 1)
        nz = size(active, 2)
        if (size(face_type, 1) /= J01_N_FACES .or. size(face_type, 2) /= nr .or. &
            size(face_type, 3) /= nz .or. size(density, 1) /= nr .or. &
            size(density, 2) /= nz .or. size(velocity_r, 1) /= nr .or. &
            size(velocity_r, 2) /= nz .or. size(velocity_z, 1) /= nr .or. &
            size(velocity_z, 2) /= nz .or. size(boundary_inflow_flux, 1) /= J01_N_FACES .or. &
            size(boundary_inflow_flux, 2) /= nr .or. size(boundary_inflow_flux, 3) /= nz) then
            ierr = J01_ERR_SHAPE
            return
        end if
        if (any(density < 0.0)) then
            ierr = J01_ERR_NEGATIVE_INPUT
            return
        end if
        allocate(flux_r(max(nr-1, 0), nz), flux_z(nr, max(nz-1, 0)), &
            boundary_outflow_flux(J01_N_FACES, nr, nz))
        flux_r = 0.0
        flux_z = 0.0
        boundary_outflow_flux = 0.0
        do k = 1, nz
            do i = 1, nr-1
                if (.not. (active(i, k) .and. active(i+1, k))) cycle
                alpha = max(abs(velocity_r(i, k)), abs(velocity_r(i+1, k)))
                flux_r(i, k) = 0.5*(velocity_r(i, k)*density(i, k)+ &
                    velocity_r(i+1, k)*density(i+1, k))-0.5*alpha*(density(i+1, k)-density(i, k))
            end do
        end do
        do k = 1, nz-1
            do i = 1, nr
                if (.not. (active(i, k) .and. active(i, k+1))) cycle
                alpha = max(abs(velocity_z(i, k)), abs(velocity_z(i, k+1)))
                flux_z(i, k) = 0.5*(velocity_z(i, k)*density(i, k)+ &
                    velocity_z(i, k+1)*density(i, k+1))-0.5*alpha*(density(i, k+1)-density(i, k))
            end do
        end do
        do k = 1, nz
            do i = 1, nr
                if (.not. active(i, k)) cycle
                if (face_type(J01_R_LO, i, k) == J01_FACE_OPEN .and. velocity_r(i, k) < 0.0) &
                    boundary_outflow_flux(J01_R_LO, i, k) = velocity_r(i, k)*density(i, k)
                if (face_type(J01_R_HI, i, k) == J01_FACE_OPEN .and. velocity_r(i, k) > 0.0) &
                    boundary_outflow_flux(J01_R_HI, i, k) = velocity_r(i, k)*density(i, k)
                if (face_type(J01_Z_LO, i, k) == J01_FACE_OPEN .and. velocity_z(i, k) < 0.0) &
                    boundary_outflow_flux(J01_Z_LO, i, k) = velocity_z(i, k)*density(i, k)
                if (face_type(J01_Z_HI, i, k) == J01_FACE_OPEN .and. velocity_z(i, k) > 0.0) &
                    boundary_outflow_flux(J01_Z_HI, i, k) = velocity_z(i, k)*density(i, k)
            end do
        end do
    end subroutine sub_J01_build_faceflux_2Drz

    subroutine sub_J01_continuity_step_2Drz(active, face_type, volume, face_area, density, &
        source_rate, loss_frequency, flux_r, flux_z, boundary_inflow_flux, &
        boundary_outflow_flux, dt, density_new, ierr)
        logical, intent(in) :: active(:, :)
        integer, intent(in) :: face_type(:, :, :)
        real, intent(in) :: volume(:, :), face_area(:, :, :), density(:, :), source_rate(:, :), &
            loss_frequency(:, :), flux_r(:, :), flux_z(:, :), boundary_inflow_flux(:, :, :), &
            boundary_outflow_flux(:, :, :), dt
        real, allocatable, intent(out) :: density_new(:, :)
        integer, intent(out) :: ierr
        integer :: nr, nz, i, k, lower_face
        real :: frlo, frhi, fzlo, fzhi, net

        ierr = J01_SUCCESS
        nr = size(active, 1)
        nz = size(active, 2)
        if (dt <= 0.0) then
            ierr = J01_ERR_TIMESTEP
            return
        end if
        if (size(volume, 1) /= nr .or. size(volume, 2) /= nz .or. &
            size(face_type, 1) /= J01_N_FACES .or. size(face_type, 2) /= nr .or. &
            size(face_type, 3) /= nz .or. size(density, 1) /= nr .or. &
            size(density, 2) /= nz .or. &
            size(face_area, 1) /= J01_N_FACES .or. size(face_area, 2) /= nr .or. &
            size(face_area, 3) /= nz .or. size(source_rate, 1) /= nr .or. &
            size(source_rate, 2) /= nz .or. size(loss_frequency, 1) /= nr .or. &
            size(loss_frequency, 2) /= nz .or. size(flux_r, 1) /= max(nr-1, 0) .or. &
            size(flux_r, 2) /= nz .or. size(flux_z, 1) /= nr .or. &
            size(flux_z, 2) /= max(nz-1, 0) .or. &
            size(boundary_inflow_flux, 1) /= J01_N_FACES .or. &
            size(boundary_inflow_flux, 2) /= nr .or. &
            size(boundary_inflow_flux, 3) /= nz .or. &
            size(boundary_outflow_flux, 1) /= J01_N_FACES .or. &
            size(boundary_outflow_flux, 2) /= nr .or. &
            size(boundary_outflow_flux, 3) /= nz) then
            ierr = J01_ERR_SHAPE
            return
        end if
        if (any(loss_frequency < 0.0) .or. any(source_rate < 0.0) .or. any(density < 0.0)) then
            ierr = J01_ERR_NEGATIVE_INPUT
            return
        end if
        do k = 1, nz
            do i = 1, nr
                if (active(i, k) .and. volume(i, k) <= 0.0) then
                    ierr = J01_ERR_NEGATIVE_INPUT
                    return
                end if
            end do
        end do
        allocate(density_new(nr, nz))
        density_new = 0.0
        do k = 1, nz
            do i = 1, nr
                if (.not. active(i, k)) cycle
                frlo = 0.0
                frhi = 0.0
                fzlo = 0.0
                fzhi = 0.0
                if (i > 1) then
                    lower_face = i-1
                    if (face_type(J01_R_LO, i, k) == J01_FACE_INTERIOR) &
                        frlo = flux_r(lower_face, k)
                end if
                if (i < nr) then
                    if (face_type(J01_R_HI, i, k) == J01_FACE_INTERIOR) frhi = flux_r(i, k)
                end if
                if (k > 1) then
                    lower_face = k-1
                    if (face_type(J01_Z_LO, i, k) == J01_FACE_INTERIOR) &
                        fzlo = flux_z(i, lower_face)
                end if
                if (k < nz) then
                    if (face_type(J01_Z_HI, i, k) == J01_FACE_INTERIOR) fzhi = flux_z(i, k)
                end if
                if (face_type(J01_R_LO, i, k) == J01_FACE_OPEN) frlo = &
                    boundary_inflow_flux(J01_R_LO, i, k)+boundary_outflow_flux(J01_R_LO, i, k)
                if (face_type(J01_R_HI, i, k) == J01_FACE_OPEN) frhi = &
                    boundary_inflow_flux(J01_R_HI, i, k)+boundary_outflow_flux(J01_R_HI, i, k)
                if (face_type(J01_Z_LO, i, k) == J01_FACE_OPEN) fzlo = &
                    boundary_inflow_flux(J01_Z_LO, i, k)+boundary_outflow_flux(J01_Z_LO, i, k)
                if (face_type(J01_Z_HI, i, k) == J01_FACE_OPEN) fzhi = &
                    boundary_inflow_flux(J01_Z_HI, i, k)+boundary_outflow_flux(J01_Z_HI, i, k)
                net = face_area(J01_R_HI, i, k)*frhi-face_area(J01_R_LO, i, k)*frlo+ &
                    face_area(J01_Z_HI, i, k)*fzhi-face_area(J01_Z_LO, i, k)*fzlo
                density_new(i, k) = (density(i, k)-dt*net/volume(i, k)+dt*source_rate(i, k))/ &
                    (1.0+dt*loss_frequency(i, k))
            end do
        end do
    end subroutine sub_J01_continuity_step_2Drz
