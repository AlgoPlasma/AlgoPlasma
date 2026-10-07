!> Mesh validation and cylindrical geometric factors for the r-z SN solver.

    subroutine sub_J02_initialize_mesh(r_edge, z_edge, active, mesh, ierr)
        real, intent(in) :: r_edge(:), z_edge(:)
        logical, intent(in) :: active(:, :)
        type(sn_mesh_2drz_type), intent(out) :: mesh
        integer, intent(out) :: ierr
        integer :: i

        ierr = SN_SUCCESS
        if (size(r_edge) < 2 .or. size(z_edge) < 2) then
            ierr = SN_ERR_MESH_EDGE_COUNT
            return
        end if
        if (size(active, 1) /= size(r_edge)-1 .or. size(active, 2) /= size(z_edge)-1) then
            ierr = SN_ERR_MESH_ACTIVE_SHAPE
            return
        end if
        if (r_edge(1) < 0.0) then
            ierr = SN_ERR_MESH_NEGATIVE_RADIUS
            return
        end if
        do i = 1, size(r_edge)-1
            if (r_edge(i+1) <= r_edge(i)) then
                ierr = SN_ERR_MESH_RADIAL_ORDER
                return
            end if
        end do
        do i = 1, size(z_edge)-1
            if (z_edge(i+1) <= z_edge(i)) then
                ierr = SN_ERR_MESH_AXIAL_ORDER
                return
            end if
        end do

        mesh%nr = size(r_edge)-1
        mesh%nz = size(z_edge)-1
        mesh%r_edge = r_edge
        mesh%z_edge = z_edge
        mesh%active = active
    end subroutine sub_J02_initialize_mesh

    subroutine sub_J02_build_geometry(mesh, theta_span, geometry, ierr)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        real, intent(in) :: theta_span
        type(sn_geometry_2drz_type), intent(out) :: geometry
        integer, intent(out) :: ierr
        integer :: i, k
        real :: ring_area

        ierr = SN_SUCCESS
        if (mesh%nr < 1 .or. mesh%nz < 1 .or. .not. allocated(mesh%r_edge) .or. &
            .not. allocated(mesh%z_edge) .or. .not. allocated(mesh%active)) then
            ierr = SN_ERR_GEOMETRY_MESH
            return
        end if
        if (size(mesh%r_edge) /= mesh%nr+1 .or. size(mesh%z_edge) /= mesh%nz+1 .or. &
            size(mesh%active, 1) /= mesh%nr .or. size(mesh%active, 2) /= mesh%nz) then
            ierr = SN_ERR_GEOMETRY_MESH
            return
        end if
        if (theta_span <= 0.0) then
            ierr = SN_ERR_GEOMETRY_THETA_SPAN
            return
        end if

        geometry%theta_span = theta_span
        allocate(geometry%rc(mesh%nr), geometry%hr(mesh%nr))
        allocate(geometry%hz(mesh%nz), geometry%xi_bar(mesh%nr))
        allocate(geometry%volume(mesh%nr, mesh%nz))
        allocate(geometry%area_r_lo(mesh%nr, mesh%nz))
        allocate(geometry%area_r_hi(mesh%nr, mesh%nz))
        allocate(geometry%area_z_lo(mesh%nr, mesh%nz))
        allocate(geometry%area_z_hi(mesh%nr, mesh%nz))

        geometry%volume = 0.0
        do i = 1, mesh%nr
            geometry%rc(i) = 0.5*(mesh%r_edge(i)+mesh%r_edge(i+1))
            geometry%hr(i) = 0.5*(mesh%r_edge(i+1)-mesh%r_edge(i))
            geometry%xi_bar(i) = geometry%hr(i)/(3.0*geometry%rc(i))
        end do
        do k = 1, mesh%nz
            geometry%hz(k) = 0.5*(mesh%z_edge(k+1)-mesh%z_edge(k))
        end do

        do k = 1, mesh%nz
            do i = 1, mesh%nr
                geometry%area_r_lo(i, k) = theta_span*mesh%r_edge(i)*(2.0*geometry%hz(k))
                geometry%area_r_hi(i, k) = theta_span*mesh%r_edge(i+1)*(2.0*geometry%hz(k))
                ring_area = 0.5*theta_span* &
                    (mesh%r_edge(i+1)**2-mesh%r_edge(i)**2)
                geometry%area_z_lo(i, k) = ring_area
                geometry%area_z_hi(i, k) = ring_area
                if (mesh%active(i, k)) then
                    geometry%volume(i, k) = ring_area*(2.0*geometry%hz(k))
                end if
            end do
        end do
    end subroutine sub_J02_build_geometry

    !> @brief Classify local faces; with partition, collectively connect remote active neighbors.
    !> @param[in] mesh Initialized owned-cell mesh.
    !> @param[out] boundary Four face-type arrays of shape (nr,nz).
    !> @param[out] ierr Zero on success; otherwise a J02 input or layout error.
    !> @param[in] partition Optional borrowed spatial ownership; physical faces remain caller-configurable.
    subroutine sub_J02_initialize_boundary_types(mesh, boundary, ierr, partition)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_boundary_2drz_type), intent(out) :: boundary
        integer, intent(out) :: ierr
        type(sn_partition_type), optional, intent(in) :: partition
        integer :: i, k

#ifndef J02_USE_MPI
        if (present(partition)) then
            ierr=SN_ERR_MPI_DISABLED
            return
        end if
#endif
        ierr = SN_SUCCESS
        if (.not. allocated(mesh%active)) then
            ierr = SN_ERR_GEOMETRY_MESH
        end if
#ifdef J02_USE_MPI
        call sub_J02_sync_status(partition,ierr)
#endif
        if (ierr/=SN_SUCCESS) return
        allocate(boundary%face_r_lo(mesh%nr, mesh%nz), &
            boundary%face_r_hi(mesh%nr, mesh%nz), &
            boundary%face_z_lo(mesh%nr, mesh%nz), &
            boundary%face_z_hi(mesh%nr, mesh%nz))
        boundary%face_r_lo = SN_FACE_WALL
        boundary%face_r_hi = SN_FACE_WALL
        boundary%face_z_lo = SN_FACE_WALL
        boundary%face_z_hi = SN_FACE_WALL
        do k = 1, mesh%nz
            do i = 1, mesh%nr
                if (.not. mesh%active(i, k)) cycle
                if (i == 1) then
                    boundary%face_r_lo(i, k) = SN_FACE_OPEN
                else if (mesh%active(i-1, k)) then
                    boundary%face_r_lo(i, k) = SN_FACE_INTERIOR
                end if
                if (i == mesh%nr) then
                    boundary%face_r_hi(i, k) = SN_FACE_OPEN
                else if (mesh%active(i+1, k)) then
                    boundary%face_r_hi(i, k) = SN_FACE_INTERIOR
                end if
                if (k == 1) then
                    boundary%face_z_lo(i, k) = SN_FACE_OPEN
                else if (mesh%active(i, k-1)) then
                    boundary%face_z_lo(i, k) = SN_FACE_INTERIOR
                end if
                if (k == mesh%nz) then
                    boundary%face_z_hi(i, k) = SN_FACE_OPEN
                else if (mesh%active(i, k+1)) then
                    boundary%face_z_hi(i, k) = SN_FACE_INTERIOR
                end if
            end do
        end do
#ifdef J02_USE_MPI
        if (present(partition)) call sub_J02_connect_partition_faces(mesh,boundary,partition,ierr)
#endif
    end subroutine sub_J02_initialize_boundary_types

    subroutine sub_J02_configure_zlo_partial_inlet_boundary(mesh, face_fraction, boundary, ierr)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        real, intent(in) :: face_fraction(:)
        type(sn_boundary_2drz_type), intent(inout) :: boundary
        integer, intent(out) :: ierr
        integer :: i
        ierr = SN_SUCCESS
        if (size(face_fraction) /= mesh%nr .or. any(face_fraction < 0.0) .or. &
            any(face_fraction > 1.0) .or. .not. fun_J02_boundary_is_valid(mesh, boundary)) then
            ierr = SN_ERR_PARTIAL_INLET
            return
        end if
        do i = 1, mesh%nr
            if (.not. mesh%active(i, 1)) cycle
            if (face_fraction(i) > 0.0) then
                boundary%face_z_lo(i, 1) = SN_FACE_OPEN
            else
                boundary%face_z_lo(i, 1) = SN_FACE_WALL
            end if
        end do
    end subroutine sub_J02_configure_zlo_partial_inlet_boundary

    logical function fun_J02_geometry_is_valid(mesh, geometry)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_geometry_2drz_type), intent(in) :: geometry

        fun_J02_geometry_is_valid = mesh%nr > 0 .and. mesh%nz > 0 .and. &
            allocated(mesh%active)
        if (.not. fun_J02_geometry_is_valid) return
        fun_J02_geometry_is_valid = size(mesh%active, 1) == mesh%nr .and. &
            size(mesh%active, 2) == mesh%nz
        if (.not. fun_J02_geometry_is_valid) return
        fun_J02_geometry_is_valid = allocated(geometry%rc) .and. &
            allocated(geometry%hr) .and. allocated(geometry%hz) .and. &
            allocated(geometry%xi_bar)
        if (.not. fun_J02_geometry_is_valid) return
        fun_J02_geometry_is_valid = size(geometry%rc) == mesh%nr .and. &
            size(geometry%hr) == mesh%nr .and. size(geometry%hz) == mesh%nz .and. &
            size(geometry%xi_bar) == mesh%nr
    end function fun_J02_geometry_is_valid
