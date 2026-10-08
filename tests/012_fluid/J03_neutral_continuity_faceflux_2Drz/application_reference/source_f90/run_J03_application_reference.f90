program run_J03_application_reference
    use mod_J03_neutral_continuity_faceflux_2Drz
    use mod_application_case
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
    implicit none
    integer, parameter :: nr = 256, nz = 256
    real, parameter :: pi = 3.1415926535897932384626433832795
    real, parameter :: r_in_lo = 0.0151837363, r_in_hi = 0.0232205007
    type(neutral_transport_closure_2drz_type) :: closure
    logical, allocatable :: active(:, :)
    integer, allocatable :: face_type(:, :, :)
    real, allocatable :: r_edge(:), z_edge(:), volume(:, :), face_area(:, :, :)
    real, allocatable :: density_ref(:, :), flux_r(:, :), flux_z(:, :)
    real, allocatable :: boundary_inflow(:, :, :), boundary_outflow(:, :, :), loss(:, :), source(:, :)
    real, allocatable :: density(:, :)
    character(len = 16) :: case_name
    character(len = 1024) :: case_root, j02_dir, output_dir, input_dir
    integer :: ierr, iterations, i, k
    logical :: converged, is_ion
    real :: final_change, max_residual, global_balance, dt, scaled_residual
    real :: inflow_rate, outflow_rate, production_rate, removal_rate, relative_balance

    call get_command_argument(1, case_name)
    call get_command_argument(2, case_root)
    call get_command_argument(3, j02_dir)
    call get_command_argument(4, output_dir)
    case_name = adjustl(case_name)
    case_root = trim(case_root)
    j02_dir = trim(j02_dir)
    output_dir = trim(output_dir)
    if (trim(case_name) /= 'B0' .and. trim(case_name) /= 'ION') &
        call fail('case must be B0 or ION')
    if (len_trim(case_root) == 0 .or. len_trim(j02_dir) == 0 .or. len_trim(output_dir) == 0) &
        call fail('usage: run_J03_application_reference B0|ION CASE_DATA_ROOT J02_DIR OUTPUT_DIR')
    is_ion = trim(case_name) == 'ION'
    input_dir = trim(case_root)
    call read_grid(trim(input_dir)//'/grid_r.dat', nr, r_edge)
    call read_grid(trim(input_dir)//'/grid_z.dat', nz, z_edge)
    call build_case_mask(active)
    call build_geometry_and_faces
    call read_f64_2d(trim(j02_dir)//'/na_sn_rz_f64.bin', nr, nz, density_ref)
    do k = 1, nz
        do i = 1, nr
            if (.not. active(i,k)) cycle
            if (.not. ieee_is_finite(density_ref(i,k)) .or. density_ref(i,k) < 0.0) then
                write(*, '(a,i0,a,i0,a,es24.16)') &
                    '[J03] invalid J02 reference density at i=', i, ', k=', k, ': ', density_ref(i,k)
                call fail('active reference density must be finite and nonnegative; regenerate J02 output')
            end if
        end do
    end do
    where (.not. active) density_ref = 0.0
    call read_f64_2d(trim(j02_dir)//'/ur_face_flux_f64.bin', nr-1, nz, flux_r)
    call read_f64_2d(trim(j02_dir)//'/uz_face_flux_f64.bin', nr, nz-1, flux_z)
    call read_f64_3d(trim(j02_dir)//'/boundary_inflow_flux_f64.bin', &
        J03_N_FACES, nr, nz, boundary_inflow)
    call read_f64_3d(trim(j02_dir)//'/boundary_outflow_flux_f64.bin', &
        J03_N_FACES, nr, nz, boundary_outflow)
    allocate(loss(nr, nz), source(nr, nz))
    loss = 0.0
    source = 0.0
    call build_case_loss(r_edge, z_edge, active, is_ion, loss)
    where (.not. active) loss = 0.0
    call sub_J03_initialize_transport_closure(active, face_type, volume, face_area, density_ref, &
        flux_r, flux_z, boundary_inflow, boundary_outflow, loss, 1.0e-6, closure, ierr)
    call check(ierr, 'initialize J02 face-flux closure')
    call sub_J03_compute_stable_timestep(closure, 0.45, dt, ierr)
    call check(ierr, 'compute timestep')
    write(*, '(a,a)') '[J03] case: ', trim(case_name)
    write(*, '(a,es12.4)') '[J03] pseudo timestep: ', dt
    call sub_J03_solve_steady(closure, source, 0.45, 1.0e-10, 50000, .true., density, &
        converged, iterations, final_change, max_residual, global_balance, ierr, 1000, &
        residual_tolerance=1.0e-8, final_scaled_residual=scaled_residual)
    if (is_ion) then
        if (ierr /= J03_ERR_NOT_CONVERGED .and. ierr /= J03_SUCCESS) call check(ierr, 'solve ION continuity')
        if (converged) write(*, '(a)') '[J03] NOTE: ION converged before the iteration limit.'
    else
        call check(ierr, 'solve B0 continuity')
        if (.not. converged) call fail('B0 continuity did not converge')
    end if
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
                    if (min(r_edge(i+1), r_in_hi) > max(r_edge(i), r_in_lo)) &
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
        write(unit, '(a)') 'case='//trim(case_name)
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
end program run_J03_application_reference
