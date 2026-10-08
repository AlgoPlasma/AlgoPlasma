!> Physical-time finite-volume step, balance diagnostics, and optional steady iteration.

    !> Conservative bound dt=cfl/max(nu+sum(A*abs(u))/V), returned in seconds.
    !> Count all internal faces, not only outgoing ones; this can overrestrict dt.
    subroutine sub_J03_compute_stable_timestep(closure, cfl, dt, ierr)
        type(neutral_transport_closure_2drz_type), intent(in) :: closure
        real, intent(in) :: cfl
        real, intent(out) :: dt
        integer, intent(out) :: ierr
        integer :: i, k, f
        real :: rate, max_rate
        ierr = J03_SUCCESS
        dt = 0.0
        if (cfl <= 0.0 .or. cfl > 1.0) then
            ierr = J03_ERR_OPTIONS
            return
        end if
        max_rate = 0.0
        do k = 1, closure%nz
            do i = 1, closure%nr
                if (.not. closure%active(i, k)) cycle
                rate = closure%loss_frequency(i, k)
                if (closure%face_type(J03_R_LO, i, k) == J03_FACE_INTERIOR) &
                    rate = rate+closure%face_area(J03_R_LO, i, k)* &
                    abs(closure%velocity_r_face(i-1, k))/closure%volume(i, k)
                if (closure%face_type(J03_R_HI, i, k) == J03_FACE_INTERIOR) &
                    rate = rate+closure%face_area(J03_R_HI, i, k)* &
                    abs(closure%velocity_r_face(i, k))/closure%volume(i, k)
                if (closure%face_type(J03_Z_LO, i, k) == J03_FACE_INTERIOR) &
                    rate = rate+closure%face_area(J03_Z_LO, i, k)* &
                    abs(closure%velocity_z_face(i, k-1))/closure%volume(i, k)
                if (closure%face_type(J03_Z_HI, i, k) == J03_FACE_INTERIOR) &
                    rate = rate+closure%face_area(J03_Z_HI, i, k)* &
                    abs(closure%velocity_z_face(i, k))/closure%volume(i, k)
                ! Fixed inflow does not remove current particles. Only the
                ! density-dependent outflow coefficient enters this rate.
                do f = J03_R_LO, J03_Z_HI
                    if (closure%face_type(f, i, k) /= J03_FACE_OPEN) cycle
                    rate = rate+closure%face_area(f, i, k)* &
                        abs(closure%boundary_outflow_velocity(f, i, k))/closure%volume(i, k)
                end do
                max_rate = max(max_rate, rate)
            end do
        end do
        if (max_rate <= tiny(1.0)) then
            dt = 1.0
        else
            dt = cfl/max_rate
        end if
    end subroutine sub_J03_compute_stable_timestep

    subroutine sub_J03_continuity_step(closure, density, source_rate, dt, clip_negative, &
        density_new, ierr)
        type(neutral_transport_closure_2drz_type), intent(in) :: closure
        real, intent(in) :: density(:, :), source_rate(:, :), dt
        logical, intent(in) :: clip_negative
        real, allocatable, intent(out) :: density_new(:, :)
        integer, intent(out) :: ierr
        integer :: i, k
        real :: frlo, frhi, fzlo, fzhi, net, val
        ierr = J03_SUCCESS
        if (any(shape(density) /= [closure%nr,closure%nz]) .or. &
            any(shape(source_rate) /= [closure%nr,closure%nz])) then
            ierr = J03_ERR_SHAPE
            return
        end if
        if (dt <= 0.0) then
            ierr = J03_ERR_OPTIONS
            return
        end if
        if ((.not. clip_negative .and. any(density < 0.0)) .or. any(source_rate < 0.0)) then
            ierr = J03_ERR_NEGATIVE_INPUT
            return
        end if
        allocate(density_new(closure%nr, closure%nz))
        density_new = 0.0
        do k = 1, closure%nz
            do i = 1, closure%nr
                if (.not. closure%active(i, k)) cycle
                call sub_J03_cell_fluxes(closure, density, i, k, frlo, frhi, fzlo, fzhi)
                net = closure%face_area(J03_R_HI, i, k)*frhi- &
                    closure%face_area(J03_R_LO, i, k)*frlo+ &
                    closure%face_area(J03_Z_HI, i, k)*fzhi- &
                    closure%face_area(J03_Z_LO, i, k)*fzlo
                ! net is an outward particle rate [1/s], not a flux density.
                ! Transport and production use the old state; linear loss uses
                ! the new state, giving the denominator 1 + dt*nu.
                val = (density(i, k)-dt*net/closure%volume(i, k)+dt*source_rate(i, k))/ &
                    (1.0+dt*closure%loss_frequency(i, k))
                ! Optional clipping changes particle number; it is not a CFL fix.
                if (clip_negative .and. val < 0.0) val = 0.0
                density_new(i, k) = val
            end do
        end do
    end subroutine sub_J03_continuity_step

    !> Residual of the steady equation: div(Gamma)+nu*n-S, in density/time.
    !> Its volume sum can cancel locally large errors; return both diagnostics.
    subroutine sub_J03_compute_residual(closure, density, source_rate, residual, &
        max_abs_residual, global_balance, ierr)
        type(neutral_transport_closure_2drz_type), intent(in) :: closure
        real, intent(in) :: density(:, :), source_rate(:, :)
        real, allocatable, intent(out) :: residual(:, :)
        real, intent(out) :: max_abs_residual, global_balance
        integer, intent(out) :: ierr
        integer :: i, k
        real :: frlo, frhi, fzlo, fzhi, net
        ierr = J03_SUCCESS
        max_abs_residual = 0.0
        global_balance = 0.0
        if (any(shape(density) /= [closure%nr,closure%nz]) .or. &
            any(shape(source_rate) /= [closure%nr,closure%nz])) then
            ierr = J03_ERR_SHAPE
            return
        end if
        allocate(residual(closure%nr, closure%nz))
        residual = 0.0
        do k = 1, closure%nz
            do i = 1, closure%nr
                if (.not. closure%active(i, k)) cycle
                call sub_J03_cell_fluxes(closure, density, i, k, frlo, frhi, fzlo, fzhi)
                net = closure%face_area(J03_R_HI, i, k)*frhi- &
                    closure%face_area(J03_R_LO, i, k)*frlo+ &
                    closure%face_area(J03_Z_HI, i, k)*fzhi- &
                    closure%face_area(J03_Z_LO, i, k)*fzlo
                residual(i, k) = net/closure%volume(i, k)+ &
                    closure%loss_frequency(i, k)*density(i, k)-source_rate(i, k)
                max_abs_residual = max(max_abs_residual, abs(residual(i, k)))
                global_balance = global_balance+residual(i, k)*closure%volume(i, k)
            end do
        end do
    end subroutine sub_J03_compute_residual

    !> Fixed-condition iteration from reference density, not a physical-time driver.
    !> Require BOTH iterate change and equation residual to avoid false convergence.
    subroutine sub_J03_solve_steady(closure, source_rate, cfl, tolerance, max_iterations, &
        clip_negative, density, converged, iterations, final_relative_change, &
        max_abs_residual, global_balance, ierr, progress_interval, residual_tolerance, final_scaled_residual)
        use iso_fortran_env, only:output_unit
        type(neutral_transport_closure_2drz_type), intent(in) :: closure
        real, intent(in) :: source_rate(:, :), cfl, tolerance
        integer, intent(in) :: max_iterations
        logical, intent(in) :: clip_negative
        real, allocatable, intent(out) :: density(:, :)
        logical, intent(out) :: converged
        integer, intent(out) :: iterations, ierr
        integer, intent(in), optional :: progress_interval
        real, intent(out) :: final_relative_change, max_abs_residual, global_balance
        real, allocatable :: density_new(:, :), residual(:, :)
        real, intent(in), optional :: residual_tolerance
        real, intent(out), optional :: final_scaled_residual
        real :: dt, diff_sum, base_sum, residual_scale, residual_limit, scaled_residual
        integer :: progress_every

        ierr = J03_SUCCESS
        converged = .false.
        iterations = 0
        final_relative_change = huge(1.0)
        max_abs_residual = huge(1.0)
        global_balance = 0.0
        if (present(final_scaled_residual)) final_scaled_residual = huge(1.0)
        residual_limit = max(tolerance, 100.0*epsilon(1.0))
        if (present(residual_tolerance)) residual_limit = residual_tolerance
        if (residual_limit <= 0.0) then
            ierr = J03_ERR_OPTIONS
            return
        end if
        progress_every = 0
        if (present(progress_interval)) progress_every = progress_interval
        if (tolerance <= 0.0 .or. max_iterations < 1 .or. progress_every < 0) then
            ierr = J03_ERR_OPTIONS
            return
        end if
        if (size(source_rate, 1) /= closure%nr .or. size(source_rate, 2) /= closure%nz) then
            ierr = J03_ERR_SHAPE
            return
        end if
        if (any(source_rate < 0.0)) then
            ierr = J03_ERR_NEGATIVE_INPUT
            return
        end if
        call sub_J03_compute_stable_timestep(closure, cfl, dt, ierr)
        if (ierr /= J03_SUCCESS) return
        density = closure%density_ref
        call sub_J03_reference_residual_scale(closure, source_rate, residual_scale)
        do iterations = 1, max_iterations
            call sub_J03_continuity_step(closure, density, source_rate, dt, clip_negative, &
                density_new, ierr)
            if (ierr /= J03_SUCCESS) return
            diff_sum = sum(abs(density_new-density), mask = closure%active)
            base_sum = sum(abs(density), mask = closure%active)
            final_relative_change = diff_sum/max(base_sum, tiny(1.0))
            call move_alloc(density_new, density)
            call sub_J03_compute_residual(closure, density, source_rate, residual, &
                max_abs_residual, global_balance, ierr)
            if (ierr /= J03_SUCCESS) return
            scaled_residual = max_abs_residual/residual_scale
            if (present(final_scaled_residual)) final_scaled_residual = scaled_residual
            if (progress_every > 0) then
                if (iterations == 1 .or. mod(iterations, progress_every) == 0) then
                    write(output_unit, '(a,i0,a,i0,a,es12.4,a,es12.4)') '[J03] continuity step ', &
                        iterations, '/', max_iterations, ', relative change=', &
                        final_relative_change, ', scaled residual=', scaled_residual
                    flush(output_unit)
                end if
            end if
            if (final_relative_change <= tolerance .and. scaled_residual <= residual_limit) then
                converged = .true.
                exit
            end if
        end do
        if (.not. converged) iterations = max_iterations
        ! The last iteration already evaluated these diagnostics on density.
        ! Reusing them avoids a redundant full mesh traversal and allocation.
        if (.not. converged) ierr = J03_ERR_NOT_CONVERGED
    end subroutine sub_J03_solve_steady


    ! Fixed reference scale (density/time), independent of dt and current iterate.
    subroutine sub_J03_reference_residual_scale(closure, source_rate, scale)
        type(neutral_transport_closure_2drz_type), intent(in) :: closure
        real, intent(in) :: source_rate(:, :)
        real, intent(out) :: scale
        integer :: i, k
        real :: fl, fh, gl, gh, rate
        scale = tiny(1.0)
        do k = 1, closure%nz
            do i = 1, closure%nr
                if (.not. closure%active(i,k)) cycle
                call sub_J03_cell_fluxes(closure, closure%density_ref, i, k, fl, fh, gl, gh)
                rate = sum(closure%face_area(:,i,k)*abs([fl,fh,gl,gh]))/closure%volume(i,k)
                rate = rate+abs(source_rate(i,k))+ &
                    closure%loss_frequency(i,k)*abs(closure%density_ref(i,k))
                scale = max(scale, rate)
            end do
        end do
    end subroutine sub_J03_reference_residual_scale

    ! Number rates (particles/s). Only open faces contribute boundary exchange.
    ! A transient step needs outflow(old n) and removal(new n); a single call
    ! evaluates all rates at one supplied density, not that mixed-time balance.
    subroutine sub_J03_compute_balance(closure, density, source_rate, inflow, outflow, &
        production, removal, relative_balance, ierr)
        type(neutral_transport_closure_2drz_type), intent(in) :: closure
        real, intent(in) :: density(:, :), source_rate(:, :)
        real, intent(out) :: inflow, outflow, production, removal, relative_balance
        integer, intent(out) :: ierr
        integer :: i, k, f
        real, parameter :: normal(4) = [-1.0, 1.0, -1.0, 1.0]
        inflow = 0.0
        outflow = 0.0
        production = 0.0
        removal = 0.0
        relative_balance = huge(1.0)
        ierr = J03_ERR_SHAPE
        if (any(shape(density) /= [closure%nr,closure%nz]) .or. &
            any(shape(source_rate) /= [closure%nr,closure%nz])) return
        do k = 1, closure%nz
            do i = 1, closure%nr
                if (.not. closure%active(i,k)) cycle
                production = production+source_rate(i,k)*closure%volume(i,k)
                removal = removal+closure%loss_frequency(i,k)*density(i,k)*closure%volume(i,k)
                do f = 1, 4
                    if (closure%face_type(f,i,k) /= J03_FACE_OPEN) cycle
                    inflow = inflow-normal(f)*closure%face_area(f,i,k)*closure%boundary_inflow_flux(f,i,k)
                    outflow = outflow+normal(f)*closure%face_area(f,i,k)* &
                        closure%boundary_outflow_velocity(f,i,k)*density(i,k)
                end do
            end do
        end do
        relative_balance = abs(outflow+removal-inflow-production)/ &
            max(abs(inflow)+abs(production),abs(outflow)+abs(removal),tiny(1.0))
        ierr = J03_SUCCESS
    end subroutine sub_J03_compute_balance

    subroutine sub_J03_cell_fluxes(closure, density, i, k, frlo, frhi, fzlo, fzhi)
        type(neutral_transport_closure_2drz_type), intent(in) :: closure
        real, intent(in) :: density(:, :)
        integer, intent(in) :: i, k
        real, intent(out) :: frlo, frhi, fzlo, fzhi
        real :: u
        ! All four fluxes use positive r/z orientation, NOT outward normals.
        ! The caller applies high-minus-low signs when forming divergence.
        ! Walls retain zero net flux; internal faces use the same upwind state
        ! on both neighboring cells, so their particle rates cancel globally.
        frlo = 0.0
        frhi = 0.0
        fzlo = 0.0
        fzhi = 0.0
        if (closure%face_type(J03_R_LO, i, k) == J03_FACE_INTERIOR) then
            u = closure%velocity_r_face(i-1, k)
            if (u >= 0.0) then
                frlo = u*density(i-1, k)
            else
                frlo = u*density(i, k)
            end if
        else if (closure%face_type(J03_R_LO, i, k) == J03_FACE_OPEN) then
            frlo = closure%boundary_inflow_flux(J03_R_LO, i, k)+ &
                closure%boundary_outflow_velocity(J03_R_LO, i, k)*density(i, k)
        end if
        if (closure%face_type(J03_R_HI, i, k) == J03_FACE_INTERIOR) then
            u = closure%velocity_r_face(i, k)
            if (u >= 0.0) then
                frhi = u*density(i, k)
            else
                frhi = u*density(i+1, k)
            end if
        else if (closure%face_type(J03_R_HI, i, k) == J03_FACE_OPEN) then
            frhi = closure%boundary_inflow_flux(J03_R_HI, i, k)+ &
                closure%boundary_outflow_velocity(J03_R_HI, i, k)*density(i, k)
        end if
        if (closure%face_type(J03_Z_LO, i, k) == J03_FACE_INTERIOR) then
            u = closure%velocity_z_face(i, k-1)
            if (u >= 0.0) then
                fzlo = u*density(i, k-1)
            else
                fzlo = u*density(i, k)
            end if
        else if (closure%face_type(J03_Z_LO, i, k) == J03_FACE_OPEN) then
            fzlo = closure%boundary_inflow_flux(J03_Z_LO, i, k)+ &
                closure%boundary_outflow_velocity(J03_Z_LO, i, k)*density(i, k)
        end if
        if (closure%face_type(J03_Z_HI, i, k) == J03_FACE_INTERIOR) then
            u = closure%velocity_z_face(i, k)
            if (u >= 0.0) then
                fzhi = u*density(i, k)
            else
                fzhi = u*density(i, k+1)
            end if
        else if (closure%face_type(J03_Z_HI, i, k) == J03_FACE_OPEN) then
            fzhi = closure%boundary_inflow_flux(J03_Z_HI, i, k)+ &
                closure%boundary_outflow_velocity(J03_Z_HI, i, k)*density(i, k)
        end if
    end subroutine sub_J03_cell_fluxes
