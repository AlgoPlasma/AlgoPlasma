!> Orchestrate inlet sampling, independent trajectories and estimator normalisation.
    subroutine sub_J01_free_molecular_mc_2Drz(r_edge, z_edge, theta_span, active, &
        face_type, inlet_r_lo, inlet_r_hi, neutral_mass, inlet_temperature, &
        wall_temperature, inlet_drift_z, inlet_density, diffuse_fraction, &
        n_histories, max_events, random_seed_value, density, velocity_r, velocity_z, &
        flux_r, flux_z, boundary_outflow_flux, history_rate, n_completed, n_truncated, &
        ierr, progress_interval)
        real, intent(in) :: r_edge(:), z_edge(:), theta_span
        logical, intent(in) :: active(:, :)
        integer, intent(in) :: face_type(:, :, :)
        real, intent(in) :: inlet_r_lo, inlet_r_hi, neutral_mass, inlet_temperature, &
            wall_temperature, inlet_drift_z, inlet_density, diffuse_fraction
        integer, intent(in) :: n_histories, max_events, random_seed_value
        real, allocatable, intent(out) :: density(:, :), velocity_r(:, :), velocity_z(:, :), &
            flux_r(:, :), flux_z(:, :), boundary_outflow_flux(:, :, :)
        real, intent(out) :: history_rate
        integer, intent(out) :: n_completed, n_truncated, ierr
        integer, intent(in), optional :: progress_interval

        integer :: nr, nz, p, report_every, i, k, neighbor
        real :: sigma_wall, eps_r, eps_z, r, z, ur, uz
        logical :: escaped, truncated
        type(fm_inlet_2drz_type) :: inlet
        type(fm_tally_2drz_type) :: tally

        ierr = J01_SUCCESS
        history_rate = 0.0
        n_completed = 0
        n_truncated = 0
        nr = size(active, 1)
        nz = size(active, 2)
        if (nr < 1 .or. nz < 1) then
            ierr = J01_ERR_SHAPE
            return
        end if
        if (size(r_edge) /= nr+1 .or. size(z_edge) /= nz+1 .or. &
            size(face_type, 1) /= J01_N_FACES .or. size(face_type, 2) /= nr .or. &
            size(face_type, 3) /= nz) then
            ierr = J01_ERR_SHAPE
            return
        end if
        if (r_edge(1) < 0.0 .or. theta_span <= 0.0 .or. neutral_mass <= 0.0 .or. &
            inlet_temperature <= 0.0 .or. wall_temperature <= 0.0 .or. &
            inlet_density < 0.0 .or. inlet_r_hi <= inlet_r_lo .or. &
            diffuse_fraction < 0.0 .or. diffuse_fraction > 1.0 .or. &
            n_histories <= 0 .or. max_events <= 0 .or. &
            any(r_edge(2:) <= r_edge(:nr)) .or. &
            any(z_edge(2:) <= z_edge(:nz))) then
            ierr = J01_ERR_CONFIGURATION
            return
        end if

        ! Reject invalid neighbours before the tracker indexes internal-face tallies.
        do k = 1, nz
            do i = 1, nr
                if (.not. active(i,k)) cycle
                ierr = J01_ERR_CONFIGURATION
                if (any(face_type(:,i,k) < J01_FACE_INTERIOR) .or. &
                    any(face_type(:,i,k) > J01_FACE_WALL)) return
                if (face_type(J01_R_LO,i,k) == J01_FACE_INTERIOR) then
                    if (i == 1) return
                    neighbor = i-1
                    if (.not. active(neighbor,k)) return
                    if (face_type(J01_R_HI,neighbor,k) /= J01_FACE_INTERIOR) return
                end if
                if (face_type(J01_R_HI,i,k) == J01_FACE_INTERIOR) then
                    if (i == nr) return
                    if (.not. active(i+1,k)) return
                    if (face_type(J01_R_LO,i+1,k) /= J01_FACE_INTERIOR) return
                end if
                if (face_type(J01_Z_LO,i,k) == J01_FACE_INTERIOR) then
                    if (k == 1) return
                    neighbor = k-1
                    if (.not. active(i,neighbor)) return
                    if (face_type(J01_Z_HI,i,neighbor) /= J01_FACE_INTERIOR) return
                end if
                if (face_type(J01_Z_HI,i,k) == J01_FACE_INTERIOR) then
                    if (k == nz) return
                    if (.not. active(i,k+1)) return
                    if (face_type(J01_Z_LO,i,k+1) /= J01_FACE_INTERIOR) return
                end if
            end do
        end do
        ierr = J01_SUCCESS

        call sub_J01_prepare_fm_inlet(r_edge, active, face_type, theta_span, inlet_r_lo, &
            inlet_r_hi, neutral_mass, inlet_temperature, inlet_drift_z, inlet_density, &
            n_histories, inlet, history_rate, ierr)
        if (ierr /= J01_SUCCESS) return
        call sub_J01_initialize_fm_tally(nr, nz, tally)
        sigma_wall = sqrt(1.380649e-23*wall_temperature/neutral_mass)
        eps_r = max(1.0e-12, 1.0e-9*minval(r_edge(2:)-r_edge(:nr)))
        eps_z = max(1.0e-12, 1.0e-9*minval(z_edge(2:)-z_edge(:nz)))
        report_every = 0
        if (present(progress_interval)) report_every = progress_interval
        call sub_J01_set_random_seed(random_seed_value)

        ! Each history represents a steady injection rate, not one PIC timestep.
        ! Track one particle to escape, accumulate its residence/crossings, then
        ! start an independent history. There is no global physical-time loop.
        do p = 1, n_histories
            call sub_J01_sample_fm_inlet(inlet, &
                z_edge(1)+max(eps_z, abs(nearest(z_edge(1), 1.0)-z_edge(1))), &
                inlet_drift_z, r, z, ur, uz)
            call sub_J01_trace_fm_history(r_edge, z_edge, active, face_type, diffuse_fraction, &
                sigma_wall, max_events, eps_r, eps_z, r, z, ur, uz, tally, escaped, truncated)
            if (escaped) n_completed = n_completed+1
            if (truncated) n_truncated = n_truncated+1
            if (report_every > 0) then
                if (mod(p, report_every) == 0 .or. p == n_histories) &
                    write(*, '(a,i0,a,i0,a,f6.2,a)') '[J01-FM] histories ', p, '/', &
                    n_histories, ' (', 100.0*real(p)/real(n_histories), '%)'
            end if
        end do
        call sub_J01_finalize_fm_tally(r_edge, z_edge, theta_span, active, history_rate, &
            tally, density, velocity_r, velocity_z, flux_r, flux_z, boundary_outflow_flux)
        ! Partial tallies remain available for diagnostics, but a truncated
        ! history set must not be accepted as a completed reference solution.
        if (n_truncated > 0) ierr = J01_ERR_PARTICLE_TRACKING
    end subroutine sub_J01_free_molecular_mc_2Drz
