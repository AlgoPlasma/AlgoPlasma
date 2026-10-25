!> One upwind sweep for prescribed inlet data and, when present, frozen wall data.
!> Cell traversal, DG solve and positivity recovery have a single implementation.
!> Compile and link with OpenMP to distribute independent speed-angle nodes.
!> The public interface and per-node arithmetic are identical in serial builds.
!> Errors are reported in node order; progress counts completed tasks, not node ids.
!> @param[in] mesh Initialized owned-cell mesh, without ghosts.
!> @param[in] geometry Geometry built from the same mesh.
!> @param[in] quadrature Complete velocity nodes and weights.
!> @param[in] sigma_t Nonnegative path-loss coefficients (nr,nz,n_dir), in inverse length.
!> @param[in] boundary Local physical, internal and optional REMOTE face types.
!> @param[out] psi New DG coefficients (3,nr,nz,n_dir); invalid when ierr is nonzero.
!> @param[out] ierr Zero on success; otherwise a J02 status code.
!> @param[in] boundary_inflow Optional phase-density input (4,nr,nz,n_dir); excludes zlo_inflow.
!> @param[in] zlo_inflow Optional compact physical z-low input (n_dir); excludes boundary_inflow.
!> @param[in] psi_old Previous wall-coupled field (3,nr,nz,n_dir), required for reflecting faces.
!> @param[in] wall_shape Optional nonnegative wall shape (n_dir), required for diffuse reflection.
!> @param[in] diffuse_fraction Optional diffuse fraction in [0,1], default zero.
!> @param[in] zlo_source_xi_lo Optional lower partial-inlet bounds (nr), supplied with upper bounds.
!> @param[in] zlo_source_xi_hi Optional upper partial-inlet bounds (nr); physical z-low ranks only.
!> @param[out] failed_direction Lowest failing velocity-node index, or zero when not applicable.
!> @param[out] failed_i Failing radial cell, global when partition is present, or zero.
!> @param[out] failed_k Failing axial cell, global when partition is present, or zero.
!> @param[in] progress_interval Optional nonnegative task reporting interval; zero disables output.
!> @param[in] partition Optional spatial ownership. All ranks enter collectively with local fields.
!> @details With partition, failures use global cell indices and upstream DG planes are exchanged.
    subroutine sub_J02_sweep(mesh, geometry, quadrature, sigma_t, boundary, psi, ierr, &
        boundary_inflow, zlo_inflow, psi_old, wall_shape, diffuse_fraction, &
        zlo_source_xi_lo, zlo_source_xi_hi, failed_direction, failed_i, failed_k, progress_interval, partition)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_quadrature_type), intent(in) :: quadrature
        type(sn_boundary_2drz_type), intent(in) :: boundary
        real, intent(in) :: sigma_t(:,:,:)
        real, allocatable, intent(out) :: psi(:,:,:,:)
        integer, intent(out) :: ierr
        real, intent(in), optional :: boundary_inflow(:,:,:,:), zlo_inflow(:)
        real, intent(in), optional :: psi_old(:,:,:,:), wall_shape(:), diffuse_fraction
        real, intent(in), optional :: zlo_source_xi_lo(:), zlo_source_xi_hi(:)
        integer, intent(out), optional :: failed_direction, failed_i, failed_k
        integer, intent(in), optional :: progress_interval
        type(sn_partition_type), optional, intent(in) :: partition
#ifdef J02_USE_MPI
        type(sn_boundary_2drz_type) :: checked_boundary
#endif
        type(sn_sweep_halo_type) :: halo
        real, allocatable :: wall(:), diffuse(:,:,:)
        integer :: m, progress_every, fd, fi, fk
        integer, allocatable :: direction_status(:), direction_i(:), direction_k(:), nodes(:)
        real :: fraction

        if (present(failed_direction)) failed_direction=0
        if (present(failed_i)) failed_i=0
        if (present(failed_k)) failed_k=0
        fd=0
        fi=0
        fk=0
#ifndef J02_USE_MPI
        if (present(partition)) then
            ierr=SN_ERR_MPI_DISABLED
            return
        end if
#endif
        ! Prepare and validate local inputs before entering the collective sweep.
        call prepare_sweep()
#ifdef J02_USE_MPI
        call sub_J02_sync_status(partition,ierr,fd,fi,fk)
#endif
        if (present(failed_direction)) failed_direction=fd
        if (present(failed_i)) failed_i=fi
        if (present(failed_k)) failed_k=fk
        if (ierr/=SN_SUCCESS) return
#ifdef J02_USE_MPI
        if (present(partition)) then
            checked_boundary=boundary
            call sub_J02_connect_partition_faces(mesh,checked_boundary,partition,ierr,validate_only=.true.)
            if (ierr/=SN_SUCCESS) return
            call sub_J02_partition_quadrature(partition,quadrature,ierr)
            if (ierr/=SN_SUCCESS) return
        end if
#endif
        allocate(psi(3,mesh%nr,mesh%nz,quadrature%n_dir))
        allocate(direction_status(quadrature%n_dir), direction_i(quadrature%n_dir), &
            direction_k(quadrature%n_dir))
        psi=0.0
        direction_status=SN_SUCCESS
        direction_i=0
        direction_k=0
        if (present(partition)) then
#ifdef J02_USE_MPI
            call sub_J02_mpi_sweep(mesh,geometry,quadrature,sigma_t,boundary,psi, &
                direction_status,direction_i,direction_k,fraction,boundary_inflow,zlo_inflow, &
                psi_old,wall,diffuse,zlo_source_xi_lo,zlo_source_xi_hi,progress_every,partition)
#endif
        else
            nodes=[(m,m=1,quadrature%n_dir)]
            call sub_J02_sweep_batch(mesh,geometry,quadrature,sigma_t,boundary,nodes,psi, &
                direction_status,direction_i,direction_k,fraction,boundary_inflow,zlo_inflow, &
                psi_old,wall,diffuse,zlo_source_xi_lo,zlo_source_xi_hi,progress_every,halo,-1)
        end if
        ! Select the lowest failing node, independent of thread completion order.
        do m = 1, quadrature%n_dir
            if (direction_status(m) == SN_SUCCESS) cycle
            ierr = direction_status(m)
            fd=m
            fi=direction_i(m)
            fk=direction_k(m)
            exit
        end do
#ifdef J02_USE_MPI
        call sub_J02_sync_status(partition,ierr,fd,fi,fk,quadrature)
#endif
        if (present(failed_direction)) failed_direction=fd
        if (present(failed_i)) failed_i=fi
        if (present(failed_k)) failed_k=fk
    contains
        ! Initialized objects and field shapes are caller contracts. Check only
        ! new physical input, boundary choices, and data needed for safe MPI grouping.
        subroutine prepare_sweep()
            use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
            integer :: i, k, face_types(SN_N_FACES)
            logical :: partial, reflecting

            ierr = SN_ERR_QUADRATURE_LAYOUT
            ! NaN directions cannot be assigned to a sweep quadrant consistently across ranks.
            if (.not.all(ieee_is_finite(quadrature%mu)) .or. .not.all(ieee_is_finite(quadrature%eta))) return
            ierr = SN_ERR_SWEEP_NEGATIVE_SIGMA
            if (any(sigma_t < 0.0)) return
            ierr = SN_ERR_REFLECTION_INPUT
            if (present(boundary_inflow) .eqv. present(zlo_inflow)) return
            if (present(zlo_source_xi_lo) .neqv. present(zlo_source_xi_hi)) return
            progress_every = 0
            if (present(progress_interval)) progress_every = progress_interval
            fraction = 0.0
            if (present(diffuse_fraction)) fraction = diffuse_fraction
            if (.not.ieee_is_finite(fraction)) return
            if (fraction < 0.0 .or. fraction > 1.0 .or. progress_every < 0) return
            partial = present(zlo_source_xi_lo)
            if (partial) then
                if (any(zlo_source_xi_lo < -1.0) .or. any(zlo_source_xi_hi > 1.0) .or. &
                    any(zlo_source_xi_lo > zlo_source_xi_hi)) return
                if (present(partition)) then
                    ierr = SN_ERR_MPI_INPUT
                    if (partition%first(2) /= 1) return
                end if
            end if
            ierr = SN_ERR_REFLECTION_INPUT
            reflecting = fun_J02_has_reflecting_faces(mesh, boundary) .or. partial
            if (reflecting) then
                if (.not. present(psi_old)) return
                if (fraction > 0.0 .and. .not. present(wall_shape)) return
                allocate(wall(quadrature%n_dir))
                wall = 0.0
                if (present(wall_shape)) wall = wall_shape
                if (any(wall < 0.0)) return
                if (fraction > 0.0) then
                    call sub_J02_compute_diffuse_wall_constants(mesh, geometry, quadrature, boundary, &
                        wall, psi_old, diffuse, ierr, zlo_source_xi_lo, zlo_source_xi_hi)
                    if (ierr /= SN_SUCCESS) return
                else
                    allocate(diffuse(SN_N_FACES,mesh%nr,mesh%nz))
                    diffuse = 0.0
                end if
            end if

            ! Interior neighbor topology comes from initialize_boundary_types.
            ! Physical face choices may be edited; REMOTE faces require a partition.
            do k = 1, mesh%nz
                do i = 1, mesh%nr
                    if (.not. mesh%active(i,k)) cycle
                    face_types = [boundary%face_r_lo(i,k),boundary%face_r_hi(i,k), &
                        boundary%face_z_lo(i,k),boundary%face_z_hi(i,k)]
                    if (any(face_types < SN_FACE_INTERIOR) .or. any(face_types > SN_FACE_REMOTE) .or. &
                        (any(face_types == SN_FACE_REMOTE) .and. .not.present(partition))) then
                        ierr = SN_ERR_SWEEP_FACE_TOPOLOGY
                        fi = i
                        fk = k
                        return
                    end if
                end do
            end do
            ierr = SN_SUCCESS
        end subroutine prepare_sweep
    end subroutine sub_J02_sweep


    ! One shared OpenMP loop for serial domains and MPI-owned spatial blocks.
    subroutine sub_J02_sweep_batch(mesh,geometry,quadrature,sigma_t,boundary,nodes,psi, &
        status,failed_i,failed_k,fraction,boundary_inflow,zlo_inflow,psi_old,wall,diffuse, &
        zlo_source_xi_lo,zlo_source_xi_hi,progress_every,halo,rank)
        use iso_fortran_env, only: output_unit
!$      use omp_lib, only: omp_get_num_threads
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_quadrature_type), intent(in) :: quadrature
        type(sn_boundary_2drz_type), intent(in) :: boundary
        type(sn_sweep_halo_type), intent(in) :: halo
        integer, intent(in) :: nodes(:),progress_every,rank
        real, intent(in) :: sigma_t(:,:,:),fraction
        real, contiguous, intent(inout) :: psi(:,:,:,:)
        integer, intent(inout) :: status(:),failed_i(:),failed_k(:)
        real, optional, intent(in) :: boundary_inflow(:,:,:,:),zlo_inflow(:),psi_old(:,:,:,:)
        real, optional, intent(in) :: wall(:),diffuse(:,:,:),zlo_source_xi_lo(:),zlo_source_xi_hi(:)
        integer :: j,m,completed,n_workers
        completed=0
        n_workers=1
!$omp parallel default(none) private(j,m) &
!$omp shared(mesh,geometry,quadrature,sigma_t,boundary,nodes,psi,status,failed_i,failed_k, &
!$omp fraction,boundary_inflow,zlo_inflow,psi_old,wall,diffuse,zlo_source_xi_lo,zlo_source_xi_hi, &
!$omp progress_every,halo,rank,completed,n_workers)
!$omp single
!$      n_workers=omp_get_num_threads()
        if (progress_every>0) then
            if (rank>=0) write(output_unit,'(a,i0)') '[J02] spatial rank: ',rank
            write(output_unit,'(a,i0)') '[J02] sweep workers: ',n_workers
            flush(output_unit)
        end if
!$omp end single
!$omp do schedule(static)
        do j=1,size(nodes)
            m=nodes(j)
            call sub_J02_sweep_velocity(mesh,geometry,quadrature,m,sigma_t(:,:,m),boundary, &
                psi(:,:,:,m),status(m),failed_i(m),failed_k(m),fraction,boundary_inflow,zlo_inflow, &
                psi_old,wall,diffuse,zlo_source_xi_lo,zlo_source_xi_hi,halo,j)
            if (progress_every>0) then
!$omp critical(j02_sweep_progress)
                completed=completed+1
                if (completed==1 .or. mod(completed,progress_every)==0 .or. completed==size(nodes)) then
                    write(output_unit,'(a,i0,a,i0)') '[J02] velocity tasks finished: ',completed,'/',size(nodes)
                    flush(output_unit)
                end if
!$omp end critical(j02_sweep_progress)
            end if
        end do
!$omp end do
!$omp end parallel
    end subroutine sub_J02_sweep_batch

    ! Private task: all cell-local work and error state belong to this invocation.
    recursive subroutine sub_J02_sweep_velocity(mesh, geometry, quadrature, m, sigma, boundary, &
        psi_direction, ierr, failed_i, failed_k, fraction, boundary_inflow, zlo_inflow, &
        psi_old, wall, diffuse, zlo_source_xi_lo, zlo_source_xi_hi, halo, halo_index)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry
        type(sn_quadrature_type), intent(in) :: quadrature
        type(sn_boundary_2drz_type), intent(in) :: boundary
        type(sn_sweep_halo_type), intent(in) :: halo
        integer, intent(in) :: m, halo_index
        real, intent(in) :: sigma(:,:), fraction
        real, contiguous, intent(out) :: psi_direction(:,:,:)
        integer, intent(out) :: ierr, failed_i, failed_k
        real, intent(in), optional :: boundary_inflow(:,:,:,:), zlo_inflow(:), psi_old(:,:,:,:)
        real, intent(in), optional :: wall(:), diffuse(:,:,:)
        real, intent(in), optional :: zlo_source_xi_lo(:), zlo_source_xi_hi(:)
        integer :: i, k, i0, i1, di, k0, k1, dk, solve_ierr
        real :: mu, eta, rc, hr, hz, a(3,3), rhs(3), coeff(3)
        logical :: partial

        ierr = SN_SUCCESS
        failed_i = 0
        failed_k = 0
        psi_direction = 0.0
        partial = present(zlo_source_xi_lo)
        mu = quadrature%mu(m)
        eta = quadrature%eta(m)
        if (abs(mu) <= epsilon(mu) .or. abs(eta) <= epsilon(eta)) then
            ierr = SN_ERR_SWEEP_AXIS_DIRECTION
            return
        end if
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
        cells: do i = i0, i1, di
            do k = k0, k1, dk
                if (.not. mesh%active(i, k)) cycle
                rc = geometry%rc(i)
                hr = geometry%hr(i)
                hz = geometry%hz(k)
                ! Interior inflow uses this sweep's upstream coefficients.
                ! Wall inflow uses psi_old, avoiding circular dependencies
                ! between reflected directions within the current sweep.
                a = 0.0
                rhs = 0.0
                ! Initialized topology supplies the upwind neighbor indices.
                call add_face(SN_R_LO, -mu, i-1, k)
                call add_face(SN_R_HI, mu, i+1, k)
                call add_face(SN_Z_LO, -eta, i, k-1)
                call add_face(SN_Z_HI, eta, i, k+1)
                call sub_J02_add_volume_matrix(a, mu, eta, rc, hr, hz)
                call sub_J02_add_absorption_matrix(a, sigma(i, k), rc, hr, hz)
                call sub_J02_solve_local_3x3(a, rhs, coeff, solve_ierr)
                if (solve_ierr /= SN_SUCCESS) then
                    ierr = SN_ERR_SWEEP_LOCAL_SOLVE
                    exit cells
                end if
                call sub_J02_enforce_local_positivity(a, rhs, coeff, ierr)
                if (ierr /= SN_SUCCESS) exit cells
                psi_direction(:, i, k) = coeff
            end do
        end do cells
        if (ierr /= SN_SUCCESS) then
            failed_i = i
            failed_k = k
        end if
    contains
        subroutine add_face(face_id, outward_dot, neighbor_i, neighbor_k)
            integer, intent(in) :: face_id, neighbor_i, neighbor_k
            real, intent(in) :: outward_dot
            integer :: kind, q
            real :: s, nr, nz, spec(3), diff(3)
            if (outward_dot > 0.0) then
                call sub_J02_add_self_face_matrix(a, face_id, outward_dot, rc, hr, hz)
                return
            end if
            s = -outward_dot
            kind = fun_J02_face_type(boundary, face_id, i, k)
            if (kind == SN_FACE_INTERIOR) then
                call sub_J02_add_neighbor_rhs(rhs, face_id, s, &
                    psi_direction(:, neighbor_i, neighbor_k), rc, hr, hz)
            else if (kind == SN_FACE_REMOTE) then
                if (face_id==SN_R_LO .or. face_id==SN_R_HI) then
                    call sub_J02_add_neighbor_rhs(rhs,face_id,s,halo%r(:,k,halo_index),rc,hr,hz)
                else
                    call sub_J02_add_neighbor_rhs(rhs,face_id,s,halo%z(:,i,halo_index),rc,hr,hz)
                end if
            else if (kind == SN_FACE_OPEN) then
                if (partial .and. face_id == SN_Z_LO .and. k == 1) then
                    call sub_J02_add_zface_constant_interval_rhs(rhs, s, &
                        fun_boundary_value(face_id, i, k, m), -1.0, zlo_source_xi_lo(i), &
                        zlo_source_xi_hi(i), rc, hr)
                    q = fun_J02_reflected_direction_index(quadrature, m, 0.0, -1.0)
                    spec = 0.0
                    diff = 0.0
                    call add_zlo_complement_coeff(spec, s, psi_old(:, i, k, q))
                    call add_zlo_complement_constant(diff, s, diffuse(face_id, i, k)*wall(m))
                    rhs = rhs+(1.0-fraction)*spec+fraction*diff
                else
                    call sub_J02_add_constant_rhs(rhs, face_id, s, &
                        fun_boundary_value(face_id, i, k, m), rc, hr, hz)
                end if
            else if (kind == SN_FACE_WALL) then
                call sub_J02_face_normal(face_id, nr, nz)
                q = fun_J02_reflected_direction_index(quadrature, m, nr, nz)
                spec = 0.0
                diff = 0.0
                call sub_J02_add_specular_rhs(spec, face_id, s, psi_old(:, i, k, q), rc, hr, hz)
                call sub_J02_add_constant_rhs(diff, face_id, s, &
                    diffuse(face_id, i, k)*wall(m), rc, hr, hz)
                rhs = rhs+(1.0-fraction)*spec+fraction*diff
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
    end subroutine sub_J02_sweep_velocity
