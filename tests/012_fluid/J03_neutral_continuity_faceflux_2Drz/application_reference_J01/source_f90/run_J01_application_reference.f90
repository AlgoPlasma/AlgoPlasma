program run_J01_application_reference
    use mod_J01_neutral_free_molecular_2Drz
    use mod_application_case
    implicit none
    integer, parameter :: nr = 256, nz = 256
    real, parameter :: theta_span = 1.0/3.0
    real, parameter :: kb = 1.380649e-23, mass = 2.18017e-25, temperature = 550.0
    real, parameter :: drift_z = 300.0, inlet_density = 5.0e18, diffuse_fraction = 0.7
    real, parameter :: r_in_lo = 0.0151837363, r_in_hi = 0.0232205007
    character(len = 1024) :: case_root, output_dir, input_dir, arg
    real, allocatable :: r_edge(:), z_edge(:), density(:, :), velocity_r(:, :), velocity_z(:, :)
    real, allocatable :: boundary_inflow(:, :, :), boundary_outflow(:, :, :), flux_r(:, :), flux_z(:, :)
    integer, allocatable :: face_type(:, :, :)
    logical, allocatable :: active(:, :)
    real :: sigma, mean_uz, gamma, lo, hi, overlap_lo, overlap_hi, fraction, history_rate
    integer :: i, k, ierr, n_histories, n_completed, n_truncated, ios

    call get_command_argument(1, case_root)
    call get_command_argument(2, output_dir)
    call get_command_argument(3, arg)
    case_root = trim(case_root)
    output_dir = trim(output_dir)
    if (len_trim(case_root) == 0 .or. len_trim(output_dir) == 0) &
        call fail('usage: run_J01_application_reference CASE_DATA_ROOT OUTPUT_DIR [N_HISTORIES]')
    n_histories = 2400000
    if (len_trim(arg) > 0) then
        read(arg, *, iostat = ios)n_histories
        if (ios /= 0 .or. n_histories <= 0) call fail('N_HISTORIES must be a positive integer')
    end if
    input_dir = trim(case_root)
    call read_grid(trim(input_dir)//'/grid_r.dat', nr, r_edge)
    call read_grid(trim(input_dir)//'/grid_z.dat', nz, z_edge)

! Shared case topology is independent of preprocessing outputs.
    call build_case_mask(active)
    allocate(face_type(J01_N_FACES, nr, nz), boundary_inflow(J01_N_FACES, nr, nz))
    face_type = J01_FACE_WALL
    boundary_inflow = 0.0
    call build_face_types

    sigma = sqrt(kb*temperature/mass)
    mean_uz = drift_z+sigma*exp(-0.5*(drift_z/sigma)**2)/sqrt(2.0*acos(-1.0))/ &
        max(0.5*(1.0+erf((drift_z/sigma)/sqrt(2.0))), tiny(1.0))
    gamma = inlet_density*mean_uz
    do i = 1, nr
        if (face_type(J01_Z_LO, i, 1) /= J01_FACE_OPEN) cycle
        lo = r_edge(i)
        hi = r_edge(i+1)
        overlap_lo = max(lo, r_in_lo)
        overlap_hi = min(hi, r_in_hi)
        if (overlap_hi <= overlap_lo) cycle
        fraction = (overlap_hi**2-overlap_lo**2)/(hi**2-lo**2)
        boundary_inflow(J01_Z_LO, i, 1) = gamma*fraction
    end do

    write(*, '(a,i0)') '[J01-FM] independent steady particle histories: ', n_histories
    write(*, '(a)') '[J01-FM] inlet: crossing-sampled drifting Maxwellian'
    call sub_J01_free_molecular_mc_2Drz(r_edge, z_edge, theta_span, active, face_type, &
        r_in_lo, r_in_hi, mass, temperature, temperature, drift_z, inlet_density, &
        diffuse_fraction, n_histories, 20000, 42, density, velocity_r, velocity_z, &
        flux_r, flux_z, boundary_outflow, history_rate, n_completed, n_truncated, ierr, &
        max(1, n_histories/100))
    if (ierr /= J01_SUCCESS) then
        write(*, '(a,i0,a,i0)') '[J01-FM] ERROR: solver code=', ierr, &
            '; truncated histories=', n_truncated
        error stop 2
    end if
    write(*, '(a,i0,a,i0)') '[J01-FM] completed=', n_completed, ', truncated=', n_truncated
    write(*, '(a,es12.4)') '[J01-FM] particle rate represented by one history: ', history_rate
    call write_f64_2d(trim(output_dir)//'/active_mask_rz_f64.bin', merge(1.0, 0.0, active))
    call write_f64_2d(trim(output_dir)//'/na_j01_rz_f64.bin', density)
    call write_f64_2d(trim(output_dir)//'/ur_j01_rz_f64.bin', velocity_r)
    call write_f64_2d(trim(output_dir)//'/uz_j01_rz_f64.bin', velocity_z)
    call write_f64_2d(trim(output_dir)//'/ur_face_flux_f64.bin', flux_r)
    call write_f64_2d(trim(output_dir)//'/uz_face_flux_f64.bin', flux_z)
    call write_f64_2d(trim(output_dir)//'/rlo_open_flux_f64.bin', boundary_outflow(J01_R_LO, :, :))
    call write_f64_2d(trim(output_dir)//'/rhi_open_flux_f64.bin', boundary_outflow(J01_R_HI, :, :))
    call write_f64_2d(trim(output_dir)//'/zlo_open_flux_f64.bin', boundary_outflow(J01_Z_LO, :, :))
    call write_f64_2d(trim(output_dir)//'/zhi_open_flux_f64.bin', boundary_outflow(J01_Z_HI, :, :))
    call write_f64_3d(trim(output_dir)//'/boundary_inflow_flux_f64.bin', boundary_inflow)
    call write_f64_3d(trim(output_dir)//'/boundary_outflow_flux_f64.bin', boundary_outflow)
    call write_summary(trim(output_dir)//'/j01_fm_summary.txt')
    write(*, '(a)') '[J01-FM] output fields written successfully.'
contains
    subroutine build_face_types
        do k = 1, nz
            do i = 1, nr
                if (.not. active(i, k)) cycle
                if (i == 1) then
                    face_type(J01_R_LO, i, k) = J01_FACE_OPEN
                else if (active(i-1, k)) then
                    face_type(J01_R_LO, i, k) = J01_FACE_INTERIOR
                end if
                if (i == nr) then
                    face_type(J01_R_HI, i, k) = J01_FACE_OPEN
                else if (active(i+1, k)) then
                    face_type(J01_R_HI, i, k) = J01_FACE_INTERIOR
                end if
                if (k == 1) then
                    lo = max(r_edge(i), r_in_lo)
                    hi = min(r_edge(i+1), r_in_hi)
                    if (hi > lo) face_type(J01_Z_LO, i, k) = J01_FACE_OPEN
                else if (active(i, k-1)) then
                    face_type(J01_Z_LO, i, k) = J01_FACE_INTERIOR
                end if
                if (k == nz) then
                    face_type(J01_Z_HI, i, k) = J01_FACE_OPEN
                else if (active(i, k+1)) then
                    face_type(J01_Z_HI, i, k) = J01_FACE_INTERIOR
                end if
            end do
        end do
    end subroutine build_face_types
    subroutine read_grid(path, n, edge)
        character(len = *), intent(in) :: path
        integer, intent(in) :: n
        real, allocatable, intent(out) :: edge(:)
        character(len = 256) :: line
        integer :: unit, j, index, stat
        real :: xlo, xhi, width
        allocate(edge(n+1))
        open(newunit = unit, file = path, status = 'old', action = 'read', iostat = stat)
        if (stat /= 0) call fail('cannot open grid file: '//trim(path))
        read(unit, '(a)') line
        do j = 1, n
            read(unit, *, iostat = stat) index, xlo, xhi, width
            if (stat /= 0 .or. index /= j) call fail('invalid grid row: '//trim(path))
            if (j == 1) edge(1) = xlo
            edge(j+1) = xhi
        end do
        close(unit)
    end subroutine read_grid
    subroutine write_f64_2d(path, array)
        character(len = *), intent(in) :: path
        real, intent(in) :: array(:, :)
        integer :: unit, stat
        open(newunit = unit, file = path, access = 'stream', form = 'unformatted', status = 'replace', &
            action = 'write', iostat = stat)
        if (stat /= 0) call fail('cannot create: '//trim(path))
        write(unit, iostat = stat) array
        close(unit)
        if (stat /= 0) call fail('cannot write: '//trim(path))
    end subroutine write_f64_2d
    subroutine write_f64_3d(path, array)
        character(len = *), intent(in) :: path
        real, intent(in) :: array(:, :, :)
        integer :: unit, stat
        open(newunit = unit, file = path, access = 'stream', form = 'unformatted', status = 'replace', &
            action = 'write', iostat = stat)
        if (stat /= 0) call fail('cannot create: '//trim(path))
        write(unit, iostat = stat) array
        close(unit)
        if (stat /= 0) call fail('cannot write: '//trim(path))
    end subroutine write_f64_3d
    subroutine write_summary(path)
        character(len = *), intent(in) :: path
        integer :: unit
        open(newunit = unit, file = path, status = 'replace', action = 'write')
        write(unit, '(a)') 'model=steady_free_molecular_history_mc'
        write(unit, '(a,i0)') 'histories=', n_histories
        write(unit, '(a,i0)') 'completed=', n_completed
        write(unit, '(a,i0)') 'truncated=', n_truncated
        write(unit, '(a,es24.16)') 'history_particle_rate_s_inv=', history_rate
        close(unit)
    end subroutine write_summary
    subroutine fail(message)
        character(len = *), intent(in) :: message
        write(*, '(2a)') '[J01-FM] ERROR: ', trim(message)
        error stop 2
    end subroutine fail
end program run_J01_application_reference
