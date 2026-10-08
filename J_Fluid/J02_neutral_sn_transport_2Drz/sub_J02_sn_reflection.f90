!> Iterate wall-coupled transport; the sweep itself is defined only in sub_J02_sn_sweep.f90.
    subroutine sub_J02_solve_source_iteration(mesh, geometry, quadrature, sigma_t, &
        boundary_inflow, boundary, wall_shape, diffuse_fraction, max_iterations, tolerance, &
        psi, converged, iterations, final_relative_change, ierr, failed_direction, failed_i, &
        failed_k, zlo_source_xi_lo, zlo_source_xi_hi, zlo_inflow, progress_interval, partition)
        use iso_fortran_env, only:output_unit
        use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
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
        type(sn_partition_type), optional, intent(in) :: partition
#ifdef J02_USE_MPI
        type(sn_transport_options_type) :: config
#endif
        real :: old_sum, new_sum
        real, allocatable :: psi_old(:, :, :, :), psi_new(:, :, :, :)
        real :: difference, base, field_scale
        integer :: fd, fi, fk, progress_every, direction_progress
        if (present(failed_direction)) failed_direction=0
        if (present(failed_i)) failed_i=0
        if (present(failed_k)) failed_k=0
#ifndef J02_USE_MPI
        if (present(partition)) then
            ierr=SN_ERR_MPI_DISABLED
            converged=.false.
            iterations=0
            final_relative_change=huge(1.0)
            return
        end if
#endif
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
        if (.not.ieee_is_finite(tolerance)) then
            ierr=SN_ERR_SOURCE_ITERATION_OPTIONS
        else if (max_iterations < 2 .or. tolerance <= 0.0 .or. progress_every < 0) then
            ierr = SN_ERR_SOURCE_ITERATION_OPTIONS
        end if
        if (.not.ieee_is_finite(diffuse_fraction)) ierr=SN_ERR_REFLECTION_INPUT
#ifdef J02_USE_MPI
        call sub_J02_sync_status(partition,ierr)
#endif
        if (ierr/=SN_SUCCESS) return
#ifdef J02_USE_MPI
        config%max_iterations=max_iterations
        config%tolerance=tolerance
        config%diffuse_fraction=diffuse_fraction
        call sub_J02_partition_iteration_options(partition,config,ierr)
#endif
        if (ierr/=SN_SUCCESS) return
        allocate(psi_old(3, mesh%nr, mesh%nz, quadrature%n_dir))
        ! This iteration resolves wall coupling, not physical time evolution.
        ! The zero field supplies the first reflected boundary estimate.
        psi_old = 0.0
        do iterations = 1, max_iterations
            call sub_J02_sweep(mesh, geometry, quadrature, sigma_t, boundary, psi_new, ierr, &
                boundary_inflow=boundary_inflow, zlo_inflow=zlo_inflow, psi_old=psi_old, &
                wall_shape=wall_shape, diffuse_fraction=diffuse_fraction, &
                zlo_source_xi_lo=zlo_source_xi_lo, zlo_source_xi_hi=zlo_source_xi_hi, &
                failed_direction=fd, failed_i=fi, failed_k=fk, progress_interval=direction_progress,partition=partition)
            if (ierr /= SN_SUCCESS) exit
            ! Scale before summing: invariant under inlet amplitude changes,
            ! including fields far below unity. An exactly zero pair is fixed.
            field_scale = max(maxval(abs(psi_old)), maxval(abs(psi_new)))
#ifdef J02_USE_MPI
            call sub_J02_partition_real_reduce(partition,field_scale,.true.)
#endif
            final_relative_change = 0.0
            if (field_scale > 0.0) then
                difference = sum(abs(psi_new/field_scale-psi_old/field_scale))
                old_sum=sum(abs(psi_old/field_scale))
                new_sum=sum(abs(psi_new/field_scale))
#ifdef J02_USE_MPI
                call sub_J02_partition_real_reduce(partition,difference,.false.)
                call sub_J02_partition_real_reduce(partition,old_sum,.false.)
                call sub_J02_partition_real_reduce(partition,new_sum,.false.)
#endif
                base=max(old_sum,new_sum)
                final_relative_change = difference/base
            end if
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
        iterations=min(iterations,max_iterations)
        call move_alloc(psi_old, psi)
        if (present(failed_direction)) failed_direction = fd
        if (present(failed_i)) failed_i = fi
        if (present(failed_k)) failed_k = fk
    end subroutine sub_J02_solve_source_iteration
