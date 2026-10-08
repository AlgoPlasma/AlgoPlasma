!> Intersect a physical z-low inlet band with the mesh and return area fractions.
!> This geometry operation does not select an inlet velocity distribution.
    subroutine sub_J02_build_partial_zlo_inlet(mesh, r_min, r_max, face_fraction, &
        xi_lo, xi_hi, ierr)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        real, intent(in) :: r_min, r_max
        real, allocatable, intent(out) :: face_fraction(:), xi_lo(:), xi_hi(:)
        integer, intent(out) :: ierr
        integer :: i
        real :: lo, hi, rc, hr, full_area, overlap_area
        ierr = SN_SUCCESS
        if (.not. allocated(mesh%r_edge) .or. .not. allocated(mesh%active) .or. &
            mesh%nr < 1 .or. mesh%nz < 1) then
            ierr = SN_ERR_GEOMETRY_MESH
            return
        end if
        if (r_min >= r_max .or. r_min < mesh%r_edge(1) .or. &
            r_max > mesh%r_edge(mesh%nr+1)) then
            ierr = SN_ERR_PARTIAL_INLET
            return
        end if
        allocate(face_fraction(mesh%nr), xi_lo(mesh%nr), xi_hi(mesh%nr))
        face_fraction = 0.0
        xi_lo = 0.0
        xi_hi = 0.0
        do i = 1, mesh%nr
            if (.not. mesh%active(i, 1)) cycle
            lo = max(mesh%r_edge(i), r_min)
            hi = min(mesh%r_edge(i+1), r_max)
            if (hi <= lo) cycle
            rc = 0.5*(mesh%r_edge(i)+mesh%r_edge(i+1))
            hr = 0.5*(mesh%r_edge(i+1)-mesh%r_edge(i))
            full_area = 0.5*(mesh%r_edge(i+1)**2-mesh%r_edge(i)**2)
            overlap_area = 0.5*(hi**2-lo**2)
            face_fraction(i) = overlap_area/full_area
            xi_lo(i) = max(-1.0, min(1.0, (lo-rc)/hr))
            xi_hi(i) = max(-1.0, min(1.0, (hi-rc)/hr))
        end do
        if (maxval(face_fraction) <= 0.0) then
            ierr = SN_ERR_PARTIAL_INLET
            deallocate(face_fraction, xi_lo, xi_hi)
        end if
    end subroutine sub_J02_build_partial_zlo_inlet

    logical function fun_J02_boundary_is_valid(mesh, boundary)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_boundary_2drz_type), intent(in) :: boundary
        fun_J02_boundary_is_valid = allocated(boundary%face_r_lo) .and. &
            allocated(boundary%face_r_hi) .and. allocated(boundary%face_z_lo) .and. &
            allocated(boundary%face_z_hi)
        if (.not. fun_J02_boundary_is_valid) return
        fun_J02_boundary_is_valid = size(boundary%face_r_lo, 1) == mesh%nr .and. &
            size(boundary%face_r_lo, 2) == mesh%nz .and. &
            size(boundary%face_r_hi, 1) == mesh%nr .and. size(boundary%face_r_hi, 2) == mesh%nz .and. &
            size(boundary%face_z_lo, 1) == mesh%nr .and. size(boundary%face_z_lo, 2) == mesh%nz .and. &
            size(boundary%face_z_hi, 1) == mesh%nr .and. size(boundary%face_z_hi, 2) == mesh%nz
    end function fun_J02_boundary_is_valid

    integer function fun_J02_face_type(boundary, face_id, i, k)
        type(sn_boundary_2drz_type), intent(in) :: boundary
        integer, intent(in) :: face_id, i, k
        select case (face_id)
          case (SN_R_LO)
            fun_J02_face_type = boundary%face_r_lo(i, k)
          case (SN_R_HI)
            fun_J02_face_type = boundary%face_r_hi(i, k)
          case (SN_Z_LO)
            fun_J02_face_type = boundary%face_z_lo(i, k)
          case (SN_Z_HI)
            fun_J02_face_type = boundary%face_z_hi(i, k)
          case default
            fun_J02_face_type = -1
        end select
    end function fun_J02_face_type

    logical function fun_J02_reflection_inputs_valid(mesh, quadrature, boundary, wall_shape, &
        psi_old, zlo_source_xi_lo, zlo_source_xi_hi)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_quadrature_type), intent(in) :: quadrature
        type(sn_boundary_2drz_type), intent(in) :: boundary
        real, intent(in) :: wall_shape(:), psi_old(:, :, :, :)
        real, intent(in), optional :: zlo_source_xi_lo(:), zlo_source_xi_hi(:)
        logical :: has_lo, has_hi
        has_lo = present(zlo_source_xi_lo)
        has_hi = present(zlo_source_xi_hi)
        fun_J02_reflection_inputs_valid = fun_J02_boundary_is_valid(mesh, boundary) .and. &
            size(wall_shape) == quadrature%n_dir .and. all(wall_shape >= 0.0) .and. &
            size(psi_old, 1) == 3 .and. size(psi_old, 2) == mesh%nr .and. &
            size(psi_old, 3) == mesh%nz .and. size(psi_old, 4) == quadrature%n_dir .and. &
            (has_lo.eqv.has_hi)
        if (.not. fun_J02_reflection_inputs_valid .or. .not. has_lo) return
        fun_J02_reflection_inputs_valid = size(zlo_source_xi_lo) == mesh%nr .and. &
            size(zlo_source_xi_hi) == mesh%nr
        if (.not. fun_J02_reflection_inputs_valid) return
        fun_J02_reflection_inputs_valid = all(zlo_source_xi_lo >= -1.0) .and. &
            all(zlo_source_xi_hi <= 1.0) .and. all(zlo_source_xi_lo <= zlo_source_xi_hi)
    end function fun_J02_reflection_inputs_valid

    ! Only active-cell walls participate in the transport solve.
    logical function fun_J02_has_reflecting_faces(mesh, boundary)
        type(sn_mesh_2drz_type), intent(in) :: mesh
        type(sn_boundary_2drz_type), intent(in) :: boundary
        fun_J02_has_reflecting_faces = &
            any((boundary%face_r_lo == SN_FACE_WALL) .and. mesh%active) .or. &
            any((boundary%face_r_hi == SN_FACE_WALL) .and. mesh%active) .or. &
            any((boundary%face_z_lo == SN_FACE_WALL) .and. mesh%active) .or. &
            any((boundary%face_z_hi == SN_FACE_WALL) .and. mesh%active)
    end function fun_J02_has_reflecting_faces
