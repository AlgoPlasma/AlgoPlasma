program run_J03_from_J01_reference
    use mod_J03_neutral_continuity_faceflux_2Drz
    use mod_application_case
    implicit none
    integer, parameter :: nr = 256, nz = 256
    real, parameter :: pi = 3.1415926535897932384626433832795
    type(neutral_transport_closure_2drz_type) :: closure
    logical, allocatable :: active(:, :)
    integer, allocatable :: face_type(:, :, :)
    real, allocatable :: r_edge(:), z_edge(:), volume(:, :), face_area(:, :, :)
    real, allocatable :: density_ref(:, :), flux_r(:, :), flux_z(:, :)
    real, allocatable :: boundary_inflow(:, :, :), boundary_outflow(:, :, :), loss(:, :), source(:, :)
    real, allocatable :: density(:, :)
    character(len = 1024) :: case_root, j01_dir, output_dir, input_dir
    integer :: ierr, iterations
    logical :: converged
    real :: final_change, max_residual, global_balance, dt, scaled_residual
    real :: inflow_rate, outflow_rate, production_rate, removal_rate, relative_balance

    call get_command_argument(1, case_root)
    call get_command_argument(2, j01_dir)
    call get_command_argument(3, output_dir)
    case_root = trim(case_root)
    j01_dir = trim(j01_dir)
    output_dir = trim(output_dir)
    if (len_trim(case_root) == 0 .or. len_trim(j01_dir) == 0 .or. len_trim(output_dir) == 0) &
        call fail('usage: run_J03_from_J01_reference CASE_DATA_ROOT J01_DIR OUTPUT_DIR')
    input_dir = trim(case_root)
    call read_grid(trim(input_dir)//'/grid_r.dat', nr, r_edge)
    call read_grid(trim(input_dir)//'/grid_z.dat', nz, z_edge)
    call build_case_mask(active)
    call build_geometry_and_faces
    call read_f64_2d(trim(j01_dir)//'/na_j01_rz_f64.bin', nr, nz, density_ref)
    where (.not. active .or. density_ref < 0.0) density_ref = 0.0
    call read_f64_2d(trim(j01_dir)//'/ur_face_flux_f64.bin', nr-1, nz, flux_r)
    call read_f64_2d(trim(j01_dir)//'/uz_face_flux_f64.bin', nr, nz-1, flux_z)
    call read_f64_3d(trim(j01_dir)//'/boundary_inflow_flux_f64.bin', &
        J03_N_FACES, nr, nz, boundary_inflow)
    call read_f64_3d(trim(j01_dir)//'/boundary_outflow_flux_f64.bin', &
        J03_N_FACES, nr, nz, boundary_outflow)
    allocate(loss(nr, nz), source(nr, nz))
    call build_case_loss(r_edge, z_edge, active, .false., loss)
    source = 0.0
    where (.not. active) loss = 0.0
    call sub_J03_initialize_transport_closure(active, face_type, volume, face_area, density_ref, &
        flux_r, flux_z, boundary_inflow, boundary_outflow, loss, 1.0e-6, closure, ierr)
    call check(ierr, 'initialize J01 FM face-flux closure')
    call sub_J03_compute_stable_timestep(closure, 0.45, dt, ierr)
    call check(ierr, 'compute timestep')
    write(*, '(a)') '[J03] case: independent J01 free-molecular face flux'
    write(*, '(a,es12.4)') '[J03] pseudo timestep: ', dt
    call sub_J03_solve_steady(closure, source, 0.45, 1.0e-10, 50000, .true., density, &
        converged, iterations, final_change, max_residual, global_balance, ierr, 1000, &
        residual_tolerance=1.0e-8, final_scaled_residual=scaled_residual)
    call check(ierr, 'solve J01 FM B0 continuity')
    if (.not. converged) call fail('J01 FM B0 continuity did not converge')
    write(*, '(a,i0,a,l1,a,es12.4)') '[J03] steps=', iterations, ', converged=', &
        converged, ', relative change=', final_change
    call write_f64_2d(trim(output_dir)//'/na_cont_rz_f64.bin', density)
    call sub_J03_compute_balance(closure, density, source, inflow_rate, outflow_rate, &
        production_rate, removal_rate, relative_balance, ierr)
    call check(ierr, 'compute particle balance')
    call write_summary(trim(output_dir)//'/j03_run_summary.txt')

contains
    subroutine build_geometry_and_faces
        integer :: i, k
        allocate(volume(nr, nz), face_area(J03_N_FACES, nr, nz), &
            face_type(J03_N_FACES, nr, nz))
        face_area = 0.0
        face_type = J03_FACE_WALL
        do k = 1, nz
            do i = 1, nr
                volume(i, k) = pi*(r_edge(i+1)**2-r_edge(i)**2)*(z_edge(k+1)-z_edge(k))
                face_area(J03_R_LO, i, k) = 2.0*pi*r_edge(i)*(z_edge(k+1)-z_edge(k))
                face_area(J03_R_HI, i, k) = 2.0*pi*r_edge(i+1)*(z_edge(k+1)-z_edge(k))
                face_area(J03_Z_LO, i, k) = pi*(r_edge(i+1)**2-r_edge(i)**2)
                face_area(J03_Z_HI, i, k) = face_area(J03_Z_LO, i, k)
                if (.not. active(i, k)) cycle
                if (i == 1) then
                    face_type(J03_R_LO, i, k) = J03_FACE_OPEN
                else if (active(i-1, k)) then
                    face_type(J03_R_LO, i, k) = J03_FACE_INTERIOR
                end if
                if (i == nr) then
                    face_type(J03_R_HI, i, k) = J03_FACE_OPEN
                else if (active(i+1, k)) then
                    face_type(J03_R_HI, i, k) = J03_FACE_INTERIOR
                end if
                if (k == 1) then
                    face_type(J03_Z_LO, i, k) = J03_FACE_OPEN
                else if (active(i, k-1)) then
                    face_type(J03_Z_LO, i, k) = J03_FACE_INTERIOR
                end if
                if (k == nz) then
                    face_type(J03_Z_HI, i, k) = J03_FACE_OPEN
                else if (active(i, k+1)) then
                    face_type(J03_Z_HI, i, k) = J03_FACE_INTERIOR
                end if
            end do
        end do
    end subroutine build_geometry_and_faces
    subroutine read_grid(path, n, edge)
        character(len = *), intent(in) :: path
        integer, intent(in) :: n
        real, allocatable, intent(out) :: edge(:)
        character(len = 256) :: line
        integer :: unit, j, index, ios
        real :: lo, hi, width
        allocate(edge(n+1))
        open(newunit = unit, file = path, status = 'old', action = 'read', iostat = ios)
        if (ios /= 0) call fail('cannot open grid file: '//trim(path))
        read(unit, '(a)') line
        do j = 1, n
            read(unit, *, iostat = ios) index, lo, hi, width
            if (ios /= 0 .or. index /= j) call fail('invalid grid row: '//trim(path))
            if (j == 1) edge(1) = lo
            edge(j+1) = hi
        end do
        close(unit)
    end subroutine read_grid
    subroutine read_f64_2d(path, n1, n2, array)
        character(len = *), intent(in) :: path
        integer, intent(in) :: n1, n2
        real, allocatable, intent(out) :: array(:, :)
        integer :: unit, ios
        allocate(array(n1, n2))
        open(newunit = unit, file = path, access = 'stream', &
            form = 'unformatted', status = 'old', action = 'read', iostat = ios)
        if (ios /= 0) call fail('cannot open binary input: '//trim(path))
        read(unit, iostat = ios) array
        close(unit)
        if (ios /= 0) call fail('cannot read expected f64 field: '//trim(path))
    end subroutine read_f64_2d
    subroutine read_f64_3d(path, n1, n2, n3, array)
        character(len = *), intent(in) :: path
        integer, intent(in) :: n1, n2, n3
        real, allocatable, intent(out) :: array(:, :, :)
        integer :: unit, ios
        allocate(array(n1, n2, n3))
        open(newunit = unit, file = path, access = 'stream', &
            form = 'unformatted', status = 'old', action = 'read', iostat = ios)
        if (ios /= 0) call fail('cannot open binary input: '//trim(path))
        read(unit, iostat = ios) array
        close(unit)
        if (ios /= 0) call fail('cannot read expected f64 field: '//trim(path))
    end subroutine read_f64_3d
    subroutine write_f64_2d(path, array)
        character(len = *), intent(in) :: path
        real, intent(in) :: array(:, :)
        integer :: unit, ios
        open(newunit = unit, file = path, access = 'stream', form = 'unformatted', status = 'replace', &
            action = 'write', iostat = ios)
        if (ios /= 0) call fail('cannot create binary output: '//trim(path))
        write(unit, iostat = ios) array
        close(unit)
        if (ios /= 0) call fail('cannot write f64 field: '//trim(path))
    end subroutine write_f64_2d
    subroutine write_summary(path)
        character(len = *), intent(in) :: path
        integer :: unit
        open(newunit = unit, file = path, status = 'replace', action = 'write')
        write(unit, '(a)') 'case=J01_FM_B0'
        write(unit, '(a,es24.16)') 'dt_pseudo=', dt
        write(unit, '(a,i0)') 'steps=', iterations
        write(unit, '(a,i0)') 'converged=', merge(1, 0, converged)
        write(unit, '(a,es24.16)') 'final_relative_change=', final_change
        write(unit, '(a,es24.16)') 'max_abs_residual=', max_residual
        write(unit, '(a,es24.16)') 'global_balance=', global_balance
        write(unit, '(a,es24.16)') 'scaled_residual=', scaled_residual
        write(unit, '(a,es24.16)') 'inflow_rate=', inflow_rate
        write(unit, '(a,es24.16)') 'outflow_rate=', outflow_rate
        write(unit, '(a,es24.16)') 'production_rate=', production_rate
        write(unit, '(a,es24.16)') 'removal_rate=', removal_rate
        write(unit, '(a,es24.16)') 'relative_balance=', relative_balance
        close(unit)
    end subroutine write_summary
    subroutine check(code, where)
        integer, intent(in) :: code
        character(len = *), intent(in) :: where
        if (code /= J03_SUCCESS) then
            write(*, '(3a,i0)') '[J03] ERROR in ', trim(where), '; code=', code
            error stop 3
        end if
    end subroutine check
    subroutine fail(message)
        character(len = *), intent(in) :: message
        write(*, '(2a)') '[J03] ERROR: ', trim(message)
        error stop 3
    end subroutine fail
end program run_J03_from_J01_reference
