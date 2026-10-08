program run_J02_application_reference
    use mod_J02_neutral_sn_transport_2Drz
    use mod_application_case
    implicit none

    integer, parameter :: nr = 256, nz = 256, n_angles = 400, n_speeds = 16
    real, parameter :: pi = 3.14159265358979323846
    real, parameter :: kb = 1.380649e-23, mass = 2.18017e-25
    real, parameter :: temperature = 550.0, drift_z = 300.0, inlet_density = 5.0e18
    real, parameter :: diffuse_fraction = 0.7, r_in_lo = 0.0151837363, r_in_hi = 0.0232205007
    type(sn_mesh_2drz_type) :: mesh
    type(sn_geometry_2drz_type) :: geometry
    type(sn_quadrature_type) :: quadrature
    type(sn_boundary_2drz_type) :: boundary
    real, allocatable :: r_edge(:), z_edge(:), ion_frequency(:, :)
    real, allocatable :: face_fraction(:), xi_lo(:), xi_hi(:), wall_shape(:)
    real, allocatable :: crossing_pdf(:), inflow_shape(:), zlo_inflow(:), sigma_t(:, :, :)
    type(sn_transport_options_type) :: options
    type(sn_transport_result_type) :: result
    logical, allocatable :: active(:, :)
    character(len = 16) :: case_name
    character(len = 1024) :: case_root, output_dir, input_dir
    integer :: ierr, m
    logical :: is_ion
    real :: sigma, speed_max, mean_uz, normal_pdf, cdf, target_flux

    call get_command_argument(1, case_name)
    call get_command_argument(2, case_root)
    call get_command_argument(3, output_dir)
    case_name = adjustl(case_name)
    case_root = trim(case_root)
    output_dir = trim(output_dir)
    if (trim(case_name) /= 'B0' .and. trim(case_name) /= 'ION') &
        call fail('case must be B0 or ION')
    if (len_trim(case_root) == 0 .or. len_trim(output_dir) == 0) &
        call fail('usage: run_J02_application_reference B0|ION CASE_DATA_ROOT OUTPUT_DIR')
    is_ion = trim(case_name) == 'ION'
    input_dir = trim(case_root)

    call read_grid(trim(input_dir)//'/grid_r.dat', nr, r_edge)
    call read_grid(trim(input_dir)//'/grid_z.dat', nz, z_edge)
    call build_case_mask(active)
    call sub_J02_initialize_mesh(r_edge, z_edge, active, mesh, ierr)
    call check(ierr, 'initialize mesh')
    call sub_J02_build_geometry(mesh, 2.0*pi, geometry, ierr)
    call check(ierr, 'build geometry')
    call sub_J02_initialize_boundary_types(mesh, boundary, ierr)
    call check(ierr, 'initialize boundary')
    call sub_J02_build_partial_zlo_inlet(mesh, r_in_lo, r_in_hi, face_fraction, xi_lo, xi_hi, ierr)
    call check(ierr, 'build partial inlet')
    call sub_J02_configure_zlo_partial_inlet_boundary(mesh, face_fraction, boundary, ierr)
    call check(ierr, 'configure partial-inlet boundary')

    sigma = sqrt(kb*temperature/mass)
    speed_max = max(abs(drift_z)+6.0*sigma, 6.0*sigma)
    call sub_J02_build_phase_quadrature(n_angles, n_speeds, 'gauss-chebyshev', &
        speed_max, quadrature, ierr)
    call check(ierr, 'build phase quadrature')
    call sub_J02_build_wall_maxwell_shape(quadrature, temperature, mass, wall_shape, ierr)
    call check(ierr, 'build wall Maxwell shape')

    allocate(crossing_pdf(quadrature%n_dir))
    crossing_pdf = 0.0
    do m = 1, quadrature%n_dir
        if (quadrature%eta(m) > 0.0) crossing_pdf(m) = exp(-0.5*((quadrature%speed(m)* &
            quadrature%mu(m)/sigma)**2+((quadrature%speed(m)*quadrature%eta(m)- &
            drift_z)/sigma)**2))
    end do
    call sub_J02_build_mc_crossing_pdf_inflow_shape(quadrature, 0.0, -1.0, &
        crossing_pdf, inflow_shape, ierr)
    call check(ierr, 'build MC-sampled inlet shape')
    normal_pdf = exp(-0.5*(drift_z/sigma)**2)/sqrt(2.0*pi)
    cdf = 0.5*(1.0+erf((drift_z/sigma)/sqrt(2.0)))
    mean_uz = drift_z+sigma*normal_pdf/max(cdf, tiny(1.0))
    target_flux = inlet_density*mean_uz
    call sub_J02_normalize_inflow_flux(quadrature, 0.0, -1.0, target_flux, &
        inflow_shape, zlo_inflow, ierr)
    call check(ierr, 'normalize inlet flux')

    allocate(ion_frequency(nr, nz))
    ion_frequency = 0.0
    call build_case_loss(r_edge, z_edge, active, is_ion, ion_frequency)
    call sub_J02_build_sigma_from_frequency(quadrature, ion_frequency, sigma_t, ierr)
    call check(ierr, 'build ionization removal coefficient')
    write(*, '(a,a)') '[J02] case: ', trim(case_name)
    write(*, '(a,i0,a,i0)') '[J02] mesh: ', nr, ' x ', nz
    write(*, '(a,i0)') '[J02] phase directions: ', quadrature%n_dir
    write(*, '(a,es12.4)') '[J02] allocated psi bytes per buffer: ', &
        real(3, kind = 8)*nr*nz*quadrature%n_dir*storage_size(1.0)/8.0_8
    ! The application supplies physics; the library owns solve/reconstruction order.
    options%diffuse_fraction = diffuse_fraction
    options%max_iterations = 120
    options%tolerance = 1.0e-6
    options%progress_interval = 1
    call sub_J02_solve_transport(mesh, geometry, quadrature, boundary, sigma_t, result, ierr, &
        wall_shape=wall_shape, options=options, zlo_source_xi_lo=xi_lo, &
        zlo_source_xi_hi=xi_hi, zlo_inflow=zlo_inflow)
    if (ierr /= SN_SUCCESS) then
        write(*, '(a,i0,2a)') '[J02] ERROR code=', ierr, ': ', trim(fun_J02_error_message(ierr))
        write(*, '(a,3(i0,1x))') '[J02] failed direction/i/k: ', &
            result%failed_direction, result%failed_i, result%failed_k
        error stop 2
    end if
    if (.not. result%converged) call fail('J02 source iteration did not converge')
    write(*, '(a,i0,a,es12.4)') '[J02] converged in ', result%iterations, &
        ' iterations; relative change=', result%relative_change

    call write_f64_2d(trim(output_dir)//'/active_mask_rz_f64.bin', merge(1.0, 0.0, active))
    call write_f64_2d(trim(output_dir)//'/na_sn_rz_f64.bin', result%density)
    call write_f64_2d(trim(output_dir)//'/ur_sn_rz_f64.bin', result%velocity_r)
    call write_f64_2d(trim(output_dir)//'/uz_sn_rz_f64.bin', result%velocity_z)
    call write_f64_2d(trim(output_dir)//'/ur_face_flux_f64.bin', result%flux_r)
    call write_f64_2d(trim(output_dir)//'/uz_face_flux_f64.bin', result%flux_z)
    call write_f64_2d(trim(output_dir)//'/rlo_open_flux_f64.bin', &
        result%outflow_flux(SN_R_LO, :, :))
    call write_f64_2d(trim(output_dir)//'/rhi_open_flux_f64.bin', &
        result%outflow_flux(SN_R_HI, :, :))
    call write_f64_2d(trim(output_dir)//'/zlo_open_flux_f64.bin', &
        result%outflow_flux(SN_Z_LO, :, :))
    call write_f64_2d(trim(output_dir)//'/zhi_open_flux_f64.bin', &
        result%outflow_flux(SN_Z_HI, :, :))
    call write_f64_3d(trim(output_dir)//'/boundary_inflow_flux_f64.bin', result%inflow_flux)
    call write_f64_3d(trim(output_dir)//'/boundary_outflow_flux_f64.bin', result%outflow_flux)
    call write_summary(trim(output_dir)//'/j02_run_summary.txt')
    write(*, '(a)') '[J02] output fields written successfully.'

contains
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
        read(unit, '(a)', iostat = ios) line
        do j = 1, n
            read(unit, *, iostat = ios) index, lo, hi, width
            if (ios /= 0 .or. index /= j) call fail('invalid grid row in: '//trim(path))
            if (j == 1) edge(1) = lo
            edge(j+1) = hi
        end do
        close(unit)
    end subroutine read_grid


    subroutine write_f64_2d(path, array)
        character(len = *), intent(in) :: path
        real, intent(in) :: array(:, :)
        real(kind = 8), allocatable :: buffer(:, :)
        integer :: unit, ios
        allocate(buffer(size(array, 1), size(array, 2)))
        buffer = real(array, kind = 8)
        open(newunit = unit, file = path, access = 'stream', form = 'unformatted', status = 'replace', &
            action = 'write', iostat = ios)
        if (ios /= 0) call fail('cannot create binary output: '//trim(path))
        write(unit, iostat = ios) buffer
        close(unit)
        if (ios /= 0) call fail('cannot write f64 field: '//trim(path))
    end subroutine write_f64_2d

    subroutine write_f64_3d(path, array)
        character(len = *), intent(in) :: path
        real, intent(in) :: array(:, :, :)
        real(kind = 8), allocatable :: buffer(:, :, :)
        integer :: unit, ios
        allocate(buffer(size(array, 1), size(array, 2), size(array, 3)))
        buffer = real(array, kind = 8)
        open(newunit = unit, file = path, access = 'stream', form = 'unformatted', status = 'replace', &
            action = 'write', iostat = ios)
        if (ios /= 0) call fail('cannot create binary output: '//trim(path))
        write(unit, iostat = ios) buffer
        close(unit)
        if (ios /= 0) call fail('cannot write f64 field: '//trim(path))
    end subroutine write_f64_3d

    subroutine write_summary(path)
        character(len = *), intent(in) :: path
        integer :: unit
        open(newunit = unit, file = path, status = 'replace', action = 'write')
        write(unit, '(a)') 'case='//trim(case_name)
        write(unit, '(a,i0)') 'source_iterations=', result%iterations
        write(unit, '(a,i0)') 'source_converged=', merge(1, 0, result%converged)
        write(unit, '(a,es24.16)') 'source_final_rel_change=', result%relative_change
        close(unit)
    end subroutine write_summary

    subroutine check(code, where)
        integer, intent(in) :: code
        character(len = *), intent(in) :: where
        if (code /= SN_SUCCESS) then
            write(*, '(3a,i0,2a)') '[J02] ERROR in ', trim(where), '; code=', code, &
                ': ', trim(fun_J02_error_message(code))
            error stop 2
        end if
    end subroutine check

    subroutine fail(message)
        character(len = *), intent(in) :: message
        write(*, '(2a)') '[J02] ERROR: ', trim(message)
        error stop 2
    end subroutine fail
end program run_J02_application_reference
