!> Raw history tallies and conversion to SI cell moments and signed face fluxes.
    subroutine sub_J01_initialize_fm_tally(nr, nz, tally)
        integer, intent(in) :: nr, nz
        type(fm_tally_2drz_type), intent(out) :: tally
        allocate(tally%residence(nr,nz), tally%moment_r(nr,nz), tally%moment_z(nr,nz), &
            tally%count_r(max(nr-1,0),nz), tally%count_z(nr,max(nz-1,0)), &
            tally%boundary_count(4,nr,nz))
        tally%residence=0.0
        tally%moment_r=0.0
        tally%moment_z=0.0
        tally%count_r=0.0
        tally%count_z=0.0
        tally%boundary_count=0.0
    end subroutine sub_J01_initialize_fm_tally

! Requires positive volumes and valid mesh dimensions; no flux is rebuilt from mean velocity.
    subroutine sub_J01_finalize_fm_tally(r_edge, z_edge, theta_span, active, history_rate, &
        tally, density, velocity_r, velocity_z, flux_r, flux_z, boundary_outflow_flux)
        real, intent(in) :: r_edge(:), z_edge(:), theta_span, history_rate
        logical, intent(in) :: active(:, :)
        type(fm_tally_2drz_type), intent(in) :: tally
        real, allocatable, intent(out) :: density(:,:), velocity_r(:,:), velocity_z(:,:)
        real, allocatable, intent(out) :: flux_r(:,:), flux_z(:,:), boundary_outflow_flux(:,:,:)
        integer :: nr, nz, i, k
        real :: volume, area
        nr=size(active,1)
        nz=size(active,2)
        allocate(density(nr,nz), velocity_r(nr,nz), velocity_z(nr,nz), &
            flux_r(max(nr-1,0),nz), flux_z(nr,max(nz-1,0)), boundary_outflow_flux(4,nr,nz))
        density=0.0
        velocity_r=0.0
        velocity_z=0.0
        flux_r=0.0
        flux_z=0.0
        boundary_outflow_flux=0.0
        do k = 1, nz
            do i = 1, nr
                if (.not. active(i, k)) cycle
                volume = 0.5*theta_span*(r_edge(i+1)**2-r_edge(i)**2)* &
                    (z_edge(k+1)-z_edge(k))
                ! history_rate [1/s/history] times summed residence [s]
                ! estimates particles in the cell; divide by sector volume [m^3].
                density(i, k) = history_rate*tally%residence(i, k)/volume
                if (tally%residence(i, k) > 0.0) then
                    velocity_r(i, k) = tally%moment_r(i, k)/tally%residence(i, k)
                    velocity_z(i, k) = tally%moment_z(i, k)/tally%residence(i, k)
                end if
                area = theta_span*r_edge(i)*(z_edge(k+1)-z_edge(k))
                if (area > 0.0) boundary_outflow_flux(J01_R_LO, i, k) = &
                    history_rate*tally%boundary_count(J01_R_LO, i, k)/area
                area = theta_span*r_edge(i+1)*(z_edge(k+1)-z_edge(k))
                boundary_outflow_flux(J01_R_HI, i, k) = &
                    history_rate*tally%boundary_count(J01_R_HI, i, k)/area
                area = 0.5*theta_span*(r_edge(i+1)**2-r_edge(i)**2)
                boundary_outflow_flux(J01_Z_LO, i, k) = &
                    history_rate*tally%boundary_count(J01_Z_LO, i, k)/area
                boundary_outflow_flux(J01_Z_HI, i, k) = &
                    history_rate*tally%boundary_count(J01_Z_HI, i, k)/area
            end do
        end do
        ! Signed crossings / full face area give Gamma [1/(m^2 s)].
        ! Do not replace these estimators by density times cell-mean velocity:
        ! residence moments and crossing counts sample different quantities.
        do k = 1, nz
            do i = 1, nr-1
                area = theta_span*r_edge(i+1)*(z_edge(k+1)-z_edge(k))
                flux_r(i, k) = history_rate*tally%count_r(i, k)/area
            end do
        end do
        do k = 1, nz-1
            do i = 1, nr
                area = 0.5*theta_span*(r_edge(i+1)**2-r_edge(i)**2)
                flux_z(i, k) = history_rate*tally%count_z(i, k)/area
            end do
        end do

    end subroutine sub_J01_finalize_fm_tally
