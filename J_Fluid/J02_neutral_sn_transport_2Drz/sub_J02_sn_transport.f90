!> Application entry: solve the distribution, then reconstruct reference fields.
!> Open and reflecting problems share one sweep implementation.
!> @param[in] mesh Initialized owned-cell mesh, without ghosts.
!> @param[in] geometry Geometry built from the same mesh.
!> @param[in] quadrature Complete velocity nodes and weights.
!> @param[in] boundary Local physical, internal and optional REMOTE face types.
!> @param[in] sigma_t Path-loss coefficients (nr,nz,n_dir), in inverse length.
!> @param[out] ierr Zero only after successful transport and reconstruction.
!> @param[in] boundary_inflow Optional prescribed phase density (4,nr,nz,n_dir); excludes zlo_inflow.
!> @param[in] wall_shape Optional wall shape (n_dir), required for diffuse reflection.
!> @param[in] options Optional reflection fraction, stopping and progress settings.
!> @param[in] zlo_source_xi_lo Optional lower partial-inlet bounds (nr), paired with upper bounds.
!> @param[in] zlo_source_xi_hi Optional upper partial-inlet bounds (nr); physical z-low ranks only.
!> @param[in] zlo_inflow Optional compact inlet phase density (n_dir); excludes boundary_inflow.
!> @param[in] partition Optional spatial ownership; collective when present, no MPI lifetime management.
!> @param[out] result Owned-cell fields and fluxes; partition_flux holds REMOTE faces only.
!> @details Check ierr before using results. Physical open fluxes exclude process interfaces.
    subroutine sub_J02_solve_transport(mesh, geometry, quadrature, boundary, sigma_t, result, ierr, &
        boundary_inflow, wall_shape, options, zlo_source_xi_lo, zlo_source_xi_hi, zlo_inflow, partition)
        use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_quadrature_type), intent(in) :: quadrature
        type(sn_boundary_2drz_type), intent(in) :: boundary
        real, intent(in) :: sigma_t(:,:,:)
        real, intent(in), optional :: boundary_inflow(:,:,:,:), zlo_inflow(:)
        type(sn_transport_result_type), intent(out) :: result
        integer, intent(out) :: ierr
        real, intent(in), optional :: wall_shape(:), zlo_source_xi_lo(:), zlo_source_xi_hi(:)
        type(sn_transport_options_type), intent(in), optional :: options
        type(sn_partition_type), optional, intent(in) :: partition
        type(sn_transport_options_type) :: config
        real, allocatable :: wall(:), local_inlet(:)
        logical :: reflecting, solved

#ifndef J02_USE_MPI
        if (present(partition)) then
            ierr=SN_ERR_MPI_DISABLED
            return
        end if
#endif
        reflecting=.false.
        validation: block
            ierr = SN_ERR_REFLECTION_INPUT
            if (.not. fun_J02_boundary_is_valid(mesh, boundary)) exit validation
            if (present(boundary_inflow) .eqv. present(zlo_inflow)) exit validation
            if (present(zlo_source_xi_lo) .neqv. present(zlo_source_xi_hi)) exit validation
            ierr = SN_ERR_QUADRATURE_LAYOUT
            if (.not. fun_J02_quadrature_is_valid(quadrature)) exit validation
            ierr = SN_ERR_SWEEP_GEOMETRY_SHAPE
            if (.not. fun_J02_geometry_is_valid(mesh, geometry)) exit validation
            ierr = SN_ERR_REFLECTION_INPUT
            config = sn_transport_options_type()
            if (present(options)) config = options
            if (.not.ieee_is_finite(config%diffuse_fraction)) exit validation
            if (config%diffuse_fraction<0.0 .or. config%diffuse_fraction>1.0) exit validation
            ierr=SN_ERR_SOURCE_ITERATION_OPTIONS
            if (.not.ieee_is_finite(config%tolerance)) exit validation
            if (config%tolerance<=0.0 .or. config%max_iterations<2 .or. config%progress_interval<0) exit validation
            ierr=SN_SUCCESS
            reflecting = fun_J02_has_reflecting_faces(mesh, boundary) .or. present(zlo_source_xi_lo)
        end block validation
#ifdef J02_USE_MPI
        call sub_J02_sync_status(partition,ierr)
#endif
        if (ierr/=SN_SUCCESS) return
#ifdef J02_USE_MPI
        call sub_J02_partition_any(partition,reflecting)
#endif
        if (present(zlo_inflow)) then
            local_inlet=zlo_inflow
            if (present(partition)) then
                if (partition%first(2)/=1) local_inlet=0.0
            end if
        end if
        if (reflecting) then
            ! An all-zero shape is sufficient for pure specular reflection only.
            ierr=SN_SUCCESS
            if (config%diffuse_fraction > 0.0 .and. .not. present(wall_shape)) ierr=SN_ERR_REFLECTION_INPUT
#ifdef J02_USE_MPI
            call sub_J02_sync_status(partition,ierr)
#endif
            if (ierr/=SN_SUCCESS) return
            allocate(wall(quadrature%n_dir))
            wall = 0.0
            if (present(wall_shape)) wall = wall_shape
            call sub_J02_solve_source_iteration(mesh, geometry, quadrature, sigma_t, boundary_inflow, &
                boundary, wall, config%diffuse_fraction, config%max_iterations, config%tolerance, &
                result%psi, solved, result%iterations, result%relative_change, ierr, &
                result%failed_direction, result%failed_i, result%failed_k, zlo_source_xi_lo, &
                zlo_source_xi_hi, local_inlet, progress_interval=config%progress_interval,partition=partition)
        else
            call sub_J02_sweep(mesh, geometry, quadrature, sigma_t, boundary, result%psi, ierr, &
                boundary_inflow=boundary_inflow, zlo_inflow=local_inlet, &
                failed_direction=result%failed_direction, failed_i=result%failed_i, &
                failed_k=result%failed_k, progress_interval=config%progress_interval,partition=partition)
            result%iterations = 1
        end if
        if (ierr /= SN_SUCCESS) return
        call sub_J02_reconstruct_cell_moments(mesh, geometry, quadrature, result%psi, &
            result%density, result%velocity_r, result%velocity_z, ierr)
#ifdef J02_USE_MPI
        call sub_J02_sync_status(partition,ierr)
#endif
        if (ierr /= SN_SUCCESS) return
        call sub_J02_reconstruct_internal_face_fluxes(mesh, geometry, quadrature, result%psi, &
            result%flux_r, result%flux_z, ierr)
#ifdef J02_USE_MPI
        call sub_J02_sync_status(partition,ierr)
#endif
        if (ierr /= SN_SUCCESS) return
        call sub_J02_reconstruct_open_boundary_fluxes(mesh, geometry, boundary, quadrature, &
            result%psi, boundary_inflow, result%inflow_flux, result%outflow_flux, ierr, &
            zlo_source_xi_lo, zlo_source_xi_hi, local_inlet)
#ifdef J02_USE_MPI
        call sub_J02_sync_status(partition,ierr)
#endif
        if (ierr/=SN_SUCCESS) return
        if (present(partition)) then
#ifdef J02_USE_MPI
            call sub_J02_reconstruct_partition_fluxes(mesh,geometry,quadrature,boundary,result%psi, &
                partition,result%partition_flux,ierr)
#endif
        end if
        result%converged = ierr == SN_SUCCESS
    end subroutine sub_J02_solve_transport
